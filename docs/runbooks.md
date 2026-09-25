# EGT Operations Runbooks

Day-2 procedures for the EGT backend. All commands assume shell access to the
environment running the API and `psql`/Prisma access to the database.
**Production is not provisioned yet** — rehearse every runbook on staging
first (TODO-needs-infra). Seed/dev credentials below are dev-only.

Conventions: `$API` = API base URL (e.g. `http://localhost:3000/api/v1` in
dev). Admin calls need an admin JWT in `Authorization: Bearer <token>`.

---

## RB-01 — Rotate JWT secrets

**When:** suspected leak, staff departure, or scheduled rotation (quarterly
recommended).

**Blast radius:** rotating `JWT_ACCESS_SECRET` invalidates **all** outstanding
access tokens (≤15 min of forced re-login). Rotating `JWT_REFRESH_SECRET`
invalidates **all** refresh tokens (every user must log in again).
`DOCUMENT_SIGNING_SECRET` rotation invalidates outstanding signed download
URLs (they expire in 15 min anyway).

1. Generate new secrets:
   `openssl rand -base64 48` (three times — one per secret).
2. Update the secret manager (or `.env` in dev). Keep the old values handy
   until step 5 passes.
3. Rolling restart the API instances. The app reads secrets at boot
   (`src/config/env.ts`); there is no hot-reload.
4. Verify: log in as a dev user, call `GET $API/auth/me` with the new token.
5. Verify old tokens are dead: call `GET $API/auth/me` with a pre-rotation
   access token → expect `401 TOKEN_INVALID`.
6. Confirm background behaviour: refresh with a pre-rotation refresh token →
   expect `401` (users re-login; this is normal).
7. Write an audit note (manual entry — e.g. a support ticket or ops log):
   who rotated, when, why.

**Rollback:** restore the previous secret values and restart. Only works if
no user has obtained tokens under the new secret that you still want valid —
in practice, rotation is one-way; prefer forward-fixing.

**Never done yet** — first rotation should be a scheduled drill on staging.

## RB-02 — Revoke user sessions

**When:** user reports a lost/stolen device, suspected account compromise, or
staff offboarding.

As the user (self-service):
```bash
# list sessions
curl -H "Authorization: Bearer <userToken>" $API/auth/sessions
# revoke one
curl -X DELETE -H "Authorization: Bearer <userToken>" $API/auth/sessions/{id}
# revoke everything (all devices)
curl -X POST -H "Authorization: Bearer <userToken>" $API/auth/logout-all
```

As an admin (for another user — via DB, since no admin session-revoke
endpoint exists):
```sql
-- inspect
SELECT id, "userAgent", "ipAddress", "expiresAt", "revokedAt"
FROM "Session" WHERE "userId" = '<user-uuid>' AND "revokedAt" IS NULL;
-- revoke all sessions of the user (cascades to their refresh tokens)
UPDATE "Session" SET "revokedAt" = now(), "revokedReason" = 'admin_revoke'
WHERE "userId" = '<user-uuid>' AND "revokedAt" IS NULL;
```
Then confirm: the user's next API call returns `401` and they must re-login.

**Gap to fix:** consider adding `DELETE /admin/users/{id}/sessions` so admins
don't need DB access for this.

## RB-03 — Handle refresh-token reuse lockout

**What happened:** someone presented an already-rotated refresh token. The API
automatically revoked the **entire token family** and locked the session
(`revokedReason = 'refresh_token_reuse_detected'`) and wrote an audit entry
(`metadata.reason = 'refresh_reuse'`). This is the designed response to
suspected token theft — **do not "unlock" the session without investigating**.

1. Find the event:
   ```bash
   curl -H "Authorization: Bearer <adminToken>" \
     "$API/admin/audit-log?action=user_login&limit=50"   # adjust filter to your viewer
   ```
   Or in SQL:
   ```sql
   SELECT "createdAt", "actorId", "ipAddress", "userAgent", metadata
   FROM "AuditLog"
   WHERE metadata->>'reason' = 'refresh_reuse'
   ORDER BY "createdAt" DESC LIMIT 20;
   ```
2. Correlate: same user, new IP/device vs. their history? Multiple reuses in a
   short window suggest real theft; a single reuse right after a network retry
   can be benign (client retried with an already-rotated token).
3. If benign: tell the user to log in again (their family was revoked as a
   precaution). No further action.
