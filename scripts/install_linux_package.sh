# update and upgrade
sudo yum update -y && sudo apt upgrade -y

# install package
sudo yum install net-tools curl vim git samba openssh-server python3-pip wget tar rsync nc podman cloud-init tcpdump psmisc bind-utils epel-release qemu-guest-agent -y

# firewalld disable
systemctl disable firewalld

# qemu-guest-agent up
systemctl enable qemu-guest-agent
 
# selinux disable
# vim /etc/selinux/config
# SELINUX=disabled

yum update -y

# ssh key generate
ssh-keygen -t rsa
