#!/bin/bash

set -e

echo "▶️ 시스템 Locale을 한국어(ko_KR.UTF-8)로 설정합니다."

# 1. locale 패키지 설치 및 설정
if [ -f /etc/debian_version ]; then
  echo "🟢 Debian/Ubuntu 계열 감지됨"
  apt update && apt install -y locales vim
  locale-gen ko_KR.UTF-8
  update-locale LANG=ko_KR.UTF-8
elif [ -f /etc/redhat-release ]; then
  echo "🟡 RHEL/CentOS 계열 감지됨"
  yum install -y glibc-common vim-enhanced
  localedef -c -f UTF-8 -i ko_KR ko_KR.UTF-8
else
  echo "🔴 지원되지 않는 OS입니다. 수동 설정 필요"
  exit 1
fi

# 2. locale 환경변수 설정
if [ -f /etc/locale.conf ]; then
  echo "LANG=ko_KR.UTF-8" > /etc/locale.conf
elif [ -f /etc/default/locale ]; then
  echo 'LANG="ko_KR.UTF-8"' > /etc/default/locale
fi

export LANG=ko_KR.UTF-8
export LANGUAGE=ko_KR:ko
export LC_ALL=ko_KR.UTF-8

# 3. Vim 설정 보완 (한글 깨짐 방지)
echo "📄 vi(vim) 한글 설정 적용 중..."

# 시스템 전역 설정
if [ -f /etc/vimrc ]; then
  VIMRC="/etc/vimrc"
elif [ -f /etc/vim/vimrc ]; then
  VIMRC="/etc/vim/vimrc"
else
  VIMRC=""
fi

if [ -n "$VIMRC" ]; then
  grep -q "set encoding=utf-8" "$VIMRC" 2>/dev/null || {
    echo -e "\n\" [자동추가] 한글 지원" >> "$VIMRC"
    echo "set encoding=utf-8" >> "$VIMRC"
    echo "set fileencodings=utf-8,euc-kr,cp949" >> "$VIMRC"
    echo "set termencoding=utf-8" >> "$VIMRC"
  }
fi

# 사용자 ~/.vimrc 도 생성
USER_VIMRC="$HOME/.vimrc"
if ! grep -q "set encoding=utf-8" "$USER_VIMRC" 2>/dev/null; then
  echo -e "\n\" [자동추가] 한글 지원" >> "$USER_VIMRC"
  echo "set encoding=utf-8" >> "$USER_VIMRC"
  echo "set fileencodings=utf-8,euc-kr,cp949" >> "$USER_VIMRC"
  echo "set termencoding=utf-8" >> "$USER_VIMRC"
fi

echo "✅ 모든 설정 완료. 아래 명령어로 즉시 적용 가능:"
echo ""
echo "  source /etc/locale.conf  또는  source /etc/default/locale"
echo "  export LANG=ko_KR.UTF-8"
echo ""
echo "📢 이제 vi/vim에서 한글이 정상 표시됩니다!"
