#!/bin/bash

# Gemini CLI 설치 스크립트
# OS별로 Node.js와 Gemini CLI를 설치합니다

set -e  # 에러 발생시 스크립트 종료

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수들
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# OS 감지 함수
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$NAME
            VER=$VERSION_ID
        elif type lsb_release >/dev/null 2>&1; then
            OS=$(lsb_release -si)
            VER=$(lsb_release -sr)
        else
            OS=$(uname -s)
            VER=$(uname -r)
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
        VER=$(sw_vers -productVersion)
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        OS="Windows"
        VER=$(cmd //c ver 2>/dev/null | grep -o '[0-9]*\.[0-9]*\.[0-9]*')
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
}

# Node.js 버전 확인 함수
check_nodejs() {
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version | cut -d'v' -f2)
        REQUIRED_VERSION="18.0.0"
        
        if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$NODE_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
            log_success "Node.js $NODE_VERSION 이미 설치됨 (요구사항: v18+)"
            return 0
        else
            log_warning "Node.js $NODE_VERSION 설치됨, 하지만 v18+ 필요"
            return 1
        fi
    else
        log_info "Node.js가 설치되지 않음"
        return 1
    fi
}

# macOS용 설치 함수
install_macos() {
    log_info "macOS 환경에서 설치를 시작합니다..."
    
    # Homebrew 확인 및 설치
    if ! command -v brew >/dev/null 2>&1; then
        log_info "Homebrew 설치 중..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # PATH 설정 (Apple Silicon Mac의 경우)
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
    
    # Node.js 설치
    if ! check_nodejs; then
        log_info "Node.js 설치 중..."
        brew install node
    fi
    
    # npm 업데이트
    log_info "npm 업데이트 중..."
    npm install -g npm@latest
}

# Ubuntu/Debian용 설치 함수
install_ubuntu_debian() {
    log_info "Ubuntu/Debian 환경에서 설치를 시작합니다..."
    
    # 패키지 목록 업데이트
    sudo apt update
    
    # curl 설치 (없는 경우)
    if ! command -v curl >/dev/null 2>&1; then
        log_info "curl 설치 중..."
        sudo apt install -y curl
    fi
    
    # Node.js 설치
    if ! check_nodejs; then
        log_info "NodeSource repository 추가 중..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        
        log_info "Node.js 설치 중..."
        sudo apt install -y nodejs
    fi
}

# CentOS/RHEL/Fedora용 설치 함수
install_redhat() {
    log_info "Red Hat 계열 환경에서 설치를 시작합니다..."
    
    # 패키지 매니저 감지
    if command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
    else
        log_error "지원하지 않는 패키지 매니저입니다"
        exit 1
    fi
    
    # curl 설치 (없는 경우)
    if ! command -v curl >/dev/null 2>&1; then
        log_info "curl 설치 중..."
        sudo $PKG_MANAGER install -y curl
    fi
    
    # Node.js 설치
    if ! check_nodejs; then
        log_info "NodeSource repository 추가 중..."
        curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
        
        log_info "Node.js 설치 중..."
        sudo $PKG_MANAGER install -y nodejs
    fi
}

# Arch Linux용 설치 함수
install_arch() {
    log_info "Arch Linux 환경에서 설치를 시작합니다..."
    
    # 패키지 데이터베이스 업데이트
    sudo pacman -Sy
    
    # Node.js 설치
    if ! check_nodejs; then
        log_info "Node.js 설치 중..."
        sudo pacman -S --noconfirm nodejs npm
    fi
}

# Windows (WSL/Git Bash/MSYS2)용 설치 함수
install_windows() {
    log_info "Windows 환경에서 설치를 시작합니다..."
    log_warning "Windows에서는 Node.js를 수동으로 설치하는 것을 권장합니다."
    log_info "https://nodejs.org에서 Node.js를 다운로드하여 설치하세요."
    
    if ! check_nodejs; then
        log_error "Node.js가 설치되지 않았습니다. 수동으로 설치 후 다시 실행하세요."
        exit 1
    fi
}

# Gemini CLI 설치 함수
install_gemini_cli() {
    log_info "Gemini CLI 설치 중..."
    
    # 전역 설치
    npm install -g @google/gemini-cli
    
    if [ $? -eq 0 ]; then
        log_success "Gemini CLI가 성공적으로 설치되었습니다!"
    else
        log_error "Gemini CLI 설치에 실패했습니다."
        exit 1
    fi
}

# 설치 후 설정 안내
post_install_info() {
    log_success "설치가 완료되었습니다!"
    echo
    log_info "다음 단계:"
    echo "1. API 키 설정 (선택사항 - Google 계정으로도 로그인 가능):"
    echo "   export GEMINI_API_KEY=\"YOUR_API_KEY\""
    echo "   또는 ~/.bashrc 또는 ~/.zshrc에 추가"
    echo
    echo "2. Google AI Studio에서 API 키 생성:"
    echo "   https://aistudio.google.com/apikey"
    echo
    echo "3. Gemini CLI 실행:"
    echo "   gemini"
    echo
    echo "4. 프로젝트 디렉토리에서 실행하여 코드베이스와 상호작용:"
    echo "   cd your-project"
    echo "   gemini"
    echo
    log_info "무료 사용량: 60 요청/분, 1000 요청/일 (Google 계정 로그인 시)"
}

# 메인 함수
main() {
    echo "================================"
    echo "    Gemini CLI 설치 스크립트    "
    echo "================================"
    echo
    
    # OS 감지
    detect_os
    log_info "감지된 OS: $OS $VER"
    echo
    
    # OS별 설치
    case "$OS" in
        "macOS")
            install_macos
            ;;
        "Ubuntu"*|"Debian"*)
            install_ubuntu_debian
            ;;
        "CentOS"*|"Red Hat"*|"Fedora"*|"Rocky"*|"AlmaLinux"*)
            install_redhat
            ;;
        "Arch"*|"Manjaro"*)
            install_arch
            ;;
        "Windows"*)
            install_windows
            ;;
        *)
            log_warning "지원하지 않는 OS입니다: $OS"
            log_info "Node.js v18+를 수동으로 설치한 후 계속 진행합니다..."
            if ! check_nodejs; then
                log_error "Node.js v18+가 필요합니다. 설치 후 다시 실행하세요."
                exit 1
            fi
            ;;
    esac
    
    # Node.js 설치 확인
    if ! check_nodejs; then
        log_error "Node.js 설치에 실패했습니다."
        exit 1
    fi
    
    # Gemini CLI 설치
    install_gemini_cli
    
    # 설치 후 안내
    post_install_info
}

# 스크립트 실행
main "$@"
