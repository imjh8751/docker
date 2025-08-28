# WAR 파일 배포 및 Context Root 설정 가이드

## 디렉토리 구조
```
project/
├── docker-compose.yml
├── server.xml
├── apps/
│   ├── myapp.war
│   ├── admin-portal.war
│   ├── api-server.war
│   └── frontend.war
└── logs/
```

## Context Root 설정 방법

### 1. server.xml에서 개별 설정
각 WAR 파일별로 `<webApplication>` 태그를 사용하여 설정:

```xml
<webApplication id="애플리케이션ID" 
                location="WAR파일명" 
                contextRoot="/원하는경로" 
                name="애플리케이션명"/>
```

### 2. 설정 예시

| WAR 파일명 | Context Root | 접속 URL |
|-----------|--------------|----------|
| myapp.war | /myapp | http://localhost:9080/myapp |
| admin-portal.war | /admin | http://localhost:9080/admin |
| api-server.war | /api | http://localhost:9080/api |
| frontend.war | / | http://localhost:9080/ (루트) |

## 배포 단계

### 1. WAR 파일 배치
```bash
# apps 디렉토리에 WAR 파일들 복사
cp /path/to/myapp.war ./apps/
cp /path/to/admin-portal.war ./apps/
cp /path/to/api-server.war ./apps/
```

### 2. server.xml 수정
각 WAR 파일에 대해 `<webApplication>` 태그 추가

### 3. 컨테이너 실행
```bash
docker-compose up -d
```

### 4. 배포 확인
```bash
# 컨테이너 로그 확인
docker-compose logs -f

# Admin Console에서 확인
# https://localhost:9443/adminCenter
# 로그인: admin / admin123
```

## 동적 배포 (Hot Deployment)

### WAR 파일 추가/교체
1. `apps/` 디렉토리에 새 WAR 파일 복사
2. server.xml에 해당하는 `<webApplication>` 태그 추가
3. 컨테이너 재시작: `docker-compose restart`

### 런타임 중 Context Root 변경
1. server.xml 수정
2. 컨테이너 재시작으로 변경사항 적용

## 주의사항

- **충돌 방지**: 동일한 contextRoot를 여러 애플리케이션에서 사용하면 안됨
- **경로 규칙**: contextRoot는 "/"로 시작해야 함 (예: "/myapp", "/api")
- **루트 설정**: 하나의 애플리케이션만 contextRoot="/"로 설정 가능
- **파일명 매칭**: location 속성은 apps/ 디렉토리의 실제 파일명과 일치해야 함
