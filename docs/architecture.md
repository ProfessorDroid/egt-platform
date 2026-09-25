# EGT Mobile App Program — Architecture

**Status: DRAFT (Stage A)** — Written 2026-09-25 from the 60-point program brief + the Phase-0 site audit.
Everything under "PLANNED" has not been built yet. Backend/mobile/admin children are building in parallel;
this document will be reconciled with their actual outputs in Stage B.

Related: `docs/site-audit.md` (live-site facts), `docs/glossary.md` (domain terms).

---

## 1. System overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER MOBILE APP                        │
│  (Android first; iOS later)  — guest browsing, RFQ submission,   │
│  partner dashboard, push notifications via FCM                    │
└──────────────┬──────────────────────────────────┬───────────────┘
               │ HTTPS / REST (JSON, JWT)         │ FCM tokens / push
               ▼                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                  NestJS API  (apps/api) — PLANNED                │
│  REST endpoints · server-side RBAC guard · input validation       │
│  (Zod/DV) · argon2 password hashing · rotating refresh tokens    │
│  signed-URL document service · audit-log interceptor             │
│       │                │                    │                     │
│       ▼                ▼                    ▼                     │
│  ┌──────────┐   ┌──────────────┐   ┌───────────────────────┐      │
│  │ Postgres │   │ Prisma ORM   │   │  Object storage (S3-   │      │
│  │ (RDS/    │◄──│  migrations  │   │  compatible, PLANNED) │      │
│  │  managed)│   │              │   │  private bucket,      │      │
│  └──────────┘   └──────────────┘   │  signed URLs only     │      │
│                                    └───────────────────────┘      │
└──────────────┬──────────────────────────────────────────────────┘
               │ HTTPS / REST (same API, JWT, RBAC)
               ▼
┌─────────────────────────────────────────────────────────────────┐
│               REACT ADMIN DASHBOARD — PLANNED                    │
│  Staff/admin web UI: RFQ pipeline (Kanban), product catalogue    │
│  CMS, leads board, partner management, user/role management,    │
│  audit-log viewer, content pages (About/OEM/FAQ…)               │
└─────────────────────────────────────────────────────────────────┘
```

Cross-cutting (PLANNED):
- `packages/shared/openapi.yaml` — single API contract, consumed by mobile + admin.
- CI/CD: lint → unit tests → integration tests → OpenAPI validation → build → deploy.
- Observability: structured JSON logs, request tracing (correlation IDs), uptime monitoring, error alerting.
- Email delivery for RFQ/enquiry notifications (provider TBD — see Open questions).

The public website (eaglegoodstrading.com, PHP) is **not** replaced by this program; it remains the
marketing surface. The mobile app talks only to the new NestJS API. No website database integration
exists (the site stores inquiries in flat JSON + email); a later phase may add a one-way
inquiry-sync, but that is out of scope for the initial build.

---

## 2. Component responsibilities

### 2.1 Mobile app — Flutter (`apps/mobile`) — PLANNED
- **Owner:** mobile child. Detailed build notes live in `docs/mobile-build.md` (mobile child owns that file).
- Guest browsing: home, product catalogue, product detail (specs, MOQ, badges), sectors, company info.
- RFQ flow: 12-step buyer requirement form (mirrors the site's quote.php fields: contact → product →
  commercial), offline draft persistence, submission via API.
- Partner experience: referral-code login (same semantics as the site's partner dashboard), lead list,
  message thread with EGT team.
- Push: FCM token registration on login; notifications for RFQ status changes and partner messages.
- Auth storage: access token in memory; refresh token in platform secure storage (Android Keystore /
  iOS Keychain). No credentials in SharedPreferences/UserDefaults.
- Local caching of catalogue + content pages with stale-while-revalidate; explicit "offline" states.
- Brand: EGT design tokens (red `#C8102E`, harbor `#0D2233`, Archivo/DM Sans) — assets vendored under
  `apps/mobile/assets/brand/` per the site audit.

### 2.2 Backend API — NestJS + Prisma + PostgreSQL (`apps/api`) — PLANNED
- **Owner:** backend child.
- REST API described by `packages/shared/openapi.yaml`; DTO validation on every input (never trust client).
- RBAC enforced **server-side** via guards on every route; roles: `guest` (unauthenticated),
  `buyer`, `supplier`, `staff`, `admin`. Role is a claim in the access token, re-checked against the DB.
- Auth: argon2id password hashing; short-lived JWT access tokens (15 min); **rotating refresh tokens**
  (single-use, reuse detection → revoke family). Password reset via single-use tokenized email link.
