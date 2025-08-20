#!/bin/bash

# 사용자 및 그룹 관리 스크립트 (고급 기능 포함)
# Linux/Ubuntu/Debian 호환
# 실행 권한: sudo 필요

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 설정 파일 경로
CONFIG_DIR="/etc/user_manager"
LOG_FILE="/var/log/user_manager.log"
BACKUP_DIR="/var/backups/user_manager"
PASSWORD_POLICY_FILE="$CONFIG_DIR/password_policy.conf"

# OS 감지 함수
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VERSION=$(lsb_release -sr)
    else
        OS=$(uname -s)
        VERSION=$(uname -r)
    fi
}

# 로그 함수들
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >> "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> "$LOG_FILE"
}

log_question() {
    echo -e "${BLUE}[?]${NC} $1"
}

log_activity() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ACTIVITY] $1" >> "$LOG_FILE"
}

# 초기화 함수
initialize_environment() {
    # 디렉토리 생성
    mkdir -p "$CONFIG_DIR" "$BACKUP_DIR"
    touch "$LOG_FILE"
    
    # 기본 비밀번호 정책 파일 생성
    if [ ! -f "$PASSWORD_POLICY_FILE" ]; then
        cat > "$PASSWORD_POLICY_FILE" << 'EOF'
# 비밀번호 정책 설정
MIN_LENGTH=8
MAX_LENGTH=128
REQUIRE_UPPERCASE=true
REQUIRE_LOWERCASE=true
REQUIRE_NUMBERS=true
REQUIRE_SPECIAL=true
MAX_AGE=90
MIN_AGE=1
WARN_AGE=7
HISTORY_SIZE=5
EOF
    fi
}

# 권한 확인
check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        log_error "이 스크립트는 sudo 권한이 필요합니다."
        echo "사용법: sudo $0"
        exit 1
    fi
}

# 사용자 존재 확인
user_exists() {
    id "$1" &>/dev/null
}

# 그룹 존재 확인
group_exists() {
    getent group "$1" &>/dev/null
}

# 비밀번호 정책 로드
load_password_policy() {
    if [ -f "$PASSWORD_POLICY_FILE" ]; then
        source "$PASSWORD_POLICY_FILE"
    fi
}

# 비밀번호 정책 설정
configure_password_policy() {
    echo -e "${CYAN}=== 비밀번호 정책 설정 ===${NC}"
    
    load_password_policy
    
    log_question "최소 길이 (현재: $MIN_LENGTH):"
    read -r min_len
    MIN_LENGTH=${min_len:-$MIN_LENGTH}
    
    log_question "최대 길이 (현재: $MAX_LENGTH):"
    read -r max_len
    MAX_LENGTH=${max_len:-$MAX_LENGTH}
    
    log_question "대문자 필수 (y/n, 현재: $REQUIRE_UPPERCASE):"
    read -r req_upper
    case $req_upper in
        [Yy]*) REQUIRE_UPPERCASE=true ;;
        [Nn]*) REQUIRE_UPPERCASE=false ;;
    esac
    
    log_question "소문자 필수 (y/n, 현재: $REQUIRE_LOWERCASE):"
    read -r req_lower
    case $req_lower in
        [Yy]*) REQUIRE_LOWERCASE=true ;;
        [Nn]*) REQUIRE_LOWERCASE=false ;;
    esac
    
    log_question "숫자 필수 (y/n, 현재: $REQUIRE_NUMBERS):"
    read -r req_num
    case $req_num in
        [Yy]*) REQUIRE_NUMBERS=true ;;
        [Nn]*) REQUIRE_NUMBERS=false ;;
    esac
    
    log_question "특수문자 필수 (y/n, 현재: $REQUIRE_SPECIAL):"
    read -r req_spec
    case $req_spec in
        [Yy]*) REQUIRE_SPECIAL=true ;;
        [Nn]*) REQUIRE_SPECIAL=false ;;
    esac
    
    log_question "비밀번호 만료일 (일, 현재: $MAX_AGE):"
    read -r max_age
    MAX_AGE=${max_age:-$MAX_AGE}
    
    log_question "비밀번호 변경 후 재변경 금지 기간 (일, 현재: $MIN_AGE):"
    read -r min_age
    MIN_AGE=${min_age:-$MIN_AGE}
    
    log_question "만료 경고 기간 (일, 현재: $WARN_AGE):"
    read -r warn_age
    WARN_AGE=${warn_age:-$WARN_AGE}
    
    log_question "비밀번호 히스토리 개수 (현재: $HISTORY_SIZE):"
    read -r hist_size
    HISTORY_SIZE=${hist_size:-$HISTORY_SIZE}
    
    # 정책 파일 저장
    cat > "$PASSWORD_POLICY_FILE" << EOF
# 비밀번호 정책 설정
MIN_LENGTH=$MIN_LENGTH
MAX_LENGTH=$MAX_LENGTH
REQUIRE_UPPERCASE=$REQUIRE_UPPERCASE
REQUIRE_LOWERCASE=$REQUIRE_LOWERCASE
REQUIRE_NUMBERS=$REQUIRE_NUMBERS
REQUIRE_SPECIAL=$REQUIRE_SPECIAL
MAX_AGE=$MAX_AGE
MIN_AGE=$MIN_AGE
WARN_AGE=$WARN_AGE
HISTORY_SIZE=$HISTORY_SIZE
EOF
    
    # PAM 설정 업데이트 (Ubuntu/Debian)
    if command -v pam-auth-update >/dev/null 2>&1; then
        # pwquality 설정
        if [ -f /etc/security/pwquality.conf ]; then
            cp /etc/security/pwquality.conf /etc/security/pwquality.conf.bak
            cat > /etc/security/pwquality.conf << EOF
minlen = $MIN_LENGTH
maxlen = $MAX_LENGTH
dcredit = $([ "$REQUIRE_NUMBERS" = "true" ] && echo "-1" || echo "0")
ucredit = $([ "$REQUIRE_UPPERCASE" = "true" ] && echo "-1" || echo "0")
lcredit = $([ "$REQUIRE_LOWERCASE" = "true" ] && echo "-1" || echo "0")
ocredit = $([ "$REQUIRE_SPECIAL" = "true" ] && echo "-1" || echo "0")
remember = $HISTORY_SIZE
EOF
        fi
        
        # login.defs 설정
        if [ -f /etc/login.defs ]; then
            cp /etc/login.defs /etc/login.defs.bak
            sed -i "s/^PASS_MAX_DAYS.*/PASS_MAX_DAYS\t$MAX_AGE/" /etc/login.defs
            sed -i "s/^PASS_MIN_DAYS.*/PASS_MIN_DAYS\t$MIN_AGE/" /etc/login.defs
            sed -i "s/^PASS_WARN_AGE.*/PASS_WARN_AGE\t$WARN_AGE/" /etc/login.defs
        fi
    fi
    
    log_info "비밀번호 정책이 설정되었습니다."
    log_activity "Password policy configured: MIN_LENGTH=$MIN_LENGTH, MAX_AGE=$MAX_AGE"
}

