# CPU 부하 테스트
curl "http://127.0.0.1:8080/api/cpu/stress?threads=8&durationSeconds=60"

# 메모리 부하 테스트
#curl "http://127.0.0.1:8080/api/memory/stress?megabytes=100"

# OOM 발생 테스트
#curl "http://127.0.0.1:8080/api/memory/stress?causeOom=true"

# 할당된 메모리 해제
#curl "http://127.0.0.1:8080/api/memory/clear"

# 상태 확인
#curl "http://127.0.0.1:8080/health"
