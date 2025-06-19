const express = require('express');
const { spawn } = require('child_process');
const path = require('path');
const os = require('os');
const dns = require('dns').promises;
const net = require('net');

const app = express();
const PORT = 3000;

// 미들웨어 설정
app.use(express.json());
app.use(express.static('public')); // 정적 파일 제공
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
    next();
});

// IP 주소 유효성 검증
function isValidIP(ip) {
    const ipRegex = /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
    return ipRegex.test(ip);
}

// 도메인을 IP로 변환
async function resolveHostname(hostname) {
    try {
        if (isValidIP(hostname)) {
            return hostname;
        }
        const addresses = await dns.lookup(hostname);
        return addresses.address;
    } catch (error) {
        throw new Error(`호스트명 해석 실패: ${hostname}`);
    }
}

// 네트워크 장비 타입 감지
function detectDeviceType(ip, latency, hop, hostname = '') {
    const lowerHostname = hostname.toLowerCase();
    
    // 호스트명 기반 감지
    if (lowerHostname.includes('firewall') || lowerHostname.includes('fw')) return 'firewall';
    if (lowerHostname.includes('switch') || lowerHostname.includes('sw')) return 'switch';
    if (lowerHostname.includes('router') || lowerHostname.includes('rt') || lowerHostname.includes('gw')) return 'router';
    if (lowerHostname.includes('load') || lowerHostname.includes('lb')) return 'firewall';
    
    // IP 패턴 기반 감지
    if (ip.startsWith('192.168.') || ip.startsWith('10.') || 
        (ip.startsWith('172.') && parseInt(ip.split('.')[1]) >= 16 && parseInt(ip.split('.')[1]) <= 31)) {
        // 사설 IP 대역
        if (hop === 1) return 'router'; // 첫 번째 홉은 보통 게이트웨이
        if (latency < 5) return 'switch'; // 낮은 지연시간
        return 'router';
    } else {
        // 공인 IP 대역
        if (latency > 100) return 'router'; // 높은 지연시간은 원거리 라우터
        if (hop % 4 === 0) return 'firewall'; // 주기적으로 방화벽 추정
        return 'router';
    }
}

// 포트 연결 테스트
async function testPortConnection(ip, port, timeout = 5000) {
    return new Promise((resolve) => {
        const socket = new net.Socket();
        const timer = setTimeout(() => {
            socket.destroy();
            resolve({ connected: false, error: 'Timeout' });
        }, timeout);

        socket.connect(port, ip, () => {
            clearTimeout(timer);
            socket.destroy();
            resolve({ connected: true });
        });

        socket.on('error', (err) => {
            clearTimeout(timer);
            socket.destroy();
            resolve({ connected: false, error: err.message });
        });
    });
}

// Traceroute 실행
async function executeTraceroute(targetIp, maxHops = 30) {
    return new Promise((resolve, reject) => {
        const isWindows = os.platform() === 'win32';
        const command = isWindows ? 'tracert' : 'traceroute';
        const args = isWindows ? 
            ['-h', maxHops.toString(), '-w', '5000', targetIp] : 
            ['-m', maxHops.toString(), '-w', '5', targetIp];

        const traceroute = spawn(command, args);
        let output = '';
        let errorOutput = '';

        traceroute.stdout.on('data', (data) => {
            output += data.toString();
        });

        traceroute.stderr.on('data', (data) => {
            errorOutput += data.toString();
        });

        traceroute.on('close', (code) => {
            if (code === 0 || output.length > 0) {
                resolve(output);
            } else {
                reject(new Error(`Traceroute 실행 실패: ${errorOutput}`));
            }
        });

        traceroute.on('error', (error) => {
            reject(new Error(`Command 실행 오류: ${error.message}`));
        });
    });
}

