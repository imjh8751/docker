#!/bin/bash

set -e

# =================================================================
# 프로젝트 생성 설정 변수 (필요에 따라 수정)
# =================================================================
APP_NAME="MultiWebhookManager"
APP_PACKAGE="org.itapi.multiwebhookmanager"
APP_VERSION="1.0.0"
APP_VERSION_CODE=1

PROJECT_DIR="./android_project"

# Android 프로젝트 설정
ANDROID_COMPILE_SDK="34"
ANDROID_MIN_SDK="24"
ANDROID_TARGET_SDK="34"
ANDROID_BUILD_TOOLS="34.0.0"

# Gradle 설정
GRADLE_VERSION="8.0"
ANDROID_GRADLE_PLUGIN="8.0.2"

# 의존성 버전
APPCOMPAT_VERSION="1.6.1"
MATERIAL_VERSION="1.10.0"
CONSTRAINTLAYOUT_VERSION="2.1.4"
FRAGMENT_VERSION="1.6.2"
VIEWPAGER2_VERSION="1.0.0"
CARDVIEW_VERSION="1.0.0"
GSON_VERSION="2.10.1"

# =================================================================
# 컬러 정의 및 로그 함수
# =================================================================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# =================================================================
# 함수 정의
# =================================================================

check_prerequisites() {
    log_info "사전 요구사항 확인 중..."
    
    # 기존 프로젝트 폴더 확인
    if [[ -d "$PROJECT_DIR" ]]; then
        log_warning "기존 프로젝트 폴더가 존재합니다: $PROJECT_DIR"
        read -p "기존 폴더를 삭제하고 새로 생성하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "기존 프로젝트 폴더 삭제 중..."
            rm -rf "$PROJECT_DIR"
        else
            log_error "프로젝트 생성을 중단합니다."
            exit 1
        fi
    fi
    
    log_success "사전 요구사항 확인 완료"
}

create_project_structure() {
    log_info "프로젝트 구조 생성 중..."
    
    # 기본 폴더 구조 생성
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    
    # Android 프로젝트 구조
    mkdir -p app/src/main/java/$(echo $APP_PACKAGE | tr '.' '/')
    mkdir -p app/src/main/res/layout
    mkdir -p app/src/main/res/values
    mkdir -p app/src/main/res/mipmap-anydpi-v26
    mkdir -p app/src/main/res/drawable
    mkdir -p app/src/main/res/xml
    mkdir -p app/src/main/res/menu
    
    log_success "프로젝트 구조 생성 완료"
}

create_gradle_files() {
    log_info "Gradle 설정 파일 생성 중..."

    # 루트 build.gradle
    cat > build.gradle << EOF
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:$ANDROID_GRADLE_PLUGIN'
    }
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
EOF

    # gradle.properties
    cat > gradle.properties << 'EOF'
# Project-wide Gradle settings.
android.useAndroidX=true
android.enableJetifier=true

# Gradle JVM options
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8

# Gradle build optimization
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configureondemand=true
EOF

    # app/build.gradle
    cat > app/build.gradle << EOF
plugins {
    id 'com.android.application'
}

