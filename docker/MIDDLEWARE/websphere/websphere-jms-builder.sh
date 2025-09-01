#!/bin/bash

# WAS JMS Producer/Consumer 자동 생성 및 빌드 스크립트
# 사용법: ./setup.sh

echo "=== WAS JMS Producer/Consumer 프로젝트 생성 시작 ==="

# 프로젝트 루트 디렉토리 생성
PROJECT_ROOT="was-jms-demo"
rm -rf $PROJECT_ROOT
mkdir -p $PROJECT_ROOT
cd $PROJECT_ROOT

echo "✓ 프로젝트 디렉토리 생성: $PROJECT_ROOT"

# =================================================================
# 1. Producer 프로젝트 구조 생성
# =================================================================
echo "📦 Producer 프로젝트 생성 중..."

mkdir -p producer/src/main/java/com/example/producer
mkdir -p producer/src/main/webapp/WEB-INF
mkdir -p producer/META-INF

# Producer pom.xml
cat > producer/pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.example</groupId>
    <artifactId>jms-producer</artifactId>
    <version>1.0.0</version>
    <packaging>ear</packaging>
    
    <properties>
        <maven.compiler.source>8</maven.compiler.source>
        <maven.compiler.target>8</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>javax.jms</groupId>
            <artifactId>javax.jms-api</artifactId>
            <version>2.0.1</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>javax.servlet</groupId>
            <artifactId>javax.servlet-api</artifactId>
            <version>3.1.0</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>javax</groupId>
            <artifactId>javaee-api</artifactId>
            <version>7.0</version>
            <scope>provided</scope>
        </dependency>
    </dependencies>
    
    <build>
        <finalName>producer</finalName>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.8.1</version>
                <configuration>
                    <source>8</source>
                    <target>8</target>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-war-plugin</artifactId>
                <version>3.2.3</version>
                <configuration>
                    <webXml>src\main\webapp\WEB-INF\web.xml</webXml>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-ear-plugin</artifactId>
                <version>3.0.2</version>
                <configuration>
                    <displayName>JMS Producer</displayName>
                    <modules>
                        <webModule>
                            <groupId>com.example</groupId>
                            <artifactId>jms-producer</artifactId>
                            <contextRoot>/producer</contextRoot>
                        </webModule>
                    </modules>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF

# Producer Servlet
cat > producer/src/main/java/com/example/producer/MessageProducerServlet.java << 'EOF'
package com.example.producer;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.jms.*;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import java.io.IOException;
import java.io.PrintWriter;

@WebServlet("/send")
public class MessageProducerServlet extends HttpServlet {
    
    private static final String CF_JNDI = "jms/ConnectionFactory";
    private static final String QUEUE_JNDI = "jms/TestQueue";
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String message = request.getParameter("msg");
        if (message == null || message.trim().isEmpty()) {
            message = "Hello from Producer!";
        }
        
        response.setContentType("text/html; charset=UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            sendMessage(message);
            out.println("<html><body>");
            out.println("<h2>✅ 메시지 전송 성공!</h2>");
            out.println("<p><strong>전송된 메시지:</strong> " + message + "</p>");
            out.println("<p><strong>시간:</strong> " + new java.util.Date() + "</p>");
            out.println("<hr>");
            out.println("<p>사용법: <code>/producer/send?msg=your_message</code></p>");
            out.println("</body></html>");
            
        } catch (Exception e) {
            out.println("<html><body>");
            out.println("<h2>❌ 메시지 전송 실패</h2>");
            out.println("<p><strong>오류:</strong> " + e.getMessage() + "</p>");
            out.println("</body></html>");
            e.printStackTrace();
        }
    }
    
    private void sendMessage(String messageText) throws NamingException, JMSException {
        InitialContext ctx = null;
        Connection connection = null;
        
        try {
            // JNDI Lookup
            ctx = new InitialContext();
            ConnectionFactory cf = (ConnectionFactory) ctx.lookup(CF_JNDI);
            Queue queue = (Queue) ctx.lookup(QUEUE_JNDI);
            
            // JMS Connection 생성
            connection = cf.createConnection();
            Session session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
            MessageProducer producer = session.createProducer(queue);
            
            // 메시지 생성 및 전송
            TextMessage message = session.createTextMessage(messageText);
            message.setStringProperty("sender", "ProducerServlet");
            message.setLongProperty("timestamp", System.currentTimeMillis());
            
            producer.send(message);
            
            System.out.println("📤 메시지 전송됨: " + messageText);
            
        } finally {
            if (connection != null) {
                connection.close();
            }
            if (ctx != null) {
                ctx.close();
            }
        }
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        doGet(request, response);
    }
}
EOF

