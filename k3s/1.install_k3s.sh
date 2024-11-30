##############################################
### 1. k3s 설치
# 1. **필수 패키지 설치**
#sudo apt-get update
#sudo apt-get install -y curl

# 2. **k3s 설치**
curl -sfL https://get.k3s.io  | INSTALL_K3S_EXEC="--disable=traefik" sh -

# 3. **설치 확인**
#sudo systemctl status k3s

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
# 1 k3s 복사
sudo cp /usr/local/bin/k3s /usr/bin/
sudo cp /usr/local/bin/kubectl /usr/bin/

# 3. 버전확인
kubectl version --client

##############################################
# kubectl 자동 완성 활성화
source <(kubectl completion bash)
alias k='kubectl'

# bash 자동 완성
complete -o default -F __start_kubectl k

##############################################
### 4. 노드 및 파드 확인
# 1. **노드 확인**
kubectl get nodes

# 2. **파드 확인**
kubectl get pods --all-namespaces

##############################################
### 자5. 토큰 저장
# 1. 토큰 저장
cat /var/lib/rancher/k3s/server/node-token
# curl --upload-file /var/lib/rancher/k3s/server/node-token http://192.168.0.69:8080/token.log
