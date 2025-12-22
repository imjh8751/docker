#!/usr/bin/env bash
set -e

#############################################
# 기본 설정
#############################################
DEFAULT_NODE_VERSION="24"
CLAUDE_PKG="@anthropic-ai/claude-code"
GEMINI_PKG="@google/gemini-cli"

#############################################
# 색상 / 로그
#############################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_i(){ echo -e "${BLUE}[INFO]${NC} $1"; }
log_w(){ echo -e "${YELLOW}[WARN]${NC} $1"; }
log_e(){ echo -e "${RED}[ERROR]${NC} $1"; }
log_ok(){ echo -e "${GREEN}[OK]${NC} $1"; }

#############################################
# nvm 로드 (항상)
#############################################
load_nvm() {
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
}

#############################################
# OS 감지
#############################################
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_FAMILY=$ID
    OS_NAME=$NAME
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_FAMILY="macos"
    OS_NAME="macOS"
  else
    OS_FAMILY="unknown"
    OS_NAME="Unknown"
  fi
}

#############################################
# Node/npm 확인
#############################################
node_ready() {
  load_nvm
  command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1
}

#############################################
# Node 설치
#############################################
install_node() {
  read -rp "설치할 Node 메이저 버전 (기본 ${DEFAULT_NODE_VERSION}): " NODE_VER
  NODE_VER="${NODE_VER:-$DEFAULT_NODE_VERSION}"

  log_i "Node.js v${NODE_VER} 설치 시작"

  # 1) nvm
  if curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash; then
    load_nvm
    nvm install "$NODE_VER"
    nvm use "$NODE_VER"
    nvm alias default "$NODE_VER"
    log_ok "nvm으로 Node 설치 완료"
    return
  fi

  log_w "nvm 실패 → OS 패키지 설치 시도"

  case "$OS_FAMILY" in
    ubuntu|debian)
      curl -fsSL "https://deb.nodesource.com/setup_${NODE_VER}.x" | sudo -E bash -
      sudo apt install -y nodejs
      ;;
    rhel|centos|rocky|almalinux|fedora)
      curl -fsSL "https://rpm.nodesource.com/setup_${NODE_VER}.x" | sudo bash -
      sudo dnf install -y nodejs || sudo yum install -y nodejs
      ;;
    arch)
      sudo pacman -S --noconfirm nodejs npm
      ;;
    macos)
      command -v brew >/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      brew install node
      ;;
    *)
      log_e "지원하지 않는 OS"
      exit 1
      ;;
  esac
}

#############################################
# Node 강제 보장
#############################################
require_node() {
  if node_ready; then
    return 0
  fi

  log_w "Node.js / npm이 준비되지 않음"
  read -rp "지금 Node.js를 설치하시겠습니까? (Y/n): " yn
  yn=${yn:-Y}

  [[ "$yn" =~ ^[Yy]$ ]] || return 1
  install_node

  node_ready || {
    log_e "Node/npm 초기화 실패 (새 셸 필요할 수 있음)"
    exit 1
  }
}

#############################################
# npm 글로벌 경로
#############################################
setup_npm_global() {
  mkdir -p ~/.npm-global
  npm config set prefix '~/.npm-global'
  export PATH="$HOME/.npm-global/bin:$PATH"

  grep -q npm-global ~/.bashrc || echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
}

#############################################
# CLI 설치
#############################################
install_cli() {
  local PKG=$1
  local NAME=$2

  require_node

  log_i "$NAME CLI 설치"
  setup_npm_global

  npm install -g "$PKG" && log_ok "$NAME 설치 완료" && return

  log_w "$NAME 설치 실패 → sudo fallback"
  sudo npm install -g "$PKG" --unsafe-perm
}

#############################################
# CLI 제거
#############################################
remove_cli() {
  npm uninstall -g "$1" || sudo npm uninstall -g "$1"
}

#############################################
# 상태 출력
#############################################
status() {
  load_nvm
  echo
  echo "Node  : $(command -v node >/dev/null && node -v || echo X)"
  echo "npm   : $(command -v npm >/dev/null && npm -v || echo X)"
  echo "Claude: $(command -v claude >/dev/null && claude --version || echo X)"
  echo "Gemini: $(command -v gemini >/dev/null && gemini --version || echo X)"
}

#############################################
# 메뉴
#############################################
menu() {
  echo
  echo "=== AI CLI Manager ==="
  echo "1) Node 설치"
  echo "2) Claude 설치"
  echo "3) Gemini 설치"
  echo "4) Claude 제거"
  echo "5) Gemini 제거"
  echo "6) 상태 확인"
  echo "0) 종료"
  read -rp "선택: " M
}

#############################################
# MAIN
#############################################
detect_os
log_i "OS: $OS_NAME ($OS_FAMILY)"

while true; do
  menu
  case "$M" in
    1) install_node ;;
    2) install_cli "$CLAUDE_PKG" "Claude" ;;
    3) install_cli "$GEMINI_PKG" "Gemini" ;;
    4) remove_cli "$CLAUDE_PKG" ;;
    5) remove_cli "$GEMINI_PKG" ;;
    6) status ;;
    0) exit 0 ;;
  esac
done
