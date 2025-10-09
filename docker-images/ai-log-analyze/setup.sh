#!/bin/bash
set -euo pipefail

# =================================================================
# 1. ⚙️ 전역 설정 및 변수 선언 (최상위 변수 유지 및 재활용)
# =================================================================

# 프로젝트 기본 정보
PROJECT_NAME="log-analyzer-agent"
NODE_VERSION="22"
PORT="13333"

# Docker 설정
DOCKER_IMAGE_NAME="${PROJECT_NAME}"
DOCKER_CONTAINER_NAME="${PROJECT_NAME}-container"
DOCKER_NETWORK="${PROJECT_NAME}-net"
DOCKER_BASE_IMAGE="node:${NODE_VERSION}-alpine"

# AI 및 서비스 설정
# Gemini 적용 가능한 다른 모델: gemini-2.5-pro (고성능, 고비용), gemini-2.5-flash (기본 권장)
GEMINI_MODEL="gemini-2.5-flash"

# Claude 적용 가능한 다른 모델 (2025년 9월 기준):
# - 최고 성능: claude-3-opus-20240229, claude-3-5-sonnet (최신, 균형)
# - 균형/표준: claude-3-sonnet-20240229
# - 빠르고 경량: claude-3-haiku-20240307 (기본 권장)
CLAUDE_MODEL="claude-4-5-sonnet"

# Ollama 적용 가능한 다른 모델 예시 (로컬 설치된 모델명을 사용):
# - 고성능/표준: llama3:8b (기본 권장), llama3.2:1b (경량)
# - 경량/빠른 분류: qwen2.5:0.5b, qwen2.5:1.5b, phi3:mini, gemma:2b
OLLAMA_MODEL="qwen2.5:0.5b"
OLLAMA_HOST="http://192.168.0.100:11434"
BATCH_ENGINE="gemini" 

# 시스템 설정
MAX_CONCURRENT_REQUESTS="5"
LOG_LEVEL="info"
BATCH_INTERVAL="*/30 * * * *"
MAX_LOG_FILES="10"
MAX_LOG_SIZE_MB="0.1"
STREAM_CHUNK_SIZE="65536"
BATCH_SIZE="100"

# 민감 정보 (Placeholder)
GEMINI_API_KEY_PLACEHOLDER="AIzaSyDnfexvMNkS-"
CLAUDE_API_KEY_PLACEHOLDER="sk-ant-api03-"
MATTERMOST_WEBHOOK_URL_PLACEHOLDER="https://mattermost.org/hooks/"

# 종속성 버전
EXPRESS_VERSION="^4.21.2"
AXIOS_VERSION="^1.7.8"
WINSTON_VERSION="^3.16.0"
JOI_VERSION="^17.9.1"
GLOB_VERSION="^10.4.5"
CORS_VERSION="^2.8.5"
HELMET_VERSION="^8.1.0"
NODE_SCHEDULE_VERSION="^2.1.1"
P_LIMIT_VERSION="^5.0.0"
GOOGLE_GEMINI_SDK_VERSION="^0.17.0"

# 디렉토리 경로
BASE_DIR="$(pwd)/${PROJECT_NAME}"
SRC_DIR="${BASE_DIR}/src"
LOGS_DIR="${BASE_DIR}/logs"
SCRIPTS_DIR="${BASE_DIR}/scripts"
VOLUMES_DIR="${BASE_DIR}/volumes"
CONFIG_DIR="${VOLUMES_DIR}/config"
STATE_DIR="${VOLUMES_DIR}/state"


# =================================================================
# 2. 📁 디렉토리 구조 및 초기화
# =================================================================

echo "🚀 1단계: 프로젝트 디렉토리 및 초기 파일 생성 시작..."

rm -rf "$BASE_DIR" # 이전 디렉토리 완전 삭제

# 디렉토리 생성
mkdir -p "$BASE_DIR"
mkdir -p "${SRC_DIR}"/{utils,services,routes,middleware}
mkdir -p "${LOGS_DIR}"/{nginx,api-server,auth-service}
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$STATE_DIR"
echo "   -> 기본 디렉토리 구조 생성 완료."


# =================================================================
# 3. 📝 config.json 파일 생성 (사용자가 제공한 내용 그대로 반영)
# =================================================================

echo "3. config.json (전역 설정 파일) 생성 중..."
cat << EOF_CONFIG_JSON > "${CONFIG_DIR}/config.json"
{
  "api": {
    "port": ${PORT},
    "logLevel": "${LOG_LEVEL}",
    "maxConcurrentRequests": ${MAX_CONCURRENT_REQUESTS}
  },
  "logProcessing": {
    "maxLogFiles": ${MAX_LOG_FILES},
    "maxLogSizeMB": ${MAX_LOG_SIZE_MB},
    "streamChunkSize": ${STREAM_CHUNK_SIZE},
    "batchSize": ${BATCH_SIZE},
    "batchInterval": "${BATCH_INTERVAL}",
    "batchEngine": "${BATCH_ENGINE}"
  },
  "appLogPaths": {
    "nginx": [
      "/var/logs/nginx/*.log"
    ],
    "api-server": [
      "/var/logs/api-server/*.log"
    ]
  },
  "ai": {
    "geminiApiKey": "${GEMINI_API_KEY_PLACEHOLDER}",
    "claudeApiKey": "${CLAUDE_API_KEY_PLACEHOLDER}",
    "ollamaHost": "${OLLAMA_HOST}",
    "geminiModel": "${GEMINI_MODEL}",
    "claudeModel": "${CLAUDE_MODEL}",
    "ollamaModel": "${OLLAMA_MODEL}"
  },
  "mattermost": {
    "webhookUrl": "${MATTERMOST_WEBHOOK_URL_PLACEHOLDER}",
    "enabled": true
  }
}
EOF_CONFIG_JSON
echo "   -> volumes/config/config.json 생성 완료."