# 비밀번호 검증
validate_password() {
    local password="$1"
    load_password_policy
    
    local errors=()
    
    if [[ ${#password} -lt $MIN_LENGTH ]]; then
        errors+=("최소 $MIN_LENGTH자 이상이어야 합니다")
    fi
    
    if [[ ${#password} -gt $MAX_LENGTH ]]; then
        errors+=("최대 $MAX_LENGTH자 이하여야 합니다")
    fi
    
    if [[ "$REQUIRE_UPPERCASE" == "true" ]] && [[ ! "$password" =~ [A-Z] ]]; then
        errors+=("대문자를 포함해야 합니다")
    fi
    
    if [[ "$REQUIRE_LOWERCASE" == "true" ]] && [[ ! "$password" =~ [a-z] ]]; then
        errors+=("소문자를 포함해야 합니다")
    fi
    
    if [[ "$REQUIRE_NUMBERS" == "true" ]] && [[ ! "$password" =~ [0-9] ]]; then
        errors+=("숫자를 포함해야 합니다")
    fi
    
    if [[ "$REQUIRE_SPECIAL" == "true" ]] && [[ ! "$password" =~ [^a-zA-Z0-9] ]]; then
        errors+=("특수문자를 포함해야 합니다")
    fi
    
    if [[ ${#errors[@]} -gt 0 ]]; then
        log_error "비밀번호 정책 위반:"
        for error in "${errors[@]}"; do
            echo "  - $error"
        done
        return 1
    fi
    
    return 0
}

# sudo 권한 설정 함수
configure_sudo_access() {
    local username="$1"
    
    echo -e "\n${CYAN}=== sudo 권한 설정 ===${NC}"
    echo "1) 기본 sudo 권한 (비밀번호 필요)"
    echo "2) 비밀번호 없는 sudo 권한 (NOPASSWD)"
    echo "3) 특정 명령어만 sudo 허용"
    echo "4) 시간 제한 sudo 권한"
    echo "5) sudo 그룹 추가만"
    
    log_question "sudo 권한 유형을 선택하세요:"
    read -r sudo_type
    
    case $sudo_type in
        1)
            # 기본 sudo 권한
            usermod -aG sudo "$username"
            log_info "기본 sudo 권한 부여 완료 (비밀번호 필요)"
            log_activity "Standard sudo access granted to user: $username"
            ;;
        2)
            # 비밀번호 없는 sudo 권한
            usermod -aG sudo "$username"
            echo "$username ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$username"
            chmod 440 "/etc/sudoers.d/$username"
            log_info "비밀번호 없는 sudo 권한 부여 완료"
            log_activity "NOPASSWD sudo access granted to user: $username"
            
            log_warn "보안 경고: 비밀번호 없는 sudo 권한은 보안 위험을 초래할 수 있습니다."
            ;;
        3)
            # 특정 명령어만 sudo 허용
            usermod -aG sudo "$username"
            
            echo "사용 가능한 명령어 예시:"
            echo "  /bin/systemctl"
            echo "  /usr/bin/apt"
            echo "  /bin/mount, /bin/umount"
            echo "  /usr/sbin/service"
            echo "  /bin/kill"
            
            log_question "허용할 명령어들을 쉼표로 구분하여 입력하세요:"
            read -r allowed_commands
            
            log_question "비밀번호 없이 실행하시겠습니까? (y/n)"
            read -r no_passwd
            
            if [[ $no_passwd =~ ^[Yy]$ ]]; then
                echo "$username ALL=(ALL) NOPASSWD: $allowed_commands" > "/etc/sudoers.d/$username"
            else
                echo "$username ALL=(ALL) $allowed_commands" > "/etc/sudoers.d/$username"
            fi
            
            chmod 440 "/etc/sudoers.d/$username"
            log_info "특정 명령어 sudo 권한 부여 완료"
            log_activity "Limited sudo access granted to user: $username, commands: $allowed_commands"
            ;;
        4)
            # 시간 제한 sudo 권한
            usermod -aG sudo "$username"
            
            log_question "sudo 권한 만료일을 입력하세요 (YYYY-MM-DD 형식):"
            read -r expire_date
            
            log_question "비밀번호 없이 실행하시겠습니까? (y/n)"
            read -r no_passwd
            
            if [[ $no_passwd =~ ^[Yy]$ ]]; then
                sudo_rule="$username ALL=(ALL) NOPASSWD:ALL"
            else
                sudo_rule="$username ALL=(ALL) ALL"
            fi
            
            echo "# Sudo access expires on $expire_date" > "/etc/sudoers.d/$username"
            echo "$sudo_rule" >> "/etc/sudoers.d/$username"
            chmod 440 "/etc/sudoers.d/$username"
            
            # cron job으로 만료일에 권한 제거 스케줄링
            cron_command="0 0 $(date -d "$expire_date" +%d) $(date -d "$expire_date" +%m) * root /bin/rm -f /etc/sudoers.d/$username && /usr/sbin/gpasswd -d $username sudo"
            echo "$cron_command" >> /etc/crontab
            
            log_info "시간 제한 sudo 권한 부여 완료 (만료일: $expire_date)"
            log_activity "Time-limited sudo access granted to user: $username, expires: $expire_date"
            ;;
        5)
            # sudo 그룹만 추가
            usermod -aG sudo "$username"
            log_info "sudo 그룹 추가 완료"
            log_activity "Added to sudo group: $username"
            ;;
        *)
            log_error "잘못된 선택입니다."
            return 1
            ;;
    esac
    
    # sudoers 파일 문법 검사
    if ! visudo -c; then
        log_error "sudoers 파일에 문법 오류가 있습니다. 권한 설정을 확인하세요."
        return 1
    fi
}

# sudo 권한 관리 함수
manage_sudo_permissions() {
    local username="$1"
    
    echo -e "\n${CYAN}=== sudo 권한 관리: $username ===${NC}"
    
    # 현재 sudo 상태 확인
    if groups "$username" | grep -q sudo; then
        echo "현재 상태: sudo 그룹 멤버"
        
        if [ -f "/etc/sudoers.d/$username" ]; then
            echo "개별 sudo 설정:"
            cat "/etc/sudoers.d/$username"
        fi
    else
        echo "현재 상태: sudo 권한 없음"
    fi
    
    echo
    echo "1) sudo 권한 부여/수정"
    echo "2) sudo 권한 완전 제거"
    echo "3) sudo 설정 파일 편집"
    echo "4) sudo 사용 기록 확인"
    echo "5) sudo 권한 테스트"
    echo "0) 돌아가기"
    
    log_question "선택하세요:"
    read -r sudo_choice
    
    case $sudo_choice in
        1)
            configure_sudo_access "$username"
            ;;
        2)
            # sudo 권한 완전 제거
            gpasswd -d "$username" sudo 2>/dev/null
            rm -f "/etc/sudoers.d/$username"
            
            # crontab에서 관련 항목 제거
            if grep -q "$username" /etc/crontab; then
                sed -i "/$username/d" /etc/crontab
            fi
            
            log_info "sudo 권한이 완전히 제거되었습니다."
            log_activity "All sudo access removed from user: $username"
            ;;
        3)
            # sudo 설정 파일 편집
            if [ -f "/etc/sudoers.d/$username" ]; then
                log_info "현재 설정:"
                cat "/etc/sudoers.d/$username"
                echo
                
                log_question "설정을 편집하시겠습니까? (y/n)"
                read -r edit_config
                
                if [[ $edit_config =~ ^[Yy]$ ]]; then
                    nano "/etc/sudoers.d/$username"
                    
                    # 문법 검사
                    if ! visudo -c; then
                        log_error "설정 파일에 오류가 있습니다."
                        log_question "이전 설정으로 복원하시겠습니까? (y/n)"
                        read -r restore
                        if [[ $restore =~ ^[Yy]$ ]]; then
                            rm -f "/etc/sudoers.d/$username"
                            log_info "설정이 제거되었습니다."
                        fi
                    else
                        log_info "설정이 업데이트되었습니다."
                        log_activity "Sudo configuration edited for user: $username"
                    fi
                fi
            else
                log_error "개별 sudo 설정 파일이 없습니다."
            fi
            ;;
        4)
            # sudo 사용 기록 확인
            echo "=== $username의 sudo 사용 기록 ==="
            grep "sudo.*$username" /var/log/auth.log 2>/dev/null | tail -20 || \
            journalctl | grep "sudo.*$username" | tail -20 || \
            echo "sudo 사용 기록이 없습니다."
            ;;
        5)
            # sudo 권한 테스트
            log_info "sudo 권한 테스트 중..."
            
            if groups "$username" | grep -q sudo; then
                echo "✓ sudo 그룹 멤버입니다."
                
                if [ -f "/etc/sudoers.d/$username" ]; then
                    echo "✓ 개별 sudo 설정이 있습니다."
                    echo "설정 내용:"
                    cat "/etc/sudoers.d/$username"
                else
                    echo "• 기본 sudo 그룹 권한을 사용합니다."
                fi
                
                # 실제 권한 테스트 (안전한 명령어 사용)
                log_question "실제 sudo 명령어를 테스트하시겠습니까? (sudo whoami 실행) (y/n)"
                read -r test_sudo
                
                if [[ $test_sudo =~ ^[Yy]$ ]]; then
                    su - "$username" -c "sudo whoami" && \
                    log_info "sudo 권한이 정상적으로 작동합니다." || \
                    log_error "sudo 권한 실행에 문제가 있습니다."
                fi
            else
                echo "✗ sudo 그룹 멤버가 아닙니다."
            fi
            ;;
        0)
            return 0
            ;;
        *)
            log_error "잘못된 선택입니다."
            ;;
    esac
}

