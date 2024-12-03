apiVersion: v1
kind: Service
metadata:
  name: kubernetesExternal
  namespace: default
spec:
  type: ExternalName
  externalName: kubernetes.default.svc.cluster.local
