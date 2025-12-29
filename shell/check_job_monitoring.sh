#!/bin/bash
# Date: 2022-8-21 18:29
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: Check whether job monitoring is added
# Version: v1.0

ENVNAME=${ENVNAME:-xxyy-prod}
SUB_DOMAINS=${SUB_DOMAINS:-xxxx}

# set color
echoRed() { echo -e $'\e[0;31m'"$1"$'\e[0m'; }
echoGreen() { echo -e $'\e[1;32m'"$1"$'\e[0m'; }
echoYellow() { echo -e $'\e[0;33m'"$1"$'\e[0m'; }
echoDarkGreen() { echo -e $'\033[36m'"$1"$'\033[0m'; }

usage() {
    echo "usage:"
    echo "${0}  [-e EnvNAME]"
    echo -e "\nOptions:"
    echo -e "-e xxyy-prod\tenv name(default \"xxyy-prod\")"
    exit 1
}

while getopts 'e:' opt; do
    case $opt in
    e)
        ENVNAME=$OPTARG
        ;;
    ?)
        usage
        exit 1
        ;;
    esac
done

prometheus_curl() {
    # 正则匹配
    # --data-urlencode 'match[]=up{job="'"${ENVNAME}"'-http",name=~"'"${JobName%%_*}"'.*"}' \
    curl -s 'http://prometheus-'"$ENVNAME"'.'"$SUB_DOMAINS"'.xxxxxxxx.cn/api/v1/series?' \
        --data-urlencode 'match[]=up{job="'"${ENVNAME}"'-http",name="'"$JobName"'"}' \
        -w '\n'
}

get_prometheus_http_code() {
    curl http://prometheus-"$ENVNAME".xxxx.xxxxxxxx.cn \
        -w '%{http_code}' \
        -o /dev/null \
        -s
}

for JobName in $(
    tools -t job -e "$ENVNAME" | grep "$ENVNAME" | sed "s/[\']/\n/g" | sed '/[,\|]/d' | sort
); do
    # echo "$JobName"
    if [[ $(get_prometheus_http_code) == "404" ]]; then
        SUB_DOMAINS="aliyun"
    fi
    # 正则匹配
    # if [[ $(prometheus_curl | grep "${JobName%%_*}" -c) -gt 0 ]]; then
    if [[ $(prometheus_curl | grep "$JobName" -c) -gt 0 ]]; then
        echoDarkGreen "$JobName ok"
    else
        echoRed "$JobName not ok"
    fi

done