android {
    namespace '$APP_PACKAGE'
    compileSdk $ANDROID_COMPILE_SDK
    buildToolsVersion "$ANDROID_BUILD_TOOLS"

    defaultConfig {
        applicationId "$APP_PACKAGE"
        minSdk $ANDROID_MIN_SDK
        targetSdk $ANDROID_TARGET_SDK
        versionCode $APP_VERSION_CODE
        versionName "$APP_VERSION"

        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            signingConfig signingConfigs.debug
        }
        debug {
            debuggable true
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    packagingOptions {
        resources {
            excludes += '/META-INF/{AL2.0,LGPL2.1}'
        }
    }

    // deprecated API 경고 억제
    tasks.withType(JavaCompile) {
        options.compilerArgs << "-Xlint:-deprecation"
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:$APPCOMPAT_VERSION'
    implementation 'com.google.android.material:material:$MATERIAL_VERSION'
    implementation 'androidx.constraintlayout:constraintlayout:$CONSTRAINTLAYOUT_VERSION'
    implementation 'androidx.fragment:fragment:$FRAGMENT_VERSION'
    implementation 'androidx.viewpager2:viewpager2:$VIEWPAGER2_VERSION'
    implementation 'androidx.cardview:cardview:$CARDVIEW_VERSION'
    implementation 'com.google.code.gson:gson:$GSON_VERSION'
    
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.1.5'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
}
EOF

    # settings.gradle
    cat > settings.gradle << EOF
pluginManagement {
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "$APP_NAME"
include ':app'
EOF

    # app/proguard-rules.pro
    cat > app/proguard-rules.pro << 'EOF'
# Keep Gson classes
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Keep model classes
-keep class * implements java.io.Serializable { *; }
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
EOF

    log_success "Gradle 설정 파일 생성 완료"
}

create_android_manifest() {
    log_info "Android Manifest 생성 중..."
    
    cat > app/src/main/AndroidManifest.xml << EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE" 
        tools:ignore="ProtectedPermissions" />
    <uses-permission android:name="android.permission.RECEIVE_SMS" />
    <uses-permission android:name="android.permission.READ_SMS" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
        android:maxSdkVersion="28" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.SEND_SMS" />

    <application
        android:allowBackup="true"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:fullBackupContent="@xml/backup_rules"
        android:icon="@mipmap/ic_launcher"
        android:label="$APP_NAME"
        android:theme="@style/Theme.Material3.DayNight"
        tools:targetApi="31">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.Material3.DayNight.NoActionBar">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <service
            android:name=".service.NotificationListenerService"
            android:exported="false"
            android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE">
            <intent-filter>
                <action android:name="android.service.notification.NotificationListenerService" />
            </intent-filter>
        </service>

        <receiver
            android:name=".receiver.SmsReceiver"
            android:exported="true">
            <intent-filter android:priority="1000">
                <action android:name="android.provider.Telephony.SMS_RECEIVED" />
            </intent-filter>
        </receiver>

    </application>

</manifest>
EOF

    log_success "Android Manifest 생성 완료"
}

create_data_models() {
    log_info "데이터 모델 클래스 생성 중..."
    
    local java_dir="app/src/main/java/$(echo $APP_PACKAGE | tr '.' '/')"
    mkdir -p "$java_dir/model"

    # WebhookConfig.java
    cat > "$java_dir/model/WebhookConfig.java" << EOF
package $APP_PACKAGE.model;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class WebhookConfig implements Serializable {
    private String id;
    private String name;
    private String url;
    private boolean enabled;
    
    // 알림 필터링
    private List<String> targetApps;
    private List<String> notificationIncludeKeywords;
    private List<String> notificationExcludeKeywords;
    private List<String> titleIncludeKeywords;
    private List<String> titleExcludeKeywords;
    
    // SMS 필터링
    private List<String> smsAllowedSenders;
    private List<String> smsIncludeKeywords;
    private List<String> smsExcludeKeywords;
    
    // 통계
    private int successCount;
    private int failureCount;
    private long lastUsed;
    
    // SMS 발송
    private List<String> smsRecipients;
    
    public WebhookConfig() {
        this.id = UUID.randomUUID().toString();
        this.enabled = true;
        this.targetApps = new ArrayList<>();
        this.notificationIncludeKeywords = new ArrayList<>();
        this.notificationExcludeKeywords = new ArrayList<>();
        this.titleIncludeKeywords = new ArrayList<>();
        this.titleExcludeKeywords = new ArrayList<>();
        this.smsAllowedSenders = new ArrayList<>();
        this.smsIncludeKeywords = new ArrayList<>();
        this.smsExcludeKeywords = new ArrayList<>();
        this.successCount = 0;
        this.failureCount = 0;
        this.lastUsed = 0;
        this.smsRecipients = new ArrayList<>();
    }

    public WebhookConfig(String name, String url) {
        this();
        this.name = name;
        this.url = url;
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getUrl() { return url; }
    public void setUrl(String url) { this.url = url; }

    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean enabled) { this.enabled = enabled; }

    public List<String> getTargetApps() { return targetApps; }
    public void setTargetApps(List<String> targetApps) { this.targetApps = targetApps; }

    public List<String> getNotificationIncludeKeywords() { return notificationIncludeKeywords; }
    public void setNotificationIncludeKeywords(List<String> notificationIncludeKeywords) { this.notificationIncludeKeywords = notificationIncludeKeywords; }

    public List<String> getNotificationExcludeKeywords() { return notificationExcludeKeywords; }
    public void setNotificationExcludeKeywords(List<String> notificationExcludeKeywords) { this.notificationExcludeKeywords = notificationExcludeKeywords; }

    public List<String> getTitleIncludeKeywords() { return titleIncludeKeywords; }
    public void setTitleIncludeKeywords(List<String> titleIncludeKeywords) { this.titleIncludeKeywords = titleIncludeKeywords; }

    public List<String> getTitleExcludeKeywords() { return titleExcludeKeywords; }
    public void setTitleExcludeKeywords(List<String> titleExcludeKeywords) { this.titleExcludeKeywords = titleExcludeKeywords; }

    public List<String> getSmsAllowedSenders() { return smsAllowedSenders; }
    public void setSmsAllowedSenders(List<String> smsAllowedSenders) { this.smsAllowedSenders = smsAllowedSenders; }

    public List<String> getSmsIncludeKeywords() { return smsIncludeKeywords; }
    public void setSmsIncludeKeywords(List<String> smsIncludeKeywords) { this.smsIncludeKeywords = smsIncludeKeywords; }

    public List<String> getSmsExcludeKeywords() { return smsExcludeKeywords; }
    public void setSmsExcludeKeywords(List<String> smsExcludeKeywords) { this.smsExcludeKeywords = smsExcludeKeywords; }

    public int getSuccessCount() { return successCount; }
    public void setSuccessCount(int successCount) { this.successCount = successCount; }

    public int getFailureCount() { return failureCount; }
    public void setFailureCount(int failureCount) { this.failureCount = failureCount; }

    public long getLastUsed() { return lastUsed; }
    public void setLastUsed(long lastUsed) { this.lastUsed = lastUsed; }
    
    public List<String> getSmsRecipients() { return smsRecipients; }
    public void setSmsRecipients(List<String> smsRecipients) { this.smsRecipients = smsRecipients; }

    public void incrementSuccess() {
        this.successCount++;
        this.lastUsed = System.currentTimeMillis();
    }

    public void incrementFailure() {
        this.failureCount++;
        this.lastUsed = System.currentTimeMillis();
    }

    public int getTotalCount() {
        return successCount + failureCount;
    }

    public double getSuccessRate() {
        int total = getTotalCount();
        return total > 0 ? (double) successCount / total * 100 : 0;
    }
}
EOF

    # MessageHistory.java
    cat > "$java_dir/model/MessageHistory.java" << EOF
package $APP_PACKAGE.model;

import java.io.Serializable;

public class MessageHistory implements Serializable {
    public enum MessageType {
        NOTIFICATION, SMS
    }

    public enum Status {
        SUCCESS, FAILURE, PENDING
    }

    private String id;
    private long timestamp;
    private MessageType type;
    private String sender;
    private String title;
    private String content;
    private String webhookId;
    private String webhookName;
    private Status status;
    private String errorMessage;

    public MessageHistory() {
        this.id = java.util.UUID.randomUUID().toString();
        this.timestamp = System.currentTimeMillis();
        this.status = Status.PENDING;
    }

    public MessageHistory(MessageType type, String sender, String title, String content, String webhookId, String webhookName) {
        this();
        this.type = type;
        this.sender = sender;
        this.title = title;
        this.content = content;
        this.webhookId = webhookId;
        this.webhookName = webhookName;
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public long getTimestamp() { return timestamp; }
    public void setTimestamp(long timestamp) { this.timestamp = timestamp; }

    public MessageType getType() { return type; }
    public void setType(MessageType type) { this.type = type; }

    public String getSender() { return sender; }
    public void setSender(String sender) { this.sender = sender; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getWebhookId() { return webhookId; }
    public void setWebhookId(String webhookId) { this.webhookId = webhookId; }

    public String getWebhookName() { return webhookName; }
    public void setWebhookName(String webhookName) { this.webhookName = webhookName; }

    public Status getStatus() { return status; }
    public void setStatus(Status status) { this.status = status; }

    public String getErrorMessage() { return errorMessage; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }
}
EOF

    log_success "데이터 모델 클래스 생성 완료"
}

create_data_manager() {
    log_info "데이터 매니저 클래스 생성 중..."
    
    local java_dir="app/src/main/java/$(echo $APP_PACKAGE | tr '.' '/')"
    mkdir -p "$java_dir/manager"

    # DataManager.java
    cat > "$java_dir/manager/DataManager.java" << EOF
package $APP_PACKAGE.manager;

import android.content.Context;
import android.content.SharedPreferences;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import $APP_PACKAGE.model.WebhookConfig;
import $APP_PACKAGE.model.MessageHistory;
import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.List;

public class DataManager {
    private static final String PREF_NAME = "MultiWebhookManager";
    private static final String KEY_WEBHOOKS = "webhooks";
    private static final String KEY_HISTORY = "message_history";
    private static final int MAX_HISTORY_SIZE = 1000;

    private static DataManager instance;
    private SharedPreferences prefs;
    private Gson gson;

    private DataManager(Context context) {
        prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
        gson = new Gson();
    }

    public static synchronized DataManager getInstance(Context context) {
        if (instance == null) {
            instance = new DataManager(context.getApplicationContext());
        }
        return instance;
    }

    // Webhook 관리
    public List<WebhookConfig> getWebhooks() {
        String json = prefs.getString(KEY_WEBHOOKS, "[]");
        Type type = new TypeToken<List<WebhookConfig>>(){}.getType();
        return gson.fromJson(json, type);
    }

    public void saveWebhooks(List<WebhookConfig> webhooks) {
        String json = gson.toJson(webhooks);
        prefs.edit().putString(KEY_WEBHOOKS, json).apply();
    }

    public void addWebhook(WebhookConfig webhook) {
        List<WebhookConfig> webhooks = getWebhooks();
        webhooks.add(webhook);
        saveWebhooks(webhooks);
    }

    public void updateWebhook(WebhookConfig updatedWebhook) {
        List<WebhookConfig> webhooks = getWebhooks();
        for (int i = 0; i < webhooks.size(); i++) {
            if (webhooks.get(i).getId().equals(updatedWebhook.getId())) {
                webhooks.set(i, updatedWebhook);
                break;
            }
        }
        saveWebhooks(webhooks);
    }

    public void deleteWebhook(String webhookId) {
        List<WebhookConfig> webhooks = getWebhooks();
        // removeIf 대신 전통적인 방식 사용 (API 24 이하 호환성)
        for (int i = webhooks.size() - 1; i >= 0; i--) {
            if (webhooks.get(i).getId().equals(webhookId)) {
                webhooks.remove(i);
                break;
            }
        }
        saveWebhooks(webhooks);
    }

    public WebhookConfig getWebhookById(String id) {
        List<WebhookConfig> webhooks = getWebhooks();
        for (WebhookConfig webhook : webhooks) {
            if (webhook.getId().equals(id)) {
                return webhook;
            }
        }
        return null;
    }

    public List<WebhookConfig> getEnabledWebhooks() {
        List<WebhookConfig> allWebhooks = getWebhooks();
        List<WebhookConfig> enabledWebhooks = new ArrayList<>();
        for (WebhookConfig webhook : allWebhooks) {
            if (webhook.isEnabled()) {
                enabledWebhooks.add(webhook);
            }
        }
        return enabledWebhooks;
    }

    // 메시지 이력 관리
    public List<MessageHistory> getMessageHistory() {
        String json = prefs.getString(KEY_HISTORY, "[]");
        Type type = new TypeToken<List<MessageHistory>>(){}.getType();
        return gson.fromJson(json, type);
    }

    public void saveMessageHistory(List<MessageHistory> history) {
        // 최대 크기 제한
        if (history.size() > MAX_HISTORY_SIZE) {
            history = history.subList(history.size() - MAX_HISTORY_SIZE, history.size());
        }
        String json = gson.toJson(history);
        prefs.edit().putString(KEY_HISTORY, json).apply();
    }

    public void addMessageHistory(MessageHistory message) {
        List<MessageHistory> history = getMessageHistory();
        history.add(0, message); // 최신 메시지를 맨 앞에 추가
        saveMessageHistory(history);
    }

    public void updateMessageHistory(MessageHistory updatedMessage) {
        List<MessageHistory> history = getMessageHistory();
        for (int i = 0; i < history.size(); i++) {
            if (history.get(i).getId().equals(updatedMessage.getId())) {
                history.set(i, updatedMessage);
                break;
            }
        }
        saveMessageHistory(history);
    }

    public void clearMessageHistory() {
        prefs.edit().putString(KEY_HISTORY, "[]").apply();
    }

    // 백업 및 복구
    public String exportData() {
        ExportData data = new ExportData();
        data.webhooks = getWebhooks();
        data.history = getMessageHistory();
        return gson.toJson(data);
    }

    public boolean importData(String json) {
        try {
            ExportData data = gson.fromJson(json, ExportData.class);
            if (data.webhooks != null) {
                saveWebhooks(data.webhooks);
            }
            if (data.history != null) {
                saveMessageHistory(data.history);
            }
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private static class ExportData {
        List<WebhookConfig> webhooks;
        List<MessageHistory> history;
    }
}
EOF

    log_success "데이터 매니저 클래스 생성 완료"
}

create_service_classes() {
    log_info "서비스 클래스 생성 중..."
    
    local java_dir="app/src/main/java/$(echo $APP_PACKAGE | tr '.' '/')"
    mkdir -p "$java_dir/service"

    # NotificationListenerService.java
    cat > "$java_dir/service/NotificationListenerService.java" << EOF
package $APP_PACKAGE.service;

import android.app.Notification;
import android.service.notification.StatusBarNotification;
import android.util.Log;
import $APP_PACKAGE.manager.DataManager;
import $APP_PACKAGE.model.WebhookConfig;
import $APP_PACKAGE.model.MessageHistory;
import $APP_PACKAGE.util.WebhookSender;
import $APP_PACKAGE.util.FilterUtils;
import java.util.List;

public class NotificationListenerService extends android.service.notification.NotificationListenerService {
    private static final String TAG = "NotificationListener";
    private DataManager dataManager;
    private WebhookSender webhookSender;

    @Override
    public void onCreate() {
        super.onCreate();
        dataManager = DataManager.getInstance(this);
        webhookSender = new WebhookSender(this);
    }

    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        processNotification(sbn);
    }

    private void processNotification(StatusBarNotification sbn) {
        try {
            String packageName = sbn.getPackageName();
            Notification notification = sbn.getNotification();
            String title = getNotificationText(notification.extras.getCharSequence(Notification.EXTRA_TITLE));
            String text = getNotificationText(notification.extras.getCharSequence(Notification.EXTRA_TEXT));

            List<WebhookConfig> enabledWebhooks = dataManager.getEnabledWebhooks();
            
            for (WebhookConfig webhook : enabledWebhooks) {
                if (shouldProcessNotification(webhook, packageName, title, text)) {
                    String message = String.format("제목: %s\\n%s", 
                        title.isEmpty() ? "없음" : title, 
                        text.isEmpty() ? "없음" : text);
                    
                    MessageHistory history = new MessageHistory(
                        MessageHistory.MessageType.NOTIFICATION,
                        packageName,
                        title,
                        text,
                        webhook.getId(),
                        webhook.getName()
                    );
                    
                    dataManager.addMessageHistory(history);
                    webhookSender.sendMessage(webhook, message, history);
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "알림 처리 오류", e);
        }
    }

    private boolean shouldProcessNotification(WebhookConfig webhook, String packageName, String title, String text) {
        // 대상 앱 체크
        if (!webhook.getTargetApps().isEmpty()) {
            boolean found = false;
            for (String targetApp : webhook.getTargetApps()) {
                if (packageName.equals(targetApp.trim())) {
                    found = true;
                    break;
                }
            }
            if (!found) return false;
        }

        // 제목 필터링
        if (!FilterUtils.checkTitleFilter(title, webhook.getTitleIncludeKeywords(), webhook.getTitleExcludeKeywords())) {
            return false;
        }

        // 내용 필터링
        return FilterUtils.checkContentFilter(text, webhook.getNotificationIncludeKeywords(), webhook.getNotificationExcludeKeywords());
    }

    private String getNotificationText(CharSequence charSequence) {
        return charSequence != null ? charSequence.toString().trim() : "";
    }
}
EOF

    log_success "서비스 클래스 생성 완료"
}

create_receiver_classes() {
    log_info "리시버 클래스 생성 중..."
    
    local java_dir="app/src/main/java/$(echo $APP_PACKAGE | tr '.' '/')"
    mkdir -p "$java_dir/receiver"

    # SmsReceiver.java
    cat > "$java_dir/receiver/SmsReceiver.java" << EOF
package $APP_PACKAGE.receiver;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.telephony.SmsMessage;
import android.util.Log;
import $APP_PACKAGE.manager.DataManager;
import $APP_PACKAGE.model.WebhookConfig;
import $APP_PACKAGE.model.MessageHistory;
import $APP_PACKAGE.util.WebhookSender;
import $APP_PACKAGE.util.FilterUtils;
import java.util.List;

public class SmsReceiver extends BroadcastReceiver {
    private static final String TAG = "SmsReceiver";

    @Override
    public void onReceive(Context context, Intent intent) {
        if ("android.provider.Telephony.SMS_RECEIVED".equals(intent.getAction())) {
            Bundle bundle = intent.getExtras();
            if (bundle != null) {
                Object[] pdus = (Object[]) bundle.get("pdus");
                if (pdus != null) {
                    String format = bundle.getString("format");
                    
                    for (Object pdu : pdus) {
                        SmsMessage sms = getSmsMessage((byte[]) pdu, format);
                        if (sms != null) {
                            String sender = sms.getOriginatingAddress();
                            String message = sms.getMessageBody();
                            processSms(context, sender, message);
                        }
                    }
                }
            }
        }
    }

    private SmsMessage getSmsMessage(byte[] pdu, String format) {
        try {
            if (Build.VERSION.SDK_INT >= 23) {
                return SmsMessage.createFromPdu(pdu, format != null ? format : "3gpp");
            } else {
                return createLegacySmsMessage(pdu);
            }
        } catch (Exception e) {
            Log.e(TAG, "SMS 메시지 생성 실패", e);
            return null;
        }
    }

    @SuppressWarnings("deprecation")
    private SmsMessage createLegacySmsMessage(byte[] pdu) {
        return SmsMessage.createFromPdu(pdu);
    }

    private void processSms(Context context, String sender, String message) {
        try {
            DataManager dataManager = DataManager.getInstance(context);
            WebhookSender webhookSender = new WebhookSender(context);
            List<WebhookConfig> enabledWebhooks = dataManager.getEnabledWebhooks();
            
            for (WebhookConfig webhook : enabledWebhooks) {
                if (shouldProcessSms(webhook, sender, message)) {
                    String mattermostMessage = String.format("발신자: %s\\n%s", 
                        sender != null ? sender : "알 수 없음", 
                        message != null ? message : "내용 없음");
                    
                    MessageHistory history = new MessageHistory(
                        MessageHistory.MessageType.SMS,
                        sender,
                        "",
                        message,
                        webhook.getId(),
                        webhook.getName()
                    );
                    
                    dataManager.addMessageHistory(history);
                    webhookSender.sendMessage(webhook, mattermostMessage, history);
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "SMS 처리 오류", e);
        }
    }

    private boolean shouldProcessSms(WebhookConfig webhook, String sender, String message) {
        if (!webhook.getSmsAllowedSenders().isEmpty()) {
            boolean found = false;
            for (String allowedSender : webhook.getSmsAllowedSenders()) {
                if (sender != null && sender.contains(allowedSender.trim())) {
                    found = true;
                    break;
                }
            }
            if (!found) return false;
        }

        return FilterUtils.checkContentFilter(message, webhook.getSmsIncludeKeywords(), webhook.getSmsExcludeKeywords());
    }
}
EOF

    log_success "리시버 클래스 생성 완료"
}

create_utility_classes() {
    log_info "유틸리티 클래스 생성 중..."
    
    local java_dir="app/src/main/java/$(echo $APP_PACKAGE | tr '.' '/')"
    mkdir -p "$java_dir/util"

    # SmsSender.java
    cat > "$java_dir/util/SmsSender.java" << EOF
package $APP_PACKAGE.util;

import android.content.Context;
import android.telephony.SmsManager;
import android.util.Log;
import java.util.List;
import java.util.ArrayList;

public class SmsSender {
    private static final String TAG = "SmsSender";

    public static void sendSmsToRecipients(Context context, List<String> recipients, String message) {
        if (recipients == null || recipients.isEmpty()) {
            return;
        }

        SmsManager smsManager = SmsManager.getDefault();
        
        for (String recipient : recipients) {
            String phoneNumber = recipient.trim();
            if (!phoneNumber.isEmpty()) {
                try {
                    // 긴 메시지의 경우 자동으로 분할하여 전송
                    if (message.length() > 160) {
                        ArrayList<String> parts = smsManager.divideMessage(message);
                        smsManager.sendMultipartTextMessage(phoneNumber, null, parts, null, null);
                    } else {
                        smsManager.sendTextMessage(phoneNumber, null, message, null, null);
                    }
                    Log.d(TAG, "SMS 전송 완료: " + phoneNumber);
                } catch (Exception e) {
                    Log.e(TAG, "SMS 전송 실패: " + phoneNumber, e);
                }
            }
        }
    }
}
EOF

    # FilterUtils.java
    cat > "$java_dir/util/FilterUtils.java" << EOF
package $APP_PACKAGE.util;

import java.util.List;

public class FilterUtils {
    private static final String TAG = "FilterUtils";

    /**
     * 제목에 대한 필터링을 수행합니다.
     * @param title 메시지의 제목
     * @param includeKeywords 포함해야 하는 키워드 목록
     * @param excludeKeywords 제외해야 하는 키워드 목록
     * @return 필터를 통과하면 true, 아니면 false
     */
    public static boolean checkTitleFilter(String title, List<String> includeKeywords, List<String> excludeKeywords) {
        if (TextUtils.isEmpty(title)) {
            Log.d(TAG, "제목이 비어있어 필터링을 건너뜁니다.");
            return true; // 제목이 없으면 필터링 통과 (제목 필터가 무의미)
        }

        String titleLower = title.toLowerCase();

        // 1. 제외 키워드 체크 (우선순위 높음: 하나라도 걸리면 무조건 차단)
        if (excludeKeywords != null && !excludeKeywords.isEmpty()) {
            for (String keyword : excludeKeywords) {
                if (!keyword.trim().isEmpty()) {
                    String lowerKeyword = keyword.trim().toLowerCase();
                    if (titleLower.contains(lowerKeyword)) {
                        Log.d(TAG, "제목이 제외 키워드에 걸림: [" + lowerKeyword + "]");
                        return false; // 제외 키워드에 포함되면 차단
                    }
                }
            }
        }

        // 2. 포함 키워드 체크 (설정되어 있다면 반드시 매치되어야 통과)
        if (includeKeywords != null && !includeKeywords.isEmpty()) {
            boolean hasValidKeyword = false;
            boolean isMatch = false;

            for (String keyword : includeKeywords) {
                if (!keyword.trim().isEmpty()) {
                    hasValidKeyword = true;
                    String lowerKeyword = keyword.trim().toLowerCase();
                    if (titleLower.contains(lowerKeyword)) {
                        isMatch = true;
                        break; // 하나라도 일치하면 즉시 통과
                    }
                }
            }

            // **핵심 수정 부분:** 유효한 포함 키워드가 있었는데 매치되지 않았다면 차단
            if (hasValidKeyword && !isMatch) {
                Log.d(TAG, "제목이 포함 키워드에 매치되지 않아 차단됩니다.");
                return false;
            }
            // 유효한 포함 키워드가 설정되어 있지 않다면 (hasValidKeyword=false), 이 필터는 통과 (다음 필터로)
        }

        return true; // 제외에도 안 걸렸고, 포함 조건도 충족(혹은 미설정)했으니 통과
    }

    /**
     * 내용에 대한 필터링을 수행합니다. (제목 필터와 동일한 로직 적용)
     * @param content 메시지의 내용
     * @param includeKeywords 포함해야 하는 키워드 목록
     * @param excludeKeywords 제외해야 하는 키워드 목록
     * @return 필터를 통과하면 true, 아니면 false
     */
    public static boolean checkContentFilter(String content, List<String> includeKeywords, List<String> excludeKeywords) {
        if (TextUtils.isEmpty(content)) {
            Log.d(TAG, "내용이 비어있어 필터링을 건너뜁니다.");
            return true;
        }

        String contentLower = content.toLowerCase();

        // 1. 제외 키워드 체크
        if (excludeKeywords != null && !excludeKeywords.isEmpty()) {
            for (String keyword : excludeKeywords) {
                if (!keyword.trim().isEmpty()) {
                    String lowerKeyword = keyword.trim().toLowerCase();
                    if (contentLower.contains(lowerKeyword)) {
                        Log.d(TAG, "내용이 제외 키워드에 걸림: [" + lowerKeyword + "]");
                        return false;
                    }
                }
            }
        }

        // 2. 포함 키워드 체크
        if (includeKeywords != null && !includeKeywords.isEmpty()) {
            boolean hasValidKeyword = false;
            boolean isMatch = false;

            for (String keyword : includeKeywords) {
                if (!keyword.trim().isEmpty()) {
                    hasValidKeyword = true;
                    String lowerKeyword = keyword.trim().toLowerCase();
                    if (contentLower.contains(lowerKeyword)) {
                        isMatch = true;
                        break;
                    }
                }
            }

            // **핵심 수정 부분:** 유효한 포함 키워드가 있었는데 매치되지 않았다면 차단
            if (hasValidKeyword && !isMatch) {
                Log.d(TAG, "내용이 포함 키워드에 매치되지 않아 차단됩니다.");
                return false;
            }
        }

        return true;
    }
}
EOF

    # WebhookSender.java
    cat > "$java_dir/util/WebhookSender.java" << EOF
package $APP_PACKAGE.util;

import android.content.Context;
import android.util.Log;
import $APP_PACKAGE.manager.DataManager;
import $APP_PACKAGE.model.WebhookConfig;
import $APP_PACKAGE.model.MessageHistory;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.List;

public class WebhookSender {
    private static final String TAG = "WebhookSender";
    private ExecutorService executor = Executors.newCachedThreadPool();
    private DataManager dataManager;
    private Context context;

    public WebhookSender(Context context) {
        this.context = context;
        this.dataManager = DataManager.getInstance(context);
    }

    public void sendMessage(WebhookConfig webhook, String message, MessageHistory history) {
        executor.execute(() -> {
            try {
                URL url = new URL(webhook.getUrl());
                HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                connection.setRequestMethod("POST");
                connection.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
                connection.setDoOutput(true);
                connection.setConnectTimeout(10000);
                connection.setReadTimeout(10000);

                String jsonPayload = String.format("{\\"text\\": \\"%s\\"}", escapeJsonString(message));

                try (OutputStream outputStream = connection.getOutputStream()) {
                    outputStream.write(jsonPayload.getBytes(StandardCharsets.UTF_8));
                }

                int responseCode = connection.getResponseCode();
                Log.d(TAG, "Webhook 응답 코드: " + responseCode + " for " + webhook.getName());
                
                if (responseCode >= 200 && responseCode < 300) {
                    // 성공
                    webhook.incrementSuccess();
                    history.setStatus(MessageHistory.Status.SUCCESS);
                    
                    // SMS 발송 (성공한 경우에만)
                    List<String> smsRecipients = webhook.getSmsRecipients();
                    if (smsRecipients != null && !smsRecipients.isEmpty()) {
                        String smsMessage = String.format("[%s] %s", 
                            webhook.getName(), 
                            message.replace("**", "").replace("\\\\n", "\n"));
                        SmsSender.sendSmsToRecipients(context, smsRecipients, smsMessage);
                    }
                } else {
                    // 실패
                    webhook.incrementFailure();
                    history.setStatus(MessageHistory.Status.FAILURE);
                    history.setErrorMessage("HTTP " + responseCode);
                }
                
                connection.disconnect();
                
                // 데이터 업데이트
                dataManager.updateWebhook(webhook);
                dataManager.updateMessageHistory(history);
                
            } catch (Exception e) {
                Log.e(TAG, "Webhook 전송 실패: " + webhook.getName(), e);
                webhook.incrementFailure();
                history.setStatus(MessageHistory.Status.FAILURE);
                history.setErrorMessage(e.getMessage());
                
                // 데이터 업데이트
                dataManager.updateWebhook(webhook);
                dataManager.updateMessageHistory(history);
            }
        });
    }

    private String escapeJsonString(String input) {
        return input.replace("\\\\", "\\\\\\\\")
                   .replace("\\"", "\\\\\\"")
                   .replace("\\n", "\\\\n")
                   .replace("\\r", "\\\\r")
                   .replace("\\t", "\\\\t");
    }

    public void shutdown() {
        if (executor != null && !executor.isShutdown()) {
            executor.shutdown();
        }
    }
}
EOF

    log_success "유틸리티 클래스 생성 완료"
}

create_main_activity() {
    log_info "메인 액티비티 생성 중..."
    
    local java_dir="app/src/main/java/$(echo $APP_PACKAGE | tr '.' '/')"

    # MainActivity.java
    cat > "$java_dir/MainActivity.java" << EOF
package $APP_PACKAGE;

import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;
import androidx.viewpager2.adapter.FragmentStateAdapter;
import androidx.viewpager2.widget.ViewPager2;
import com.google.android.material.tabs.TabLayout;
import com.google.android.material.tabs.TabLayoutMediator;
import $APP_PACKAGE.fragment.StatusFragment;
import $APP_PACKAGE.fragment.WebhookFragment;
import $APP_PACKAGE.fragment.HistoryFragment;
import $APP_PACKAGE.fragment.SettingsFragment;

public class MainActivity extends AppCompatActivity {
    private TabLayout tabLayout;
    private ViewPager2 viewPager;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        setupUI();
    }

    private void setupUI() {
        tabLayout = findViewById(R.id.tabLayout);
        viewPager = findViewById(R.id.viewPager);

        // ViewPager 어댑터 설정
        FragmentStateAdapter adapter = new FragmentStateAdapter(this) {
            @Override
            public Fragment createFragment(int position) {
                switch (position) {
                    case 0: return new StatusFragment();
                    case 1: return new WebhookFragment();
                    case 2: return new HistoryFragment();
                    case 3: return new SettingsFragment();
                    default: return new StatusFragment();
                }
            }

            @Override
            public int getItemCount() {
                return 4;
            }
        };

        viewPager.setAdapter(adapter);

        // TabLayout과 ViewPager 연결
        new TabLayoutMediator(tabLayout, viewPager, (tab, position) -> {
            switch (position) {
                case 0: tab.setText("상태"); break;
                case 1: tab.setText("Webhook"); break;
                case 2: tab.setText("이력"); break;
                case 3: tab.setText("설정"); break;
            }
        }).attach();
    }
}
EOF

    log_success "메인 액티비티 생성 완료"
}

create_fragment_classes() {
    log_info "프래그먼트 클래스 생성 중..."
    
    local java_dir="app/src/main/java/$(echo $APP_PACKAGE | tr '.' '/')"
    mkdir -p "$java_dir/fragment"

    # StatusFragment.java
    cat > "$java_dir/fragment/StatusFragment.java" << EOF
package $APP_PACKAGE.fragment;

import android.Manifest;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.provider.Settings;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;
import $APP_PACKAGE.R;
import $APP_PACKAGE.service.NotificationListenerService;
import $APP_PACKAGE.manager.DataManager;
import $APP_PACKAGE.model.WebhookConfig;
import java.util.List;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;

public class StatusFragment extends Fragment {
    private static final int SMS_PERMISSION_REQUEST = 1001;
    private TextView statusText;
    private Button enableNotificationButton;
    private Button smsPermissionButton;
    private DataManager dataManager;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_status, container, false);
        
        statusText = view.findViewById(R.id.statusText);
        enableNotificationButton = view.findViewById(R.id.enableNotificationButton);
        smsPermissionButton = view.findViewById(R.id.smsPermissionButton);
        
        dataManager = DataManager.getInstance(requireContext());
        
        enableNotificationButton.setOnClickListener(v -> openNotificationSettings());
        smsPermissionButton.setOnClickListener(v -> requestSmsPermission());
        
        return view;
    }

    @Override
    public void onResume() {
        super.onResume();
        updateStatus();
    }

    private void updateStatus() {
        boolean notificationEnabled = isNotificationServiceEnabled();
        boolean smsEnabled = isSmsPermissionGranted();
        List<WebhookConfig> webhooks = dataManager.getWebhooks();
        List<WebhookConfig> enabledWebhooks = dataManager.getEnabledWebhooks();
        
        StringBuilder status = new StringBuilder();
        
        // 서비스 상태
        if (notificationEnabled && smsEnabled) {
            status.append("✅ 모든 서비스가 활성화되었습니다\\n\\n");
        } else {
            status.append("⚠️ 서비스 설정이 필요합니다\\n\\n");
        }
        
        // 권한 상태
        status.append("📱 서비스 상태:\\n");
        status.append("• 알림 접근 권한: ").append(notificationEnabled ? "✅ 활성화" : "❌ 비활성화").append("\\n");
        status.append("• SMS 권한: ").append(smsEnabled ? "✅ 허용" : "❌ 거부").append("\\n\\n");
        
        // Webhook 상태
        status.append("🔗 Webhook 현황:\\n");
        status.append("• 전체 Webhook: ").append(webhooks.size()).append("개\\n");
        status.append("• 활성화된 Webhook: ").append(enabledWebhooks.size()).append("개\\n\\n");
        
        // 통계 정보
        if (!webhooks.isEmpty()) {
            int totalSuccess = 0;
            int totalFailure = 0;
            for (WebhookConfig webhook : webhooks) {
                totalSuccess += webhook.getSuccessCount();
                totalFailure += webhook.getFailureCount();
            }
            
            status.append("📊 전송 통계:\\n");
            status.append("• 성공: ").append(totalSuccess).append("건\\n");
            status.append("• 실패: ").append(totalFailure).append("건\\n");
            
            if (totalSuccess + totalFailure > 0) {
                double successRate = (double) totalSuccess / (totalSuccess + totalFailure) * 100;
                status.append("• 성공률: ").append(String.format("%.1f%%", successRate));
            }
        }
        
        statusText.setText(status.toString());

        enableNotificationButton.setText(notificationEnabled ? 
            "알림 설정 다시 열기" : "알림 접근 권한 설정");
            
        smsPermissionButton.setText(smsEnabled ? 
            "SMS 권한 재설정" : "SMS 권한 허용");
    }

    private boolean isNotificationServiceEnabled() {
        ComponentName cn = new ComponentName(requireContext(), NotificationListenerService.class);
        String flat = Settings.Secure.getString(requireContext().getContentResolver(), "enabled_notification_listeners");
        return flat != null && flat.contains(cn.flattenToString());
    }

    private boolean isSmsPermissionGranted() {
        return ContextCompat.checkSelfPermission(requireContext(), Manifest.permission.RECEIVE_SMS) 
            == PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(requireContext(), Manifest.permission.SEND_SMS) 
            == PackageManager.PERMISSION_GRANTED;
    }

    private void openNotificationSettings() {
        startActivity(new Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS));
        Toast.makeText(requireContext(), "알림 접근 권한에서 'Multi Webhook Manager'를 활성화해주세요.", 
            Toast.LENGTH_LONG).show();
    }
    
    private ActivityResultLauncher<String[]> requestPermissionLauncher = 
        registerForActivityResult(new ActivityResultContracts.RequestMultiplePermissions(), result -> {
            updateStatus();
            Boolean smsGranted = result.get(Manifest.permission.RECEIVE_SMS);
            if (smsGranted != null && smsGranted) {
                Toast.makeText(requireContext(), "SMS 권한이 허용되었습니다.", Toast.LENGTH_SHORT).show();
            } else {
                Toast.makeText(requireContext(), "SMS 권한이 거부되었습니다.", Toast.LENGTH_SHORT).show();
            }
        });
    
    private void requestSmsPermission() {
        if (!isSmsPermissionGranted()) {
            requestPermissionLauncher.launch(new String[]{
                Manifest.permission.RECEIVE_SMS, 
                Manifest.permission.READ_SMS,
                Manifest.permission.SEND_SMS  // 추가
            });
        } else {
            Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
            intent.setData(android.net.Uri.parse("package:" + requireContext().getPackageName()));
            startActivity(intent);
        }
    }
}
EOF

    # WebhookFragment.java
    cat > "$java_dir/fragment/WebhookFragment.java" << EOF
package $APP_PACKAGE.fragment;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.google.android.material.floatingactionbutton.FloatingActionButton;
import $APP_PACKAGE.R;
import $APP_PACKAGE.adapter.WebhookAdapter;
import $APP_PACKAGE.dialog.WebhookConfigDialog;
import $APP_PACKAGE.dialog.ConfirmationDialog;
import $APP_PACKAGE.manager.DataManager;
import $APP_PACKAGE.model.WebhookConfig;
import java.util.List;

public class WebhookFragment extends Fragment implements WebhookAdapter.OnWebhookActionListener {
    private RecyclerView recyclerView;
    private WebhookAdapter adapter;
    private DataManager dataManager;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_webhook, container, false);
        
        recyclerView = view.findViewById(R.id.recyclerView);
        FloatingActionButton fab = view.findViewById(R.id.fab);
        
        dataManager = DataManager.getInstance(requireContext());
        
        setupRecyclerView();
        loadWebhooks();
        
        fab.setOnClickListener(v -> showAddWebhookDialog());
        
        return view;
    }

    private void setupRecyclerView() {
        recyclerView.setLayoutManager(new LinearLayoutManager(requireContext()));
        adapter = new WebhookAdapter(this);
        recyclerView.setAdapter(adapter);
    }

    private void loadWebhooks() {
        List<WebhookConfig> webhooks = dataManager.getWebhooks();
        adapter.updateWebhooks(webhooks);
    }
    
    private void showAddWebhookDialog() {
        WebhookConfigDialog dialog = WebhookConfigDialog.newInstance(null, webhook -> {
            dataManager.addWebhook(webhook);
            loadWebhooks();
            Toast.makeText(requireContext(), "Webhook이 추가되었습니다.", Toast.LENGTH_SHORT).show();
        });
        dialog.show(getParentFragmentManager(), "WebhookConfigDialog");
    }

    @Override
    public void onEditWebhook(WebhookConfig webhook) {
        WebhookConfigDialog dialog = WebhookConfigDialog.newInstance(webhook, updatedWebhook -> {
            dataManager.updateWebhook(updatedWebhook);
            loadWebhooks();
            Toast.makeText(requireContext(), "Webhook이 수정되었습니다.", Toast.LENGTH_SHORT).show();
        });
        dialog.show(getParentFragmentManager(), "WebhookConfigDialog");
    }

    @Override
    public void onDeleteWebhook(WebhookConfig webhook) {
        ConfirmationDialog dialog = ConfirmationDialog.newInstance(
            "Webhook 삭제",
            "'" + webhook.getName() + "'을(를) 삭제하시겠습니까?",
            () -> {
                dataManager.deleteWebhook(webhook.getId());
                loadWebhooks();
                Toast.makeText(requireContext(), "Webhook이 삭제되었습니다.", Toast.LENGTH_SHORT).show();
            }
        );
        dialog.show(getParentFragmentManager(), "ConfirmationDialog");
    }

    @Override
    public void onToggleWebhook(WebhookConfig webhook, boolean enabled) {
        webhook.setEnabled(enabled);
        dataManager.updateWebhook(webhook);
        Toast.makeText(requireContext(), 
            webhook.getName() + "이(가) " + (enabled ? "활성화" : "비활성화") + "되었습니다.", 
            Toast.LENGTH_SHORT).show();
    }
}
EOF

    # HistoryFragment.java
    cat > "$java_dir/fragment/HistoryFragment.java" << EOF
package $APP_PACKAGE.fragment;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;
import androidx.core.view.MenuProvider;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.Lifecycle;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import $APP_PACKAGE.R;
import $APP_PACKAGE.adapter.HistoryAdapter;
import $APP_PACKAGE.dialog.ConfirmationDialog;
import $APP_PACKAGE.manager.DataManager;
import $APP_PACKAGE.model.MessageHistory;
import java.util.List;

public class HistoryFragment extends Fragment {
    private RecyclerView recyclerView;
    private HistoryAdapter adapter;
    private DataManager dataManager;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_history, container, false);
        
        recyclerView = view.findViewById(R.id.recyclerView);
        
        dataManager = DataManager.getInstance(requireContext());
        
        setupRecyclerView();
        loadHistory();
        setupMenu();
        
        return view;
    }

    private void setupRecyclerView() {
        recyclerView.setLayoutManager(new LinearLayoutManager(requireContext()));
        adapter = new HistoryAdapter();
        recyclerView.setAdapter(adapter);
    }

    private void loadHistory() {
        List<MessageHistory> history = dataManager.getMessageHistory();
        adapter.updateHistory(history);
    }

    private void setupMenu() {
        requireActivity().addMenuProvider(new MenuProvider() {
            @Override
            public void onCreateMenu(Menu menu, MenuInflater menuInflater) {
                menuInflater.inflate(R.menu.history_menu, menu);
            }

            @Override
            public boolean onMenuItemSelected(MenuItem menuItem) {
                if (menuItem.getItemId() == R.id.action_clear_history) {
                    showClearHistoryDialog();
                    return true;
                }
                return false;
            }
        }, this, Lifecycle.State.RESUMED);
    }

    private void showClearHistoryDialog() {
        ConfirmationDialog dialog = ConfirmationDialog.newInstance(
            "이력 삭제",
            "모든 발송 이력을 삭제하시겠습니까?",
            () -> {
                dataManager.clearMessageHistory();
                loadHistory();
                Toast.makeText(requireContext(), "모든 이력이 삭제되었습니다.", Toast.LENGTH_SHORT).show();
            }
        );
        dialog.show(getParentFragmentManager(), "ConfirmationDialog");
    }

    @Override
    public void onResume() {
        super.onResume();
        loadHistory();
    }
}
EOF

    # SettingsFragment.java
    cat > "$java_dir/fragment/SettingsFragment.java" << EOF
