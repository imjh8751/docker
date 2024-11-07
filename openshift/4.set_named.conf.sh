#!/bin/bash

NAMED_CONF="/etc/named.conf"

# 백업 파일 생성
cp $NAMED_CONF ${NAMED_CONF}.bak

# listen-on port 53 옵션 수정
sed -i 's/listen-on port 53 {[^}]*};/listen-on port 53 { any; };/g' $NAMED_CONF

# allow-query 옵션 수정
sed -i 's/allow-query {[^}]*};/allow-query { any; };/g' $NAMED_CONF

# forwarders 옵션 추가
if ! grep -q "forwarders" $NAMED_CONF; then
    sed -i '/options {/a \ \ \ \ forwarders { 8.8.8.8; };' $NAMED_CONF
fi

echo "Options have been updated in $NAMED_CONF"
