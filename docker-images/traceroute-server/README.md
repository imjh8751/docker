### 1. Docker 이미지 빌드:
docker build -t network-tracer .

### 2. Docker 컨테이너 실행:
docker run -d -p 3333:3333 --name network-tracer network-tracer

### 3. 네트워크 권한이 필요한 경우 (더 정확한 traceroute를 위해):
docker run -d -p 3333:3333 --cap-add=NET_RAW --name network-tracer network-tracer

### 4. 테스트:
curl -X POST http://localhost:3333/trace \
  -H "Content-Type: application/json" \
  -d '{"destination": "google.com", "port": 80}'

curl -X POST http://localhost:3333/trace \
  -H "Content-Type: application/json" \
  -d '{"destination": "google.com", "port": 80}' | jq -r '.visualization'
