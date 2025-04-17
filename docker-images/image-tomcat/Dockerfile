FROM tomcat:9.0.104-jre8

# 시스템 패키지 업데이트 및 보안 관련 패키지 설치
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    unzip \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Tomcat 사용자 생성 및 퍼미션 설정
RUN groupadd -r tomcat && \
    useradd -r -g tomcat -d $CATALINA_HOME -s /bin/false tomcat

# 관리자 페이지 및 불필요한 애플리케이션 제거
RUN rm -rf ${CATALINA_HOME}/webapps/* && \
    mkdir -p ${CATALINA_HOME}/webapps/ROOT && \
    mkdir -p ${CATALINA_HOME}/conf && \
    chown -R tomcat:tomcat ${CATALINA_HOME} && \
    chmod -R 755 ${CATALINA_HOME} && \
    chmod -R 755 ${CATALINA_HOME}/conf

# 최적화된 server.xml 및 기타 설정 파일 복사
COPY server.xml ${CATALINA_HOME}/conf/
COPY context.xml ${CATALINA_HOME}/conf/
COPY web.xml ${CATALINA_HOME}/conf/
COPY tomcat-users.xml ${CATALINA_HOME}/conf/
COPY catalina.properties ${CATALINA_HOME}/conf/
#COPY logging.properties ${CATALINA_HOME}/conf/

# index.jsp 파일 추가
COPY index.jsp ${CATALINA_HOME}/webapps/ROOT/

# 보안 헤더 설정을 위한 web.xml 파일 설정 (필요하다면)
RUN mkdir -p ${CATALINA_HOME}/conf/Catalina/localhost

# JVM 및 Tomcat 최적화 환경 변수 설정
ENV CATALINA_OPTS="-Xms512m -Xmx1024m -Djava.security.egd=file:/dev/./urandom -server -Dfile.encoding=UTF-8"
#ENV UMASK="0027"
ENV JAVA_OPTS="-Dfile.encoding=UTF-8 -Duser.timezone=Asia/Seoul"

# 비특권 사용자로 실행
USER tomcat

EXPOSE 8080

CMD ["catalina.sh", "run"
