# mattermost git clone
git clone https://github.com/mattermost/docker

cd docker

# copy .env file
cp env.example .env

# make directories and change owner
mkdir -p ./volumes/app/mattermost/{config,data,logs,plugins,client/plugins,bleve-indexes}
chown -R 2000:2000 ./volumes/app/mattermost
