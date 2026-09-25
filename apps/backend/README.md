# EGT Backend — Eagle Goods Trading Co. (NestJS + Prisma + PostgreSQL)

Modular-monolith API for the EGT B2B sourcing/export app. API is versioned at
`/api/v1`. Swagger UI at `/api/docs`.

## Quick start (local dev)

```bash
cp .env.example .env
# fill in DATABASE_URL + the three *_SECRET values (openssl rand -base64 48)

# database (needs Docker) — or point DATABASE_URL at any Postgres 14+
docker compose up -d postgres

npm install
npx prisma migrate dev        # creates DB, applies migrations
npm run prisma:seed           # dev-only seed: roles, categories, 16 audited products, test users
npm run start:dev             # http://localhost:3000, docs at /api/docs
```

## Scripts

| Command | What it does |
|---|---|
| `npm run start:dev` | watch mode |
| `npm run build` / `npm run start:prod` | production build/run |
| `npm test` | jest unit tests (mocked Prisma; no DB needed) |
| `npm run test:cov` | unit tests with coverage |
| `npx prisma migrate dev` | create/apply migrations (local Postgres) |
| `npx prisma migrate deploy` | apply migrations (prod/CI) |
| `npm run prisma:seed` | dev-only seed — **refuses to run with NODE_ENV=production** |
| `npm run openapi:export` | regenerate `packages/shared/openapi.yaml` (the mobile/admin contract) |

## Test users (dev seed only)

| email | password | role |
|---|---|---|
| buyer@example.com | Buyer#12345 | buyer |
| buyer2@example.com | Buyer#12345 | buyer |
| supplier@example.com | Supplier#12345 | supplier |
| staff@example.com | Staff#12345 | staff |
| admin@example.com | Admin#12345 | admin |

## Auth model

- `POST /api/v1/auth/register` (buyer/supplier only — role is coerced server-side)
- `POST /api/v1/auth/verify-email`, `/login`, `/refresh`, `/logout`, `/logout-all`
- `GET /api/v1/auth/sessions`, `DELETE /api/v1/auth/sessions/:id`
- `POST /api/v1/auth/forgot-password`, `/reset-password`
- Access tokens: 15 min JWT. Refresh tokens: 30 d, rotating, SHA-256 stored.
  **Reuse detection:** presenting an already-rotated refresh token revokes the
  whole token family and locks the session.
- Passwords: argon2id. 5 failed logins → 15-min lockout (plus route throttling).

## RBAC

Roles: `buyer`, `supplier`, `staff`, `admin` (guests = unauthenticated).
`JwtAuthGuard` + `RolesGuard` run globally; roles/permissions are resolved from
the **database** on every request — client-sent roles are never trusted.
Buyers see only their own RFQs/orders/quotes/documents/shipments; suppliers see
only their own listings. Admin routes live under `/api/v1/admin/*` (admin only).

## Key business rules (all enforced server-side)

- **RFQ numbers** are transactional yearly-sequential (`EGT-RFQ-2026-000001`):
  allocated with an atomic UPSERT…RETURNING in the same transaction as the
  insert — no gaps on retry, no collisions under concurrency.
- **RFQ lifecycle** is a strict state machine
  (`submitted → under_review → sourcing → supplier_matched → sample_discussion →
  quotation_ready → buyer_action_required → approved → order_processing →
  completed`, plus `closed` from early states). Illegal jumps → 422.
- **Quote acceptance** re-verifies everything at accept time: quote must be
  `sent`, within `validUntil`, caller must own the RFQ, RFQ must be
  `quotation_ready`/`buyer_action_required`. Expired → 422, wrong owner → 403,
  double accept → 409. Accept atomically creates the order + moves RFQ → approved.
- **Supplier listings** start `pending_review` and are **never auto-published**;
  staff/admin review, and reviewers cannot approve their own listings.
- **Documents** live outside the web root with random UUID filenames; downloads
  go through HMAC-signed URLs with 15-min expiry and per-document auth checks.
  10 MB max, allowlisted MIME types.

## Notifications

`NotificationsService.emit(event, userId, …)` persists a row, honours the
user's per-event-type preferences, and fans out to registered device tokens via
a `PushProvider` interface. Development uses `LogPushProvider` (logs only) —
swap in FCM/APNs when keys are available. Event types: `rfq_status_changed`,
`quote_available`, `quote_revision_requested`, `order_status_changed`,
`shipment_update`, `document_uploaded`, `security_alert`, `ticket_reply`,
`message_received`.

## Errors & pagination

- Errors: `{ code, message, details? }` — friendly messages, never stack traces.
- Lists: `{ data, page, limit, total }`.

## Product data

The catalogue is seeded **only** with the 16 products verified in
`docs/site-audit.md` (names/categories/specs/order volumes verbatim). The three
compliance bullets flagged as unverified in the audit (ISO/GMP, FSSAI/APEDA,
APEDA/GlobalG.A.P.) are deliberately excluded. No prices are published —
pricing happens via quotation, as on the live site.

## What's NOT included / needs decisions

See the build coordinator's done-tracker: SMTP credentials (verification/reset
emails currently only logged), FCM/APNs keys (push is log-only in dev),
production hosting decision, and a real contact email address (the audit found
none published on the site).
