FROM quay.io/keycloak/keycloak:26.6.0

# 빌드 타임 환경변수 설정 (작성하신 compose 파일 내용과 일치해야 함)
ENV KC_DB=postgres
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# 미리 빌드 실행 (여기서 CPU를 한 번 쓰고 끝냄)
RUN /opt/keycloak/bin/kc.sh build
