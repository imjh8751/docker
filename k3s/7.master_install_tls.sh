#!/bin/bash

# Helm 설치를 위한 GPG 키 추가
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -

# HTTPS를 통한 패키지 설치를 위해 apt-transport-https 설치
sudo apt-get install apt-transport-https --yes

# Helm 저장소 추가
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

# 패키지 목록 업데이트
sudo apt-get update

# Helm 설치
sudo apt-get install helm

# Jetstack Helm 저장소 추가
helm repo add jetstack https://charts.jetstack.io

# Helm 저장소 업데이트
helm repo update

# cert-manager 최신 버전 가져오기
LATEST_VERSION=$(curl -s https://api.github.com/repos/cert-manager/cert-manager/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

# cert-manager CRDs 다운로드
curl -L -o cert-manager.yml https://github.com/cert-manager/cert-manager/releases/download/v${LATEST_VERSION}/cert-manager.crds.yaml

# cert-manager CRDs 적용
kubectl apply -f cert-manager.yml

# cert-manager 설치
helm install cert-manager jetstack/cert-manager \
--namespace cert-manager \
--create-namespace \
--version v1.8.0

# cert-manager 네임스페이스의 파드 상태 확인
kubectl get pods --namespace=cert-manager

# tls-issuer.yml 파일 생성
cat <<EOF > tls-issuer.yml
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: tls-issuer # 마음대로 지정합니다
  namespace: default
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: [YOUR_EMAIL]
    privateKeySecretRef:
      name: tls-key # 마음대로 지정합니다
    solvers:
      - selector: {}
        http01:
          ingress:
            class: traefik
EOF

# tls-issuer 생성
kubectl create -f tls-issuer.yml

# Issuer 상태 확인
kubectl get issuer -o wide

# tls-cert.yml 파일 생성
cat <<EOF > tls-cert.yml
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: tls-cert
  namespace: default
spec:
  secretName: tls-secret # 마음대로 작성
  issuerRef:
    name: tls-issuer # 위에서 지정한 이름
  commonName: [YOUR_DOMAIN]
  dnsNames:
    - [YOUR_DOMAIN]
    # 서브도메인 등록 가능
    # - sub.example.com
EOF

# Certificate 생성
kubectl create -f tls-cert.yml

# Certificate 상태 확인
kubectl get certificate -o wide

# traefik.yml 파일 생성
cat <<EOF > traefik.yml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: traefik-routers
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
    - host: [YOUR_DOMAIN]
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: echo-server
                port:
                  number: 80
  tls:
    - secretName: tls-secret # tls-cert 에서 지정한 키 이름
      hosts:
        - [YOUR_DOMAIN]
EOF

# Ingress 리소스 생성
kubectl create -f traefik.yml

# Certificate 상세 정보 확인
kubectl describe certificate tls-cert

echo "모든 설정이 완료되었습니다."