// Traceroute 결과 파싱
function parseTracerouteOutput(output, sourceIp, targetIp) {
    const lines = output.split('\n').filter(line => line.trim());
    const hops = [];
    const isWindows = os.platform() === 'win32';

    // 출발지 추가
    hops.push({
        hop: 0,
        ip: sourceIp,
        hostname: 'localhost',
        type: 'source',
        latency: 0,
        name: 'Source',
        status: 'success'
    });

    for (const line of lines) {
        let hopMatch, ipMatch, latencyMatch, hostnameMatch;
        
        if (isWindows) {
            // Windows tracert 출력 파싱
            hopMatch = line.match(/^\s*(\d+)\s+/);
            if (!hopMatch) continue;
            
            const hopNum = parseInt(hopMatch[1]);
            ipMatch = line.match(/(\d+\.\d+\.\d+\.\d+)/);
            latencyMatch = line.match(/(\d+)\s*ms/g);
            hostnameMatch = line.match(/\[(\d+\.\d+\.\d+\.\d+)\]/) || line.match(/(\S+)\s+\[/);
            
            if (line.includes('*') || line.includes('요청 시간이 만료')) {
                hops.push({
                    hop: hopNum,
                    ip: '*',
                    hostname: '*',
                    type: 'timeout',
                    latency: 999,
                    name: `Hop ${hopNum} (Timeout)`,
                    status: 'timeout'
                });
                continue;
            }
        } else {
            // Linux/Unix traceroute 출력 파싱
            hopMatch = line.match(/^\s*(\d+)\s+/);
            if (!hopMatch) continue;
            
            const hopNum = parseInt(hopMatch[1]);
            ipMatch = line.match(/\((\d+\.\d+\.\d+\.\d+)\)/);
            latencyMatch = line.match(/(\d+(?:\.\d+)?)\s*ms/g);
            hostnameMatch = line.match(/^\s*\d+\s+(\S+)/);
            
            if (line.includes('*')) {
                hops.push({
                    hop: hopNum,
                    ip: '*',
                    hostname: '*',
                    type: 'timeout',
                    latency: 999,
                    name: `Hop ${hopNum} (Timeout)`,
                    status: 'timeout'
                });
                continue;
            }
        }

        if (ipMatch && hopMatch) {
            const hopNum = parseInt(hopMatch[1]);
            const ip = ipMatch[1] || ipMatch[0];
            const hostname = hostnameMatch ? hostnameMatch[1] : ip;
            
            // 평균 지연시간 계산
            let avgLatency = 0;
            if (latencyMatch && latencyMatch.length > 0) {
                const latencies = latencyMatch.map(match => 
                    parseFloat(match.replace(/[^\d.]/g, ''))
                ).filter(lat => !isNaN(lat));
                avgLatency = latencies.length > 0 ? 
                    latencies.reduce((a, b) => a + b, 0) / latencies.length : 0;
            }

            const deviceType = hopNum === hops.length ? 'destination' : 
                detectDeviceType(ip, avgLatency, hopNum, hostname);

            hops.push({
                hop: hopNum,
                ip: ip,
                hostname: hostname !== ip ? hostname : '',
                type: deviceType,
                latency: Math.round(avgLatency * 100) / 100,
                name: `${deviceType.charAt(0).toUpperCase() + deviceType.slice(1)} ${hopNum}`,
                status: 'success'
            });
        }
    }

    // 목적지가 마지막 홉이 아닌 경우 추가
    if (hops.length > 1 && hops[hops.length - 1].ip !== targetIp) {
        hops.push({
            hop: hops.length,
            ip: targetIp,
            hostname: '',
            type: 'destination',
            latency: 0,
            name: 'Destination',
            status: 'success'
        });
    } else if (hops.length > 1) {
        // 마지막 홉을 목적지로 변경
        hops[hops.length - 1].type = 'destination';
        hops[hops.length - 1].name = 'Destination';
    }

    return hops;
}

// 로컬 IP 주소 가져오기
function getLocalIP() {
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name]) {
            if (iface.family === 'IPv4' && !iface.internal) {
                return iface.address;
            }
        }
    }
    return '127.0.0.1';
}

// API 엔드포인트들
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Traceroute API
app.post('/api/traceroute', async (req, res) => {
    try {
        const { sourceIp, destIp, destPort, maxHops = 30 } = req.body;

        if (!destIp) {
            return res.status(400).json({ error: '목적지 IP가 필요합니다.' });
        }

        // 목적지 IP 해석
        const targetIp = await resolveHostname(destIp);
        const localIp = sourceIp || getLocalIP();

        console.log(`Traceroute 시작: ${localIp} -> ${targetIp}:${destPort}`);

        // Traceroute 실행
        const output = await executeTraceroute(targetIp, maxHops);
        
        // 결과 파싱
        const hops = parseTracerouteOutput(output, localIp, targetIp);

        // 포트 연결 테스트 (선택적)
        let portStatus = null;
        if (destPort) {
            portStatus = await testPortConnection(targetIp, parseInt(destPort));
        }

        res.json({
            success: true,
            source: localIp,
            destination: targetIp,
            port: destPort,
            hops: hops,
            portStatus: portStatus,
            totalHops: hops.length - 1,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('Traceroute 오류:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 호스트명 해석 API
app.post('/api/resolve', async (req, res) => {
    try {
        const { hostname } = req.body;
        const ip = await resolveHostname(hostname);
        res.json({ success: true, hostname, ip });
    } catch (error) {
        res.status(400).json({ success: false, error: error.message });
    }
});

// 포트 테스트 API
app.post('/api/port-test', async (req, res) => {
    try {
        const { ip, port, timeout = 5000 } = req.body;
        const result = await testPortConnection(ip, parseInt(port), timeout);
        res.json({ success: true, ...result });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// 서버 시작
app.listen(PORT, () => {
    console.log(`🚀 Traceroute 서버가 포트 ${PORT}에서 실행 중입니다.`);
    console.log(`📱 브라우저에서 http://localhost:${PORT} 접속하세요.`);
    console.log(`🔧 로컬 IP: ${getLocalIP()}`);
});

// 에러 핸들링
process.on('uncaughtException', (error) => {
    console.error('처리되지 않은 예외:', error);
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('처리되지 않은 Promise 거부:', reason);
});
