#!/bin/bash

# keepalived VIP 자동 설정 스크립트
# 작성자: System Administrator
# 설명: keepalived 최신 버전 설치 및 VIP 설정 자동화

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 루트 권한 확인
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "이 스크립트는 root 권한으로 실행해야 합니다."
        exit 1
    fi
}

# OS 확인
detect_os() {
    if [[ -f /etc/redhat-release ]]; then
        OS="rhel"
        if command -v dnf &> /dev/null; then
            PKG_MGR="dnf"
        else
            PKG_MGR="yum"
        fi
    elif [[ -f /etc/debian_version ]]; then
        OS="debian"
        PKG_MGR="apt"
    else
        log_error "지원되지 않는 운영체제입니다."
        exit 1
    fi
    log_info "운영체제: $OS, 패키지 매니저: $PKG_MGR"
}

# 네트워크 인터페이스 확인
get_interfaces() {
    # 실제 사용 가능한 인터페이스만 추출 (@ 문자 처리)
    ip -o link show | awk -F': ' '{print $2}' | sed 's/@.*//g' | grep -v lo | sort -u
}

# IP 주소 유효성 검사
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a octets <<< "$ip"
        for octet in "${octets[@]}"; do
            if ((octet > 255)); then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

# 사용자 입력 받기
get_user_input() {
    echo -e "${BLUE}=== keepalived VIP 설정 ===${NC}"
    echo
    
    # VIP 입력
    while true; do
        read -p "VIP (Virtual IP) 주소를 입력하세요: " VIP
        if validate_ip "$VIP"; then
            break
        else
            log_error "올바른 IP 주소 형식이 아닙니다. 다시 입력해주세요."
        fi
    done
    
    # 네트워크 인터페이스 선택
    echo
    echo "사용 가능한 네트워크 인터페이스:"
    interfaces=$(get_interfaces)
    echo "$interfaces"
    echo
    echo "주의: 인터페이스명에 '@'가 포함된 경우 '@' 앞 부분만 사용하세요"
    echo "예시: eth0@if15 -> eth0"
    echo
    while true; do
        read -p "사용할 네트워크 인터페이스를 입력하세요 (예: eth0, ens33): " INTERFACE_INPUT
        
        # @ 문자가 있으면 앞부분만 추출
        INTERFACE=$(echo "$INTERFACE_INPUT" | sed 's/@.*//g')
        
        # 인터페이스 존재 확인 (실제 인터페이스명으로)
        if ip link show "$INTERFACE" &>/dev/null; then
            log_info "선택된 인터페이스: $INTERFACE"
            break
        else
            log_error "존재하지 않는 인터페이스입니다: $INTERFACE"
            echo "사용 가능한 인터페이스를 다시 확인하세요:"
            ip -o link show | grep -v lo | awk -F': ' '{print "  - "$2}'
        fi
    done
    
    # 서버 역할 선택
    echo
    echo "서버 역할을 선택하세요:"
    echo "1) MASTER"
    echo "2) BACKUP"
    while true; do
        read -p "선택 (1 또는 2): " role_choice
        case $role_choice in
            1)
                ROLE="MASTER"
                DEFAULT_PRIORITY=100
                break
                ;;
            2)
                ROLE="BACKUP"
                DEFAULT_PRIORITY=90
                break
                ;;
            *)
                log_error "1 또는 2를 입력해주세요."
                ;;
        esac
    done
    
    # 우선순위 입력
    echo
    read -p "우선순위를 입력하세요 (기본값: $DEFAULT_PRIORITY, 범위: 1-255): " PRIORITY
    if [[ -z "$PRIORITY" ]]; then
        PRIORITY=$DEFAULT_PRIORITY
    fi
    
    # 우선순위 유효성 검사
    if ! [[ "$PRIORITY" =~ ^[0-9]+$ ]] || [ "$PRIORITY" -lt 1 ] || [ "$PRIORITY" -gt 255 ]; then
        log_warn "잘못된 우선순위입니다. 기본값 $DEFAULT_PRIORITY을 사용합니다."
        PRIORITY=$DEFAULT_PRIORITY
    fi
    
    # VRID 입력
    echo
    read -p "VRID (Virtual Router ID)를 입력하세요 (기본값: 51, 범위: 1-255): " VRID
    if [[ -z "$VRID" ]]; then
        VRID=51
    fi
    
    # VRID 유효성 검사
    if ! [[ "$VRID" =~ ^[0-9]+$ ]] || [ "$VRID" -lt 1 ] || [ "$VRID" -gt 255 ]; then
        log_warn "잘못된 VRID입니다. 기본값 51을 사용합니다."
        VRID=51
    fi
    
    # 인증 패스워드 입력
    echo
    echo "VRRP 인증 설정:"
    echo "1) 인증 사용 안함 (noauth) - 권장"
    echo "2) PASS 인증 사용 (8자 이하)"
    while true; do
        read -p "선택 (1 또는 2): " auth_choice
        case $auth_choice in
            1)
                USE_AUTH=false
                AUTH_PASS=""
                log_info "인증을 사용하지 않습니다."
                break
                ;;
            2)
                USE_AUTH=true
                while true; do
                    read -s -p "인증 패스워드를 입력하세요 (영문+숫자, 8자 이하): " AUTH_PASS
                    echo
                    if [[ -z "$AUTH_PASS" ]]; then
                        log_error "패스워드를 입력해주세요."
                        continue
                    fi
                    
                    # 패스워드 길이 체크
                    if [[ ${#AUTH_PASS} -gt 8 ]]; then
                        log_error "패스워드는 8자 이하여야 합니다."
                        continue
                    fi
                    
                    # 패스워드 형식 체크 (영문, 숫자만 허용)
                    if [[ ! "$AUTH_PASS" =~ ^[a-zA-Z0-9]+$ ]]; then
                        log_error "패스워드는 영문과 숫자만 사용해주세요."
                        continue
                    fi
                    
                    break
                done
                break
                ;;
            *)
                log_error "1 또는 2를 입력해주세요."
                ;;
        esac
    done
    
    # 헬스체크 대상 IP 입력
    echo
    echo "헬스체크를 수행할 대상 IP를 설정합니다."
    echo "옵션:"
    echo "1) localhost (127.0.0.1) - 로컬 서버 체크"
    echo "2) VIP 주소 ($VIP) - VIP로 헬스체크"
    echo "3) 직접 입력 - 특정 IP 주소 지정"
    while true; do
        read -p "선택 (1, 2, 또는 3): " health_choice
        case $health_choice in
            1)
                HEALTH_CHECK_IP="127.0.0.1"
                break
                ;;
            2)
                HEALTH_CHECK_IP="$VIP"
                break
                ;;
            3)
                while true; do
                    read -p "헬스체크할 IP 주소를 입력하세요: " custom_ip
                    if validate_ip "$custom_ip"; then
                        HEALTH_CHECK_IP="$custom_ip"
                        break
                    else
                        log_error "올바른 IP 주소 형식이 아닙니다. 다시 입력해주세요."
                    fi
                done
                break
                ;;
            *)
                log_error "1, 2, 또는 3을 입력해주세요."
                ;;
        esac
    done
    
    # 설정 확인
    echo
    echo -e "${BLUE}=== 설정 확인 ===${NC}"
    echo "VIP: $VIP"
    echo "인터페이스: $INTERFACE"
    echo "역할: $ROLE"
    echo "우선순위: $PRIORITY"
    echo "VRID: $VRID"
    if [[ "$USE_AUTH" == true ]]; then
        echo "인증: PASS 인증 사용 (패스워드: ${#AUTH_PASS}자)"
    else
        echo "인증: 사용 안함"
    fi
    echo "헬스체크 대상 IP: $HEALTH_CHECK_IP"
    echo
    read -p "설정이 맞습니까? (y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "설정을 취소합니다."
        exit 0
    fi
}

