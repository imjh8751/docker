위의 Docker Compose 파일에서는 liquibase/liquibase 이미지를 사용하여 Liquibase를 실행하고, postgres:latest 이미지를 사용하여 PostgreSQL을 실행합니다. Liquibase 컨테이너는 ./changelog 디렉토리를 Liquibase 컨테이너의 /liquibase/changelog 디렉토리에 마운트하여 변경 로그 파일을 제공합니다. 또한 ./liquibase.properties 파일을 Liquibase 컨테이너의 /liquibase/liquibase.properties 경로에 마운트하여 Liquibase 구성을 제공합니다. PostgreSQL 컨테이너는 postgres-data 볼륨을 사용하여 데이터를 보존합니다.
 
