const express = require('express');
const axios = require('axios');
const bodyParser = require('body-parser');
const { Chart } = require('chart.js');
const { createServer } = require('http');
const { Server } = require('socket.io');

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer);

app.use(express.static('public'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// 메인 페이지
app.get('/', (req, res) => {
  res.sendFile(__dirname + '/public/index.html');
});

// 부하 테스트 API
app.post('/start-test', async (req, res) => {
  const testConfig = req.body;
  res.json({ message: '테스트가 시작되었습니다.' });
  
  // 부하 테스트 실행
  startLoadTest(testConfig);
});

// 서버 시작
const PORT = process.env.PORT || 3000;
httpServer.listen(PORT, () => {
  console.log(`서버가 포트 ${PORT}에서 실행 중입니다.`);
});

// 부하 테스트 함수
async function startLoadTest(config) {
  const {
    url,
    headers,
    body,
    totalRequests,
    requestInterval,
    initialUsers,
    usersIncrement
  } = config;
  
  let completedRequests = 0;
  let successCount = 0;
  let failureCount = 0;
  let currentUsers = initialUsers;
  const errors = {};
  
  // 테스트 결과 통계
  const stats = {
    startTime: Date.now(),
    timestamps: [],
    tps: [],
    userCounts: [],
    successCounts: [],
    failureCounts: []
  };
  
  // 초기 상태 전송
  io.emit('testStarted', { totalRequests });
  io.emit('stats', {
    success: 0,
    failure: 0,
    currentUsers,
    progress: 0,
    errors: {}
  });
  
  // 주기적으로 요청 발송
  const intervalId = setInterval(async () => {
    // 가상 사용자 증가
    if (usersIncrement > 0) {
      currentUsers += usersIncrement;
    }
    
    // 현재 시간 기록
    const now = Date.now();
    const elapsedSeconds = (now - stats.startTime) / 1000;
    
    // 동시에 여러 요청 발송 (가상 사용자당 한 개의 요청)
    const requests = [];
    const requestStartTime = Date.now();
    
    for (let i = 0; i < currentUsers && completedRequests < totalRequests; i++) {
      requests.push(sendRequest(url, headers, body));
      completedRequests++;
    }
    
    // 모든 요청 결과 처리
    const results = await Promise.all(requests);
    
    // 결과 집계
    results.forEach(result => {
      if (result.success) {
        successCount++;
      } else {
        failureCount++;
        const errorKey = result.error.message || '알 수 없는 오류';
        errors[errorKey] = (errors[errorKey] || 0) + 1;
      }
    });
    
    // TPS 계산 (현재 주기의 초당 처리량)
    const requestEndTime = Date.now();
    const batchDurationSeconds = (requestEndTime - requestStartTime) / 1000;
    const currentTps = batchDurationSeconds > 0 ? requests.length / batchDurationSeconds : 0;
    
    // 통계 데이터 업데이트
    stats.timestamps.push(elapsedSeconds);
    stats.tps.push(currentTps);
    stats.userCounts.push(currentUsers);
    stats.successCounts.push(successCount);
    stats.failureCounts.push(failureCount);
    
    // 클라이언트에 현재 상태 전송
    io.emit('stats', {
      success: successCount,
      failure: failureCount,
      currentUsers,
      progress: Math.floor((completedRequests / totalRequests) * 100),
      errors,
      tps: currentTps,
      testData: {
        timestamps: stats.timestamps,
        tps: stats.tps,
        userCounts: stats.userCounts,
        successCounts: stats.successCounts,
        failureCounts: stats.failureCounts
      }
    });
    
    // 테스트 완료 여부 확인
    if (completedRequests >= totalRequests) {
      clearInterval(intervalId);
      io.emit('testCompleted', {
        success: successCount,
        failure: failureCount,
        errors,
        totalTime: (Date.now() - stats.startTime) / 1000,
        avgTps: successCount / ((Date.now() - stats.startTime) / 1000)
      });
    }
  }, requestInterval);
}

// 단일 HTTP 요청 함수
async function sendRequest(url, headers, body) {
  try {
    const response = await axios.post(url, body, { headers });
    return {
      success: true,
      status: response.status,
      data: response.data
    };
  } catch (error) {
    return {
      success: false,
      error: {
        message: error.message,
        status: error.response ? error.response.status : 'No response',
        data: error.response ? error.response.data : null
      }
    };
  }
}
