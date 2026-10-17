# Download

debian-live-13.7.0-amd64-lxqt.iso

https://www.debian.org/CD/live/

# Enalble SSH

su -
apt update
apt install openssh-server -y
systemctl enable --now ssh
systemctl status ssh
ufw allow OpenSSH

# Enable Remote Access

su -
apt install xrdp -y
systemctl enable --now xrdp
systemctl status xrdp
ufw allow 3389/tcp
reboot

# Install qemu agent

sudo apt update
sudo apt install qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent