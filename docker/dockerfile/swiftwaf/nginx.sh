#!/bin/bash

# 更新configmap
update_configmap() {
    local external_update internal_update
    external_update="$HOME/k3s-yamls/nginx/external/update.sh"
    internal_update="$HOME/k3s-yamls/nginx/internal/update.sh"
    # 判断脚本是否存在
    if [[ -f $external_update ]]; then
        cd "$(dirname "$external_update")" || echo "$(dirname "$external_update") 目录不存在"
        echo "更新 external(外网) nginx配置"
        sudo bash update.sh
    else
        echo "$external_update 文件不存在"
    fi

    if [[ -f $internal_update ]]; then
        cd "$(dirname "$internal_update")" || echo "$(dirname "$internal_update") 目录不存在"
        echo "更新 internal(内网) nginx配置"
        sudo bash update.sh
    else
        echo "$internal_update 文件不存在"
    fi
    # 更新configmap pod内部配置同步存在延迟，添加等待配置同步
    sleep 3
}

# k8s environment
run_k8s_swiftwaf() {
    local name="swiftwaf"

    # 执行命令前判断是否更新配置文件
    if [[ $1 == "-t" ]]; then
        update_configmap
    elif [[ "$1 $2" == "-s reload" ]]; then
        run_k8s_swiftwaf "-t"
    fi

    for pod in $(kubectl get pods | grep "$name" | cut -d" " -f 1); do
        echo "$pod"
        kubectl exec "$pod" -- nginx "$@" || {
            exit 1
        }
    done
    return 0
}

# docker environment
run_docker_swiftwaf() {
    local name="swiftwaf"

    docker exec "$name" nginx "$@" || {
        exit 1
    }
}

# 控制器
run_swiftwaf() {
    local name="swiftwaf"

    if [[ $(docker ps | awk '{print $NF}' | grep "^$name$" -c) -eq 1 ]]; then
        echo "Docker environment execution"
        run_docker_swiftwaf "$@"
    elif [[ $(kubectl get pods | awk '{print $1}' | grep swiftwaf -c) -gt 0 ]]; then
        echo "k8s environment execution"
        run_k8s_swiftwaf "$@"
    fi
}

main() {

    case "$#" in
    1)
        case "$1" in
        -t)
            # 处理 -t 或 -V 的情况
            run_swiftwaf "$@"
            ;;
        -V)
            # 处理 -t 或 -V 的情况
            run_swiftwaf "$@"
            ;;
        *)
            # 处理其他 1 个参数的情况
            ;;
        esac
        ;;
    2)
        case "$1 $2" in
        "-s reload")
            # 处理 -s reload 的情况
            run_swiftwaf "$@"
            ;;
        *)
            # 处理其他 2 个参数的情况
            ;;
        esac
        ;;
    *)
        # 处理其他不同数量参数的情况
        # 说明
        echo "Control swiftwaf pod in k3s

    Options:
    -V            : show version and configure options then exit
    -t            : test configuration and exit
    -s signal     : send signal to a master process: reload
    "
        ;;
    esac
}

main "$@"
