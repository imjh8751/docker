# KubeKey 다운로드 및 실행 권한 부여
curl -sfL https://get-kk.kubesphere.io | VERSION=v3.0.7 sh -

# 버전을 지정하지 않으면 kubernetes는 1.23.10, kubesphere는 최신버전으로 설치
./kk create cluster --with-kubernetes v1.22.17 --with-kubesphere

# 설치 확인
kubectl logs -n kubesphere-system $(kubectl get pod -n kubesphere-system -l 'app in (ks-install, ks-installer)' -o jsonpath='{.items[0].metadata.name}') -f

# 이미 구성된 cluster로부터 sample config 추출
./kk create config --from-cluster
