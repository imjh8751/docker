#!/bin/bash

URLS=("https://m.kblife.co.kr" "https://www.kblife.co.kr" "https://sfa.kblife.co.kr")
TIMEOUT=40

GOTIFY_API_TOKEN="AVgIKiVH2cGfb4b"
TELEGRAM_BOT_TOKEN="6251622378:AAHMLv4GfSxFOdyVB0OZ3laOcmo1vJRveTk"
TELEGRAM_CHAT_ID="5749876184"
MATTERMOST_WEBHOOK="https://mattermost.itapi.org/hooks/jrrtz45djpbu98buet71tk39bc"
ROCKETCHAT_WEBHOOK_URL="https://rocketchat.itapi.org/hooks/65aa62890bac3077646a7076/FMiNL4M28P2WyvBo8je6xGTn4RxqRXNDYvgLoTTvX9T6D75J"

for URL in "${URLS[@]}"; do
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $URL --max-time $TIMEOUT)

  # Measure start time
  START_TIME=$(date +%s.%N)
  # Measure end time
  END_TIME=$(date +%s.%N)
  # Calculate elapsed time
  ELAPSED_TIME=$(echo "$END_TIME - $START_TIME" | bc)

  if [ $RESPONSE -eq 200 ] || [ $RESPONSE -eq 302 ]; then
  #if [ $RESPONSE -eq 200 ]; then
    echo "Success: HTTP $RESPONSE OK from $URL $ELAPSED_TIME"
  else
    MESSAGE="HTTP $RESPONSE and Abnormal Response from $URL / Loading Time : $ELAPSED_TIME"

    # Gotify
    curl -X POST "https://gotify.itapi.org/message?token=$GOTIFY_API_TOKEN" -F "title=Notification" -F "message=$MESSAGE"
    # Telegram
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d "chat_id=$TELEGRAM_CHAT_ID" -d "text=$MESSAGE"
    # Mattermost
    curl -X POST -H 'Content-Type: application/json' -d '{"text":"'"$MESSAGE"'"}' $MATTERMOST_WEBHOOK
    # rocket.chat
    curl -X POST -H 'Content-Type: application/json' -d '{"text": "'"${MESSAGE}"'"}' ${ROCKETCHAT_WEBHOOK_URL}
  fi
done
