FROM debian:bookworm

ARG VERSION=1.6.1.3
ARG WEB_VERSION=0.6.1.1

# master 계정 생성 (UID 1000)
RUN adduser --disabled-password --gecos "" --uid 1000 master

RUN apt-get -qq update && \
    apt-get -qq install -y --no-install-recommends wget ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /arachni && \
    wget -qO- https://github.com/Arachni/arachni/releases/download/v${VERSION}/arachni-${VERSION}-${WEB_VERSION}-linux-x86_64.tar.gz | \
    tar xvz -C /arachni --strip-components=1 && \
    chown -R master:master /arachni # /arachni 디렉토리의 소유자를 master로 변경

WORKDIR /arachni
EXPOSE 9292

USER master # 이후 명령어는 master 계정으로 실행
