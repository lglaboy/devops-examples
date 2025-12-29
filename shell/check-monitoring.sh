#!/bin/bash
# Date: 2022-8-21 18:29
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: Check whether job/middleware monitoring is added
# Version: v1.1

ENVNAME=${ENVNAME:-xxyy-prod}
SUB_DOMAINS=${SUB_DOMAINS:-xxxx}
TYPE=${TYPE:-job}

middleware_list='etcd-001
etcd-002
etcd-003
redis
pg-master
pg-slave
pg-cold
rocketmq-nameserver-001
rocketmq-nameserver-002
rocketmq-broken-001
rocketmq-broken-002
xxljob
es
mongo
'

# 声明一个字典，用于特殊环境名替换
declare -A env_dic
env_dic=(["env2.0-prod"]="env-prod" ["env-prod"]="environment-prod" ["abcdyy-prod"]="abcd-prod")

# 定义一个list，排除指定环境
remove_env_list=("demo-prod" "v2-prod" "ab-prod" "xx-prod" "new-prod" "xxxx-sit")

# set color
echoRed() { echo -e $'\e[0;31m'"$1"$'\e[0m'; }
echoGreen() { echo -e $'\e[1;32m'"$1"$'\e[0m'; }
echoYellow() { echo -e $'\e[0;33m'"$1"$'\e[0m'; }
echoDarkGreen() { echo -e $'\033[36m'"$1"$'\033[0m'; }

usage() {
    echo "usage:"
    echo "${0}  [-e EnvNAME]"
    echo -e "\nOptions:"
    echo -e "-t Type           Type: job/middleware/ssl/prometheus (default \"job\")"
    echo -e "-e xxyy-prod  env name(default \"xxyy-prod\")"
    echo -e "-a                Check all items according to the -t parameter"
    exit 1
}

while getopts 't:e:a' opt; do
    case $opt in
    t)
        TYPE=$OPTARG
        ;;
    e)
        ENVNAME=$OPTARG
        ;;
    a)
        TAG="all"
        ;;
    ?)
        usage
        exit 1
        ;;
    esac
done

check_job_prometheus_curl() {
    local envname=$1
    local label_name=$2
    local job

    envname=$(replace_env_name "$envname")
    job="$envname"-http

    # 正则匹配
    # --data-urlencode 'match[]=up{job="'"${ENVNAME}"'-http",name=~"'"${JobName%%_*}"'.*"}' \
    curl -s 'http://prometheus-'"$envname"'.'"$SUB_DOMAINS"'.xxxxxxxx.cn/api/v1/series?' \
        --data-urlencode 'match[]=up{job="'"${job}"'",name=~"'"$label_name"'.*"}' \
        -w '\n'
    # This comment is moved out:
    # --data-urlencode 'match[]=up{job="'"${job}"'",name="'"$label_name"'"}' \
}

check_middleware_prometheus_curl() {
    local envname=$1
    local label_name=$2
    local job
    envname=$(replace_env_name "$envname")
    job="$envname"-tcp
    # 正则匹配
    # --data-urlencode 'match[]=up{job="'"${ENVNAME}"'-http",name=~"'"${JobName%%_*}"'.*"}' \
    curl -s 'http://prometheus-'"$envname"'.'"$SUB_DOMAINS"'.xxxxxxxx.cn/api/v1/series?' \
        --data-urlencode 'match[]=up{job="'"${job}"'",name=~".*'"$label_name"'.*"}' \
        -w '\n'
}

get_ssl_prometheus_curl(){
    local envname=$1
    local job
    envname=$(replace_env_name "$envname")
    job="$envname"-https

    if check_prometheus_url "$envname"; then
        curl -s 'http://prometheus-'"$envname"'.'"$SUB_DOMAINS"'.xxxxxxxx.cn/api/v1/series?' \
            --data-urlencode 'match[]=up{job="'"${job}"'"}' \
            -w '\n' |
            jq '.data[] | {name:.name,instance:.instance}'
    fi
}


get_prometheus_http_code() {
    local envname=$1
    local sub_domains=$2
    curl http://prometheus-"$envname"."$sub_domains".xxxxxxxx.cn/graph \
        -w '%{http_code}' \
        -o /dev/null \
        -s
}

