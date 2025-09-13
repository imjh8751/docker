# 확인방법 
docker exec -t crowdsec cscli collections list 

# 컬렉션 (npmplus) 등이 다 적용되어있는지   
docker exec -t crowdsec cscli metrics

# ip blocked 된 목록
docker exec crowdsec cscli decisions list

# 로그파일 수집이 잘 이루어지고 있는지
#docker exec -t crowdsec cscli decision add -i x.x.x.x
#docker exec -t crowdsec cscli decision delete -i x.x.x.x

# 수동으로 차단이 잘 되고 있는지

#2. 브라우저 자동 HTTPS 리다이렉트 해제
#Chrome/Edge에서:

#주소창에 chrome://net-internals/#hsts 입력
#"Delete domain security policies"에서 해당 도메인/IP 삭제
#또는 시크릿 모드에서 접속 시도
