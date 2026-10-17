# Install OBS Assessment Tool

https://github.com/ObsidianCorps/obs-assessment-tool

- Create a container Alpine 3.21 on Proxmox

On the Proxmox host, go to Options → Features. Enable Nesting and keyctl. This is required for Docker in an unprivileged LXC. Start the CT again.

- Install Docker
apk update
apk add docker docker-cli-compose
rc-update add docker default
rc-service docker start

- Check that Docker is running
rc-service docker status
docker version
docker compose version

- Install git to get the repository
apk add git
cd /opt/
git clone https://github.com/ObsidianCorps/obs-assessment-tool.git

- Update Files

cd /opt/obs-assessment-tool/deploy

cat >> docker-compose.yml <<'EOF'
    ports:
      - "3000:80"
EOF
cat docker-compose.yml

docker compose up -d --build

docker-compose.yml down

- Access the Admin Panel

ip addr

http://192.168.0.105:3000/app.html