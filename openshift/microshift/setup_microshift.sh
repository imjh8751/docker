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

# 초기 기본값 설정
MS_VERSION="latest-4.20"
VER_NUM="4.20"

# 명령어 출력 및 실행 함수
function run_cmd() {
    echo -e "${YELLOW}[EXEC] $1${NC}"
    eval "$1"
}

# 버전 변경 함수
function change_version() {
    echo -e "\n${CYAN}현재 설정: $MS_VERSION (Base: $VER_NUM)${NC}"
    echo "1) 4.20 (최신/테스트)"
    echo "2) 4.18 (안정 버전)"
    echo "3) 직접 입력 (예: latest-4.17 / 4.17)"
    read -p "선택하세요: " v_choice

    case $v_choice in
        1) MS_VERSION="latest-4.20"; VER_NUM="4.20" ;;
        2) MS_VERSION="latest-4.18"; VER_NUM="4.18" ;;
        3) 
           read -p "MS_VERSION 입력 (예: latest-4.17): " MS_VERSION
           read -p "VER_NUM 입력 (예: 4.17): " VER_NUM
           ;;
        *) echo "변경 없이 유지합니다." ;;
    esac
    echo -e "${GREEN}-> 설정 완료: $MS_VERSION / $VER_NUM${NC}"
}

function show_menu() {
    echo -e "\n${CYAN}==========================================================${NC}"
    echo -e "${CYAN}    MicroShift 통합 관리 스크립트 (버전 선택 & 트러블슈팅)${NC}"
    echo -e "${CYAN}==========================================================${NC}"
    echo -e " [현재 대상 버전: ${YELLOW}$MS_VERSION${CYAN}]"
    echo -e "----------------------------------------------------------"
    echo -e " v. ${GREEN}설치 버전 변경 (4.18 <-> 4.20)${NC}"
    echo -e " 1. 시스템 업데이트 및 필수 패키지 설치"
    echo -e " 2. MicroShift & 의존성 Repo 등록 (선택된 버전 기준)"
    echo -e " 3. MicroShift 패키지 설치"
    echo -e " 4. Pull Secret 등록 (vi 편집기 실행)"
    echo -e " 5. [필수] Config.yaml & 경로 트러블슈팅 (Symlink)"
    echo -e " 6. 방화벽 및 SELinux 복구"
    echo -e " 7. oc 명령어 도구 설치"
    echo -e " 8. 서비스 시작 및 Kubeconfig 자동 설정"
    echo -e " 9. 클러스터 상태 확인 (oc get po -A)"
    echo -e " 0. 종료"
    echo -e "=========================================================="
}

while true; do
    show_menu
    read -p "수행할 작업 번호를 입력하세요: " choice

    case $choice in
        v|V) change_version ;;
        1)
            run_cmd "dnf update -y"
            run_cmd "dnf install -y yum-utils policycoreutils-python-utils jq wget tar"
            ;;
        2)
            BASE_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/microshift/ocp/${MS_VERSION}/el9/os/"
            DEP_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rpms/${VER_NUM}-el9/"
            
            # 4.20 베타/최신 버전인 경우 경로 보정
            if [[ "$MS_VERSION" == *"4.20"* ]]; then
                DEP_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rpms/${VER_NUM}-el9-beta/"
            fi

            echo -e "${YELLOW}[EXEC] Generating /etc/yum.repos.d/microshift.repo...${NC}"
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
            run_cmd "dnf makecache"
            ;;
        3)
            run_cmd "dnf install -y microshift"
            ;;
        4)
            run_cmd "mkdir -p /etc/microshift"
            echo -e "${RED}!! Red Hat Pull Secret JSON을 아래 편집기에 붙여넣으세요 !!${NC}"
            run_cmd "vi /etc/microshift/pull-secret.json"
            run_cmd "chmod 600 /etc/microshift/pull-secret.json"
            ;;
        5)
            echo -e "${YELLOW}[EXEC] Creating /etc/microshift/config.yaml...${NC}"
            cat <<EOF > /etc/microshift/config.yaml
pullSecretPublisher:
  pullSecretFile: /etc/microshift/pull-secret.json
EOF
            run_cmd "mkdir -p /etc/crio"
            run_cmd "ln -sf /etc/microshift/pull-secret.json /etc/crio/openshift-pull-secret"
            run_cmd "mkdir -p /var/lib/kubelet"
            run_cmd "ln -sf /etc/microshift/pull-secret.json /var/lib/kubelet/config.json"
            run_cmd "restorecon -Rv /etc/microshift/"
            ;;
        6)
            run_cmd "firewall-cmd --permanent --zone=trusted --add-source=10.42.0.0/16"
            run_cmd "firewall-cmd --permanent --zone=public --add-port={80,443,6443}/tcp"
            run_cmd "firewall-cmd --reload"
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
            echo -e "${GREEN}Kubeconfig 생성 대기 중...${NC}"
            while [ ! -f "$KUBECONFIG_PATH" ]; do sleep 3; echo -n "."; done
            
            TARGET_USER=${SUDO_USER:-$(whoami)}
            USER_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
            run_cmd "mkdir -p $USER_HOME/.kube"
            run_cmd "cp $KUBECONFIG_PATH $USER_HOME/.kube/config"
            run_cmd "chown -R $TARGET_USER:$TARGET_USER $USER_HOME/.kube"
            echo -e "\n${GREEN}-> 완료! oc 명령어를 사용해 보세요.${NC}"
            ;;
        9)
            run_cmd "oc get po -A"
            run_cmd "microshift version"
            ;;
        0)
            echo "종료합니다."
            exit 0
            ;;
        *)
            echo -e "${RED}잘못된 번호입니다.${NC}"
            ;;
    esac
done
