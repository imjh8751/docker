#!/bin/bash

# ==============================================================================
# 사용자 및 그룹 관리 스크립트 v3.0 (Ultimate Edition)
# 기능: 사용자/그룹 생성·관리, Sudo 설정, 보안 정책, 백업/복원, 로그 분석
# 호환: Ubuntu/Debian, CentOS/RHEL/Rocky (자동 감지)
# 주의: Root 권한 필수
# ==============================================================================

# --- 색상 정의 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- 설정 파일 경로 ---
CONFIG_DIR="/etc/user_manager"
LOG_FILE="/var/log/user_manager.log"
BACKUP_DIR="/var/backups/user_manager"
PASSWORD_POLICY_FILE="$CONFIG_DIR/password_policy.conf"

# --- OS 및 환경 감지 ---
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
        ID_LIKE=${ID_LIKE:-""}
    else
        OS=$(uname -s)
        VERSION=$(uname -r)
    fi

    # 패밀리 및 서비스 명칭 감지
    if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
        OS_FAMILY="debian"
        SSH_SERVICE="ssh"
        PAM_CONFIG_TOOL="pam-auth-update"
    elif [[ "$ID" == "centos" || "$ID" == "rhel" || "$ID" == "rocky" || "$ID" == "fedora" || "$ID_LIKE" == *"rhel"* ]]; then
        OS_FAMILY="rhel"
        SSH_SERVICE="sshd"
        PAM_CONFIG_TOOL="authselect"
    else
        OS_FAMILY="unknown"
        SSH_SERVICE="sshd"
    fi
}

# --- 로그 및 유틸리티 함수 ---
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

