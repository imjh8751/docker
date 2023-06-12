mkdir /data
cd /data
git clone https://github.com/immich-app/immich.git
cd immich/docker
cp .env.example .env
vi .env

#http://ip:2283/api
# docker-compose up -d
