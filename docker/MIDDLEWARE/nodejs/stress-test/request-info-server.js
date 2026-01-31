const express = require('express');
const bodyParser = require('body-parser');
const morgan = require('morgan'); // HTTP 요청 로깅을 위한 미들웨어

const app = express();
const PORT = process.env.PORT || 3001; // 기존 서버와 다른 포트 사용

// 미들웨어 설정
app.use(morgan('dev')); // 로깅 미들웨어
app.use(bodyParser.json()); // JSON 요청 바디 파싱
app.use(bodyParser.urlencoded({ extended: true })); // URL 인코딩된 요청 바디 파싱
app.use(express.static('public')); // 정적 파일 제공

// 루트 경로 핸들러
app.get('/', (req, res) => {
  res.sendFile(__dirname + '/public/request-info.html');
});

// 모든 HTTP 메서드와 경로에 대한 요청 정보 출력 핸들러
app.all('*', (req, res) => {
  // 요청 정보 수집
  const requestInfo = {
    timestamp: new Date().toISOString(),
    method: req.method,
    url: req.url,
    path: req.path,
    params: req.params,
    query: req.query,
    headers: req.headers,
    ip: req.ip,
    body: req.body,
    cookies: req.cookies || {},
    protocol: req.protocol,
    secure: req.secure,
    xhr: req.xhr,
  };
  
  // 요청 정보를 콘솔에 출력
  console.log('\n===== 새로운 요청 정보 =====');
  console.log('시간:', requestInfo.timestamp);
  console.log('메서드:', requestInfo.method);
  console.log('URL:', requestInfo.url);
  console.log('IP 주소:', requestInfo.ip);
  console.log('헤더:', JSON.stringify(requestInfo.headers, null, 2));
  console.log('요청 바디:', JSON.stringify(requestInfo.body, null, 2));
  console.log('쿼리 파라미터:', JSON.stringify(requestInfo.query, null, 2));
  console.log('============================\n');
  
  // 클라이언트에 요청 정보 응답
  res.json({
    message: '요청 정보가 성공적으로 기록되었습니다',
    requestInfo
  });
});

// 서버 시작
app.listen(PORT, () => {
  console.log(`요청 정보 출력 서버가 포트 ${PORT}에서 실행 중입니다.`);
  console.log(`접속 URL: http://localhost:${PORT}`);
});
