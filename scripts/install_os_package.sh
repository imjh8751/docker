#!/bin/bash

# 시스템 모니터링 패키지 설치 스크립트
# 지원 OS: Ubuntu/Debian, CentOS/RHEL/Fedora, Arch Linux, macOS

set -e

# 색상 설정
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

log_header() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# OS 감지
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            OS_VERSION=$VERSION_ID
        elif [ -f /etc/redhat-release ]; then
            OS="rhel"
        elif [ -f /etc/debian_version ]; then
            OS="debian"
        else
            OS="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi
    
    log_info "감지된 OS: $OS"
}

# 시스템 업데이트
system_update() {
    log_header "시스템 업데이트 및 업그레이드"
    
    case $OS in
        ubuntu|debian)
            sudo apt update -y && sudo apt upgrade -y
            ;;
        fedora)
            sudo dnf update -y && sudo dnf upgrade -y
            ;;
        centos|rhel)
            sudo yum update -y && sudo yum upgrade -y
            ;;
        arch|manjaro)
            sudo pacman -Syu --noconfirm
            ;;
        macos)
            log_info "macOS는 Software Update를 통해 수동으로 업데이트하세요"
            ;;
        *)
            log_warn "알 수 없는 OS: 업데이트를 건너뜁니다"
            ;;
    esac
    
    log_info "시스템 업데이트 완료"
}

# 기본 패키지 설치
install_basic_packages() {
    log_header "기본 패키지 설치"
    
    case $OS in
        ubuntu|debian)
            sudo apt install -y \
                net-tools \
                curl \
                vim \
                git \
                samba \
                openssh-server \
                python3-pip \
                nfs-common \
                wget \
                build-essential
            ;;
        fedora)
            sudo dnf install -y \
                net-tools \
                curl \
                vim \
                git \
                samba \
                openssh-server \
                python3-pip \
                nfs-utils \
                wget \
                gcc \
                gcc-c++ \
                make
            ;;
        centos|rhel)
            sudo yum install -y \
                net-tools \
                curl \
                vim \
                git \
                samba \
                openssh-server \
                python3-pip \
                nfs-utils \
                wget \
                gcc \
                gcc-c++ \
                make
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm \
                net-tools \
                curl \
                vim \
                git \
                samba \
                openssh \
                python-pip \
                nfs-utils \
                wget \
                base-devel
            ;;
        macos)
            # Homebrew가 설치되어 있는지 확인
            if ! command -v brew &> /dev/null; then
                log_info "Homebrew 설치 중..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            brew install \
                curl \
                vim \
                git \
                wget \
                python3
            ;;
    esac
    
    log_info "기본 패키지 설치 완료"
}

# 시스템 모니터링 패키지 설치
install_monitoring_packages() {
    log_header "시스템 모니터링 패키지 설치"
    
    case $OS in
        ubuntu|debian)
            sudo apt install -y \
                htop \
                iotop \
                nmon \
                glances \
                neofetch \
                tree \
                ncdu \
                dstat \
                atop \
                sysstat \
                lsof \
                strace \
                tcpdump \
                nethogs \
                iftop \
                vnstat \
                smartmontools \
                lm-sensors \
                inxi \
                bmon \
                multitail
            ;;
        fedora)
            sudo dnf install -y \
                htop \
                iotop \
                nmon \
                glances \
                neofetch \
                tree \
                ncdu \
                dstat \
                atop \
                sysstat \
                lsof \
                strace \
                tcpdump \
                nethogs \
                iftop \
                vnstat \
                smartmontools \
                lm_sensors \
                inxi \
                bmon \
                multitail
            ;;
        centos|rhel)
            # EPEL 저장소 활성화
            sudo yum install -y epel-release
            
            sudo yum install -y \
                htop \
                iotop \
                nmon \
                glances \
                neofetch \
                tree \
                ncdu \
                dstat \
                atop \
                sysstat \
                lsof \
                strace \
                tcpdump \
                nethogs \
                iftop \
                vnstat \
                smartmontools \
                lm_sensors \
                inxi \
                bmon \
                multitail
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm \
                htop \
                iotop \
                nmon \
                glances \
                neofetch \
                tree \
                ncdu \
                dstat \
                atop \
                sysstat \
                lsof \
                strace \
                tcpdump \
                nethogs \
                iftop \
                vnstat \
                smartmontools \
                lm_sensors \
                inxi \
                bmon \
                multitail
            ;;
        macos)
            brew install \
                htop \
                glances \
                neofetch \
                tree \
                ncdu \
                lsof \
                tcpdump \
                smartmontools \
                inxi
            
            # macOS 전용 도구
            brew install --cask stats
            ;;
    esac
    
    log_info "시스템 모니터링 패키지 설치 완료"
}

# 추가 모니터링 도구 설치 (선택사항)
install_advanced_monitoring() {
    log_header "고급 모니터링 도구 설치 (선택사항)"
    
    read -p "btop++를 설치하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_btop
    fi
    
    read -p "gotop을 설치하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_gotop
    fi
    
    read -p "bandwhich (네트워크 모니터링)를 설치하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_bandwhich
    fi
}

