# EGT Security Posture

**Scope:** the mobile app program (Flutter app, NestJS API, PostgreSQL, React
admin). The PHP website is out of scope for this document.

**Honesty header:** this document describes what is *implemented in code*
(verified by reading the source on 2026-09-25), what is *planned*, and what is
*absent*. It is not a pentest report — no independent security test has been
run (needs-from-Sukh). Related: `docs/security-test-plan.md` (executable cases),
`docs/api.md` (auth flow), `docs/database.md` (data model).

---

## 1. Threat model

### 1.1 Assets

| Asset | Where it lives | Impact if compromised |
|---|---|---|
| Buyer PII + commercial RFQ terms (budgets, target prices, delivery addresses) | Postgres (`User`, `Rfq`, `Order`, `Company`) | Confidentiality — buyer trust, competitive harm |
| Quotes & proforma pricing | Postgres (`Quote`, `QuoteItem`) | Confidentiality — price leakage to competitors |
| Trade documents (COA, BL, invoices) | `DOCUMENT_STORAGE_DIR` (disk) + metadata in Postgres | Confidentiality — shipment forgery risk |
| Credentials & tokens | Postgres (argon2id hashes, SHA-256 token hashes); client secure storage | Account takeover if leaked |
| JWT / document-signing secrets | env / secret manager | Total auth bypass if leaked |
| Admin access (user/role mgmt, audit log) | API + admin dashboard | Full system compromise |
| Audit log integrity | Postgres (`AuditLog`, append-only) | Loss of accountability/forensics |

### 1.2 Actors

| Actor | Capability assumed |
|---|---|
| Anonymous internet attacker | Can hit public endpoints; cannot authenticate. |
| Malicious buyer account | Authenticated; tries to read other buyers' RFQs/quotes/orders. |
| Malicious supplier account | Authenticated; tries to self-approve listings, read unshared RFQs. |
| Compromised staff account | Elevated read/write on pipeline; tries privilege escalation to admin. |
| Attacker with a stolen refresh token | Tries to mint new access tokens; reuse should be detected. |
| Attacker with a stolen access token | 15-minute window of use; tries to extend it. |
| Malicious file uploader | Tries path traversal, MIME spoofing, oversized uploads, malware. |

### 1.3 Trust boundaries

```
[ Mobile app ] ──HTTPS──> [ API ] ──> [ Postgres ]      (1) client is untrusted; server re-validates everything
[ Admin SPA ]  ──HTTPS──> [ API ]                         (2) same API + same RBAC; no separate auth system
[ API ] ──HMAC──> [ Document storage (disk) ]             (3) private dir; clients get signed URLs only, 15-min TTL
[ API ] ──?──> [ SMTP provider ]                          (4) NOT CONFIGURED — email flows are non-functional
[ API ] ──?──> [ FCM/APNs ]                               (5) NOT CONFIGURED — push is log-only
```

**Key design decisions from this model:**
role is re-resolved from the DB on every request (never trusted from the
token/client); buyers are scoped to their own data server-side; suppliers see
only their own listings and staff-shared RFQs; documents are never addressable
by predictable URL.

---

## 2. What is actually implemented (verified in source)

All of the following were read in the code on 2026-09-25 — file pointers given.

