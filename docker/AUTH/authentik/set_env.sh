# docker-compose 파일 다운로드
wget https://goauthentik.io/docker-compose.yml

#암호화키 생성을 도와줄 패키지
sudo apt-get install -y pwgen

#다음 명령을 실행하여 비밀번호와 비밀 키를 생성
echo "PG_PASS=$(pwgen -s 40 1)" >> .env
echo "AUTHENTIK_SECRET_KEY=$(pwgen -s 50 1)" >> .env

#오류 보고를 사용하도록 설정하려면 다음 명령을 실행합니다.
echo "AUTHENTIK_ERROR_REPORTING__ENABLED=true" >> .env
