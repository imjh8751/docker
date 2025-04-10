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
* example.com 도메인의 정적 리소스 확장자(.css, .js, .jpg 등)를 가진 URL만 크롤링하는 테스트 스크립트
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
    public static final String TARGET_DOMAIN = "twww.kblife.co.kr"
   
    // 최대 방문 깊이
    public static final int MAX_DEPTH = 3
   
    // 정적 리소스 확장자 목록
    public static final List<String> STATIC_EXTENSIONS = [
        ".css", ".js", ".jpg", ".jpeg", ".png", ".gif", ".svg", ".webp",
        ".woff", ".woff2", ".ttf", ".eot", ".otf", ".ico", ".pdf", ".mp3", ".mp4"
    ]
   
    // HTML에서 리소스 URL을 추출하기 위한 패턴들
    public static final Pattern CSS_PATTERN = Pattern.compile("<link[^>]*href=[\"']([^\"']+)[\"'][^>]*>", Pattern.CASE_INSENSITIVE)
    public static final Pattern JS_PATTERN = Pattern.compile("<script[^>]*src=[\"']([^\"']+)[\"'][^>]*>", Pattern.CASE_INSENSITIVE)
    public static final Pattern IMG_PATTERN = Pattern.compile("<img[^>]*src=[\"']([^\"']+)[\"'][^>]*>", Pattern.CASE_INSENSITIVE)
    public static final Pattern BACKGROUND_PATTERN = Pattern.compile("url\\([\"']?([^\"'\\)]+)[\"']?\\)", Pattern.CASE_INSENSITIVE)
    public static final Pattern SOURCE_PATTERN = Pattern.compile("<source[^>]*src=[\"']([^\"']+)[\"'][^>]*>", Pattern.CASE_INSENSITIVE)
   
    @BeforeProcess
    public static void beforeProcess() {
        HTTPRequestControl.setConnectionTimeout(300000)
        test = new GTest(1, "Static Resources Crawler Test")
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
                                "connection": "keep-alive"  // 연결 유지
        ])
       
        request.setHeaders(headers)
        CookieManager.addCookies(cookies)
        grinder.logger.info("before. init headers and cookies")
    }
   
    @Test
    public void test() {
        // 초기 URL 설정 (example.com의 메인 페이지로 시작)
        String initialUrl = https://twww.kblife.co.kr
       
        // 초기 URL 방문하여 정적 리소스 수집 시작
        processPage(initialUrl, 0)
    }
   
    /**
     * HTML 페이지를 방문하여 정적 리소스를 추출하고 호출하는 메서드
     *
     * @param url 방문할 URL
     * @param depth 현재 방문 깊이
     */
    private void processPage(String url, int depth) {
        // 최대 깊이 체크
        if (depth > MAX_DEPTH) {
            return
        }
       
        // 이미 방문한 URL인지 확인
        if (visitedUrls.contains(url)) {
            return
        }
       
        // example.com 도메인이 아닌 경우 무시
        if (!url.contains(TARGET_DOMAIN)) {
            return
        }
       
        // URL 방문 기록 추가
        visitedUrls.add(url)
       
        try {
            grinder.logger.info("Processing HTML page: {}", url)
           
            // URL 방문
            HTTPResponse response = request.GET(url)
           
            // 응답 상태 코드 확인
            grinder.logger.info("Response status code: {}", response.statusCode)
           
            if (response.statusCode == 200) {
                // 페이지 내용에서 모든 리소스 URL 추출
                String htmlContent = new String(response.getBodyText())
                List<String> resourceUrls = extractResourceUrls(htmlContent)
                grinder.logger.info("resourceUrls: {}개 {}", resourceUrls.size(), resourceUrls)
               
                // 정적 리소스만 필터링하여 요청
                resourceUrls.each { resourceUrl ->
                    String absoluteUrl = makeAbsoluteUrl(url, resourceUrl)
                   
                    if (absoluteUrl != null &&
                        absoluteUrl.contains(TARGET_DOMAIN) &&
                        isStaticResource(absoluteUrl)) {
                       
                        // 해당 URL이 아직 방문하지 않은 정적 리소스인 경우에만 요청
                        if (!visitedUrls.contains(absoluteUrl)) {
                            fetchStaticResource(absoluteUrl)
                        }
                    }
                }
               
                // HTML 페이지에서 다른 HTML 페이지 링크를 찾아 재귀적으로 탐색
                /*if (depth < MAX_DEPTH) {
                    List<String> htmlLinks = extractHtmlLinks(htmlContent)
                    htmlLinks.each { link ->
                        String absoluteLink = makeAbsoluteUrl(url, link)
                        if (absoluteLink != null &&
                            absoluteLink.contains(TARGET_DOMAIN) &&
                            !isStaticResource(absoluteLink)) {
                            processPage(absoluteLink, depth + 1)
                        }
                    }
                }*/
               
                assertThat(response.statusCode, is(200))
            } else {
                grinder.logger.warn("Warning. Failed to process page. The response code was {}.", response.statusCode)
            }
        } catch (Exception e) {
            grinder.logger.error("Error processing page {}: {}", url, e.message)
        }
    }
   
    /**
     * 정적 리소스 URL을 실제로 요청하는 메서드
     *
     * @param url 요청할 정적 리소스 URL
     */
    private void fetchStaticResource(String url) {
        try {
            visitedUrls.add(url)
            grinder.logger.info("Fetching static resource: {}", url)
           
            HTTPResponse response = request.GET(url)
           
            grinder.logger.info("Static resource fetched: {} (Status: {})", url, response.statusCode)
           
            if (response.statusCode == 200) {
                grinder.logger.info("Successfully fetched static resource: {}", url)
            } else {
                grinder.logger.warn("Warning. Failed to fetch static resource: {} (Status: {})", url, response.statusCode)
            }
        } catch (Exception e) {
            grinder.logger.error("Error fetching static resource {}: {}", url, e.message)
        }
    }
   
    /**
     * HTML 페이지에서 다른 HTML 페이지 링크를 추출하는 메서드
     *
     * @param htmlContent HTML 콘텐츠
     * @return HTML 페이지 링크 목록
     */
    private List<String> extractHtmlLinks(String htmlContent) {
        List<String> links = new ArrayList<>()
        Pattern pattern = Pattern.compile("<a\\s+[^>]*href=[\"']([^\"']+)[\"'][^>]*>", Pattern.CASE_INSENSITIVE)
        Matcher matcher = pattern.matcher(htmlContent)
       
        while (matcher.find()) {
            String href = matcher.group(1)
            if (href != null && !href.isEmpty() &&
                !href.startsWith("#") &&

               !href.startsWith("javascript:") &&
                !isStaticResource(href)) {
                links.add(href)
            }
        }
       
        return links
    }
   
    /**
     * HTML 페이지에서 모든 유형의 리소스 URL을 추출하는 메서드
     *
     * @param htmlContent HTML 콘텐츠
     * @return 추출된 리소스 URL 목록
     */
    private List<String> extractResourceUrls(String htmlContent) {
        Set<String> urls = new HashSet<>()


        // CSS 파일 추출
        addMatchesToList(CSS_PATTERN.matcher(htmlContent), urls, 1)
       
        // JavaScript 파일 추출
        addMatchesToList(JS_PATTERN.matcher(htmlContent), urls, 1)
       
        // 이미지 파일 추출
        addMatchesToList(IMG_PATTERN.matcher(htmlContent), urls, 1)
       
        // CSS 내 배경 이미지 URL 추출
        addMatchesToList(BACKGROUND_PATTERN.matcher(htmlContent), urls, 1)
       
        // source 태그의 src 속성 추출 (비디오, 오디오 등)
        addMatchesToList(SOURCE_PATTERN.matcher(htmlContent), urls, 1)
       
        return new ArrayList<>(urls)
    }
   
    /**
     * 패턴 매칭 결과를 리스트에 추가하는 헬퍼 메서드
     */
    private void addMatchesToList(Matcher matcher, Set<String> list, int group) {
        while (matcher.find()) {
            String url = matcher.group(group)
            if (url != null && !url.isEmpty()) {
                list.add(url)
            }
        }
    }
   
    /**
     * 주어진 URL이 정적 리소스인지 확인하는 메서드
     *
     * @param url 확인할 URL
     * @return 정적 리소스 여부
     */
    private boolean isStaticResource(String url) {
        if (url == null || url.isEmpty()) {
            return false
        }
       
        // URL에 쿼리 파라미터가 있는 경우 제거 (예: .css?v=123)
        String cleanUrl = url
        int queryIndex = cleanUrl.indexOf('?')
        if (queryIndex > 0) {
            cleanUrl = cleanUrl.substring(0, queryIndex)
        }
       
        // 정적 리소스 확장자 확인
        for (String ext : STATIC_EXTENSIONS) {
            if (cleanUrl.toLowerCase().endsWith(ext)) {
                return true
            }
        }
       
        return false
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
        if (href.startsWith(http://) || href.startsWith(https://)) {
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
