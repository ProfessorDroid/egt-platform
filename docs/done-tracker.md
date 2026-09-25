# EGT Program — Done Tracker

**Purpose:** brutally honest mapping of the program's definition-of-done
criteria to DONE / PARTIAL / BLOCKED-NEEDS-HUMAN, with evidence and file
pointers. Nothing here claims more than the tools proved.

**Sourcing note:** the coordinator's summary named the definition-of-done
criteria below; the brief's full numbered list of 22 deliverables is not
present in this workspace or in memory, so it could not be mapped item-by-item.
§2 inventories the deliverable artifacts that actually exist in the repo
(derived from file contents, not from the brief's numbering). If the brief's
22-item list surfaces, reconcile it against this file.

**Status key:**
- **DONE** — implemented *and* verified by a tool run (test, build, migration,
  or live smoke test). Evidence cited.
- **PARTIAL** — substantially implemented but missing verification, integration,
  or a production-critical piece.
- **BLOCKED-NEEDS-HUMAN** — cannot proceed without Sukh (account, key, decision)
  or provisioned infrastructure.

Ownership reminder: `docs/mobile-build.md` belongs to the mobile child and is
not covered here.

---

## 1. Definition-of-done criteria

| # | Criterion | Status | Evidence / file pointers | What unblocks full DONE |
|---|---|---|---|---|
| 1 | Frontend works | **PARTIAL** | Flutter scaffold complete: 110 lib files / ~12.9k lines, 30 screens, 378 EN l10n keys (+pa/hi stubs), clean architecture, Dio+refresh, secure storage, deep links; bracket/import/l10n audits pass (`apps/mobile/`) | **BLOCKED**: Flutter SDK absent on build machine — never compiled, no `flutter analyze`/`flutter test`/APK. Needs SDK + device testing. |
| 2 | Backend works | **DONE** | REAL: `npm install` OK (648 pkgs), `prisma migrate deploy` on real PG16, 35/35 jest pass, live API smoke test (`apps/backend/`) | — |
| 3 | DB works | **DONE** | Schema migrated on PG16; UUID PKs, soft deletes, audit fields, indexes, yearly-sequential numbering; dev seed (16 products, 4 roles, 5 users) with prod guard (`prisma/seed.ts`, `docs/database.md`) | Prod DB provisioning (needs-from-Sukh) is deployment, not DB function |
| 4 | Auth works | **DONE** | Smoke-verified: register→login→refresh→logout; unit-tested: role coercion, 5-fail lockout, rotation, reuse→family-revoke, logout-all (`test/unit/auth.service.spec.ts`) | Email verify/reset **delivery** blocked on SMTP (criterion 11-adjacent gap) |
| 5 | Authorization works | **DONE** | Unit + live smoke negatives: cross-buyer 403, buyer on `/admin/*` 403, illegal transition 422, supplier self-approval 403; role re-resolved from DB per request (`test/unit/rbac.spec.ts`) | — |
| 6 | RFQ end-to-end | **PARTIAL** | Backend lifecycle fully unit-tested (happy path, illegal jumps, terminal states) + smoke-tested transition 422; quote-accept atomicity unit-tested (`rfq-state-machine.spec.ts`, `quotes.service.spec.ts`) | No UI-driven E2E: mobile uncompiled, admin pipeline never exercised against a live API |
| 7 | Catalogue | **DONE** | 16 site-audited products seeded verbatim (unverified compliance bullets excluded); `GET /products`, `/products/{slug}`, `/products/categories` live; admin product CRUD builds (`apps/backend/prisma/seed.ts`) | — |
| 8 | Buyer dashboard | **PARTIAL** | Mobile buyer screens scaffolded (uncompiled); admin `/admin/overview` + Dashboard page build and render **empty states only** — never placeholder stats | Live data + compiled app; verify against staging API |
| 9 | Supplier workflow | **PARTIAL** | Backend: profile, listings, `pending_review` never-auto-publish, review endpoint, self-approval 403 (unit-tested); admin Suppliers page builds | Never exercised end-to-end (submit → review → approve → visible) |
| 10 | Secure document upload | **PARTIAL** | Implemented: MIME allowlist, 10 MB cap, UUID filenames outside web root, HMAC-signed 15-min URLs, per-doc authz; signed-URL crypto unit-tested (`documents-crypto.spec.ts`) | Live upload→signed-download round-trip never executed (see ST-DOC in `docs/security-test-plan.md`) |
| 11 | Notifications work | **PARTIAL** | Persistence, per-event preferences, device-token register/remove endpoints implemented; event types defined | Fan-out is `LogPushProvider` (**log-only**). Needs FCM/APNs keys (needs-from-Sukh) |
| 12 | Admin works | **PARTIAL** | REAL: `tsc -b` + `vite build` exit 0, 13/13 vitest; reconciled against real `openapi.yaml`; idle sign-out; UNDECLARED shapes marked | Never run against a live API; response field names are best-effort guesses; admin README still describes removed MFA/idle-lock (stale — fix before handoff) |
| 13 | APIs protected | **DONE** | Global `JwtAuthGuard` + `RolesGuard`; helmet; CORS allowlist; throttling; validation on every DTO; friendly error envelope | TLS termination still TODO (infra) |
| 14 | Errors handled | **DONE** | `{code,message,details?}` envelope; no stack traces; `VALIDATION_ERROR` field details; verified in unit + smoke tests | — |
| 15 | Production configuration exists | **PARTIAL** | `.env.example`, zod-validated `src/config/env.ts`, `docker-compose.yml`, multi-stage `Dockerfile` (non-root), env matrix in `docs/deployment.md` | No provisioned infra, no vault, no prod secrets, no prod domains/CORS |
| 16 | Backups exist | **BLOCKED-NEEDS-HUMAN** | Design + restore procedure documented (`docs/deployment.md` §4, `docs/runbooks.md` RB-04); local docker volume only | Managed Postgres with snapshots + PITR; infra decision (needs-from-Sukh) |
| 17 | Tests pass | **DONE** | Backend 35/35 jest; admin 13/13 vitest; shared types build (`openapi-typescript` codegen) | Mobile `flutter test` never ran (no SDK); add CI per `docs/deployment.md` §2 |
| 18 | Security testing completed | **PARTIAL** | 35 unit tests (auth/RBAC/state-machine/quote-rules/signed-URLs) + live smoke test (auth flow + RBAC negatives); full executable plan written (`docs/security-test-plan.md`) | Plan **not executed**; no independent pentest (needs-from-Sukh) |
| 19 | No critical vulnerabilities | **PARTIAL** | No known vulns in implemented code paths; deps installed clean; argon2id/HMAC/JWT per current guidance | **Cannot assert**: no `npm audit` gate in CI, no pentest, no DAST/SAST run |
| 20 | Android release production-ready | **BLOCKED-NEEDS-HUMAN** | `applicationId com.eaglegoodstrading.egt` configured; manifest permissions justified; `usesCleartextTraffic=false`; Play listing guide written (`docs/app-store.md`) | No Flutter SDK (never compiled), no release keystore, no Play Console account, no FCM configs, privacy-policy page 500 on website, no contact email |

### Counts

- **DONE: 8** (backend, DB, auth, authorization, catalogue, APIs protected, errors handled, tests pass)
- **PARTIAL: 10** (frontend, RFQ e2e, buyer dashboard, supplier workflow, secure doc upload, notifications, admin, prod config, security testing, no critical vulns)
- **BLOCKED-NEEDS-HUMAN: 2** (backups, Android release prod-ready)

## 2. Deliverable artifact inventory (from repo contents)

| Artifact | Location | State |
|---|---|---|
| Site audit (Phase 0) | `docs/site-audit.md` | DONE — 16 products, 6 forms, brand tokens, gaps flagged |
| Architecture | `docs/architecture.md` | DONE (Stage A draft; partially superseded by builds) |
| Glossary | `docs/glossary.md` | DONE |
| Mobile build notes | `docs/mobile-build.md` | Owned by mobile child — not touched |
| API contract | `packages/shared/openapi.yaml` + generated types | DONE — 63 paths / 76 ops; **zero response schemas published** |
| Backend API (NestJS) | `apps/backend/` | DONE — verified per §1 |
| Database schema + migrations + seed | `apps/backend/prisma/` | DONE — verified per §1 |
| Flutter mobile app | `apps/mobile/` | PARTIAL — scaffold only, never compiled |
| React admin dashboard | `apps/admin/` | PARTIAL — builds + tests pass, never hit a live API |
| API guide | `docs/api.md` | DONE (this phase) |
| Database guide | `docs/database.md` | DONE (this phase) |
| Security posture | `docs/security.md` | DONE (this phase) |
| Security test plan | `docs/security-test-plan.md` | DONE as a document; **not executed** |
| Deployment guide + CI plan | `docs/deployment.md` | DONE as a document; CI not wired, infra not provisioned |
| Play Store guide | `docs/app-store.md` | DONE as a document; submission blocked |
| Operations runbooks | `docs/runbooks.md` | DONE as documents; **never rehearsed** |
| Done tracker | `docs/done-tracker.md` | DONE (this file) |

## 3. Consolidated needs-from-Sukh (blocks PARTIAL → DONE)

1. **Play Console account** + **release signing keystore** (criterion 20)
2. **FCM/APNs configs** (criterion 11; ST-CLIENT-06)
3. **Server infra decision** — API host, managed Postgres, document storage (criteria 15, 16)
4. **Production domains + CORS** decisions (criteria 13/15)
5. **SMTP credentials + verified sender** (criterion 4 gap; ST-AUTH-19)
6. **Real EGT contact email** (Play listing + `MAIL_FROM`; audit found none published)
7. **"EST. 2024" vs "since 2016"** founding-year decision (app-store copy)
8. **Production signing secrets + vault** (criteria 15, 19; runbook RB-01)
9. **Independent penetration test** (criteria 18, 19)
10. **Admin account policy** (who gets staff/admin; bootstrap procedure)
11. **MFA recovery/policy decision** (MFA absent — build it or accept password-only for staff)
12. **Shipment-status vocabulary + private-label field mapping** confirmations (flagged during build)
13. Founding-year/email decisions also gate the **privacy-policy page fix** (website `privacy-policy.php` is HTTP 500 — Play requires a live policy URL)

## 4. What I could not verify

- The brief's literal section-47 checklist and its numbered 22-deliverable list
  (not present in workspace or memory; §1 maps the coordinator's verbatim
  criteria instead — see sourcing note).
- Anything requiring a live browser, a device, or provisioned infra.
- Mobile code beyond static reads (no Flutter SDK — correctness of the Dart
  source is per the mobile child's audits, not mine).
- Whether the admin dashboard has ever been run against the live backend API.
- Exact live smoke-test coverage beyond what the coordinator reported
  (auth flow + RBAC negatives incl. cross-buyer 403, buyer-on-/admin 403,
  illegal transition 422).
