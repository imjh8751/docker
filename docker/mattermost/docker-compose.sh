git clone https://github.com/mattermost/docker
cd docker

cp env.example .env

이 .env 파일을 vi 편집기로 들어가면 아래처럼 내용이 있습니다.
여기서 image 선택, DOMAIN, TZ, POSTGRES 설정등을 변경할 수 있습니다.
이미지 태그나 라이선스 관련은 아래 항목인데 사용 라이선스에 따라 enterprise-edition과 team-edtion으로 나뉘어져있습니다. 저같은경우 개인이기때문에 팀에디션으로 변경했습니다.

MATTERMOST_IMAGE=mattermost-enterprise-edition
MATTERMOST_IMAGE_TAG=5.36

enterprise -> team

환경변수를 모두 수정하셨으면
아래 명령어로 디렉터리 생성 및 권한을 부여합니다.

mkdir -p ./volumes/app/mattermost/{config,data,logs,plugins,client/plugins,bleve-indexes}
sudo chown -R 2000:2000 ./volumes/app/mattermost

이제 nginx 사용버전 이나 reverse proxy를 사용하는 버전이있는데 여기서는 reverse proxy 버전으로 진행하겠습니다.(nginx 포함버전은 글 최하단의 github를 참고해주세요)

sudo docker-compose -f docker-compose.yml -f docker-compose.without-nginx.yml up -d
