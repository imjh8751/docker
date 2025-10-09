#!/bin/bash

set -e

# =================================================================
# 빌드 설정 변수 (필요에 따라 수정)
# =================================================================
APP_NAME="PushToMattermost"
APP_VERSION="1.0.0"

PROJECT_DIR="./android_project"              # 기존 프로젝트 폴더 경로
OUTPUT_DIR="./build_output"                  # APK 출력 폴더
DOCKER_IMAGE="openjdk:17-jdk-slim"          # Docker 베이스 이미지
GRADLE_VERSION="8.0"                        # Gradle 버전
ANDROID_BUILD_TOOLS="34.0.0"               # Android Build Tools 버전
ANDROID_COMPILE_SDK="34"                    # Android Compile SDK 버전

# =================================================================
# 컬러 정의 및 로그 함수
# =================================================================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# =================================================================
# 함수 정의
# =================================================================

check_prerequisites() {
    log_info "사전 요구사항 확인 중..."
    
    # Docker 확인
    if ! command -v docker &> /dev/null; then
        log_error "Docker가 설치되지 않았습니다."
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker 데몬이 실행되지 않았습니다."
        exit 1
    fi
    
    # 프로젝트 폴더 확인
    if [[ ! -d "$PROJECT_DIR" ]]; then
        log_error "프로젝트 폴더가 존재하지 않습니다: $PROJECT_DIR"
        exit 1
    fi
    
    # 필수 파일 확인
    if [[ ! -f "$PROJECT_DIR/build.gradle" ]] && [[ ! -f "$PROJECT_DIR/build.gradle.kts" ]]; then
        log_error "프로젝트 폴더에 build.gradle 파일이 없습니다: $PROJECT_DIR"
        exit 1
    fi
    
    if [[ ! -f "$PROJECT_DIR/app/build.gradle" ]] && [[ ! -f "$PROJECT_DIR/app/build.gradle.kts" ]]; then
        log_error "프로젝트 폴더에 app/build.gradle 파일이 없습니다: $PROJECT_DIR/app"
        exit 1
    fi
    
    log_success "사전 요구사항 확인 완료"
}

create_build_dockerfile() {
    log_info "Dockerfile 생성 중..."
    
    cat > Dockerfile << EOF
FROM $DOCKER_IMAGE

ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/build-tools/$ANDROID_BUILD_TOOLS

# 필수 패키지 설치
RUN apt-get update && apt-get install -y wget unzip curl git && rm -rf /var/lib/apt/lists/*

# Gradle 설치
RUN wget -q https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip -O gradle.zip && \\
    unzip -q gradle.zip -d /opt && \\
    ln -s /opt/gradle-$GRADLE_VERSION/bin/gradle /usr/local/bin/gradle && \\
    rm gradle.zip

# Android SDK 설치
RUN mkdir -p \$ANDROID_HOME/cmdline-tools && \\
    cd \$ANDROID_HOME/cmdline-tools && \\
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdtools.zip && \\
    unzip -q cmdtools.zip && mv cmdline-tools latest && rm cmdtools.zip

# Android SDK 구성 요소 설치
RUN yes | \$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses && \\
    \$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-$ANDROID_COMPILE_SDK" "build-tools;$ANDROID_BUILD_TOOLS"

WORKDIR /workspace

# 프로젝트 파일 복사
COPY $PROJECT_DIR .

# 빌드 실행
CMD ["sh", "-c", "gradle wrapper --gradle-version $GRADLE_VERSION && chmod +x ./gradlew && ./gradlew clean assembleRelease --no-daemon --stacktrace"]
EOF
    
    log_success "Dockerfile 생성 완료"
}

docker_build() {
    log_info "Docker 이미지 빌드 중..."
    docker build -t android-builder:latest .
    log_success "Docker 이미지 빌드 완료"

    log_info "APK 빌드 중..."
    docker run --rm -v "$(pwd)/$PROJECT_DIR:/workspace" android-builder:latest

    # APK 파일 경로 확인 및 복사
    APK_PATH="$PROJECT_DIR/app/build/outputs/apk/release/app-release.apk"
    
    if [[ -f "$APK_PATH" ]]; then
        mkdir -p "$OUTPUT_DIR"
        cp "$APK_PATH" "$OUTPUT_DIR/${APP_NAME}-${APP_VERSION}.apk"
        log_success "APK 생성 완료: $OUTPUT_DIR/${APP_NAME}-${APP_VERSION}.apk"
        
        # APK 정보 출력
        APK_SIZE=$(du -h "$OUTPUT_DIR/${APP_NAME}-${APP_VERSION}.apk" | cut -f1)
        log_info "APK 크기: $APK_SIZE"
    else
        log_error "APK 파일을 찾을 수 없습니다: $APK_PATH"
        log_info "빌드 로그를 확인하여 오류를 파악하세요."
        exit 1
    fi
}

cleanup() {
    log_info "임시 파일 정리 중..."
    if [[ -f "Dockerfile" ]]; then
        rm -f Dockerfile
    fi
    log_success "정리 완료"
}

main() {
    log_info "=== Android APK 빌드 시작 ==="
    log_info "프로젝트 경로: $PROJECT_DIR"
    log_info "출력 경로: $OUTPUT_DIR"
    log_info "앱 이름: $APP_NAME"
    log_info "앱 버전: $APP_VERSION"
    
    check_prerequisites
    create_build_dockerfile
    docker_build
    cleanup
    
    log_success "=== 빌드 완료 ==="
}

# 스크립트 실행
main "$@"
