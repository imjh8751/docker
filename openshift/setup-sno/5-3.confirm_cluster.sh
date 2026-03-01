#!/bin/bash

# 이 명령어는 "클러스터 전체의 최종 설치가 100% 끝났는지" 확인합니다.
openshift-install --dir=/root/installation_directory_sno wait-for install-complete
