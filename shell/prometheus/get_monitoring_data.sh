#!/bin/bash
# Date: 2023-03-08 09:33
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: Get monitoring data
# Version: v1.0

# 说明:
# 无论哪天执行该脚本，均返回昨天早上6点至晚上12点的数据

# 定义变量

# ENVNAME=${ENVNAME:-xxyy-prod}
# PROMETHEUS_URL=${PROMETHEUS_URL:-http://prometheus-xxxx-prod.xxxx.xxxxxxxx.cn}
# SUB_DOMAINS=${SUB_DOMAINS:-xxxx}

# 计算昨天晚上12点的时间戳
# day="$(date +%F) 00:00:00"
# TIMESTAMP=$(date -d "${day}" +"%s")
TIMESTAMP=$(date -d "$(date +%F) 00:00:00" +"%s")

# 查询接口
INSTANCE_QUERIES_API="/api/v1/query"

# 间隔，时长
INTERVAL=18h

# 报表保存目录
DATA_DIR=${DATA_DIR:-/tmp/prometheus_monitoring_data}

# 声明一个字典，用于特殊环境名替换
declare -A env_dic
env_dic=(["env2.0-prod"]="env-prod" ["env-prod"]="environment-prod" ["abcdyy-prod"]="abcd-prod")

# 定义一个list，排除指定环境
remove_env_list=("demo-prod" "v2-prod" "ab-prod" "xx-prod" "new-prod" "xxxx-sit")


# 说明：
usage(){
    echo "usage:"
    echo "${0} env_name"
    echo -e "\nEg:"
    echo "获取xxxx-prod环境的监控报表"
    echo "${0} xxxx-prod"
    exit 1
}


# 检查jq是否安装
check_jq(){
    if which jq > /dev/null;then
        echo "OK"
    else
        echo "jq 命令不存在"
        exit 1
    fi
}


# CPU
# 最高CPU

get_cpu_max() {
    local request_uri env_name
    request_uri=${1}${INSTANCE_QUERIES_API}
    env_name=${2}
    curl --data-urlencode 'query=round(1 - min_over_time((sum(increase(node_cpu_seconds_total{mode="idle",job=~"'"${env_name}"'"} [5m])) by (instance,job) / sum(increase(node_cpu_seconds_total{job=~"'"${env_name}"'"}[5m])) by (instance,job)) ['"${INTERVAL}"':5m]),0.01)' \
        --data-urlencode "time=${TIMESTAMP}" \
        -s \
        ''"${request_uri}"'' |
        jq '.data.result[] | "最高CPU百分比 instance:\(.metric.instance) value:\(.value[-1])" ' \
        | sed 's/\"//g' \
        | sort -k 3 -V -r
}

# 平均CPU

get_cpu_avg() {
    local request_uri env_name
    request_uri=${1}${INSTANCE_QUERIES_API}
    env_name=${2}
    curl --data-urlencode 'query=round(1 - avg_over_time((sum(increase(node_cpu_seconds_total{mode="idle",job=~"'"${env_name}"'"} [5m])) by (instance,job) / sum(increase(node_cpu_seconds_total{job=~"'"${env_name}"'"}[5m])) by (instance,job)) ['"${INTERVAL}"':5m]),0.01)' \
        --data-urlencode "time=${TIMESTAMP}" \
        -s \
        ''"${request_uri}"'' |
        jq '.data.result[] | "平均CPU百分比 instance:\(.metric.instance) value:\(.value[-1])" ' \
        | sed 's/\"//g' \
        | sort -k 3 -V -r
}

# 负载
# 使用五分钟平均负载

# 最高

get_load5_max() {
    local request_uri env_name
    request_uri=${1}${INSTANCE_QUERIES_API}
    env_name=${2}
    curl --data-urlencode 'query=max_over_time(node_load5{job=~"'"${env_name}"'"} ['"${INTERVAL}"'])' \
        --data-urlencode "time=${TIMESTAMP}" \
        -s \
        ''"${request_uri}"'' |
        jq '.data.result[] | "load5最高 instance:\(.metric.instance) value:\(.value[-1])" ' \
        | sed 's/\"//g' \
        | sort -k 3 -V -r
}

# 平均
get_load5_avg() {
    local request_uri env_name
    request_uri=${1}${INSTANCE_QUERIES_API}
    env_name=${2}
    curl --data-urlencode 'query=round(avg_over_time(node_load5{job=~"'"${env_name}"'"} ['"${INTERVAL}"']),0.01)' \
        --data-urlencode "time=${TIMESTAMP}" \
        -s \
        ''"${request_uri}"'' |
        jq '.data.result[] | "load5平均 instance:\(.metric.instance) value:\(.value[-1])" ' \
        | sed 's/\"//g' \
        | sort -k 3 -V -r
}

# IO

