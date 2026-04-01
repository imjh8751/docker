#!/bin/bash

# ==========================================
# SSH 환경 설정 및 관리 대화형 스크립트
# ==========================================

# 1. Root 권한 체크
if [ "$EUID" -ne 0 ]; then
  echo "오류: 이 스크립트는 root 권한으로 실행해야 합니다. (sudo ./setup_ssh.sh)"
  exit 1
fi

# 2. OS 및 패키지 매니저 환경 감지
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "운영체제 정보를 확인할 수 없습니다."
    exit 1
fi

SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP_CONFIG="/etc/ssh/sshd_config.bak.$(date +%F_%T)"

# 최초 1회 설정 파일 백업
if [ ! -f "/tmp/ssh_setup_backed_up" ]; then
    cp "$SSHD_CONFIG" "$BACKUP_CONFIG"
    echo "[안내] 원본 설정 파일이 백업되었습니다: $BACKUP_CONFIG"
    touch /tmp/ssh_setup_backed_up
fi

# --- 함수 정의 부 ---

# 현재 설정된 값 읽어오기 함수 (설정이 없으면 디폴트 텍스트 반환)
get_current_value() {
    local key=$1
    local default_val=$2
    # 주석 제외하고 해당 설정 키값 추출
    local val=$(grep -iE "^\s*${key}\s+" "$SSHD_CONFIG" | awk '{print $2}')
    
    if [ -z "$val" ]; then
        echo "$default_val"
    else
        echo "$val"
    fi
}

# sshd_config 설정 변경 함수
update_sshd_config() {
    local key=$1
    local value=$2
    
    # 주석 처리되어 있거나 설정이 존재하는 경우 치환, 없으면 파일 끝에 추가
    if grep -q -iE "^\s*#?\s*${key}\s" "$SSHD_CONFIG"; then
        sed -i -E "s/^\s*#?\s*${key}\s+.*/${key} ${value}/i" "$SSHD_CONFIG"
    else
        echo "${key} ${value}" >> "$SSHD_CONFIG"
    fi
    echo " -> [적용 완료] ${key} 설정이 '${value}'(으)로 변경되었습니다."
}

# 서비스 재기동 및 방화벽 설정 적용 함수
apply_and_restart() {
    local CURRENT_PORT=$(get_current_value "Port" "22")
    echo "-------------------------------------"
    echo " 방화벽 및 서비스 재기동을 진행합니다."
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        if command -v ufw > /dev/null && ufw status | grep -q "Status: active"; then
            ufw allow "$CURRENT_PORT"/tcp > /dev/null
            echo "[방화벽] UFW에서 TCP ${CURRENT_PORT} 포트를 개방했습니다."
        fi
        systemctl restart ssh
        echo "[서비스] ssh 서비스가 성공적으로 재기동되었습니다."

    elif [[ "$OS" == *"centos"* || "$OS" == *"rhel"* || "$OS" == *"rocky"* || "$OS" == *"almalinux"* ]]; then
        if command -v semanage > /dev/null && getenforce | grep -q -i "Enforcing"; then
            semanage port -a -t ssh_port_t -p tcp "$CURRENT_PORT" 2>/dev/null || semanage port -m -t ssh_port_t -p tcp "$CURRENT_PORT"
            echo "[SELinux] TCP ${CURRENT_PORT} 포트를 ssh_port_t로 허용했습니다."
        fi
        if command -v firewall-cmd > /dev/null && systemctl is-active firewalld > /dev/null; then
            firewall-cmd --permanent --add-port="${CURRENT_PORT}/tcp" > /dev/null
            firewall-cmd --reload > /dev/null
            echo "[방화벽] Firewalld에서 TCP ${CURRENT_PORT} 포트를 개방했습니다."
        fi
        systemctl restart sshd
        echo "[서비스] sshd 서비스가 성공적으로 재기동되었습니다."
    else
        systemctl restart sshd || systemctl restart ssh
        echo "[서비스] OS를 자동 인식할 수 없어 수동으로 SSH 서비스 재기동을 시도했습니다."
    fi
    echo "-------------------------------------"
}

