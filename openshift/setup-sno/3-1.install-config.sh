#!/bin/bash

# SSH 키 생성
ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519

# 생성된 공개 키 값을 읽어서 변수에 저장
ssh_key=$(cat ~/.ssh/id_ed25519.pub)

# installation_directory 폴더 생
mkdir -p /root/installation_directory
cd /root/installation_directory

# 설정파일 생성
CONFIG_FILE="/root/installation_directory/install-config.yaml"
cat /dev/null > /root/installation_directory/install-config.yaml

cat <<EOF >> $CONFIG_FILE
apiversion: v1
baseDomain: sno.io
compute:
- hyperthreading: Enabled
  name: worker
  replicas: 0
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 1
metadata:
  name: ocp4
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork: #SNO 설치 시 주석 해제
  - cidr: 10.0.0.0/16 #SNO 설치 시 주석 해제
  networkType: OVNKubernetes #OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
bootstrapInPlace: #SNO 설치 시 주석 해제
  installationDisk: /dev/sda #SNO 설치 시 주석 해제
fips: false
pullSecret: '{"auths":{"cloud.openshift.com":{"auth":"==","email":"imjh8751@gmail.com"},"quay.io":{"auth":"==","email":"imjh8751@gmail.com"},"registry.connect.redhat.com":{"auth":"==","email":"imjh8751@gmail.com"},"registry.redhat.io":{"auth":"==","email":"imjh8751@gmail.com"}}}'
sshKey: '$ssh_key'
EOF

echo "Configuration has been added to $CONFIG_FILE"

# 백업파일 생성
cp -arp install-config.yaml install-config.yaml.bak
cd /root

# manifests 생성
openshift-install create manifests --dir installation_directory/

# master 컨테이너 배포 설정 false 처리, SNO 설치 시 주석
#sed -i 's/true/false/' /root/installation_directory/manifests/cluster-scheduler-02-config.yml

# ignition config 파일 생성
cd /root
#openshift-install create ignition-configs --dir installation_directory/
openshift-install create single-node-ignition-config --dir installation_directory/ # SNO 설치 시 주석 해제
