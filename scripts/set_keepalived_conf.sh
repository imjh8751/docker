#!/bin/bash

# ==============================================================================
# Script Name: install_keepalived_final.sh
# Description: Keepalived Source Install & Advanced Configuration (Auth Added)
# ==============================================================================

set -e

# --- [색상 및 로그 설정] ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- [사전 체크] ---
if [ "$EUID" -ne 0 ]; then
    log_error "이 스크립트는 root 권한으로 실행해야 합니다."
    exit 1
fi

# --- [1. OS 감지 및 의존성 설치] ---
detect_os_and_install_dependencies() {
    log_info "OS 감지 및 빌드 의존성 패키지 설치 중..."
    
    if [ -f /etc/redhat-release ]; then
        OS_TYPE="RHEL"
        PKG_MGR="yum"
        # RHEL 계열
        $PKG_MGR install -y gcc make openssl-devel libnl3-devel ipset-devel iptables-devel file curl wget net-tools libnftnl-devel libmnl-devel
    elif [ -f /etc/debian_version ]; then
        OS_TYPE="Debian"
        PKG_MGR="apt-get"
        $PKG_MGR update
        # Debian/Ubuntu 계열 (Ubuntu 24.04 대응: libiptables-dev 제거 -> libnftnl-dev libmnl-dev)
        $PKG_MGR install -y build-essential libssl-dev libnl-3-dev libnl-genl-3-dev libipset-dev libnftnl-dev libmnl-dev curl wget net-tools
    else
        log_error "지원하지 않는 OS입니다."
        exit 1
    fi
    log_info "OS: $OS_TYPE, 의존성 설치 완료."
}

# --- [유효성 검사 함수] ---
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a octets <<< "$ip"
        for octet in "${octets[@]}"; do
            if ((octet > 255)); then return 1; fi
        done
        return 0
    else
        return 1
    fi
}

get_interfaces() {
    ip -o link show | awk -F': ' '{print $2}' | sed 's/@.*//g' | grep -v lo | sort -u
}

