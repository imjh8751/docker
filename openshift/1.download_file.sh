# 설치 폴더 추가
mkdir -p /root/setup_files
cd /root/setup_files

# 파일 다운로드
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux-4.17.3.tar.gz
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-install-linux-4.17.3.tar.gz

# 압축 해제
tar -xvf *.tar

# local 복사
mv oc kubectl openshift-install /usr/local/bin

# 버전 확인
oc version
kubectl version
openshift-install version

# SELINUX=disabled
setenforce 0

# name server 설치
yum -y install bind bind-utils
