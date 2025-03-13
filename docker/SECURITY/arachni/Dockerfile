FROM debian:bookworm

ARG VERSION=1.6.1.3
ARG WEB_VERSION=0.6.1.1
ARG CHROME_VERSION=114.0.5735.90

# master 계정 생성 (UID 1000)
RUN adduser --disabled-password --gecos "" --uid 1000 master

RUN apt-get -qq update && \
    apt-get -qq install -y --no-install-recommends wget ca-certificates libcurl4 libnghttp2-14 unzip chromium && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# chromedriver 다운로드 및 설치
RUN wget https://chromedriver.storage.googleapis.com/${CHROME_VERSION}/chromedriver_linux64.zip && \
    unzip chromedriver_linux64.zip && \
    mv chromedriver /usr/bin/ && \
    rm chromedriver_linux64.zip && \
    chmod +x /usr/bin/chromedriver

RUN mkdir /arachni && \
    wget -qO- https://github.com/Arachni/arachni/releases/download/v${VERSION}/arachni-${VERSION}-${WEB_VERSION}-linux-x86_64.tar.gz | \
    tar xvz -C /arachni --strip-components=1 && \
    chown -R master:master /arachni

WORKDIR /arachni

EXPOSE 9292

USER master
