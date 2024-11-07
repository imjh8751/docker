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
baseDomain: okd.io
compute:
- hyperthreading: Enabled
  name: worker
  replicas: 0
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 3
metadata:
  name: ocp4
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  networkType: OVNKubernetes #OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
fips: false
pullSecret: '{"auths":{"cloud.openshift.com":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K29jbV9hY2Nlc3NfMmEwZGM5MTUzMGQ1NDMzZDljNDZmNGYwMDk4ZDU1YTQ6NkVZVldNMkJNRFFLNTE4WVBTVjU2NVNIUFcwODZQV0VMMjI2QlRQRzBCNjhUVkZBNzE5TDBRMk1aQzFSN1oyNQ==","email":"imjh8751@gmail.com"},"quay.io":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K29jbV9hY2Nlc3NfMmEwZGM5MTUzMGQ1NDMzZDljNDZmNGYwMDk4ZDU1YTQ6NkVZVldNMkJNRFFLNTE4WVBTVjU2NVNIUFcwODZQV0VMMjI2QlRQRzBCNjhUVkZBNzE5TDBRMk1aQzFSN1oyNQ==","email":"imjh8751@gmail.com"},"registry.connect.redhat.com":{"auth":"fHVoYy1wb29sLTVkZGVhNTNmLTUzNmItNDA0Mi1iODEzLTRmN2E4YzhiMThhNzpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSTRPVFZqT1dKa01EZzNORFkwT1RnMllXUXdOMk0wWWpSaE1XWTVaREkzTVNKOS5TVld2RHpBbnA0U0NYbkI4dndBa3pSeXNRZDZBVmh6UDdVcUJVX3FqSXRFd1RKYndJb2xnUzMyYUt5anZ6N2ZLakZXTi0wdkVabE43RVVFN2k0Yll6TjllUGlfLXBLbS13MHVuN01mcmdwSWpncndwVlFkb1lsTG1WVmtrNzBDdDhNRkFEb0lhWlkwY0FMQm9zSnlRVVBheFR5WFFCUGRuQUd1amdfYWRhekJRb2plRHh4cmtCYy1IbFNTNWpfUjBKeWgtVWdIc2xkeUdsTG1VMEhScENaVUFHZ2QzeklmU3piTUJrNHZadnQwUUlzTmVsQVhyS3QtSkowOHJnQmRvV2ZsTERWdDl5WEcyUU5vQUdQVjc4Q0FmR0FrbFl6dGZHQmkwWjRCQnhUQUlPQTI5cU9UOFJ4eFJSTkdnYUlhTkJ4bi1udDE3bDhSazUzZjVZMVNsSlAzMHlXckQtSUwxdkR6VEhEOG9MZWxUV2NkcTk3SmtkWmVkRnhRY3RxNWlfSnphdC05ajQyMmVzWDI3YmJPdGZFR3RNQlVhTHY4dVgwRERWdHE2NU5tX3Y3aHExTHJNX2RMU2kxdTkwX0JXdTlLQk40WHQydnJPSHRaTGs2LXpBeXhkWTY4SF9mbVAzaXBoc1E3VmZIcmpPc0lyeHFPZmZPY0taSXdoSkhmd2tmMVUxaWtGT3FtVlYtTzFoSEFvMzl0S1R2QVJIMzJPU1Z3TS1pNjBzbEtrN0NCNi0waVdNbVFWU3RoT0NzVWl0aVdVVzMzWUhCdFpGMjViMXNKUldHZ09sUU9VRU9CTzV3TGVTRV9uNkdOTFUwTVBBN3dQTXgtMWFJNE9sVHNZOUJEOGN4TXRDOFdWMmpBYVhtcTQ5QXFoMU1YQlgxbjFFVnliaEtJbXRSWQ==","email":"imjh8751@gmail.com"},"registry.redhat.io":{"auth":"fHVoYy1wb29sLTVkZGVhNTNmLTUzNmItNDA0Mi1iODEzLTRmN2E4YzhiMThhNzpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSTRPVFZqT1dKa01EZzNORFkwT1RnMllXUXdOMk0wWWpSaE1XWTVaREkzTVNKOS5TVld2RHpBbnA0U0NYbkI4dndBa3pSeXNRZDZBVmh6UDdVcUJVX3FqSXRFd1RKYndJb2xnUzMyYUt5anZ6N2ZLakZXTi0wdkVabE43RVVFN2k0Yll6TjllUGlfLXBLbS13MHVuN01mcmdwSWpncndwVlFkb1lsTG1WVmtrNzBDdDhNRkFEb0lhWlkwY0FMQm9zSnlRVVBheFR5WFFCUGRuQUd1amdfYWRhekJRb2plRHh4cmtCYy1IbFNTNWpfUjBKeWgtVWdIc2xkeUdsTG1VMEhScENaVUFHZ2QzeklmU3piTUJrNHZadnQwUUlzTmVsQVhyS3QtSkowOHJnQmRvV2ZsTERWdDl5WEcyUU5vQUdQVjc4Q0FmR0FrbFl6dGZHQmkwWjRCQnhUQUlPQTI5cU9UOFJ4eFJSTkdnYUlhTkJ4bi1udDE3bDhSazUzZjVZMVNsSlAzMHlXckQtSUwxdkR6VEhEOG9MZWxUV2NkcTk3SmtkWmVkRnhRY3RxNWlfSnphdC05ajQyMmVzWDI3YmJPdGZFR3RNQlVhTHY4dVgwRERWdHE2NU5tX3Y3aHExTHJNX2RMU2kxdTkwX0JXdTlLQk40WHQydnJPSHRaTGs2LXpBeXhkWTY4SF9mbVAzaXBoc1E3VmZIcmpPc0lyeHFPZmZPY0taSXdoSkhmd2tmMVUxaWtGT3FtVlYtTzFoSEFvMzl0S1R2QVJIMzJPU1Z3TS1pNjBzbEtrN0NCNi0waVdNbVFWU3RoT0NzVWl0aVdVVzMzWUhCdFpGMjViMXNKUldHZ09sUU9VRU9CTzV3TGVTRV9uNkdOTFUwTVBBN3dQTXgtMWFJNE9sVHNZOUJEOGN4TXRDOFdWMmpBYVhtcTQ5QXFoMU1YQlgxbjFFVnliaEtJbXRSWQ==","email":"imjh8751@gmail.com"}}}'
sshKey: '$ssh_key'
EOF

echo "Configuration has been added to $CONFIG_FILE"

# 백업파일 생성
cp -arp install-config.yaml install-config.yaml.bak
cd /root

# manifests 생성
openshift-install create manifests --dir installation_directory/

# master 컨테이너 배포 설정 false 처리
sed -i 's/true/false/' /root/installation_directory/manifests/cluster-scheduler-02-config.yml

# ignition config 파일 생성
cd /root
openshift-install create ignition-configs --dir installation_directory/

# ignition config 파일 복사 및 권한 부여
cd /root/installation_directory
cp -arp *.ign /usr/share/nginx/html/files/
chmod 644 /usr/share/nginx/html/files/*

# coreos 파일 다운로드
cd /usr/share/nginx/html/files
openshift-install coreos print-stream-json | grep '.iso[^.]' | grep x86_64
wget https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.17-9.4/builds/417.94.202409120353-0/x86_64/rhcos-417.94.202409120353-0-live.x86_64.iso

# igition hash 값 생성
cd /usr/share/nginx/html/files
sha512sum bootstrap.ign |awk {'print $1'} > bootstrap.hash
sha512sum master.ign |awk {'print $1'} > master.hash
sha512sum worker.ign |awk {'print $1'} > worker.hash
