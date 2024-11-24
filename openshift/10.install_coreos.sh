# Proxmox 관리자 화면에서 CoreOS VM 생성하고, IP, GATEWAY,DNS 설정 후 아래 명령어 수행
# Bootstrap
# IP : 192.168.0.79
# GATEWAY : 192.168.0.1
# DNS : 192.168.0.69

# Master (Master 와 Worker 개수에 따른 IP 지정)
# IP : 192.168.0.70
# GATEWAY : 192.168.0.1
# DNS : 192.168.0.69

# Worker (Master 와 Worker 개수에 따른 IP 지정)
# IP : 192.168.0.71, 192.168.0.72
# GATEWAY : 192.168.0.1
# DNS : 192.168.0.69

# bootstrap 서버일 경우
hash=`curl http://192.168.0.69:8080/bootstrap.hash`
sudo coreos-installer install --copy-network --ignition-url http://192.168.0.69:8080/bootstrap.ign /dev/sda --ignition-hash sha512-${hash}

# master 서버일 경우
hash=`curl http://192.168.0.69:8080/master.hash`
sudo coreos-installer install --copy-network --ignition-url http://192.168.0.69:8080/master.ign /dev/sda --ignition-hash sha512-${hash}

# workder 서버일 경우
hash=`curl http://192.168.0.69:8080/worker.hash`
sudo coreos-installer install --copy-network --ignition-url http://192.168.0.69:8080/worker.ign /dev/sda --ignition-hash sha512-${hash}