package $APP_PACKAGE.fragment;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;
import androidx.cardview.widget.CardView;
import androidx.fragment.app.Fragment;
import $APP_PACKAGE.R;
import $APP_PACKAGE.dialog.BackupRestoreDialog;
import $APP_PACKAGE.manager.DataManager;

public class SettingsFragment extends Fragment {
    private DataManager dataManager;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_settings, container, false);
        
        dataManager = DataManager.getInstance(requireContext());
        
        CardView backupCard = view.findViewById(R.id.backupCard);
        CardView restoreCard = view.findViewById(R.id.restoreCard);
        CardView aboutCard = view.findViewById(R.id.aboutCard);
        
        backupCard.setOnClickListener(v -> showBackupDialog());
        restoreCard.setOnClickListener(v -> showRestoreDialog());
        aboutCard.setOnClickListener(v -> showAboutInfo());
        
        return view;
    }
    
    private void showBackupDialog() {
        BackupRestoreDialog dialog = BackupRestoreDialog.newInstance(dataManager, true);
        dialog.show(getParentFragmentManager(), "BackupDialog");
    }
    
    private void showRestoreDialog() {
        BackupRestoreDialog dialog = BackupRestoreDialog.newInstance(dataManager, false);
        dialog.show(getParentFragmentManager(), "RestoreDialog");
    }

    private void showAboutInfo() {
        Toast.makeText(requireContext(), "Multi Webhook Manager v1.0.0", Toast.LENGTH_SHORT).show();
    }
}
EOF

    log_success "프래그먼트 클래스 생성 완료"
}

