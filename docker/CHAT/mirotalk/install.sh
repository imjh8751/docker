# clone this repo
git clone https://github.com/miroslavpejic85/mirotalk.git

# go to mirotalk dir
cd mirotalk

# copy .env.template to .env (edit it according to your needs)
cp .env.template .env

# Copy app/src/config.template.js in app/src/config.js (edit it according to your needs)
cp app/src/config.template.js app/src/config.js

# Copy docker-compose.template.yml in docker-compose.yml (edit it according to your needs)
cp docker-compose.template.yml docker-compose.yml

# Get official image from Docker Hub
docker pull mirotalk/p2p:latest

# create and start containers
docker-compose up -d
