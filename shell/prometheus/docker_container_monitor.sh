#!/bin/bash

# 定义字典，处理特殊情况
declare -A dic
dic=([wx]="weserver" [sync-2cloud]="sync2cloud" [sync_o2p]="sync" [sync_p2o]="sync" [book-baidu]="bookbaidu" [insure-pay]="insure" [pay-adapter]="pay" [auth_1.0]="auth" [regulatory-platform]="regulatory" [supervision-platform]='ehealth')

# 获取值
# DockerCheck=${dic["${JobName%_*}"]}

# 输出文件

get_service_monitor_config() {
    docker inspect --format '{{.Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -q) | sed 's/\///g' | grep prod | grep -v -E "front|web|auth_1.0_prod" | while read line; do
        name=$(echo $line | awk '{print $1}')
        ip=$(echo $line | awk '{print $2}')
        if [[ $name =~ "gateway" ]]; then
            url="http://$ip:8080/v1/healthcheck"
        elif [[ ${dic["${name%_*}"]} ]]; then
            url="http://$ip:8080/${dic["${name%_*}"]}/v1/healthcheck"
        else
            url="http://$ip:8080/$(echo $name | awk -F '_' '{print $1}')/v1/healthcheck"
        fi
        
        echo "- targets:"
        echo "  - $url"
        echo "  labels:"
        echo "    name: $name"
        echo "    hostname: $(hostname)"
    done
}


# 获取执行输出
get_service_monitor_config

# 将函数输出结果写入指定文件
# get_service_monitor_config > /tmp/get_service_monitor_config.conf