# EGT Mobile App Program — PROGRESS.md

Maintained by the build coordinator. Updated at each phase transition.

## Phase status

- [x] PHASE 0 — Site audit (`docs/site-audit.md`) — DONE 2026-09-25 (239 lines, 15 routes, 16 products, 6 forms, 10 assets)
- [x] PHASE 1 — Backend (NestJS) — DONE 2026-09-25 (REAL: 648 pkgs installed, prisma migrate deploy on PG16, 35/35 jest pass, live API smoke test incl. RBAC negatives, 63-path openapi.yaml + @egt/shared types generated)
- [x] PHASE 1 — Mobile (Flutter scaffold) — DONE 2026-09-25 (complete scaffold: 110 lib files/~12.9k lines, 30 screens, 378 l10n keys, bracket/import/l10n audits pass; NOT compiled — Flutter SDK absent, documented in docs/mobile-build.md)
- [ ] PHASE 1 — Admin (React) — DONE 2026-09-25 (REAL build pass: tsc+vite exit 0, 13/13 vitest; API contract marked PENDING-BACKEND pending real openapi.yaml)
- [x] PHASE 1 — Admin API reconciliation — DONE 2026-09-25 (real openapi.yaml consumed; MFA/re-auth/assign/notes removed as no-backend-equivalent; build green, 13/13 tests; response shapes marked UNDECLARED where spec publishes none)
- [x] PHASE 2 — Docs/QA Stage B (api/database/security/security-test-plan/deployment/app-store/runbooks/done-tracker) — DONE 2026-09-25 (8 docs; done-tracker: 8 DONE / 10 PARTIAL / 2 BLOCKED of 20 criteria)

## Phase 0 findings (2026-09-25)

- 15 routes inventoried; 6 live (200): homepage, products.php, quote.php, earn-with-egt.php, contact.php, partner-dashboard.php (not in sitemap). 9 sitemap pages return HTTP 500 (about, catalogue, oem-private-label, sourcing-process, quality-control, shipping-documentation, faq, privacy-policy, terms-and-conditions). refer-and-earn.html is 404. No cart, login, tracking, or dropshipping page exists.
- 16 verified products on products.php. Brief mismatch: Hand Wash, Nitrile Gloves, Packaging Supplies NOT on live site; live adds laundry detergent, bathroom & tile cleaner, biomass pellets, wheat flour, potatoes, cow-dung manure powder.
- 6 forms identified with field lists. No newsletter.
- Brand: red #C8102E, deep red #9E0C24, harbor navy #0D2233, ink #101820; Archivo (display) + DM Sans (body), self-hosted. Logo: 314×153 transparent PNG, "EST. 2024".
- Contacts: phone +91 9876609948 verified; NO published email address found.
- Open question for Sukh: logo says EST. 2024 vs contact page "Export Specialists since 2016" — conflicting; needs his call.
- Ownership exception: mobile child owns docs/mobile-build.md (setup/build docs); docs child owns the rest of docs/**.

## Key decisions

- Flutter chosen as cross-platform framework (Android first, iOS future).
- Backend: NestJS + TypeScript + Prisma + PostgreSQL, modular monolith.
- Admin: React + Vite + TypeScript.
- Contract: backend child generates `packages/shared/openapi.yaml`; mobile/admin consume it.
- Directory ownership is strict: backend child owns `apps/backend/**` + `packages/shared/**`; mobile child owns `apps/mobile/**`; admin child owns `apps/admin/**`; docs child owns `docs/**`.

## Toolchain reality (verified 2026-09-25)

- Node v24.20.0 + npm 10.9.4 available → backend/admin builds and tests can genuinely run.
- Flutter/Dart NOT installed → mobile child scaffolds complete Dart source without faking builds.

## Ground rules given to every child

1. REAL DATA ONLY — all content from the Phase 0 site audit. No invented testimonials/customers/stats/certifications. Dev seeds marked dev-only, never auto-run in prod.
2. Honest done-reporting — never claim deployed/published/build-passed without tool proof. Collect a needs-from-Sukh list instead.
3. No hardcoded secrets — `.env.example` only.
4. Security: server-side RBAC, argon2, rotating refresh tokens, rate limiting, signed doc URLs, audit logs, friendly errors.

## Needs from Sukh (accumulating)

- Google Play Console account + signing keys (release builds)
- Server infrastructure choice (where to host backend/PostgreSQL)
- Independent penetration test (before any production launch)
- Real content decisions (testimonials? stats? supplier TDS/test reports? RFQ pain points? youth commission structure?)
- Approval for a live end-to-end RFQ/contact test when the time comes

## Blockers / risks

- None yet.