create_adapter_classes() {
    log_info "어댑터 클래스 생성 중..."
    
    local java_dir="app/src/main/java/$(echo $APP_PACKAGE | tr '.' '/')"
    mkdir -p "$java_dir/adapter"

    # WebhookAdapter.java
    cat > "$java_dir/adapter/WebhookAdapter.java" << EOF
package $APP_PACKAGE.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.Switch;
import android.widget.TextView;
import androidx.recyclerview.widget.RecyclerView;
import $APP_PACKAGE.R;
import $APP_PACKAGE.model.WebhookConfig;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public class WebhookAdapter extends RecyclerView.Adapter<WebhookAdapter.ViewHolder> {
    private List<WebhookConfig> webhooks = new ArrayList<>();
    private OnWebhookActionListener listener;

    public interface OnWebhookActionListener {
        void onEditWebhook(WebhookConfig webhook);
        void onDeleteWebhook(WebhookConfig webhook);
        void onToggleWebhook(WebhookConfig webhook, boolean enabled);
    }

    public WebhookAdapter(OnWebhookActionListener listener) {
        this.listener = listener;
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_webhook, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(ViewHolder holder, int position) {
        WebhookConfig webhook = webhooks.get(position);
        
        holder.nameText.setText(webhook.getName());
        holder.urlText.setText(webhook.getUrl());
        holder.enabledSwitch.setChecked(webhook.isEnabled());
        
        // 통계 정보
        String stats = String.format(Locale.getDefault(), 
            "성공: %d건, 실패: %d건, 성공률: %.1f%%", 
            webhook.getSuccessCount(), 
            webhook.getFailureCount(), 
            webhook.getSuccessRate());
        holder.statsText.setText(stats);
        
        // 마지막 사용 시간
        if (webhook.getLastUsed() > 0) {
            SimpleDateFormat sdf = new SimpleDateFormat("MM/dd HH:mm", Locale.getDefault());
            holder.lastUsedText.setText("마지막 사용: " + sdf.format(new Date(webhook.getLastUsed())));
            holder.lastUsedText.setVisibility(View.VISIBLE);
        } else {
            holder.lastUsedText.setVisibility(View.GONE);
        }
        
        // 이벤트 리스너
        holder.enabledSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (listener != null) {
                listener.onToggleWebhook(webhook, isChecked);
            }
        });
        
        holder.editButton.setOnClickListener(v -> {
            if (listener != null) {
                listener.onEditWebhook(webhook);
            }
        });
        
        holder.deleteButton.setOnClickListener(v -> {
            if (listener != null) {
                listener.onDeleteWebhook(webhook);
            }
        });
    }

    @Override
    public int getItemCount() {
        return webhooks.size();
    }

    public void updateWebhooks(List<WebhookConfig> newWebhooks) {
        this.webhooks.clear();
        this.webhooks.addAll(newWebhooks);
        notifyDataSetChanged();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        TextView nameText, urlText, statsText, lastUsedText;
        Switch enabledSwitch;
        ImageButton editButton, deleteButton;

        ViewHolder(View itemView) {
            super(itemView);
            nameText = itemView.findViewById(R.id.nameText);
            urlText = itemView.findViewById(R.id.urlText);
            statsText = itemView.findViewById(R.id.statsText);
            lastUsedText = itemView.findViewById(R.id.lastUsedText);
            enabledSwitch = itemView.findViewById(R.id.enabledSwitch);
            editButton = itemView.findViewById(R.id.editButton);
            deleteButton = itemView.findViewById(R.id.deleteButton);
        }
    }
}
EOF

    # HistoryAdapter.java
    cat > "$java_dir/adapter/HistoryAdapter.java" << EOF
