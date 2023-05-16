위의 docker-compose.yml 파일은 다음과 같은 작업을 수행합니다.

Metabase 컨테이너를 metabase 이미지에서 실행합니다.
컨테이너 이름을 metabase로 설정합니다.
항상 재시작하도록 설정합니다.
MySQL 데이터베이스를 사용하도록 Metabase를 구성합니다. 환경 변수를 통해 데이터베이스 연결을 구성합니다.
호스트 머신의 3000 포트와 컨테이너의 3000 포트 간의 포트 매핑을 설정합니다.
호스트 머신의 ./metabase-data 폴더와 컨테이너의 /metabase-data 폴더를 볼륨으로 설정하여 데이터 유지 보수를 지원합니다.
Metabase 컨테이너를 위한 Docker 네트워크를 생성합니다.
docker-compose.yml 파일을 작성하신 후, 다음과 같은 명령어를 사용하여 Metabase를 시작할 수 있습니다.
