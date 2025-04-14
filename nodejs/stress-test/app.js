const express = require('express');
const http = require('http');
const https = require('https');
const path = require('path');
const { URL } = require('url');
const socketIo = require('socket.io');
const os = require('os'); // CPU/메모리 정보를 위한 모듈 추가

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
  
  if (!socketId) {
    return res.status(400).json({ error: 'Socket ID is required' });
  }
  
  // 이미 진행 중인 테스트가 있다면 중지
  if (activeTests.has(socketId)) {
    const { testIntervalId, statsIntervalId, systemMonitorId } = activeTests.get(socketId);
    if (testIntervalId) clearInterval(testIntervalId);
    if (statsIntervalId) clearInterval(statsIntervalId);
    if (systemMonitorId) clearInterval(systemMonitorId);
    activeTests.delete(socketId);
  }

  // 응답을 즉시 보내고 백그라운드에서 테스트 실행
  res.json({ message: 'Test started' });

  // 테스트 시작
  runLoadTest(socketId, url, method, headers, body, requestCount, testDuration, 
    requestInterval, initialUsers, userIncrement);
});

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
      const { testIntervalId, statsIntervalId, systemMonitorId } = activeTests.get(socket.id);
      
      // 인터벌 클리어
      if (testIntervalId) clearInterval(testIntervalId);
      if (statsIntervalId) clearInterval(statsIntervalId);
      if (systemMonitorId) clearInterval(systemMonitorId);
      
      // 활성 테스트에서 제거
      activeTests.delete(socket.id);
      
      // 클라이언트에 테스트 중지 통보 (해당 클라이언트에게만)
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
      const { testIntervalId, statsIntervalId, systemMonitorId } = activeTests.get(socket.id);
      
      if (testIntervalId) clearInterval(testIntervalId);
      if (statsIntervalId) clearInterval(statsIntervalId);
      if (systemMonitorId) clearInterval(systemMonitorId);
      
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

let prevIdle = 0;
let prevTotal = 0;

// 시스템 리소스 사용량 측정 함수
function getSystemStats() {
  // CPU 사용량 계산 (%)
  const cpus = os.cpus();
  let totalIdle = 0;
  let totalTick = 0;
  
  for (const cpu of cpus) {
    for (const type in cpu.times) {
      totalTick += cpu.times[type];
    }
    totalIdle += cpu.times.idle;
  }

  const idleDiff = totalIdle - prevIdle;
  const totalDiff = totalTick - prevTotal;
  const cpuUsage = totalDiff > 0 ? parseFloat((1 - idleDiff / totalDiff) * 100).toFixed(2) : 0;

  prevIdle = totalIdle;
  prevTotal = totalTick;
  
  // 전체 시스템 메모리와 사용 가능한 메모리 (MB)
  const totalMem = os.totalmem() / (1024 * 1024);
  const freeMem = os.freemem() / (1024 * 1024);
  const usedMem = totalMem - freeMem;
  const memoryUsage = (usedMem / totalMem) * 100;  
  
  // 현재 프로세스의 메모리 사용량 (MB)
  const processMemory = process.memoryUsage();
  const rss = processMemory.rss / (1024 * 1024);
  
  return {
    cpuCount: cpus.length,
    cpuUsage: parseFloat(cpuUsage),
    totalMemory: parseFloat(totalMem.toFixed(2)),
    usedMemory: parseFloat(usedMem.toFixed(2)),
    memoryUsage: parseFloat(memoryUsage.toFixed(2)),
    processMemory: parseFloat(rss.toFixed(2))
  };
}

// 부하 테스트 실행 함수 (socketId 매개변수 추가)
// runLoadTest 함수를 수정 - server.js 파일에서 이 함수를 찾아 교체하세요
function runLoadTest(socketId, url, method, headers, body, requestCount, testDuration, 
  requestInterval, initialUsers, userIncrement) {
  
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
    failRateHistory: [],
    cpuHistory: [],
    memoryHistory: [],
    pendingRequests: new Map() // 진행 중인 요청을 추적하기 위한 맵
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

  // 시스템 리소스 모니터링 (2초 간격)
  const systemMonitorId = setInterval(() => {
    const systemStats = getSystemStats();
    const totalElapsedTime = (Date.now() - stats.startTime) / 1000;
    
    stats.cpuHistory.push({
      time: totalElapsedTime,
      value: systemStats.cpuUsage
    });
    
    stats.memoryHistory.push({
      time: totalElapsedTime,
      value: systemStats.memoryUsage
    });
    
    // 해당 클라이언트에게만 시스템 상태 전송
    io.to(socketId).emit('systemStats', systemStats);
  }, 2000);

  // 실시간 통계 업데이트 간격 (1초)
  const statsIntervalId = setInterval(() => {
    updateStats(socketId, stats);
    
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
      clearInterval(systemMonitorId);
      
      // 활성 테스트에서 제거 (대기 중인 요청이 모두 처리될 때까지 기다림)
      if (!testFinished) {
        testFinished = true;
        finalizeTest(socketId, stats);
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
      
      sendRequest(socketId, options, isHttps, postData, stats);
    }
    
    // 사용자 수 증가
    stats.activeUsers += userIncrement;
  }, requestInterval);
  
  // 인터벌 ID를 저장하여 나중에 중지할 수 있도록 함
  activeTests.set(socketId, { testIntervalId, statsIntervalId, systemMonitorId });
}

