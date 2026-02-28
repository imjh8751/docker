#!/bin/bash

echo "▶️ 1. HAProxy 패키지 설치를 시작합니다..."
yum -y install haproxy

echo "▶️ 2. HAProxy 원본 설정 파일 백업 및 초기화 중..."
cp -arp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.ori
cat /dev/null > /etc/haproxy/haproxy.cfg

HAPROXY_CONF="/etc/haproxy/haproxy.cfg"

echo "▶️ 3. OKD4 전용 HAProxy 설정(Config)을 작성합니다..."
cat <<EOF >> $HAPROXY_CONF
global
  log         127.0.0.1 local2
  pidfile     /var/run/haproxy.pid
  maxconn     4000
  daemon

defaults
  mode                    http
  log                     global
  option                  dontlognull
  option http-server-close
  option                  redispatch
  retries                 3
  timeout http-request    10s
  timeout queue           1m
  timeout connect         10s
  timeout client          1m
  timeout server          1m
  timeout http-keep-alive 10s
  timeout check           10s
  maxconn                 3000

frontend stats
  bind *:1936
  mode            http
  log             global
  maxconn 10
  stats enable
  stats hide-version
  stats refresh 30s
  stats show-node
  stats show-desc Stats for ocp4 cluster 
  stats auth admin:admin
  stats uri /stats

listen api-server-6443 
  bind *:6443
  mode tcp
  server master01 master01.ocp4.okd.io:6443 check inter 1s

listen machine-config-server-22623 
  bind *:22623
  mode tcp
  server master01 master01.ocp4.okd.io:22623 check inter 1s

listen ingress-router-443 
  bind *:443
  mode tcp
  balance source
  server master01 master01.ocp4.okd.io:443 check inter 1s

listen ingress-router-80 
  bind *:80
  mode tcp
  balance source
  server master01 master01.ocp4.okd.io:80 check inter 1s
EOF

echo "✅ HAProxy 설정 파일 작성이 완료되었습니다."

# ---------------------------------------------------------
# 추가된 OS 설정 파트 (SELinux, 방화벽, 데몬 실행)
# ---------------------------------------------------------

echo "▶️ 4. SELinux 정책 설정 중 (HAProxy 네트워크 바인딩 허용)..."
# SELinux가 Enforcing 상태일 경우 HAProxy가 비표준 포트(22623 등)를 사용할 수 있도록 허용합니다.
if command -v setsebool >/dev/null 2>&1; then
  setsebool -P haproxy_connect_any 1
  echo "✅ SELinux 정책(haproxy_connect_any) 적용 완료."
else
  echo "⚠️ setsebool 명령어가 없습니다. SELinux가 비활성화되어 있거나 도구가 설치되지 않았습니다."
fi

echo "▶️ 5. 방화벽(Firewalld) 포트 개방 중..."
if systemctl is-active --quiet firewalld; then
  firewall-cmd --permanent --add-port=6443/tcp
  firewall-cmd --permanent --add-port=22623/tcp
  firewall-cmd --permanent --add-port=80/tcp
  firewall-cmd --permanent --add-port=443/tcp
  firewall-cmd --permanent --add-port=1936/tcp
  firewall-cmd --reload
  echo "✅ 방화벽 포트(6443, 22623, 80, 443, 1936) 개방 완료."
else
  echo "⚠️ Firewalld가 실행 중이 아닙니다. 방화벽 설정을 건너뜁니다."
fi

echo "▶️ 6. HAProxy 서비스 자동 실행 등록 및 시작 중..."
systemctl daemon-reload
systemctl enable --now haproxy
systemctl restart haproxy

echo ""
echo "🎉 [성공] OKD4를 위한 HAProxy 서버 구성이 완벽하게 끝났습니다!"
echo "상태 확인 명령: systemctl status haproxy"