package $APP_PACKAGE.adapter;

import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.recyclerview.widget.RecyclerView;
import $APP_PACKAGE.R;
import $APP_PACKAGE.model.MessageHistory;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public class HistoryAdapter extends RecyclerView.Adapter<HistoryAdapter.ViewHolder> {
    private List<MessageHistory> history = new ArrayList<>();

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_history, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(ViewHolder holder, int position) {
        MessageHistory message = history.get(position);
        
        // 시간
        SimpleDateFormat sdf = new SimpleDateFormat("MM/dd HH:mm:ss", Locale.getDefault());
        holder.timeText.setText(sdf.format(new Date(message.getTimestamp())));
        
        // 타입
        String typeText = message.getType() == MessageHistory.MessageType.SMS ? "SMS" : "알림";
        holder.typeText.setText(typeText);
        
        // 발신자/앱
        holder.senderText.setText(message.getSender());
        
        // 제목 (알림인 경우만)
        if (message.getType() == MessageHistory.MessageType.NOTIFICATION && 
            message.getTitle() != null && !message.getTitle().isEmpty()) {
            holder.titleText.setText(message.getTitle());
            holder.titleText.setVisibility(View.VISIBLE);
        } else {
            holder.titleText.setVisibility(View.GONE);
        }
        
        // 내용
        String content = message.getContent();
        if (content != null && content.length() > 100) {
            content = content.substring(0, 97) + "...";
        }
        holder.contentText.setText(content);
        
        // Webhook 이름
        holder.webhookText.setText(message.getWebhookName());
        
        // 상태
        switch (message.getStatus()) {
            case SUCCESS:
                holder.statusText.setText("✅ 성공");
                holder.statusText.setTextColor(Color.GREEN);
                break;
            case FAILURE:
                holder.statusText.setText("❌ 실패");
                holder.statusText.setTextColor(Color.RED);
                if (message.getErrorMessage() != null) {
                    holder.statusText.setText("❌ 실패: " + message.getErrorMessage());
                }
                break;
            case PENDING:
                holder.statusText.setText("⏳ 대기");
                holder.statusText.setTextColor(Color.GRAY);
                break;
        }
    }

    @Override
    public int getItemCount() {
        return history.size();
    }

    public void updateHistory(List<MessageHistory> newHistory) {
        this.history.clear();
        this.history.addAll(newHistory);
        notifyDataSetChanged();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        TextView timeText, typeText, senderText, titleText, contentText, webhookText, statusText;

        ViewHolder(View itemView) {
            super(itemView);
            timeText = itemView.findViewById(R.id.timeText);
            typeText = itemView.findViewById(R.id.typeText);
            senderText = itemView.findViewById(R.id.senderText);
            titleText = itemView.findViewById(R.id.titleText);
            contentText = itemView.findViewById(R.id.contentText);
            webhookText = itemView.findViewById(R.id.webhookText);
            statusText = itemView.findViewById(R.id.statusText);
        }
    }
}
EOF

    log_success "어댑터 클래스 생성 완료"
}

