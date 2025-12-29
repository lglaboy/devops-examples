#!/bin/bash

# 通过命令同时控制容器内nginx及宿主机nginx
# 如果需要执行nginx -s reload，从而reload 容器内部nginx，则需要替换原nginx可执行文件
# sudo mv /usr/sbin/nginx /usr/sbin/nginx-source
# 创建 /usr/sbin/nginx 文件，将当前文件内容复制进去
# sudo vim /usr/sbin/nginx
# 授予可执行权限
# sudo chmod +x /usr/sbin/nginx

filename=$(basename "$0")

run_k8s_swiftwaf() {
    local full_name name
    # 限制条件
    if [[ $# -eq 1 && $1 == "-t" ]] || [[ $# -eq 2 && $1 == "-s" ]]; then
        full_name=$(docker ps | grep swiftwaf | awk '{print $NF}' | cut -d"_" -f 3 | sort -u)

        name=${full_name%-*}

        if [[ -n "$name" ]]; then
            for pod in $(kubectl get pods | grep "$name" | cut -d" " -f 1); do
                echo "$pod"
                kubectl exec "$pod" -- nginx "$@"
            done
        fi
    fi
}

run_local_nginx() {
    # 根据当前文件名判断，如果当前文件为nginx，则需要判断源文件是否存在
    # 如果当前文件名不是nginx，则判断nginx是否存在，存在则执行
    case $filename in
    nginx)
        if [[ -n $(type -t nginx-source) ]]; then
            echo "local nginx-source"
            nginx-source "$@"
        fi
        ;;
    *)
        if [[ -n $(type -t nginx) ]]; then
            echo "local nginx"
            nginx "$@"
        fi
        ;;
    esac
}

run_k8s_swiftwaf "$@"
run_local_nginx "$@"
