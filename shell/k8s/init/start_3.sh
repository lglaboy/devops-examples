#! /bin/bash
# 3.0 init 脚本

set -e

check_count=10
code_tag=0

declare -A dict
dict=([nacos_url]="http://nacos-server-headless:8848/nacos/v1/cs/configs?dataId=nacos.cfg.dataId&group=test&content=HelloWorld")

# set color
echoRed()    { echo $'\e[0;31m'"$1"$'\e[0m'; }
echoGreen()  { echo $'\e[0;32m'"$1"$'\e[0m'; }
echoYellow() { echo $'\e[0;33m'"$1"$'\e[0m'; }
echoBule()   { echo $'\e[0;36m'"$1"$'\e[0m'; }

health_service() {
    local url=$1
    local service_name
    local response
    local status
    service_name=$(echo "$url" | awk -F '://' '{print $2}' | awk -F '-' '{print $1}')
    if [ "$service_name" = "nacos" ]; then
        response=$(curl -s -XPOST "$url")
    fi
    status=$(echo "${response}" | awk -F ':|"' '{print $(NF-1)}' | tail -1)
    if [ "$status" = "true" ]; then
        echoGreen "$(date): $service_name service is up"
        return 0
    else
        echoRed "$(date): $service_name service is down"
        return 1
    fi
}

exit_code() {
    for url in "${dict[@]}" ;do
        local check_num=1
        local service_name
        service_name=$(echo "$url" | awk -F '://' '{print $2}' | awk -F '-' '{print $1}')
        while [ $check_num -le $check_count ]; do
            # 检查
            echoYellow "[$check_num] $(date): Checking $service_name service"
            health_service "$url"
            code=$?
            
            if [ "$code" = "0" ]; then
                break
            fi
            check_num=$((check_num+1))
            sleep 2
        done

        # 
        if [ $check_num -gt $check_count ]; then
            # 检查达到上限，未成功，定义未失败
            code_tag="1"
            # 任何一个失败，直接退出
            break
        else
            # 只要在有限次数内成功即成功
            code_tag="0"
        fi
    done

    if [ "$code_tag" = "0" ]; then
        exit 0
    elif [ "$code_tag" = "1" ]; then
        exit 1
    fi
}

exit_code
