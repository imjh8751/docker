#!/bin/bash

# 디렉토리 구조 수정 및 문제 해결 스크립트

echo "=== WebSphere WAR 프로젝트 디렉토리 수정 ==="

# 현재 위치 확인
echo "현재 위치: $(pwd)"

# websphere-client-info 디렉토리가 없으면 생성
if [ ! -d "websphere-client-info" ]; then
    echo "📁 websphere-client-info 디렉토리 생성..."
    mkdir -p websphere-client-info
fi

cd websphere-client-info

# 필요한 모든 디렉토리 생성
echo "📂 필요한 디렉토리들 생성 중..."
mkdir -p src/main/java/com/websphere/sample
mkdir -p src/main/webapp/WEB-INF
mkdir -p src/main/webapp/css
mkdir -p src/main/webapp/js
mkdir -p src/main/webapp/error
mkdir -p target
mkdir -p build

# 디렉토리 구조 확인
echo "✅ 생성된 디렉토리 구조:"
find . -type d | sort

# 권한 설정
chmod 755 src/main/webapp/WEB-INF
chmod 755 src/main/webapp/css
chmod 755 src/main/webapp/js
chmod 755 src/main/webapp/error

echo ""
echo "🔧 문제 해결 완료!"
echo ""

# web.xml이 없으면 기본 생성
if [ ! -f "src/main/webapp/WEB-INF/web.xml" ]; then
    echo "📋 기본 web.xml 생성 중..."
    cat > src/main/webapp/WEB-INF/web.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://java.sun.com/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://java.sun.com/xml/ns/javaee 
         http://java.sun.com/xml/ns/javaee/web-app_3_0.xsd"
         version="3.0">

    <display-name>WebSphere Client Info Application</display-name>
    <description>클라이언트 정보를 출력하는 샘플 웹 애플리케이션</description>

    <welcome-file-list>
        <welcome-file>index.jsp</welcome-file>
        <welcome-file>index.html</welcome-file>
    </welcome-file-list>

    <session-config>
        <session-timeout>30</session-timeout>
    </session-config>

    <error-page>
        <error-code>404</error-code>
        <location>/error/404.jsp</location>
    </error-page>
    
    <error-page>
        <error-code>500</error-code>
        <location>/error/500.jsp</location>
    </error-page>

</web-app>
EOF
    echo "✅ web.xml 생성 완료"
fi