# =================================================================
# 4. 📝 메타 파일 생성 및 Docker Compose
# =================================================================

# .gitignore 파일
cat << 'EOF_GITIGNORE' > "${BASE_DIR}/.gitignore"
node_modules/
dist/
.env
volumes/state/*
EOF_GITIGNORE

# package.json 파일
cat << EOF_PACKAGE_JSON > "${BASE_DIR}/package.json"
{
    "name": "${PROJECT_NAME}",
    "version": "1.0.0",
    "description": "Multi-LLM Log Analysis AI Agent with Mattermost reporting",
    "main": "src/index.js",
    "scripts": {
        "start": "node src/index.js"
    },
    "dependencies": {
        "express": "${EXPRESS_VERSION}",
        "axios": "${AXIOS_VERSION}",
        "winston": "${WINSTON_VERSION}",
        "joi": "${JOI_VERSION}",
        "glob": "${GLOB_VERSION}",
        "cors": "${CORS_VERSION}",
        "helmet": "${HELMET_VERSION}",
        "node-schedule": "${NODE_SCHEDULE_VERSION}",
        "p-limit": "${P_LIMIT_VERSION}",
        "@google/generative-ai": "${GOOGLE_GEMINI_SDK_VERSION}"
    },
    "author": "",
    "license": "ISC"
}
EOF_PACKAGE_JSON

# Dockerfile
cat << EOF_DOCKERFILE > "${BASE_DIR}/Dockerfile"
FROM ${DOCKER_BASE_IMAGE} AS base

RUN apk add --no-cache bash

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev

COPY src src
# config.json 및 state.json은 볼륨 마운트되므로 복사하지 않음

# 로그 파일 접근 경로 (볼륨 마운트의 대상이 됨)
RUN mkdir -p /var/logs

EXPOSE ${PORT}
CMD [ "npm", "start" ]
EOF_DOCKERFILE

# docker-compose.yml 파일
cat << EOF_DOCKER_COMPOSE > "${BASE_DIR}/docker-compose.yml"
services:
  ${PROJECT_NAME}:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: ${DOCKER_CONTAINER_NAME}
    image: ${DOCKER_IMAGE_NAME}
    restart: unless-stopped
    networks:
      - ${DOCKER_NETWORK}
    ports:
      - "${PORT}:${PORT}"
    
    volumes:
      # 1. 설정 파일 유동성 확보: 호스트 config.json을 컨테이너 루트로 마운트
      - ./volumes/config/config.json:/app/config.json 
      
      # 2. 상태 파일 영속성 확보
      - ./volumes/state:/app/state 
      
      # 3. 로그 파일 접근 (호스트 logs 디렉토리를 컨테이너의 /var/logs로 마운트)
      - /opt/npmplus/nginx:/var/logs/nginx
    
networks:
  ${DOCKER_NETWORK}:
    driver: bridge
EOF_DOCKER_COMPOSE

# 로그 파일 생성 (테스트용)
cat << 'EOF_LOG1' > "${LOGS_DIR}/nginx/access.log"
2025-09-28 10:00:01 [INFO] Nginx: GET /index.html 200 (File exists)
2025-09-28 10:00:02 [ERROR] Nginx: Backend service timeout on /data endpoint.
EOF_LOG1
cat << 'EOF_LOG2' > "${LOGS_DIR}/nginx/error_critical.log"
2025-09-28 10:00:05 [CRITICAL] Nginx: Configuration reload failed, using old settings.
EOF_LOG2
cat << 'EOF_LOG3' > "${LOGS_DIR}/api-server/server.log"
2025-09-28 10:00:07 [WARN] APIServer: Database query slow (550ms).
EOF_LOG3

echo "✅ 1단계 완료: 메타 파일 및 기본 설정 파일 생성 완료."

## 5. 💻 Node.js 소스 코드 생성 (모든 소스 파일 포함)

echo "💻 2단계: 핵심 소스 코드 (모든 파일) 생성 시작..."

# 1. src/utils/config.js (config.json 로드)
cat << 'EOF_CONFIG' > "${SRC_DIR}/utils/config.js"
// src/utils/config.js (JSON 로드 버전)

const path = require('path');
const fs = require('fs');

// 마운트된 config.json 파일의 경로 (컨테이너 내부 경로)
const CONFIG_FILE_PATH = path.resolve(__dirname, '../../config.json'); 
let config = {};

try {
    // 동기적으로 JSON 파일 로드
    const rawData = fs.readFileSync(CONFIG_FILE_PATH, 'utf8');
    config = JSON.parse(rawData);
    
    // 기본 앱 목록을 appLogPaths의 키를 사용하여 동적으로 구성
    config.defaultApps = Object.keys(config.appLogPaths)
        .filter(app => config.appLogPaths[app].length > 0);

} catch (error) {
    console.error(`🚨 FATAL: Could not load or parse config file at ${CONFIG_FILE_PATH}`);
    console.error(`Error details: ${error.message}`);
    process.exit(1); 
}

module.exports = config;
EOF_CONFIG

# 2. src/utils/logger.js (config.json에서 레벨 설정)
cat << 'EOF_LOGGER' > "${SRC_DIR}/utils/logger.js"
const { createLogger, format, transports } = require('winston');
const config = require('./config');

const logger = createLogger({
    // 💡 config.json에서 로그 레벨 설정
    level: config.api.logLevel || 'info',
    format: format.combine(
        format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
        format.errors({ stack: true }),
        format.splat(),
        format.json()
    ),
    transports: [
        new transports.Console({
            format: format.combine(format.colorize(), format.simple())
        })
    ],
    exceptionHandlers: [
        new transports.Console({
            format: format.combine(format.colorize(), format.simple())
        })
    ]
});

module.exports = logger;
EOF_LOGGER

# 3. src/utils/validator.js
cat << 'EOF_VALIDATOR' > "${SRC_DIR}/utils/validator.js"
const Joi = require('joi');

const analyzeSchema = Joi.object({
    apps: Joi.array().items(Joi.string()).min(1).required(),
    engine: Joi.string().valid('gemini', 'ollama', 'claude').required()
});

const validateAnalyzeRequest = (data) => {
    return analyzeSchema.validate(data);
};

module.exports = {
    validateAnalyzeRequest
};
EOF_VALIDATOR

# 4. src/services/stateManager.js (볼륨 마운트를 위해 인메모리 방식 유지)
cat << 'EOF_STATE_MANAGER' > "${SRC_DIR}/services/stateManager.js"
const logger = require('../utils/logger');
const fs = require('fs');
const path = require('path');

// 💡 볼륨 마운트된 상태 파일 경로
const STATE_FILE = path.resolve(__dirname, '../../state/state.json');
let logAnalysisState = {};

const loadState = () => {
    if (!fs.existsSync(STATE_FILE)) {
        logger.info('[StateManager] State file not found. Initializing new state.');
        return;
    }
    try {
        const rawData = fs.readFileSync(STATE_FILE, 'utf8');
        logAnalysisState = JSON.parse(rawData);
        logger.info(`[StateManager] State loaded successfully. ${Object.keys(logAnalysisState).length} markers found.`);
    } catch (error) {
        logger.error(`[StateManager] Failed to load state: ${error.message}. Resetting to empty state.`);
        logAnalysisState = {};
    }
};

const saveState = () => {
    try {
        const dir = path.dirname(STATE_FILE);
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
        fs.writeFileSync(STATE_FILE, JSON.stringify(logAnalysisState, null, 2), 'utf8');
    } catch (error) {
        logger.error(`[StateManager] Failed to save state to ${STATE_FILE}: ${error.message}`);
    }
};

// --- API ---

const getLastMarker = (logIdentifier) => {
    return logAnalysisState[logIdentifier] || 0;
};

const updateMarker = (logIdentifier, newMarker) => {
    if (newMarker > getLastMarker(logIdentifier)) {
        logAnalysisState[logIdentifier] = newMarker;
        // 💡 마커 업데이트 시 파일에 저장
        saveState(); 
        logger.debug(`[StateManager] Updated marker for ${logIdentifier} to ${newMarker}`);
    }
};

const resetState = () => {
    const previousStateCount = Object.keys(logAnalysisState).length;
    logAnalysisState = {};
    saveState(); // 초기화 후 파일에 저장
    logger.info(`[StateManager] Log analysis state has been reset. Cleared ${previousStateCount} markers.`);
    return previousStateCount;
};

const getStateSnapshot = () => {
    return { ...logAnalysisState };
};

// 서비스 시작 시 상태 로드
loadState();

module.exports = {
    getLastMarker,
    updateMarker,
    resetState,
    getStateSnapshot,
};
EOF_STATE_MANAGER

cat << 'EOF_REPORT_GENERATOR' > "${SRC_DIR}/services/reportGenerator.js"
const logger = require('../utils/logger');

/**
 * AI 분석 결과를 최종 사용자에게 전달하거나 파일로 저장하는 역할을 합니다.
 * 현재는 콘솔에 출력하는 역할만 수행합니다.
 * @param {string} analysisResult logAnalyzer.js에서 반환된 Markdown 분석 결과
 */