# 쉘 관리 기능
manage_user_shell() {
    log_question "사용자명을 입력하세요:"
    read -r username
    
    if ! user_exists "$username"; then
        log_error "사용자 '$username'이 존재하지 않습니다."
        return 1
    fi
    
    current_shell=$(getent passwd "$username" | cut -d: -f7)
    echo "현재 쉘: $current_shell"
    
    echo -e "\n${CYAN}=== 쉘 관리 ===${NC}"
    echo "1) 쉘 변경"
    echo "2) 로그인 허용/금지 설정"
    echo "3) 사용 가능한 쉘 목록"
    echo "4) bash 설정 확인"
    echo "5) 쉘 히스토리 관리"
    
    log_question "선택하세요:"
    read -r shell_choice
    
    case $shell_choice in
        1)
            echo "사용 가능한 쉘:"
            cat /etc/shells
            log_question "새 쉘을 입력하세요:"
            read -r new_shell
            
            if grep -q "^$new_shell$" /etc/shells; then
                usermod -s "$new_shell" "$username"
                log_info "사용자 '$username'의 쉘이 '$new_shell'로 변경되었습니다."
                log_activity "Shell changed for user $username: $current_shell -> $new_shell"
            else
                log_error "유효하지 않은 쉘입니다."
            fi
            ;;
        2)
            echo "1) 로그인 허용"
            echo "2) 로그인 금지 (/usr/sbin/nologin)"
            echo "3) 로그인 금지 (/bin/false)"
            
            log_question "선택하세요:"
            read -r login_choice
            
            case $login_choice in
                1)
                    usermod -s /bin/bash "$username"
                    log_info "로그인이 허용되었습니다."
                    ;;
                2)
                    usermod -s /usr/sbin/nologin "$username"
                    log_info "로그인이 금지되었습니다 (nologin)."
                    ;;
                3)
                    usermod -s /bin/false "$username"
                    log_info "로그인이 금지되었습니다 (false)."
                    ;;
            esac
            log_activity "Login access modified for user $username"
            ;;
        3)
            echo "=== 사용 가능한 쉘 목록 ==="
            cat /etc/shells
            ;;
        4)
            echo "=== bash 설정 확인 ==="
            user_home=$(eval echo ~"$username")
            echo "홈 디렉토리: $user_home"
            
            if [ -f "$user_home/.bashrc" ]; then
                echo ".bashrc 파일: 존재"
                echo "마지막 수정: $(stat -c %y "$user_home/.bashrc")"
            else
                echo ".bashrc 파일: 없음"
            fi
            
            if [ -f "$user_home/.bash_profile" ]; then
                echo ".bash_profile 파일: 존재"
            else
                echo ".bash_profile 파일: 없음"
            fi
            
            # bash 버전 확인
            echo "시스템 bash 버전: $(bash --version | head -1)"
            ;;
        5)
            echo "=== 쉘 히스토리 관리 ==="
            user_home=$(eval echo ~"$username")
            
            if [ -f "$user_home/.bash_history" ]; then
                echo "히스토리 파일 크기: $(wc -l < "$user_home/.bash_history") 라인"
                
                log_question "히스토리를 삭제하시겠습니까? (y/n)"
                read -r clear_history
                
                if [[ $clear_history =~ ^[Yy]$ ]]; then
                    > "$user_home/.bash_history"
                    log_info "히스토리가 삭제되었습니다."
                    log_activity "History cleared for user $username"
                fi
            else
                echo "히스토리 파일이 없습니다."
            fi
            ;;
    esac
}

