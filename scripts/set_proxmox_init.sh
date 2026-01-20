#!/bin/bash

#vi /etc/apt/sources.list.d/pve-enterprise.list
#vi /etc/apt/sources.list​
#deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription​
#apt update
#apt upgrade​

# 위젯 설정파일을 홈디렉토리로 백업
cp /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js ~/proxmoxlib.js_bak

# 경고메시지 제거
sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

# 서비스 재시작
systemctl restart pveproxy.service
