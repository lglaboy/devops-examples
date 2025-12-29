#!/bin/bash
#
# 批量检查每个服务的请求耗时，通过 & 防止for循环被阻塞，影响检查其它地址

LOG_FILE="/tmp/check_request.log"

ip_list="
10.0.0.196
10.0.0.239
10.0.0.243
10.0.0.235
10.0.1.9
"

num=1

# 提供ip,请求对应IP:8080/patient/v1/healthcheck 接口耗时
request_time() {
    local time
    time=$(date +"%Y-%m-%d %H:%M:%S.%N")
    # 指定1s为超时时间
    # total_time=$(curl -m 1 "$1:8080/patient/v1/healthcheck" -s -o /dev/null -w "%{time_total}\n")
    # 不指定超时时间
    total_time=$(curl "$1:8080/patient/v1/healthcheck" -s -o /dev/null -w "%{time_total}\n")
    echo "$time" "$num" "$1:8080/patient/v1/healthcheck" "$total_time" | tee -a $LOG_FILE
}

while true;do
    for ip in $ip_list;do
        request_time "$ip" &
    done
    ((num++))
    sleep 1
done