- File/document service: uploads (COA/MSDS, product images, partner docs) go to a private bucket;
  clients receive **time-limited signed URLs**; no public listing of the bucket.
- Audit log: every mutating action and every admin data access writes an append-only audit record
  (actor, action, entity, before/after hash, IP, timestamp).
- Rate limiting per IP + per account on auth and RFQ endpoints; idempotency keys on RFQ submission.
- Background jobs (email notifications, push fan-out) via a queue (BullMQ/Redis — TBD).

### 2.3 Admin dashboard — React (`apps/admin`) — PLANNED
- **Owner:** admin child.
- Staff/admin-only SPA served over HTTPS; same API + same RBAC (no separate auth system).
- RFQ pipeline board (12-step lifecycle stages → Kanban), buyer/supplier/partner management,
  product catalogue CMS, content-page editor (About/OEM/Sourcing/QC/Shipping/FAQ/Privacy/Terms),
  Live Leads board publishing, notification composer, audit-log viewer, user/role administration.
- All destructive actions require confirmation + write audit entries; admin sessions time out on inactivity.

### 2.4 Database — PostgreSQL (managed, e.g. RDS/Cloud SQL) — PLANNED
- **Owner:** backend child (schema via Prisma migrations).
- Core domains: users (+roles), products (+specs, images, MOQ), RFQs (+line items, status history,
  documents), partners (+referral codes, leads, messages), content pages, notifications, audit logs,
  refresh-token families.
- Migrations are forward-only and reviewed; seed data only for dev/staging (never prod credentials).
- Backups: automated daily snapshots + point-in-time recovery (see Stage B `docs/deployment.md`).

---

## 3. RFQ lifecycle — data flow

The 12-step lifecycle (from the brief; exact stage names to be locked in the admin build):

```
 1. draft (mobile, local)          7. quoted (staff sends proforma)
 2. submitted (API)                8. negotiating
 3. triaged (staff assigns)        9. confirmed (buyer accepts)
 4. under review                  10. production / sourcing
 5. supplier matched              11. shipped (docs attached: BL, COA, invoice)
 6. sampling                       12. delivered / closed (feedback)
```

Flow:

```
Mobile app                      API                        Admin dashboard
──────────                      ───                        ───────────────
buyer completes 12-step form
  → POST /rfqs (idempotency key)
  → server validates DTO,
    creates RFQ (status=submitted),
    writes audit entry,
    enqueues staff notification      → staff sees new card in
                                      pipeline (Kanban, realtime)
                                      → triage: assign owner,
                                        move to under review
buyer gets push: "RFQ received"      ← status change events
                                      → staff requests sample /
                                        attaches docs (signed URLs)
buyer uploads docs / accepts quote ←→ negotiation via messages
                                      → confirmed → production →
                                        shipped (BL/COA attached)
buyer confirms delivery, rates    → delivered/closed; audit
                                      trail complete
```

Invariants:
- Status transitions are a server-side state machine; illegal transitions are rejected (422).
- Buyers see only their own RFQs; suppliers see only RFQs shared with them by staff; staff see all.
- Every transition writes an audit record and (where configured) a push/email notification.
- Price fields are never exposed to roles that shouldn't see them (supplier sees buyer's target price
  only if staff explicitly shares it — TBD in Stage B).

---

## 4. Auth / token flow

```
Mobile / Admin
   │
   │  POST /auth/login {email|phone, password}
   ▼
API: verify argon2id hash → issue:
   • access JWT (15 min, claims: sub, role, tokenVersion)
   • refresh token (opaque, single-use, stored hashed server-side, family id)
   │
   │  access token in Authorization: Bearer header
   ▼
API guard: validate JWT → load user → check tokenVersion → enforce RBAC
   │
   │  POST /auth/refresh {refreshToken}   (before access expiry)
   ▼
API: validate refresh token → ROTATE: invalidate old, issue new pair.
Reuse of an already-rotated token → revoke entire family, force re-login,
log security event.
   │
   │  POST /auth/logout → revoke family
   ▼
```

- Password policy: min 12 chars, breached-password check (k-anonymity API or local list — TBD Stage B).
- MFA: TOTP for staff/admin (PLANNED, Stage B decision); buyers/partners optional.
- Partner "login" uses the referral-code scheme from the website (code → partner session, limited scope);
  partner sessions are short-lived and cannot access buyer RFQ data beyond their own leads.