# Producer web.xml
cat > producer/src/main/webapp/WEB-INF/web.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://java.sun.com/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://java.sun.com/xml/ns/javaee
         http://java.sun.com/xml/ns/javaee/web-app_3_0.xsd"
         version="3.0">
    
    <display-name>JMS Producer Web Application</display-name>
    
    <resource-ref>
        <res-ref-name>jms/ConnectionFactory</res-ref-name>
        <res-type>javax.jms.ConnectionFactory</res-type>
        <res-auth>Container</res-auth>
        <res-sharing-scope>Shareable</res-sharing-scope>
    </resource-ref>
    
    <resource-ref>
        <res-ref-name>jms/TestQueue</res-ref-name>
        <res-type>javax.jms.Queue</res-type>
        <res-auth>Container</res-auth>
        <res-sharing-scope>Shareable</res-sharing-scope>
    </resource-ref>
    
</web-app>
EOF

# Producer application.xml
cat > producer/META-INF/application.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<application xmlns="http://java.sun.com/xml/ns/javaee"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://java.sun.com/xml/ns/javaee
             http://java.sun.com/xml/ns/javaee/application_7.xsd"
             version="7">
    
    <display-name>JMS Producer Application</display-name>
    
    <module>
        <web>
            <web-uri>producer.war</web-uri>
            <context-root>/producer</context-root>
        </web>
    </module>
    
</application>
EOF

echo "✓ Producer 프로젝트 생성 완료"

# =================================================================
# 2. Consumer 프로젝트 구조 생성
# =================================================================
echo "📦 Consumer 프로젝트 생성 중..."

mkdir -p consumer/src/main/java/com/example/consumer
mkdir -p consumer/META-INF

# Consumer pom.xml
cat > consumer/pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.example</groupId>
    <artifactId>jms-consumer</artifactId>
    <version>1.0.0</version>
    <packaging>ear</packaging>
    
    <properties>
        <maven.compiler.source>8</maven.compiler.source>
        <maven.compiler.target>8</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>javax.jms</groupId>
            <artifactId>javax.jms-api</artifactId>
            <version>2.0.1</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>javax.ejb</groupId>
            <artifactId>javax.ejb-api</artifactId>
            <version>3.2.2</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>javax</groupId>
            <artifactId>javaee-api</artifactId>
            <version>7.0</version>
            <scope>provided</scope>
        </dependency>
    </dependencies>
    
    <build>
        <finalName>consumer</finalName>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.8.1</version>
                <configuration>
                    <source>8</source>
                    <target>8</target>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-ejb-plugin</artifactId>
                <version>3.0.1</version>
                <configuration>
                    <ejbVersion>3.2</ejbVersion>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-ear-plugin</artifactId>
                <version>3.0.2</version>
                <configuration>
                    <displayName>JMS Consumer</displayName>
                    <modules>
                        <ejbModule>
                            <groupId>com.example</groupId>
                            <artifactId>jms-consumer</artifactId>
                        </ejbModule>
                    </modules>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF

# Consumer MDB
cat > consumer/src/main/java/com/example/consumer/MessageConsumerMDB.java << 'EOF'
package com.example.consumer;

import javax.ejb.ActivationConfigProperty;
import javax.ejb.MessageDriven;
import javax.jms.JMSException;
import javax.jms.Message;
import javax.jms.MessageListener;
import javax.jms.TextMessage;
import java.util.Date;