const generateAndOutputReport = async (analysisResult) => {
    logger.info('--- 📊 AI Log Analysis Report (Markdown Table) ---');
    console.log(analysisResult);
    logger.info('--- End of Report ---');
};

module.exports = {
    generateAndOutputReport,
};
EOF_REPORT_GENERATOR

# 5. src/services/logAnalyzer.js
cat << 'EOF_LOG_ANALYZER' > "${SRC_DIR}/services/logAnalyzer.js"
const { GoogleGenerativeAI } = require('@google/generative-ai');
const axios = require('axios');
const logger = require('../utils/logger');
const config = require('../utils/config');

// config.json의 구조가 다르므로, 이전에 사용된 config 구조에 맞춰 임시적으로 값을 조정
// analyzeLogs 함수의 인수에 맞추기 위해 config.ai 구조 대신 config.gemini 등을 사용해야 합니다.

// Markdown 테이블 추출기: 최소한의 유효성 검사만 수행
const extractMarkdownTable = (text) => {
    if (!text || typeof text !== 'string') return '';
    
    const rawText = text.trim();
    const lines = rawText.split(/\r?\n/).filter(line => line.trim() !== '');
    if (lines.length < 2) return ''; // 최소한 두 줄 (헤더와 구분선) 필요
    return rawText;
};

// Gemini 응답에서 텍스트를 안전하게 추출
const getFirstAvailableText = (resp) => {
    if (!resp) return null;

    // 최상위 text 확인 (Google SDK의 경우 response.text 사용)
    const candidates = resp.candidates || [];
    for (const candidate of candidates) {
        const parts = candidate?.content?.parts || [];
        for (const part of parts) {
            if (typeof part?.text === 'string' && part.text.trim() !== '') {
                return part.text.trim();
            }
        }
    }

    return null;
};


