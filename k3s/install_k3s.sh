##############################################
### 1. k3s 설치
# 1. **필수 패키지 설치**
#sudo apt-get update
#sudo apt-get install -y curl

# 2. **k3s 설치**
curl -sfL https://get.k3s.io | sh -

# 3. **설치 확인**
sudo systemctl status k3s

##############################################
### 2. kubectl 설정
# 1. **kubeconfig 파일 설정**
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# 2. **환경 변수 설정**
echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
source ~/.bashrc

##############################################
### 3. kubectl 설치
# 1 Kubernetes repository 추가
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# 2. kubectl 설치
sudo yum install -y kubectl

# 3. 버전확인
kubectl version --client

##############################################
### 4. 노드 및 파드 확인
# 1. **노드 확인**
kubectl get nodes

# 2. **파드 확인**
kubectl get pods --all-namespaces
