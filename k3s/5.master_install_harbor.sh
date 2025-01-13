#!/bin/bash

# Harbor 설치를 위한 변수 설정
HARBOR_VERSION=$(curl -s https://api.github.com/repos/goharbor/harbor/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
INSTALL_DIR="/opt/harbor"

# 설치 디렉토리 생성
mkdir -p $INSTALL_DIR

# Harbor 패키지 다운로드
curl -L https://github.com/goharbor/harbor/releases/download/$HARBOR_VERSION/harbor-online-installer-$HARBOR_VERSION.tgz -o harbor.tgz

# 패키지 압축 해제
tar -xzf harbor.tgz -C $INSTALL_DIR

# 설치 디렉토리로 이동
cd $INSTALL_DIR/harbor

# harbor.yml 예제 설정 파일 복사
cp harbor.yml.tmpl harbor.yml

# 사용자 설정에 맞게 harbor.yml 파일 수정 (이 부분은 사용자 설정에 따라 필요)

# 설치 스크립트 실행
#./install.sh

# 완료 메시지 출력
#echo "Harbor $HARBOR_VERSION 버전 설치가 완료되었습니다!"
