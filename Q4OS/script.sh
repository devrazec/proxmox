#!/usr/bin/env bash
#
# Post-install script for Q4OS 6.10 (Debian 13 based)
# Sets the computer name to q4osclient and installs/enables: OpenSSH server,
# xrdp (RDP), x11vnc (VNC) and Samba (share "install").
#
# Usage:
#   sudo bash script.sh
#   sudo VNC_PASSWORD='other' bash script.sh          # override default (adminq12)
#
set -euo pipefail

VNC_PORT=5900
RDP_PORT=3389

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root: sudo bash $0" >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# VNC password (override with the VNC_PASSWORD env var)
VNC_PASSWORD="${VNC_PASSWORD:-adminq12}"

NEW_HOSTNAME="q4osclient"
SHARE_NAME="install"
SHARE_PATH="/srv/install"
# User that will access the share (the user who ran sudo)
SMB_USER="${SUDO_USER:-adminq}"
SMB_PASSWORD="${SMB_PASSWORD:-adminq12}"

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

echo "==> Installing openssh-server, xrdp, x11vnc and samba"
apt-get install -y openssh-server xrdp xorgxrdp x11vnc samba

# ---------------------------------------------------------------- SSH
echo "==> Enabling SSH"
systemctl enable --now ssh

# ---------------------------------------------------------------- XRDP
echo "==> Enabling xrdp"
# xrdp needs access to the TLS key
adduser --quiet xrdp ssl-cert || true
systemctl enable --now xrdp

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
ExecStart=/usr/bin/x11vnc -display :0 -auth guess -forever -loop 10 -shared -rfbauth /etc/x11vnc/passwd -rfbport ${VNC_PORT} -noxdamage
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
mkdir -p "$SHARE_PATH"
chown "${SMB_USER}:${SMB_USER}" "$SHARE_PATH"
chmod 2775 "$SHARE_PATH"

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

testparm -s >/dev/null
printf '%s\n%s\n' "$SMB_PASSWORD" "$SMB_PASSWORD" | smbpasswd -s -a "$SMB_USER"
systemctl enable smbd nmbd
systemctl restart smbd nmbd

# ---------------------------------------------------------------- Firewall
if command -v ufw >/dev/null 2>&1; then
    echo "==> Opening firewall ports (ufw)"
    ufw allow OpenSSH
    ufw allow ${RDP_PORT}/tcp
    ufw allow ${VNC_PORT}/tcp
    ufw allow 139/tcp
    ufw allow 445/tcp
fi

# ---------------------------------------------------------------- Summary
echo
echo "==> Service status"
for svc in ssh xrdp x11vnc smbd; do
    printf '%-8s enabled=%-9s active=%s\n' "$svc" \
        "$(systemctl is-enabled "$svc" 2>/dev/null || true)" \
        "$(systemctl is-active "$svc" 2>/dev/null || true)"
done

IP=$(hostname -I 2>/dev/null | awk '{print $1}')
echo
echo "Done. Connect with:"
echo "  SSH: ssh <user>@${IP:-<ip>}"
echo "  RDP: ${IP:-<ip>}:${RDP_PORT}"
echo "  VNC: ${IP:-<ip>}:${VNC_PORT}"
echo "  SMB: \\\\${NEW_HOSTNAME}\\${SHARE_NAME}  (user: ${SMB_USER})"
echo
echo "A reboot is recommended: sudo reboot"