# 最高
get_io_max() {
    local request_uri env_name
    request_uri=${1}${INSTANCE_QUERIES_API}
    env_name=${2}
    curl --data-urlencode 'query=round(max_over_time(rate(node_disk_io_time_seconds_total{ job=~"'"${env_name}"'" , device=~"vd.*|sd.*"}[2m]) ['"${INTERVAL}"':1m]),0.01) > 0' \
        --data-urlencode "time=${TIMESTAMP}" \
        -s \
        ''"${request_uri}"'' |
        jq '.data.result[] | "IO最高 instance:\(.metric.instance)|device:\(.metric.device) value:\(.value[-1])" ' \
        | sed 's/\"//g' \
        | sort -k2,2 -k4,4Vr
}
# 平均

get_io_avg() {
    local request_uri env_name
    request_uri=${1}${INSTANCE_QUERIES_API}
    env_name=${2}
    curl --data-urlencode 'query=round(avg_over_time(rate(node_disk_io_time_seconds_total{ job=~"'"${env_name}"'" , device=~"vd.*|sd.*"}[2m]) ['"${INTERVAL}"':1m]),0.01) > 0' \
        --data-urlencode "time=${TIMESTAMP}" \
        -s \
        ''"${request_uri}"'' |
        jq '.data.result[] | "IO平均 instance:\(.metric.instance)|device:\(.metric.device) value:\(.value[-1])" ' \
        | sed 's/\"//g' \
        | sort -k2,2 -k4,4Vr
}

# 内存
# 使用内存

get_mem_max() {
    local request_uri env_name
    request_uri=${1}${INSTANCE_QUERIES_API}
    env_name=${2}
    curl --data-urlencode 'query=round(((1 - min_over_time((node_memory_MemAvailable_bytes/node_memory_MemTotal_bytes{job=~"'"${env_name}"'"}) ['"${INTERVAL}"':1m])) * 100),0.01)' \
        --data-urlencode "time=${TIMESTAMP}" \
        -s \
        ''"${request_uri}"'' |
        jq '.data.result[] | "使用内存百分比最高 instance:\(.metric.instance) value:\(.value[-1])" ' \
        | sed 's/\"//g' \
        | sort -k 3 -V -r
}

get_mem_avg() {
    local request_uri env_name
    request_uri=${1}${INSTANCE_QUERIES_API}
    env_name=${2}
    curl --data-urlencode 'query=round(((1 - avg_over_time((node_memory_MemAvailable_bytes/node_memory_MemTotal_bytes{job=~"'"${env_name}"'"}) ['"${INTERVAL}"':1m])) * 100),0.01)' \
        --data-urlencode "time=${TIMESTAMP}" \
        -s \
        ''"${request_uri}"'' |
        jq '.data.result[] | "使用内存百分比平均 instance:\(.metric.instance) value:\(.value[-1])" ' \
        | sed 's/\"//g' \
        | sort -k 3 -V -r
}

# 针对服务
# 获取服务状态异常时间

get_server_http_code_error_time() {
    local request_uri env_name
    request_uri=${1}${INSTANCE_QUERIES_API}
    env_name=${2}
    curl --data-urlencode 'query=round((count_over_time((probe_http_status_code{job="'"${env_name}"'-http"} > 210 or probe_http_status_code{job="'"${env_name}"'-http"} < 200) ['"${INTERVAL}"':])/count_over_time(probe_http_status_code{job="'"${env_name}"'-http"} ['"${INTERVAL}"':]) * 60 * 60 * 18),0.01)' \
        --data-urlencode "time=${TIMESTAMP}" \
        -s \
        ''"${request_uri}"'' |
        jq '.data.result[] | "服务状态异常时间(s) name:\(.metric.name)|instance:\(.metric.instance) value:\(.value[-1])" ' \
        | sed 's/\"//g' \
        | sort -k 4 -V -r
}

# tcp 异常时间
get_tcp_code_error_time() {
    local request_uri env_name
    request_uri=${1}${INSTANCE_QUERIES_API}
    env_name=${2}
    curl --data-urlencode 'query=round((count_over_time((probe_success{job="'"${env_name}"'-tcp"} == 0) ['"${INTERVAL}"':])/(count_over_time((probe_success{job="'"${env_name}"'-tcp"} > 0) ['"${INTERVAL}"':]) + count_over_time((probe_success{job="'"${env_name}"'-tcp"} == 0) ['"${INTERVAL}"':])) * 60 * 60 * 18),0.01)' \
        --data-urlencode "time=${TIMESTAMP}" \
        -s \
        ''"${request_uri}"'' |
        jq '.data.result[] | "TCP状态异常时间(s) name:\(.metric.name)|instance:\(.metric.instance) value:\(.value[-1])" ' \
        | sed 's/\"//g' \
        | sort -k 4 -V -r
}

