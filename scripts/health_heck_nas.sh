#!/bin/bash
# 사용자 설정
MOUNT_PATHS=("/DATA_NAS1" "/DATA_NAS2")
NAS_IPS=("192.168.0.102" "192.168.0.101")
TEST_DIRS=("" "")
WEBHOOK_URL="https://api-health.itapi.org/api/mattermost/send"
CHANNEL="fep"
TITLE="NAS 관제"

# 내부 설정
LOG_FILE="./nas_health_multi.log"
FLAG_FILE="./health-check-nas-flag"
HOSTNAME=$(hostname)
FAILURE=0
SUCCESS_COUNT=0
TOTAL_COUNT=${#MOUNT_PATHS[@]}

# 마크다운 테이블 헤더
TABLE="| NAS IP | NAS VOLUME | MOUNT 경로 | 용량 | 연결상태 |\n|--------|-------------|--------------|--------|------------|"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$HOSTNAME] $1" >> "$LOG_FILE"
}

send_alert() {
    local text="$1"
    curl -s -X POST -H "Content-Type: application/json" -d "{
        \"channel\": \"$CHANNEL\",
        \"title\": \"$TITLE\",
        \"text\": \"$text\"
    }" "$WEBHOOK_URL" > /dev/null
}

get_flag_status() {
    if [ -f "$FLAG_FILE" ]; then
        cat "$FLAG_FILE"
    else
        echo "0" > "$FLAG_FILE"
        echo "0"
    fi
}

set_flag_status() {
    echo "$1" > "$FLAG_FILE"
}

# 기존 상태 확인
PREV_STATUS=$(get_flag_status)

for i in "${!MOUNT_PATHS[@]}"; do
    MP="${MOUNT_PATHS[$i]}"
    IP="${NAS_IPS[$i]}"
    SUBDIR="${TEST_DIRS[$i]}"
    TEST_DIR="$MP/$SUBDIR"
    TMP_FILE="$TEST_DIR/.tmp_nas_check_${HOSTNAME}_$$"
    
    STATUS="✅ 정상"
    USAGE="N/A"
    NAS_VOLUME="N/A"
    IS_SUCCESS=1
    
    START_TIME=$(date +%s.%N)
    
    # 1. 마운트 확인 (3초 타임아웃)
    if ! timeout 3s mountpoint -q "$MP"; then
        STATUS="❌ 마운트 확인 실패 (timeout 또는 비정상)"
        FAILURE=1
        IS_SUCCESS=0
    else
        # 2. NAS VOLUME 정보 (IP + 콜론 제거)
        RAW_VOLUME=$(awk -v path="$MP" '$2 == path {print $1}' /proc/mounts)
        NAS_VOLUME=$(echo "$RAW_VOLUME" | sed 's/^[^:]*://')  # 예: 192.168.0.102:/nfs1 → /nfs1
        [ -z "$NAS_VOLUME" ] && NAS_VOLUME="N/A"
        
        # 3. 디렉토리 존재 확인 (5초 타임아웃)
        if ! timeout 5s test -d "$TEST_DIR"; then
            STATUS="❌ 디렉토리 접근 실패 또는 타임아웃: $TEST_DIR"
            FAILURE=1
            IS_SUCCESS=0
        else
            # 4. 쓰기/읽기 테스트 (10초 타임아웃)
            if timeout 10s bash -c "echo 'NAS health check test' > '$TMP_FILE'" 2>/dev/null; then
                # 쓰기 성공 - 읽기 테스트 (5초 타임아웃)
                if timeout 5s bash -c "READ=\$(cat '$TMP_FILE' 2>/dev/null); [[ \"\$READ\" == 'NAS health check test' ]]"; then
                    # 읽기도 성공
                    timeout 3s rm -f "$TMP_FILE" 2>/dev/null
                else
                    STATUS="❌ 읽기 실패 또는 타임아웃"
                    FAILURE=1
                    IS_SUCCESS=0
                    timeout 3s rm -f "$TMP_FILE" 2>/dev/null
                fi
            else
                # 쓰기 실패 - 원인 분석
                EXIT_CODE=$?
                if [ $EXIT_CODE -eq 124 ]; then
                    STATUS="❌ 쓰기 타임아웃 (NAS 장애 의심)"
                else
                    if timeout 3s test -w "$TEST_DIR"; then
                        STATUS="❌ 쓰기 실패 (알 수 없는 오류)"
                    else
                        STATUS="❌ 쓰기 권한 없음 (Read-only 또는 Permission 오류)"
                    fi
                fi
                FAILURE=1
                IS_SUCCESS=0
            fi
            
            # 5. 응답 시간 체크
            END_TIME=$(date +%s.%N)
            ELAPSED=$(echo "$END_TIME - $START_TIME" | bc)
            if (( $(echo "$ELAPSED > 3.0" | bc -l) )); then
                if [[ "$STATUS" == "✅ 정상" ]]; then
                    STATUS="❌ 지연 응답 (${ELAPSED}s)"
                    FAILURE=1
                    IS_SUCCESS=0
                fi
            fi
            
            # 6. 용량 정보 (3초 타임아웃)
            USAGE=$(timeout 3s df -h "$MP" 2>/dev/null | awk 'NR==2 {print $2 "/" $3 " (" $5 ")"}')
            [ -z "$USAGE" ] && USAGE="N/A"
        fi
    fi
    
    # 성공 카운트 증가
    [[ "$IS_SUCCESS" -eq 1 ]] && SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    
    # 테이블 행 추가
    TABLE="${TABLE}\n| $IP | $NAS_VOLUME | $MP | $USAGE | $STATUS |"
done

# 결과 전송
if [ "$SUCCESS_COUNT" -ne "$TOTAL_COUNT" ]; then
    # 장애 상태
    MESSAGE="❌ **[심각] NAS 상태 요약**\n- 총 대상: $TOTAL_COUNT\n- 성공: $SUCCESS_COUNT\n- 실패: $((TOTAL_COUNT - SUCCESS_COUNT))\n\n$TABLE"
    log "NAS 장애 발생:\n$MESSAGE"
    send_alert "🚨 **NAS 장애 발생**\n\n$MESSAGE"
    set_flag_status "1"
    exit 1
else
    # 정상 상태
    if [ "$PREV_STATUS" = "1" ]; then
        # 장애에서 정상으로 복구됨 - 복구 알림 전송
        MESSAGE="✅ **[해제] NAS 상태 요약**\n- 총 대상: $TOTAL_COUNT\n- 성공: $SUCCESS_COUNT\n- 실패: $((TOTAL_COUNT - SUCCESS_COUNT))\n\n$TABLE"
        log "NAS 장애 복구:\n$MESSAGE"
        send_alert "✅ **NAS 장애 복구**\n\n$MESSAGE"
        set_flag_status "0"
        exit 0
    else
        # 계속 정상 상태 - 알림 전송하지 않음
        log "NAS 정상 상태 유지"
        set_flag_status "0"
        exit 0
    fi
fi
