curl https://raw.githubusercontent.com/makeplane/plane/develop/docker-compose-hub.yml --output docker-compose.yml
curl https://raw.githubusercontent.com/makeplane/plane/develop/setup.sh --output setup.sh
chmod +x setup.sh
./setup.sh localhost
