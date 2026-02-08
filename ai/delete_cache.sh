# 1. 디스크 기록 동기화 (데이터 보호)
sudo sync

# 2. 페이지 캐시 삭제
sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
