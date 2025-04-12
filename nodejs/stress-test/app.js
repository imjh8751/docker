const express = require('express');
const http = require('http');
const https = require('https');
const path = require('path');
const { URL } = require('url');
const socketIo = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

app.use(express.static(path.join(__dirname, 'public')));
app.use(express.json());

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// 부하 테스트 API 엔드포인트
app.post('/start-test', (req, res) => {
  // 요청 바디에서 테스트 설정을 가져옴
  const { url, method, headers, body, requestCount, testDuration, 
    requestInterval, initialUsers, userIncrement } = req.body;

  // 요청한 소켓 ID 조회 (요청 헤더에서 소켓 ID를 전달받음)
  const socketId = req.headers['socket-id'];
  
  // 이미 진행 중인 테스트가 있다면 중지
  if (socketId && activeTests.has(socketId)) {
    const { testIntervalId, statsIntervalId } = activeTests.get(socketId);
    if (testIntervalId) clearInterval(testIntervalId);
    if (statsIntervalId) clearInterval(statsIntervalId);
    activeTests.delete(socketId);
  }

  // 응답을 즉시 보내고 백그라운드에서 테스트 실행
  res.json({ message: 'Test started' });

  // 테스트 시작
  runLoadTest(url, method, headers, body, requestCount, testDuration, 
    requestInterval, initialUsers, userIncrement);
});

// 이 코드는 app.js 파일의 기존 코드에 추가해야 할 부분입니다
// 아래 코드를 app.js의 서버 시작 코드 앞에 추가하세요 (server.listen 위에)

// 활성 테스트 상태 관리
let activeTests = new Map(); // 테스트 ID와 관련된 인터벌 ID들을 저장

// 소켓 연결 처리
io.on('connection', (socket) => {
  console.log('New client connected:', socket.id);
  
  // 테스트 중지 이벤트 처리
  socket.on('stopTest', () => {
    console.log('Stop test requested by client:', socket.id);
    
    // 해당 소켓 ID와 연결된 테스트를 중지
    if (activeTests.has(socket.id)) {
      const { testIntervalId, statsIntervalId } = activeTests.get(socket.id);
      
      // 인터벌 클리어
      if (testIntervalId) clearInterval(testIntervalId);
      if (statsIntervalId) clearInterval(statsIntervalId);
      
      // 활성 테스트에서 제거
      activeTests.delete(socket.id);
      
      // 클라이언트에 테스트 중지 통보
      socket.emit('testStopped', {
        message: 'Test was stopped by user request'
      });
      
      console.log('Test stopped for client:', socket.id);
    }
  });
  
  // 연결 종료 처리
  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
    
    // 연결이 끊긴 클라이언트의 테스트 정리
    if (activeTests.has(socket.id)) {
      const { testIntervalId, statsIntervalId } = activeTests.get(socket.id);
      
      if (testIntervalId) clearInterval(testIntervalId);
      if (statsIntervalId) clearInterval(statsIntervalId);
      
      activeTests.delete(socket.id);
      console.log('Test resources cleared for disconnected client:', socket.id);
    }
  });
});

// 서버 시작
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

// 부하 테스트 실행 함수
function runLoadTest(url, method, headers, body, requestCount, testDuration, 
  requestInterval, initialUsers, userIncrement) {
  
  // 소켓 ID 추출 (어떤 클라이언트가 요청했는지 확인하기 위함)
  const socketId = io.sockets.sockets.keys().next().value;
  
  // 테스트 결과 통계
  const stats = {
    totalRequests: 0,
    successCount: 0,
    failCount: 0,
    responseTimes: [],
    errors: {},
    startTime: Date.now(),
    lastReportTime: Date.now(),
    activeUsers: initialUsers,
    tpsHistory: [],
    responseTimeHistory: [],
    userCountHistory: [],
    successRateHistory: [],
    failRateHistory: []
  };

  // URL 파싱
  const parsedUrl = new URL(url);
  const isHttps = parsedUrl.protocol === 'https:';
  const options = {
    hostname: parsedUrl.hostname,
    port: parsedUrl.port || (isHttps ? 443 : 80),
    path: parsedUrl.pathname + parsedUrl.search,
    method: method,
    headers: headers
  };

  // JSON 문자열화
  const postData = typeof body === 'string' ? body : JSON.stringify(body);
  if (method !== 'GET' && method !== 'HEAD') {
    options.headers['Content-Length'] = Buffer.byteLength(postData);
  }

  let testFinished = false;
  
  // 테스트 종료 시간 계산
  const endTime = testDuration ? Date.now() + (testDuration * 1000) : null;

  // 실시간 통계 업데이트 간격 (1초)
  const statsIntervalId = setInterval(() => {
    updateStats(stats);
    
    // 테스트 종료 조건 확인
    if ((requestCount && stats.totalRequests >= requestCount) || 
        (endTime && Date.now() >= endTime)) {
      
      // 테스트 인터벌 클리어
      if (activeTests.has(socketId)) {
        const { testIntervalId } = activeTests.get(socketId);
        if (testIntervalId) clearInterval(testIntervalId);
      }
      
      // 통계 인터벌도 클리어 (자기 자신)
      clearInterval(statsIntervalId);
      
      // 활성 테스트에서 제거
      if (activeTests.has(socketId)) {
        activeTests.delete(socketId);
      }
      
      if (!testFinished) {
        testFinished = true;
        finalizeTest(stats);
      }
    }
  }, 1000);

  // 주기적인 요청 전송
  const testIntervalId = setInterval(() => {
    // 현재 활성 사용자 수만큼 요청 보내기
    for (let i = 0; i < stats.activeUsers; i++) {
      if ((requestCount && stats.totalRequests >= requestCount) || 
          (endTime && Date.now() >= endTime)) {
        clearInterval(testIntervalId);
        break;
      }
      
      sendRequest(options, isHttps, postData, stats);
    }
    
    // 사용자 수 증가
    stats.activeUsers += userIncrement;
  }, requestInterval);
  
  // 인터벌 ID를 저장하여 나중에 중지할 수 있도록 함
  activeTests.set(socketId, { testIntervalId, statsIntervalId });
}

