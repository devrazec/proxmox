# Install Kasm

- Download ISO of Debian in CD

https://cdimage.debian.org/cdimage/archive/11.11.0/amd64/iso-cd/

https://cdimage.debian.org/cdimage/archive/13.6.0/amd64/iso-cd/

- Create a vm Debian 11.11 on Proxmox

CPU	2 cores
Memory 4GB
Storage	75GB

- Install ssh

sudo apt install -y openssh-server
sudo systemctl enable --now ssh
sudo systemctl status ssh
sudo ufw allow OpenSSH

- Access the Server as root

ip -br addr
ssh operador@192.168.0.103
su -

- Install Kasm

sudo apt install -y curl

cd /tmp

curl --fail-early \
  -fO https://kasm-static-content.s3.amazonaws.com/kasm_release_1.19.0-latest.tar.gz \
  -fO https://kasm-static-content.s3.amazonaws.com/kasm_release_1.19.0-latest.tar.gz.sha256sum

sha256sum --check *.sha256sum

tar -xf kasm_release_1.19.0-latest.tar.gz

sudo bash kasm_release/install.sh

- Access the Admin Panel

http://192.168.0.103

- Get the activate code

https://kasm.com/activate

- Kasm UI Login Credentials after instalation

https://192.168.0.103/

------------------------------------
  username: admin@kasm.local
  password: vAvgPAqdg0QYa
------------------------------------
  username: user@kasm.local
  password: oUw5aw3oJXbxO
------------------------------------

Kasm Database Credentials
------------------------------------
  username: kasmapp
  password: 3MpE4wnWZQWugBatP89P
------------------------------------

Kasm Manager Token
------------------------------------
  password: m7G2HT4IC6WOABcONoq0
------------------------------------

Service Registration Token
------------------------------------
  password: YLB7lA3JHKhQILyGzBLP
------------------------------------

- Check from the Server Side if it has connection

nc -vz 192.168.0.104 3389
nc -vz 192.168.0.104 4902

- Check from the Windows Side if it has connection

curl -vk https://192.168.0.103/