- Social login: not in scope for v1.

---

## 5. Environment strategy

|                    | dev | staging | prod |
|--------------------|-----|---------|------|
| Purpose            | local dev | pre-release verification | live users |
| API base URL       | localhost | `api-staging.*` (TBD) | `api.*` (TBD) |
| DB                 | local Postgres (docker) | managed, staging tier | managed, prod tier, PITR |
| Mobile builds      | debug | internal testing track | Play release track |
| Seed data          | yes (fake) | yes (fake) | **never** |
| Secrets            | `.env` local | secret manager | secret manager, rotation |
| Push               | FCM sandbox project | FCM staging project | FCM prod project |

Promotion rule: `dev → staging → prod` only via CI after the full test suite passes;
no direct deploys to staging/prod from a laptop. Database migrations run automatically on deploy,
forward-only, with a tested rollback plan (down-migrations or restore).

---

## 6. Tech-stack decisions (with rationale)

| Choice | Decision | Rationale (brief) |
|--------|----------|-------------------|
| Mobile: Flutter (Dart) | per brief | One codebase for Android now + iOS later; Sukh asked for both platforms eventually. |
| Backend: NestJS (TypeScript) | per brief | Structured DI framework; guards/interceptors fit RBAC + audit requirements cleanly. |
| ORM: Prisma | per brief | Type-safe schema + migrations; pairs with Postgres. |
| DB: PostgreSQL (managed) | per brief | Relational fit for RFQ pipeline/audit; managed service removes backup/HA burden. |
| Admin: React SPA | per brief | Same API contract; team familiarity; fast iteration for internal tooling. |
| API contract: OpenAPI YAML in `packages/shared/` | per brief | Single source of truth; codegen for mobile/admin clients; CI-validated. |
| Auth: JWT access (15m) + rotating opaque refresh | per security rules | Limits blast radius of stolen tokens; rotation detects theft. |
| Passwords: argon2id | per security rules | Memory-hard; current OWASP recommendation. |
| File URLs: signed, time-limited | per security rules | No public bucket; documents (COA/BL) stay private. |
| Push: FCM | standard | Android-first; free tier; token-based, no PII in payload. |

Deferred / TBD (Stage B or later): queue choice (BullMQ/Redis vs managed), email provider,
hosting target (infra not yet chosen — see Open questions), analytics, crash reporting.

---

## 7. Open questions / risks

1. **9 of 15 sitemap pages return HTTP 500** (about, catalogue, oem-private-label, sourcing-process,
   quality-control, shipping-documentation, faq, privacy-policy, terms-and-conditions). The app's
   content screens (About, OEM, Sourcing, QC, FAQ, Privacy, Terms) cannot be sourced from the site
   until these are fixed. **App content strategy:** ship with the admin CMS as the content source and a
   clearly-marked "content pending" state; do not scrape or invent copy. Needs Sukh's decision on
   whether the website gets fixed first or the app carries the content.
2. **No published email address found on the site.** Contact screens in the app must not invent one.
   Needed from Sukh before Play publish (Play's data-safety + store listing require a real contact).
3. **"EST. 2024" (logo) vs "Export Specialists since 2016" (contact page).** Do not resolve in the app;
   needs Sukh's clarification before any "About" copy ships.
4. **Unverified compliance claims on products.php** (ISO 9001 & GMP dishwash; FSSAI/APEDA wheat;
   APEDA/Global G.A.P. potatoes) conflict with the homepage's "Compliance docs on request". The app
   must show only "Compliance docs on request" unless Sukh provides evidence.
5. **Play Console account, app signing keys, and server infrastructure are NOT yet available.**
   No store submission, no production deploy, and no independent security test can be scheduled until
   Sukh provisions these. This blocks: closed testing track, release signing, prod hosting, pentest.
6. **Earn-with-EGT form fields unknown** (JS-rendered, not extractable). Partner signup in the app
   must be modeled from a real capture later, not from this audit.
7. **Website has no cart/login/tracking** — the app's RFQ + partner features have no web backend to
   integrate with; the NestJS API is the system of record for everything the app does.
8. **Nav/footer IA unverified** (header/footer link text not extractable). App information architecture
   should be re-checked against a real browser capture before locking.
9. **iOS is future scope.** Architecture keeps the door open (Flutter), but no iOS signing, TestFlight,
   or App Store review planning is in this phase.

---

*Stage B will reconcile this document with the actual backend/mobile/admin outputs and mark each
PLANNED item as built, changed, or still pending.*