# keepalived 설치
install_keepalived() {
    log_info "keepalived 설치를 시작합니다..."
    
    case $OS in
        "rhel")
            $PKG_MGR update -y
            $PKG_MGR install -y keepalived curl telnet
            ;;
        "debian")
            $PKG_MGR update
            $PKG_MGR install -y keepalived curl telnet
            ;;
    esac
    
    # 설치 확인
    if command -v keepalived &> /dev/null; then
        version=$(keepalived --version 2>&1 | head -1)
        log_info "keepalived 설치 완료: $version"
    else
        log_error "keepalived 설치에 실패했습니다."
        exit 1
    fi
}

# 헬스체크 스크립트 생성
create_health_check() {
    log_info "헬스체크 스크립트를 생성합니다..."
    
    cat > /etc/keepalived/check_service.sh << EOF
#!/bin/bash

# 포트 80 헬스체크 스크립트
# 대상 IP: $HEALTH_CHECK_IP
# curl과 telnet을 사용하여 이중 체크

# 설정
TARGET_IP="$HEALTH_CHECK_IP"
TARGET_PORT="80"
TIMEOUT="5"

# 로그 파일
LOG_FILE="/var/log/keepalived_health.log"

# 로그 함수
log_message() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - \$1" >> \$LOG_FILE
}

