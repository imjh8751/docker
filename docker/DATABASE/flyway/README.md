위의 Docker Compose 파일에서는 flyway/flyway 이미지를 사용하여 Flyway를 실행하고, postgres:latest 이미지를 사용하여 PostgreSQL을 실행합니다. Flyway 컨테이너는 ./sql 디렉토리를 Flyway 컨테이너의 /flyway/sql 디렉토리에 마운트하여 SQL 스크립트를 제공합니다. 또한 PostgreSQL 컨테이너는 postgres-data 볼륨을 사용하여 데이터를 보존합니다.
 