const analyzeLogs = async (engine, logContent) => {
    // 💡 참고: config.json이 config.ai 구조를 사용하므로, 
    // 여기서는 기존 config.gemini 대신 config.ai를 사용하도록 변경합니다.
    const GEMINI_API_KEY = config.ai.geminiApiKey;
    const GEMINI_MODEL = config.ai.geminiModel;
    const CLAUDE_API_KEY = config.ai.claudeApiKey;
    const CLAUDE_MODEL = config.ai.claudeModel;
    const OLLAMA_HOST = config.ai.ollamaHost;
    const OLLAMA_MODEL = config.ai.ollamaModel;

    const prompt = `당신은 로그 분석 전문가 AI입니다. 다음 애플리케이션 로그를 분석하세요.
오류, 경고, 성능 문제, 주요 보안 이벤트에 집중하세요.
로그는 여러 애플리케이션에서 가져온 것이며, 각 경로가 명확하게 표시되어 있습니다.
AI 응답은 반드시 **Markdown 표** 형태로만 반환해야 하며, **추가 설명, 헤더, 텍스트는 포함하지 마세요**.
표는 다음 열을 반드시 포함해야 합니다 (상태에는 적절한 이모지 사용):
| 로그 경로 | 상태 | 설명 | 권장 조치 |
|-------------------------|----------|--------------|--------------|
| /var/logs/app/file1.log | 🔴 높음 | 오류 세부 정보 | 해결책 |

Analyze this log content:
---LOG START---
${logContent}
---LOG END---`;

    try {
        let rawText = null;

        if (engine === 'gemini') {
            if (!GEMINI_API_KEY) throw new Error('GEMINI_API_KEY is not configured.');

            // 💡 FIX: 이전 정상 작동 방식 (GoogleGenerativeAI, 키를 문자열로 전달)으로 복원
            const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
            const model = genAI.getGenerativeModel({ model: GEMINI_MODEL });

            logger.info(`[Gemini] Requesting analysis with model: ${GEMINI_MODEL}`);
            const response = await model.generateContent(prompt);
            
            // SDK의 response.text가 비어있을 경우 candidates에서 안전하게 추출
            rawText = response.text || getFirstAvailableText(response.response);
            
            if (!rawText) {
                const finishReason = response?.response?.candidates?.[0]?.finishReason || 'UNKNOWN';
                if (finishReason === 'SAFETY') throw new Error(`Gemini blocked by safety settings.`);
            }

        } else if (engine === 'claude') {
            if (!CLAUDE_API_KEY) throw new Error('CLAUDE_API_KEY is not configured.');
            
            const claudeUrl = 'https://api.anthropic.com/v1/messages';
            logger.info(`[Claude] Requesting analysis with model: ${CLAUDE_MODEL}`);
            
            const response = await axios.post(claudeUrl, {
                model: CLAUDE_MODEL,
                max_tokens: 4096,
                messages: [{ role: 'user', content: prompt }],
                stop_sequences: ["\n\n"], // 추가 텍스트 방지 유도
            }, {
                headers: {
                    'x-api-key': CLAUDE_API_KEY,
                    'anthropic-version': '2023-06-01',
                    'content-type': 'application/json'
                }
            });

            if (response.data?.content?.length > 0) {
                rawText = response.data.content[0].text;
            }

            if (!rawText) {
                const stopReason = response.data?.stop_reason || 'UNKNOWN';
                if (stopReason === 'safety') throw new Error(`Claude blocked by safety settings.`);
            }

        } else if (engine === 'ollama') {
            const ollamaUrl = `${OLLAMA_HOST}/api/generate`;
            logger.info(`[Ollama] Requesting analysis with model ${OLLAMA_MODEL} at ${ollamaUrl}`);

            const response = await axios.post(ollamaUrl, {
                model: OLLAMA_MODEL,
                prompt,
                stream: false
            });

            rawText = response.data?.response;

        } else {
            throw new Error(`Unsupported AI engine: ${engine}`);
        }

        // --- 공통 후처리 및 유효성 검사 ---
        if (!rawText || rawText.trim() === '') {
            logger.error(`[${engine}] API returned no text.`);
            throw new Error(`${engine} API returned an empty text response.`);
        }
        
        const analysisText = extractMarkdownTable(rawText);

        if (!analysisText) {
            logger.error(`[${engine}] Failed to extract parsable Markdown table from response.`);
            throw new Error('AI analysis failed: AI did not return a parsable Markdown table as requested.');
        }

        return analysisText;

    } catch (error) {
        // Axios 오류 처리 강화 (API 키, 네트워크, 4xx/5xx 등)
        let message = error.message;
        if (error.response?.data?.error) {
            message = error.response.data.error.message || message;
        } else if (error.response?.data?.type) {
            message = error.response.data.type; // Claude 오류 유형
        }
        logger.error(`[${engine}] AI analysis failed: ${message}`);
        throw new Error(`AI analysis failed: ${message}`);
    }
};

module.exports = { analyzeLogs };
EOF_LOG_ANALYZER

# 7. src/services/streamProcessor.js (Glob 패턴 처리 로직 포함)
cat << 'EOF_STREAM_PROCESSOR_V3' > "${SRC_DIR}/services/streamProcessor.js"
const fs = require('fs');
const path = require('path');
const logger = require('../utils/logger');
const stateManager = require('./stateManager');
const config = require('../utils/config');
const { globSync } = require('glob');

/**
 * 주어진 경로 패턴 배열을 Glob으로 확장하여 실제 파일 경로 목록을 반환합니다.
 * @param {string[]} pathPatterns - config.json에서 정의된 패턴 배열
 * @returns {string[]} 실제 로그 파일 경로 배열
 */