create_dialog_classes() {
    log_info "다이얼로그 클래스 생성 중..."
    
    local java_dir="app/src/main/java/$(echo $APP_PACKAGE | tr '.' '/')"
    mkdir -p "$java_dir/dialog"

    # WebhookConfigDialog.java
    cat > "$java_dir/dialog/WebhookConfigDialog.java" << EOF
package $APP_PACKAGE.dialog;

import android.app.Dialog;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.EditText;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.DialogFragment;
import $APP_PACKAGE.R;
import $APP_PACKAGE.model.WebhookConfig;
import java.util.ArrayList;

public class WebhookConfigDialog extends DialogFragment {
    private WebhookConfig webhook;
    private OnWebhookSaveListener listener;
    
    private EditText nameEdit, urlEdit;
    private EditText targetAppsEdit, notificationIncludeEdit, notificationExcludeEdit;
    private EditText titleIncludeEdit, titleExcludeEdit;
    private EditText smsAllowedSendersEdit, smsIncludeEdit, smsExcludeEdit;
    private EditText smsRecipientsEdit;

    public interface OnWebhookSaveListener {
        void onSave(WebhookConfig webhook);
    }

    public static WebhookConfigDialog newInstance(WebhookConfig webhook, OnWebhookSaveListener listener) {
        WebhookConfigDialog dialog = new WebhookConfigDialog();
        dialog.webhook = webhook;
        dialog.listener = listener;
        return dialog;
    }

    @NonNull
    @Override
    public Dialog onCreateDialog(@Nullable Bundle savedInstanceState) {
        View view = LayoutInflater.from(getContext()).inflate(R.layout.dialog_webhook_config, null);
        
        initViews(view);
        
        if (webhook != null) {
            loadWebhookData();
        }

        return new AlertDialog.Builder(requireContext())
                .setTitle(webhook == null ? "Webhook 추가" : "Webhook 수정")
                .setView(view)
                .setPositiveButton("저장", null)
                .setNegativeButton("취소", (dialog, which) -> dismiss())
                .create();
    }

    @Override
    public void onStart() {
        super.onStart();
        AlertDialog dialog = (AlertDialog) getDialog();
        if (dialog != null) {
            dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(v -> saveWebhook());
        }
    }

    private void initViews(View view) {
        nameEdit = view.findViewById(R.id.nameEdit);
        urlEdit = view.findViewById(R.id.urlEdit);
        targetAppsEdit = view.findViewById(R.id.targetAppsEdit);
        notificationIncludeEdit = view.findViewById(R.id.notificationIncludeEdit);
        notificationExcludeEdit = view.findViewById(R.id.notificationExcludeEdit);
        titleIncludeEdit = view.findViewById(R.id.titleIncludeEdit);
        titleExcludeEdit = view.findViewById(R.id.titleExcludeEdit);
        smsAllowedSendersEdit = view.findViewById(R.id.smsAllowedSendersEdit);
        smsIncludeEdit = view.findViewById(R.id.smsIncludeEdit);
        smsExcludeEdit = view.findViewById(R.id.smsExcludeEdit);
        smsRecipientsEdit = view.findViewById(R.id.smsRecipientsEdit);
    }

    private void loadWebhookData() {
        nameEdit.setText(webhook.getName());
        urlEdit.setText(webhook.getUrl());
        targetAppsEdit.setText(String.join(",", webhook.getTargetApps()));
        notificationIncludeEdit.setText(String.join(",", webhook.getNotificationIncludeKeywords()));
        notificationExcludeEdit.setText(String.join(",", webhook.getNotificationExcludeKeywords()));
        titleIncludeEdit.setText(String.join(",", webhook.getTitleIncludeKeywords()));
        titleExcludeEdit.setText(String.join(",", webhook.getTitleExcludeKeywords()));
        smsAllowedSendersEdit.setText(String.join(",", webhook.getSmsAllowedSenders()));
        smsIncludeEdit.setText(String.join(",", webhook.getSmsIncludeKeywords()));
        smsExcludeEdit.setText(String.join(",", webhook.getSmsExcludeKeywords()));
        smsRecipientsEdit.setText(String.join(",", webhook.getSmsRecipients()));
    }

    private void saveWebhook() {
        String name = nameEdit.getText().toString().trim();
        String url = urlEdit.getText().toString().trim();

        if (TextUtils.isEmpty(name)) {
            Toast.makeText(getContext(), "이름을 입력해주세요.", Toast.LENGTH_SHORT).show();
            return;
        }

        if (TextUtils.isEmpty(url)) {
            Toast.makeText(getContext(), "URL을 입력해주세요.", Toast.LENGTH_SHORT).show();
            return;
        }

        if (!url.startsWith("http://") && !url.startsWith("https://")) {
            Toast.makeText(getContext(), "올바른 URL을 입력해주세요.", Toast.LENGTH_SHORT).show();
            return;
        }

        WebhookConfig savedWebhook = webhook != null ? webhook : new WebhookConfig();
        savedWebhook.setName(name);
        savedWebhook.setUrl(url);
        
        savedWebhook.setTargetApps(parseStringList(targetAppsEdit.getText().toString()));
        savedWebhook.setNotificationIncludeKeywords(parseStringList(notificationIncludeEdit.getText().toString()));
        savedWebhook.setNotificationExcludeKeywords(parseStringList(notificationExcludeEdit.getText().toString()));
        savedWebhook.setTitleIncludeKeywords(parseStringList(titleIncludeEdit.getText().toString()));
        savedWebhook.setTitleExcludeKeywords(parseStringList(titleExcludeEdit.getText().toString()));
        savedWebhook.setSmsAllowedSenders(parseStringList(smsAllowedSendersEdit.getText().toString()));
        savedWebhook.setSmsIncludeKeywords(parseStringList(smsIncludeEdit.getText().toString()));
        savedWebhook.setSmsExcludeKeywords(parseStringList(smsExcludeEdit.getText().toString()));
        savedWebhook.setSmsRecipients(parseStringList(smsRecipientsEdit.getText().toString()));

        if (listener != null) {
            listener.onSave(savedWebhook);
        }
        dismiss();
    }

    private ArrayList<String> parseStringList(String input) {
        ArrayList<String> result = new ArrayList<>();
        if (!TextUtils.isEmpty(input)) {
            String[] items = input.split(",");
            for (String item : items) {
                String trimmed = item.trim();
                if (!trimmed.isEmpty()) {
                    result.add(trimmed);
                }
            }
        }
        return result;
    }
}
EOF

    # BackupRestoreDialog.java
    cat > "$java_dir/dialog/BackupRestoreDialog.java" << EOF
package $APP_PACKAGE.dialog;

import android.app.Dialog;
import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.DialogFragment;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import $APP_PACKAGE.R;
import $APP_PACKAGE.manager.DataManager;
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class BackupRestoreDialog extends DialogFragment {
    private DataManager dataManager;
    private boolean isBackup;
    
    private ActivityResultLauncher<String> createDocumentLauncher;
    private ActivityResultLauncher<String[]> openDocumentLauncher;

    public static BackupRestoreDialog newInstance(DataManager dataManager, boolean isBackup) {
        BackupRestoreDialog dialog = new BackupRestoreDialog();
        Bundle args = new Bundle();
        args.putBoolean("isBackup", isBackup);
        dialog.setArguments(args);
        dialog.dataManager = dataManager;
        return dialog;
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (getArguments() != null) {
            isBackup = getArguments().getBoolean("isBackup", true);
        }
        
        createDocumentLauncher = registerForActivityResult(
            new ActivityResultContracts.CreateDocument("application/json"),
            uri -> {
                if (uri != null) {
                    performBackupToFile(uri);
                }
            }
        );
        
        openDocumentLauncher = registerForActivityResult(
            new ActivityResultContracts.OpenDocument(),
            uri -> {
                if (uri != null) {
                    performRestoreFromFile(uri);
                }
            }
        );
    }

    @NonNull
    @Override
    public Dialog onCreateDialog(@Nullable Bundle savedInstanceState) {
        View view = LayoutInflater.from(getContext()).inflate(R.layout.dialog_backup_restore, null);
        
        TextView messageText = view.findViewById(R.id.messageText);
        Button actionButton = view.findViewById(R.id.actionButton);
        Button cancelButton = view.findViewById(R.id.cancelButton);
        
        if (isBackup) {
            messageText.setText("모든 Webhook 설정과 발송 이력을 파일로 내보냅니다.\\n\\n파일명: backup_" + 
                new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(new Date()) + ".json");
            actionButton.setText("백업하기");
            actionButton.setOnClickListener(v -> startBackup());
        } else {
            messageText.setText("백업 파일에서 데이터를 복구합니다.\\n\\n주의: 현재 데이터가 모두 덮어쓰여집니다.");
            actionButton.setText("파일 선택");
            actionButton.setOnClickListener(v -> startRestore());
        }
        
        cancelButton.setOnClickListener(v -> dismiss());

        return new AlertDialog.Builder(requireContext())
                .setTitle(isBackup ? "데이터 백업" : "데이터 복구")
                .setView(view)
                .create();
    }

    private void startBackup() {
        String fileName = "backup_" + new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(new Date()) + ".json";
        createDocumentLauncher.launch(fileName);
    }

    private void startRestore() {
        openDocumentLauncher.launch(new String[]{"application/json", "text/plain"});
    }

    private void performBackupToFile(Uri uri) {
        try {
            String backupData = dataManager.exportData();
            
            OutputStream outputStream = requireContext().getContentResolver().openOutputStream(uri);
            if (outputStream != null) {
                outputStream.write(backupData.getBytes());
                outputStream.close();
                
                Toast.makeText(getContext(), "백업이 완료되었습니다.", Toast.LENGTH_SHORT).show();
                dismiss();
            }
        } catch (Exception e) {
            Toast.makeText(getContext(), "백업 실패: " + e.getMessage(), Toast.LENGTH_SHORT).show();
        }
    }

    private void performRestoreFromFile(Uri uri) {
        try {
            InputStream inputStream = requireContext().getContentResolver().openInputStream(uri);
            if (inputStream != null) {
                BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
                StringBuilder content = new StringBuilder();
                String line;
                
                while ((line = reader.readLine()) != null) {
                    content.append(line);
                }
                
                reader.close();
                inputStream.close();
                
                boolean success = dataManager.importData(content.toString());
                if (success) {
                    Toast.makeText(getContext(), "복구가 완료되었습니다.", Toast.LENGTH_SHORT).show();
                    dismiss();
                } else {
                    Toast.makeText(getContext(), "복구 실패: 잘못된 파일 형식입니다.", Toast.LENGTH_SHORT).show();
                }
            }
        } catch (Exception e) {
            Toast.makeText(getContext(), "복구 실패: " + e.getMessage(), Toast.LENGTH_SHORT).show();
        }
    }
}
EOF

    # 새로운 ConfirmationDialog.java 추가 (삭제 확인용)
    cat > "$java_dir/dialog/ConfirmationDialog.java" << EOF
package $APP_PACKAGE.dialog;

import android.app.Dialog;
import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.DialogFragment;

public class ConfirmationDialog extends DialogFragment {
    private String title;
    private String message;
    private OnConfirmListener listener;

    public interface OnConfirmListener {
        void onConfirm();
    }

    public static ConfirmationDialog newInstance(String title, String message, OnConfirmListener listener) {
        ConfirmationDialog dialog = new ConfirmationDialog();
        dialog.title = title;
        dialog.message = message;
        dialog.listener = listener;
        return dialog;
    }

    @NonNull
    @Override
    public Dialog onCreateDialog(@Nullable Bundle savedInstanceState) {
        return new AlertDialog.Builder(requireContext())
                .setTitle(title)
                .setMessage(message)
                .setPositiveButton("확인", (dialog, which) -> {
                    if (listener != null) {
                        listener.onConfirm();
                    }
                })
                .setNegativeButton("취소", null)
                .create();
    }
}
EOF

    log_success "다이얼로그 클래스 생성 완료"
}

