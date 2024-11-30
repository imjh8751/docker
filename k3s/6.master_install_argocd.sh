#!/bin/bash

# namespace 생성
kubectl create namespace argocd

# istio 가 설치되어있다면 injection 추가
kubectl label ns argocd istio-injection=enabled

# Argo CD 설치 YAML 파일 다운로드
curl -o install.yaml https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# --insecure 옵션 추가
sed -i '/- \/usr\/local\/bin\/argocd-server/a\        - --insecure' install.yaml

# 변경된 파일 내용 출력 (선택 사항)
echo "변경된 install.yaml 파일 내용:"
grep -A 3 '- \/usr\/local\/bin\/argocd-server' install.yaml

# Argo CD 설치
kubectl apply -f install.yaml

#############################################################################################################
# 참고용
# 설치 
#kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 삭제
#kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