const findLogFiles = (pathPatterns) => {
    let files = new Set();
    
    for (let pattern of pathPatterns) {
        // 1. 디렉토리 처리 (경로가 '/' 또는 '\'로 끝나면 해당 디렉토리의 모든 파일을 찾음)
        if (pattern.endsWith(path.sep) || pattern.endsWith('/')) {
            pattern = path.join(pattern, '*'); // 디렉토리 패턴을 Glob 패턴으로 변환 (모든 파일)
        }
        
        // 2. Glob 패턴 처리
        try {
            // nodir: true는 디렉토리를 결과에서 제외합니다.
            const foundFiles = globSync(pattern, { nodir: true });
            foundFiles.forEach(file => files.add(file));
        } catch(error) {
            logger.error(`[Stream] Invalid glob pattern: ${pattern}. Error: ${error.message}`);
        }
    }
    
    return Array.from(files);
};

/**
 * 단일 로그 파일에서 새로운 내용을 읽고 마커를 업데이트합니다.
 */
const processSingleLogFileStream = (appName, logFilePath) => {
    return new Promise((resolve, reject) => {
        const logIdentifier = `${appName}:${logFilePath}`;
        let stats;
        
        // --- 1. 상태 및 파일 크기 초기 설정 ---
        let lastMarker = stateManager.getLastMarker(logIdentifier);
        let fileSize;

        try {
            stats = fs.statSync(logFilePath);
            fileSize = stats.size;
        } catch (error) {
            logger.warn(`[Stream] Log file not found or inaccessible: ${logFilePath}`);
            return resolve({ content: '', newMarker: 0, logIdentifier: logIdentifier });
        }
        
        const maxLogSizeInBytes = config.logProcessing.maxLogSizeMB * 1024 * 1024;


        // --- 2. 💥 로테이션/Truncate 감지 및 마커 재조정 (핵심 수정) ---
        if (fileSize < lastMarker) {
            logger.warn(`[Stream] Log file ${logIdentifier} was rotated or truncated. Resetting marker from ${lastMarker} to 0.`);
            
            // 마커를 즉시 0으로 리셋하고, fileSize와 lastMarker를 현재 값으로 재설정
            // stateManager.updateMarker(logIdentifier, 0); // 🚨 주의: stateManager 저장 호출은 최종 성공 시에만!
            lastMarker = 0; // 이 인스턴스에서만 마커를 0으로 사용
            
            // 이 시점부터는 fileSize > lastMarker (0) 이므로 아래의 일반 로직을 그대로 따름.
        }
        
        // --- 3. 처리 여부 검사 (마커 재조정 후 다시 검사) ---
        if (fileSize === lastMarker) {
            logger.info(`[Stream] Skipping ${logIdentifier}: already processed (Size: ${fileSize}, Marker: ${lastMarker})`);
            return resolve({ content: '', newMarker: fileSize, logIdentifier: logIdentifier });
        }

        if (fileSize === 0) {
            logger.info(`[Stream] Skipping ${logIdentifier}: file is empty`);
            return resolve({ content: '', newMarker: 0, logIdentifier: logIdentifier });
        }


        // --- 4. 읽을 오프셋 계산 (기존 로직 유지) ---
        const newLogSize = fileSize - lastMarker;
        let readStartOffset = lastMarker;
        let readLength = newLogSize;

        if (newLogSize > maxLogSizeInBytes) {
            readStartOffset = Math.floor(fileSize - maxLogSizeInBytes);
            readLength = fileSize - readStartOffset; 
            
            logger.warn(
                `[Stream] New logs for ${logIdentifier} (${(newLogSize / 1024 / 1024).toFixed(2)}MB) exceed ` +
                `MAX_LOG_SIZE_MB (${config.logProcessing.maxLogSizeMB}MB). ` +
                `Reading only latest ${(readLength / 1024 / 1024).toFixed(2)}MB from file.`
            );
        }
        
        // --- 5. 스트림 생성 및 읽기 (기존 로직 유지) ---
        const readStream = fs.createReadStream(logFilePath, {
            encoding: 'utf8',
            start: readStartOffset,
            end: fileSize - 1,
            highWaterMark: config.logProcessing.streamChunkSize 
        });

        let newLogContent = '';
        logger.info(
            `[Stream] Reading ${logIdentifier} from offset ${readStartOffset} to ${fileSize} ` +
            `(Reading ${(readLength / 1024).toFixed(2)}KB of ${(newLogSize / 1024).toFixed(2)}KB new content)`
        );

        readStream.on('data', (chunk) => {
            newLogContent += chunk.toString();
        });

        readStream.on('end', () => {
            const newMarker = fileSize;
            // ... (생략: 로깅)
            
            // 🚨 최종 마커 업데이트는 analyze가 성공했을 때 batchProcessor/analyze.js에서 수행함.
            // 로테이션된 경우(lastMarker=0), 여기서 반환되는 newMarker는 fileSize가 되며,
            // analyze 성공 시 stateManager에 0이 아닌 fileSize가 저장됩니다.
            const content = `--- ${logFilePath} (App: ${appName}) ---\n${newLogContent}\n\n`;
            
            resolve({ content, newMarker, logIdentifier });
        });

        readStream.on('error', (error) => {
            logger.error(`[Stream] Error reading ${logIdentifier}: ${error.message}`);
            reject(error);
        });
    });
};

/**
 * 💡 최상위 함수: 주어진 앱에 대해 설정된 모든 경로 패턴을 처리합니다.
 */
