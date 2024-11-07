#!/bin/bash

sed -i '/bootstrap/s/^/#/' /etc/haproxy/haproxy.cfg 
systemctl restart haproxy
echo "export KUBECONFIG=/root/installation_directory/auth/kubeconfig" >> ~/.bash_profile
export KUBECONFIG=/root/installation_directory/auth/kubeconfig