validate_username() {
    # 사용자명/그룹명 유효성 검사 (특수문자 방지)
    if [[ ! "$1" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        log_error "잘못된 이름 형식입니다. (영문 소문자, 숫자, _, - 만 허용)"
        return 1
    fi
    return 0
}

check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[CRITICAL] 이 스크립트는 sudo(root) 권한으로 실행해야 합니다.${NC}"
        exit 1
    fi
}

user_exists() { id "$1" &>/dev/null; }
group_exists() { getent group "$1" &>/dev/null; }

initialize_environment() {
    mkdir -p "$CONFIG_DIR" "$BACKUP_DIR"
    touch "$LOG_FILE"
    chmod 600 "$LOG_FILE" # 보안: root만 읽기 가능

    # 기본 정책 파일 생성
    if [ ! -f "$PASSWORD_POLICY_FILE" ]; then
        cat > "$PASSWORD_POLICY_FILE" << 'EOF'
MIN_LENGTH=8
MAX_LENGTH=128
REQUIRE_UPPERCASE=true
REQUIRE_LOWERCASE=true
REQUIRE_NUMBERS=true
REQUIRE_SPECIAL=true
MAX_AGE=90
MIN_AGE=0
WARN_AGE=7
HISTORY_SIZE=5
EOF
    fi
}

load_password_policy() {
    [ -f "$PASSWORD_POLICY_FILE" ] && source "$PASSWORD_POLICY_FILE"
}

# ==============================================================================
# 1. 비밀번호 정책 관리
# ==============================================================================
configure_password_policy() {
    echo -e "${CYAN}=== 비밀번호 정책 설정 ===${NC}"
    load_password_policy
    
    # 입력값 받기 (기본값 활용)
    log_question "최소 길이 (현재: ${MIN_LENGTH:-8}):"
    read -r min_len
    MIN_LENGTH=${min_len:-$MIN_LENGTH}

    log_question "대문자 필수 (y/n, 현재: ${REQUIRE_UPPERCASE:-true}):"
    read -r req_upper
    [[ "$req_upper" =~ ^[Nn] ]] && REQUIRE_UPPERCASE=false || REQUIRE_UPPERCASE=true

    log_question "숫자 필수 (y/n, 현재: ${REQUIRE_NUMBERS:-true}):"
    read -r req_num
    [[ "$req_num" =~ ^[Nn] ]] && REQUIRE_NUMBERS=false || REQUIRE_NUMBERS=true
    
    log_question "특수문자 필수 (y/n, 현재: ${REQUIRE_SPECIAL:-true}):"
    read -r req_spec
    [[ "$req_spec" =~ ^[Nn] ]] && REQUIRE_SPECIAL=false || REQUIRE_SPECIAL=true

    log_question "비밀번호 만료일 (일, 현재: ${MAX_AGE:-90}):"
    read -r max_age
    MAX_AGE=${max_age:-$MAX_AGE}

    # 정책 파일 저장
    cat > "$PASSWORD_POLICY_FILE" << EOF
MIN_LENGTH=$MIN_LENGTH
REQUIRE_UPPERCASE=$REQUIRE_UPPERCASE
REQUIRE_NUMBERS=$REQUIRE_NUMBERS
REQUIRE_SPECIAL=$REQUIRE_SPECIAL
MAX_AGE=$MAX_AGE
MIN_AGE=$MIN_AGE
WARN_AGE=$WARN_AGE
HISTORY_SIZE=$HISTORY_SIZE
EOF

    # OS별 설정 적용
    log_info "시스템 설정 파일(/etc/login.defs, pwquality.conf)을 업데이트합니다..."

    # 1. login.defs (공통)
    sed -i "s/^PASS_MAX_DAYS.*/PASS_MAX_DAYS\t$MAX_AGE/" /etc/login.defs
    sed -i "s/^PASS_MIN_DAYS.*/PASS_MIN_DAYS\t$MIN_AGE/" /etc/login.defs
    sed -i "s/^PASS_WARN_AGE.*/PASS_WARN_AGE\t$WARN_AGE/" /etc/login.defs

    # 2. pwquality.conf (공통 사용 추세)
    if [ -f /etc/security/pwquality.conf ]; then
        # 백업
        cp /etc/security/pwquality.conf /etc/security/pwquality.conf.bak
        
        cat > /etc/security/pwquality.conf << EOF
minlen = $MIN_LENGTH
dcredit = $([ "$REQUIRE_NUMBERS" = "true" ] && echo "-1" || echo "0")
ucredit = $([ "$REQUIRE_UPPERCASE" = "true" ] && echo "-1" || echo "0")
lcredit = $([ "$REQUIRE_LOWERCASE" = "true" ] && echo "-1" || echo "0")
ocredit = $([ "$REQUIRE_SPECIAL" = "true" ] && echo "-1" || echo "0")
remember = $HISTORY_SIZE
enforce_for_root
EOF
    else
        log_warn "/etc/security/pwquality.conf 파일을 찾을 수 없어 패스워드 복잡도 설정이 건너뛰어졌습니다."
    fi

    log_info "비밀번호 정책이 업데이트되었습니다."
}

# 비밀번호 검증 함수
validate_password() {
    local password="$1"
    load_password_policy
    local errors=()

    [[ ${#password} -lt $MIN_LENGTH ]] && errors+=("최소 $MIN_LENGTH자 이상")
    [[ "$REQUIRE_UPPERCASE" == "true" && ! "$password" =~ [A-Z] ]] && errors+=("대문자 포함 필요")
    [[ "$REQUIRE_NUMBERS" == "true" && ! "$password" =~ [0-9] ]] && errors+=("숫자 포함 필요")
    [[ "$REQUIRE_SPECIAL" == "true" && ! "$password" =~ [^a-zA-Z0-9] ]] && errors+=("특수문자 포함 필요")

    if [[ ${#errors[@]} -gt 0 ]]; then
        log_warn "비밀번호 정책 위반: ${errors[*]}"
        return 1
    fi
    return 0
}

# ==============================================================================
# 2. SUDO 권한 관리 (안전성 강화됨)
# ==============================================================================
configure_sudo_access() {
    local username="$1"
    
    echo -e "\n${CYAN}=== sudo 권한 설정: $username ===${NC}"
    echo "1) 기본 sudo 권한 (그룹 추가)"
    echo "2) 비밀번호 없는 sudo 권한 (NOPASSWD)"
    echo "3) 특정 명령어만 허용"
    echo "4) 시간 제한 sudo 권한 (만료일 설정)"
    echo "5) sudo 권한 제거"
    
    log_question "선택하세요:"
    read -r sudo_type

    # 안전한 편집을 위한 임시 파일
    local tmp_sudo="/tmp/sudoers_check_$username"
    
    case $sudo_type in
        1)
            usermod -aG sudo "$username" 2>/dev/null || usermod -aG wheel "$username"
            log_info "$username 사용자에게 기본 관리자 권한을 부여했습니다."
            return
            ;;
        2)
            echo "$username ALL=(ALL) NOPASSWD:ALL" > "$tmp_sudo"
            log_warn "비밀번호 없는 sudo 권한은 보안 위험이 있습니다."
            ;;
        3)
            log_question "허용할 명령어 경로 (콤마 구분, 예: /bin/systemctl,/usr/bin/apt):"
            read -r cmds
            echo "$username ALL=(ALL) $cmds" > "$tmp_sudo"
            ;;
        4)
            log_question "만료일 입력 (YYYY-MM-DD):"
            read -r exp_date
            
            # 유효성 검사
            if ! date -d "$exp_date" >/dev/null 2>&1; then
                log_error "날짜 형식이 잘못되었습니다."
                return
            fi
            
            echo "# Expires on $exp_date" > "$tmp_sudo"
            echo "$username ALL=(ALL) ALL" >> "$tmp_sudo"
            
            # /etc/cron.d/ 사용하여 안전하게 스케줄링
            local m d
            m=$(date -d "$exp_date" +%m)
            d=$(date -d "$exp_date" +%d)
            local cron_file="/etc/cron.d/sudo_expire_$username"
            
            echo "0 0 $d $m * root rm -f /etc/sudoers.d/$username $cron_file && gpasswd -d $username sudo 2>/dev/null" > "$cron_file"
            log_info "만료 예약 설정됨 ($exp_date): $cron_file"
            ;;
        5)
            rm -f "/etc/sudoers.d/$username"
            rm -f "/etc/cron.d/sudo_expire_$username"
            gpasswd -d "$username" sudo 2>/dev/null
            gpasswd -d "$username" wheel 2>/dev/null
            log_info "$username 의 sudo 권한을 제거했습니다."
            return
            ;;
        *) return ;;
    esac

    # visudo 검증 후 적용 (핵심 안전 장치)
    if [ -f "$tmp_sudo" ]; then
        if visudo -c -f "$tmp_sudo"; then
            mv "$tmp_sudo" "/etc/sudoers.d/$username"
            chmod 440 "/etc/sudoers.d/$username"
            log_info "sudo 설정이 안전하게 적용되었습니다."
        else
            log_error "설정 파일 문법 오류! 변경 사항이 취소되었습니다."
            rm -f "$tmp_sudo"
        fi
    fi
}

# ==============================================================================
# 3. 사용자 및 쉘 관리
# ==============================================================================
manage_user_shell() {
    log_question "사용자명 입력:"
    read -r username
    validate_username "$username" || return
    if ! user_exists "$username"; then log_error "사용자가 없습니다."; return; fi

    local current_shell
    current_shell=$(getent passwd "$username" | cut -d: -f7)
    echo "현재 쉘: $current_shell"

    echo "1) 쉘 변경"
    echo "2) 로그인 차단 (nologin)"
    echo "3) 차단 해제 (/bin/bash)"
    read -r choice

    case $choice in
        1)
            cat /etc/shells
            log_question "변경할 쉘 경로:"
            read -r new_shell
            if grep -q "^$new_shell$" /etc/shells; then
                usermod -s "$new_shell" "$username"
                log_info "쉘 변경 완료."
            else
                log_error "유효하지 않은 쉘입니다."
            fi
            ;;
        2)
            usermod -s /sbin/nologin "$username" 2>/dev/null || usermod -s /usr/sbin/nologin "$username"
            log_info "로그인 차단됨."
            ;;
        3)
            usermod -s /bin/bash "$username"
            log_info "로그인 차단 해제됨."
            ;;
    esac
}