const processAppLogStreams = async (appName, logPathPatterns) => {
    // Glob을 사용하여 패턴을 실제 파일 목록으로 확장
    const filePaths = findLogFiles(logPathPatterns);
    
    if (filePaths.length === 0) {
        logger.info(`[Stream] No log files found for app: ${appName}`);
        return [];
    }
    
    // config.logProcessing.maxLogFiles 제한 적용
    const filesToProcess = filePaths.slice(0, config.logProcessing.maxLogFiles);

    logger.info(`[Stream] Found ${filePaths.length} files, processing ${filesToProcess.length} for app ${appName}.`);
    
    const results = [];
    for (const logFilePath of filesToProcess) {
        try {
            const result = await processSingleLogFileStream(appName, logFilePath);
            // newMarker가 0이 아니거나, 내용이 있는 경우만 결과에 추가
            if (result.content && result.content.trim()) {
                 results.push(result);
            }
        } catch (error) {
            logger.error(`[Stream] Failed to process file ${logFilePath}: ${error.message}`);
        }
    }
    
    return results;
}

module.exports = {
    processAppLogStreams,
};
EOF_STREAM_PROCESSOR_V3

cat << 'EOF_MESSENGER' > "${SRC_DIR}/utils/messenger.js"
const axios = require('axios');
const config = require('./config');
const logger = require('./logger');

/**
 * Mattermost 웹훅을 통해 분석 보고서를 전송합니다.
 *
 * @param {string} analysisResult logAnalyzer에서 반환된 Markdown 분석 결과
 */
const sendReportToMattermost = async (analysisResult) => {
    // 💡 FIX: config.messenger 대신 config.mattermost 사용 (config.json 구조에 맞춤)
    const mattermostConfig = config.mattermost || {};
    const webhookUrl = mattermostConfig.webhookUrl;
    // config.json에 channelId가 없지만, 혹시 모를 경우를 대비하여 안전하게 접근하도록 수정
    const channelId = mattermostConfig.channelId; 

    if (!webhookUrl) {
        logger.warn("Mattermost Webhook URL이 설정되지 않아 보고서를 전송할 수 없습니다. (utils/config.js 확인 필요)");
        return;
    }
    
    // Mattermost 메시지 형식 (간단한 포맷)
    const payload = {
        channel_id: channelId, // channelId가 undefined라도 Mattermost가 웹훅 기본 채널로 전송함
        username: "Log Analyzer AI",
        icon_url: "https://example.com/ai_icon.png", // 적절한 아이콘 URL로 변경 필요
        text: "## 🤖 AI 로그 분석 결과 보고서\n\n" + analysisResult
    };

    try {
        await axios.post(webhookUrl, payload);
        logger.info('[Messenger] AI Report successfully sent to Mattermost.');
    } catch (error) {
        logger.error(`[Messenger] Failed to send report to Mattermost: ${error.message}`);
        // Mattermost 오류의 경우 응답 본문에서 세부 정보 확인
        if (error.response) {
            logger.error(`[Messenger] Mattermost response status: ${error.response.status}, data: ${error.response.data}`);
        }
    }
};

module.exports = {
    sendReportToMattermost,
};
EOF_MESSENGER

# 8. src/services/batchProcessor.js
cat << 'EOF_BATCH_PROCESSOR_V3' > "${SRC_DIR}/services/batchProcessor.js"
const schedule = require('node-schedule');
const logger = require('../utils/logger');
const config = require('../utils/config');
const { analyzeLogs } = require('./logAnalyzer');
const { processAppLogStreams } = require('./streamProcessor'); // Glob 포함된 최상위 함수
const { sendReportToMattermost } = require('../utils/messenger'); // 💡 FIX: reportGenerator 대신 messenger에서 가져옴
const stateManager = require('../services/stateManager');
const rawPLimit = require('p-limit');
const pLimit = rawPLimit.default || rawPLimit;

let batchJob = null;
const limit = pLimit(config.api.maxConcurrentRequests || 5);

/**
 * 배치 분석 작업을 수행합니다.
 */
const performBatchAnalysis = async (appsToAnalyze, engine) => {
    const allLogContent = [];
    const logMarkersToUpdate = []; // { logIdentifier, newMarker }
    const appPaths = config.appLogPaths;

    logger.info(`[Batch] Starting analysis for apps: ${appsToAnalyze.join(', ')} using engine: ${engine}`);

    const appProcessingJobs = appsToAnalyze
        .filter(appName => appPaths[appName] && appPaths[appName].length > 0)
        .map(appName => limit(async () => {
            const logPathPatterns = appPaths[appName]; // 패턴 배열
            
            // 💡 Glob 패턴 처리 및 파일 스트림 처리 (streamProcessor.js)
            const results = await processAppLogStreams(appName, logPathPatterns);
            
            for (const { content, newMarker, logIdentifier } of results) {
                if (content && content.trim()) {
                    allLogContent.push(content);
                    logMarkersToUpdate.push({ logIdentifier, newMarker }); 
                }
            }
        }));
    
    await Promise.all(appProcessingJobs);

    if (allLogContent.length === 0) {
        logger.info('[Batch] No new log content found in batch to analyze.');
        return;
    }
    
    const combinedLogContent = allLogContent.join('');
    
    try {
        const analysisReport = await analyzeLogs(engine, combinedLogContent);
        
        // Mattermost 전송 시, 분석 결과만 인수로 전달합니다.
        await sendReportToMattermost(analysisReport); // 💡 인수는 analysisReport만 사용

        // 💡 분석 성공 시에만 마커 업데이트
        logMarkersToUpdate.forEach(({ logIdentifier, newMarker }) => {
            stateManager.updateMarker(logIdentifier, newMarker);
        });

        logger.info(`[Batch] Analysis successful. ${logMarkersToUpdate.length} file(s) processed. Report sent.`);

    } catch (error) {
        logger.error(`[Batch] AI analysis or Mattermost submission failed: ${error.message}`);
    }
};


