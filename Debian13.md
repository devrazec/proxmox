# Download

debian-live-13.7.0-amd64-lxqt.iso

https://www.debian.org/CD/live/

# Enalble SSH

sudo apt update
sudo apt install openssh-server -y
sudo systemctl enable --now ssh
sudo systemctl status ssh
sudo ufw allow OpenSSH

# Enable Remote Access

sudo apt install xrdp -y
sudo systemctl enable --now xrdp
sudo systemctl status xrdp
sudo ufw allow 3389/tcp
sudo reboot