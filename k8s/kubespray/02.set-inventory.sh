# ## Configure 'ip' variable to bind kubernetes services on a
# ## different ip than the default iface
# ## We should set etcd_member_name for etcd cluster. The node that is not a etcd member do not need to set the value, or can set the empty string value.
[all]
m-k8s ansible_host=192.168.0.90  ip=192.168.0.90 etcd_member_name=etcd1
n1-k8s ansible_host=192.168.0.91  ip=192.168.0.91
n2-k8s ansible_host=192.168.0.92  ip=192.168.0.92
n3-k8s ansible_host=192.168.0.93  ip=192.168.0.93

# ## configure a bastion host if your nodes are not directly reachable
# [bastion]
# bastion ansible_host=x.x.x.x ansible_user=some_user

[kube_control_plane]
m-k8s

[etcd]
m-k8s

[kube_node]
n1-k8s
n2-k8s
n3-k8s

[calico_rr]

[k8s_cluster:children]
kube_control_plane
kube_node
calico_rr
출처: https://betwe.tistory.com/entry/Kubernetes-Kubespray-로-K8S-Cluster-구성하기 [개발과 육아사이:티스토리]