# curl을 사용한 HTTP 체크
check_http() {
    if curl -s --connect-timeout 3 --max-time \$TIMEOUT http://\$TARGET_IP:\$TARGET_PORT/health > /dev/null 2>&1; then
        return 0
    elif curl -s --connect-timeout 3 --max-time \$TIMEOUT http://\$TARGET_IP:\$TARGET_PORT/ > /dev/null 2>&1; then
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

    # 스크립트 권한 설정 (보안 강화)
    chmod 755 /etc/keepalived/check_service.sh
    chown root:root /etc/keepalived/check_service.sh
    
    log_info "헬스체크 스크립트 생성 및 권한 설정 완료: /etc/keepalived/check_service.sh"
    log_info "헬스체크 대상: $HEALTH_CHECK_IP:80"
}

# keepalived 설정 파일 생성
create_keepalived_config() {
    log_info "keepalived 설정 파일을 생성합니다..."
    
    # 기존 설정 파일 백업
    if [[ -f /etc/keepalived/keepalived.conf ]]; then
        cp /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.backup.$(date +%Y%m%d_%H%M%S)
        log_info "기존 설정 파일을 백업했습니다."
    fi
    
    # 새 설정 파일 생성
    cat > /etc/keepalived/keepalived.conf << EOF
! keepalived configuration file
! Generated on $(date)

global_defs {
    router_id $(hostname)
    script_user root
    enable_script_security
}

vrrp_script chk_service {
    script "/etc/keepalived/check_service.sh"
    interval 3
    weight -2
    fall 3
    rise 2
    user root
}

vrrp_instance VI_1 {
    state $ROLE
    interface $INTERFACE  
    virtual_router_id $VRID
    priority $PRIORITY
    advert_int 1
EOF

    # 인증 설정 추가 (조건부)
    if [[ "$USE_AUTH" == true ]]; then
        cat >> /etc/keepalived/keepalived.conf << EOF
    authentication {
        auth_type PASS
        auth_pass $AUTH_PASS
    }
EOF
    else
        cat >> /etc/keepalived/keepalived.conf << EOF
    nopreempt
EOF
    fi

    # 나머지 설정 추가
    cat >> /etc/keepalived/keepalived.conf << EOF
    virtual_ipaddress {
        $VIP
    }
    track_script {
        chk_service
    }
}
EOF

    log_info "keepalived 설정 파일 생성 완료: /etc/keepalived/keepalived.conf"
}

