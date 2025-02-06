#!/bin/sh
#
# check if docker is running
if ! (docker ps >/dev/null 2>&1)
then
        echo "docker daemon not running, will exit here!"
        exit
fi
echo "Preparing folder init and creating ./init/initdb.sql"
mkdir -p /APP/guacamole/init >/dev/null 2>&1
chmod -R +x /APP/guacamole/init
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --postgresql > /APP/guacamole/init/initdb.sql
echo "done"
echo "Preparing folder record and set permissions"
mkdir -p /APP/guacamole/record >/dev/null 2>&1
chmod -R 777 /APP/guacamole/record
echo "done"
