curl -sfL https://get-kk.kubesphere.io | VERSION=v3.0.7 sh -
./kk create cluster --with-kubernetes v1.22.17 --with-kubesphere
kubectl logs -n kubesphere-system $(kubectl get pod -n kubesphere-system -l 'app in (ks-install, ks-installer)' -o jsonpath='{.items[0].metadata.name}') -f
