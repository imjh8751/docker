# 필수 설치 프로그램
yum install wget tar vim curl net-tools nc httpd-tools -y

# name server 설치
yum install bind bind-utils -y

# 설치 폴더 추가
mkdir -p /root/setup_files
cd /root/setup_files

# 2026.02 기준 최신버전은 4.21
STABLE_VER=4.20

# 웹 페이지에서 HTML 내용을 가져옵니다
content=$(curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-$STABLE_VER/)

# 필요한 버전 정보를 추출합니다
OCP_VER=`echo "$content" | grep -oP '(?<=openshift-client-linux-)[^"]*(?=.tar.gz)' | awk -F '-' '{print $1}' | head -n 1`

# 파일 다운로드 : https://mirror.openshift.com/pub/openshift-v4/clients/ocp/
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-$STABLE_VER/openshift-client-linux-$OCP_VER.tar.gz
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-$STABLE_VER/openshift-install-linux-$OCP_VER.tar.gz

# 압축 해제
tar -xvf openshift-client-linux-$OCP_VER.tar.gz
tar -xvf openshift-install-linux-$OCP_VER.tar.gz

# local 복사
mv oc kubectl openshift-install /usr/local/sbin

# 버전 확인
oc version
kubectl version
openshift-install version

# SELINUX=disabled
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
setenforce 0