# --- [2. 사용자 입력 및 설정] ---
get_user_input() {
    echo -e "${BLUE}=== Keepalived 설정 입력 ===${NC}"

    # 1. VIP 입력
    while true; do
        read -p "VIP (Virtual IP) 주소 입력: " VIP
        if validate_ip "$VIP"; then break; else log_error "잘못된 IP 형식입니다."; fi
    done

    # 2. 인터페이스 선택
    echo -e "\n사용 가능한 인터페이스 목록:"
    get_interfaces
    while true; do
        read -p "Keepalived를 적용할 인터페이스 이름: " INTERFACE
        if ip link show "$INTERFACE" &>/dev/null; then break; else log_error "존재하지 않는 인터페이스입니다."; fi
    done

    # 3. 역할 선택
    echo -e "\n서버 역할 선택:"
    select ROLE_OPT in "MASTER" "BACKUP"; do
        case $ROLE_OPT in
            MASTER) ROLE="MASTER"; PRIORITY=101; break ;;
            BACKUP) ROLE="BACKUP"; PRIORITY=100; break ;;
            *) log_error "1 또는 2를 선택하세요." ;;
        esac
    done

    # 4. 인증 설정 (추가된 부분)
    echo -e "\n=== VRRP 인증 설정 ==="
    read -p "인증 유형 (auth_type) [기본값: PASS]: " AUTH_TYPE
    AUTH_TYPE=${AUTH_TYPE:-PASS}

    while true; do
        read -p "인증 비밀번호 (auth_pass) [최대 8자]: " AUTH_PASS
        # 길이 체크: 1글자 이상, 8글자 이하
        if [[ ${#AUTH_PASS} -gt 0 && ${#AUTH_PASS} -le 8 ]]; then
            break
        else
            log_error "비밀번호는 1자 이상 8자 이하여야 합니다. (Keepalived 제한)"
        fi
    done

    # 5. 헬스 체크 포트
    echo -e ""
    read -p "감시할 서비스 포트 (예: 80, 443, 6443): " CHECK_PORT
    CHECK_PORT=${CHECK_PORT:-80}
}

# --- [3. 소스 다운로드 및 컴파일 설치] ---
install_keepalived_source() {
    log_info "Keepalived 소스 다운로드 및 컴파일 시작..."
    
    KEEPALIVED_VERSION="2.2.8"
    SRC_DIR="/usr/local/src/keepalived-${KEEPALIVED_VERSION}"
    
    cd /usr/local/src
    if [ ! -d "$SRC_DIR" ]; then
        if ! wget https://www.keepalived.org/software/keepalived-${KEEPALIVED_VERSION}.tar.gz; then
             log_error "소스 다운로드 실패. 인터넷 연결을 확인하세요."
             exit 1
        fi
        tar -xvf keepalived-${KEEPALIVED_VERSION}.tar.gz
    fi
    
    cd "$SRC_DIR"
    
    log_info "Configure 실행 중..."
    ./configure --prefix=/usr/local --sysconfdir=/etc
    
    log_info "Make & Install 실행 중..."
    make && make install
    
    if [ ! -f /etc/systemd/system/keepalived.service ]; then
        if [ -f ./keepalived/keepalived.service ]; then
            cp ./keepalived/keepalived.service /etc/systemd/system/
        else 
            cp /usr/local/src/keepalived-${KEEPALIVED_VERSION}/keepalived/keepalived.service /etc/systemd/system/ 2>/dev/null || true
        fi
        systemctl daemon-reload
    fi
    
    log_info "Keepalived 설치 완료."
}

# --- [4. 헬스 체크 및 알림 스크립트 생성] ---
create_scripts() {
    CONF_DIR="/etc/keepalived"
    mkdir -p $CONF_DIR

    cat <<EOF > $CONF_DIR/check_service.sh
아하, 어떤 의도인지 정확히 이해했습니다! 작성하시려는 구문이 다른 쉘 스크립트 파일 내부에 포함되는 형태라면, EOF를 따옴표로 감싸는 대신 변수 앞에 역슬래시(\)를 붙여서 상위 스크립트가 변수를 가로채지 않도록 처리해야 하죠.

사용자가 요청하신 이중 체크(curl + tcp) 로직에 역슬래시 처리를 완벽하게 적용한 코드는 다음과 같습니다.

역슬래시(\) 처리가 포함된 스크립트 생성 구문
Bash
cat <<EOF > $CONF_DIR/check_service.sh
#!/bin/bash

# 설정
TARGET_IP="127.0.0.1"
TARGET_PORT="$CHECK_PORT"
TIMEOUT="5"

# 로그 파일
LOG_FILE="/var/log/keepalived_health.log"

# 로그 함수
log_message() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - \$1" >> "\$LOG_FILE"
}

# curl을 사용한 HTTP 체크
check_http() {
    if curl -s --connect-timeout 3 --max-time \$TIMEOUT "http://\$TARGET_IP:\$TARGET_PORT/health" > /dev/null 2>&1; then
        return 0
    elif curl -s --connect-timeout 3 --max-time \$TIMEOUT "http://\$TARGET_IP:\$TARGET_PORT/" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# telnet을 사용한 포트 체크
check_port() {
    if timeout \$TIMEOUT bash -c "</dev/tcp/\$TARGET_IP/\$TARGET_PORT" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 메인 헬스체크 로직
if check_http && check_port; then
    log_message "Health check PASSED - \$TARGET_IP:\$TARGET_PORT is accessible"
    exit 0
else
    log_message "Health check FAILED - \$TARGET_IP:\$TARGET_PORT is not responding"
    exit 1
fi
EOF
    chmod +x $CONF_DIR/check_service.sh

    cat <<EOF > $CONF_DIR/notify.sh
#!/bin/bash
TYPE=\$1
NAME=\$2
STATE=\$3
LOG_FILE="/var/log/keepalived_notify.log"
echo "\$(date) - Keepalived State Change: \$STATE" >> \$LOG_FILE
EOF
    chmod +x $CONF_DIR/notify.sh

    log_info "헬스 체크 및 알림 스크립트 생성 완료."
}

# --- [5. 설정 파일(keepalived.conf) 생성] ---
create_config() {
    log_info "keepalived.conf 파일 생성 중..."
    
    ROUTER_ID=$(hostname)
    VRID=51

    cat <<EOF > /etc/keepalived/keepalived.conf
! Configuration File for keepalived

global_defs {
   router_id $ROUTER_ID
   script_user root
   enable_script_security
}

vrrp_script chk_service {
    script "/etc/keepalived/check_service.sh"
    interval 3
    weight -2
    fall 3
    rise 2
}

vrrp_instance VI_1 {
    state $ROLE
    interface $INTERFACE
    virtual_router_id $VRID
    priority $PRIORITY
    advert_int 1
    
    # 사용자 입력 인증 정보 적용
    authentication {
        auth_type $AUTH_TYPE
        auth_pass $AUTH_PASS
    }
    
    virtual_ipaddress {
        $VIP
    }
    
    track_script {
        chk_service
    }
    
    notify "/etc/keepalived/notify.sh"
}
EOF
}

# --- [6. 방화벽 설정] ---
configure_firewall() {
    log_info "방화벽 설정 (VRRP 및 서비스 포트 허용)..."
    
    if [ "$OS_TYPE" == "RHEL" ]; then
        if systemctl is-active --quiet firewalld; then
            firewall-cmd --permanent --add-rich-rule="rule protocol value='vrrp' accept"
            firewall-cmd --permanent --add-port=${CHECK_PORT}/tcp
            firewall-cmd --reload
        fi
    elif [ "$OS_TYPE" == "Debian" ]; then
        if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
            ufw allow vrrp
            ufw allow ${CHECK_PORT}/tcp
        fi
    fi
}

# --- [7. 서비스 시작] ---
start_service() {
    log_info "서비스 시작 및 상태 확인..."
    systemctl enable keepalived
    systemctl restart keepalived
    sleep 2
    
    if systemctl is-active --quiet keepalived; then
        log_info "Keepalived 서비스가 정상 실행 중입니다."
        echo -e "${BLUE}=== 설정 요약 ===${NC}"
        echo " - 역할: $ROLE (Priority: $PRIORITY)"
        echo " - VIP: $VIP"
        echo " - 인증: $AUTH_TYPE / $AUTH_PASS"
        echo " - 감시 포트: $CHECK_PORT"
        ip addr show $INTERFACE | grep "$VIP"
    else
        log_error "서비스 실행 실패. 'systemctl status keepalived'를 확인하세요."
    fi
}

# --- [메인 실행] ---
detect_os_and_install_dependencies
get_user_input
install_keepalived_source
create_scripts
create_config
configure_firewall
start_service
