# EGT Security Test Plan

**Sourcing note (read first):** the coordinator's summary referenced the brief's
section-47 security-testing checklist, but the brief's literal text is not
present in this workspace or in memory, so it could not be reproduced verbatim
here. The test cases below are derived from the security controls actually
implemented in `apps/backend` (verified in source) plus the OWASP MASVS
categories used in `docs/security.md`. If the brief's section 47 names
additional cases, they should be appended — nothing here should be treated as
the complete brief checklist.

**Execution status: NOT EXECUTED.** Nothing below has been run as a security
test campaign. The only verification that exists is:

- **35/35 jest unit tests** (`apps/backend/test/unit/`, mocked Prisma, no DB) —
  exactly covering: auth register/login/refresh/logout-all (role coercion,
  5-fail lockout, refresh rotation + reuse→family-revoke), email-verify token
  rejection, signed-URL round-trip/expiry/tamper/wrong-secret, quote-accept
  rules (403/409/422/happy-path), RBAC negatives (guest 401, buyer-on-admin
  403, cross-buyer 403, supplier self-approval 403), RFQ state-machine
  transitions. **These test logic with mocks, not a live system.**
- **Live API smoke test** (real PG16, 2026-09-25) — covered: full auth flow
  (register→login→refresh→logout), RBAC negatives (**cross-buyer 403, buyer on
  `/admin/*` 403, illegal RFQ transition 422**). It did **not** cover: reuse
  detection under live conditions, lockout timing, document upload/download
  round-trip, quote-accept concurrency, throttling thresholds, or any
  attack-oriented probing.

How to use this plan: each case has ID, objective, steps, expected result, and
a status column (`Pass` / `Fail` / `Not executed`). Execute against a **staging**
environment with test accounts only — never production customer data.

---

## ST-AUTH — Authentication & session management

| ID | Objective | Steps | Expected result | Status |
|---|---|---|---|---|
| ST-AUTH-01 | Registration cannot create staff/admin | POST `/auth/register` with `role:"admin"` and with `role:"staff"` | Both accounts created as **buyer**; no privilege granted | Not executed |
| ST-AUTH-02 | Duplicate email rejected without enumeration signal | POST `/auth/register` twice with same email | Second → `409 EMAIL_TAKEN`; first account unaffected | Not executed |
| ST-AUTH-03 | Weak passwords rejected | Try: `short`, `alllowercase1!`, `ALLUPPER1!`, `NoDigits!!`, `NoSymbol12` | All → `400 VALIDATION_ERROR` with field messages | Not executed |
| ST-AUTH-04 | Passwords stored as argon2id | Inspect `User.passwordHash` in DB after register | `$argon2id$…` format; plaintext absent; raw password nowhere in logs | Not executed |
| ST-AUTH-05 | Wrong password increments counter; 5th locks account | Login 5× with wrong password on a test account | 1–4 → `401`; 5th → lockout; correct password during lockout → rejected (`lockedUntil` set ~15 min) | Not executed |
| ST-AUTH-06 | Login throttle | 11 login attempts within 60 s (any credentials) | 11th → `429 RATE_LIMITED` | Not executed |
| ST-AUTH-07 | Successful login resets fail counter and issues pair | After failures < 5, login correctly | `200` with `accessToken` + `refreshToken`; `failedLoginCount=0`, `lastLoginAt` set | Not executed |
| ST-AUTH-08 | Access token expires in 15 min | Decode `exp` claim of a fresh token | `exp − iat` ≈ 900 s | Not executed |
| ST-AUTH-09 | Expired access token rejected | Wait 15+ min (or craft expired JWT) and call `GET /auth/me` | `401 TOKEN_INVALID` / "Session expired" | Not executed |
| ST-AUTH-10 | Token role claim not trusted | Take buyer token, tamper `role` claim → call `GET /admin/users` | `403` (role re-resolved from DB) | Not executed |
| ST-AUTH-11 | Refresh rotates and invalidates old token | Login → refresh → reuse the **old** refresh token | Rotation returns new pair; reusing old → whole family revoked, session locked, audit entry `refresh_reuse`, forced re-login | Not executed |
| ST-AUTH-12 | Unknown refresh token rejected | POST `/auth/refresh` with random string | `401` | Not executed |
| ST-AUTH-13 | Refresh tokens stored hashed | Inspect `RefreshToken.tokenHash` in DB | SHA-256 hex; raw token absent | Not executed |
| ST-AUTH-14 | Logout revokes family | Login → logout → refresh with that token | `401` | Not executed |
| ST-AUTH-15 | Logout-all revokes every session | Login on two "devices" → logout-all → refresh both | Both `401`; all `Session` rows revoked | Not executed |
| ST-AUTH-16 | Session list + single revoke | `GET /auth/sessions`, then `DELETE /auth/sessions/{id}` for one | Listed sessions show device/IP; deleted session's tokens stop working | Not executed |
| ST-AUTH-17 | Email verification token single-use | Verify with a valid token, then reuse it | First → success; second → `400` | Not executed |
| ST-AUTH-18 | Password reset token single-use + expiry | Request reset; use token; reuse; use after expiry | Only first use succeeds; others rejected | Not executed |
| ST-AUTH-19 | Reset email actually delivered | Register → forgot-password → check inbox | Email arrives with working link (**currently fails — no SMTP**; record as blocked) | Not executed |