# 사용자 활동 로그 보기
show_user_activity() {
    echo -e "${CYAN}=== 사용자 활동 로그 ===${NC}"
    echo "1) 전체 로그 보기"
    echo "2) 특정 사용자 로그"
    echo "3) 최근 활동 (24시간)"
    echo "4) 로그인 실패 기록"
    echo "5) sudo 사용 기록"
    
    log_question "선택하세요:"
    read -r log_choice
    
    case $log_choice in
        1)
            if [ -f "$LOG_FILE" ]; then
                less "$LOG_FILE"
            else
                log_error "로그 파일이 없습니다."
            fi
            ;;
        2)
            log_question "사용자명을 입력하세요:"
            read -r username
            if [ -f "$LOG_FILE" ]; then
                grep "$username" "$LOG_FILE" | less
            fi
            # 시스템 로그에서도 검색
            journalctl -u ssh -u systemd-logind | grep "$username" | tail -20
            ;;
        3)
            echo "=== 최근 24시간 활동 ==="
            # 로그인 기록
            echo "최근 로그인:"
            last -n 20
            echo
            # 스크립트 로그
            if [ -f "$LOG_FILE" ]; then
                echo "스크립트 활동:"
                tail -50 "$LOG_FILE"
            fi
            ;;
        4)
            echo "=== 로그인 실패 기록 ==="
            if command -v lastb >/dev/null 2>&1; then
                lastb -n 20
            else
                grep "Failed password" /var/log/auth.log 2>/dev/null | tail -20 || \
                journalctl -u ssh | grep "Failed password" | tail -20
            fi
            ;;
        5)
            echo "=== sudo 사용 기록 ==="
            grep "sudo" /var/log/auth.log 2>/dev/null | tail -20 || \
            journalctl | grep "sudo" | tail -20
            ;;
    esac
}

# 백업 생성
create_backup() {
    local backup_name="backup_$(date +%Y%m%d_%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    log_info "백업 생성 중: $backup_path"
    
    mkdir -p "$backup_path"
    
    # 중요 파일들 백업
    cp /etc/passwd "$backup_path/passwd"
    cp /etc/shadow "$backup_path/shadow"
    cp /etc/group "$backup_path/group"
    cp /etc/gshadow "$backup_path/gshadow"
    
    if [ -f /etc/login.defs ]; then
        cp /etc/login.defs "$backup_path/login.defs"
    fi
    
    if [ -f /etc/security/pwquality.conf ]; then
        cp /etc/security/pwquality.conf "$backup_path/pwquality.conf"
    fi
    
    # 홈 디렉토리 목록
    ls -la /home > "$backup_path/home_directories.list"
    
    # 설정 파일 백업
    if [ -d "$CONFIG_DIR" ]; then
        cp -r "$CONFIG_DIR" "$backup_path/config"
    fi
    
    # 백업 정보 파일 생성
    cat > "$backup_path/backup_info.txt" << EOF
백업 생성 시간: $(date)
운영체제: $OS $VERSION
생성자: $(whoami)
백업 포함 내용:
- /etc/passwd, /etc/shadow, /etc/group, /etc/gshadow
- /etc/login.defs (비밀번호 정책)
- /etc/security/pwquality.conf
- 홈 디렉토리 목록
- 사용자 관리 설정 파일
EOF
    
    # 압축
    tar -czf "$backup_path.tar.gz" -C "$BACKUP_DIR" "$backup_name"
    rm -rf "$backup_path"
    
    log_info "백업 완료: $backup_path.tar.gz"
    log_activity "Backup created: $backup_path.tar.gz"
}