| Control | Where | Detail |
|---|---|---|
| Password hashing | `apps/backend/prisma/schema.prisma` (`User.passwordHash`), auth service | **argon2id**. Policy: 10–128 chars, upper+lower+digit+symbol (`RegisterDto`). |
| Short-lived access tokens | `apps/backend/src/config/env.ts` (`ACCESS_TOKEN_TTL_SECONDS=900`) | JWT, 15 minutes. |
| Rotating refresh tokens | `apps/backend/src/modules/auth/auth.service.ts` (~lines 220–310) | Opaque, 30-day, single-use, SHA-256 stored, `familyId` chains. |
| Refresh reuse detection | same | Reuse of a rotated token → revoke **entire family**, lock session, audit entry. Unit-tested. |
| Server-side RBAC | `src/common/guards/jwt-auth.guard.ts`, `roles.guard.ts` (global `APP_GUARD`) | Role resolved from DB per request. Unit-tested negatives (buyer on `/admin/*` → 403; cross-buyer → 403). |
| Registration role coercion | `auth.service.ts` register | Public register can only create buyer/supplier; `admin` coerced to buyer. Unit-tested. |
| Login lockout | `auth.service.ts` (~lines 119–148) | 5 failed attempts → 15-min `lockedUntil`; counter resets on success. Unit-tested. |
| Route throttling | `src/app.module.ts` + `auth.controller.ts` | Global 120 req/60 s; login 10/60 s. `429 RATE_LIMITED`. |
| Input validation | DTOs with class-validator on every input | Invalid input → `400 VALIDATION_ERROR` with field details. |
| RFQ state machine | RFQ service + unit tests | Illegal transitions → 422; terminal states respected. |
| Quote accept re-verification | `quotes.service.ts` (~line 105) | Ownership, `sent` state, `validUntil`, quotable RFQ state re-checked atomically; double accept → 409. Unit-tested. |
| Supplier self-approval block | suppliers service | Reviewer cannot approve their own listing (403). Unit-tested. |
| Signed document URLs | `documents.controller.ts`, `documents-crypto.spec.ts` | HMAC-signed, 15-min TTL; tampered/expired/wrong-secret tokens rejected. Unit-tested. |
| Upload hardening | `documents.controller.ts` (`ALLOWED_MIME`, 10 MB `fileSize` cap) | Allowlist: pdf, jpg/jpeg, png, webp, doc/docx, xls/xlsx, csv, txt. Random UUID filenames, stored outside web root. |
| Audit log | `src/modules/audit/audit.module.ts` | Append-only; 21 action types; actor/IP/user-agent/entity recorded; writes never break the request path. |
| Friendly errors | `src/common/filters/all-exceptions.filter.ts` | `{ code, message, details? }`; no stack traces to clients. |
| Security headers | `src/main.ts` | `helmet()` applied. |
| CORS allowlist | `src/main.ts` + `CORS_ORIGINS` | Explicit origin allowlist; credentials enabled. |
| Body limits | `src/main.ts` | JSON/urlencoded capped at `MAX_REQUEST_BODY_MB` (2 MB). |
| No cleartext on mobile | `apps/mobile/android/app/src/main/AndroidManifest.xml` | `android:usesCleartextTraffic="false"`. |
| Token storage (mobile) | `lib/src/core/storage/secure_token_storage.dart` | Refresh token in platform secure storage (Keystore/Keychain); access token in memory only. |
| Token storage (admin) | `apps/admin/src/api/client.ts` | Access token in memory; refresh token in `sessionStorage`. |
| Admin idle sign-out | `apps/admin/src/auth/AuthContext.tsx` | 15-min idle → sign out (API offers no unlock endpoint). |
| Deterministic numbering | `src/common/utils/sequences.util.ts` | Yearly-sequential numbers allocated atomically — no gaps/duplicates on retry. |
| Secrets config | `src/config/env.ts` (zod-validated) | JWT/doc-signing secrets must be ≥ 32 chars; app refuses to boot otherwise. |
| Docker least-privilege | `apps/backend/Dockerfile` | Non-root `egt` user at runtime; dev dependencies stripped. |

---

## 3. OWASP MASVS control mapping

Mapping against the OWASP Mobile Application Security Verification Standard
(v2.x) categories. Statuses: **Implemented** (in code, verified), **Planned**
(designed, not built), **Absent** (no implementation).

### V1 — Architecture, design & threat modeling

| Control | Status | Evidence / note |
|---|---|---|
| Documented architecture with trust boundaries | Implemented | `docs/architecture.md` + §1 above |
| Security controls enforced server-side | Implemented | guards, state machine, RBAC (unit-tested) |

### V2 — Data storage & privacy

| Control | Status | Evidence / note |
|---|---|---|
| No sensitive data in plaintext client storage | Implemented | tokens in secure storage (mobile) / sessionStorage (admin) |
| No credentials in SharedPreferences/UserDefaults | Implemented | `flutter_secure_storage` only |
| Sensitive data encrypted at rest server-side | Partial | Passwords argon2id; tokens SHA-256 hashed. **DB-level encryption at rest (managed disk encryption) not yet provisioned** — TODO-needs-infra |
| Secure data wipe on logout | Implemented | token revocation + client-side token clear |
| No sensitive data in logs | Implemented | log provider records push *intent*, not token contents; audit failures log action names only |

### V3 — Cryptography

| Control | Status | Evidence / note |
|---|---|---|
| Industry-standard algorithms | Implemented | argon2id, JWT (HS256 with ≥32-char secrets), HMAC-signed URLs, SHA-256 |
| No hardcoded secrets | Implemented | env-only; `.env.example` placeholders |
| Secrets ≥ 32 chars enforced | Implemented | zod schema in `env.ts` |
| Key rotation procedure | Planned | documented in `docs/runbooks.md`; never exercised |
| Secrets in a managed vault | Absent | local `.env` in dev; **no vault provisioned for staging/prod** |

### V4 — Authentication & session management