const startBatchProcessing = () => {
    if (batchJob) {
        logger.warn('Batch processing is already running.');
        return;
    }
    
    batchJob = schedule.scheduleJob(config.logProcessing.batchInterval, async () => {
        logger.info(`[Batch] Starting scheduled log analysis batch job...`);
        
        const allApps = Object.keys(config.appLogPaths);
        const engine = config.logProcessing.batchEngine; 
        
        try {
            await performBatchAnalysis(allApps, engine);
        } catch (error) {
            logger.error(`[Batch] Fatal error during batch processing: ${error.message}`);
        }
        logger.info('[Batch] Batch log analysis job finished.');
    });

    logger.info(`[Batch] Batch processing scheduled to run with interval: ${config.logProcessing.batchInterval} using engine: ${config.logProcessing.batchEngine}`);
};

const stopBatchProcessing = () => {
    if (batchJob) {
        batchJob.cancel();
        batchJob = null;
        logger.info('[Batch] Batch processing stopped.');
    }
};

module.exports = {
    startBatchProcessing,
    stopBatchProcessing
};

EOF_BATCH_PROCESSOR_V3

# 9. src/routes/analyze.js
cat << 'EOF_ANALYZE_ROUTE_V3' > "${SRC_DIR}/routes/analyze.js"
const express = require('express');
const rawPLimit = require('p-limit');
const pLimit = rawPLimit.default || rawPLimit;
const router = express.Router();

const { validateAnalyzeRequest } = require('../utils/validator');
const config = require('../utils/config');
const logger = require('../utils/logger');
const { analyzeLogs } = require('../services/logAnalyzer');
const { processAppLogStreams } = require('../services/streamProcessor'); // Glob 포함된 최상위 함수
const { sendReportToMattermost } = require('../utils/messenger'); // 💡 FIX: utils/messenger에서 가져옴
const stateManager = require('../services/stateManager');

const limit = pLimit(config.api.maxConcurrentRequests);

/**
 * POST /api/analyze
 */
router.post('/', async (req, res, next) => {
    const { error, value } = validateAnalyzeRequest(req.body);
    if (error) {
        return res.status(400).send({ message: 'Invalid request body', details: error.details });
    }

    const { apps, engine } = value;
    const allLogContent = [];
    const logMarkersToUpdate = [];
    let totalFilesChecked = 0;

    logger.info(`[API] Starting analysis for apps: ${apps.join(', ')} using engine: ${engine}`);

    const appPaths = config.appLogPaths;
    
    // 로그 파일 처리 작업 생성 및 병렬 실행
    const logProcessingJobs = Object.keys(appPaths)
        .filter(appName => apps.includes(appName) && appPaths[appName].length > 0)
        .map(appName => limit(async () => {
            const logPathPatterns = appPaths[appName]; // 패턴 배열
            
            // 💡 Glob 패턴 처리 및 파일 스트림 처리 (streamProcessor.js)
            const results = await processAppLogStreams(appName, logPathPatterns);
            
            totalFilesChecked += results.length;

            for (const { content, newMarker, logIdentifier } of results) {
                if (content && content.trim()) {
                    allLogContent.push(content);
                    logMarkersToUpdate.push({ logIdentifier, newMarker }); 
                }
            }
        }));
    
    try {
        await Promise.all(logProcessingJobs);
    } catch(err) {
        logger.error(`A concurrency error occurred during file processing: ${err.message}`);
        return res.status(500).send({ message: 'Error during log file processing', details: err.message });
    }

    if (allLogContent.length === 0) {
        logger.info('No new log content found to analyze.');
        return res.status(200).send({ message: 'No new logs found for analysis.', totalFilesChecked });
    }
    
    const combinedLogContent = allLogContent.join('');
    
    try {
        const analysisReport = await analyzeLogs(engine, combinedLogContent);
        
        // Mattermost 전송 시, 분석 결과만 인수로 전달합니다.
        await sendReportToMattermost(analysisReport); // 💡 인수는 analysisReport만 사용

        // 💡 분석에 성공하면 상태 관리자의 마커 업데이트
        logMarkersToUpdate.forEach(({ logIdentifier, newMarker }) => {
            stateManager.updateMarker(logIdentifier, newMarker);
        });

        logger.info(`[API] Analysis successful and state updated. Report sent to Mattermost.`);
        
        // API 응답에는 분석 결과를 직접 포함
        return res.status(200).send({
            message: 'Analysis successful. Report sent to Mattermost.',
            analysisReport: analysisReport,
            processedFiles: logMarkersToUpdate.length
        });

    } catch (error) {
        logger.error(`[API] AI analysis/Mattermost failed: ${error.message}`);
        return res.status(500).send({ 
            message: `AI analysis/Mattermost failed: ${error.message}`,
            details: error.stack
        });
    }
});

module.exports = router;
EOF_ANALYZE_ROUTE_V3

# 10. src/routes/reset.js
cat << 'EOF_RESET_ROUTE' > "${SRC_DIR}/routes/reset.js"
const express = require('express');
const router = express.Router();
const stateManager = require('../services/stateManager');
const logger = require('../utils/logger');

/**
 * GET /api/state
 * 현재 로그 분석 마커 상태를 반환합니다.
 */
router.get('/', (req, res) => {
    const snapshot = stateManager.getStateSnapshot();
    res.status(200).send({
        message: 'Current log marker state snapshot.',
        state: snapshot,
        totalMarkers: Object.keys(snapshot).length
    });
});

/**
 * POST /api/state/reset
 * 모든 로그 분석 마커 상태를 초기화합니다.
 */
