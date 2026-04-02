#!/bin/bash

# 색상 정의
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# root 권한 확인
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}오류: 이 스크립트는 root 권한(sudo)으로 실행해야 합니다.${NC}"
  exit 1
fi

# 기본 설정값
MS_VERSION="latest-4.20"
VER_NUM="4.20"

# 명령어 출력 및 실행 함수
function run_cmd() {
    echo -e "${YELLOW}[EXEC] $1${NC}"
    eval "$1"
}

function show_menu() {
    echo -e "\n${CYAN}==========================================================${NC}"
    echo -e "${CYAN}    MicroShift 4.20+ 통합 설치 및 트러블슈팅 (명령어 출력형)${NC}"
    echo -e "${CYAN}==========================================================${NC}"
    echo -e " [현재 설정 버전: $MS_VERSION]"
    echo -e "----------------------------------------------------------"
    echo -e " 1. 시스템 업데이트 및 필수 패키지 설치"
    echo -e " 2. MicroShift & 의존성(CRI-O 등) Repo 등록"
    echo -e " 3. MicroShift 패키지 설치"
    echo -e " 4. Pull Secret 등록 (JSON 파일 직접 생성)"
    echo -e " 5. [중요] Config.yaml 설정 및 경로 트러블슈팅(Symlink)"
    echo -e " 6. 방화벽(Firewalld) 및 SELinux 복구"
    echo -e " 7. oc 명령어 도구 설치 (4.20 버전 동기화)"
    echo -e " 8. 서비스 시작 및 Kubeconfig 자동 설정"
    echo -e " 9. 클러스터 상태 및 버전 최종 확인"
    echo -e " 0. 종료"
    echo -e "=========================================================="
}

while true; do
    show_menu
    read -p "수행할 작업 번호를 입력하세요: " choice

    case $choice in
        1)
            run_cmd "dnf update -y"
            run_cmd "dnf install -y yum-utils policycoreutils-python-utils jq wget tar"
            ;;
        2)
            BASE_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/microshift/ocp/${MS_VERSION}/el9/os/"
            DEP_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rpms/${VER_NUM}-el9-beta/"
            echo -e "${YELLOW}[EXEC] cat <<EOF > /etc/yum.repos.d/microshift.repo ...${NC}"
            cat <<EOF > /etc/yum.repos.d/microshift.repo
[microshift]
name=MicroShift
baseurl=${BASE_URL}
enabled=1
gpgcheck=0
[openshift-dependencies]
name=OpenShift Dependencies
baseurl=${DEP_URL}
enabled=1
gpgcheck=0
EOF
            ;;
        3)
            run_cmd "dnf install -y microshift"
            ;;
        4)
            run_cmd "mkdir -p /etc/microshift"
            echo -e "${RED}!! 메모장 등에 복사한 Pull Secret JSON을 아래 vi 편집기에 붙여넣으세요 !!${NC}"
            run_cmd "vi /etc/microshift/pull-secret.json"
            run_cmd "chmod 600 /etc/microshift/pull-secret.json"
            ;;
        5)
            echo -e "${GREEN}# MicroShift 4.20 버전의 경로/인증 이슈를 해결합니다.${NC}"
            echo -e "${YELLOW}[EXEC] cat <<EOF > /etc/microshift/config.yaml ...${NC}"
            cat <<EOF > /etc/microshift/config.yaml
pullSecretPublisher:
  pullSecretFile: /etc/microshift/pull-secret.json
EOF
            run_cmd "mkdir -p /etc/crio"
            run_cmd "ln -sf /etc/microshift/pull-secret.json /etc/crio/openshift-pull-secret"
            run_cmd "mkdir -p /var/lib/kubelet"
            run_cmd "ln -sf /etc/microshift/pull-secret.json /var/lib/kubelet/config.json"
            ;;
        6)
            run_cmd "firewall-cmd --permanent --zone=trusted --add-source=10.42.0.0/16"
            run_cmd "firewall-cmd --permanent --zone=public --add-port={80,443,6443}/tcp"
            run_cmd "firewall-cmd --reload"
            run_cmd "restorecon -Rv /etc/microshift/"
            ;;
        7)
            CLIENT_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${MS_VERSION}/openshift-client-linux-amd64-rhel9.tar.gz"
            run_cmd "curl -L $CLIENT_URL -o oc.tar.gz"
            run_cmd "tar -xvf oc.tar.gz"
            run_cmd "mv oc kubectl /usr/local/bin/"
            run_cmd "rm -f oc.tar.gz"
            ;;
        8)
            run_cmd "systemctl enable --now crio microshift"
            KUBECONFIG_PATH="/var/lib/microshift/resources/kubeadmin/kubeconfig"
            echo -e "${GREEN}Kubeconfig 생성을 기다리는 중... (최대 5분)${NC}"
            while [ ! -f "$KUBECONFIG_PATH" ]; do sleep 3; echo -n "."; done
            
            TARGET_USER=${SUDO_USER:-$(whoami)}
            USER_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
            run_cmd "mkdir -p $USER_HOME/.kube"
            run_cmd "cp $KUBECONFIG_PATH $USER_HOME/.kube/config"
            run_cmd "chown -R $TARGET_USER:$TARGET_USER $USER_HOME/.kube"
            echo -e "\n${GREEN}-> Kubeconfig 설정 완료.${NC}"
            ;;
        9)
            run_cmd "oc get nodes -o wide"
            run_cmd "oc get po -A"
            run_cmd "microshift version"
            ;;
        0)
            echo "스크립트를 종료합니다."
            exit 0
            ;;
        *)
            echo -e "${RED}잘못된 선택입니다.${NC}"
            ;;
    esac
done
