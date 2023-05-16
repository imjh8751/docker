위의 docker-compose.yml 파일은 다음과 같은 작업을 수행합니다:

server, scheduler, worker 컨테이너를 최신 버전의 Redash 이미지인 redash/redash:latest에서 실행합니다.
각 컨테이너의 환경 변수는 .env 파일에서 가져옵니다.
postgres 컨테이너를 PostgreSQL 13 버전의 Alpine 이미지인 postgres:13-alpine에서 실행합니다.
redis 컨테이너를 Redis 6 버전의 Alpine 이미지인 redis:6-alpine에서 실행합니다.
nginx 컨테이너를 Nginx 1.21 이미지에서 실행합니다.
각 컨테이너는 항상 재시작되도록 설정되어 있습니다.
필요한 컨테이너 간의 의존성이 설정되어 있습니다.
필요한 포트 매핑 및 볼륨 마운트가 설정되어 있습니다.
docker-compose.yml 파일을 작성한 후, 다음 명령어를 사용하여 Redash를 시작할 수 있습니다:
