#!/usr/bin/env bash
#
# Post-install script for Q4OS 6.10 (Debian 13 based)
# Sets the computer name to q4osclient and installs/enables: OpenSSH server,
# x11vnc (VNC) and Samba (share "Users"), plus Node.js, git and
# Visual Studio Code.
#
# Usage:
#   sudo bash script.sh
#   sudo VNC_PASSWORD='other' bash script.sh          # override default (adminq12)
#
set -euo pipefail

VNC_PORT=5900

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root: sudo bash $0" >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# VNC password (override with the VNC_PASSWORD env var)
VNC_PASSWORD="${VNC_PASSWORD:-adminq12}"

NEW_HOSTNAME="q4osclient"
SHARE_NAME="Users"
SHARE_PATH="/home"   # Linux equivalent of the "Users" folder
# User that will access the share (the user who ran sudo)
SMB_USER="${SUDO_USER:-adminq}"
SMB_PASSWORD="${SMB_PASSWORD:-adminq12}"

# Next.js app served over HTTPS (nginx -> Next.js on localhost)
APP_REPO="https://github.com/devrazec/q4os"
APP_DIR="/opt/q4os-app"
APP_PORT=3000
APP_USER="$SMB_USER"
APP_SHARE_NAME="Apps"

# ---------------------------------------------------------------- Hostname
echo "==> Setting computer name to ${NEW_HOSTNAME}"
hostnamectl set-hostname "$NEW_HOSTNAME"
if grep -q '^127\.0\.1\.1' /etc/hosts; then
    sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t${NEW_HOSTNAME}/" /etc/hosts
else
    printf '127.0.1.1\t%s\n' "$NEW_HOSTNAME" >> /etc/hosts
fi

echo "==> Updating package lists"
apt-get update

echo "==> Installing openssh-server, x11vnc and samba"
apt-get install -y openssh-server x11vnc samba

# ---------------------------------------------------------------- Dev tools
echo "==> Installing Node.js, npm and git"
apt-get install -y nodejs npm git

echo "==> Installing Visual Studio Code (Microsoft repo)"
apt-get install -y wget gpg ca-certificates
install -d -m 0755 /etc/apt/keyrings
wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor --yes -o /etc/apt/keyrings/packages.microsoft.gpg
chmod 644 /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    > /etc/apt/sources.list.d/vscode.list
apt-get update
apt-get install -y code

# ---------------------------------------------------------------- Next.js + HTTPS
echo "==> Installing nginx and openssl"
apt-get install -y nginx openssl

echo "==> Deploying Next.js project from ${APP_REPO}"
# /opt is root-owned, so create the app folder as root and hand it to the user
mkdir -p "$APP_DIR"
chown "${APP_USER}:${APP_USER}" "$APP_DIR"
if [[ -d "$APP_DIR/.git" ]]; then
    sudo -u "$APP_USER" git -C "$APP_DIR" pull --ff-only
else
    sudo -u "$APP_USER" git clone "$APP_REPO" "$APP_DIR"
fi
chown -R "${APP_USER}:${APP_USER}" "$APP_DIR"

cat > /etc/systemd/system/nextjs.service <<EOF
[Unit]
Description=Next.js app (q4os)
After=network.target

[Service]
Type=simple
User=${APP_USER}
WorkingDirectory=${APP_DIR}
Environment=NODE_ENV=production
Environment=PORT=${APP_PORT}
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
# Enabled now so it starts automatically on every boot
systemctl enable nextjs

if [[ -f "$APP_DIR/package.json" ]]; then
    sudo -u "$APP_USER" bash -c "cd '$APP_DIR' && npm install && npm run build"
    systemctl restart nextjs
else
    echo "WARNING: no package.json in ${APP_REPO}; build skipped, nextjs will start on boot once the project exists." >&2
fi