| Control | Status | Evidence / note |
|---|---|---|
| Strong password policy | Implemented | 10+ chars, complexity classes |
| Breached-password check | Absent | flagged TBD in architecture; not built |
| MFA for staff/admin | Absent | **removed** — no backend endpoint exists (admin reconciled 2026-09-25) |
| Short-lived sessions + rotation | Implemented | 15-min JWT; rotating refresh + reuse detection |
| Session inventory + remote revoke | Implemented | `GET/DELETE /auth/sessions`, `logout-all` |
| Brute-force protection | Implemented | 10/min throttle + 5-fail 15-min lockout |
| Biometric app unlock | Implemented (client) | `local_auth` wired in mobile (`USE_BIOMETRIC` permission); never tested on device |

### V5 — Network communication

| Control | Status | Evidence / note |
|---|---|---|
| TLS for all API traffic | Planned | `usesCleartextTraffic="false"` set; **no TLS termination documented/provisioned** (needs infra) |
| Certificate pinning | Absent | not implemented |
| CORS restricted | Implemented | explicit allowlist |

### V6 — Platform interaction

| Control | Status | Evidence / note |
|---|---|---|
| Minimal permissions | Implemented | manifest declares only: INTERNET, ACCESS_NETWORK_STATE, USE_BIOMETRIC, POST_NOTIFICATIONS, CAMERA, READ_MEDIA_IMAGES/VIDEO (+ legacy READ_EXTERNAL_STORAGE maxSdkVersion 32) — see `docs/app-store.md` for justifications |
| Deep-link validation | Partial | custom scheme `egt://` registered; App Links require server-side `assetlinks.json` — **not provisioned** |
| No sensitive data via IPC/clipboard | Implemented | no such flows in scaffold |

### V7 — Code quality & build settings

| Control | Status | Evidence / note |
|---|---|---|
| No debug flags in release | Planned | build flavors exist (`dev`/`staging` suffixes); release build never produced (no Flutter SDK) |
| Friendly errors, no stack traces | Implemented | `AllExceptionsFilter` |
| Dependency scanning | Absent | no `npm audit` / SCA gate in CI yet — add in `docs/deployment.md` pipeline |
| Signed release builds | Absent | no keystore (needs-from-Sukh) |

### V8 — Resilience (anti-tamper / anti-reverse-engineering)

| Control | Status | Evidence / note |
|---|---|---|
| Root/jailbreak detection | Absent | out of scope for v1 threat model (server-side enforcement is the mitigation) |
| Obfuscation | Planned | enable Dart obfuscation at release build (Flutter `--obfuscate`); not done |

### Privacy & data handling

| Control | Status | Evidence / note |
|---|---|---|
| Data-safety disclosure prepared | Planned | drafted in `docs/app-store.md` from actual data flows |
| Analytics/crash reporting | Absent | flags exist in `AppConfig`; **no provider wired** (no data collected yet — good for privacy, missing for ops) |

---

## 4. Explicit gaps (must be closed before production)

1. **No TLS termination documented.** The API expects HTTPS (mobile forbids
   cleartext) but no certificate/reverse-proxy is provisioned. TODO-needs-infra.
2. **No WAF / DDoS protection.** Rate limiting is application-level only.
3. **No independent penetration test.** Unit tests + smoke test only (see
   `docs/security-test-plan.md`). needs-from-Sukh.
4. **Email flows are non-functional.** Verification and password-reset tokens are
   generated but **never sent** — no SMTP credentials (needs-from-Sukh).
   Consequences: users cannot self-verify email or self-serve password reset.
5. **Push is log-only.** `LogPushProvider`; no FCM/APNs keys (needs-from-Sukh).
6. **No managed secret vault.** Rotation procedure is documented but untested;
   dev JWT secrets are placeholders.
7. **No MFA for staff/admin** (backend has no endpoints; admin feature removed
   in reconciliation). Decide: build MFA or accept password-only for staff.
8. **Admin dashboard README is partially stale** — still describes TOTP MFA,
   idle-lock screen and re-auth flows that were removed. Fix before handoff.
9. **Certificate pinning, root detection, obfuscation** — absent (accepted risk
   for v1; server-side enforcement is the primary mitigation).
10. **Managed DB encryption at rest / PITR backups** — not provisioned
    (TODO-needs-infra, see `docs/deployment.md`).
11. **Deep-link App Links** (`assetlinks.json` on the website host) — not
    provisioned; custom scheme works without it.

## 5. Incident-relevant contacts & procedures

- Suspicious audit entries → `docs/runbooks.md` ("Investigate audit log entries").
- Suspected token theft → refresh reuse auto-revokes the family; follow the
  "Handle refresh-token reuse lockout" runbook, then rotate JWT secrets.
- No on-call rotation exists yet — define one before production (TODO).
