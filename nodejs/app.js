// express 모듈을 불러옵니다.
const express = require('express');

// app 객체를 생성합니다.
const app = express();

// json 형식의 요청 본문을 파싱할 수 있도록 미들웨어를 설정합니다.
app.use(express.json());

// / 경로에 post 요청이 들어오면
app.post('/', (req, res) => {
  // 요청 본문에 있는 json 데이터를 가져옵니다.
  const data = req.body;

  // 콘솔에 출력합니다.
  console.log(data);

  // 응답으로 성공 메시지를 보냅니다.
  res.send('Data received successfully.');

  // parameter 추출
  const queryParams = req.query;

  // User-Agent 추출
  const userAgent = req.headers['user-agent'];
  console.log('User-Agent:', userAgent);

  // 클라이언트 IP 주소 추출
  const clientIp = req.connection.remoteAddress;
  console.log('Client IP:', clientIp);

  console.log('Received request with the following parameters:');
  for (const key in queryParams) {
    console.log(`${key}: ${queryParams[key]}`);
  }

  res.send(`<pre>${JSON.stringify(queryParams, null, 2)}</pre>`
  + `<br>User-Agent: ` + userAgent
  + `<br>Client IP: ` + clientIp
  );
  
});

// 3000번 포트에서 서버를 실행합니다.
app.listen(3000, () => {
  console.log('Server is running on port 3000.');
});