# 1. 현재 설정 상태 확인 메뉴
view_settings() {
    echo ""
    echo "=========================================="
    echo "          [ 현재 SSH 설정 상태 ]          "
    echo "=========================================="
    echo " 1. 사용 포트 (Port): $(get_current_value "Port" "22 (OS 디폴트)")"
    echo " 2. Root 로그인 허용 (PermitRootLogin): $(get_current_value "PermitRootLogin" "prohibit-password (OS 디폴트)")"
    echo " 3. 패스워드 인증 (PasswordAuthentication): $(get_current_value "PasswordAuthentication" "yes (OS 디폴트)")"
    echo "=========================================="
    read -p "계속하려면 Enter 키를 누르세요..."
}

# 2. 항목별 설정 관리 메뉴
manage_settings() {
    while true; do
        echo ""
        echo "=========================================="
        echo "           [ 항목별 설정 관리 ]           "
        echo " (입력 없이 Enter를 누르면 디폴트값이 적용)"
        echo "=========================================="
        echo " 1. SSH 포트 번호 변경"
        echo " 2. Root 로그인 허용 여부 변경"
        echo " 3. 패스워드 인증 허용 여부 변경"
        echo " 4. [이전 메뉴로 돌아가기]"
        echo "=========================================="
        read -p "수정할 항목의 번호를 선택하세요: " SUB_CHOICE

        case $SUB_CHOICE in
            1)
                CUR_PORT=$(get_current_value "Port" "22")
                read -p "▶ 새로운 포트 번호 (현재: $CUR_PORT) [디폴트: 22]: " INPUT_PORT
                NEW_PORT=${INPUT_PORT:-22}
                update_sshd_config "Port" "$NEW_PORT"
                apply_and_restart
                ;;
            2)
                CUR_ROOT=$(get_current_value "PermitRootLogin" "prohibit-password")
                read -p "▶ Root 로그인 허용 (yes / no / prohibit-password) (현재: $CUR_ROOT) [디폴트: no]: " INPUT_ROOT
                NEW_ROOT=${INPUT_ROOT:-no}
                update_sshd_config "PermitRootLogin" "$NEW_ROOT"
                apply_and_restart
                ;;
            3)
                CUR_PW=$(get_current_value "PasswordAuthentication" "yes")
                read -p "▶ 패스워드 인증 (yes / no) (현재: $CUR_PW) [디폴트: yes]: " INPUT_PW
                NEW_PW=${INPUT_PW:-yes}
                update_sshd_config "PasswordAuthentication" "$NEW_PW"
                apply_and_restart
                ;;
            4)
                break
                ;;
            *)
                echo "잘못된 입력입니다. 1~4 번호를 선택해주세요."
                ;;
        esac
    done
}

# --- 메인 루프 ---
while true; do
    echo ""
    echo "-------------------------------------"
    echo "   홈 서버 SSH 보안 설정 매니저"
    echo "-------------------------------------"
    echo " 1. 현재 SSH 설정 상태 확인"
    echo " 2. SSH 설정 항목별 관리 (수정)"
    echo " 3. 종료"
    echo "-------------------------------------"
    read -p "원하시는 메뉴의 번호를 선택하세요: " MAIN_CHOICE

    case $MAIN_CHOICE in
        1)
            view_settings
            ;;
        2)
            manage_settings
            ;;
        3)
            echo "프로그램을 종료합니다. 수고하셨습니다."
            # 임시 플래그 파일 삭제
            rm -f /tmp/ssh_setup_backed_up
            exit 0
            ;;
        *)
            echo "잘못된 입력입니다. 1, 2, 3 중에서 입력해주세요."
            ;;
    esac
done