# ==============================================================================
# 4. 그룹 관리 기능
# ==============================================================================
create_group() {
    log_question "생성할 그룹명:"
    read -r gname
    validate_username "$gname" || return

    if group_exists "$gname"; then
        log_error "이미 존재하는 그룹입니다."
    else
        log_question "GID를 지정하시겠습니까? (y/n)"
        read -r use_gid
        if [[ $use_gid =~ ^[Yy] ]]; then
            log_question "GID 입력:"
            read -r gid
            groupadd -g "$gid" "$gname"
        else
            groupadd "$gname"
        fi
        log_info "그룹 '$gname' 생성 완료."
    fi
}

manage_group_membership() {
    log_question "관리할 사용자명:"
    read -r uname
    if ! user_exists "$uname"; then log_error "사용자 없음"; return; fi

    echo "현재 소속 그룹: $(groups "$uname")"
    
    echo "1) 그룹에 추가"
    echo "2) 그룹에서 제거"
    read -r choice

    log_question "대상 그룹명:"
    read -r gname

    if ! group_exists "$gname"; then log_error "그룹이 존재하지 않습니다."; return; fi

    case $choice in
        1)
            usermod -aG "$gname" "$uname"
            log_info "$uname -> $gname 추가됨"
            ;;
        2)
            gpasswd -d "$uname" "$gname"
            log_info "$uname -> $gname 제거됨"
            ;;
    esac
}

