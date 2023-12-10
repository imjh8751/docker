git clone https://github.com/kubernetes-sigs/kubespray.git

sudo apt install -y python3-pip
cd kubespray/
sudo pip3 install -r requirements.txt

cp -r inventory/sample inventory/mycluster
vi inventory/mycluster/inventory.ini
