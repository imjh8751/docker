apiVersion: v1
kind: Service
metadata:
  name: kubernetesex
  namespace: default
spec:
  type: ExternalName
  externalName: kubernetes.default.svc.cluster.local