# ==============================================================================
# 5. 백업 및 복원
# ==============================================================================
create_backup() {
    local backup_name="backup_$(hostname)_$(date +%Y%m%d_%H%M%S).tar.gz"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    log_info "백업 시작... ($backup_path)"
    
    # 중요 설정 파일 백업
    # /etc/passwd, shadow, group, gshadow, sudoers.d, user_manager config
    tar -czf "$backup_path" \
        /etc/passwd /etc/shadow /etc/group /etc/gshadow \
        /etc/sudoers.d "$CONFIG_DIR" 2>/dev/null

    log_info "계정 설정 백업 완료."
    
    log_question "홈 디렉토리도 백업하시겠습니까? (시간이 오래 걸릴 수 있음) (y/n)"
    read -r backup_home
    if [[ $backup_home =~ ^[Yy] ]]; then
        local home_backup="${backup_path}_home.tar.gz"
        tar -czf "$home_backup" /home --exclude=*.iso --exclude=*.vdi 2>/dev/null
        log_info "홈 디렉토리 백업 완료: $home_backup"
    fi
}

restore_backup() {
    echo -e "${RED}!!! 경고: 복원 시 현재 시스템의 계정 정보를 덮어씁니다. !!!${NC}"
    echo "시스템이 불안정해질 수 있으며, 현재 로그인 세션 외에는 접속이 불가할 수 있습니다."
    
    log_question "복원할 백업 파일 경로:"
    read -r backup_file
    
    if [ ! -f "$backup_file" ]; then log_error "파일이 없습니다."; return; fi

    log_question "정말 복원하시겠습니까? (yes/no)"
    read -r confirm
    if [[ "$confirm" != "yes" ]]; then return; fi

    local tmp_dir=$(mktemp -d)
    tar -xzf "$backup_file" -C "$tmp_dir"
    
    # 파일 복사 (루트 경로 유지하며 압축 해제됨)
    cp "$tmp_dir/etc/passwd" /etc/
    cp "$tmp_dir/etc/shadow" /etc/
    cp "$tmp_dir/etc/group" /etc/
    cp "$tmp_dir/etc/gshadow" /etc/
    
    if [ -d "$tmp_dir/etc/sudoers.d" ]; then
        cp -r "$tmp_dir/etc/sudoers.d/"* /etc/sudoers.d/
    fi

    rm -rf "$tmp_dir"
    log_info "복원이 완료되었습니다."
}

