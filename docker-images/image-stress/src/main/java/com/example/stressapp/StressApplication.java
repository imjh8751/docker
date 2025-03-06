package com.example.stressapp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@SpringBootApplication
public class StressApplication {
    public static void main(String[] args) {
        SpringApplication.run(StressApplication.class, args);
    }
}

/**
 * CPU 부하 테스트를 위한 컨트롤러
 */
@RestController
@RequestMapping("/api/cpu")
class CpuStressController {

    private final ExecutorService executorService = Executors.newCachedThreadPool();

    @GetMapping("/stress")
    public String stressCpu(@RequestParam(defaultValue = "4") int threads,
                           @RequestParam(defaultValue = "30") int durationSeconds) {
        
        for (int i = 0; i < threads; i++) {
            executorService.submit(() -> {
                long endTime = System.currentTimeMillis() + (durationSeconds * 1000);
                while (System.currentTimeMillis() < endTime) {
                    // CPU를 최대한 사용하는 연산 수행
                    for (int j = 0; j < 1000000; j++) {
                        Math.sin(Math.sqrt(Math.pow(Math.random() * 100, 2)));
                    }
                }
            });
        }
        
        return "CPU 부하 테스트가 시작되었습니다. 스레드 수: " + threads + ", 지속 시간: " + durationSeconds + "초";
    }

    @GetMapping("/status")
    public String status() {
        return "CPU 부하 테스트 서비스 정상 동작 중";
    }
}

/**
 * 메모리 부하 테스트를 위한 컨트롤러
 */
@RestController
@RequestMapping("/api/memory")
class MemoryStressController {

    // 메모리 누수를 위한 전역 리스트 (GC에서 회수되지 않음)
    private static final List<byte[]> memoryLeakList = new ArrayList<>();

    @GetMapping("/stress")
    public String stressMemory(@RequestParam(defaultValue = "10") int megabytes,
                              @RequestParam(defaultValue = "false") boolean causeOom) {
        
        try {
            // 요청된 크기의 메모리 할당
            int allocations = megabytes;
            
            for (int i = 0; i < allocations; i++) {
                // 1MB 크기의 바이트 배열 할당
                byte[] memory = new byte[1024 * 1024];
                memoryLeakList.add(memory);
            }
            
            // OOM을 즉시 발생시키려면 남은 메모리를 최대한 사용
            if (causeOom) {
                while (true) {
                    byte[] memory = new byte[1024 * 1024 * 10]; // 10MB씩 계속 할당
                    memoryLeakList.add(memory);
                }
            }
            
            return megabytes + "MB의 메모리가 할당되었습니다. 현재 총 할당: " + memoryLeakList.size() + "MB";
        } catch (OutOfMemoryError e) {
            return "메모리 부족 오류(OOM) 발생: " + e.getMessage();
        }
    }

    @GetMapping("/clear")
    public String clearMemory() {
        int freedMemory = memoryLeakList.size();
        memoryLeakList.clear();
        System.gc(); // GC 요청
        return freedMemory + "MB의 메모리가 해제되었습니다.";
    }

    @GetMapping("/status")
    public String status() {
        return "메모리 부하 테스트 서비스 정상 동작 중";
    }
}

/**
 * 기본 상태 확인 엔드포인트
 */
@RestController
class HealthController {
    
    @GetMapping("/health")
    public String health() {
        return "시스템 정상 동작 중";
    }
    
    @GetMapping("/")
    public String home() {
        return "부하 테스트 애플리케이션이 실행 중입니다. 사용 가능한 엔드포인트:\n" +
               "- /api/cpu/stress: CPU 부하 테스트\n" +
               "- /api/memory/stress: 메모리 부하 테스트\n" +
               "- /api/memory/clear: 할당된 메모리 해제\n" +
               "- /health: 시스템 상태 확인";
    }
}
