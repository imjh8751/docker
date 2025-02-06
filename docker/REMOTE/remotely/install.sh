mkdir -p /var/www/remotely
wget -q https://raw.githubusercontent.com/immense/Remotely/master/docker-compose/docker-compose.yml
docker-compose up -d
