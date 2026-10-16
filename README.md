# Download Proxmox

Proxmox VE 8.4 ISO Installer
https://www.proxmox.com/en/downloads/proxmox-virtual-environment/iso/proxmox-ve-8-4-iso-installer

# Update

ls -l /etc/resolv.conf

cp /etc/resolv.conf /root/resolv.conf.backup

printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

getent hosts ftp.pt.debian.org
getent hosts security.debian.org

apt update

or

Make the fix permanent
pve2 → System → DNS → Edit
Set the DNS server to 1.1.1.1 and save. You can also use 8.8.8.8 as an alternative.

# Install Alpine Linux 3.21 with docker 

- Get Updates
cat /etc/apk/repositories
apk update

- Install Docker and Compose
apk add docker docker-cli-compose

- Alpine uses OpenRC rather than systemd
rc-update add docker default
rc-service docker start

- Check that Docker is running
rc-service docker status
docker version
docker compose version

- Run a test container
docker run --rm hello-world

- Install git to get the repository
apk add git
cd /opt/
git clone https://github.com/devrazec/proxmox.git

cd /opt/proxmox

git pull
git status

docker compose -f production.yml pull
docker compose -f production.yml up -d
docker compose -f production.yml ps

- Install Dockge to Manage Containers

mkdir -p /opt/stacks /opt/dockge
cd /opt/dockge

wget https://raw.githubusercontent.com/louislam/dockge/master/compose.yaml

docker compose up -d

- Access the Admin Panel

ip addr
http://192.168.2.6:5001/

# Install qemu agent

sudo apt update
sudo apt install qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent

# Install on Q4OS Hyper-V Drivers

sudo apt update
sudo apt full-upgrade -y
sudo reboot

sudo apt install hyperv-daemons
sudo reboot

# Enalble SSH on Q4OS

sudo apt update
sudo apt install openssh-server -y
sudo systemctl enable --now ssh
sudo systemctl status ssh
sudo ufw allow OpenSSH

# Enable Remote Access on Q4OS

sudo apt install xrdp -y
sudo systemctl enable --now xrdp
sudo systemctl status xrdp
sudo ufw allow 3389/tcp
sudo reboot

# Add Linux Q4OS on a Windows Local Domain

sudo apt update
sudo apt install realmd sssd sssd-tools \
  libnss-sss libpam-sss adcli \
  samba-common-bin krb5-user

sudo apt install packagekit samba-common-bin krb5-user -y

sudo realm discover cmviladoporto.lan

sudo realm join --user=cezar.souza cmviladoporto.lan

realm list

sudo apt install cifs-utils smbclient keyutils -y

kinit cezar.souza@CMVILADOPORTO.LAN

klist

# Map Shared Folders from Windows Server

smbclient -L //cmvp2012 -k

mkdir -p ~/Rede/P ~/Rede/R ~/Rede/T ~/Rede/X

sudo apt install libpam-mount cifs-utils keyutils -y

ls -l /etc/security/pam_mount.conf.xml

sudo cp /etc/security/pam_mount.conf.xml \
  /etc/security/pam_mount.conf.xml.bak

Edit pam_mount.conf.xml

<volume fstype="cifs"
        server="intranet"
        path="publico"
        mountpoint="~/Rede/P"
        options="sec=krb5,cruid=%(USERUID),vers=3.0,nosuid,nodev" />

<volume fstype="cifs"
        server="cmvp2012"
        path="trabalho"
        mountpoint="~/Rede/R"
        options="sec=krb5,cruid=%(USERUID),vers=3.0,nosuid,nodev" />

<volume fstype="cifs"
        server="cmvp2012"
        path="trabalho"
        mountpoint="~/Rede/T"
        options="sec=krb5,cruid=%(USERUID),vers=3.0,prefixpath=Informatica,nosuid,nodev" />

<volume fstype="cifs"
        server="cmvp2012"
        path="deposito"
        mountpoint="~/Rede/X"
        options="sec=krb5,cruid=%(USERUID),vers=3.0,nosuid,nodev" />

sudo pam-auth-update

findmnt -t cifs
ls ~/Rede/P
ls ~/Rede/R
ls ~/Rede/T
ls ~/Rede/X

journalctl -b --no-pager | grep -Ei 'pam_mount|cifs|kerberos'