# btop++ 설치
install_btop() {
    log_info "btop++ 설치 중..."
    
    case $OS in
        ubuntu|debian)
            if ! sudo apt install -y btop 2>/dev/null; then
                install_btop_from_binary
            fi
            ;;
        fedora)
            if ! sudo dnf install -y btop 2>/dev/null; then
                install_btop_from_binary
            fi
            ;;
        centos|rhel)
            install_btop_from_binary
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm btop
            ;;
        macos)
            brew install btop
            ;;
        *)
            install_btop_from_binary
            ;;
    esac
}

# btop++ 바이너리 설치
install_btop_from_binary() {
    log_info "btop++ 바이너리로 설치 중..."
    
    LATEST_VERSION=$(curl -s https://api.github.com/repos/aristocratos/btop/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/' || echo "1.3.2")
    ARCH=$(uname -m)
    
    case $ARCH in
        x86_64) ARCH_NAME="x86_64" ;;
        aarch64|arm64) ARCH_NAME="aarch64" ;;
        *) log_error "지원되지 않는 아키텍처: $ARCH"; return 1 ;;
    esac
    
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    if [[ "$OS" == "macos" ]]; then
        BINARY_URL="https://github.com/aristocratos/btop/releases/download/v$LATEST_VERSION/btop-$ARCH_NAME-macos-ventura.tbz"
    else
        BINARY_URL="https://github.com/aristocratos/btop/releases/download/v$LATEST_VERSION/btop-$ARCH_NAME-linux-musl.tbz"
    fi
    
    if curl -L -o btop.tbz "$BINARY_URL"; then
        tar -xjf btop.tbz
        sudo cp btop/bin/btop /usr/local/bin/
        sudo chmod +x /usr/local/bin/btop
        log_info "btop++ 설치 완료"
    else
        log_error "btop++ 설치 실패"
    fi
    
    cd / && rm -rf "$TEMP_DIR"
}

# gotop 설치
install_gotop() {
    log_info "gotop 설치 중..."
    
    if command -v snap &> /dev/null && [[ "$OS" =~ ^(ubuntu|debian)$ ]]; then
        sudo snap install gotop
    else
        # GitHub 릴리스에서 설치
        LATEST_VERSION=$(curl -s https://api.github.com/repos/xxxserxxx/gotop/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/' || echo "4.2.0")
        ARCH=$(uname -m)
        
        case $ARCH in
            x86_64) ARCH_NAME="amd64" ;;
            aarch64|arm64) ARCH_NAME="arm64" ;;
            *) log_error "지원되지 않는 아키텍처: $ARCH"; return 1 ;;
        esac
        
        if [[ "$OS" == "macos" ]]; then
            PLATFORM="darwin"
        else
            PLATFORM="linux"
        fi
        
        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR"
        
        BINARY_URL="https://github.com/xxxserxxx/gotop/releases/download/v$LATEST_VERSION/gotop_v${LATEST_VERSION}_${PLATFORM}_${ARCH_NAME}.tgz"
        
        if curl -L -o gotop.tgz "$BINARY_URL"; then
            tar -xzf gotop.tgz
            sudo cp gotop /usr/local/bin/
            sudo chmod +x /usr/local/bin/gotop
            log_info "gotop 설치 완료"
        else
            log_error "gotop 설치 실패"
        fi
        
        cd / && rm -rf "$TEMP_DIR"
    fi
}

# bandwhich 설치
install_bandwhich() {
    log_info "bandwhich 설치 중..."
    
    case $OS in
        ubuntu|debian)
            if ! sudo apt install -y bandwhich 2>/dev/null; then
                install_bandwhich_from_binary
            fi
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm bandwhich
            ;;
        macos)
            brew install bandwhich
            ;;
        *)
            install_bandwhich_from_binary
            ;;
    esac
}

# bandwhich 바이너리 설치
install_bandwhich_from_binary() {
    LATEST_VERSION=$(curl -s https://api.github.com/repos/imsnif/bandwhich/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/' || echo "0.20.0")
    ARCH=$(uname -m)
    
    case $ARCH in
        x86_64) ARCH_NAME="x86_64" ;;
        aarch64|arm64) ARCH_NAME="aarch64" ;;
        *) log_error "지원되지 않는 아키텍처: $ARCH"; return 1 ;;
    esac
    
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    if [[ "$OS" == "macos" ]]; then
        BINARY_URL="https://github.com/imsnif/bandwhich/releases/download/v$LATEST_VERSION/bandwhich-v$LATEST_VERSION-$ARCH_NAME-apple-darwin.tar.gz"
    else
        BINARY_URL="https://github.com/imsnif/bandwhich/releases/download/v$LATEST_VERSION/bandwhich-v$LATEST_VERSION-$ARCH_NAME-unknown-linux-musl.tar.gz"
    fi
    
    if curl -L -o bandwhich.tar.gz "$BINARY_URL"; then
        tar -xzf bandwhich.tar.gz
        sudo cp bandwhich /usr/local/bin/
        sudo chmod +x /usr/local/bin/bandwhich
        log_info "bandwhich 설치 완료"
    else
        log_error "bandwhich 설치 실패"
    fi
    
    cd / && rm -rf "$TEMP_DIR"
}

