각 VM 콘솔에서 실행 (복붙/타이핑)
이제 Proxmox에서 각 VM의 콘솔 창을 열고, 아래 명령어 한 줄만 입력하시면 모든 설치가 자동으로 끝납니다.

⚠️ 주의 (매우 중요): > curl 명령어를 통해 Bastion 서버(192.168.0.69)에서 스크립트를 다운로드하려면, VM 부팅 직후 임시로라도 IP가 있어야 통신이 가능합니다.

만약 사내망에 DHCP 서버가 있어서 VM이 임시 IP를 받은 상태라면 아래 명령어가 바로 동작합니다.

만약 DHCP가 아예 없는 망이라면, curl 자체가 실패하므로 이전 답변처럼 sudo ip a add 192.168.0.70/24 dev ens18 && 처럼 임시 IP를 먼저 주고 curl을 실행하셔야 합니다.

(DHCP 등으로 통신이 가능한 상태일 때의 명령어)

Bootstrap 콘솔:
curl -s http://192.168.0.69:8080/bootstrap.sh | bash

Master01 콘솔:
curl -s http://192.168.0.69:8080/master01.sh | bash

Worker01 콘솔:
curl -s http://192.168.0.69:8080/worker01.sh | bash

Worker02 콘솔:
curl -s http://192.168.0.69:8080/worker02.sh | bash

이 스크립트를 사용하시면 coreos-installer의 --copy-network 옵션이 "Wired connection 1" 프로필을 그대로 디스크로 복사하기 때문에, 설치 후 재부팅하면 정적 IP가 완벽하게 유지된 상태로 부팅됩니다.