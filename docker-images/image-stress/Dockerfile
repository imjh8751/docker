FROM openjdk:17-jdk-slim

WORKDIR /app

# 필요한 도구 설치
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    wget \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Gradle 설치
ENV GRADLE_VERSION=7.6
RUN wget https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -P /tmp \    && unzip -d /opt/gradle /tmp/gradle-${GRADLE_VERSION}-bin.zip \
    && rm /tmp/gradle-${GRADLE_VERSION}-bin.zip

ENV PATH=$PATH:/opt/gradle/gradle-${GRADLE_VERSION}/bin

# 빌드 설정 파일 복사
COPY build.gradle .
COPY settings.gradle .

# 소스 코드 복사
COPY src ./src/

# Gradle로 빌드
RUN gradle build --no-daemon

# 포트 노출 (외부 호출용)
EXPOSE 8080

# 애플리케이션 실행
CMD ["java", "-jar", "build/libs/stress-app.jar"]