## ST-AUTHZ — Authorization (RBAC)

| ID | Objective | Steps | Expected result | Status |
|---|---|---|---|---|
| ST-AUTHZ-01 | Guest cannot touch auth-required endpoints | Call `/rfqs`, `/orders`, `/admin/users` without token | All `401` | Not executed |
| ST-AUTHZ-02 | Buyer blocked from admin routes | Buyer token → `GET /admin/users`, `GET /admin/audit-log`, `PATCH /admin/users/{id}/role` | All `403` | Not executed |
| ST-AUTHZ-03 | Staff blocked from admin routes | Staff token → `/admin/*` | `403` | Not executed |
| ST-AUTHZ-04 | Cross-buyer isolation (RFQ read) | Buyer B → `GET /rfqs/{buyerA-rfq-id}` | `403` | Not executed |
| ST-AUTHZ-05 | Cross-buyer isolation (RFQ transition) | Buyer B → `POST /rfqs/{buyerA-rfq-id}/transition` | `403` | Not executed |
| ST-AUTHZ-06 | Cross-buyer isolation (quotes/orders/documents) | Buyer B → quote/order/document URLs of buyer A | `403` or `404`-masked (confirm which the API uses) | Not executed |
| ST-AUTHZ-07 | Supplier cannot self-approve listing | Supplier (also staff role, owning the supplier) → `PATCH /suppliers/listings/{own-id}/review` approve | `403` | Not executed |
| ST-AUTHZ-08 | Supplier sees only own listings + shared RFQs | Supplier token → `GET /suppliers/me/listings`, `GET /rfqs` | Only own records | Not executed |
| ST-AUTHZ-09 | Quote accept ownership | Buyer B → `POST /quotes/{buyerA-quote-id}/accept` | `403` | Not executed |
| ST-AUTHZ-10 | Role can only change via admin endpoint | Buyer attempts any self-promotion path (PATCH `/users/me` with role field) | Role unchanged; `403` where applicable | Not executed |

## ST-RFQ — RFQ / quote / order business rules

| ID | Objective | Steps | Expected result | Status |
|---|---|---|---|---|
| ST-RFQ-01 | Illegal transition rejected | `POST /rfqs/{id}/transition` submitted→approved | `422` | Not executed |
| ST-RFQ-02 | Terminal states stay terminal | Transition from `completed`/`closed` | `422` | Not executed |
| ST-RFQ-03 | Expired quote cannot be accepted | Accept a quote past `validUntil` | `422` | Not executed |
| ST-RFQ-04 | Double accept rejected | Accept the same quote twice (second immediately) | First `200` + order created; second `409` | Not executed |
| ST-RFQ-05 | RFQ numbers unique under concurrency | Fire 10 concurrent `POST /rfqs` | 10 distinct `EGT-RFQ-<year>-<seq>` numbers, no gaps on retry | Not executed |
| ST-RFQ-06 | Accept is atomic | Accept valid quote; inspect DB | Quote=accepted, Order created, RFQ=approved — all or nothing | Not executed |

## ST-DOC — Document security

