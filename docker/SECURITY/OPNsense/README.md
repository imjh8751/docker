# OPNsense 홈서버 구축 가이드

OPNsense는 FreeBSD 기반의 오픈소스 방화벽 및 라우팅 플랫폼입니다. 이 가이드는 홈서버 환경에서 OPNsense를 설치하고 설정하는 방법을 설명합니다.

## 📋 목차

1. [시스템 요구사항](#시스템-요구사항)
2. [ISO 다운로드](#iso-다운로드)
3. [가상머신 설정](#가상머신-설정)
4. [OPNsense 설치](#opnsense-설치)
5. [초기 설정](#초기-설정)
6. [웹 GUI 접근](#웹-gui-접근)
7. [기본 설정](#기본-설정)
8. [홈서버 연동](#홈서버-연동)
9. [보안 설정](#보안-설정)
10. [문제 해결](#문제-해결)

## 🖥️ 시스템 요구사항

### 최소 요구사항
- **CPU**: 1 코어 (64비트)
- **RAM**: 1GB
- **저장소**: 8GB
- **네트워크**: 최소 2개 인터페이스 (WAN/LAN)

### 권장 요구사항
- **CPU**: 2+ 코어
- **RAM**: 2GB 이상
- **저장소**: 20GB 이상 (로그 및 패키지용)
- **네트워크**: 3개 이상 인터페이스 (WAN/LAN/DMZ)

## 📥 ISO 다운로드

제공된 다운로드 스크립트를 사용하세요:

```bash
# 스크립트 실행 권한 부여
chmod +x download_opnsense.sh

# 스크립트 실행
./download_opnsense.sh
```

### 수동 다운로드
공식 사이트에서도 다운로드 가능합니다:
- **공식 사이트**: https://opnsense.org/download/
- **미러 목록**: https://opnsense.org/download/

## 🖥️ 가상머신 설정

### VMware ESXi/vSphere

1. **새 가상머신 생성**
   ```
   이름: OPNsense-Firewall
   게스트 OS: FreeBSD 13 (64비트)
   ```

2. **하드웨어 설정**
   ```
   CPU: 2 vCPU
   메모리: 2GB
   하드디스크: 20GB (Thin Provisioning)
   네트워크 어댑터 1: WAN 네트워크
   네트워크 어댑터 2: LAN 네트워크
   CD/DVD: OPNsense ISO 마운트
   ```

### Proxmox VE

1. **VM 생성**
   ```bash
   # CLI로 VM 생성 (예시)
   qm create 100 --name opnsense --memory 2048 --cores 2 --scsihw virtio-scsi-pci
   qm set 100 --scsi0 local-lvm:20 --cdrom local:iso/OPNsense-24.1-dvd-amd64.img
   qm set 100 --net0 virtio,bridge=vmbr0,tag=10  # WAN
   qm set 100 --net1 virtio,bridge=vmbr1         # LAN
   ```

2. **웹 UI 설정**
   - CPU: 2 코어
   - 메모리: 2048MB
   - 하드디스크: 20GB
   - 네트워크: 2개 인터페이스 추가

### VirtualBox

1. **새 머신 생성**
   ```
   이름: OPNsense
   타입: BSD
   버전: FreeBSD (64-bit)
   메모리: 2048MB
   ```

2. **네트워크 설정**
   ```
   어댑터 1: NAT (WAN)
   어댑터 2: 내부 네트워크 (LAN)
   ```

## 💿 OPNsense 설치

### 1. 부팅 및 설치 시작

1. VM 전원 켜기
2. ISO에서 부팅
3. `Install (UFS)` 선택 (권장)

### 2. 설치 과정

1. **키보드 레이아웃 선택**
   ```
   기본값: United States of America ISO-8859-1
   ```

2. **파티션 설정**
   ```
   Auto (UFS) Guided Disk Setup 선택
   전체 디스크 사용
   ```

3. **루트 패스워드 설정**
   ```
   강력한 패스워드 입력 (최소 8자리)
   ```

4. **설치 완료**
   ```
   재부팅 후 ISO 제거
   ```

## ⚙️ 초기 설정

### 1. 콘솔 설정

시스템 부팅 후 콘솔 메뉴가 표시됩니다:

```
*** OPNsense.localdomain: OPNsense 24.1 ***

WAN (vtnet0)  -> v4: DHCP/192.168.1.100/24
LAN (vtnet1)  -> v4: 192.168.1.1/24

0) Logout
1) Assign interfaces
2) Set interface IP address
3) Reset the root password
4) Reset to factory defaults
5) Power off system
6) Reboot system
7) Ping host
8) Shell
9) pfTop
10) Firewall log
11) Reload all services
12) Update from console
13) Restore a backup
14) Restart web configurator
```

### 2. 인터페이스 할당

**옵션 1** 선택하여 네트워크 인터페이스 할당:

```
WAN 인터페이스: vtnet0 (또는 em0)
LAN 인터페이스: vtnet1 (또는 em1)
```

### 3. LAN IP 설정

**옵션 2** 선택하여 LAN IP 설정:

```
인터페이스: LAN (2)
IPv4 주소: 192.168.1.1
서브넷 마스크: 24
게이트웨이: 없음
DHCP 서버: Yes
DHCP 범위: 192.168.1.100 - 192.168.1.199
```

## 🌐 웹 GUI 접근

### 1. LAN에서 접근

브라우저에서 접근:
```
URL: https://192.168.1.1
사용자명: root
패스워드: (설치 시 설정한 패스워드)
```

### 2. 초기 설정 마법사

웹 GUI 첫 접근 시 설정 마법사가 실행됩니다:

1. **일반 설정**
   ```
   호스트명: opnsense
   도메인: localdomain
   기본 언어: 한국어 (선택사항)
   ```

2. **시간 서버**
   ```
   시간대: Asia/Seoul
   시간 서버: kr.pool.ntp.org
   ```

3. **WAN 설정**
   ```
   타입: DHCP (홈 네트워크의 경우)
   또는 고정 IP 설정
   ```

4. **LAN 설정**
   ```
   IP 주소: 192.168.1.1
   서브넷 마스크: 24
   ```

5. **관리자 패스워드 변경** (선택사항)

## 🔧 기본 설정

### 1. 방화벽 규칙 설정

**Firewall > Rules > LAN**에서:

```
기본 허용 규칙:
- LAN net → any (모든 트래픽 허용)
- Anti-Lockout Rule (관리 접근 보호)
```

### 2. DHCP 서버 설정

**Services > DHCPv4 > LAN**에서:

```
활성화: ✓
범위: 192.168.1.100 - 192.168.1.199
DNS 서버: 8.8.8.8, 8.8.4.4
도메인명: localdomain
리스 시간: 7200초
```

### 3. DNS 설정

**System > Settings > General**에서:

```
DNS 서버:
- 8.8.8.8 (Google DNS)
- 1.1.1.1 (Cloudflare DNS)
DNS 재정의 허용: ✓
```

## 🏠 홈서버 연동

### 1. 포트 포워딩 설정

**Firewall > NAT > Port Forward**에서 규칙 추가:

```
예시: 웹서버 포트포워딩
인터페이스: WAN
프로토콜: TCP
목적지 포트: 80
리다이렉트 대상 IP: 192.168.1.100
리다이렉트 대상 포트: 80
설명: Web Server
```

### 2. DMZ 네트워크 설정

**Interfaces > Assignments**에서 3번째 인터페이스 추가:

```
인터페이스 이름: DMZ
IPv4 설정: 192.168.2.1/24
```

### 3. VLAN 설정 (고급)

**Interfaces > Other Types > VLAN**에서:

```
상위 인터페이스: LAN
VLAN 태그: 10
설명: Server_VLAN
```

## 🔒 보안 설정

### 1. SSL 인증서 설정

**System > Trust > Authorities**에서:

```
자체 서명 인증서 생성:
이름: OPNsense-CA
키 길이: 2048 비트
다이제스트: SHA256
유효기간: 3650일
```

### 2. 접근 제한 설정

**System > Settings > Administration**에서:

```
HTTPS만 허용: ✓
웹 GUI 포트: 443
SSH 활성화: 필요시만
```

### 3. 방화벽 로깅

**Firewall > Settings > Advanced**에서:

```
로그 활성화: ✓
로그 레벨: Informational
로그 파일 크기: 50MB
```

### 4. IDS/IPS 설정 (Suricata)

**Services > Intrusion Detection**에서:

```
Suricata 설치 및 활성화
규칙 세트: ET Open 규칙
모니터링 인터페이스: WAN, LAN
```

## 📊 모니터링 설정

### 1. 시스템 모니터링

**Reporting > Health**에서 다음 항목 모니터링:
- CPU 사용률
- 메모리 사용률
- 디스크 사용률
- 네트워크 트래픽

### 2. 로그 설정

**System > Settings > Logging**에서:

```
원격 로깅: (필요시 설정)
로그 순환: 활성화
보존 기간: 30일
```

### 3. 알림 설정

**System > Settings > Notifications**에서:

```
이메일 알림 설정:
SMTP 서버: (Gmail 등)
발신자: admin@yourdomain.com
수신자: your-email@example.com
```

## 🔧 고급 설정

### 1. Load Balancer 설정

**Services > Load Balancer**에서 여러 서버 간 부하 분산:

```
가상 서버 생성:
이름: Web-LB
IP: 192.168.1.10
포트: 80
모드: HTTP
```

### 2. VPN 설정 (OpenVPN)

**VPN > OpenVPN > Servers**에서:

```
서버 모드: 원격 액세스 (SSL/TLS)
프로토콜: UDP
포트: 1194
터널 네트워크: 10.0.8.0/24
```

### 3. 캐시 프록시 (Squid)

**Services > Web Proxy**에서:

```
일반 설정:
활성화: ✓
인터페이스: LAN
포트: 3128
캐시 크기: 1GB
```

## 🔄 백업 및 복원

### 1. 설정 백업

**System > Configuration > Backups**에서:

```
백업 생성:
- 다운로드 링크 클릭
- 정기적으로 백업 수행
- 안전한 위치에 저장
```

### 2. 자동 백업 설정

**System > Configuration > Backups**에서:

```
AutoConfigBackup 플러그인 설치:
자동 백업: 활성화
백업 주기: 매주
암호화: 활성화
```

## 🛠️ 문제 해결

### 1. 웹 GUI 접근 불가

**증상**: 브라우저에서 https://192.168.1.1 접근 안됨

**해결방법**:
```bash
# 콘솔에서 확인
2) Set interface IP address
# LAN IP 주소 재설정

14) Restart web configurator
# 웹 설정 도구 재시작
```

### 2. 인터넷 연결 안됨

**증상**: LAN에서 인터넷 접근 불가

**해결방법**:
1. **System > Gateways > Single**에서 WAN 게이트웨이 확인
2. **System > Routes**에서 기본 라우트 확인
3. **Firewall > Rules > LAN**에서 허용 규칙 확인

### 3. DHCP 클라이언트 IP 할당 안됨

**해결방법**:
1. **Services > DHCPv4 > LAN**에서 DHCP 서버 활성화 확인
2. **Status > DHCP Leases**에서 임대 상태 확인
3. 클라이언트에서 IP 갱신: `ipconfig /release && ipconfig /renew`

### 4. 포트 포워딩 작동 안함

**해결방법**:
1. **Firewall > NAT > Port Forward**에서 규칙 확인
2. **Firewall > Rules > WAN**에서 자동 생성된 규칙 확인
3. 대상 서버의 방화벽 설정 확인

### 5. 성능 문제

**해결방법**:
1. **System > Settings > Tunables**에서 성능 튜닝
2. VM 리소스 증가 (CPU, RAM)
3. **Status > System**에서 시스템 부하 모니터링

## 📚 추가 자료

### 공식 문서
- [OPNsense 문서](https://docs.opnsense.org/)
- [OPNsense 위키](https://wiki.opnsense.org/)
- [커뮤니티 포럼](https://forum.opnsense.org/)

### 한국어 자료
- [OPNsense 한국 커뮤니티](https://cafe.naver.com/opnsense)
- [홈랩 커뮤니티](https://homelab.kr/)

### 유용한 플러그인
- **os-acme-client**: Let's Encrypt SSL 인증서 자동 갱신
- **os-haproxy**: 고성능 로드 밸런서
- **os-nginx**: 웹 서버 및 리버스 프록시
- **os-wireguard**: 모던 VPN 솔루션
- **os-telegraf**: 시스템 메트릭 수집

## 📋 체크리스트

### 설치 완료 체크리스트
- [ ] VM 생성 및 리소스 할당
- [ ] OPNsense ISO 다운로드
- [ ] 네트워크 인터페이스 2개 이상 설정
- [ ] OPNsense 설치 완료
- [ ] 웹 GUI 접근 확인
- [ ] 초기 설정 마법사 완료

### 기본 설정 체크리스트
- [ ] WAN 인터페이스 구성
- [ ] LAN 인터페이스 IP 설정
- [ ] DHCP 서버 활성화
- [ ] DNS 서버 설정
- [ ] 기본 방화벽 규칙 확인
- [ ] 시간대 설정

### 보안 설정 체크리스트
- [ ] 강력한 관리자 패스워드 설정
- [ ] HTTPS 전용 웹 GUI 설정
- [ ] SSH 접근 제한
- [ ] 방화벽 로깅 활성화
- [ ] 정기 백업 설정
- [ ] 업데이트 정책 수립

### 홈서버 연동 체크리스트
- [ ] 포트 포워딩 규칙 설정
- [ ] DMZ 네트워크 구성 (필요시)
- [ ] 내부 서비스 방화벽 규칙
- [ ] 모니터링 설정
- [ ] 로그 분석 환경 구축

## 🚀 성능 최적화

### 1. 하드웨어 최적화
```
CPU: 
- 가상화 지원 (VT-x/AMD-V) 활성화
- 멀티코어 할당으로 처리량 향상

메모리:
- 최소 2GB, 권장 4GB 이상
- Balloon driver 비활성화 (VMware)

스토리지:
- SSD 사용 권장
- RAID 구성으로 안정성 향상
```

### 2. 네트워크 최적화
```
네트워크 어댑터:
- VMXNET3 (VMware) 또는 VirtIO (KVM/Proxmox) 사용
- SR-IOV 지원시 활용

대역폭:
- 인터페이스별 QoS 설정
- Traffic Shaping 활용
```

### 3. 시스템 튜닝
**System > Settings > Tunables**에서:

```
# 네트워크 버퍼 크기 증가
net.inet.tcp.sendbuf_max=16777216
net.inet.tcp.recvbuf_max=16777216

# 커넥션 제한 증가
kern.maxfiles=65536
kern.maxfilesperproc=32768

# 메모리 최적화
vm.pmap.pv_entry_max=2097152
```

## 🔐 고급 보안 설정

### 1. 두 단계 인증 (2FA)
**System > Access > Tester**에서:

```
TOTP 활성화:
1. Google Authenticator 앱 설치
2. QR 코드 스캔
3. 인증 코드 입력하여 검증
```

### 2. 지리적 차단 (GeoIP)
**Firewall > Aliases > GeoIP**에서:

```
차단할 국가 선택:
- 위험 국가 IP 대역 차단
- 화이트리스트 방식 적용 권장
```

### 3. 침입 탐지 시스템 고급 설정
**Services > Intrusion Detection > Administration**에서:

```
Suricata 고급 설정:
- Custom rules 추가
- Alert threshold 조정
- 로그 분석 자동화
```

## 📊 모니터링 및 알림

### 1. Grafana 연동
```bash
# Telegraf 플러그인 설치
System > Firmware > Plugins > os-telegraf

# InfluxDB 서버 설정
Services > Telegraf > Input > System
```

### 2. 로그 분석
**Status > System Logs**에서:

```
주요 모니터링 항목:
- 인증 실패 로그
- 방화벽 차단 로그
- 시스템 오류 로그
- 네트워크 이상 로그
```

### 3. 알림 규칙 설정
**Services > Monit**에서:

```
모니터링 대상:
- CPU 사용률 > 80%
- 메모리 사용률 > 90%
- 디스크 사용률 > 85%
- 네트워크 연결 장애
```

## 🌐 VPN 서버 구축

### 1. OpenVPN 서버 설정
**VPN > OpenVPN > Servers**에서:

```
기본 설정:
서버 모드: Remote Access (SSL/TLS)
백엔드: Local Database
프로토콜: UDP4
로컬 포트: 1194
설명: HomeVPN
```

### 2. 인증서 생성
**System > Trust > Authorities**에서:

```
CA 생성:
이름: OpenVPN-CA
방법: Create an internal Certificate Authority
키 타입: RSA
키 길이: 2048
다이제스트: SHA256
국가: KR
```

### 3. 클라이언트 인증서 생성
**System > Trust > Certificates**에서:

```
클라이언트 인증서:
이름: client1
방법: Create an internal Certificate
인증서 타입: Client Certificate
```

### 4. 클라이언트 설정 파일 내보내기
**VPN > OpenVPN > Client Export**에서:

```
내보내기 옵션:
- Windows Installer
- Viscosity Bundle
- OpenVPN Config
```

## 🔄 업데이트 및 유지보수

### 1. 시스템 업데이트
**System > Firmware > Updates**에서:

```
정기 업데이트:
- 보안 업데이트: 즉시 적용
- 기능 업데이트: 테스트 후 적용
- 백업 후 업데이트 수행
```

### 2. 설정 백업 자동화
```bash
# 크론탭을 통한 자동 백업 (고급 사용자)
System > Settings > Cron

작업: 설정 백업
시간: 매주 일요일 새벽 2시
명령어: /usr/local/etc/rc.backup_config
```

### 3. 로그 관리
**System > Settings > Logging**에서:

```
로그 설정:
로그 레벨: Informational
원격 로깅: syslog 서버로 전송
로그 순환: 30일 보관
압축: 활성화
```

## 📞 지원 및 커뮤니티

### 기술 지원
```
공식 지원:
- Commercial Support: https://opnsense.org/support-overview/
- Business Edition: 전문 기술 지원 포함

커뮤니티 지원:
- Reddit: r/OPNsenseFirewall
- Discord: OPNsense Community
- Telegram: @opnsense
```

### 문제 보고
```
버그 리포트:
- GitHub Issues: https://github.com/opnsense/core/issues
- 포럼: 사용법 관련 질문
- 메일링 리스트: 개발자 논의
```

## 📝 마무리

이 가이드를 통해 OPNsense 기반의 홈서버 방화벽을 성공적으로 구축하셨기를 바랍니다. 

**중요한 보안 권고사항**:
1. 정기적인 시스템 업데이트
2. 강력한 패스워드 정책
3. 정기적인 설정 백업
4. 로그 모니터링 및 분석
5. 침입 탐지 시스템 활용

**추가 학습 권장사항**:
- pfSense와의 차이점 이해
- FreeBSD 시스템 관리 기초
- 네트워크 보안 기본 개념
- 방화벽 정책 설계 원칙

문제가 발생하거나 추가 도움이 필요한 경우, OPNsense 커뮤니티나 공식 문서를 참조하시기 바랍니다.

---

**작성일**: 2025년 9월
**버전**: OPNsense 24.1 기준
**최종 업데이트**: 2025-09-11
