# 필수 설치 프로그램
yum install wget tar vim curl net-tools nc -y

# name server 설치
yum install bind bind-utils -y

# 설치 폴더 추가
mkdir -p /root/setup_files
cd /root/setup_files

# 파일 다운로드 : https://mirror.openshift.com/pub/openshift-v4/clients/ocp/
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux-4.17.4.tar.gz
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-install-linux-4.17.4.tar.gz

# 압축 해제
tar -xvf openshift-client-linux-4.17.4.tar.gz
tar -xvf openshift-install-linux-4.17.4.tar.gz

# local 복사
mv oc kubectl openshift-install /usr/local/bin

# 버전 확인
oc version
kubectl version
openshift-install version

# SELINUX=disabled
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
setenforce 0
