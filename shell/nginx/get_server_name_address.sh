#!/bin/bash
# Date: 2023-04-06 09:37
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: get nginx server_name address
# Version: v1.0


for f in /etc/nginx/conf.d/*.conf
do
    [[ -e "$f" ]] || break
    for server_name in $(grep -E "server_name" $f|grep -v -E "^\s+#|^#"|awk -F ';' '{print $1}'|awk  '{for (i=2;i<=NF;i++)print($i" ")}')
    do
        [[ $server_name == "_" ]] && break
        for port in $(grep -E listen $f|grep -v -E "^\s+#|^#"|grep -v ssl|awk -F ';' '{print $1}'|awk '{print $2}')
        do
            echo "http://$server_name:$port"
        done

        for port in $(grep -E listen $f|grep -v -E "^\s+#|^#"|grep ssl|awk -F ';' '{print $1}'|awk '{print $2}')
        do
            echo "https://$server_name:$port"
        done
    done
done