# EGT Admin Dashboard

React 18 + Vite + TypeScript admin console for Eagle Goods Trading Co. — the back-office for the EGT mobile app program.

## Run

```bash
npm install
npm run dev      # http://localhost:5174
npm run build    # typecheck + production build
npm test         # vitest unit tests (RBAC guards, API error mapping)
```

## Backend contract (PENDING)

Reconciled 2026-09-25 against the real `packages/shared/openapi.yaml` (63 paths). Notable: the spec publishes **zero response schemas**, so all response interfaces in `src/api/types.ts` are marked `UNDECLARED-RESPONSE-SHAPE` (best-effort field guesses; the client normalizes list responses to accept array-or-paged-object). Features with no backend equivalent were **removed, not stubbed**: TOTP MFA, idle lock screen, re-authentication, RFQ assign/notes/request-info, product delete + image management, supplier account management, per-order document listing, shipment milestone quick-set, ticket resolution text. If the backend later adds these endpoints, reintroduce the UI.

Expected base URL: `VITE_API_URL` (see `.env.example`; defaults to `/api/v1`).

## Auth & security

- Email + password login (`/auth/login`); refresh via `/auth/refresh {refreshToken}`; logout `/auth/logout`.
- Sessions are own-only: `GET /auth/sessions`, `DELETE /auth/sessions/{id}` ("My sessions" in the account area).
- Access token in memory, refresh token in `sessionStorage`; silent refresh on 401; 15-minute idle **signs out** (no lock screen — no backend endpoint supports it).
- **No MFA, no re-authentication**: the real API has no `/auth/mfa/*` or `/auth/reauth` endpoints (removed 2026-09-25 reconciliation).
- RBAC: `admin` sees everything; `staff` sees dashboard / RFQs / products / suppliers / orders / shipments / documents / support — users & audit logs are hidden in nav **and** blocked by route guards.

## Modules

Dashboard (BI widgets from live API data only — empty state when absent) · RFQs (list/filter, detail, **state-machine-constrained transitions** via `POST /rfqs/{id}/transition {to}`, buyer conversation through `/conversations`, quotation form via `POST /quotes`) · Products (update name/description/orderVolume/active/featured via `PATCH /products/{id}` — **no delete, no image endpoints**; detail addressed by slug) · Suppliers (**listing review queue**: `GET /suppliers/pending` + `PATCH /suppliers/listings/{id}/review`) · Orders (status via `PATCH /orders/{id}/status`, documents via `/documents/upload`) · Shipments (event timeline from detail's inline events; `POST` events `{status,location?,note?}`) · Users (roles via `PATCH /admin/users/{id}/role`, enable/disable via `PATCH /admin/users/{id}/active` toggle) · Documents (upload tool + signed-URL download — **no vault listing endpoint**) · Support tickets (`/support/tickets/*`; triage/reply/close via status PATCH) · Audit log (`GET /admin/audit-log`).

## Brand

Tokens match the live site's `assets/css/egt-ds-2026.css`: red `#C8102E`, deep red `#9E0C24`, harbor navy `#0D2233`, ink `#101820`, Archivo (display) + DM Sans (body).

### Fonts (self-hosted, same as the main site)

The CSS references the same woff2 approach as the website. Copy these files from the site's `assets/fonts/` into this app's `public/fonts/`:

- `public/fonts/archivo/archivo-latin.woff2` ← site `assets/fonts/archivo/archivo-latin.woff2`
- `public/fonts/dm-sans/dm-sans-latin.woff2` ← site `assets/fonts/dm-sans/dm-sans-latin.woff2`

Until they are copied, the UI falls back to system fonts — no build or runtime error.

### Logo

`public/brand/egt-logo.png` (already present) is used on the login card and the sidebar.