echo "==> Configuring nginx HTTPS reverse proxy"
mkdir -p /etc/nginx/ssl
CERT=/etc/nginx/ssl/q4os.crt
CERT_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
# (Re)generate if missing or if it predates the localhost/IP names
if [[ ! -f $CERT ]] || ! openssl x509 -noout -ext subjectAltName -in "$CERT" 2>/dev/null | grep -q 'localhost'; then
    SAN="DNS:${NEW_HOSTNAME},DNS:${NEW_HOSTNAME}.local,DNS:localhost,IP:127.0.0.1"
    [[ -n $CERT_IP ]] && SAN+=",IP:${CERT_IP}"
    openssl req -x509 -nodes -newkey rsa:2048 -days 825 \
        -keyout /etc/nginx/ssl/q4os.key -out "$CERT" \
        -subj "/CN=${NEW_HOSTNAME}" \
        -addext "subjectAltName=${SAN}"
    chmod 600 /etc/nginx/ssl/q4os.key
fi

# Trust the certificate on this machine (system store + the user's browser DB)
cp "$CERT" /usr/local/share/ca-certificates/q4os.crt
update-ca-certificates
apt-get install -y libnss3-tools
NSS_DB="$(getent passwd "$APP_USER" | cut -d: -f6)/.pki/nssdb"
sudo -u "$APP_USER" mkdir -p "$NSS_DB"
[[ -f $NSS_DB/cert9.db ]] || sudo -u "$APP_USER" certutil -N -d "sql:${NSS_DB}" --empty-password
sudo -u "$APP_USER" certutil -D -d "sql:${NSS_DB}" -n q4os 2>/dev/null || true
sudo -u "$APP_USER" certutil -A -d "sql:${NSS_DB}" -n q4os -t "C,," -i "$CERT"