// HTTP 요청 보내기 (socketId 매개변수 추가)
// sendRequest 함수를 수정 - server.js 파일에서 이 함수를 찾아 교체하세요
function sendRequest(socketId, options, isHttps, postData, stats) {
  const startTime = Date.now();
  stats.totalRequests++;
  
  // 진행 중인 요청 추적을 위해 요청 ID 생성
  const requestId = `req_${Date.now()}_${Math.random().toString(36).substring(2, 15)}`;
  
  // 진행 중인 요청 추적
  if (!stats.pendingRequests) stats.pendingRequests = new Map();
  stats.pendingRequests.set(requestId, startTime);
  
  const requester = isHttps ? https : http;
  
  // 타임아웃 옵션 추가 (60초)
  const requestOptions = {...options, timeout: 60000};
  
  const req = requester.request(requestOptions, (res) => {
    let responseData = '';
    
    res.on('data', (chunk) => {
      responseData += chunk;
    });
    
    res.on('end', () => {
      const endTime = Date.now();
      const responseTime = endTime - startTime;
      stats.responseTimes.push(responseTime);
      
      // 완료된 요청 추적에서 제거
      if (stats.pendingRequests) stats.pendingRequests.delete(requestId);
      
      if (res.statusCode >= 200 && res.statusCode < 400) {
        stats.successCount++;
      } else {
        stats.failCount++;
        const errorKey = `Status ${res.statusCode}`;
        stats.errors[errorKey] = (stats.errors[errorKey] || 0) + 1;
        
        // 실패 정보 전송 (해당 클라이언트에게만)
        io.to(socketId).emit('error', {
          statusCode: res.statusCode,
          time: new Date().toISOString(),
          responseTime,
          message: `HTTP Status: ${res.statusCode}`
        });
      }
    });
  });
  
  // 타임아웃 이벤트 핸들러 추가
  req.on('timeout', () => {
    req.abort();
    const endTime = Date.now();
    const responseTime = endTime - startTime;
    stats.responseTimes.push(responseTime);
    stats.failCount++;
    
    // 완료된 요청 추적에서 제거
    if (stats.pendingRequests) stats.pendingRequests.delete(requestId);
    
    const errorKey = 'Request Timeout';
    stats.errors[errorKey] = (stats.errors[errorKey] || 0) + 1;
    
    io.to(socketId).emit('error', {
      code: 'TIMEOUT',
      time: new Date().toISOString(),
      responseTime,
      message: '요청 타임아웃 (60초)'
    });
  });
  
  req.on('error', (error) => {
    const endTime = Date.now();
    const responseTime = endTime - startTime;
    stats.responseTimes.push(responseTime);
    stats.failCount++;
    
    // 완료된 요청 추적에서 제거
    if (stats.pendingRequests) stats.pendingRequests.delete(requestId);
    
    const errorKey = error.code || 'Unknown Error';
    stats.errors[errorKey] = (stats.errors[errorKey] || 0) + 1;
    
    // 실패 정보 전송 (해당 클라이언트에게만)
    io.to(socketId).emit('error', {
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
  
  // 요청 객체와 시작 시간 반환 (테스트 종료 시 처리를 위해)
  return { req, startTime, requestId };
}

// 통계 업데이트 및 클라이언트에 전송 (socketId 매개변수 추가)
function updateStats(socketId, stats) {
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
  
  // 클라이언트에 데이터 전송 (해당 클라이언트에게만)
  io.to(socketId).emit('stats', {
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
    cpuHistory: stats.cpuHistory,
    memoryHistory: stats.memoryHistory,
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

// 테스트 완료 후 최종 보고 (socketId 매개변수 추가)
function finalizeTest(socketId, stats) {
  const testDuration = (Date.now() - stats.startTime) / 1000; // 초 단위
  
  // 대기 중인 요청이 있는지 확인
  const pendingRequestsCount = stats.pendingRequests ? stats.pendingRequests.size : 0;
  
  if (pendingRequestsCount > 0) {
    // 대기 중인 요청이 있음을 알림
    io.to(socketId).emit('pendingRequests', {
      count: pendingRequestsCount,
      message: `${pendingRequestsCount}개의 요청이 아직 진행 중입니다. 모든 요청이 완료될 때까지 기다립니다...`
    });
    
    // 모든 요청이 완료될 때까지 주기적으로 확인
    const pendingCheckInterval = setInterval(() => {
      if (!stats.pendingRequests || stats.pendingRequests.size === 0) {
        clearInterval(pendingCheckInterval);
        sendFinalStats(socketId, stats);
      } else {
        // 아직 진행 중인 요청 수 알림
        io.to(socketId).emit('pendingRequests', {
          count: stats.pendingRequests.size,
          message: `${stats.pendingRequests.size}개의 요청이 아직 진행 중입니다...`
        });
      }
    }, 1000);
  } else {
    // 대기 중인 요청이 없으면 바로 결과 전송
    sendFinalStats(socketId, stats);
  }
}

// 최종 통계 전송 함수 (새 함수)
function sendFinalStats(socketId, stats) {
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
    failRateHistory: stats.failRateHistory,
    cpuHistory: stats.cpuHistory,
    memoryHistory: stats.memoryHistory
  };
  
  // 해당 클라이언트에게만 최종 결과 전송
  io.to(socketId).emit('testComplete', finalStats);
}
