# EGT staging — free tier runbook (Neon + Render)

**Decision (2026-09-25, Sukh): free staging instead of a paid Hostinger VPS.**
Cost: **₹0/month**. Live URLs after deploy:

- API: `https://egt-api-staging.onrender.com` (docs at `/api/docs`)
- Admin: `https://egt-admin-staging.onrender.com`

Honest limits (staging only): the API sleeps after 15 min idle (first request
after a break takes ~30–60s); uploaded documents vanish on redeploy (ephemeral
disk); Neon free DB is 0.5 GB. Good for end-to-end testing, not for real users.

Prepared in-repo: `render.yaml` (Render blueprint), `Dockerfile` (runs
`prisma migrate deploy` on boot), `GET /api/v1/health` liveness probe.

## 1. Sukh's steps (about 10 minutes, all clicks — no secrets shared in chat)

1. **Neon (free PostgreSQL)** — sign up at neon.tech (free tier, no card):
   - New Project → name `egt-staging`, region **AWS Asia Pacific (Mumbai)**
     if offered, PostgreSQL 16.
   - On the dashboard, copy the **direct (non-pooled)** connection string.
     It looks like `postgresql://user:password@ep-xxx.aws.neon.tech/dbname?sslmode=require`.
     Keep it handy for step 4 — you paste it into Render yourself, so the
     password never passes through chat.
2. **GitHub repo** — create an empty repo named `egt-platform` (private is fine).
3. **Give the assistant push access** — GitHub → Settings → SSH and GPG keys →
   New SSH key, paste this public key (safe to share — it only *authorizes*
   this assistant, it can't log in anywhere by itself):
   ```
   ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL9GNDhI7WwAVMjIzoRdmf0+ARN44CU0xtPfuvbNq4CK hatch
   ```
   Then send the repo URL (e.g. `git@github.com:YOURNAME/egt-platform.git`).
4. **Render (free)** — sign up at render.com (free, GitHub login is easiest):
   - New → **Blueprint** → connect the `egt-platform` repo → Render detects
     `render.yaml`.
   - When prompted for `DATABASE_URL`, paste the Neon connection string
     from step 1. The three `*_SECRET` values generate automatically.
   - Click **Apply**. First deploy takes ~5–10 min (Docker build).

## 2. Assistant's steps (after the repo URL arrives)

1. `git init` / push the monorepo (`apps/backend`, `apps/admin`,
   `render.yaml`, docs) to his repo via the added SSH key.
2. Verify live: `GET /api/v1/health` → `{"status":"ok"}`.
3. Smoke test against staging: register → login → create RFQ → staff
   transition → illegal transition rejected (422) → cross-user read (403).
4. Confirm admin dashboard loads and talks to the staging API.
5. Report the live URLs + any issues.

## 3. Verify checklist

- [ ] `https://egt-api-staging.onrender.com/api/v1/health` returns ok
- [ ] Swagger loads at `/api/docs`
- [ ] register + login works; 5 wrong passwords lock the account
- [ ] buyer creates RFQ → 201; staff advances it; illegal jump → 422
- [ ] buyer B cannot read buyer A's RFQ → 403
- [ ] admin site loads, dashboard talks to the API (CORS OK)

## 4. Notes / troubleshooting

- **Cold starts**: normal on free tier. If the first tap is slow, wait ~60s
  and retry — the instance is waking up.
- **Secret length**: the API requires `*_SECRET` ≥ 32 chars. Render's
  generated values satisfy this; if the service crashes at boot with a zod
  error naming a secret, regenerate that env var in the Render dashboard.
- **Neon pooled vs direct**: use the *direct* connection string. The pooled
  (PgBouncer) URL needs extra Prisma flags — not worth it for staging.
- **Uploads**: documents uploaded to staging disappear on redeploy. Never
  use staging uploads as real records.
- **Never** run the dev seed against this database (seed is dev-only and
  guarded, but say it anyway).
