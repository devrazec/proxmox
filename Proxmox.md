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