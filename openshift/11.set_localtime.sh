#!/bin/bash

# 서버 목록
servers=("192.168.0.70" "192.168.0.71" "192.168.0.72" "192.168.0.73" "192.168.0.74" "192.168.0.75")

# 명령어 실행 함수
execute_command() {
    local server=$1
    ssh core@$server "sudo ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime"
}

# 각 서버에 명령어 실행
for server in "${servers[@]}"; do
    echo "Executing on $server..."
    execute_command $server
    echo "Done with $server"
done

echo "All commands executed successfully."

# install bootstrap and master
openshift-install --dir /root/installation_directory wait-for bootstrap-complete --log-level=info
