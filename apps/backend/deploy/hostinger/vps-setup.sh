#!/usr/bin/env bash
#
# EGT API — Hostinger VPS one-shot setup (staging)
# Run ONCE as root on a fresh Hostinger KVM VPS (Ubuntu 24.04).
#   curl -fsSL <this-file-url> -o vps-setup.sh   # or upload via scp
#   chmod +x vps-setup.sh && ./vps-setup.sh
#
# What it does: Node 24, PostgreSQL 16, nginx, certbot, UFW firewall,
# app user `egt`, directories, staging database + role (password printed ONCE).
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then echo "Run as root."; exit 1; fi
export DEBIAN_FRONTEND=noninteractive

echo "==> apt update/upgrade"
apt-get update -qq
apt-get upgrade -y -qq

echo "==> Node.js 24 (NodeSource)"
curl -fsSL https://deb.nodesource.com/setup_24.x | bash - >/dev/null
apt-get install -y -qq nodejs
node --version

echo "==> PostgreSQL 16 + nginx + certbot + firewall"
apt-get install -y -qq postgresql-16 postgresql-contrib nginx certbot python3-certbot-nginx ufw fail2ban
systemctl enable --now postgresql nginx

echo "==> UFW firewall (SSH + HTTP/S only)"
ufw allow OpenSSH >/dev/null
ufw allow 'Nginx Full' >/dev/null
ufw --force enable >/dev/null
ufw status | head -8

echo "==> app user + directories"
id -u egt &>/dev/null || useradd -m -s /bin/bash egt
mkdir -p /opt/egt/api /opt/egt/releases /var/lib/egt-documents /var/log/egt-api /var/backups/egt
chown -R egt:egt /opt/egt /var/lib/egt-documents /var/log/egt-api
chmod 750 /var/lib/egt-documents

echo "==> PostgreSQL: role + staging database"
DB_PASS="$(openssl rand -hex 24)"
sudo -u postgres psql -v ON_ERROR_STOP=1 <<EOF
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'egt_api') THEN
    CREATE ROLE egt_api LOGIN PASSWORD '$DB_PASS';
  END IF;
END
\$\$;
EOF
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='egt_staging'" | grep -q 1; then
  sudo -u postgres psql -c "CREATE DATABASE egt_staging OWNER egt_api" >/dev/null
fi
# Harden: egt_api cannot create DBs/roles
sudo -u postgres psql -c "ALTER ROLE egt_api NOCREATEDB NOCREATEROLE;" >/dev/null

echo ""
echo "==============================================================="
echo " SETUP COMPLETE"
echo "---------------------------------------------------------------"
echo " PostgreSQL staging DB : egt_staging"
echo " PostgreSQL user       : egt_api"
echo " PostgreSQL password   : $DB_PASS"
echo "   ^^^ SAVE THIS IN YOUR VAULT NOW — it is shown only once."
echo " App directory         : /opt/egt/api  (owner: egt)"
echo " Document storage      : /var/lib/egt-documents"
echo " Next: upload the API tarball and run deploy/hostinger/deploy.sh"
echo "==============================================================="