// HTTP 요청 보내기
function sendRequest(options, isHttps, postData, stats) {
  const startTime = Date.now();
  stats.totalRequests++;
  
  const requester = isHttps ? https : http;
  const req = requester.request(options, (res) => {
    let responseData = '';
    
    res.on('data', (chunk) => {
      responseData += chunk;
    });
    
    res.on('end', () => {
      const endTime = Date.now();
      const responseTime = endTime - startTime;
      stats.responseTimes.push(responseTime);
      
      if (res.statusCode >= 200 && res.statusCode < 400) {
        stats.successCount++;
      } else {
        stats.failCount++;
        const errorKey = `Status ${res.statusCode}`;
        stats.errors[errorKey] = (stats.errors[errorKey] || 0) + 1;
        
        // 실패 정보 전송
        io.emit('error', {
          statusCode: res.statusCode,
          time: new Date().toISOString(),
          responseTime,
          message: `HTTP Status: ${res.statusCode}`
        });
      }
    });
  });
  
  req.on('error', (error) => {
    const endTime = Date.now();
    const responseTime = endTime - startTime;
    stats.responseTimes.push(responseTime);
    stats.failCount++;
    
    const errorKey = error.code || 'Unknown Error';
    stats.errors[errorKey] = (stats.errors[errorKey] || 0) + 1;
    
    // 실패 정보 전송
    io.emit('error', {
      code: error.code,
      time: new Date().toISOString(),
      responseTime,
      message: error.message
    });
  });
  
  if (options.method !== 'GET' && options.method !== 'HEAD' && postData) {
    req.write(postData);
  }
  
  req.end();
}

// 통계 업데이트 및 클라이언트에 전송
function updateStats(stats) {
  const now = Date.now();
  const elapsedTime = (now - stats.lastReportTime) / 1000; // 초 단위
  const totalElapsedTime = (now - stats.startTime) / 1000; // 초 단위
  
  // TPS 계산
  const newRequests = stats.totalRequests - (stats.tpsHistory.length > 0 ? 
    stats.tpsHistory[stats.tpsHistory.length - 1].totalRequests : 0);
  const tps = newRequests / elapsedTime;
  
  // 평균 응답 시간 계산
  const avgResponseTime = stats.responseTimes.length > 0 ? 
    stats.responseTimes.reduce((sum, time) => sum + time, 0) / stats.responseTimes.length : 0;
  
  // 성공률/실패율 계산
  const successRate = stats.totalRequests > 0 ? (stats.successCount / stats.totalRequests) * 100 : 0;
  const failRate = stats.totalRequests > 0 ? (stats.failCount / stats.totalRequests) * 100 : 0;
  
  // 히스토리 데이터 추가
  stats.tpsHistory.push({ 
    time: totalElapsedTime, 
    value: tps, 
    totalRequests: stats.totalRequests 
  });
  stats.responseTimeHistory.push({ 
    time: totalElapsedTime, 
    value: avgResponseTime 
  });
  stats.userCountHistory.push({ 
    time: totalElapsedTime, 
    value: stats.activeUsers 
  });
  stats.successRateHistory.push({ 
    time: totalElapsedTime, 
    value: successRate 
  });
  stats.failRateHistory.push({ 
    time: totalElapsedTime, 
    value: failRate 
  });
  
  // 클라이언트에 데이터 전송
  io.emit('stats', {
    totalRequests: stats.totalRequests,
    successCount: stats.successCount,
    failCount: stats.failCount,
    tps,
    avgResponseTime,
    activeUsers: stats.activeUsers,
    successRate,
    failRate,
    tpsHistory: stats.tpsHistory,
    responseTimeHistory: stats.responseTimeHistory,
    userCountHistory: stats.userCountHistory,
    successRateHistory: stats.successRateHistory,
    failRateHistory: stats.failRateHistory,
    errors: stats.errors,
    elapsedTime: totalElapsedTime
  });
  
  stats.lastReportTime = now;
  
  // 메모리 최적화: 너무 많은 히스토리 데이터가 쌓이지 않도록 관리
  if (stats.responseTimes.length > 1000) {
    // 마지막 100개 데이터만 유지
    stats.responseTimes = stats.responseTimes.slice(-100);
  }
}

// 테스트 완료 후 최종 보고
function finalizeTest(stats) {
  const testDuration = (Date.now() - stats.startTime) / 1000; // 초 단위
  
  const finalStats = {
    totalRequests: stats.totalRequests,
    successCount: stats.successCount,
    failCount: stats.failCount,
    avgTps: stats.totalRequests / testDuration,
    avgResponseTime: stats.responseTimes.length > 0 ? 
      stats.responseTimes.reduce((sum, time) => sum + time, 0) / stats.responseTimes.length : 0,
    successRate: stats.totalRequests > 0 ? (stats.successCount / stats.totalRequests) * 100 : 0,
    failRate: stats.totalRequests > 0 ? (stats.failCount / stats.totalRequests) * 100 : 0,
    testDuration,
    errors: stats.errors,
    tpsHistory: stats.tpsHistory,
    responseTimeHistory: stats.responseTimeHistory,
    userCountHistory: stats.userCountHistory,
    successRateHistory: stats.successRateHistory,
    failRateHistory: stats.failRateHistory
  };
  
  io.emit('testComplete', finalStats);
}
