#Docker Compose Setup
#Clone the repository
# https://docs.plane.so/self-hosting
git clone https://github.com/makeplane/plane
cd plane
chmod +x setup.sh

#Run setup.sh
./setup.sh http://localhost 

#If running in a cloud env replace localhost with public facing IP address of the VM

#Export Environment Variables
set -a
source .env
set +a

#Run Docker compose up
docker compose up -d
