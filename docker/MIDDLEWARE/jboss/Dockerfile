FROM quay.io/wildfly/wildfly:latest-jdk11

# 관리자 사용자 생성
USER root
RUN /opt/jboss/wildfly/bin/add-user.sh admin admin123 --silent

# 애플리케이션 디렉토리 생성
RUN mkdir -p /opt/jboss/wildfly/standalone/deployments/

# 빌드된 애플리케이션 파일들 복사
# EAR 파일 복사 (enterprise application)
COPY ./deployments/*.ear /opt/jboss/wildfly/standalone/deployments/

# WAR 파일 복사 (web application)
COPY ./deployments/*.war /opt/jboss/wildfly/standalone/deployments/

# JAR 파일 복사 (library)
COPY ./deployments/*.jar /opt/jboss/wildfly/standalone/deployments/

# 설정 파일 복사 (선택사항)
COPY ./config/standalone.xml /opt/jboss/wildfly/standalone/configuration/standalone.xml

# PostgreSQL JDBC 드라이버 추가
ADD https://jdbc.postgresql.org/download/postgresql-42.6.0.jar /opt/jboss/wildfly/standalone/deployments/

# 데이터소스 설정을 위한 CLI 스크립트
COPY ./config/datasource-commands.cli /opt/jboss/

# 권한 설정
RUN chown -R jboss:jboss /opt/jboss/wildfly/standalone/deployments/
RUN chown -R jboss:jboss /opt/jboss/wildfly/standalone/configuration/

# jboss 사용자로 변경
USER jboss

# 포트 노출
EXPOSE 8080 9990

# 서버 시작 명령어
CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