create_layout_resources() {
    log_info "레이아웃 리소스 생성 중..."
    
    # activity_main.xml
    cat > app/src/main/res/layout/activity_main.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">

    <com.google.android.material.tabs.TabLayout
        android:id="@+id/tabLayout"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        app:tabMode="fixed"
        app:tabGravity="fill" />

    <androidx.viewpager2.widget.ViewPager2
        android:id="@+id/viewPager"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1" />

</LinearLayout>
EOF

    # fragment_status.xml
    cat > app/src/main/res/layout/fragment_status.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<ScrollView xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:padding="16dp">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical">

        <androidx.cardview.widget.CardView
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginBottom="16dp"
            app:cardCornerRadius="8dp"
            app:cardElevation="4dp">

            <LinearLayout
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:orientation="vertical"
                android:padding="16dp">

                <TextView
                    android:id="@+id/statusText"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:text="상태 확인 중..."
                    android:textSize="14sp"
                    android:lineSpacingExtra="4dp"
                    android:fontFamily="monospace" />

            </LinearLayout>

        </androidx.cardview.widget.CardView>

        <Button
            android:id="@+id/enableNotificationButton"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="알림 접근 권한 설정"
            android:layout_marginBottom="8dp" />

        <Button
            android:id="@+id/smsPermissionButton"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="SMS 권한 허용" />

    </LinearLayout>

</ScrollView>
EOF

    # fragment_webhook.xml
    cat > app/src/main/res/layout/fragment_webhook.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<androidx.coordinatorlayout.widget.CoordinatorLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/recyclerView"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:padding="8dp" />

    <com.google.android.material.floatingactionbutton.FloatingActionButton
        android:id="@+id/fab"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_gravity="bottom|end"
        android:layout_margin="16dp"
        android:src="@drawable/ic_add"
        app:tint="@android:color/white" />

</androidx.coordinatorlayout.widget.CoordinatorLayout>
EOF

    # fragment_history.xml
    cat > app/src/main/res/layout/fragment_history.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<androidx.recyclerview.widget.RecyclerView xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/recyclerView"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:padding="8dp" />
EOF

    # fragment_settings.xml
    cat > app/src/main/res/layout/fragment_settings.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<ScrollView xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:padding="16dp">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical">

        <androidx.cardview.widget.CardView
            android:id="@+id/backupCard"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginBottom="8dp"
            app:cardCornerRadius="8dp"
            app:cardElevation="4dp"
            android:clickable="true"
            android:focusable="true"
            android:foreground="?android:attr/selectableItemBackground">

            <LinearLayout
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:orientation="vertical"
                android:padding="16dp">

                <TextView
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:text="데이터 백업"
                    android:textSize="18sp"
                    android:textStyle="bold" />

                <TextView
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:text="Webhook 설정과 발송 이력을 파일로 내보냅니다"
                    android:textSize="14sp"
                    android:layout_marginTop="4dp" />

            </LinearLayout>

        </androidx.cardview.widget.CardView>

        <androidx.cardview.widget.CardView
            android:id="@+id/restoreCard"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginBottom="8dp"
            app:cardCornerRadius="8dp"
            app:cardElevation="4dp"
            android:clickable="true"
            android:focusable="true"
            android:foreground="?android:attr/selectableItemBackground">

            <LinearLayout
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:orientation="vertical"
                android:padding="16dp">

                <TextView
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:text="데이터 복구"
                    android:textSize="18sp"
                    android:textStyle="bold" />

                <TextView
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:text="백업 파일에서 데이터를 불러옵니다"
                    android:textSize="14sp"
                    android:layout_marginTop="4dp" />

            </LinearLayout>

        </androidx.cardview.widget.CardView>

        <androidx.cardview.widget.CardView
            android:id="@+id/aboutCard"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            app:cardCornerRadius="8dp"
            app:cardElevation="4dp"
            android:clickable="true"
            android:focusable="true"
            android:foreground="?android:attr/selectableItemBackground">

            <LinearLayout
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:orientation="vertical"
                android:padding="16dp">

                <TextView
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:text="앱 정보"
                    android:textSize="18sp"
                    android:textStyle="bold" />

                <TextView
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:text="Multi Webhook Manager v1.0.0"
                    android:textSize="14sp"
                    android:layout_marginTop="4dp" />

            </LinearLayout>

        </androidx.cardview.widget.CardView>

    </LinearLayout>

</ScrollView>
EOF

    log_success "레이아웃 리소스 생성 완료"
}

create_item_layouts() {
    log_info "아이템 레이아웃 생성 중..."
    
    # item_webhook.xml
    cat > app/src/main/res/layout/item_webhook.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<androidx.cardview.widget.CardView xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:layout_margin="4dp"
    app:cardCornerRadius="8dp"
    app:cardElevation="4dp">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        android:padding="16dp">

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="horizontal"
            android:gravity="center_vertical">

            <LinearLayout
                android:layout_width="0dp"
                android:layout_height="wrap_content"
                android:layout_weight="1"
                android:orientation="vertical">

                <TextView
                    android:id="@+id/nameText"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:text="Webhook Name"
                    android:textSize="16sp"
                    android:textStyle="bold" />

                <TextView
                    android:id="@+id/urlText"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:text="https://example.com/webhook"
                    android:textSize="12sp"
                    android:textColor="@android:color/darker_gray"
                    android:layout_marginTop="2dp" />

            </LinearLayout>

            <Switch
                android:id="@+id/enabledSwitch"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_marginStart="8dp" />

        </LinearLayout>

        <TextView
            android:id="@+id/statsText"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="성공: 0건, 실패: 0건, 성공률: 0%"
            android:textSize="12sp"
            android:layout_marginTop="8dp" />

        <TextView
            android:id="@+id/lastUsedText"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="마지막 사용: 없음"
            android:textSize="11sp"
            android:textColor="@android:color/darker_gray"
            android:layout_marginTop="2dp" />

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="horizontal"
            android:gravity="end"
            android:layout_marginTop="8dp">

            <ImageButton
                android:id="@+id/editButton"
                android:layout_width="36dp"
                android:layout_height="36dp"
                android:src="@drawable/ic_edit"
                android:background="?attr/selectableItemBackgroundBorderless"
                android:layout_marginEnd="4dp" />

            <ImageButton
                android:id="@+id/deleteButton"
                android:layout_width="36dp"
                android:layout_height="36dp"
                android:src="@drawable/ic_delete"
                android:background="?attr/selectableItemBackgroundBorderless" />

        </LinearLayout>

    </LinearLayout>

</androidx.cardview.widget.CardView>
EOF

    # item_history.xml
    cat > app/src/main/res/layout/item_history.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<androidx.cardview.widget.CardView xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:layout_margin="4dp"
    app:cardCornerRadius="8dp"
    app:cardElevation="2dp">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        android:padding="12dp">

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="horizontal"
            android:gravity="center_vertical">

            <TextView
                android:id="@+id/timeText"
                android:layout_width="0dp"
                android:layout_height="wrap_content"
                android:layout_weight="1"
                android:text="12/25 14:30:15"
                android:textSize="12sp"
                android:textColor="@android:color/darker_gray" />

            <TextView
                android:id="@+id/typeText"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="알림"
                android:textSize="11sp"
                android:background="@drawable/background_tag"
                android:padding="4dp"
                android:layout_marginStart="8dp" />

            <TextView
                android:id="@+id/statusText"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="✅ 성공"
                android:textSize="11sp"
                android:layout_marginStart="4dp" />

        </LinearLayout>

        <TextView
            android:id="@+id/senderText"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="com.kakao.talk"
            android:textSize="14sp"
            android:textStyle="bold"
            android:layout_marginTop="4dp" />

        <TextView
            android:id="@+id/titleText"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="메시지 제목"
            android:textSize="13sp"
            android:layout_marginTop="2dp"
            android:visibility="gone" />

        <TextView
            android:id="@+id/contentText"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="메시지 내용..."
            android:textSize="12sp"
            android:layout_marginTop="2dp"
            android:maxLines="2"
            android:ellipsize="end" />

        <TextView
            android:id="@+id/webhookText"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="Webhook: Main Server"
            android:textSize="11sp"
            android:textColor="@android:color/darker_gray"
            android:layout_marginTop="4dp" />

    </LinearLayout>

</androidx.cardview.widget.CardView>
EOF

    log_success "아이템 레이아웃 생성 완료"
}

create_dialog_layouts() {
    log_info "다이얼로그 레이아웃 생성 중..."
    
    # dialog_webhook_config.xml
    cat > app/src/main/res/layout/dialog_webhook_config.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<ScrollView xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:padding="16dp">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical">

        <TextView
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="기본 설정"
            android:textSize="16sp"
            android:textStyle="bold"
            android:layout_marginBottom="8dp" />

        <com.google.android.material.textfield.TextInputLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginBottom="8dp">

            <com.google.android.material.textfield.TextInputEditText
                android:id="@+id/nameEdit"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:hint="Webhook 이름" />

        </com.google.android.material.textfield.TextInputLayout>

        <com.google.android.material.textfield.TextInputLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginBottom="16dp">

            <com.google.android.material.textfield.TextInputEditText
                android:id="@+id/urlEdit"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:hint="Webhook URL"
                android:inputType="textUri" />

        </com.google.android.material.textfield.TextInputLayout>

        <TextView
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="알림 필터링"
            android:textSize="16sp"
            android:textStyle="bold"
            android:layout_marginBottom="8dp" />

        <com.google.android.material.textfield.TextInputLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginBottom="8dp">

            <com.google.android.material.textfield.TextInputEditText
                android:id="@+id/targetAppsEdit"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:hint="대상 앱 (패키지명, 쉼표로 구분)" />

        </com.google.android.material.textfield.TextInputLayout>

        <com.google.android.material.textfield.TextInputLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginBottom="8dp">

            <com.google.android.material.textfield.TextInputEditText
                android:id="@+id/notificationIncludeEdit"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:hint="알림 포함 키워드 (쉼표로 구분)" />

        </com.google.android.material.textfield.TextInputLayout>

        <com.google.android.material.textfield.TextInputLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginBottom="8dp">

            <com.google.android.material.textfield.TextInputEditText
                android:id="@+id/notificationExcludeEdit"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:hint="알림 제외 키워드 (쉼표로 구분)" />

        </com.google.android.material.textfield.TextInputLayout>

        <com.google.android.material.textfield.TextInputLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginBottom="8dp">

            <com.google.android.material.textfield.TextInputEditText
                android:id="@+id/titleIncludeEdit"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:hint="제목 포함 키워드 (쉼표로 구분)" />

        </com.google.android.material.textfield.TextInputLayout>

        <com.google.android.material.textfield.TextInputLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginBottom="16dp">

            <com.google.android.material.textfield.TextInputEditText
                android:id="@+id/titleExcludeEdit"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:hint="제목 제외 키워드 (쉼표로 구분)" />

        </com.google.android.material.textfield.TextInputLayout>

        <TextView
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="SMS 필터링"
            android:textSize="16sp"
            android:textStyle="bold"
            android:layout_marginBottom="8dp" />

        <com.google.android.material.textfield.TextInputLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginBottom="8dp">

            <com.google.android.material.textfield.TextInputEditText
                android:id="@+id/smsAllowedSendersEdit"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:hint="SMS 허용 발신자 (쉼표로 구분)" />

        </com.google.android.material.textfield.TextInputLayout>

        <com.google.android.material.textfield.TextInputLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginBottom="8dp">

            <com.google.android.material.textfield.TextInputEditText
                android:id="@+id/smsIncludeEdit"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:hint="SMS 포함 키워드 (쉼표로 구분)" />

        </com.google.android.material.textfield.TextInputLayout>

        <com.google.android.material.textfield.TextInputLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content">

            <com.google.android.material.textfield.TextInputEditText
                android:id="@+id/smsExcludeEdit"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:hint="SMS 제외 키워드 (쉼표로 구분)" />

        </com.google.android.material.textfield.TextInputLayout>
        
        <TextView
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="SMS 발송"
            android:textSize="16sp"
            android:textStyle="bold"
            android:layout_marginTop="16dp"
            android:layout_marginBottom="8dp" />

        <com.google.android.material.textfield.TextInputLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content">

            <com.google.android.material.textfield.TextInputEditText
                android:id="@+id/smsRecipientsEdit"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:hint="SMS 전송 대상 (전화번호, 쉼표로 구분)"
                android:inputType="phone" />

        </com.google.android.material.textfield.TextInputLayout>

    </LinearLayout>

</ScrollView>
EOF

    # dialog_backup_restore.xml
    cat > app/src/main/res/layout/dialog_backup_restore.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    android:padding="24dp">

    <TextView
        android:id="@+id/messageText"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="메시지"
        android:textSize="14sp"
        android:layout_marginBottom="24dp" />

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:gravity="end">

        <Button
            android:id="@+id/cancelButton"
            style="@style/Widget.Material3.Button.TextButton"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="취소"
            android:layout_marginEnd="8dp" />

        <Button
            android:id="@+id/actionButton"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="실행" />

    </LinearLayout>

</LinearLayout>
EOF

    log_success "다이얼로그 레이아웃 생성 완료"
}

