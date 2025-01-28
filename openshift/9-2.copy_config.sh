#!/bin/bash

# ignition config 파일 복사 및 권한 부여
cd /root/installation_directory
cp -arp *.ign /usr/share/nginx/html/files/
chmod 644 /usr/share/nginx/html/files/*

# coreos 파일 다운로드
cd /usr/share/nginx/html/files
openshift-install coreos print-stream-json | grep '.iso[^.]' | grep x86_64
COREOS=`openshift-install coreos print-stream-json | grep '.iso[^.]' | grep x86_64 | awk -F '"' '/location/ {print $4}'`
echo $COREOS
wget $COREOS
#wget https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.17-9.4/builds/417.94.202409120353-0/x86_64/rhcos-417.94.202409120353-0-live.x86_64.iso
rsync -avhP rhcos*.iso 192.168.0.101:/pv2-zfs/pv2-vol/template/iso 

# igition hash 값 생성
cd /usr/share/nginx/html/files
sha512sum bootstrap.ign |awk {'print $1'} > bootstrap.hash
sha512sum master.ign |awk {'print $1'} > master.hash
sha512sum worker.ign |awk {'print $1'} > worker.hash
