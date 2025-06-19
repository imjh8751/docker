### 1. Docker 이미지 빌드:
docker build -t network-tracer .

### 2. Docker 컨테이너 실행:
docker run -d -p 3000:3000 --name network-tracer network-tracer

### 3. 네트워크 권한이 필요한 경우 (더 정확한 traceroute를 위해):
docker run -d -p 3000:3000 --cap-add=NET_RAW --name network-tracer network-tracer
