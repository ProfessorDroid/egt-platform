#!/usr/bin/env bash
#
# EGT API — deploy a release tarball on the Hostinger VPS (staging).
# Run as the `egt` user (or root; it re-execs via su for npm steps):
#   ./deploy.sh /tmp/egt-api-20260925.tar.gz
#
# Tarball layout (built on the build machine with `npm run build` already run
# OR built here — this script handles both):
#   dist/  node_modules excluded; includes: package.json, package-lock.json,
#   prisma/, dist/ (optional), src/ (if building here)
#
# Steps: extract -> npm ci -> prisma generate -> prisma migrate deploy ->
#        build (if needed) -> keep previous dist as rollback -> restart service.
set -euo pipefail

TARBALL="${1:?usage: deploy.sh <tarball>}"
APP_DIR=/opt/egt/api
RELEASES=/opt/egt/releases
STAMP="$(date +%Y%m%d-%H%M%S)"

if [ "$(id -u)" -eq 0 ]; then
  # Re-run as egt for everything except the final systemctl restart.
  cp "$TARBALL" /tmp/egt-deploy.tar.gz
  chown egt:egt /tmp/egt-deploy.tar.gz
  su egt -c "$0 /tmp/egt-deploy.tar.gz"
  systemctl restart egt-api
  systemctl is-active --quiet egt-api && echo "egt-api restarted OK" || { echo "egt-api FAILED to start — check journalctl -u egt-api"; exit 1; }
  exit 0
fi

echo "==> extracting $TARBALL"
mkdir -p "$RELEASES/$STAMP"
tar -xzf "$TARBALL" -C "$RELEASES/$STAMP"
cd "$RELEASES/$STAMP"

echo "==> npm ci (production)"
npm ci --omit=dev --no-audit --no-fund

echo "==> prisma generate + migrate deploy"
npx prisma generate
npx prisma migrate deploy

if [ ! -d dist ]; then
  echo "==> building (dist/ not in tarball)"
  npm ci --no-audit --no-fund   # devDeps needed for nest build
  npm run build
  npm prune --omit=dev
fi

echo "==> swapping into $APP_DIR (previous kept as rollback)"
if [ -d "$APP_DIR/dist" ]; then
  rm -rf "$APP_DIR/dist.prev"
  mv "$APP_DIR/dist" "$APP_DIR/dist.prev"
fi
# Keep the live .env — never overwrite it from a release.
cp -a "$RELEASES/$STAMP/." "$APP_DIR/"
rm -rf "$RELEASES/$STAMP"

echo "==> quick smoke: does dist/main.js exist and parse?"
node --check "$APP_DIR/dist/main.js" && echo "dist/main.js OK"

echo "DEPLOY STAGED — service restart is handled by the root wrapper."
echo "Rollback: mv $APP_DIR/dist.prev $APP_DIR/dist && systemctl restart egt-api"
