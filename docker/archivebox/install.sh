#!/bin/bash

curl -fsSL 'https://docker-compose.archivebox.io' > docker-compose.yml

docker compose run archivebox init --setup

docker compose up -d
