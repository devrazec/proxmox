# Install Q4OS 6.10

Hardware 
2GB RAM
32GB HD
1 Processor

Select the option to install without intervention

User: adminq or root
Password adminq12

Settings

- Select profile light / minimal desktop
- Disable screen save
- Enable root login and autologin on Login Manager to the user adminq
- Install Chromium

# Execute the script from the cd drive

lsblk
sudo mkdir -p /mnt/iso
sudo mount -o ro /dev/sr0 /mnt/iso
cd /mnt/iso
sudo ./script.sh
sudo umount /mnt/iso

# Execute the script from a pendrive

# Remove access

SSH: root@192.168.0.104
Password: adminq12
Port: 22

RDP User: adminq
Password: adminq12
Port: 3389

VNC User: adminq
Password: adminq12
Port: 5900

SMB Shared Folder: \\q4osclient\Users
User: adminq
Password: adminq12

# Check Computer IP

ip addr show
192.168.0.104

hostname -I

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

# Enable VNC on Q4OS

sudo apt install x11vnc -y
x11vnc -storepasswd
Password: adminq12

sudo mkdir -p /etc/x11vnc
sudo x11vnc -storepasswd /etc/x11vnc/passwd
sudo chmod 600 /etc/x11vnc/passwd

sudo nano /etc/systemd/system/x11vnc.service

sudo systemctl daemon-reload
sudo systemctl enable x11vnc
sudo systemctl restart x11vnc

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

- Authentication

cmviladoporto\cezar

# Transform Script to Executable on Mac

chmod +x script.sh

# Create a Iso from a folder on Mac

hdiutil makehybrid -o /Users/user/projects/proxmox/Q4OS/q4osinstall.iso /Users/user/projects/proxmox/Q4OS -iso -joliet