router.post('/reset', (req, res) => {
    const clearedCount = stateManager.resetState();
    logger.warn(`[API] Log analysis state reset requested. Cleared ${clearedCount} markers.`);
    res.status(200).send({
        message: 'Log analysis state has been reset successfully.',
        clearedMarkers: clearedCount
    });
});

module.exports = router;
EOF_RESET_ROUTE

# 11. src/middleware/errorHandler.js
cat << 'EOF_ERROR_HANDLER' > "${SRC_DIR}/middleware/errorHandler.js"
const logger = require('../utils/logger');

/**
 * 전역 에러 핸들러
 */
const errorHandler = (err, req, res, next) => {
    logger.error('Unhandled Error:', {
        message: err.message,
        stack: err.stack,
        url: req.originalUrl,
        method: req.method
    });

    const statusCode = err.statusCode || 500;
    const message = err.message || 'Internal Server Error';

    res.status(statusCode).send({
        status: 'error',
        message: message
    });
};

module.exports = errorHandler;
EOF_ERROR_HANDLER


# 12. src/index.js (메인 엔트리 포인트)
cat << EOF_INDEX > "${SRC_DIR}/index.js"
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');

const config = require('./utils/config');
const logger = require('./utils/logger');
const { startBatchProcessing } = require('./services/batchProcessor');
const errorHandler = require('./middleware/errorHandler');

const analyzeRouter = require('./routes/analyze');
const resetRouter = require('./routes/reset');

const app = express();
const PORT = config.api.port;

// 미들웨어 설정
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 라우터 설정
app.use('/api/analyze', analyzeRouter);
app.use('/api/state', resetRouter); // 상태 확인 및 리셋용

// 기본 헬스 체크
app.get('/', (req, res) => {
    res.status(200).send('Log Analyzer Agent is running.');
});

// 에러 핸들링 미들웨어
app.use(errorHandler);

// 서버 시작
const server = app.listen(PORT, () => {
    logger.info(\`✅ Server running on port \${PORT}\`);
    logger.info(\`🔍 Log Level: \${config.api.logLevel}\`);

    // 배치 처리 시작 (cron 스케줄링)
    startBatchProcessing();
});

// Graceful Shutdown
process.on('SIGTERM', () => {
    logger.info('SIGTERM signal received: Closing HTTP server.');
    server.close(() => {
        logger.info('HTTP server closed. Exiting process.');
        process.exit(0);
    });
});
EOF_INDEX


# --- 6. 🛠️ 실행 스크립트 생성 및 권한 설정 ---
echo "⚙️ 3단계: 실행 스크립트 생성 시작..."

# scripts/build.sh
cat << 'EOF_BUILD' > "${SCRIPTS_DIR}/build.sh"
#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."
echo "--- 🐳 Docker 이미지 빌드 시작 ---"
# config.json으로 설정이 분리되었으므로, .env 파일은 더 이상 필요하지 않습니다.
docker compose -f docker-compose.yml build --no-cache
echo "--- ✅ Docker 이미지 빌드 완료 ---"
EOF_BUILD
chmod +x "${SCRIPTS_DIR}/build.sh"

# scripts/start.sh
cat << EOF_START > "${SCRIPTS_DIR}/start.sh"
#!/bin/bash
set -euo pipefail

cd "\$(dirname "\$0")/.."

echo "--- 🚀 Docker Compose 서비스 시작 (백그라운드) ---"
docker compose -f docker-compose.yml up -d 
echo "--- ✅ 서비스 시작 완료 ---"
echo "💡 설정 파일 경로: \$(pwd)/volumes/config/config.json"
echo "💡 로그를 확인하려면: docker logs ${DOCKER_CONTAINER_NAME} -f"
echo "💡 설정 변경 후 재시작: docker compose restart"
echo "💡 서비스 종료는: ./scripts/stop.sh"
EOF_START
chmod +x "${SCRIPTS_DIR}/start.sh"

# scripts/stop.sh
cat << EOF_STOP > "${SCRIPTS_DIR}/stop.sh"
#!/bin/bash
set -euo pipefail

DOCKER_CONTAINER_NAME="${DOCKER_CONTAINER_NAME}"
DOCKER_NETWORK="${DOCKER_NETWORK}"

cd "\$(dirname "\$0")/.."

echo "--- 🛑 Docker Compose 서비스 종료 및 컨테이너 삭제 ---"
docker compose -f docker-compose.yml down
echo "--- ✅ 서비스 종료 완료 ---"

if docker network ls --format "{{.Name}}" | grep -q "${DOCKER_NETWORK}"; then
    echo "--- 🗑️ 사용된 Docker 네트워크 (${DOCKER_NETWORK}) 정리 ---"
    docker network rm "${DOCKER_NETWORK}" || true
fi
EOF_STOP
chmod +x "${SCRIPTS_DIR}/stop.sh"

echo "✅ 3단계 완료: 실행 스크립트 생성 및 권한 설정."
echo "================================================================="
echo "🎉 프로젝트 '${PROJECT_NAME}' 생성이 완료되었습니다."
echo "💡 **핵심 수정 사항**: 누락되었던 모든 Node.js 소스 파일 (총 12개)을 스크립트에 포함했습니다."
echo "💡 **예상 오류 해결**: 이제 모든 \`require()\` 경로에 해당하는 파일이 \`COPY src src\` 단계에서 컨테이너에 완벽하게 복사될 것입니다."
echo ""
echo "다음 명령을 순서대로 실행하세요:"
echo "1. **중요**: 설정 파일 확인 및 API 키 입력: cd ${PROJECT_NAME} && vi volumes/config/config.json"
echo "2. 빌드: ./scripts/build.sh (자동으로 \`--no-cache\` 적용)"
echo "3. 실행: ./scripts/start.sh"
echo "================================================================="
