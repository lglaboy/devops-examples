#!/bin/bash

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
