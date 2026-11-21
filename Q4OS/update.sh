#!/usr/bin/env bash
#
# Update the Next.js app on Q4OS: pull the latest code from git, rebuild it
# and restart the server.
#
# Usage (run as the normal user, not with sudo; it asks for sudo itself):
#   bash update.sh
#
set -euo pipefail

APP_DIR="/opt/q4os-app"
SERVICE="nextjs"

if [[ $EUID -eq 0 ]]; then
    echo "Run as the normal user (not root): bash $0" >&2
    exit 1
fi

cd "$APP_DIR"

echo "==> Pulling latest code"
git pull --ff-only

if [[ ! -f package.json ]]; then
    echo "No package.json in ${APP_DIR}; nothing to build." >&2
    exit 1
fi

echo "==> Installing dependencies"
npm install

echo "==> Building"
npm run build

echo "==> Restarting ${SERVICE}"
sudo systemctl restart "$SERVICE"

sleep 2
printf '%s is %s\n' "$SERVICE" "$(systemctl is-active "$SERVICE" || true)"
echo "Done. Reload the browser (Ctrl+Shift+R) to see the changes."
