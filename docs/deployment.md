# EGT Deployment Guide

**Status:** dev works locally (Docker Compose + real PG16). Staging and
production are **not provisioned** — every staging/prod step below is
TODO-needs-infra until Sukh decides on server infrastructure. Nothing here has
been run against a remote host.

Related: `docs/api.md` (base URLs), `docs/database.md` (migrations/seeds),
`docs/security.md` (gaps), `docs/runbooks.md` (day-2 operations).

---

## 1. Environments

| | dev | staging | prod |
|---|---|---|---|
| Purpose | local development | pre-release verification, security-test execution | live users |
| API host | `localhost:3000` (docker compose) | **TODO** — suggested `staging-api.eaglegoodstrading.com` | **TODO** — suggested `api.eaglegoodstrading.com` |
| DB | Postgres 16 (docker, `egt-pgdata` volume) | **TODO** — managed Postgres, staging tier | **TODO** — managed Postgres, prod tier, PITR enabled |
| Mobile build | debug APK | internal testing track (Play) — **needs Play Console** | Play release track — **needs keystore + Play Console** |
| Admin hosting | `vite dev` (localhost:5174) | **TODO** — static host behind reverse proxy | **TODO** — static host, same-origin `/api/v1` proxy |
| Seed data | yes (dev-only) | yes (clearly fake) | **never** |
| Secrets | `.env` (local, gitignored) | **TODO** — secret manager | **TODO** — secret manager + rotation |
| Push | log-only | **TODO** — FCM staging project | **TODO** — FCM prod project + APNs (iOS future) |
| Email | logged only | **TODO** — SMTP creds | **TODO** — SMTP creds + verified sender |

Promotion rule: `dev → staging → prod` **only via CI** after the full test
suite passes. No direct deploys from a laptop to staging/prod. Migrations run
automatically on deploy (Docker `CMD`: `prisma migrate deploy`), forward-only.

### 1.1 Dev quick start (works today)

```bash
cd apps/backend
cp .env.example .env        # fill DATABASE_URL + the three *_SECRET values
docker compose up -d postgres
npm install
npx prisma migrate dev
npm run prisma:seed        # dev-only: roles, 16 products, 5 test users
npm run start:dev          # http://localhost:3000 — Swagger at /api/docs
```

Admin (separate terminal):

```bash
cd apps/admin
npm install
npm run dev                # http://localhost:5174 (VITE_API_URL defaults to /api/v1)
```

## 2. CI/CD pipeline

No CI is wired yet. The pipeline below is the target state — add as
`.github/workflows/ci.yml` when a repo host is chosen.

```yaml
name: EGT CI
on:
  push:
    branches: [main]
  pull_request:

jobs:
  backend:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: egt
          POSTGRES_PASSWORD: egt_ci_password
          POSTGRES_DB: egt
        ports: ["5432:5432"]
        options: >-
          --health-cmd "pg_isready -U egt -d egt"
          --health-interval 5s --health-timeout 3s --health-retries 10
    env:
      DATABASE_URL: postgresql://egt:egt_ci_password@localhost:5432/egt?schema=public
      JWT_ACCESS_SECRET: ${{ secrets.CI_JWT_ACCESS_SECRET }}   # ≥32 chars, CI-only
      JWT_REFRESH_SECRET: ${{ secrets.CI_JWT_REFRESH_SECRET }}
      DOCUMENT_SIGNING_SECRET: ${{ secrets.CI_DOC_SIGNING_SECRET }}
      NODE_ENV: test
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 24, cache: npm, cache-dependency-path: apps/backend/package-lock.json }
      - working-directory: apps/backend
        run: |
          npm ci
          npx prisma migrate deploy            # migrations must apply cleanly
          npm run prisma:seed                  # dev-only seed on CI database
          npm test                             # 35 unit tests
          npm run build                        # production build
          npm run openapi:export                # regenerate contract
          git diff --exit-code ../../packages/shared/openapi.yaml  # contract drift fails the build
      - run: npm audit --omit=dev --audit-level=high   # dependency vulnerabilities fail the build

  shared-types:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 24 }
      - working-directory: packages/shared
        run: |
          npm ci
          npm run build        # openapi-typescript codegen must succeed
          npm test || true     # add contract tests when they exist

  admin:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 24, cache: npm, cache-dependency-path: apps/admin/package-lock.json }
      - working-directory: apps/admin
        run: |
          npm ci
          npm test             # 13 vitest
          npm run build        # tsc -b + vite build

  mobile:
    # CONDITIONAL — requires a runner with the Flutter SDK installed.
    # Skipped until Flutter is available in CI (currently absent everywhere).
    if: ${{ vars.FLUTTER_AVAILABLE == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: "3.24.x", channel: stable }
      - working-directory: apps/mobile
        run: |
          flutter pub get
          flutter analyze
          flutter test
          flutter build apk --flavor prod --obfuscate --split-debug-info=build/symbols

  deploy-staging:
    needs: [backend, shared-types, admin]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: staging            # TODO-needs-infra: define secrets/hosts
    steps:
      - run: echo "TODO: deploy backend image + run migrations + deploy admin build"

  deploy-prod:
    needs: [deploy-staging]
    runs-on: ubuntu-latest
    environment: production         # TODO-needs-infra: manual approval gate
    steps:
      - run: echo "TODO: manual-approval deploy after staging sign-off"
```