# 기본 index.html 생성 (임시)
if [ ! -f "src/main/webapp/index.html" ]; then
    echo "🌐 임시 index.html 생성 중..."
    cat > src/main/webapp/index.html << 'EOF'
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WebSphere 클라이언트 정보</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
        }
        .container {
            background: rgba(255,255,255,0.1);
            padding: 30px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
        }
        h1 { text-align: center; margin-bottom: 20px; }
        .info { background: rgba(255,255,255,0.2); padding: 15px; margin: 10px 0; border-radius: 8px; }
        .highlight { color: #ffeb3b; font-weight: bold; }
        .links { text-align: center; margin-top: 30px; }
        .links a { 
            display: inline-block; 
            margin: 10px; 
            padding: 10px 20px; 
            background: #2196F3; 
            color: white; 
            text-decoration: none; 
            border-radius: 25px; 
            transition: background 0.3s;
        }
        .links a:hover { background: #1976D2; }
    </style>
    <script>
        function updateInfo() {
            document.getElementById('current-time').textContent = new Date().toLocaleString('ko-KR');
            document.getElementById('user-agent').textContent = navigator.userAgent;
            document.getElementById('screen-size').textContent = screen.width + ' x ' + screen.height;
            document.getElementById('window-size').textContent = window.innerWidth + ' x ' + window.innerHeight;
        }
        
        window.onload = updateInfo;
        setInterval(updateInfo, 1000);
    </script>
</head>
<body>
    <div class="container">
        <h1>🌐 WebSphere 클라이언트 정보</h1>
        
        <div class="info">
            <h3>📍 현재 위치</h3>
            <p><strong>URL:</strong> <span class="highlight" id="current-url"></span></p>
            <p><strong>현재 시간:</strong> <span class="highlight" id="current-time"></span></p>
        </div>
        
        <div class="info">
            <h3>💻 브라우저 정보</h3>
            <p><strong>User Agent:</strong> <span id="user-agent"></span></p>
            <p><strong>언어:</strong> <span class="highlight" id="language"></span></p>
            <p><strong>플랫폼:</strong> <span class="highlight" id="platform"></span></p>
        </div>
        
        <div class="info">
            <h3>📱 화면 정보</h3>
            <p><strong>화면 해상도:</strong> <span class="highlight" id="screen-size"></span></p>
            <p><strong>브라우저 창 크기:</strong> <span class="highlight" id="window-size"></span></p>
            <p><strong>색상 깊이:</strong> <span class="highlight" id="color-depth"></span></p>
        </div>
        
        <div class="info">
            <h3>🔗 연결 정보</h3>
            <p><strong>온라인 상태:</strong> <span class="highlight" id="online-status"></span></p>
            <p><strong>쿠키 사용:</strong> <span class="highlight" id="cookie-enabled"></span></p>
        </div>
        
        <div class="links">
            <a href="index.jsp">JSP 버전 보기</a>
            <a href="test.jsp">테스트 페이지</a>
            <a href="api/status">API 상태</a>
            <a href="javascript:location.reload()">새로고침</a>
        </div>
        
        <div style="text-align: center; margin-top: 20px; opacity: 0.7;">
            <p>WebSphere 클라이언트 정보 애플리케이션 v1.0</p>
            <p>프로젝트가 완전히 설정되면 더 자세한 정보를 확인할 수 있습니다.</p>
        </div>
    </div>
    
    <script>
        // 페이지 로드 후 정보 업데이트
        document.getElementById('current-url').textContent = window.location.href;
        document.getElementById('language').textContent = navigator.language;
        document.getElementById('platform').textContent = navigator.platform;
        document.getElementById('color-depth').textContent = screen.colorDepth + ' bit';
        document.getElementById('online-status').textContent = navigator.onLine ? '온라인' : '오프라인';
        document.getElementById('cookie-enabled').textContent = navigator.cookieEnabled ? '사용 가능' : '사용 불가';
    </script>
</body>
</html>
EOF
    echo "✅ 임시 index.html 생성 완료"
fi

# 간단한 CSS 파일 생성
if [ ! -f "src/main/webapp/css/style.css" ]; then
    echo "🎨 기본 CSS 파일 생성 중..."
    cat > src/main/webapp/css/style.css << 'EOF'
/* 기본 스타일 */
body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    line-height: 1.6;
    color: #333;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
    margin: 0;
    padding: 20px;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    background: white;
    border-radius: 15px;
    box-shadow: 0 10px 30px rgba(0,0,0,0.3);
    overflow: hidden;
}

header {
    background: linear-gradient(135deg, #2c3e50 0%, #3498db 100%);
    color: white;
    padding: 30px;
    text-align: center;
}

.info-section {
    margin: 30px;
    padding: 25px;
    background: #f8f9fa;
    border-radius: 10px;
    border-left: 5px solid #3498db;
}

.test-link {
    display: inline-block;
    padding: 12px 24px;
    background: #3498db;
    color: white;
    text-decoration: none;
    border-radius: 25px;
    transition: all 0.3s ease;
    margin: 5px;
}

.test-link:hover {
    background: #2980b9;
    transform: translateY(-2px);
}
EOF
    echo "✅ 기본 CSS 생성 완료"
fi

# 간단한 테스트 WAR 생성 스크립트
cat > quick-war.sh << 'EOF'
#!/bin/bash
echo "=== 빠른 WAR 생성 ==="

# 빌드 디렉토리 정리
rm -rf build target *.war

# 빌드 디렉토리 생성
mkdir -p build

# 웹 리소스 복사
echo "📋 웹 리소스 복사 중..."
cp -r src/main/webapp/* build/ 2>/dev/null || echo "일부 파일 복사 실패 (정상)"

# WAR 파일 생성
echo "📦 WAR 파일 생성 중..."
cd build
if command -v jar &> /dev/null; then
    jar -cvf ../websphere-client-info.war . > /dev/null 2>&1
    echo "✅ jar 명령어로 WAR 생성 완료"
elif command -v zip &> /dev/null; then
    zip -r ../websphere-client-info.war . > /dev/null 2>&1
    echo "✅ zip 명령어로 WAR 생성 완료"
else
    echo "❌ jar 또는 zip 명령어가 필요합니다"
    cd ..
    exit 1
fi

cd ..
rm -rf build

if [ -f "websphere-client-info.war" ]; then
    echo "🎉 WAR 파일 생성 성공: $(ls -lh websphere-client-info.war)"
    echo ""
    echo "🚀 배포 방법:"
    echo "1. WebSphere Admin Console: http://localhost:9060/ibm/console"
    echo "2. Applications → Install → websphere-client-info.war 업로드"
    echo "3. 설치 후 시작"
    echo "4. 접속: http://localhost:9080/websphere-client-info/"
else
    echo "❌ WAR 파일 생성 실패"
    exit 1
fi
EOF

chmod +x quick-war.sh

echo ""
echo "🎯 문제 해결 완료 및 추가 도구 생성:"
echo "  ✅ 모든 필요한 디렉토리 생성"
echo "  ✅ 기본 web.xml 생성"
echo "  ✅ 임시 index.html 생성"
echo "  ✅ 기본 CSS 스타일 생성"
echo "  ✅ 빠른 WAR 생성 스크립트 생성"
echo ""
echo "🚀 다음 단계:"
echo "1. ./quick-war.sh           # 빠른 WAR 생성"
echo "2. 또는 원본 스크립트 다시 실행하여 완전한 프로젝트 생성"
echo ""
echo "📁 현재 디렉토리 구조:"
tree . 2>/dev/null || find . -type d | sort

cd ..