cat > /etc/nginx/sites-available/nextjs <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    ssl_certificate     /etc/nginx/ssl/q4os.crt;
    ssl_certificate_key /etc/nginx/ssl/q4os.key;

    location / {
        proxy_pass http://127.0.0.1:${APP_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/nextjs /etc/nginx/sites-enabled/nextjs
nginx -t
systemctl enable nginx
systemctl restart nginx

# ---------------------------------------------------------------- Browser autostart
echo "==> Enabling fullscreen browser autostart (Chromium is installed separately)"
apt-get install -y curl

# Launcher: wait until the site answers, then open it fullscreen.
# (kiosk mode: fullscreen, no tabs or address bar; exit with Alt+F4)
cat > /usr/local/bin/q4os-browser <<'EOF'
#!/usr/bin/env bash
exec >>"$HOME/q4os-browser.log" 2>&1
echo "--- $(date) starting"
export DISPLAY="${DISPLAY:-:0}"
until curl -sk -o /dev/null https://localhost; do sleep 2; done
BROWSER=$(command -v chromium || command -v chromium-browser) || { echo "Chromium is not installed" >&2; exit 1; }
exec "$BROWSER" --kiosk --no-first-run --no-default-browser-check \
    --password-store=basic --disable-features=Translate,SigninIntercept \
    https://localhost
EOF
chmod 755 /usr/local/bin/q4os-browser

APP_HOME="$(getent passwd "$APP_USER" | cut -d: -f6)"
# TDE (Trinity) reads ~/.trinity/Autostart; this is what its Autostart Manager edits
TDE_AUTOSTART="${APP_HOME}/.trinity/Autostart"
sudo -u "$APP_USER" mkdir -p "$TDE_AUTOSTART"
cat > "${TDE_AUTOSTART}/q4os-browser.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Q4OS Browser
Exec=/usr/local/bin/q4os-browser
Terminal=false
EOF
chown "${APP_USER}:${APP_USER}" "${TDE_AUTOSTART}/q4os-browser.desktop"

# ---------------------------------------------------------------- SSH
echo "==> Enabling SSH"
systemctl enable --now ssh

# ---------------------------------------------------------------- VNC
echo "==> Configuring x11vnc"
mkdir -p /etc/x11vnc
x11vnc -storepasswd "$VNC_PASSWORD" /etc/x11vnc/passwd
chmod 600 /etc/x11vnc/passwd

cat > /etc/systemd/system/x11vnc.service <<EOF
[Unit]
Description=VNC Remote Access - Login Screen
After=display-manager.service
Wants=display-manager.service

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -display :0 -auth guess -forever -shared -rfbauth /etc/x11vnc/passwd -rfbport ${VNC_PORT} -noxdamage
Restart=always
RestartSec=5

[Install]
WantedBy=graphical.target
EOF

systemctl daemon-reload
systemctl enable x11vnc
systemctl restart x11vnc

# ---------------------------------------------------------------- Samba
echo "==> Configuring Samba share '${SHARE_NAME}' (${SHARE_PATH})"
# /home is a system directory: don't change its owner or permissions
mkdir -p "$SHARE_PATH"

if ! grep -q "^\[${SHARE_NAME}\]" /etc/samba/smb.conf; then
    cp -n /etc/samba/smb.conf /etc/samba/smb.conf.bak
    cat >> /etc/samba/smb.conf <<EOF

[${SHARE_NAME}]
   path = ${SHARE_PATH}
   browseable = yes
   read only = no
   valid users = ${SMB_USER}
   create mask = 0664
   directory mask = 2775
EOF
fi

# Disable the default [homes] share (shows up as a folder named after the user)
cp -n /etc/samba/smb.conf /etc/samba/smb.conf.bak
awk '
    /^\[/ { in_homes = ($0 == "[homes]") }
    in_homes && !/^[;#]/ && NF { print ";" $0; next }
    { print }
' /etc/samba/smb.conf > /etc/samba/smb.conf.new
mv /etc/samba/smb.conf.new /etc/samba/smb.conf

# Second share: the Next.js project folder
if ! grep -q "^\[${APP_SHARE_NAME}\]" /etc/samba/smb.conf; then
    cat >> /etc/samba/smb.conf <<EOF

[${APP_SHARE_NAME}]
   path = ${APP_DIR}
   browseable = yes
   read only = no
   valid users = ${SMB_USER}
   force user = ${APP_USER}
   create mask = 0664
   directory mask = 2775
EOF
fi

testparm -s >/dev/null
printf '%s\n%s\n' "$SMB_PASSWORD" "$SMB_PASSWORD" | smbpasswd -s -a "$SMB_USER"
systemctl enable smbd nmbd
systemctl restart smbd nmbd

# ---------------------------------------------------------------- Firewall
if command -v ufw >/dev/null 2>&1; then
    echo "==> Opening firewall ports (ufw)"
    ufw allow OpenSSH
    ufw allow ${VNC_PORT}/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 139/tcp
    ufw allow 445/tcp
fi

# ---------------------------------------------------------------- Summary
echo
echo "==> Service status"
for svc in ssh x11vnc smbd nginx nextjs; do
    printf '%-8s enabled=%-9s active=%s\n' "$svc" \
        "$(systemctl is-enabled "$svc" 2>/dev/null || true)" \
        "$(systemctl is-active "$svc" 2>/dev/null || true)"
done

IP=$(hostname -I 2>/dev/null | awk '{print $1}')
echo
echo "Done. Connect with:"
echo "  SSH: ssh <user>@${IP:-<ip>}"
echo "  VNC: ${IP:-<ip>}:${VNC_PORT}"
echo "  WEB: https://${IP:-<ip>}  (self-signed certificate)"
echo "  SMB:\\\\${NEW_HOSTNAME}\\${SHARE_NAME}  (user: ${SMB_USER})"
echo "  SMB:\\\\${NEW_HOSTNAME}\\${APP_SHARE_NAME}  (Next.js project folder)"
echo
echo "A reboot is recommended: sudo reboot"
