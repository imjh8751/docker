#!/bin/bash

set -e

echo "▶️ 시스템 Locale과 Timezone, vi 설정을 한국어(KST) 기준으로 구성합니다."

# 1. 시간대 설정
echo "🕒 시간대를 Asia/Seoul로 설정합니다..."
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
if [ -f /etc/timezone ]; then
  echo "Asia/Seoul" > /etc/timezone
fi
export TZ="Asia/Seoul"

# 2. locale 설정
echo "🌐 Locale을 한국어(UTF-8)로 설정 중..."

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

# 3. locale 환경변수 적용
if [ -f /etc/locale.conf ]; then
  echo "LANG=ko_KR.UTF-8" > /etc/locale.conf
elif [ -f /etc/default/locale ]; then
  echo 'LANG="ko_KR.UTF-8"' > /etc/default/locale
fi

export LANG=ko_KR.UTF-8
export LANGUAGE=ko_KR:ko
export LC_ALL=ko_KR.UTF-8

# 4. vim 설정
echo "📄 vi/vim 한글 설정 적용 중..."
VIMRC_SYS=""
[ -f /etc/vimrc ] && VIMRC_SYS="/etc/vimrc"
[ -f /etc/vim/vimrc ] && VIMRC_SYS="/etc/vim/vimrc"

if [ -n "$VIMRC_SYS" ]; then
  grep -q "set encoding=utf-8" "$VIMRC_SYS" 2>/dev/null || {
    echo -e "\n\" [자동추가] 한글 지원" >> "$VIMRC_SYS"
    echo "set encoding=utf-8" >> "$VIMRC_SYS"
    echo "set fileencodings=utf-8,euc-kr,cp949" >> "$VIMRC_SYS"
    echo "set termencoding=utf-8" >> "$VIMRC_SYS"
  }
fi

USER_VIMRC="$HOME/.vimrc"
if ! grep -q "set encoding=utf-8" "$USER_VIMRC" 2>/dev/null; then
  echo -e "\n\" [자동추가] 한글 지원" >> "$USER_VIMRC"
  echo "set encoding=utf-8" >> "$USER_VIMRC"
  echo "set fileencodings=utf-8,euc-kr,cp949" >> "$USER_VIMRC"
  echo "set termencoding=utf-8" >> "$USER_VIMRC"
fi

# 5. 결과 확인
echo ""
echo "✅ 설정 완료 결과:"
echo "🕓 현재 시간 (KST): $(date)"
echo "🌍 현재 locale:"
locale

echo ""
echo "⚠️ 세션에 즉시 적용하려면 다음 명령을 실행하세요:"
echo "  source /etc/locale.conf     # 또는 /etc/default/locale"
echo "  export TZ=Asia/Seoul        # 타임존 적용"
