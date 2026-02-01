**PostgreSQL 데이터베이스는 생성되었지만, Hoppscotch가 사용해야 할 테이블(Schema)이 아직 생성되지 않아서(Migration 미실행)** 발생하는 오류입니다.

로그의 핵심 에러는 다음과 같습니다.

> `relation "public.InfraConfig" does not exist` `Error: Database migration not found.`

Hoppscotch Backend가 DB에 접속은 성공했으나, `InfraConfig`라는 테이블을 찾지 못해 종료된 상황입니다.

아래 단계를 순서대로 진행하여 해결할 수 있습니다.

### 1. `.env` 파일 확인 (필수)

먼저 `docker-compose.yml`과 같은 위치에 있는 `.env` 파일에 데이터베이스 연결 정보가 정확히 설정되어 있는지 확인하세요. `hoppscotch-db` 컨테이너의 설정과 일치해야 합니다.

```bash
# .env 파일 예시
DATABASE_URL=postgresql://admin:Admin2580@hoppscotch-db:5432/hoppscotch
```

* `admin`: `POSTGRES_USER`
* `Admin2580`: `POSTGRES_PASSWORD`
* `hoppscotch-db`: `docker-compose.yml` 내의 DB 서비스 이름 (컨테이너 이름)
* `hoppscotch`: `POSTGRES_DB`

### 2. 마이그레이션(Migration) 수동 실행

컨테이너가 계속 재시작(Restart loop) 중이므로, 강제로 마이그레이션 명령어를 실행해 주어야 합니다.

터미널에서 다음 명령어를 입력하세요.

**방법 A: 컨테이너가 (재시작 중이라도) 실행 중일 때** `**exec**` **사용** 타이밍을 맞춰 실행하거나, 컨테이너가 잠시 떠 있는 동안 실행합니다. 로그 경로(`/dist/backend`)를 기반으로 한 명령어입니다.

```bash
docker compose exec hoppscotch sh -c "cd /dist/backend && npx prisma migrate deploy"
```

**방법 B:** `**run**` **명령어로 일회성 실행 (권장)** 위 명령어가 "Container is restarting" 등의 이유로 실패한다면, 아예 새 컨테이너를 띄워 마이그레이션만 수행하고 종료시킵니다.

```bash
docker compose run --rm hoppscotch sh -c "cd /dist/backend && npx prisma migrate deploy"
```

> **참고:** 실행 시 `Datasource "db": PostgreSQL database "hoppscotch", schema "public" at "hoppscotch-db:5432"` 메시지와 함께 마이그레이션이 적용(`Applying migration...`)되었다는 로그가 뜨면 성공입니다.

### 3. 컨테이너 재시작

마이그레이션이 성공했다면, 계속 재시작되던 컨테이너가 정상적으로 테이블을 찾고 구동될 것입니다. 깔끔하게 재시작해 줍니다.

```bash
docker compose restart hoppscotch
```

### 요약


1. `.env`의 `DATABASE_URL`이 `hoppscotch-db` 서비스 이름과 비밀번호를 정확히 가리키는지 확인.
2. `docker compose run ... npx prisma migrate deploy` 명령어로 테이블 생성.
3. 서비스 재시작.


