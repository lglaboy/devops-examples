#!/bin/bash
# Date: 2023-03-23 14:39
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: Count the number of Grafana alarms
# Version: v1.0

KEY=${KEY:-955c064f-cbe5-444b-bf06-d5302470c675}
GRAFANA_DOCKER_NAME=${GRAFANA_DOCKER_NAME:-grafana}

# 从日志中统计数量
get_grafana_alerts(){
    echo "$(date "+%FT00:00:00" -d '-1days') -> $(date "+%FT23:59:59" -d '-1days') 告警次数统计"
    docker logs -t --since="$(date "+%FT00:00:00" -d '-1days')" --until "$(date "+%FT23:59:59" -d '-1days')" "${GRAFANA_DOCKER_NAME}" | grep message |grep grafana.xxxxxxxx |awk -F '%2F' '{print $5}'|grep prod |sort |uniq -c|sort -k1nr|awk '{print "> " "环境:"$2 " " "告警次数:"$1}'
}

# 发送消息
wecom_robot_send_markdown(){
    local message
    message="${1//$'\n'/\\n}"
    curl 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key='"${KEY}"'' \
    -H 'Content-Type: application/json' \
    -s \
    -d '
    {
            "msgtype": "markdown",
            "markdown": {
                "content": "'"${message}"'"
            }
    }'

}

wecom_robot_send_markdown "$(get_grafana_alerts)"