@MessageDriven(
    activationConfig = {
        @ActivationConfigProperty(
            propertyName = "destinationType", 
            propertyValue = "javax.jms.Queue"
        ),
        @ActivationConfigProperty(
            propertyName = "destination", 
            propertyValue = "jms/TestQueue"
        ),
        @ActivationConfigProperty(
            propertyName = "connectionFactoryJndiName", 
            propertyValue = "jms/ConnectionFactory"
        )
    }
)
public class MessageConsumerMDB implements MessageListener {
    
    @Override
    public void onMessage(Message message) {
        try {
            if (message instanceof TextMessage) {
                TextMessage textMessage = (TextMessage) message;
                String messageText = textMessage.getText();
                
                // 메시지 속성 읽기
                String sender = textMessage.getStringProperty("sender");
                long timestamp = textMessage.getLongProperty("timestamp");
                
                // 콘솔 출력
                System.out.println("=================================================");
                System.out.println("📥 [JMS Consumer] 메시지 수신됨!");
                System.out.println("📄 내용: " + messageText);
                System.out.println("👤 발신자: " + (sender != null ? sender : "Unknown"));
                System.out.println("⏰ 전송시간: " + new Date(timestamp));
                System.out.println("🕐 수신시간: " + new Date());
                System.out.println("🆔 메시지ID: " + message.getJMSMessageID());
                System.out.println("=================================================");
                
            } else {
                System.out.println("⚠️  [JMS Consumer] 지원하지 않는 메시지 타입: " 
                                 + message.getClass().getName());
            }
            
        } catch (JMSException e) {
            System.err.println("❌ [JMS Consumer] 메시지 처리 중 오류 발생: " + e.getMessage());
            e.printStackTrace();
        } catch (Exception e) {
            System.err.println("❌ [JMS Consumer] 예상치 못한 오류: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
EOF

# Consumer ejb-jar.xml
mkdir -p consumer/src/main/resources/META-INF
cat > consumer/src/main/resources/META-INF/ejb-jar.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<ejb-jar xmlns="http://java.sun.com/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://java.sun.com/xml/ns/javaee
         http://java.sun.com/xml/ns/javaee/ejb-jar_3_2.xsd"
         version="3.2">
    
    <display-name>JMS Consumer EJB</display-name>
    
    <enterprise-beans>
        <message-driven>
            <ejb-name>MessageConsumerMDB</ejb-name>
            <ejb-class>com.example.consumer.MessageConsumerMDB</ejb-class>
            <messaging-type>javax.jms.MessageListener</messaging-type>
            
            <resource-ref>
                <res-ref-name>jms/ConnectionFactory</res-ref-name>
                <res-type>javax.jms.ConnectionFactory</res-type>
                <res-auth>Container</res-auth>
                <res-sharing-scope>Shareable</res-sharing-scope>
            </resource-ref>
            
            <resource-ref>
                <res-ref-name>jms/TestQueue</res-ref-name>
                <res-type>javax.jms.Queue</res-type>
                <res-auth>Container</res-auth>
                <res-sharing-scope>Shareable</res-sharing-scope>
            </resource-ref>
        </message-driven>
    </enterprise-beans>
    
</ejb-jar>
EOF

# Consumer application.xml
cat > consumer/META-INF/application.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<application xmlns="http://java.sun.com/xml/ns/javaee"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://java.sun.com/xml/ns/javaee
             http://java.sun.com/xml/ns/javaee/application_7.xsd"
             version="7">
    
    <display-name>JMS Consumer Application</display-name>
    
    <module>
        <ejb>consumer.jar</ejb>
    </module>
    
</application>
EOF

echo "✓ Consumer 프로젝트 생성 완료"

# =================================================================
# 3. WAS 설정 파일 생성 (참고용)
# =================================================================
echo "📋 WAS 설정 참고 파일 생성 중..."

cat > was-setup-guide.txt << 'EOF'
=== WebSphere Application Server JMS 설정 가이드 ===

1. JMS 리소스 생성 (WAS 관리콘솔):

   A) JMS Provider 생성:
      - Resources > JMS > JMS providers > New
      - Name: DefaultJMSProvider
      - Type: WebSphere embedded messaging

   B) ConnectionFactory 생성:
      - JMS providers > DefaultJMSProvider > Connection factories > New
      - Name: DefaultConnectionFactory  
      - JNDI name: jms/ConnectionFactory
      - Connection pool settings: Default

   C) Queue 생성:
      - JMS providers > DefaultJMSProvider > Queues > New
      - Name: TestQueue
      - JNDI name: jms/TestQueue

2. 애플리케이션 배포:
   - Applications > Install new application
   - producer.ear 업로드 및 설치
   - consumer.ear 업로드 및 설치

3. 애플리케이션 시작:
   - Enterprise Applications에서 두 앱 모두 시작

4. 테스트:
   - 브라우저에서 접속: http://server:port/producer/send?msg=테스트메시지
   - Consumer 로그에서 메시지 확인

주의사항:
- WAS 버전에 따라 설정 경로가 다를 수 있습니다
- Messaging Engine이 활성화되어 있어야 합니다
- 방화벽 설정을 확인하세요
EOF

# =================================================================
# 4. Maven 빌드 실행
# =================================================================
echo "🔨 Maven 빌드 시작..."

# Maven이 설치되어 있는지 확인
if ! command -v mvn &> /dev/null; then
    echo "❌ Maven이 설치되어 있지 않습니다. 다음 중 하나를 선택하세요:"
    echo "   1. Maven 설치: https://maven.apache.org/install.html"
    echo "   2. 또는 IDE에서 pom.xml 파일을 직접 빌드"
    echo "   3. 또는 Ant 빌드 스크립트 사용 (아래 ant-build.xml 참조)"
else
    echo "✓ Maven 발견됨. 빌드 진행..."
    
