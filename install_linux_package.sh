# update and upgrade
sudo yum update -y && sudo apt upgrade -y

# install package
sudo yum install net-tools curl vim git samba openssh-server python3-pip wget tar rsync nc podman cloud-init -y

# ssh key generate
ssh-keygen -t rsa
