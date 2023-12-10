# update and upgrade
sudo apt update -y && sudo apt upgrade -y

# install package
sudo apt install net-tools curl vim git samba openssh-server -y

# ssh key generate
ssh-keygen -t rsa