get_all_env() {
    for env in $(tools -t env | awk -F '|' '{print $2}' | tail -n +4 | grep -v "^$" | grep prod | sort); do
        if ! match_remove_env "$env"; then
            continue
        fi
        echo "$env"
    done
}

match_remove_env() {
    local env_name=$1
    for remove_env in "${remove_env_list[@]}"; do
        if [[ $remove_env == "$env_name" ]]; then
            return 1
        fi
    done

}

replace_env_name() {
    local envname=$1
    if [[ -n ${env_dic["${envname}"]} ]]; then
        envname=${env_dic["${envname}"]}
    fi
    echo "$envname"
}

check_prometheus_url() {
    local envname=$1
    local sub_domains=$SUB_DOMAINS
    envname=$(replace_env_name "$envname")

    if [[ $(get_prometheus_http_code "$envname" "$SUB_DOMAINS") != "200" ]]; then
        if [[ $SUB_DOMAINS == "xxxx" ]]; then
            SUB_DOMAINS=aliyun
        elif [[ $SUB_DOMAINS == "aliyun" ]]; then
            SUB_DOMAINS=xxxx
        fi
        if [[ $(get_prometheus_http_code "$envname" $SUB_DOMAINS) != "200" ]]; then
            echoRed "无法访问普罗米修斯地址"
            echoRed "http://prometheus-$envname.${sub_domains}.xxxxxxxx.cn"
            echoRed "http://prometheus-$envname.$SUB_DOMAINS.xxxxxxxx.cn"
            # exit 1
            return 1
        fi
    fi
}

check_job_monitor() {
    local env_names=$1
    for envname in $env_names; do
        echo "check $envname $TYPE"
        if check_prometheus_url "$envname"; then
            for JobName in $(
                tools -t job -e "$envname" | grep "$envname" | sed "s/[\']/\n/g" | sed '/[,\|]/d' | sort
            ); do
                JobName=${JobName//_prod/}
                JobName=${JobName//_front/}

                # 正则匹配
                # if [[ $(prometheus_curl | grep "${JobName%%_*}" -c) -gt 0 ]]; then
                if [[ $(check_job_prometheus_curl "$envname" "$JobName" | grep "$JobName" -c) -gt 0 ]]; then
                    echoDarkGreen "$JobName ok"
                else
                    echoRed "$JobName not ok"
                fi

            done
        fi
    done

}

check_middleware_monitor() {
    local env_names=$1
    for envname in $env_names; do
        echo "check $envname $TYPE"
        if check_prometheus_url "$envname"; then
            for middleware in $middleware_list; do
                if [[ $(check_middleware_prometheus_curl "$envname" "$middleware" | jq . | grep name | grep "$middleware" -c) -gt 0 ]]; then
                    echoDarkGreen "$middleware ok"
                else
                    echoRed "$middleware not ok"
                fi

            done
        fi
    done
}

get_ssl_monitor() {
    local job
    local env_names=$1
    for envname in $env_names; do
        echo "get $envname $TYPE"
        get_ssl_prometheus_curl "$envname"
    done
}

check_all_prometheus_url() {

    for envname in $(tools -t env | awk -F '|' '{print $2}' | tail -n +4 | grep -v "^$" | grep prod); do
        envname=$(replace_env_name "$envname")

        if ! match_remove_env "$envname"; then
            continue
        fi
        echo "get $envname $TYPE"
        if ! check_prometheus_url "$envname"; then
            continue
        fi
        echoGreen "http://prometheus-$envname.$SUB_DOMAINS.xxxxxxxx.cn"
    done
}

if [[ $TAG == "all" ]]; then
    ENVNAME=$(get_all_env)
fi

if [[ $TYPE == "job" ]]; then
    check_job_monitor "$ENVNAME"
elif [[ $TYPE == "middleware" ]]; then
    check_middleware_monitor "$ENVNAME"
elif [[ $TYPE == "ssl" ]]; then
    get_ssl_monitor "$ENVNAME"
elif [[ $TYPE == "prometheus" ]]; then
    check_all_prometheus_url
fi
