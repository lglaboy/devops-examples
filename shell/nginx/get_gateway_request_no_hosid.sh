#!/bin/bash
# Date: 2022-08-03 16:08
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: Filter nginx log files
# Version: v1.0

DATE=$(date +%Y%m%d_%H%M%S)
OUT_FILE=/tmp/gateway_all_${DATE}.log
# 仅gateway相关路由请求
OUT_ROUTE_FILE=/tmp/gateway_route_path_${DATE}.log
MATCH_VALUE="manage|patient|doctor|pay|message|es|clinic|consult|pharmacy|content|sync|recommend|logistics|patientmgt|customer|follow|pay2thirdparty|healthmgt|shopping|patientuser|epcplatform"

awk -F '|' '$1~/-/{print $2 "|" $7}' $(ls /var/log/nginx/gateway_access.log*|grep -v .gz$) | sed -f /opt/script/replace_logs.sed | sort -t "|" -k 2 -u  > ${OUT_FILE}
grep -E ' /('${MATCH_VALUE}')/' ${OUT_FILE} | grep -E 'healthcheck|swagger' -v > ${OUT_ROUTE_FILE}