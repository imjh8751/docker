# bootstrap 서버일 경우
hash=`curl http://192.168.0.69:8080/bootstrap.hash`
sudo coreos-installer install --copy-network --ignition-url http://192.168.0.69:8080/bootstrap.ign /dev/sda --ignition-hash sha512-${hash}

# master 서버일 경우
hash=`curl http://192.168.0.69:8080/master.hash`
sudo coreos-installer install --copy-network --ignition-url http://192.168.0.69:8080/master.ign /dev/sda --ignition-hash sha512-${hash}

# workder 서버일 경우
hash=`curl http://192.168.0.69:8080/worker.hash`
sudo coreos-installer install --copy-network --ignition-url http://192.168.0.69:8080/worker.ign /dev/sda --ignition-hash sha512-${hash}
