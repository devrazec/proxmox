# Install NIS2PME 

https://nis2pme.pt/en/platform/

- Create a container Alpine 3.21 on Proxmox

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
git clone https://github.com/nis2pme/platform.git

cd /opt/platform

cat > .env <<'EOF'
APP_URL=http://localhost
DB_PASSWORD=admin123
TLS_MODE=self-signed
EOF

On the Proxmox host, go to Options → Features. Enable Nesting and keyctl. This is required for Docker in an unprivileged LXC. Start the CT again.

apk add cgroup-tools
sed -i 's/^#\?rc_cgroup_mode=.*/rc_cgroup_mode="unified"/' /etc/rc.conf
grep -q '^rc_controller_cgroups' /etc/rc.conf || echo 'rc_controller_cgroups="YES"' >> /etc/rc.conf
rc-update add cgroups boot
rc-service cgroups restart

mkdir -p /sys/fs/cgroup/init
for p in $(cat /sys/fs/cgroup/cgroup.procs); do echo $p > /sys/fs/cgroup/init/cgroup.procs 2>/dev/null; done
echo "+cpuset +cpu +io +memory +hugetlb +pids" > /sys/fs/cgroup/cgroup.subtree_control
cat /sys/fs/cgroup/cgroup.subtree_control
rc-service docker restart

docker compose up -d

docker compose down

- Access the Admin Panel

ip addr
https://192.168.0.103/setup

maxchip@outlook.com
Admin@Cezar1