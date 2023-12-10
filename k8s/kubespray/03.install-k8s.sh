ansible all -i inventory/mycluster/inventory.ini -m ping
ansible all -i inventory/mycluster/inventory.ini -m apt -a 'update_cache=yes' --become
ansible all -i inventory/mycluster/inventory.ini -a 'sudo timedatectl set-timezone Asia/Seoul' --become
ansible all -i inventory/mycluster/inventory.ini -a 'date'
ansible all -i inventory/mycluster/inventory.ini -a 'timedatectl'
ansible-playbook -i inventory/mycluster/inventory.ini -become --become-user=root cluster.yml