Notes:

- The **contract-drift check** (`git diff --exit-code` on `openapi.yaml`) is the
  key guard: any controller/DTO change that alters the exported spec without
  committing it fails CI.
- The **mobile job is conditional** — it runs only when a Flutter-capable
  runner exists. Today Flutter is absent on the build machine and no CI runner
  is configured, so this job would be skipped.
- `deploy-staging` / `deploy-prod` are placeholders until infra is chosen.

## 3. Environment config matrix

Backend env vars (from `apps/backend/.env.example` + `src/config/env.ts`).
**Never commit real values; never reuse dev secrets in staging/prod.**

| Variable | dev | staging | prod |
|---|---|---|---|
| `NODE_ENV` | `development` | `staging` (or `production`) | `production` |
| `PORT` | `3000` | `3000` | `3000` (behind proxy) |
| `DATABASE_URL` | local docker PG | managed staging PG | managed prod PG (PITR) |
| `JWT_ACCESS_SECRET` | random ≥32 chars (local) | secret manager | secret manager + rotation |
| `JWT_REFRESH_SECRET` | random ≥32 chars (local) | secret manager | secret manager + rotation |
| `DOCUMENT_SIGNING_SECRET` | random ≥32 chars (local) | secret manager | secret manager + rotation |
| `ACCESS_TOKEN_TTL_SECONDS` | `900` | `900` | `900` |
| `REFRESH_TOKEN_TTL_DAYS` | `30` | `30` | `30` |
| `CORS_ORIGINS` | `http://localhost:3000,http://localhost:5173` | staging admin origin | **production domains** (needs-from-Sukh) |
| `MAX_REQUEST_BODY_MB` | `2` | `2` | `2` |
| `MAX_UPLOAD_MB` | `10` | `10` | `10` |
| `DOCUMENT_STORAGE_DIR` | `/var/lib/egt-documents` (docker volume) | managed disk / object storage | managed disk / object storage (backed up) |
| `DOCUMENT_URL_TTL_MINUTES` | `15` | `15` | `15` |
| `LOGIN_MAX_ATTEMPTS` / `LOGIN_LOCKOUT_MINUTES` | `5` / `15` | `5` / `15` | `5` / `15` |
| `THROTTLE_DEFAULT_TTL` / `THROTTLE_DEFAULT_LIMIT` | `60` / `120` | `60` / `120` | tune under load |
| `SMTP_HOST/PORT/USER/PASS` | empty (emails logged) | **TODO** — SMTP creds | **TODO** — SMTP creds + verified sender |
| `MAIL_FROM` | `noreply@example.com` | real sender | real sender (needs-from-Sukh: real EGT contact email) |
| `APP_PUBLIC_URL` | `http://localhost:3000` | staging URL | production URL (used in email links) |

Admin build-time vars: `VITE_API_URL` (default `/api/v1` — same-origin).

Mobile build-time config: `AppConfig` flavor URLs (placeholders today —
replace with provisioned hosts).

Generate secrets with: `openssl rand -base64 48`.

## 4. Database backup, retention & restore

