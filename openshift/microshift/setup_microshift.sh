#!/bin/bash

# root 권한 확인
if [ "$EUID" -ne 0 ]; then
  echo "오류: 이 스크립트는 root 권한(sudo)으로 실행해야 합니다."
  exit 1
fi

# 기본 설정값
MS_VERSION="latest-4.20"
VER_NUM="4.20"

function show_menu() {
    echo ""
    echo "=========================================================="
    echo "    MicroShift 4.20+ 통합 설치 및 트러블슈팅 툴"
    echo "=========================================================="
    echo " [현재 설정 버전: $MS_VERSION]"
    echo "----------------------------------------------------------"
    echo " 1. [준비] 시스템 업데이트 및 필수 패키지 설치"
    echo " 2. [저장소] MicroShift & 의존성 Repo 등록"
    echo " 3. [설치] MicroShift 패키지 설치"
    echo " 4. [인증] Pull Secret 등록 (JSON 파일 생성)"
    echo " 5. [트러블슈팅] Config.yaml 설정 및 경로 심볼릭 링크"
    echo " 6. [보안] 방화벽(Firewalld) 및 SELinux 설정"
    echo " 7. [클라이언트] oc 명령어 도구 설치 (버전 동기화)"
    echo " 8. [구동] 서비스 시작 및 Kubeconfig 자동 설정"
    echo " 9. [확인] 클러스터 상태 및 버전 체크"
    echo " 0. 종료"
    echo "=========================================================="
}

while true; do
    show_menu
    read -p "실행할 작업 번호를 입력하세요: " choice

    case $choice in
        1)
            echo "시스템 업데이트 및 필수 패키지(jq, wget, tar 등) 설치 중..."
            dnf update -y && dnf install -y yum-utils policycoreutils-python-utils jq wget tar
            echo "-> 완료."
            ;;
        2)
            echo "MicroShift 및 의존성 리포지토리 등록 중..."
            BASE_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/microshift/ocp/${MS_VERSION}/el9/os/"
            DEP_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rpms/${VER_NUM}-el9-beta/"
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
            echo "-> 리포지토리 등록 완료."
            ;;
        3)
            echo "MicroShift 패키지 설치 중..."
            dnf install -y microshift
            echo "-> 설치 완료."
            ;;
        4)
            echo "Red Hat Pull Secret 등록 단계입니다."
            echo "https://console.redhat.com/openshift/install/pull-secret 에서 JSON을 복사하세요."
            mkdir -p /etc/microshift
            vi /etc/microshift/pull-secret.json
            chmod 600 /etc/microshift/pull-secret.json
            echo "-> Pull Secret 파일 생성 완료."
            ;;
        5)
            echo "4.20 버전 특유의 경로 문제 및 설정 트러블슈팅 적용 중..."
            # 1. config.yaml 설정
            cat <<EOF > /etc/microshift/config.yaml
pullSecretPublisher:
  pullSecretFile: /etc/microshift/pull-secret.json
EOF
            # 2. 시스템 컴포넌트가 찾는 경로에 심볼릭 링크 생성 (로그 에러 해결책)
            mkdir -p /etc/crio
            ln -sf /etc/microshift/pull-secret.json /etc/crio/openshift-pull-secret
            # 3. Kubelet 참조 경로 링크
            mkdir -p /var/lib/kubelet
            ln -sf /etc/microshift/pull-secret.json /var/lib/kubelet/config.json
            echo "-> 트러블슈팅 설정 완료 (Config.yaml & Symlinks)."
            ;;
        6)
            echo "방화벽 포트 개방 및 SEL인증 컨텍스트 재설정 중..."
            firewall-cmd --permanent --zone=trusted --add-source=10.42.0.0/16
            firewall-cmd --permanent --zone=public --add-port={80,443,6443}/tcp
            firewall-cmd --reload
            restorecon -Rv /etc/microshift/
            echo "-> 보안 설정 완료."
            ;;
        7)
            echo "OpenShift CLI (oc) 설치 중..."
            CLIENT_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${MS_VERSION}/openshift-client-linux-amd64-rhel9.tar.gz"
            curl -L "$CLIENT_URL" -o oc.tar.gz
            tar -xvf oc.tar.gz && mv oc kubectl /usr/local/bin/ && rm -f oc.tar.gz
            echo "-> oc 설치 완료: $(oc version --client | head -n 1)"
            ;;
        8)
            echo "서비스 구동 및 Kubeconfig 적용 중..."
            systemctl enable --now crio microshift
            KUBECONFIG_PATH="/var/lib/microshift/resources/kubeadmin/kubeconfig"
            echo "Kubeconfig 생성 대기 중..."
            while [ ! -f "$KUBECONFIG_PATH" ]; do sleep 2; echo -n "."; done
            
            TARGET_USER=${SUDO_USER:-$(whoami)}
            USER_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
            mkdir -p "$USER_HOME/.kube"
            cp "$KUBECONFIG_PATH" "$USER_HOME/.kube/config"
            chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/.kube"
            echo -e "\n-> 구동 완료! 현재 사용자($TARGET_USER)에게 권한이 부여되었습니다."
            ;;
        9)
            echo "클러스터 상태 확인..."
            oc get nodes -o wide
            echo "----------------------------------------------------------"
            oc get po -A
            echo "----------------------------------------------------------"
            microshift version
            ;;
        0)
            echo "종료합니다."
            exit 0
            ;;
        *)
            echo "잘못된 번호입니다."
            ;;
    esac
done
