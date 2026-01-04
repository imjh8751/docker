NetBox는 Django 기반의 IPAM/DCIM 도구로, 데이터베이스(PostgreSQL)와 캐싱/큐(Redis)가 필수적입니다.
안정적인 운영을 위해 공식 netbox-community/netbox-docker 프로젝트의 권장 구조를 기반으로 작성된 docker-compose.yml입니다. 
이 구성은 웹 서비스, 백그라운드 워커, 하우스키핑(청소), DB, Redis(캐시 및 큐 분리)를 모두 포함합니다.
