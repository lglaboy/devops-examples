#! /bin/bash

set -e

check_count=10
code_tag=0

declare -A dict
dict=([nacos_url]="http://nacos-server-headless:8848/nacos/v1/cs/configs?dataId=nacos.cfg.dataId&group=test&content=HelloWorld" [eureka_url]="http://eureka-0:10100/actuator/health")

# set color
echoRed()    { echo $'\e[0;31m'"$1"$'\e[0m'; }
echoGreen()  { echo $'\e[0;32m'"$1"$'\e[0m'; }
echoYellow() { echo $'\e[0;33m'"$1"$'\e[0m'; }
echoBule()   { echo $'\e[0;36m'"$1"$'\e[0m'; }

health_service() {
    local url=$1
    local service_name=$(echo $url | awk -F '://' '{print $2}' | awk -F '-' '{print $1}')
    if [ "$service_name" = "nacos" ]; then
        local response=$(curl -XPOST "$url")
    elif [ "$service_name" = "eureka" ]; then
        local response=$(curl -XGET "$url")
    fi
    local status=$(echo ${response} | awk -F ':|"' '{print $(NF-1)}' | tail -1)
    if [ "$status" = "true" ] || [ "$status" = "UP" ]; then
        echoGreen "$(date): $service_name service is up"
        local code='0'
    else
        echoYellow "[$check_num] $(date): Checking $service_name service again"
        if [ $check_num -eq $check_count ]; then
            local code='1'
        fi
    fi
    exit_code=$code
    if [ "$exit_code" = "1" ]; then
        echoRed "[$check_num] $(date): $service_name service is down"
    fi
    if [ "$code_tag" = "$exit_code" ]; then
        code_tag="0"
    elif [ "$exit_code" = "1" ]; then
        code_tag="1"
    else
        :
    fi
}

exit_code() {
    for url in "${dict[@]}" ;do
        local check_num=1
        local service_name=$(echo $url | awk -F '://' '{print $2}' | awk -F '-' '{print $1}')
        while [ $check_num -le $check_count ]; do
            # 如果是 p2o 或 o2p，只检查 nacos
            if [[ $POD_NAME =~ "p2o" ]] || [[ $POD_NAME =~ "o2p" ]]; then
                health_service ${dict[nacos_url]}
            else
                # 检查 nacos 和 eureka 是否可用
                health_service $url
            fi
            sleep 2
            if [ "$exit_code" = "0" ]; then
                break
            fi
            check_num=$(($check_num+1))
        done
    done
    if [ "$code_tag" = "0" ]; then
        exit 0
    elif [ "$code_tag" = "1" ]; then
        exit 1
    else
        :
    fi
}

exit_code
