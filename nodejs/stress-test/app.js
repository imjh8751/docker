<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>HTTP 부하 테스트 도구</title>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.0/css/bootstrap.min.css" rel="stylesheet">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/socket.io/4.5.1/socket.io.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js"></script>
  <style>
    .json-editor {
      font-family: monospace;
      height: 150px;
      width: 100%;
    }
    .chart-container {
      height: 300px;
      margin-bottom: 20px;
    }
    .error-log {
      max-height: 200px;
      overflow-y: auto;
    }
    .card {
      margin-bottom: 20px;
    }
    .stats-card {
      text-align: center;
      font-weight: bold;
    }
  </style>
</head>
<body>
  <div class="container-fluid mt-3">
    <h1 class="text-center mb-4">HTTP 부하 테스트 도구</h1>
    
    <div class="row">
      <!-- 왼쪽 설정 패널 -->
      <div class="col-md-4">
        <div class="card">
          <div class="card-header">테스트 설정</div>
          <div class="card-body">
            <form id="test-form">
              <div class="mb-3">
                <label for="url" class="form-label">URL</label>
                <input type="text" class="form-control" id="url" required>
              </div>
              
              <div class="mb-3">
                <label for="method" class="form-label">HTTP 메소드</label>
                <select class="form-select" id="method">
                  <option value="GET">GET</option>
                  <option value="POST" selected>POST</option>
                  <option value="PUT">PUT</option>
                  <option value="DELETE">DELETE</option>
                  <option value="PATCH">PATCH</option>
                </select>
              </div>
              
              <div class="mb-3">
                <label for="headers" class="form-label">HTTP 헤더 (JSON)</label>
                <textarea class="json-editor form-control" id="headers">{
  "Content-Type": "application/json",
  "context": "val1",
  "text1": "val2"
}</textarea>
              </div>
              
              <div class="mb-3">
                <label for="body" class="form-label">HTTP 바디 (JSON)</label>
                <textarea class="json-editor form-control" id="body">{
  "test": {
    "key": "val"
  },
  "last": "aaa"
}</textarea>
              </div>
              
              <div class="mb-3">
                <label class="form-label">테스트 종료 조건</label>
                <div class="form-check">
                  <input class="form-check-input" type="radio" name="endCondition" id="requestCount" checked>
                  <label class="form-check-label" for="requestCount">총 요청 개수</label>
                </div>
                <div class="form-check">
                  <input class="form-check-input" type="radio" name="endCondition" id="testDuration">
                  <label class="form-check-label" for="testDuration">테스트 시간 (초)</label>
                </div>
              </div>
              
              <div class="mb-3" id="requestCountInput">
                <label for="count" class="form-label">총 요청 개수</label>
                <input type="number" class="form-control" id="count" value="100" min="1">
              </div>
              
              <div class="mb-3" id="testDurationInput" style="display: none;">
                <label for="duration" class="form-label">테스트 시간 (초)</label>
                <input type="number" class="form-control" id="duration" value="60" min="1">
              </div>
              
              <div class="mb-3">
                <label for="interval" class="form-label">요청 주기 (밀리초)</label>
                <input type="number" class="form-control" id="interval" value="1000" min="10">
              </div>
              
              <div class="mb-3">
                <label for="users" class="form-label">초기 가상 유저 수</label>
                <input type="number" class="form-control" id="users" value="1" min="1">
              </div>
              
              <div class="mb-3">
                <label for="increment" class="form-label">요청 주기당 가상 유저 증가 수</label>
                <input type="number" class="form-control" id="increment" value="0" min="0">
              </div>
              
              <button type="submit" class="btn btn-primary" id="start-test">테스트 시작</button>
              <button type="button" class="btn btn-danger" id="stop-test" disabled>테스트 중지</button>
            </form>
          </div>
        </div>
      </div>
      
      <!-- 오른쪽 결과 패널 -->
      <div class="col-md-8">
        <!-- 요약 통계 -->		
		<div class="row">
          <div class="col-md-3">
            <div class="card stats-card">
              <div class="card-body">
                <h5>총 요청</h5>
                <div id="total-requests" class="display-6">0</div>
              </div>
            </div>
          </div>
          <div class="col-md-3">
            <div class="card stats-card">
              <div class="card-body bg-success text-white">
                <h5>성공</h5>
                <div id="success-count" class="display-6">0</div>
              </div>
            </div>
          </div>
          <div class="col-md-3">
            <div class="card stats-card">
              <div class="card-body bg-danger text-white">
                <h5>실패</h5>
                <div id="fail-count" class="display-6">0</div>
              </div>
            </div>
          </div>
          <div class="col-md-3">
            <div class="card stats-card">
              <div class="card-body bg-info text-white">
                <h5>TPS</h5>
                <div id="tps" class="display-6">0</div>
              </div>
            </div>
          </div>
        </div>

        <!-- 새로운 시스템 리소스 사용률 카드 추가 -->
        <div class="row mt-3">
          <div class="col-md-6">
            <div class="card stats-card">
              <div class="card-body bg-warning">
                <h5>CPU 사용률</h5>
                <div id="cpu-usage" class="display-6">0%</div>
              </div>
            </div>
          </div>
          <div class="col-md-6">
            <div class="card stats-card">
              <div class="card-body bg-secondary text-white">
                <h5>메모리 사용률</h5>
                <div id="memory-usage" class="display-6">0%</div>
              </div>
            </div>
          </div>
        </div>
        
        <!-- 테스트 진행 상황 -->
        <div class="card">
          <div class="card-header">테스트 상태</div>
          <div class="card-body">
            <div class="progress mb-3">
              <div id="test-progress" class="progress-bar" role="progressbar" style="width: 0%"></div>
            </div>
            <div class="row">
              <div class="col-md-4">
                <p><strong>경과 시간:</strong> <span id="elapsed-time">0</span>초</p>
              </div>
              <div class="col-md-4">
                <p><strong>평균 응답 시간:</strong> <span id="avg-response-time">0</span>ms</p>
              </div>
              <div class="col-md-4">
                <p><strong>현재 가상 유저:</strong> <span id="active-users">0</span></p>
              </div>
            </div>
          </div>
        </div>
        
        <!-- 차트 -->
        <div class="row">
          <div class="col-md-6">
            <div class="card">
              <div class="card-header">TPS 추이</div>
              <div class="card-body chart-container">
                <canvas id="tps-chart"></canvas>
              </div>
            </div>
          </div>
          <div class="col-md-6">
            <div class="card">
              <div class="card-header">응답 시간 추이</div>
              <div class="card-body chart-container">
                <canvas id="response-time-chart"></canvas>
              </div>
            </div>
          </div>
        </div>
        
        <div class="row">
          <div class="col-md-6">
            <div class="card">
              <div class="card-header">가상 유저 추이</div>
              <div class="card-body chart-container">
                <canvas id="user-chart"></canvas>
              </div>
            </div>
          </div>
          <div class="col-md-6">
            <div class="card">
              <div class="card-header">성공/실패율 추이</div>
              <div class="card-body chart-container">
                <canvas id="rate-chart"></canvas>
              </div>
            </div>
          </div>
        </div>
		
		<!-- 이 코드를 기존 차트 섹션 아래에 추가 -->
        <div class="row">
          <div class="col-md-6">
            <div class="card">
              <div class="card-header">CPU 사용률 추이</div>
              <div class="card-body chart-container">
                <canvas id="cpu-chart"></canvas>
              </div>
            </div>
          </div>
          <div class="col-md-6">
            <div class="card">
              <div class="card-header">메모리 사용률 추이</div>
              <div class="card-body chart-container">
                <canvas id="memory-chart"></canvas>
              </div>
            </div>
          </div>
        </div>
        
        <!-- 오류 로그 -->
        <div class="card">
          <div class="card-header">오류 로그</div>
          <div class="card-body">
            <div class="mb-3">
              <h5>오류 요약</h5>
              <div id="error-summary"></div>
            </div>
            <h5>상세 오류</h5>
            <div class="error-log" id="error-log"></div>
          </div>
        </div>
      </div>
    </div>
  </div>
  
  <script>
    document.addEventListener('DOMContentLoaded', function() {
      // 소켓 연결
      const socket = io();
      
      // 차트 설정
      const charts = {
        tps: new Chart(document.getElementById('tps-chart').getContext('2d'), {
          type: 'line',
          data: {
            labels: [],
            datasets: [{
              label: 'TPS',
              data: [],
              borderColor: 'rgba(54, 162, 235, 1)',
              backgroundColor: 'rgba(54, 162, 235, 0.1)',
              borderWidth: 2,
              fill: true,
              tension: 0.2
            }]
          },
          options: {
            scales: {
              x: {
                title: {
                  display: true,
                  text: '시간 (초)'
                }
              },
              y: {
                beginAtZero: true,
                title: {
                  display: true,
                  text: 'TPS'
                }
              }
            },
            responsive: true,
            maintainAspectRatio: false
          }
        }),
        
        responseTime: new Chart(document.getElementById('response-time-chart').getContext('2d'), {
          type: 'line',
          data: {
            labels: [],
            datasets: [{
              label: '응답 시간 (ms)',
              data: [],
              borderColor: 'rgba(255, 99, 132, 1)',
              backgroundColor: 'rgba(255, 99, 132, 0.1)',
              borderWidth: 2,
              fill: true,
              tension: 0.2
            }]
          },
          options: {
            scales: {
              x: {
                title: {
                  display: true,
                  text: '시간 (초)'
                }
              },
              y: {
                beginAtZero: true,
                title: {
                  display: true,
                  text: '응답 시간 (ms)'
                }
              }
            },
            responsive: true,
            maintainAspectRatio: false
          }
        }),
        
        users: new Chart(document.getElementById('user-chart').getContext('2d'), {
          type: 'line',
          data: {
            labels: [],
            datasets: [{
              label: '가상 유저 수',
              data: [],
              borderColor: 'rgba(75, 192, 192, 1)',
              backgroundColor: 'rgba(75, 192, 192, 0.1)',
              borderWidth: 2,
              fill: true,
              tension: 0.2
            }]
          },
          options: {
            scales: {
              x: {
                title: {
                  display: true,
                  text: '시간 (초)'
                }
              },
              y: {
                beginAtZero: true,
                title: {
                  display: true,
                  text: '가상 유저 수'
                }
              }
            },
            responsive: true,
            maintainAspectRatio: false
          }
        }),
        
        rates: new Chart(document.getElementById('rate-chart').getContext('2d'), {
          type: 'line',
          data: {
            labels: [],
            datasets: [
              {
                label: '성공률 (%)',
                data: [],
                borderColor: 'rgba(40, 167, 69, 1)',
                backgroundColor: 'rgba(40, 167, 69, 0.1)',
                borderWidth: 2,
                fill: true,
                tension: 0.2
              },
              {
                label: '실패율 (%)',
                data: [],
                borderColor: 'rgba(220, 53, 69, 1)',
                backgroundColor: 'rgba(220, 53, 69, 0.1)',
                borderWidth: 2,
                fill: true,
                tension: 0.2
              }
            ]
          },
          options: {
            scales: {
              x: {
                title: {
                  display: true,
                  text: '시간 (초)'
                }
              },
              y: {
                beginAtZero: true,
                max: 100,
                title: {
                  display: true,
                  text: '비율 (%)'
                }
              }
            },
            responsive: true,
            maintainAspectRatio: false
          }
        })
      };
	  
	  // CPU 사용률 차트
      charts.cpu = new Chart(document.getElementById('cpu-chart').getContext('2d'), {
        type: 'line',
        data: {
          labels: [],
          datasets: [{
            label: 'CPU 사용률 (%)',
            data: [],
            borderColor: 'rgba(255, 193, 7, 1)',
            backgroundColor: 'rgba(255, 193, 7, 0.1)',
            borderWidth: 2,
            fill: true,
            tension: 0.2
          }]
        },
        options: {
          scales: {
            x: {
              title: {
                display: true,
                text: '시간 (초)'
              }
            },
            y: {
              beginAtZero: true,
              max: 100,
              title: {
                display: true,
                text: 'CPU 사용률 (%)'
              }
            }
          },
          responsive: true,
          maintainAspectRatio: false
        }
      });
      
      // 메모리 사용률 차트
      charts.memory = new Chart(document.getElementById('memory-chart').getContext('2d'), {
        type: 'line',
        data: {
          labels: [],
          datasets: [{
            label: '메모리 사용률 (%)',
            data: [],
            borderColor: 'rgba(108, 117, 125, 1)',
            backgroundColor: 'rgba(108, 117, 125, 0.1)',
            borderWidth: 2,
            fill: true,
            tension: 0.2
          }]
        },
        options: {
          scales: {
            x: {
              title: {
                display: true,
                text: '시간 (초)'
              }
            },
            y: {
              beginAtZero: true,
              max: 100,
              title: {
                display: true,
                text: '메모리 사용률 (%)'
              }
            }
          },
          responsive: true,
          maintainAspectRatio: false
        }
      });

      
      // 테스트 종료 조건 선택 이벤트
      document.getElementById('requestCount').addEventListener('change', function() {
        document.getElementById('requestCountInput').style.display = 'block';
        document.getElementById('testDurationInput').style.display = 'none';
      });
      
      document.getElementById('testDuration').addEventListener('change', function() {
        document.getElementById('requestCountInput').style.display = 'none';
        document.getElementById('testDurationInput').style.display = 'block';
      });
      
      // 폼 제출 이벤트
      const testForm = document.getElementById('test-form');
      testForm.addEventListener('submit', function(e) {
        e.preventDefault();
        
        // 폼 데이터 수집
        const url = document.getElementById('url').value;
        const method = document.getElementById('method').value;
        let headers;
        let body;
        
        try {
          headers = JSON.parse(document.getElementById('headers').value);
        } catch (error) {
          alert('헤더가 유효한 JSON 형식이 아닙니다: ' + error.message);
          return;
        }
        
        try {
          if (method !== 'GET' && method !== 'HEAD') {
            body = JSON.parse(document.getElementById('body').value);
          }
        } catch (error) {
          alert('바디가 유효한 JSON 형식이 아닙니다: ' + error.message);
          return;
        }
        
        const useRequestCount = document.getElementById('requestCount').checked;
        const requestCount = useRequestCount ? parseInt(document.getElementById('count').value) : null;
        const testDuration = !useRequestCount ? parseInt(document.getElementById('duration').value) : null;
        const requestInterval = parseInt(document.getElementById('interval').value);
        const initialUsers = parseInt(document.getElementById('users').value);
        const userIncrement = parseInt(document.getElementById('increment').value);
        
		// 테스트 시작 요청
        fetch('/start-test', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Socket-ID': socket.id // 소켓 ID를 헤더에 추가
          },
          body: JSON.stringify({
            url,
            method,
            headers,
            body,
            requestCount,
            testDuration,
            requestInterval,
            initialUsers,
            userIncrement
          })
        });
        
        // UI 초기화
        document.getElementById('start-test').disabled = true;
        document.getElementById('stop-test').disabled = false;
        document.getElementById('total-requests').textContent = '0';
        document.getElementById('success-count').textContent = '0';
        document.getElementById('fail-count').textContent = '0';
        document.getElementById('tps').textContent = '0';
        document.getElementById('elapsed-time').textContent = '0';
        document.getElementById('avg-response-time').textContent = '0';
        document.getElementById('active-users').textContent = '0';
        document.getElementById('error-summary').innerHTML = '';
        document.getElementById('error-log').innerHTML = '';
        document.getElementById('test-progress').style.width = '0%';
        
        // 차트 초기화
        Object.values(charts).forEach(chart => {
          chart.data.labels = [];
          chart.data.datasets.forEach(dataset => {
            dataset.data = [];
          });
          chart.update();
        });
      });
      
      // 통계 데이터 수신
      socket.on('stats', function(data) {
        // 기본 통계 업데이트
        document.getElementById('total-requests').textContent = data.totalRequests;
        document.getElementById('success-count').textContent = data.successCount;
        document.getElementById('fail-count').textContent = data.failCount;
        document.getElementById('tps').textContent = data.tps.toFixed(2);
        document.getElementById('elapsed-time').textContent = data.elapsedTime.toFixed(1);
        document.getElementById('avg-response-time').textContent = data.avgResponseTime.toFixed(2);
        document.getElementById('active-users').textContent = data.activeUsers;
        
        // 진행률 계산 (요청 수 기준)
        const requestCount = parseInt(document.getElementById('count').value);
        const progress = document.getElementById('requestCount').checked && requestCount ? 
          Math.min(100, (data.totalRequests / requestCount) * 100) : 
          Math.min(100, (data.elapsedTime / parseInt(document.getElementById('duration').value)) * 100);
        
        document.getElementById('test-progress').style.width = `${progress}%`;
        
        // 오류 요약 업데이트
        const errorSummary = document.getElementById('error-summary');
        errorSummary.innerHTML = '';
        
        for (const [errorType, count] of Object.entries(data.errors)) {
          const errorEntry = document.createElement('div');
          errorEntry.innerHTML = `<span class="badge bg-danger">${count}</span> ${errorType}`;
          errorSummary.appendChild(errorEntry);
        }
        
		// 차트 데이터 업데이트
        updateChart(charts.tps, data.tpsHistory);
        updateChart(charts.responseTime, data.responseTimeHistory);
        updateChart(charts.users, data.userCountHistory);
        updateChart(charts.cpu, data.cpuHistory);
        updateChart(charts.memory, data.memoryHistory);
        
        // 성공/실패율 차트는 두 데이터셋이 있으므로 따로 처리
        if (data.successRateHistory && data.successRateHistory.length > 0) {
          const labels = data.successRateHistory.map(item => item.time.toFixed(1));
          charts.rates.data.labels = labels;
          charts.rates.data.datasets[0].data = data.successRateHistory.map(item => item.value);
          charts.rates.data.datasets[1].data = data.failRateHistory.map(item => item.value);
          charts.rates.update();
        }
      });
	  
      // 시스템 리소스 데이터 수신 처리
      socket.on('systemStats', function(data) {
        // CPU 및 메모리 사용률 표시 업데이트
        document.getElementById('cpu-usage').textContent = data.cpuUsage.toFixed(2) + '%';
        document.getElementById('memory-usage').textContent = data.memoryUsage.toFixed(2) + '%';
        
        // CPU 및 메모리 차트 업데이트 (stats 이벤트에서 받는 히스토리 데이터)
        if (data.cpuHistory && data.cpuHistory.length > 0) {
          updateChart(charts.cpu, data.cpuHistory);
          updateChart(charts.memory, data.memoryHistory);
        }
      });
      
      // 오류 데이터 수신
      socket.on('error', function(error) {
        const errorLog = document.getElementById('error-log');
        const errorEntry = document.createElement('div');
        errorEntry.className = 'alert alert-danger py-1 mb-2';
        errorEntry.innerHTML = `<strong>${error.time}</strong>: ${error.message || error.code} (${error.responseTime}ms)`;
        errorLog.prepend(errorEntry);
        
        // 최대 50개 로그만 유지
        if (errorLog.children.length > 50) {
          errorLog.removeChild(errorLog.lastChild);
        }
      });
      
      // 테스트 완료 이벤트
      socket.on('testComplete', function(finalStats) {
        document.getElementById('start-test').disabled = false;
        document.getElementById('stop-test').disabled = true;
        
        // 테스트 진행률 100%로 설정
        document.getElementById('test-progress').style.width = '100%';
        
        // 최종 결과 알림
        alert(`테스트 완료!\n총 요청: ${finalStats.totalRequests}\n성공: ${finalStats.successCount}\n실패: ${finalStats.failCount}\n평균 TPS: ${finalStats.avgTps.toFixed(2)}\n평균 응답 시간: ${finalStats.avgResponseTime.toFixed(2)}ms\n테스트 시간: ${finalStats.testDuration.toFixed(1)}초`);
      });
	  
	  // 테스트 중지 이벤트 수신
      socket.on('testStopped', function(data) {
        document.getElementById('start-test').disabled = false;
        document.getElementById('stop-test').disabled = true;
  
        // 선택적으로 사용자에게 알림
        alert('테스트가 중지되었습니다: ' + data.message);
      });
      
      // 차트 업데이트 헬퍼 함수
      function updateChart(chart, historyData) {
        if (!historyData || historyData.length === 0) return;
        
        const labels = historyData.map(item => item.time.toFixed(1));
        const data = historyData.map(item => item.value);
        
        chart.data.labels = labels;
        chart.data.datasets[0].data = data;
        chart.update();
      }
      
      // 테스트 중지 버튼
      document.getElementById('stop-test').addEventListener('click', function() {
        socket.emit('stopTest');
        document.getElementById('start-test').disabled = false;
        document.getElementById('stop-test').disabled = true;
      });
    });
  </script>
</body>
</html>
