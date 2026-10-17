# Install OpenIsms 

https://github.com/NISD2/open-isms

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
git clone https://github.com/NISD2/open-isms.git

- Update Files

cd /opt/open-isms

cp Caddyfile.self-host.example Caddyfile
cp .env.self-host.example .env

sed -i 's/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=admin123/' .env
sed -i "s|^AUTH_SECRET=.*|AUTH_SECRET=7K0c6Kkf+2VWrNovY/3wEfSt9rrHgH256zTTumHq9b4=|" .env
sed -i 's|^AUTH_URL=.*|AUTH_URL=http://localhost:3000|' .env
sed -i 's|^NEXT_PUBLIC_APP_URL=.*|NEXT_PUBLIC_APP_URL=http://localhost:3000|' .env

sed -i 's|^BOOTSTRAP_ADMIN_EMAIL=.*|BOOTSTRAP_ADMIN_EMAIL=maxchip@outlook.com|' .env
sed -i 's|^BOOTSTRAP_ADMIN_PASSWORD=.*|BOOTSTRAP_ADMIN_PASSWORD=admin123|' .env

sed -i "s|^AWS_SECRET_ACCESS_KEY=.*|AWS_SECRET_ACCESS_KEY=7K0c6Kkf+2VWrNovY/3wEfSt9rrHgH256zTTumHq9b4=|" .env

sed -i "s|^MINIO_KMS_KEY=.*|MINIO_KMS_KEY=7K0c6Kkf+2VWrNovY/3wEfSt9rrHgH256zTTumHq9b4=|" .env

docker compose up -d 

docker compose down

docker ps

- Access the Admin Panel

ip addr

http://192.168.0.104:3026/

maxchip@outlook.com
Admin@Cezar1