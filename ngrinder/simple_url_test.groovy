import static net.grinder.script.Grinder.grinder
import static org.junit.Assert.*
import static org.hamcrest.Matchers.*
import net.grinder.script.GTest
import net.grinder.script.Grinder
import net.grinder.scriptengine.groovy.junit.GrinderRunner
import net.grinder.scriptengine.groovy.junit.annotation.BeforeProcess
import net.grinder.scriptengine.groovy.junit.annotation.BeforeThread
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.ngrinder.http.HTTPRequest
import org.ngrinder.http.HTTPRequestControl
import org.ngrinder.http.HTTPResponse
import org.ngrinder.http.cookie.Cookie
import org.ngrinder.http.cookie.CookieManager
import groovy.json.JsonSlurper

// 이미 방문한 URL을 추적하기 위한 Set
import java.util.concurrent.ConcurrentHashMap
import java.util.regex.Matcher
import java.util.regex.Pattern

/**
 * URL 응답에서 모든 링크를 찾아 example.com 도메인을 포함하는 URL만 방문하는 테스트 스크립트
 *
 * @author admin
 */
@RunWith(GrinderRunner)
class TestRunner {
    public static GTest test
    public static HTTPRequest request
    public static Map<String, String> headers = [:]
    public static Map<String, Object> params = [:]
    public static List<Cookie> cookies = []
    
    // 방문한 URL을 추적하기 위한 ConcurrentHashMap 기반 Set
    public static Set<String> visitedUrls = Collections.newSetFromMap(new ConcurrentHashMap<String, Boolean>())
    
    // 크롤링할 도메인 설정
    public static final String TARGET_DOMAIN = "example.com"
    
    // 최대 방문 깊이
    public static final int MAX_DEPTH = 3
    
    // 링크 추출을 위한 정규표현식 패턴
    public static final Pattern HREF_PATTERN = Pattern.compile("<a\\s+[^>]*href=[\"']([^\"']+)[\"'][^>]*>", Pattern.CASE_INSENSITIVE)
    
    @BeforeProcess
    public static void beforeProcess() {
        HTTPRequestControl.setConnectionTimeout(300000)
        test = new GTest(1, "URL Crawler Test")
        request = new HTTPRequest()
        grinder.logger.info("before process.")
    }
    
    @BeforeThread
    public void beforeThread() {
        test.record(this, "test")
        grinder.statistics.delayReports = true
        grinder.logger.info("before thread.")
    }
    
    @Before
    public void before() {
        
		setHeaders([
            "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
			"accept-language": "ko,en;q=0.9,en-US;q=0.8",
			"user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
			"Referrer-Policy": "strict-origin-when-cross-origin",
			"accept-encoding": "gzip, deflate",  // 압축 허용
			"connection": "keep-alive"  // 연결 유지
		])
        
        request.setHeaders(headers)
        CookieManager.addCookies(cookies)
        grinder.logger.info("before. init headers and cookies")
    }
    
    @Test
    public void test() {
        // 초기 URL 설정 (테스트 대상 URL로 변경 필요)
        String initialUrl = "http://192.168.0.37:9011"
        
        // 초기 URL 방문 및 링크 크롤링 시작
        crawlUrl(initialUrl, 0)
    }
    
    /**
     * URL을 방문하고 링크를 추출하여 target 도메인이 포함된 링크를 재귀적으로 방문
     * 
     * @param url 방문할 URL
     * @param depth 현재 방문 깊이
     */
    private void crawlUrl(String url, int depth) {
        // 최대 깊이 체크
        if (depth > MAX_DEPTH) {
            return
        }
        
        // 이미 방문한 URL인지 확인
        if (visitedUrls.contains(url)) {
            return
        }
        
        // URL 방문 기록 추가
        visitedUrls.add(url)
        
        try {
            grinder.logger.info("Visiting URL: {}", url)
            
            // URL 방문
            HTTPResponse response = request.GET(url)
            
			// 응답 상태 코드 확인
			grinder.logger.info("Response status code: {}", response.statusCode);

			// 응답 헤더 확인
			grinder.logger.info("Response headers: {}", response.getHeaders());
			
            // 응답 상태 코드 확인
            if (response.statusCode == 200) {
                // 페이지 내용에서 링크 추출
                String htmlContent = new String(response.getBodyText())
				// response.getBody() 대신 아래 메서드들을 시도해 보세요
				//String htmlContent = response.getBodyText();  // 텍스트로 가져오기
				// 또는
				//String htmlContent = new String(response.getBodyBytes());  // 바이트 배열로 가져온 후 변환
				// 또는 (헤더 및 본문 모두 포함)
				//String fullResponse = response.getText();
				
                List<String> extractedUrls = extractLinks(htmlContent)
                
                // 추출된 링크 순회
                extractedUrls.each { href ->
                    String absoluteUrl = makeAbsoluteUrl(url, href)
                    
                    // TARGET_DOMAIN이 포함된 URL만 크롤링
                    if (absoluteUrl != null && absoluteUrl.contains(TARGET_DOMAIN)) {
                        // 재귀적으로 링크 방문
                        crawlUrl(absoluteUrl, depth + 1)
                    }
                }
                
                assertThat(response.statusCode, is(200))
            } else {
                grinder.logger.warn("Warning. The response may not be correct. The response code was {}.", response.statusCode)
            }
        } catch (Exception e) {
            grinder.logger.error("Error crawling URL {}: {}", url, e.message)
        }
    }
    
    /**
     * HTML 콘텐츠에서 링크 추출
     * 
     * @param htmlContent HTML 콘텐츠
     * @return 추출된 링크 목록
     */
    private List<String> extractLinks(String htmlContent) {
        List<String> links = new ArrayList<>()
        Matcher matcher = HREF_PATTERN.matcher(htmlContent)
        
        while (matcher.find()) {
            String href = matcher.group(1)
            if (href != null && !href.isEmpty()) {
                links.add(href)
            }
        }
        
        return links
    }
    
    /**
     * 상대 URL을 절대 URL로 변환
     * 
     * @param baseUrl 기준 URL
     * @param href 상대 또는 절대 URL
     * @return 절대 URL
     */
    private String makeAbsoluteUrl(String baseUrl, String href) {
        if (href == null || href.isEmpty() || href.startsWith("#") || href.startsWith("javascript:")) {
            return null
        }
        
        // 이미 절대 URL인 경우
        if (href.startsWith("http://") || href.startsWith("https://")) {
            return href
        }
        
        try {
            // baseUrl에서 도메인 추출
            URL url = new URL(baseUrl)
            String baseDomain = url.getProtocol() + "://" + url.getHost()
            if (url.getPort() != -1) {
                baseDomain += ":" + url.getPort()
            }
            
            // 상대 경로를 절대 경로로 변환
            if (href.startsWith("/")) {
                return baseDomain + href
            } else {
                String path = url.getPath()
                if (!path.endsWith("/")) {
                    // 마지막 경로 부분 제거
                    int lastSlash = path.lastIndexOf("/")
                    if (lastSlash != -1) {
                        path = path.substring(0, lastSlash + 1)
                    } else {
                        path = "/"
                    }
                }
                return baseDomain + path + href
            }
        } catch (Exception e) {
            grinder.logger.error("Error making absolute URL from {} and {}: {}", baseUrl, href, e.message)
            return null
        }
    }
    
    /**
     * HTTP 헤더를 설정하는 함수
     *
     * @param newHeaders 설정할 HTTP 헤더 (Map<String, String>)
     */
    static void setHeaders(Map<String, String> newHeaders) {
        headers.clear()
        headers.putAll(newHeaders)
    }
}
