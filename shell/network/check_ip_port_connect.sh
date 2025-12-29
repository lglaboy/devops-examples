#!/bin/bash
# 检查网络端口连通性

ip_list='
xxx.xxx.xxx.xxx
xxx.xxx.xxx.xxx
xxx.xxx.xxx.xxx
xxx.xxx.xxx.xxx
'

port_list='
80
443
2020
6000
9876
10911'


for ip in $(echo $ip_list);do
    for port in $port_list;do
        nc -z -w 1 "$ip" "$port" && echo 访问 IP:"$ip" 端口:"$port" succeeded! || echo 访问 IP:"$ip" 端口:"$port" failed!
    done
done