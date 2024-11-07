#!/bin/bash
yum -y install haproxy
cp -arp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.ori

HAPROXY_CONF="/etc/haproxy/haproxy.cfg"

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
  server bootstrap bootstrap.ocp4.okd.io:6443 check inter 1s backup 
  server master01 master01.ocp4.okd.io:6443 check inter 1s
  server master02 master02.ocp4.okd.io:6443 check inter 1s
  server master03 master03.ocp4.okd.io:6443 check inter 1s

listen machine-config-server-22623 
  bind *:22623
  mode tcp
  server bootstrap bootstrap.ocp4.okd.io:22623 check inter 1s backup 
  server master01 master01.ocp4.okd.io:22623 check inter 1s
  server master02 master02.ocp4.okd.io:22623 check inter 1s
  server master03 master03.ocp4.okd.io:22623 check inter 1s

listen ingress-router-443 
  bind *:443
  mode tcp
  balance source
  server worker01 worker01.ocp4.okd.io:443 check inter 1s
  server worker02 worker02.ocp4.okd.io:443 check inter 1s

listen ingress-router-80 
  bind *:80
  mode tcp
  balance source
  server worker01 worker01.ocp4.okd.io:80 check inter 1s
  server worker02 worker02.ocp4.okd.io:80 check inter 1s
EOF

echo "HAProxy configuration has been added to $HAPROXY_CONF"

# haproxy 재기동
systemctl enable haproxy
systemctl start haproxy
