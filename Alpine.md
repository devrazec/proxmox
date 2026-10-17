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