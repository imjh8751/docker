#!/bin/bash

NAMED_CONF="/etc/named.conf"

# 백업 파일 생성
cp $NAMED_CONF ${NAMED_CONF}.bak

# listen-on port 53 옵션 수정
sed -i 's/listen-on port 53 {[^}]*};/listen-on port 53 { any; };/g' $NAMED_CONF

# allow-query 옵션 수정
sed -i 's/allow-query     {[^}]*};/allow-query     { any; };/g' $NAMED_CONF

# forwarders 옵션 (탭 들여쓰기 포함)
FORWARDERS="        forwarders { 8.8.8.8; 168.126.63.1; };"

# sed 명령어를 사용하여 recursion yes; 아래에 들여쓰기된 forwarders 추가
sed -i '/recursion yes;/a\ '"$FORWARDERS" "$NAMED_CONF"

echo "Options have been updated in $NAMED_CONF"
