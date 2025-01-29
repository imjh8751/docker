#!/bin/bash

# 최신 버전을 가져오기 위한 변수 설정
K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep 'tag_name' | cut -d '"' -f 4)

# k9s를 다운로드하고 설치하기 위한 경로 설정
INSTALL_DIR="/usr/local/sbin"

# k9s를 다운로드하고 실행 가능하게 만들기
curl -LO https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz
tar -xzf k9s_Linux_amd64.tar.gz
mv k9s /usr/local/bin/k9s

# 실행 가능한 권한 부여
chmod +x /usr/local/sbin/k9s

# 설치 완료 메시지 출력
echo "k9s ${K9S_VERSION} 설치 완료!"

# k9s 버전 확인
k9s --version