# ==============================================================================
# 6. 사용자 생성 (통합)
# ==============================================================================
create_user() {
    log_question "새 사용자명:"
    read -r username
    validate_username "$username" || return

    if user_exists "$username"; then log_error "이미 존재합니다."; return; fi

    # 홈 디렉토리 및 쉘 설정
    useradd_opts="-m -s /bin/bash" # -m: 홈 디렉토리 생성 강제

    log_question "사용자 설명을 입력하세요 (예: 홍길동, 개발팀):"
    read -r comment
    [ -n "$comment" ] && useradd_opts="$useradd_opts -c \"$comment\""

    log_question "특정 UID를 사용하시겠습니까? (y/n)"
    read -r use_uid
    if [[ $use_uid =~ ^[Yy] ]]; then
        log_question "UID:"
        read -r uid
        useradd_opts="$useradd_opts -u $uid"
    fi

    # 사용자 생성 실행
    eval "useradd $useradd_opts $username"
    
    if [ $? -eq 0 ]; then
        log_info "사용자 '$username' 생성 성공."
        
        # 비밀번호 설정
        log_question "비밀번호를 설정하시겠습니까? (y/n)"
        read -r set_pw
        if [[ $set_pw =~ ^[Yy] ]]; then
            while true; do
                log_question "비밀번호 입력:"
                read -s p1
                echo
                log_question "비밀번호 확인:"
                read -s p2
                echo
                
                if [ "$p1" == "$p2" ]; then
                    if validate_password "$p1"; then
                        echo "$username:$p1" | chpasswd
                        log_info "비밀번호 설정 완료."
                        break
                    else
                        log_warn "비밀번호가 정책에 맞지 않습니다. 다시 시도하세요."
                    fi
                else
                    log_error "비밀번호가 일치하지 않습니다."
                fi
            done
        fi

        # 기본 bash 설정 복사 (Redhat 계열 등 자동 생성 안될 경우 대비)
        local user_home="/home/$username"
        if [ -d "$user_home" ] && [ ! -f "$user_home/.bashrc" ]; then
            cp /etc/skel/.bash* "$user_home/" 2>/dev/null
            chown -R "$username:$username" "$user_home"
        fi

    else
        log_error "사용자 생성 실패."
    fi
}

# ==============================================================================
# 7. 보안 설정 및 로그 보기
# ==============================================================================
security_settings() {
    echo -e "${CYAN}=== 시스템 보안 설정 ===${NC}"
    echo "1) 로그인 실패 잠금 정책 (Auto Detect)"
    echo "2) SSH Root 로그인 차단"
    echo "3) SSH 포트 변경"
    read -r choice

    case $choice in
        1)
            log_question "최대 실패 횟수 (예: 5):"
            read -r max_fail
            
            # PAM 모듈 자동 감지
            if [ -f /lib/security/pam_faillock.so ] || grep -q "pam_faillock" /etc/pam.d/system-auth 2>/dev/null; then
                log_info "이 시스템은 pam_faillock을 사용합니다."
                log_info "faillock --user <user> --reset 명령으로 해제 가능합니다."
                log_warn "RHEL8+/Ubuntu20.04+ 에서는 설정 파일을 직접 수정하는 것보다 'authselect' 등을 권장합니다."
            elif command -v pam_tally2 >/dev/null; then
                # 구형 시스템
                if ! grep -q "pam_tally2" /etc/pam.d/common-auth; then
                    echo "auth required pam_tally2.so deny=${max_fail:-5} unlock_time=600" >> /etc/pam.d/common-auth
                    log_info "pam_tally2 정책 추가됨."
                else
                    log_info "이미 pam_tally2가 설정되어 있습니다."
                fi
            else
                log_error "지원되는 PAM 모듈을 찾을 수 없습니다."
            fi
            ;;
        2)
            sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
            sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
            systemctl reload "$SSH_SERVICE"
            log_info "SSH Root 로그인이 차단되었습니다."
            ;;
        3)
            log_question "변경할 포트 번호 (예: 2222):"
            read -r port
            if [[ "$port" =~ ^[0-9]+$ ]]; then
                sed -i "s/^#Port.*/Port $port/" /etc/ssh/sshd_config
                sed -i "s/^Port.*/Port $port/" /etc/ssh/sshd_config
                log_info "SSH 포트가 $port 로 변경되었습니다. (방화벽 확인 필요)"
                systemctl reload "$SSH_SERVICE"
            else
                log_error "숫자만 입력하세요."
            fi
            ;;
    esac
}

