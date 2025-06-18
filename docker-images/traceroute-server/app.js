const express = require('express');
const { exec } = require('child_process');
const dns = require('dns');
const net = require('net');
const os = require('os');

const app = express();
const PORT = 3333;

app.use(express.json());

// 서버 IP 자동 감지
function getServerIP() {
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
        for (const interface of interfaces[name]) {
            if (interface.family === 'IPv4' && !interface.internal) {
                return interface.address;
            }
        }
    }
    return '127.0.0.1';
}

// 도메인을 IP로 변환
function resolveHostname(hostname) {
    return new Promise((resolve, reject) => {
        if (/^\d+\.\d+\.\d+\.\d+$/.test(hostname)) {
            resolve(hostname);
        } else {
            dns.lookup(hostname, (err, address) => {
                if (err) reject(err);
                else resolve(address);
            });
        }
    });
}

// 장비 타입 추정 (IP 기반)
function guessDeviceType(ip, hopNumber, totalHops) {
    // 일반적인 패턴으로 장비 타입 추정
    const lastOctet = parseInt(ip.split('.').pop());
    
    if (hopNumber === 1) {
        return '🌐 Gateway Router';
    } else if (hopNumber === totalHops) {
        return '🎯 Destination';
    } else if (lastOctet === 1 || lastOctet === 254) {
        return '🔀 Core Router';
    } else if (lastOctet >= 10 && lastOctet <= 50) {
        return '🛡️ Firewall/Security';
    } else if (lastOctet >= 100 && lastOctet <= 150) {
        return '🔄 Load Balancer/Switch';
    } else {
        return '📡 Network Device';
    }
}

// Traceroute 실행
function performTraceroute(targetIP) {
    return new Promise((resolve, reject) => {
        const isWindows = process.platform === 'win32';
        const command = isWindows ? `tracert -h 30 ${targetIP}` : `traceroute -m 30 ${targetIP}`;
        
        exec(command, { timeout: 30000 }, (error, stdout, stderr) => {
            if (error && !stdout) {
                reject(error);
                return;
            }
            
            const lines = stdout.split('\n');
            const hops = [];
            
            lines.forEach(line => {
                line = line.trim();
                if (!line) return;
                
                let hopMatch;
                if (isWindows) {
                    // Windows tracert 파싱
                    hopMatch = line.match(/^\s*(\d+)\s+(?:(\d+)\s*ms|\*)\s+(?:(\d+)\s*ms|\*)\s+(?:(\d+)\s*ms|\*)\s+(.+)$/);
                } else {
                    // Linux/Mac traceroute 파싱
                    hopMatch = line.match(/^\s*(\d+)\s+(.+?)(?:\s+\(([^)]+)\))?\s+(\d+(?:\.\d+)?)\s*ms/);
                }
                
                if (hopMatch) {
                    const hopNum = parseInt(hopMatch[1]);
                    let ip = '';
                    let hostname = '';
                    
                    if (isWindows) {
                        const target = hopMatch[5];
                        const ipMatch = target.match(/(\d+\.\d+\.\d+\.\d+)/);
                        if (ipMatch) {
                            ip = ipMatch[1];
                            hostname = target.replace(ip, '').trim();
                        } else {
                            hostname = target;
                        }
                    } else {
                        hostname = hopMatch[2];
                        ip = hopMatch[3] || hopMatch[2];
                        if (!/^\d+\.\d+\.\d+\.\d+$/.test(ip)) {
                            ip = hostname;
                        }
                    }
                    
                    if (ip && ip !== '*') {
                        hops.push({
                            hop: hopNum,
                            ip: ip,
                            hostname: hostname || ip
                        });
                    }
                }
            });
            
            resolve(hops);
        });
    });
}

// 포트 연결 테스트
function testPortConnection(ip, port) {
    return new Promise((resolve) => {
        const socket = new net.Socket();
        const timeout = 5000;
        
        socket.setTimeout(timeout);
        
        socket.on('connect', () => {
            socket.destroy();
            resolve({
                success: true,
                message: '포트 연결 성공',
                responseTime: Date.now() - startTime
            });
        });
        
        socket.on('timeout', () => {
            socket.destroy();
            resolve({
                success: false,
                message: '연결 타임아웃',
                responseTime: timeout
            });
        });
        
        socket.on('error', (err) => {
            socket.destroy();
            resolve({
                success: false,
                message: `연결 실패: ${err.code}`,
                responseTime: Date.now() - startTime
            });
        });
        
        const startTime = Date.now();
        socket.connect(port, ip);
    });
}