| ID | Objective | Steps | Expected result | Status |
|---|---|---|---|---|
| ST-DOC-01 | MIME allowlist enforced | Upload `.exe`, `.html`, `.svg`, double-extension `x.pdf.exe` | Rejected (`FILE_TYPE_NOT_ALLOWED`); never stored | Not executed |
| ST-DOC-02 | 10 MB cap enforced | Upload 10 MB + 1 byte file | Rejected | Not executed |
| ST-DOC-03 | Filenames randomised, no traversal | Upload `../../evil.txt`; list storage dir | Stored as UUID filename; no traversal; `originalName` preserved only as metadata | Not executed |
| ST-DOC-04 | Signed URL expiry | Get download URL, wait 15+ min, fetch | Rejected after TTL | Not executed |
| ST-DOC-05 | Signed URL tamper resistance | Flip one char in the signature/query, fetch | Rejected | Not executed |
| ST-DOC-06 | Per-document authorization | Buyer B fetches buyer A's document download URL | `403`/`404` | Not executed |
| ST-DOC-07 | No directory listing | Request the storage path / predictable URLs directly | No listing; no access without signed token | Not executed |

## ST-NET — Network & platform

| ID | Objective | Steps | Expected result | Status |
|---|---|---|---|---|
| ST-NET-01 | Global rate limit | 121 requests in 60 s from one client | 121st → `429 RATE_LIMITED` with envelope | Not executed |
| ST-NET-02 | CORS allowlist | Request with `Origin: https://evil.example` | Blocked ("CORS origin not allowed") | Not executed |
| ST-NET-03 | Security headers | `curl -I` on API responses | helmet headers present (HSTS only meaningful behind TLS — record) | Not executed |
| ST-NET-04 | No stack traces in errors | Trigger 500 (e.g. malformed JSON deep path) | `{code:"INTERNAL_ERROR", message:"Something went wrong…"}`; no trace | Not executed |
| ST-NET-05 | Oversized body rejected | POST > 2 MB JSON body | Rejected at body-parser limit | Not executed |
| ST-NET-06 | Mobile forbids cleartext | Inspect release APK manifest/network config | `usesCleartextTraffic=false`; no http:// API calls in traffic capture | Not executed |
| ST-NET-07 | TLS verification (when provisioned) | Point staging at real TLS; intercept with proxy | App refuses proxied connection without installed CA (baseline; pinning is a separate decision) | Not executed |

## ST-CLIENT — Mobile & admin client

| ID | Objective | Steps | Expected result | Status |
|---|---|---|---|---|
| ST-CLIENT-01 | No tokens in insecure storage (mobile) | After login, dump SharedPreferences/UserDefaults | No tokens present; tokens only in Keystore/Keychain | Not executed |
| ST-CLIENT-02 | Logout wipes tokens (mobile) | Login → logout → inspect secure storage | Tokens cleared | Not executed |
| ST-CLIENT-03 | Refresh token not in admin localStorage | After admin login, inspect storage | Refresh token only in `sessionStorage`, access token in memory | Not executed |
| ST-CLIENT-04 | Admin idle sign-out | Idle 15+ min in admin | Signed out; tokens cleared | Not executed |
| ST-CLIENT-05 | Admin shows no placeholder stats | Load dashboard with empty backend | "No data yet" empty states; no invented numbers | Not executed |
| ST-CLIENT-06 | Malformed API shapes fail soft | Point admin at mocked odd responses | Empty states, no crash (until response schemas are published) | Not executed |

## ST-OPS — Operational security

| ID | Objective | Steps | Expected result | Status |
|---|---|---|---|---|
| ST-OPS-01 | JWT secret rotation works | Rotate `JWT_ACCESS_SECRET` per runbook; verify old tokens die, new logins work | No downtime beyond token expiry; procedure completes | Not executed |
| ST-OPS-02 | Audit log captures security events | Perform failed logins, reuse, role change | `user_login_failed`, `refresh_reuse`, `role_changed` rows with actor/IP | Not executed |
| ST-OPS-03 | Audit log is append-only | Attempt update/delete via API | No endpoint exists; direct DB write is the only path (DB role-restricted) | Not executed |
| ST-OPS-04 | Backup restore works | Restore staging DB from a backup snapshot | Data intact; app boots against restored DB | Not executed |

---

## Sign-off

| Role | Name | Date | Result |
|---|---|---|---|
| Security tester | _TBD — needs independent tester (needs-from-Sukh)_ | — | Not executed |
| Backend owner | — | — | — |
| Sukh (acceptance) | — | — | — |

**No critical vulnerabilities may ship to production without this plan being
executed and every case `Pass` (or explicitly risk-accepted in writing).**