4. If suspicious:
   - Revoke all sessions (RB-02).
   - Force a password reset (issue via `forgot-password` once SMTP works; until
     then, admin sets a temporary password via DB + `passwordHash` regeneration
     — use the app's argon2 path, never plaintext).
   - Consider rotating `JWT_REFRESH_SECRET` (RB-01) if the leak scope is unclear.
5. Record the decision in the audit trail (support ticket or ops log).

## RB-04 — Restore DB from backup

**When:** data corruption, bad migration, accidental delete. Full procedure in
`docs/deployment.md` §4.2 — this is the operator's checklist:

1. **Stop writes:** scale the API to 0 / stop the container.
2. **Restore to a new database** (`egt_restore`), never over the live one:
   `pg_restore -d <restore-url> egt-<date>.dump`
3. **Sanity checks** on the restored copy:
   ```sql
   SELECT count(*) FROM "User"; SELECT count(*) FROM "Rfq";
   SELECT count(*) FROM "Document";
   -- spot-check the newest rows' createdAt
   SELECT max("createdAt") FROM "Rfq";
   ```
4. **Restore `DOCUMENT_STORAGE_DIR`** from its snapshot to the matching point
   in time (files and DB metadata must agree).
5. **Cut over:** repoint `DATABASE_URL` at the restored DB (or rename
   databases), run `npx prisma migrate deploy` (no-op if schema matches),
   restart the API.
6. **Verify:** login works, RFQ list loads, a document downloads via signed URL.
7. **Post-mortem:** what caused the restore, what was lost (RPO), follow-ups.

**Never rehearsed** — first restore drill on staging is a launch blocker.

## RB-05 — Add a product

**When:** EGT lists a new export product (staff/admin only).

Preferred path — admin dashboard: Products → New product (fields: name, slug,
category, short description, order volume, spec bullets, images, flags).

API path:
```bash
curl -X POST -H "Authorization: Bearer <staffToken>" \
     -H 'Content-Type: application/json' \
     -d '{"name":"Example Product","slug":"example-product","categoryId":"<uuid>",
          "shortDescription":"…","orderVolume":"500 L / 50 Cartons",
          "specifications":["Spec one","Spec two"]}' \
     $API/products
# upload images separately via POST $API/documents/upload (kind: compliance/other),
# then attach through the product update endpoint
```

Rules (from the site-audit ground rules):
- Names, spec bullets and order volumes should mirror the live website verbatim.
- **No prices** on the product — pricing happens via quotation.
- **No compliance/certification claims** (ISO, FSSAI, APEDA, Global G.A.P.)
  without evidence from Sukh; use "Compliance docs on request".
- New products default to `isActive=true`, `isFeatured=true` — review before
  they appear in the app catalogue.

## RB-06 — Approve a supplier listing

**When:** a supplier submits a product listing (`status = pending_review`).

1. Review queue: admin dashboard → Suppliers → Pending, or
   `GET $API/suppliers/pending` (staff/admin).
2. Inspect the listing: company, capabilities, custom name/description,
   attached documents (download via signed URLs — verify they open and match
   the claim).
3. Decision via `PATCH $API/suppliers/listings/{id}/review`
   (staff/admin) with `{ "status": "approved" | "changes_required" | "rejected",
   "reviewNote": "…" }`.
4. Rules enforced server-side:
   - Listings are **never auto-published** — nothing reaches the catalogue
     without this review.
   - A reviewer **cannot approve their own** supplier record (403).
   - Every review writes an audit entry (`supplier_product_reviewed`).
5. If approved and it maps to a catalogue `Product`, it becomes visible per the
   product's `isActive` flag; custom (non-catalogue) listings stay
   supplier-attributed.

## RB-07 — Investigate audit log entries

**When:** suspicious activity, user disputes ("I didn't change that"), or
routine review.

1. Query via `GET $API/admin/audit-log` (admin only; filter by actor, action,
   entity, time range) or SQL:
   ```sql
   -- everything one user did in the last 7 days
   SELECT "createdAt", action, "entityType", "entityId", "ipAddress", metadata
   FROM "AuditLog"
   WHERE "actorId" = '<user-uuid>' AND "createdAt" > now() - interval '7 days'
   ORDER BY "createdAt" DESC;
   -- all security-relevant actions across users
   SELECT "createdAt", action, "actorId", "ipAddress", metadata
   FROM "AuditLog"
   WHERE action IN ('user_login_failed','role_changed','admin_action',
                    'document_downloaded','quote_accepted')
     AND "createdAt" > now() - interval '24 hours'
   ORDER BY "createdAt" DESC;
   ```
2. What to look for:
   - `user_login_failed` bursts from one IP → brute force (check throttling worked).
   - `metadata.reason = 'refresh_reuse'` → possible token theft (RB-03).
   - `role_changed` → verify it was an intended admin action.
   - `document_downloaded` outside business hours / from unusual IPs.
   - `admin_action` entries you don't recognise → escalate.
3. The log is **append-only** (no API update/delete); if rows are missing for a
   period, suspect DB-level tampering and treat as an incident.
4. `AuditService` never throws — if the API was up but no rows were written,
   check application logs for `[audit] failed to write audit log`.

---

## Missing runbooks (write before production)

- Bootstrap the first production admin user (empty DB → admin account).
- Rotate `DOCUMENT_SIGNING_SECRET` independently of JWT secrets.
- Add `DELETE /admin/users/{id}/sessions` (or document permanent DB-access need).
- Disable/delete a user account (GDPR-style data deletion request flow).
- Rotate SMTP credentials and verify email delivery.
- FCM/APNs key rotation and push-delivery verification.