**Current state:** local docker volume `egt-pgdata` only — **no automated
backups exist**. Everything below is the production target (TODO-needs-infra).

### 4.1 Production backup design (to provision)

- Managed Postgres with **daily automated snapshots** + **point-in-time
  recovery** (PITR), 30-day retention.
- `DOCUMENT_STORAGE_DIR` on a snapshotted volume (or object storage with
  versioning) — files and DB metadata must restore to a consistent point.
- Nightly `pg_dump` (custom format) to off-site storage as a second line:
  `pg_dump -Fc "$DATABASE_URL" -f "egt-$(date +%F).dump"`.

### 4.2 Restore procedure

```bash
# 1. Stop the API (prevent writes)
# 2. Restore the database to a NEW database first (never overwrite in place)
pg_restore -d "postgresql://…/egt_restore" egt-2026-09-25.dump
# 3. Smoke-check row counts on critical tables
psql "$RESTORE_URL" -c "SELECT count(*) FROM \"User\"; SELECT count(*) FROM \"Rfq\";"
# 4. Restore DOCUMENT_STORAGE_DIR from its snapshot to the matching point
# 5. Point DATABASE_URL at the restored DB (blue/green) or rename databases
# 6. Restart the API, run prisma migrate deploy (no-op if schema matches)
# 7. Verify: login, list RFQs, download a document via signed URL
```

### 4.3 Restore drill

Quarterly, on staging: restore the latest prod backup to staging, run the
smoke checks, record the result. First drill is a launch blocker
(see `docs/security-test-plan.md` ST-OPS-04).

## 5. Monitoring, logging & crash reporting

**Current state:** structured console logs only (NestJS default + explicit
error logging in the exception filter and audit service). **No monitoring,
alerting, uptime checks, or crash reporting are wired.**

Production target (TODO-needs-infra):

- **Uptime:** external health checks on `GET /api/docs` or a `/health` endpoint
  (add one — currently the API has no health endpoint; Swagger UI doubles as a
  liveness signal in dev).
- **Logs:** ship JSON logs to a central sink; alert on 5xx spikes and on
  `refresh_reuse` / `user_login_failed` bursts (possible attack).
- **Audit:** `AuditLog` table is queryable via `GET /admin/audit-log`; set up
  periodic review (see runbook "Investigate audit log entries").
- **Mobile:** `AppConfig.enableCrashReporting` flags exist per flavor but **no
  provider is wired** — add Crashlytics/Sentry before the Play release track.
- **Admin:** no RUM; rely on API-side alerting.

## 6. Disaster recovery (summary)

| Scenario | Response |
|---|---|
| DB corruption / accidental delete | Restore from snapshot per §4.2; RPO ≤ 24 h (daily) or minutes (PITR once provisioned) |
| Secret leak (JWT/doc-signing) | Rotate per `docs/runbooks.md` ("Rotate JWT secrets"); all sessions re-login |
| Host loss | Re-provision from Docker image + `prisma migrate deploy` + restore DB + storage snapshot |
| Bad deploy | Roll back to previous image tag; migrations are forward-only — have a tested down-migration or DB restore ready before any destructive migration |
| Document storage loss | Restore volume snapshot; orphaned DB rows (`Document` without file) must be reconciled by staff |

RTO/RPO targets are **undefined until infra is chosen** — set them with Sukh
before production.

## 7. Pre-production checklist (all TODO)

- [ ] Server infra chosen + provisioned (API host, managed Postgres, storage)
- [ ] Production domains + TLS certificates; `CORS_ORIGINS` updated
- [ ] Secrets in a managed vault; dev secrets never reused
- [ ] SMTP credentials + verified sender; verification/reset emails tested end-to-end
- [ ] FCM project (prod) + APNs (iOS future); push tested on device
- [ ] Play Console account + release keystore; `assetlinks.json` for App Links
- [ ] Backups + PITR verified; first restore drill passed
- [ ] Monitoring/alerting wired; on-call defined
- [ ] Security test plan (`docs/security-test-plan.md`) executed — all `Pass`
- [ ] Independent penetration test completed (needs-from-Sukh)
- [ ] Founding-year ("EST. 2024" vs "since 2016") and real contact email decided
- [ ] Admin README stale MFA/idle-lock references fixed