create_values_resources() {
    log_info "값 리소스 생성 중..."
    
    # strings.xml
    cat > app/src/main/res/values/strings.xml << EOF
<resources>
    <string name="app_name">$APP_NAME</string>
    
    <!-- Tab titles -->
    <string name="tab_status">상태</string>
    <string name="tab_webhook">Webhook</string>
    <string name="tab_history">이력</string>
    <string name="tab_settings">설정</string>
    
    <!-- Status messages -->
    <string name="checking_status">상태 확인 중…</string>
    <string name="service_enabled_message">모든 서비스가 활성화되었습니다.</string>
    <string name="service_disabled_message">서비스 설정이 필요합니다.</string>
    
    <!-- Button texts -->
    <string name="notification_access_settings">알림 접근 권한 설정</string>
    <string name="reopen_settings">설정 다시 열기</string>
    <string name="sms_permission_allow">SMS 권한 허용</string>
    <string name="sms_permission_reset">SMS 권한 재설정</string>
    
    <!-- Toast messages -->
    <string name="enable_notification_access">알림 접근 권한에서 \'%1\$s\'을 활성화해주세요.</string>
    <string name="sms_permission_granted">SMS 권한이 허용되었습니다.</string>
    <string name="sms_permission_denied">SMS 권한이 거부되었습니다.</string>
    
    <!-- Webhook messages -->
    <string name="webhook_added">Webhook이 추가되었습니다.</string>
    <string name="webhook_updated">Webhook이 수정되었습니다.</string>
    <string name="webhook_deleted">Webhook이 삭제되었습니다.</string>
    <string name="webhook_enabled">%1\$s이(가) 활성화되었습니다.</string>
    <string name="webhook_disabled">%1\$s이(가) 비활성화되었습니다.</string>
    
    <!-- Dialog messages -->
    <string name="dialog_webhook_delete_title">Webhook 삭제</string>
    <string name="dialog_webhook_delete_message">\'%1\$s\'을(를) 삭제하시겠습니까?</string>
    <string name="dialog_history_clear_title">이력 삭제</string>
    <string name="dialog_history_clear_message">모든 발송 이력을 삭제하시겠습니까?</string>
    <string name="history_cleared">모든 이력이 삭제되었습니다.</string>
    
    <!-- Common buttons -->
    <string name="save">저장</string>
    <string name="cancel">취소</string>
    <string name="delete">삭제</string>
    <string name="ok">확인</string>
    
    <!-- Input hints -->
    <string name="hint_webhook_name">Webhook 이름</string>
    <string name="hint_webhook_url">Webhook URL</string>
    <string name="hint_target_apps">대상 앱 (패키지명, 쉼표로 구분)</string>
    <string name="hint_notification_include">알림 포함 키워드 (쉼표로 구분)</string>
    <string name="hint_notification_exclude">알림 제외 키워드 (쉼표로 구분)</string>
    <string name="hint_title_include">제목 포함 키워드 (쉼표로 구분)</string>
    <string name="hint_title_exclude">제목 제외 키워드 (쉼표로 구분)</string>
    <string name="hint_sms_senders">SMS 허용 발신자 (쉼표로 구분)</string>
    <string name="hint_sms_include">SMS 포함 키워드 (쉼표로 구분)</string>
    <string name="hint_sms_exclude">SMS 제외 키워드 (쉼표로 구분)</string>
    <string name="hint_sms_recipients">SMS 전송 대상 (전화번호, 쉼표로 구분)</string>
    
    <!-- Validation messages -->
    <string name="error_name_required">이름을 입력해주세요.</string>
    <string name="error_url_required">URL을 입력해주세요.</string>
    <string name="error_invalid_url">올바른 URL을 입력해주세요.</string>

</resources>
EOF

    # colors.xml
    cat > app/src/main/res/values/colors.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="purple_200">#FFBB86FC</color>
    <color name="purple_500">#FF6200EE</color>
    <color name="purple_700">#FF3700B3</color>
    <color name="teal_200">#FF03DAC5</color>
    <color name="teal_700">#FF018786</color>
    <color name="black">#FF000000</color>
    <color name="white">#FFFFFFFF</color>
    <color name="light_gray">#FFF5F5F5</color>
    <color name="dark_gray">#FF757575</color>
    <color name="success_green">#FF4CAF50</color>
    <color name="error_red">#FFF44336</color>
    <color name="warning_orange">#FFFF9800</color>
    <color name="tag_background">#FFE0E0E0</color>
</resources>
EOF

    # themes.xml
    cat > app/src/main/res/values/themes.xml << 'EOF'
<resources xmlns:tools="http://schemas.android.com/tools">
    <!-- Base application theme. -->
    <style name="Base.Theme.MultiWebhookManager" parent="Theme.Material3.DayNight">
        <!-- Customize your light theme here. -->
        <item name="colorPrimary">@color/purple_500</item>
        <item name="colorPrimaryVariant">@color/purple_700</item>
        <item name="colorOnPrimary">@color/white</item>
        <item name="colorSecondary">@color/teal_200</item>
        <item name="colorSecondaryVariant">@color/teal_700</item>
        <item name="colorOnSecondary">@color/black</item>
    </style>

    <style name="Theme.MultiWebhookManager" parent="Base.Theme.MultiWebhookManager" />
</resources>
EOF

    log_success "값 리소스 생성 완료"
}

create_drawable_resources() {
    log_info "Drawable 리소스 생성 중..."
    
    # background_rounded.xml
    cat > app/src/main/res/drawable/background_rounded.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="@color/light_gray" />
    <corners android:radius="8dp" />
    <stroke android:width="1dp" android:color="@color/dark_gray" />
</shape>
EOF

    # background_tag.xml
    cat > app/src/main/res/drawable/background_tag.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="@color/tag_background" />
    <corners android:radius="12dp" />
</shape>
EOF

    # ic_add.xml
    cat > app/src/main/res/drawable/ic_add.xml << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="?attr/colorOnPrimary">
    <path
        android:fillColor="@android:color/white"
        android:pathData="M19,13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z"/>
</vector>
EOF

    # ic_edit.xml
    cat > app/src/main/res/drawable/ic_edit.xml << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="?attr/colorOnSurface">
    <path
        android:fillColor="@android:color/white"
        android:pathData="M3,17.25V21h3.75L17.81,9.94l-3.75,-3.75L3,17.25zM20.71,7.04c0.39,-0.39 0.39,-1.02 0,-1.41l-2.34,-2.34c-0.39,-0.39 -1.02,-0.39 -1.41,0l-1.83,1.83 3.75,3.75 1.83,-1.83z"/>
</vector>
EOF

    # ic_delete.xml
    cat > app/src/main/res/drawable/ic_delete.xml << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="?attr/colorError">
    <path
        android:fillColor="@android:color/white"
        android:pathData="M6,19c0,1.1 0.9,2 2,2h8c1.1,0 2,-0.9 2,-2V7H6v12zM19,4h-3.5l-1,-1h-5l-1,1H5v2h14V4z"/>
</vector>
EOF

    # ic_launcher_background.xml
    cat > app/src/main/res/drawable/ic_launcher_background.xml << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:fillColor="#3DDC84"
        android:pathData="M0,0h108v108h-108z" />
    <path android:fillColor="#00000000"
        android:pathData="M9,0L9,108L0,108L0,0L9,0Z" />
</vector>
EOF

    # ic_launcher_foreground.xml
    cat > app/src/main/res/drawable/ic_launcher_foreground.xml << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <group android:scaleX="0.58"
        android:scaleY="0.58"
        android:translateX="22.68"
        android:translateY="22.68">
        <path android:fillColor="#FFFFFF"
            android:pathData="M12,2C6.48,2 2,6.48 2,12s4.48,10 10,10 10,-4.48 10,-10S17.52,2 12,2zM13,17h-2v-6h2v6zM13,9h-2L11,7h2v2z"/>
    </group>
</vector>
EOF

    log_success "Drawable 리소스 생성 완료"
}

create_menu_resources() {
    log_info "메뉴 리소스 생성 중..."
    
    # history_menu.xml
    cat > app/src/main/res/menu/history_menu.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto">
    
    <item
        android:id="@+id/action_clear_history"
        android:title="이력 삭제"
        android:icon="@drawable/ic_delete"
        app:showAsAction="never" />
        
</menu>
EOF

    log_success "메뉴 리소스 생성 완료"
}

create_mipmap_resources() {
    log_info "Mipmap 리소스 생성 중..."
    
    # ic_launcher.xml
    cat > app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
EOF

    # ic_launcher_round.xml
    cat > app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
EOF

    log_success "Mipmap 리소스 생성 완료"
}

create_backup_rules() {
    log_info "백업 규칙 생성 중..."
    
    # backup_rules.xml
    cat > app/src/main/res/xml/backup_rules.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
    <exclude domain="sharedpref" path="device_prefs.xml"/>
</full-backup-content>
EOF

    # data_extraction_rules.xml
    cat > app/src/main/res/xml/data_extraction_rules.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <cloud-backup>
        <include domain="file" path="." />
    </cloud-backup>
    <device-transfer>
        <include domain="file" path="." />
    </device-transfer>
</data-extraction-rules>
EOF

    log_success "백업 규칙 생성 완료"
}

print_project_info() {
    log_info "=== 다중 Webhook 관리 프로젝트 생성 정보 ==="
    echo "앱 이름: $APP_NAME"
    echo "패키지명: $APP_PACKAGE"
    echo "앱 버전: $APP_VERSION"
    echo "프로젝트 경로: $PROJECT_DIR"
    echo ""
    echo "🎯 주요 기능:"
    echo "• 다중 Webhook 관리 (추가/수정/삭제/활성화)"
    echo "• 고급 필터링 시스템 (앱, 키워드, 제목 등)"
    echo "• 발송 이력 관리 (성공/실패/대기 상태)"
    echo "• 백업 및 복구 기능"
    echo "• Material Design 3 UI"
    echo ""
    echo "📱 화면 구성:"
    echo "• 상태 탭: 서비스 상태 및 권한 확인"
    echo "• Webhook 탭: Webhook 관리"
    echo "• 이력 탭: 발송 이력 조회"
    echo "• 설정 탭: 백업/복구 및 앱 정보"
    echo ""
    echo "Android 컴파일 SDK: $ANDROID_COMPILE_SDK"
    echo "최소 SDK: $ANDROID_MIN_SDK"
    echo "타겟 SDK: $ANDROID_TARGET_SDK"
    echo "Gradle 버전: $GRADLE_VERSION"
    log_info "============================================="
}

main() {
    log_info "=== 다중 Webhook 관리 Android 프로젝트 생성 시작 ==="
    
    print_project_info
    check_prerequisites
    create_project_structure
    create_gradle_files
    create_android_manifest
    create_data_models
    create_data_manager
    create_service_classes
    create_receiver_classes
    create_utility_classes
    create_main_activity
    create_fragment_classes
    create_adapter_classes
    create_dialog_classes
    create_layout_resources
    create_item_layouts
    create_dialog_layouts
    create_values_resources
    create_drawable_resources
    create_menu_resources
    create_mipmap_resources
    create_backup_rules
    
    log_success "=== 다중 Webhook 관리 프로젝트 생성 완료 ==="
    log_info "프로젝트가 '$PROJECT_DIR' 폴더에 생성되었습니다."
    log_info ""
    log_info "📋 다음 단계:"
    log_info "1. Android Studio에서 프로젝트 열기"
    log_info "2. 프로젝트 빌드 및 APK 생성"
    log_info "3. 앱 설치 후 알림 접근 권한 허용"
    log_info "4. SMS 권한 허용"
    log_info "5. Webhook 추가 및 필터링 조건 설정"
    log_info ""
    log_info "🚀 이제 완전한 다중 Webhook 관리 앱을 사용할 수 있습니다!"
}

# 스크립트 실행
main "$@"
