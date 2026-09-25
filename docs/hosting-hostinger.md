# EGT on Hostinger — staging runbook

**Decision (2026-09-25, Sukh): host the platform on Hostinger.**
Target state for this runbook: **staging** on a Hostinger KVM VPS.

## 0. Why a VPS, not the current plan

The site currently runs on **Premium Web Hosting (shared)**. Shared hosting is
PHP/MySQL only:

- it **cannot** run a persistent Node.js process (the NestJS API),
- it has **no PostgreSQL** (MySQL/MariaDB only),
- it cannot run Prisma migrations or a document-signing file store properly.

So the API + PostgreSQL need a **Hostinger VPS (KVM)** — full root access,
Ubuntu, we install everything. The existing shared plan keeps running the
public website untouched; nothing on the live site changes.

Recommended for staging: **KVM 1** — 1 vCPU, 4 GB RAM, 50 GB NVMe
(~$5–6.50/mo intro). Plenty for API + PostgreSQL 16 + nginx at staging load.
Production later: KVM 2+ on a separate VPS or a resized plan.

Files prepared for this runbook (all in-repo):

| file | purpose |
|---|---|
| `apps/backend/deploy/hostinger/vps-setup.sh` | one-shot server setup (run once as root) |
| `apps/backend/deploy/hostinger/egt-api.service` | systemd unit |
| `apps/backend/deploy/hostinger/nginx-staging-api.conf` | nginx reverse proxy |
| `apps/backend/deploy/hostinger/deploy.sh` | repeatable release deploy |

## 1. Sukh's steps in hPanel (only you can do these)

1. **Buy the VPS**: hPanel → VPS → KVM 1. OS **Ubuntu 24.04**,
   datacenter **Mumbai** (closest to Punjab), hostname `egt-staging`.
2. **SSH access** (pick one):
   - *Recommended:* paste this public key into the VPS SSH-key manager so
     the assistant can deploy over SSH without any password:
     ```
     ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL9GNDhI7WwAVMjIzoRdmf0+ARN44CU0xtPfuvbNq4CK hatch
     ```
     (A public key is safe to share — it cannot be used to log in anywhere
     by itself; it only *authorizes* this assistant's private key.)
   - *Alternative:* set a strong root password and share it via the Secure
     Vault (never in chat).
3. **Note the VPS IP address** shown in hPanel and send it here.
4. **DNS**: add an A record in the eaglegoodstrading.com DNS zone:
   `staging-api.eaglegoodstrading.com` → `<VPS IP>`.
   (The assistant can also do this via the hPanel DNS editor once told.)

## 2. Assistant's steps over SSH (after access works)

1. Upload + run `vps-setup.sh` as root → Node 24, PostgreSQL 16, nginx,
   certbot, UFW (SSH + HTTP/S only), `egt` user, `egt_staging` database.
   **Save the printed DB password into the vault** — shown once.
2. Build the API release tarball locally (`npm ci`, `npm run build`,
   `npx prisma generate`), upload, run `deploy.sh` as root.
3. Create `/opt/egt/api/.env` (staging): `NODE_ENV=staging`,
   `PORT=3000`, `DATABASE_URL` (vault password), three `*_SECRET` values
   generated on-server via `openssl rand -base64 48`,
   `CORS_ORIGINS=https://staging-admin.eaglegoodstrading.com`,
   `DOCUMENT_STORAGE_DIR=/var/lib/egt-documents`. **Never commit this file.**
4. Install `egt-api.service` → `systemctl enable --now egt-api`.
5. Install the nginx vhost, `certbot --nginx -d staging-api.eaglegoodstrading.com`.
6. Serve the admin dashboard (static `dist/`) from the same VPS at
   `staging-admin.eaglegoodstrading.com` (second A record + nginx static vhost).
7. Verify: `GET /api/v1/health` (or docs ping), Swagger at `/api/docs`,
   register → login → create RFQ → staff transition smoke test,
   `prisma migrate` status clean, UFW active, fail2ban running.
8. Backups: Hostinger weekly VPS snapshots **plus** a nightly
   `pg_dump egt_staging` cron to `/var/backups/egt` (copied offsite later).

## 3. Verify checklist (before calling staging "up")

- [ ] `https://staging-api.eaglegoodstrading.com/api/docs` loads (Swagger)
- [ ] register + login returns JWT; wrong password 5× locks the account
- [ ] buyer creates RFQ → 201; staff moves it forward; illegal jump → 422
- [ ] buyer B cannot read buyer A's RFQ → 403
- [ ] admin dashboard loads against staging API, RBAC nav correct
- [ ] `systemctl status egt-api` active; logs flowing to /var/log/egt-api/
- [ ] UFW enabled; only 22/80/443 open

## 4. Rollback

`deploy.sh` keeps the previous build at `/opt/egt/api/dist.prev`:
`mv /opt/egt/api/dist.prev /opt/egt/api/dist && systemctl restart egt-api`.
Migrations are forward-only; a bad migration is fixed by a new forward
migration, never by editing history.

## 5. Still needed after staging (not Hostinger's job)

- Google Play Console account + Android signing keystore (mobile release)
- FCM project + APNs (push notifications)
- SMTP credentials + real EGT contact email
- Independent penetration test before any production claim
- Flutter SDK build + physical-device testing