# 针对nginx统计出

# 根据upstream计算的
get_nginx_request_time_p95() {
    local request_uri env_name
    request_uri=${1}${INSTANCE_QUERIES_API}
    env_name=${2}
    curl --data-urlencode 'query=round(quantile_over_time(0.95, sum(nginx_vts_upstream_request_seconds{job="'"${env_name}"'-nginx"}) by (upstream,instance,job) ['"${INTERVAL}"':]),0.01) > 0' \
        --data-urlencode "time=${TIMESTAMP}" \
        -s \
        ''"${request_uri}"'' |
        jq '.data.result[] | "请求时间P95(s) upstream:\(.metric.upstream) value:\(.value[-1])" ' \
        | sed 's/\"//g' \
        | sort -k 3 -V -r
}

# 峰值95%
get_nginx_request_time_max_p95() {
    local request_uri env_name
    request_uri=${1}${INSTANCE_QUERIES_API}
    env_name=${2}
    curl --data-urlencode 'query=round(quantile_over_time(0.95, sum(max_over_time(nginx_vts_upstream_request_seconds{job="'"${env_name}"'-nginx"} [1m])) by (upstream,instance,job) ['"${INTERVAL}"':]),0.01) > 0' \
        --data-urlencode "time=${TIMESTAMP}" \
        -s \
        ''"${request_uri}"'' |
        jq '.data.result[] | "请求时间峰值P95(s) upstream:\(.metric.upstream) value:\(.value[-1])" '  \
        | sed 's/\"//g' \
        | sort -k 3 -V -r
}

# 500 以上个数

get_nginx_http_code_5xx() {
    local request_uri env_name
    request_uri=${1}${INSTANCE_QUERIES_API}
    env_name=${2}
    curl --data-urlencode 'query=increase(sum(nginx_vts_upstream_requests_total{code="5xx",job=~"'"${env_name}"'-nginx"}) by (upstream,code,job) ['"${INTERVAL}"':]) > 0' \
        --data-urlencode "time=${TIMESTAMP}" \
        -s \
        ''"${request_uri}"'' |
        jq '.data.result[] | "http状态码5xx upstream:\(.metric.upstream) value:\(.value[-1])" '  \
        | sed 's/\"//g' \
        | sort -k 3 -V -r
}

# 统一返回数据处理

output_format(){
    local env_name
    env_name=$1
    if [ ! -d "${DATA_DIR}" ];then
        mkdir "${DATA_DIR}"
    fi
    get_monitoring_report "$env_name" | sed 's/ /,/g' |tee "${DATA_DIR}/${env_name}_$(date +%F_%T).csv"
}

# 获取所有数据
get_monitoring_report() {
    local env_name prometheus_url
    env_name=${1}
    prometheus_url="http://prometheus-${env_name}.xxxx.xxxxxxxx.cn"

    get_cpu_max "${prometheus_url}" "${env_name}"

    get_cpu_avg "${prometheus_url}" "${env_name}"

    get_load5_max "${prometheus_url}" "${env_name}"

    get_load5_avg "${prometheus_url}" "${env_name}"

    get_io_max "${prometheus_url}" "${env_name}"

    get_io_avg "${prometheus_url}" "${env_name}"

    get_mem_max "${prometheus_url}" "${env_name}"

    get_mem_avg "${prometheus_url}" "${env_name}"

    get_server_http_code_error_time "${prometheus_url}" "${env_name}"

    get_tcp_code_error_time "${prometheus_url}" "${env_name}"

    get_nginx_request_time_p95 "${prometheus_url}" "${env_name}"

    get_nginx_request_time_max_p95 "${prometheus_url}" "${env_name}"

    get_nginx_http_code_5xx "${prometheus_url}" "${env_name}"
}

# 替换name
replace_env_name() {
    local envname=$1
    if [[ -n ${env_dic["${envname}"]} ]]; then
        envname=${env_dic["${envname}"]}
    fi
    echo "$envname"
}

# 删除废弃项目
match_remove_env() {
    local env_name=$1
    for remove_env in "${remove_env_list[@]}"; do
        if [[ $remove_env == "$env_name" ]]; then
            return 1
        fi
    done

}
# 获取符合规范的所有环境监控数据

get_all_env_monitoring_report() {

    for envname in $(tools -t env | awk -F '|' '{print $2}' | tail -n +4 | grep -v "^$" | grep prod|sort); do
        envname=$(replace_env_name "$envname")

        if ! match_remove_env "$envname"; then
            continue
        fi
        echo "获取 $envname 监控数据" 
        output_format "$envname" 
    done
}



if [ $# == 1 ]; then
    output_format "$1"
    # get_monitoring_report "$1" | sed 's/ /,/g'
else
    get_all_env_monitoring_report
    # usage
fi