# 알림 스크립트 생성
create_notify_script() {
    log_info "상태 변경 알림 스크립트를 생성합니다..."
    
    cat > /etc/keepalived/notify.sh << 'EOF'
#!/bin/bash

# keepalived 상태 변경 알림 스크립트

TYPE=$1
NAME=$2
STATE=$3

LOG_FILE="/var/log/keepalived_notify.log"

case $STATE in
    "MASTER")
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Became MASTER" >> $LOG_FILE
        # 필요시 추가 작업 수행
        ;;
    "BACKUP")
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Became BACKUP" >> $LOG_FILE
        # 필요시 추가 작업 수행
        ;;
    "FAULT")
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Entered FAULT state" >> $LOG_FILE
        # 필요시 추가 작업 수행
        ;;
    *)
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Unknown state: $STATE" >> $LOG_FILE
        ;;
esac
EOF

    chmod +x /etc/keepalived/notify.sh
    log_info "알림 스크립트 생성 완료: /etc/keepalived/notify.sh"
}

# 서비스 설정 및 시작
configure_service() {
    log_info "keepalived 서비스를 설정하고 시작합니다..."
    
    # 서비스 활성화
    systemctl enable keepalived
    
    # 설정 파일 검증
    if keepalived -t -f /etc/keepalived/keepalived.conf; then
        log_info "설정 파일 검증 완료"
    else
        log_error "설정 파일에 오류가 있습니다."
        exit 1
    fi
    
    # 서비스 시작
    systemctl restart keepalived
    
    # 서비스 상태 확인
    if systemctl is-active --quiet keepalived; then
        log_info "keepalived 서비스가 정상적으로 시작되었습니다."
    else
        log_error "keepalived 서비스 시작에 실패했습니다."
        systemctl status keepalived
        exit 1
    fi
}

# 방화벽 설정
configure_firewall() {
    log_info "방화벽 설정을 확인합니다..."
    
    case $OS in
        "rhel")
            if systemctl is-active --quiet firewalld; then
                firewall-cmd --permanent --add-rich-rule="rule protocol value='vrrp' accept"
                firewall-cmd --permanent --add-port=80/tcp
                firewall-cmd --reload
                log_info "firewalld 규칙이 추가되었습니다."
            fi
            ;;
        "debian")
            if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
                ufw allow 80/tcp
                log_info "ufw 규칙이 추가되었습니다."
            fi
            ;;
    esac
}

# 상태 확인 및 정보 출력
show_status() {
    echo
    echo -e "${GREEN}=== 설치 및 설정 완료 ===${NC}"
    echo
    echo "서비스 상태:"
    systemctl status keepalived --no-pager -l
    echo
    echo "현재 IP 주소:"
    ip addr show $INTERFACE | grep inet
    echo
    echo "설정 파일 위치:"
    echo "- 메인 설정: /etc/keepalived/keepalived.conf"
    echo "- 헬스체크: /etc/keepalived/check_service.sh"
    echo "- 알림 스크립트: /etc/keepalived/notify.sh"
    echo
    echo "로그 파일:"
    echo "- 서비스 로그: journalctl -u keepalived -f"
    echo "- 헬스체크 대상: $HEALTH_CHECK_IP:80"
    echo "- 헬스체크 로그: tail -f /var/log/keepalived_health.log"
    echo "- 알림 로그: tail -f /var/log/keepalived_notify.log"
    echo
    echo "유용한 명령어:"
    echo "- 서비스 재시작: systemctl restart keepalived"
    echo "- 설정 검증: keepalived -t -f /etc/keepalived/keepalived.conf"
    echo "- VIP 확인: ip addr show | grep $VIP"
    echo
    log_info "keepalived VIP 설정이 완료되었습니다!"
}

# 메인 실행 함수
main() {
    echo -e "${BLUE}"
    echo "======================================"
    echo "   keepalived VIP 자동 설정 스크립트"
    echo "======================================"
    echo -e "${NC}"
    
    check_root
    detect_os
    get_user_input
    install_keepalived
    create_health_check
    create_keepalived_config
    create_notify_script
    configure_service
    configure_firewall
    show_status
}

# 스크립트 실행
main "$@"
