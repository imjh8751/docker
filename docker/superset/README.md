위의 docker-compose.yml 파일은 다음과 같은 작업을 수행합니다:

Superset 컨테이너를 amancevice/superset 이미지에서 실행합니다.
컨테이너 이름을 superset으로 설정합니다.
항상 재시작하도록 설정합니다.
예제 데이터를 로드하도록 Superset을 구성합니다.
관리자 계정의 사용자 이름과 비밀번호, 이름 및 성을 설정합니다. (여기서는 admin/admin으로 설정되어 있습니다.)
호스트 머신의 8088 포트와 컨테이너의 8088 포트 간의 포트 매핑을 설정합니다.
호스트 머신의 ./superset 폴더와 컨테이너의 /home/superset 폴더를 볼륨으로 설정하여 데이터 유지 보수를 지원합니다.
Superset 컨테이너를 위한 Docker 네트워크를 생성합니다.
docker-compose.yml 파일을 작성하신 후, 다음과 같은 명령어를 사용하여 Superset을 시작할 수 있습니다:
