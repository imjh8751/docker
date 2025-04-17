<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    // No-cache 설정
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate"); // HTTP 1.1
    response.setHeader("Pragma", "no-cache"); // HTTP 1.0
    response.setHeader("Expires", "0"); // Proxies

    // 클라이언트 정보 얻기
    String userAgent = request.getHeader("User-Agent");
    String clientIP = request.getRemoteAddr();
    String serverName = request.getServerName();
    int serverPort = request.getServerPort();
    String protocol = request.getScheme();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Client Information</title>
    <style>
        body {
            font-family: sans-serif;
            background-color: #f4f4f4;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
        }
        .container {
            background-color: #fff;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            text-align: center;
        }
        h1 {
            color: #333;
            margin-bottom: 20px;
        }
        .info-item {
            margin-bottom: 10px;
            text-align: left;
        }
        .label {
            font-weight: bold;
            color: #555;
            display: inline-block;
            width: 120px;
        }
        .value {
            color: #777;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome!</h1>
        <p>This is the default index page.</p>
        <h2>Client Information</h2>
        <div class="info-item">
            <span class="label">User Agent:</span> <span class="value"><%= userAgent %></span>
        </div>
        <div class="info-item">
            <span class="label">Client IP:</span> <span class="value"><%= clientIP %></span>
        </div>
        <h2>Server Information</h2>
        <div class="info-item">
            <span class="label">Server Name:</span> <span class="value"><%= serverName %></span>
        </div>
        <div class="info-item">
            <span class="label">Server Port:</span> <span class="value"><%= serverPort %></span>
        </div>
        <div class="info-item">
            <span class="label">Protocol:</span> <span class="value"><%= protocol %></span>
        </div>
    </div>
</body>
</html>