// 네트워크 경로 시각화
function visualizeNetworkPath(sourceIP, targetIP, hops, portTestResult) {
    let diagram = '\n';
    diagram += '═══════════════════════════════════════════════════\n';
    diagram += '            🔍 NETWORK PATH ANALYSIS\n';
    diagram += '═══════════════════════════════════════════════════\n';
    diagram += `📍 출발지: ${sourceIP}\n`;
    diagram += `🎯 목적지: ${targetIP}\n`;
    diagram += '═══════════════════════════════════════════════════\n\n';
    
    // 네트워크 경로 다이어그램
    diagram += '📊 네트워크 경로 추적:\n';
    diagram += '┌─────────────────────────────────────────────────┐\n';
    
    hops.forEach((hop, index) => {
        const deviceType = guessDeviceType(hop.ip, hop.hop, hops.length);
        const isLast = index === hops.length - 1;
        
        diagram += `│ ${hop.hop.toString().padStart(2)} │ ${deviceType}\n`;
        diagram += `│    │ 📍 ${hop.ip}\n`;
        if (hop.hostname !== hop.ip) {
            diagram += `│    │ 🏷️  ${hop.hostname}\n`;
        }
        
        if (!isLast) {
            diagram += '│    │\n';
            diagram += '│    ▼\n';
        }
    });
    
    diagram += '└─────────────────────────────────────────────────┘\n\n';
    
    // 포트 테스트 결과
    diagram += '🚪 포트 연결 테스트 결과:\n';
    diagram += '┌─────────────────────────────────────────────────┐\n';
    diagram += `│ 상태: ${portTestResult.success ? '✅ 성공' : '❌ 실패'}\n`;
    diagram += `│ 메시지: ${portTestResult.message}\n`;
    diagram += `│ 응답시간: ${portTestResult.responseTime}ms\n`;
    diagram += '└─────────────────────────────────────────────────┘\n';
    
    return diagram;
}

// API 엔드포인트
app.post('/trace', async (req, res) => {
    try {
        const { destination, port } = req.body;
        
        if (!destination || !port) {
            return res.status(400).json({
                error: '목적지(destination)와 포트(port)를 입력해주세요'
            });
        }
        
        console.log(`\n🚀 네트워크 테스트 시작: ${destination}:${port}`);
        
        // 출발지 IP 자동 감지
        const sourceIP = getServerIP();
        
        // 도메인을 IP로 변환
        const targetIP = await resolveHostname(destination);
        console.log(`🔍 목적지 IP 확인: ${destination} → ${targetIP}`);
        
        // Traceroute 실행
        console.log('📡 네트워크 경로 추적 중...');
        const hops = await performTraceroute(targetIP);
        
        // 포트 연결 테스트
        console.log(`🚪 포트 ${port} 연결 테스트 중...`);
        const portTestResult = await testPortConnection(targetIP, port);
        
        // 결과 시각화
        const visualization = visualizeNetworkPath(sourceIP, targetIP, hops, portTestResult);
        console.log(visualization);
        
        // JSON 응답
        res.json({
            success: true,
            sourceIP,
            destination,
            targetIP,
            port,
            hops: hops.map(hop => ({
                ...hop,
                deviceType: guessDeviceType(hop.ip, hop.hop, hops.length)
            })),
            portTest: portTestResult,
            visualization
        });
        
    } catch (error) {
        console.error('❌ 테스트 실행 중 오류:', error.message);
        res.status(500).json({
            error: '테스트 실행 중 오류가 발생했습니다',
            details: error.message
        });
    }
});

// 서버 시작
app.listen(PORT, () => {
    console.log(`🌐 네트워크 테스트 서버가 포트 ${PORT}에서 실행 중입니다`);
    console.log(`📍 서버 IP: ${getServerIP()}`);
    console.log('\n📚 사용법:');
    console.log(`curl -X POST http://localhost:${PORT}/trace \\`);
    console.log(`  -H "Content-Type: application/json" \\`);
    console.log(`  -d '{"destination": "google.com", "port": 80}'`);
    console.log('\n또는');
    console.log(`curl -X POST http://localhost:${PORT}/trace \\`);
    console.log(`  -H "Content-Type: application/json" \\`);
    console.log(`  -d '{"destination": "8.8.8.8", "port": 53}'`);
});