# 백업 복원
restore_backup() {
    echo -e "${CYAN}=== 백업 복원 ===${NC}"
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        log_error "백업 파일이 없습니다."
        return 1
    fi
    
    echo "사용 가능한 백업:"
    ls -la "$BACKUP_DIR"/*.tar.gz 2>/dev/null || {
        log_error "백업 파일이 없습니다."
        return 1
    }
    
    log_question "복원할 백업 파일명을 입력하세요 (확장자 제외):"
    read -r backup_name
    
    local backup_file="$BACKUP_DIR/$backup_name.tar.gz"
    
    if [ ! -f "$backup_file" ]; then
        log_error "백업 파일을 찾을 수 없습니다: $backup_file"
        return 1
    fi
    
    log_warn "주의: 이 작업은 현재 사용자/그룹 설정을 덮어씁니다."
    log_question "정말 복원하시겠습니까? (yes/no)"
    read -r confirm
    
    if [[ "$confirm" != "yes" ]]; then
        log_info "복원이 취소되었습니다."
        return 0
    fi
    
    # 현재 설정 백업
    local current_backup="$BACKUP_DIR/before_restore_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$current_backup"
    cp /etc/passwd /etc/shadow /etc/group /etc/gshadow "$current_backup/"
    
    # 백업 압축 해제
    local temp_dir="/tmp/restore_$"
    mkdir -p "$temp_dir"
    tar -xzf "$backup_file" -C "$temp_dir"
    
    local extract_dir="$temp_dir/$backup_name"
    
    # 파일 복원
    if [ -f "$extract_dir/passwd" ]; then
        cp "$extract_dir/passwd" /etc/passwd
        log_info "/etc/passwd 복원됨"
    fi
    
    if [ -f "$extract_dir/shadow" ]; then
        cp "$extract_dir/shadow" /etc/shadow
        chmod 640 /etc/shadow
        log_info "/etc/shadow 복원됨"
    fi
    
    if [ -f "$extract_dir/group" ]; then
        cp "$extract_dir/group" /etc/group
        log_info "/etc/group 복원됨"
    fi
    
    if [ -f "$extract_dir/gshadow" ]; then
        cp "$extract_dir/gshadow" /etc/gshadow
        chmod 640 /etc/gshadow
        log_info "/etc/gshadow 복원됨"
    fi
    
    if [ -f "$extract_dir/login.defs" ]; then
        cp "$extract_dir/login.defs" /etc/login.defs
        log_info "/etc/login.defs 복원됨"
    fi
    
    if [ -f "$extract_dir/pwquality.conf" ]; then
        cp "$extract_dir/pwquality.conf" /etc/security/pwquality.conf
        log_info "/etc/security/pwquality.conf 복원됨"
    fi
    
    # 설정 디렉토리 복원
    if [ -d "$extract_dir/config" ]; then
        cp -r "$extract_dir/config"/* "$CONFIG_DIR/"
        log_info "설정 파일 복원됨"
    fi
    
    # 임시 파일 정리
    rm -rf "$temp_dir"
    
    log_info "복원 완료. 현재 설정은 $current_backup에 백업되었습니다."
    log_activity "Backup restored: $backup_file"
}

# 그룹 생성 함수
create_group() {
    log_question "새 그룹을 생성하시겠습니까? (y/n)"
    read -r create_group_choice
    
    if [[ $create_group_choice =~ ^[Yy]$ ]]; then
        log_question "그룹명을 입력하세요:"
        read -r group_name
        
        if group_exists "$group_name"; then
            log_warn "그룹 '$group_name'이 이미 존재합니다."
        else
            log_question "그룹 ID(GID)를 지정하시겠습니까? (y/n)"
            read -r set_gid
            
            if [[ $set_gid =~ ^[Yy]$ ]]; then
                log_question "GID를 입력하세요:"
                read -r gid
                groupadd -g "$gid" "$group_name"
            else
                groupadd "$group_name"
            fi
            
            if [[ $? -eq 0 ]]; then
                log_info "그룹 '$group_name' 생성 완료"
                log_activity "Group created: $group_name"
            else
                log_error "그룹 생성 실패"
            fi
        fi
    fi
}

# 사용자 생성 함수
create_user() {
    log_question "사용자명을 입력하세요:"
    read -r username
    
    if user_exists "$username"; then
        log_error "사용자 '$username'이 이미 존재합니다."
        return 1
    fi
    
    # 기본 옵션들
    useradd_options=""
    
    # 홈 디렉토리 설정
    home_dir=""
    log_question "홈 디렉토리를 지정하시겠습니까? (기본: /home/$username) (y/n)"
    read -r set_home
    
    if [[ $set_home =~ ^[Yy]$ ]]; then
        log_question "홈 디렉토리 경로를 입력하세요:"
        read -r home_dir
        useradd_options="$useradd_options -d $home_dir"
    else
        home_dir="/home/$username"
    fi
    
    # 홈 디렉토리 생성 여부
    log_question "홈 디렉토리를 생성하시겠습니까? (y/n)"
    read -r create_home
    
    create_home_flag=false
    if [[ $create_home =~ ^[Yy]$ ]]; then
        useradd_options="$useradd_options -m"
        create_home_flag=true
    fi
    
    # 기본 쉘 설정
    log_question "기본 쉘을 지정하시겠습니까? (기본: /bin/bash) (y/n)"
    read -r set_shell
    
    if [[ $set_shell =~ ^[Yy]$ ]]; then
        echo "사용 가능한 쉘:"
        cat /etc/shells
        log_question "쉘 경로를 입력하세요:"
        read -r shell_path
        
        if grep -q "^$shell_path$" /etc/shells; then
            useradd_options="$useradd_options -s $shell_path"
        else
            log_error "유효하지 않은 쉘입니다. 기본 쉘을 사용합니다."
            useradd_options="$useradd_options -s /bin/bash"
        fi
    else
        useradd_options="$useradd_options -s /bin/bash"
    fi
    
    # UID 설정
    log_question "사용자 ID(UID)를 지정하시겠습니까? (y/n)"
    read -r set_uid
    
    if [[ $set_uid =~ ^[Yy]$ ]]; then
        log_question "UID를 입력하세요:"
        read -r uid
        useradd_options="$useradd_options -u $uid"
    fi
    
    # 기본 그룹 설정
    log_question "기본 그룹을 지정하시겠습니까? (y/n)"
    read -r set_primary_group
    
    if [[ $set_primary_group =~ ^[Yy]$ ]]; then
        echo "기존 그룹 목록:"
        getent group | cut -d: -f1 | sort
        log_question "기본 그룹명을 입력하세요:"
        read -r primary_group
        
        if group_exists "$primary_group"; then
            useradd_options="$useradd_options -g $primary_group"
        else
            log_error "그룹 '$primary_group'이 존재하지 않습니다."
            return 1
        fi
    fi
    
    # 추가 그룹 설정
    log_question "추가 그룹에 사용자를 추가하시겠습니까? (y/n)"
    read -r add_groups
    
    if [[ $add_groups =~ ^[Yy]$ ]]; then
        echo "기존 그룹 목록:"
        getent group | cut -d: -f1 | sort
        log_question "추가할 그룹들을 쉼표로 구분하여 입력하세요 (예: group1,group2,group3):"
        read -r additional_groups
        useradd_options="$useradd_options -G $additional_groups"
    fi
    
    # 비밀번호 만료 설정
    load_password_policy
    log_question "비밀번호 만료 설정을 적용하시겠습니까? (정책: ${MAX_AGE}일) (y/n)"
    read -r set_expiry
    
    if [[ $set_expiry =~ ^[Yy]$ ]]; then
        useradd_options="$useradd_options -f $MAX_AGE"
    fi
    
    # 사용자 생성
    log_info "사용자 생성 중: useradd $useradd_options $username"
    useradd $useradd_options "$username"
    
    if [[ $? -eq 0 ]]; then
        log_info "사용자 '$username' 생성 완료"
        log_activity "User created: $username"
        
        # 홈 디렉토리 권한 설정 및 확인
        if [[ $create_home_flag == true ]]; then
            # 실제 홈 디렉토리 경로 확인
            actual_home=$(eval echo ~"$username")
            
            if [ -d "$actual_home" ]; then
                # 사용자의 UID/GID 가져오기
                user_uid=$(id -u "$username")
                user_gid=$(id -g "$username")
                
                # 홈 디렉토리 권한 설정
                chown -R "$user_uid:$user_gid" "$actual_home"
                chmod 755 "$actual_home"
                
                log_info "홈 디렉토리 권한 설정 완료: $actual_home (소유자: $user_uid:$user_gid)"
                log_activity "Home directory permissions set for $username: $actual_home"
            else
                # 홈 디렉토리가 생성되지 않은 경우 수동으로 생성
                log_warn "홈 디렉토리가 생성되지 않았습니다. 수동으로 생성합니다."
                
                # 실제 홈 디렉토리 경로 결정
                if [ -n "$home_dir" ]; then
                    actual_home="$home_dir"
                else
                    actual_home="/home/$username"
                fi
                
                # 디렉토리 생성
                mkdir -p "$actual_home"
                
                # 사용자의 UID/GID 가져오기
                user_uid=$(id -u "$username")
                user_gid=$(id -g "$username")
                
                # /etc/skel 내용 복사
                if [ -d /etc/skel ]; then
                    cp -r /etc/skel/. "$actual_home/"
                    log_info "기본 설정 파일들을 복사했습니다."
                fi
                
                # 권한 설정
                chown -R "$user_uid:$user_gid" "$actual_home"
                chmod 755 "$actual_home"
                
                log_info "홈 디렉토리를 수동으로 생성했습니다: $actual_home"
                log_activity "Home directory manually created for $username: $actual_home"
            fi
        fi
        
        # 비밀번호 설정
        log_question "비밀번호를 설정하시겠습니까? (y/n)"
        read -r set_password
        
        if [[ $set_password =~ ^[Yy]$ ]]; then
            log_question "비밀번호 정책을 적용하시겠습니까? (y/n)"
            read -r apply_policy
            
            if [[ $apply_policy =~ ^[Yy]$ ]]; then
                # 정책에 맞는 비밀번호 입력받기
                while true; do
                    log_question "비밀번호를 입력하세요:"
                    read -s password
                    echo
                    log_question "비밀번호를 다시 입력하세요:"
                    read -s password_confirm
                    echo
                    
                    if [[ "$password" != "$password_confirm" ]]; then
                        log_error "비밀번호가 일치하지 않습니다."
                        continue
                    fi
                    
                    if validate_password "$password"; then
                        echo "$username:$password" | chpasswd
                        log_info "비밀번호가 설정되었습니다."
                        break
                    else
                        log_warn "비밀번호 정책에 맞지 않습니다. 다시 입력해주세요."
                    fi
                done
            else
                passwd "$username"
            fi
            
            # 비밀번호 만료 정책 적용
            if [[ $set_expiry =~ ^[Yy]$ ]]; then
                chage -M "$MAX_AGE" -m "$MIN_AGE" -W "$WARN_AGE" "$username"
                log_info "비밀번호 만료 정책이 적용되었습니다."
            fi
        fi
        
        # sudo 권한 부여
        log_question "sudo 권한을 부여하시겠습니까? (y/n)"
        read -r grant_sudo
        
        if [[ $grant_sudo =~ ^[Yy]$ ]]; then
            configure_sudo_access "$username"
        fi
        
        # 로그인 허용/금지 설정
        log_question "SSH 로그인을 허용하시겠습니까? (y/n)"
        read -r allow_ssh
        
        if [[ $allow_ssh =~ ^[Nn]$ ]]; then
            # SSH 접근 제한
            if [ -f /etc/ssh/sshd_config ]; then
                if ! grep -q "DenyUsers" /etc/ssh/sshd_config; then
                    echo "DenyUsers $username" >> /etc/ssh/sshd_config
                else
                    sed -i "/DenyUsers/s/$/ $username/" /etc/ssh/sshd_config
                fi
                log_info "SSH 로그인이 금지되었습니다."
                log_activity "SSH access denied for user: $username"
            fi
        fi
        
        # bash 설정 파일 생성
        user_home=$(eval echo ~"$username")
        if [[ $create_home_flag == true ]] && [ -d "$user_home" ]; then
            log_question "기본 bash 설정 파일을 생성하시겠습니까? (y/n)"
            read -r create_bash_config
            
            if [[ $create_bash_config =~ ^[Yy]$ ]]; then
                # 사용자의 UID/GID 가져오기
                user_uid=$(id -u "$username")
                user_gid=$(id -g "$username")
                
                # .bashrc 설정
                if [ ! -f "$user_home/.bashrc" ]; then
                    cp /etc/skel/.bashrc "$user_home/.bashrc" 2>/dev/null || {
                        cat > "$user_home/.bashrc" << 'EOF'
# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000

# Update window size after each command
shopt -s checkwinsize

# Enable color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Common aliases with color support
alias ll='ls -al --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Additional useful aliases
alias ..='cd ..'
alias ...='cd ../..'
alias h='history'
alias df='df -h'
alias du='du -h'
alias free='free -h'

# Enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
EOF
                    }
                fi
                
                # .bash_profile 설정
                if [ ! -f "$user_home/.bash_profile" ]; then
                    cat > "$user_home/.bash_profile" << 'EOF'
# ~/.bash_profile: executed by bash(1) for login shells.

if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# User specific environment and startup programs
PATH=$PATH:$HOME/bin
export PATH
EOF
                fi
                
                # .bash_logout 설정 (선택적)
                if [ ! -f "$user_home/.bash_logout" ]; then
                    cat > "$user_home/.bash_logout" << 'EOF'
# ~/.bash_logout: executed by bash(1) when login shell exits.

# Clear the screen for security's sake.
clear
EOF
                fi
                
                # 홈 디렉토리 내 모든 파일의 소유권 재설정
                chown -R "$user_uid:$user_gid" "$user_home"
                
                # 각 파일의 적절한 권한 설정
                chmod 644 "$user_home/.bashrc" 2>/dev/null
                chmod 644 "$user_home/.bash_profile" 2>/dev/null
                chmod 644 "$user_home/.bash_logout" 2>/dev/null
                
                # 숨김 파일들 권한 설정
                find "$user_home" -name ".*" -type f -exec chmod 644 {} \; 2>/dev/null
                find "$user_home" -name ".*" -type d -exec chmod 755 {} \; 2>/dev/null
                
                log_info "bash 설정 파일이 생성되고 권한이 설정되었습니다."
                log_activity "Bash configuration files created for $username with proper ownership ($user_uid:$user_gid)"
            fi
        elif [[ $create_home_flag == true ]]; then
            log_warn "홈 디렉토리가 존재하지 않아 bash 설정 파일을 생성할 수 없습니다."
        fi
        
        # 사용자 정보 표시
        show_user_info "$username"
        
    else
        log_error "사용자 생성 실패"
    fi
}

# 사용자 정보 표시
show_user_info() {
    local username="$1"
    echo
    log_info "=== 사용자 정보 ==="
    id "$username"
    echo "홈 디렉토리: $(eval echo ~"$username")"
    echo "기본 쉘: $(getent passwd "$username" | cut -d: -f7)"
    echo "소속 그룹: $(groups "$username")"
    
    if groups "$username" | grep -q sudo; then
        echo "sudo 권한: ✓"
    else
        echo "sudo 권한: ✗"
    fi
    
    # 비밀번호 정책 정보
    echo
    echo "=== 비밀번호 정책 정보 ==="
    chage -l "$username" 2>/dev/null || echo "비밀번호 정책 정보 없음"
    
    # 로그인 히스토리
    echo
    echo "=== 최근 로그인 기록 ==="
    last "$username" -n 5 2>/dev/null || echo "로그인 기록 없음"
}

# 사용자 관리 메뉴
manage_user() {
    log_question "사용자명을 입력하세요:"
    read -r username
    
    if ! user_exists "$username"; then
        log_error "사용자 '$username'이 존재하지 않습니다."
        return 1
    fi
    
    while true; do
        echo
        echo "=== 사용자 관리 메뉴: $username ==="
        echo "1) 그룹 추가"
        echo "2) 그룹 제거"
        echo "3) sudo 권한 관리"
        echo "4) sudo 권한 제거"
        echo "5) 비밀번호 변경"
        echo "6) 사용자 정보 보기"
        echo "7) 쉘 관리"
        echo "8) 계정 잠금/해제"
        echo "9) 홈 디렉토리 관리"
        echo "10) 사용자 삭제"
        echo "0) 돌아가기"
        
        log_question "선택하세요:"
        read -r choice
        
        case $choice in
            1)
                echo "기존 그룹 목록:"
                getent group | cut -d: -f1 | sort
                log_question "추가할 그룹명을 입력하세요:"
                read -r add_group
                if group_exists "$add_group"; then
                    usermod -aG "$add_group" "$username"
                    log_info "그룹 '$add_group' 추가 완료"
                    log_activity "Group $add_group added to user $username"
                else
                    log_error "그룹 '$add_group'이 존재하지 않습니다."
                fi
                ;;
            2)
                echo "현재 소속 그룹: $(groups "$username")"
                log_question "제거할 그룹명을 입력하세요:"
                read -r remove_group
                gpasswd -d "$username" "$remove_group"
                log_info "그룹 '$remove_group'에서 제거 완료"
                log_activity "Group $remove_group removed from user $username"
                ;;
            3)
                manage_sudo_permissions "$username"
                ;;
            4)
                gpasswd -d "$username" sudo
                rm -f "/etc/sudoers.d/$username"
                log_info "sudo 권한 제거 완료"
                log_activity "Sudo access removed from user: $username"
                ;;
            5)
                log_question "비밀번호 정책을 적용하시겠습니까? (y/n)"
                read -r apply_policy
                
                if [[ $apply_policy =~ ^[Yy]$ ]]; then
                    while true; do
                        log_question "새 비밀번호를 입력하세요:"
                        read -s password
                        echo
                        log_question "비밀번호를 다시 입력하세요:"
                        read -s password_confirm
                        echo
                        
                        if [[ "$password" != "$password_confirm" ]]; then
                            log_error "비밀번호가 일치하지 않습니다."
                            continue
                        fi
                        
                        if validate_password "$password"; then
                            echo "$username:$password" | chpasswd
                            log_info "비밀번호가 변경되었습니다."
                            log_activity "Password changed for user: $username"
                            break
                        else
                            log_warn "비밀번호 정책에 맞지 않습니다. 다시 입력해주세요."
                        fi
                    done
                else
                    passwd "$username"
                    log_activity "Password changed for user: $username"
                fi
                ;;
            6)
                show_user_info "$username"
                ;;
            7)
                manage_user_shell
                ;;
            8)
                echo "1) 계정 잠금"
                echo "2) 계정 잠금 해제"
                log_question "선택하세요:"
                read -r lock_choice
                
                case $lock_choice in
                    1)
                        usermod -L "$username"
                        log_info "계정이 잠겼습니다."
                        log_activity "Account locked: $username"
                        ;;
                    2)
                        usermod -U "$username"
                        log_info "계정 잠금이 해제되었습니다."
                        log_activity "Account unlocked: $username"
                        ;;
                esac
                ;;
            9)
                user_home=$(eval echo ~"$username")
                echo "현재 홈 디렉토리: $user_home"
                echo "1) 홈 디렉토리 권한 수정"
                echo "2) 홈 디렉토리 백업"
                echo "3) 홈 디렉토리 용량 확인"
                
                log_question "선택하세요:"
                read -r home_choice
                
                case $home_choice in
                    1)
                        log_question "권한을 설정하세요 (예: 755):"
                        read -r permissions
                        chmod "$permissions" "$user_home"
                        chown -R "$username:$(id -gn "$username")" "$user_home"
                        log_info "홈 디렉토리 권한이 설정되었습니다."
                        ;;
                    2)
                        backup_home="/tmp/${username}_home_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
                        tar -czf "$backup_home" -C "$(dirname "$user_home")" "$(basename "$user_home")"
                        log_info "홈 디렉토리가 백업되었습니다: $backup_home"
                        ;;
                    3)
                        echo "홈 디렉토리 용량:"
                        du -sh "$user_home" 2>/dev/null || echo "용량 정보를 가져올 수 없습니다."
                        echo "상세 내용:"
                        du -h "$user_home"/* 2>/dev/null || echo "내용이 없거나 접근할 수 없습니다."
                        ;;
                esac
                ;;
            10)
                log_question "사용자 '$username'을 정말 삭제하시겠습니까? (홈 디렉토리 포함) (y/n)"
                read -r confirm_delete
                if [[ $confirm_delete =~ ^[Yy]$ ]]; then
                    # 백업 생성
                    user_home=$(eval echo ~"$username")
                    if [ -d "$user_home" ]; then
                        backup_file="/tmp/${username}_deleted_$(date +%Y%m%d_%H%M%S).tar.gz"
                        tar -czf "$backup_file" -C "$(dirname "$user_home")" "$(basename "$user_home")" 2>/dev/null
                        log_info "삭제 전 홈 디렉토리 백업: $backup_file"
                    fi
                    
                    userdel -r "$username"
                    rm -f "/etc/sudoers.d/$username" 2>/dev/null
                    log_info "사용자 '$username' 삭제 완료"
                    log_activity "User deleted: $username"
                    return 0
                fi
                ;;
            0)
                return 0
                ;;
            *)
                log_error "잘못된 선택입니다."
                ;;
        esac
        
        echo
        log_question "계속하려면 Enter를 누르세요..."
        read -r
    done
}

# 시스템 보안 설정
security_settings() {
    echo -e "${CYAN}=== 시스템 보안 설정 ===${NC}"
    echo "1) 비밀번호 정책 설정"
    echo "2) 로그인 실패 정책"
    echo "3) 세션 타임아웃 설정"
    echo "4) SSH 보안 설정"
    echo "5) 계정 잠금 정책"
    
    log_question "선택하세요:"
    read -r security_choice
    
    case $security_choice in
        1)
            configure_password_policy
            ;;
        2)
            log_question "로그인 실패 허용 횟수를 입력하세요 (기본: 3):"
            read -r max_failures
            max_failures=${max_failures:-3}
            
            log_question "계정 잠금 시간(초)을 입력하세요 (기본: 600):"
            read -r lock_time
            lock_time=${lock_time:-600}
            
            # PAM 설정 업데이트
            if [ -f /etc/pam.d/common-auth ]; then
                cp /etc/pam.d/common-auth /etc/pam.d/common-auth.bak
                if ! grep -q "pam_tally2" /etc/pam.d/common-auth; then
                    echo "auth required pam_tally2.so deny=$max_failures unlock_time=$lock_time" >> /etc/pam.d/common-auth
                fi
            fi
            
            log_info "로그인 실패 정책이 설정되었습니다."
            ;;
        3)
            log_question "세션 타임아웃(분)을 입력하세요 (기본: 30):"
            read -r timeout_min
            timeout_min=${timeout_min:-30}
            timeout_sec=$((timeout_min * 60))
            
            echo "export TMOUT=$timeout_sec" > /etc/profile.d/timeout.sh
            log_info "세션 타임아웃이 ${timeout_min}분으로 설정되었습니다."
            ;;
        4)
            echo "SSH 보안 설정:"
            echo "1) root 로그인 금지"
            echo "2) 비밀번호 인증 비활성화 (키 인증만 허용)"
            echo "3) 포트 변경"
            echo "4) 모든 설정 적용"
            
            log_question "선택하세요:"
            read -r ssh_choice
            
            if [ -f /etc/ssh/sshd_config ]; then
                cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
                
                case $ssh_choice in
                    1|4)
                        sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
                        log_info "root 로그인이 금지되었습니다."
                        ;;& 
                    2|4)
                        log_question "비밀번호 인증을 비활성화하시겠습니까? (y/n)"
                        read -r disable_password
                        if [[ $disable_password =~ ^[Yy]$ ]]; then
                            sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
                            log_info "비밀번호 인증이 비활성화되었습니다."
                        fi
                        ;;& 
                    3|4)
                        log_question "SSH 포트를 변경하시겠습니까? (기본: 22) (y/n)"
                        read -r change_port
                        if [[ $change_port =~ ^[Yy]$ ]]; then
                            log_question "새 포트 번호를 입력하세요:"
                            read -r new_port
                            sed -i "s/#Port 22/Port $new_port/" /etc/ssh/sshd_config
                            log_info "SSH 포트가 $new_port로 변경되었습니다."
                        fi
                        ;;
                esac
                
                systemctl reload sshd
                log_info "SSH 설정이 적용되었습니다."
            fi
            ;;
        5)
            echo "계정 잠금 정책 관리:"
            echo "1) 잠긴 계정 목록"
            echo "2) 계정 잠금 해제"
            echo "3) 로그인 실패 기록 초기화"
            
            log_question "선택하세요:"
            read -r lock_choice
            
            case $lock_choice in
                1)
                    echo "잠긴 계정 목록:"
                    awk -F: '($2 ~ /^!/) {print $1}' /etc/shadow
                    ;;
                2)
                    log_question "잠금 해제할 사용자명:"
                    read -r unlock_user
                    if user_exists "$unlock_user"; then
                        usermod -U "$unlock_user"
                        pam_tally2 --user="$unlock_user" --reset 2>/dev/null
                        log_info "사용자 '$unlock_user'의 잠금이 해제되었습니다."
                    fi
                    ;;
                3)
                    pam_tally2 --reset 2>/dev/null || echo "pam_tally2를 사용할 수 없습니다."
                    log_info "로그인 실패 기록이 초기화되었습니다."
                    ;;
            esac
            ;;
    esac
}

# 메인 메뉴
main_menu() {
    while true; do
        echo
        echo "========================================"
        echo "     사용자/그룹 관리 스크립트 v2.0"
        echo "========================================"
        echo "OS: $OS $VERSION"
        echo "로그 파일: $LOG_FILE"
        echo
        echo "1) 새 사용자 생성"
        echo "2) 새 그룹 생성"
        echo "3) 사용자 관리"
        echo "4) 모든 사용자 목록"
        echo "5) 모든 그룹 목록"
        echo "6) 사용자 활동 로그"
        echo "7) 시스템 보안 설정"
        echo "8) 백업 생성"
        echo "9) 백업 복원"
        echo "10) 비밀번호 정책 설정"
        echo "0) 종료"
        echo
        
        log_question "메뉴를 선택하세요:"
        read -r choice
        
        case $choice in
            1)
                create_user
                ;;
            2)
                create_group
                ;;
            3)
                manage_user
                ;;
            4)
                echo "=== 시스템 사용자 목록 ==="
                printf "%-20s %-8s %-8s %-20s %-30s\n" "사용자명" "UID" "GID" "홈디렉토리" "쉘"
                echo "--------------------------------------------------------------------------------"
                getent passwd | while IFS=: read -r username password uid gid gecos home shell; do
                    printf "%-20s %-8s %-8s %-20s %-30s\n" "$username" "$uid" "$gid" "$home" "$shell"
                done | sort -k2 -n
                ;;
            5)
                echo "=== 시스템 그룹 목록 ==="
                printf "%-20s %-8s %-40s\n" "그룹명" "GID" "멤버"
                echo "------------------------------------------------------------------------"
                getent group | while IFS=: read -r groupname password gid members; do
                    printf "%-20s %-8s %-40s\n" "$groupname" "$gid" "$members"
                done | sort -k2 -n
                ;;
            6)
                show_user_activity
                ;;
            7)
                security_settings
                ;;
            8)
                create_backup
                ;;
            9)
                restore_backup
                ;;
            10)
                configure_password_policy
                ;;
            0)
                log_info "스크립트를 종료합니다."
                log_activity "Script terminated by user"
                exit 0
                ;;
            *)
                log_error "잘못된 선택입니다."
                ;;
        esac
        
        echo
        log_question "계속하려면 Enter를 누르세요..."
        read -r
    done
}

# 메인 실행부
main() {
    check_privileges
    detect_os
    initialize_environment
    
    log_info "사용자/그룹 관리 스크립트 v2.0 시작"
    log_activity "Script started by $(whoami) from $(who am i | awk '{print $5}' | tr -d '()')"
    
    main_menu
}

# 스크립트 실행
main
