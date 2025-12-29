#!/bin/bash
# Date: 2022-8-22 16:15
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: check internet network port
# Version: v1.0

ip_list='
xxx.xxx.xxx.xxx
xxx.xxx.xxx.xxx
xxx.xxx.xxx.xxx
xxx.xxx.xxx.xxx
'

aliyun_ip_list='xxx.xxx.xxx.xxx'

cloud_mq_ip_list='xxx.xxx.xxx.xxx
xxx.xxx.xxx.xxx
'

port_list='80
443
'

aliyun_port_list='443
2020
6000'

cloud_mq_port_list='9876
10911'

check_network_port_connectivity(){
    local ip_list=$1
    local port_list=$2
    for line in $ip_list
    do
        for port in $port_list
        do
            nc -z -w 1 "$line" "$port" && echo 访问 IP:"$line" 端口:"$port" succeeded! || echo 访问 IP:"$line" 端口:"$port" failed!
        done
    done
}


check_network_port_connectivity "$ip_list" "$port_list"
check_network_port_connectivity "$aliyun_ip_list" "$aliyun_port_list"
check_network_port_connectivity "$cloud_mq_ip_list" "$cloud_mq_port_list"
