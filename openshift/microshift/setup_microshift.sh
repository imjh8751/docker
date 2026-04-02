#!/bin/bash

# root 권한 확인
if [ "$EUID" -ne 0 ]; then
  echo "오류: 이 스크립트는 root 권한(sudo)으로 실행해야 합니다."
  exit 1
fi

# 기본 버전 설정 (현재 4.20은 RC 베타 버전입니다)
MS_VERSION="latest-4.20"

function show_menu() {
    echo ""
    echo "=========================================================="
    echo "     MicroShift & OpenShift CLI 설치 툴 (대상: EL9)"
    echo "=========================================================="
    echo " 현재 설정된 버전 : [ $MS_VERSION ]"
    echo "=========================================================="
    echo " 1. 설치할 MicroShift 버전 변경 (기본: latest-4.20)"
    echo " 2. 시스템 업데이트 및 필수 패키지 설치"
    echo " 3. MicroShift 및 의존성 Repository 추가 (수정됨)"
    echo " 4. MicroShift 패키지 설치"
    echo " 5. 방화벽(Firewalld) 포트 개방 설정"
    echo " 6. OpenShift CLI (oc) 설치 (버전 동기화)"
    echo " 7. MicroShift 서비스 시작 및 Kubeconfig 적용"
    echo " 0. 스크립트 종료"
    echo "=========================================================="
}

while true; do
    show_menu
    read -p "실행할 작업의 번호를 입력하세요: " choice

    case $choice in
        1)
            echo ""
            read -p "설치할 버전을 입력하세요 (예: latest-4.18, latest-4.20 등): " input_version
            if [ -n "$input_version" ]; then
                MS_VERSION=$input_version
                echo "-> 버전이 [$MS_VERSION] (으)로 변경되었습니다."
            else
                echo "-> 입력값이 없어 기존 버전을 유지합니다."
            fi
            ;;
        2)
            echo ""
            echo "[작업 2] 시스템 업데이트 및 필수 패키지 설치 중..."
            dnf update -y
            dnf install -y yum-utils policycoreutils-python-utils jq wget tar
            echo "-> 완료되었습니다."
            ;;
        3)
            echo ""
            echo "[작업 3] MicroShift 및 의존성 Repository 추가 중..."
            
            # 입력된 버전에서 숫자만 추출 (예: latest-4.20 -> 4.20)
            VER_NUM=$(echo "$MS_VERSION" | grep -oE '[0-9]+\.[0-9]+')
            
            # MicroShift OS 패키지 주소
            BASE_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/microshift/ocp/${MS_VERSION}/el9/os/"
            
            # OpenShift 의존성(cri-o 등) 패키지 주소 (베타/RC 버전인 경우 beta 경로 사용)
            DEP_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rpms/${VER_NUM}-el9-beta/"
            
            echo "-> MicroShift 주소: $BASE_URL"
            echo "-> Dependencies 주소: $DEP_URL"

            cat <<EOF > /etc/yum.repos.d/microshift.repo
[microshift]
name=MicroShift
baseurl=${BASE_URL}
enabled=1
gpgcheck=0
skip_if_unavailable=0

[openshift-dependencies]
name=OpenShift Dependencies
baseurl=${DEP_URL}
enabled=1
gpgcheck=0
skip_if_unavailable=0
EOF
            echo "-> /etc/yum.repos.d/microshift.repo 파일이 생성되었습니다."
            ;;
        4)
            echo ""
            echo "[작업 4] MicroShift 패키지 설치 중..."
            dnf install -y microshift
            echo "-> 설치가 완료되었습니다."
            ;;
        5)
            echo ""
            echo "[작업 5] 방화벽(Firewalld) 설정 중..."
            firewall-cmd --permanent --zone=trusted --add-source=10.42.0.0/16
            firewall-cmd --permanent --zone=trusted --add-source=169.254.169.1
            firewall-cmd --permanent --zone=public --add-port=80/tcp
            firewall-cmd --permanent --zone=public --add-port=443/tcp
            firewall-cmd --permanent --zone=public --add-port=6443/tcp
            firewall-cmd --reload
            echo "-> OVN-Kubernetes 및 웹/API 포트 방화벽 개방이 완료되었습니다."
            ;;
        6)
            echo ""
            echo "[작업 6] OpenShift CLI (oc) 다운로드 및 설치 중..."
            CLIENT_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${MS_VERSION}/openshift-client-linux-amd64-rhel9.tar.gz"
            echo "-> 다운로드 경로: $CLIENT_URL"
            
            curl -O "$CLIENT_URL"
            
            if [ -f "openshift-client-linux-amd64-rhel9.tar.gz" ]; then
                tar -xvf openshift-client-linux-amd64-rhel9.tar.gz
                mv oc kubectl /usr/local/bin/
                rm -f openshift-client-linux-amd64-rhel9.tar.gz README.md
                echo ""
                echo "-> oc 설치가 완료되었습니다. 설치된 버전 정보:"
                oc version --client
            else
                echo "-> [오류] 클라이언트 파일을 다운로드하지 못했습니다. URL이나 버전을 다시 확인해 주세요."
            fi
            ;;
        7)
            echo ""
            echo "[작업 7] MicroShift 서비스 구동 및 Kubeconfig 적용..."
            systemctl enable --now microshift
            
            echo "-> MicroShift 데몬 시작됨. Kubeconfig 파일이 생성될 때까지 대기합니다..."
            KUBECONFIG_PATH="/var/lib/microshift/resources/kubeadmin/kubeconfig"
            
            while [ ! -f "$KUBECONFIG_PATH" ]; do
                sleep 5
                echo -n "."
            done
            echo " 생성 완료!"

            if [ -n "$SUDO_USER" ]; then
                USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
                TARGET_USER="$SUDO_USER"
            else
                USER_HOME=$HOME
                TARGET_USER=$(whoami)
            fi

            mkdir -p "$USER_HOME/.kube"
            cat "$KUBECONFIG_PATH" > "$USER_HOME/.kube/config"
            chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/.kube"
            chmod 600 "$USER_HOME/.kube/config"

            echo "-> Kubeconfig가 $TARGET_USER 사용자의 ~/.kube/config 에 복사되었습니다."
            echo "-> 서비스 상태 확인: systemctl status microshift"
            ;;
        0)
            echo ""
            echo "스크립트를 종료합니다."
            break
            ;;
        *)
            echo "-> 잘못된 입력입니다. 0~7 사이의 숫자를 입력해 주세요."
            ;;
    esac
done