show_logs() {
    echo -e "${CYAN}=== 활동 로그 및 시스템 로그 ===${NC}"
    echo "1) 스크립트 활동 로그 ($LOG_FILE)"
    echo "2) 시스템 인증 로그 (auth.log / secure)"
    echo "3) 특정 사용자 활동 검색"
    read -r choice

    case $choice in
        1) less "$LOG_FILE" ;;
        2)
            if [ -f /var/log/auth.log ]; then less /var/log/auth.log
            elif [ -f /var/log/secure ]; then less /var/log/secure
            else journalctl -u ssh | tail -n 50; fi
            ;;
        3)
            log_question "사용자명:"
            read -r uname
            grep "$uname" "$LOG_FILE"
            echo "--- System Log ---"
            grep "$uname" /var/log/auth.log 2>/dev/null || grep "$uname" /var/log/secure 2>/dev/null
            ;;
    esac
}

# ==============================================================================
# 메인 메뉴
# ==============================================================================
manage_user_menu() {
    log_question "대상 사용자명:"
    read -r target_user
    if ! user_exists "$target_user"; then log_error "존재하지 않음"; return; fi
    
    while true; do
        echo -e "\n${PURPLE}--- 사용자 관리: $target_user ---${NC}"
        echo "1. Sudo 권한 관리"
        echo "2. 그룹 멤버십 관리"
        echo "3. 쉘 및 로그인 차단"
        echo "4. 비밀번호 변경 (강제)"
        echo "5. 사용자 정보 확인"
        echo "6. 사용자 삭제"
        echo "0. 뒤로 가기"
        read -r u_choice

        case $u_choice in
            1) configure_sudo_access "$target_user" ;;
            2) manage_group_membership ;; 
            3) manage_user_shell ;; 
            4) 
               log_question "새 비밀번호:"
               read -s newpw
               echo "$target_user:$newpw" | chpasswd
               log_info "비밀번호 변경됨."
               ;;
            5) id "$target_user"; chage -l "$target_user" ;;
            6) 
               log_question "정말 삭제하시겠습니까? (홈 디렉토리 포함) (yes/no)"
               read -r del_conf
               if [ "$del_conf" == "yes" ]; then
                   userdel -r "$target_user"
                   rm -f "/etc/sudoers.d/$target_user"
                   log_info "사용자 삭제 완료."
                   break
               fi
               ;;
            0) break ;;
        esac
    done
}

main_menu() {
    while true; do
        echo -e "\n${GREEN}========================================${NC}"
        echo -e "   User Manager v3.0 Ultimate ($OS $VERSION)"
        echo -e "${GREEN}========================================${NC}"
        echo "1. 사용자 생성"
        echo "2. 사용자 관리 (검색/수정/삭제)"
        echo "3. 그룹 생성"
        echo "4. 그룹 관리 (멤버 추가/제거)"
        echo "5. 시스템 보안 설정 (SSH/Password)"
        echo "6. 백업 및 복원"
        echo "7. 로그 확인"
        echo "8. 전체 사용자/그룹 목록 보기"
        echo "0. 종료"
        
        log_question "선택:"
        read -r main_choice

        case $main_choice in
            1) create_user ;;
            2) manage_user_menu ;;
            3) create_group ;;
            4) manage_group_membership ;;
            5) security_settings; configure_password_policy ;;
            6) 
               echo "1. 백업 | 2. 복원"
               read -r bk
               [ "$bk" == "1" ] && create_backup || restore_backup
               ;;
            7) show_logs ;;
            8) 
               echo "=== Users ==="; cut -d: -f1 /etc/passwd | tail -n 10
               echo "=== Groups ==="; cut -d: -f1 /etc/group | tail -n 10
               ;;
            0) exit 0 ;;
            *) log_error "잘못된 입력" ;;
        esac
        
        echo "Press Enter..."
        read
    done
}

# --- 실행 ---
check_privileges
detect_os
initialize_environment
log_activity "Script started on $OS ($OS_FAMILY)"
main_menu