    # Producer 빌드
    echo "🔨 Producer 빌드 중..."
    cd producer
    mvn clean package
    if [ $? -eq 0 ]; then
        echo "✅ Producer 빌드 성공: producer/target/producer.ear"
        cp target/producer.ear ../producer.ear
    else
        echo "❌ Producer 빌드 실패"
    fi
    cd ..
    
    # Consumer 빌드
    echo "🔨 Consumer 빌드 중..."
    cd consumer
    mvn clean package
    if [ $? -eq 0 ]; then
        echo "✅ Consumer 빌드 성공: consumer/target/consumer.ear"
        cp target/consumer.ear ../consumer.ear
    else
        echo "❌ Consumer 빌드 실패"
    fi
    cd ..
fi

# =================================================================
# 5. 빌드 결과 및 사용법 안내
# =================================================================
echo ""
echo "🎉 === 빌드 완료! ==="
echo ""

if [ -f "producer.ear" ] && [ -f "consumer.ear" ]; then
    echo "✅ 생성된 EAR 파일:"
    echo "   📦 $(pwd)/producer.ear ($(du -h producer.ear | cut -f1))"
    echo "   📦 $(pwd)/consumer.ear ($(du -h consumer.ear | cut -f1))"
else
    echo "⚠️  EAR 파일이 생성되지 않았습니다. Maven 빌드를 수동으로 실행하세요:"
    echo "   cd producer && mvn clean package"
    echo "   cd consumer && mvn clean package"
fi

echo ""
echo "📂 생성된 프로젝트 구조:"
tree . 2>/dev/null || find . -type f | head -20

echo ""
echo "🚀 사용법:"
echo "1. WAS 관리콘솔에서 JMS 리소스 설정 (was-setup-guide.txt 참조)"
echo "2. producer.ear, consumer.ear을 WAS에 배포"
echo "3. 테스트: http://your-server:port/producer/send?msg=hello"
echo "4. consumer 로그에서 메시지 확인"
echo ""
echo "💡 참고: was-setup-guide.txt 파일에 상세한 WAS 설정 방법이 있습니다."

# 실행 권한 부여 안내
echo ""
echo "📋 이 스크립트 실행 방법:"
echo "   chmod +x setup.sh"
echo "   ./setup.sh"
EOF