# SSH 키 생성
generate_ssh_key() {
    log_header "SSH 키 생성"
    
    if [ -f ~/.ssh/id_rsa ]; then
        log_warn "SSH 키가 이미 존재합니다: ~/.ssh/id_rsa"
        read -p "새 SSH 키를 생성하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "SSH 키 생성을 건너뜁니다"
            return
        fi
    fi
    
    read -p "SSH 키에 사용할 이메일을 입력하세요 (엔터 시 기본값): " email
    
    if [ -z "$email" ]; then
        ssh-keygen -t rsa -b 4096
    else
        ssh-keygen -t rsa -b 4096 -C "$email"
    fi
    
    log_info "SSH 키 생성 완료"
    log_info "공개 키: ~/.ssh/id_rsa.pub"
}

# 시스템 서비스 활성화
enable_services() {
    log_header "시스템 서비스 활성화"
    
    case $OS in
        ubuntu|debian|fedora|centos|rhel)
            # SSH 서버 활성화
            if systemctl is-enabled ssh &>/dev/null || systemctl is-enabled sshd &>/dev/null; then
                sudo systemctl enable ssh 2>/dev/null || sudo systemctl enable sshd 2>/dev/null
                sudo systemctl start ssh 2>/dev/null || sudo systemctl start sshd 2>/dev/null
                log_info "SSH 서비스 활성화 완료"
            fi
            
            # Samba 서비스 (선택사항)
            read -p "Samba 서비스를 활성화하시겠습니까? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sudo systemctl enable smbd nmbd 2>/dev/null || sudo systemctl enable smb nmb 2>/dev/null
                sudo systemctl start smbd nmbd 2>/dev/null || sudo systemctl start smb nmb 2>/dev/null
                log_info "Samba 서비스 활성화 완료"
            fi
            ;;
        arch|manjaro)
            sudo systemctl enable sshd
            sudo systemctl start sshd
            log_info "SSH 서비스 활성화 완료"
            ;;
        macos)
            log_info "macOS에서는 시스템 환경설정에서 서비스를 활성화하세요"
            ;;
    esac
}

# 설치된 도구 목록 출력
show_installed_tools() {
    log_header "설치된 모니터링 도구"
    
    echo "=== 기본 시스템 모니터링 도구 ==="
    echo "• htop - 향상된 top 명령어"
    echo "• iotop - I/O 사용량 모니터링"
    echo "• nmon - 시스템 성능 모니터링"
    echo "• glances - 통합 시스템 모니터링"
    echo "• neofetch - 시스템 정보 표시"
    echo "• tree - 디렉토리 구조 표시"
    echo "• ncdu - 디스크 사용량 분석"
    echo ""
    echo "=== 네트워크 모니터링 도구 ==="
    echo "• nethogs - 프로세스별 네트워크 사용량"
    echo "• iftop - 네트워크 트래픽 모니터링"
    echo "• vnstat - 네트워크 통계"
    echo "• bmon - 실시간 네트워크 대역폭 모니터링"
    echo ""
    echo "=== 시스템 분석 도구 ==="
    echo "• sysstat - 시스템 통계 수집"
    echo "• lsof - 열린 파일 목록"
    echo "• strace - 시스템 호출 추적"
    echo "• atop - 고급 시스템/프로세스 모니터"
    echo "• smartmontools - 하드디스크 상태 모니터링"
    echo "• lm-sensors - 하드웨어 센서 모니터링"
    echo ""
    
    if command -v btop &> /dev/null; then
        echo "✓ btop++ - 현대적인 리소스 모니터"
    fi
    if command -v gotop &> /dev/null; then
        echo "✓ gotop - 터미널 기반 그래픽 모니터"
    fi
    if command -v bandwhich &> /dev/null; then
        echo "✓ bandwhich - 프로세스별 네트워크 사용량"
    fi
}

# 메인 실행 함수
main() {
    log_info "시스템 모니터링 환경 설치 스크립트 시작"
    
    # root 권한 확인
    if [[ $EUID -eq 0 ]]; then
        log_warn "root 사용자로 실행 중입니다. 일반 사용자로 실행하는 것을 권장합니다."
    fi
    
    # OS 감지
    detect_os
    
    if [[ "$OS" == "unknown" ]]; then
        log_error "지원되지 않는 OS입니다."
        exit 1
    fi
    
    # 단계별 실행
    system_update
    install_basic_packages
    install_monitoring_packages
    install_advanced_monitoring
    generate_ssh_key
    enable_services
    
    log_info "모든 설치가 완료되었습니다!"
    echo ""
    show_installed_tools
    
    log_info "시스템을 재부팅하는 것을 권장합니다."
}

# 스크립트 실행
main "$@"
