#!/bin/bash

shutdown_env_list='shutdown-env1-test
shutdown-env2-test
shutdown-env3-test'

start_env_list='start-env1-test
start-env2-test
start-env3-test'

function update_shutdown_env(){
    local env_name
    for i in ${shutdown_env_list};do
        env_name=$i
        echo ${env_name}
        kubectl -n ${env_name} apply -f configmaps.yaml
        kubectl -n ${env_name} scale statefulset nacos-mysql --replicas=1
        sleep 10s
        kubectl -n ${env_name} scale deployment nacos-server --replicas=1
        sleep 60s
        tools -t nacos -f update -K redis.password -V redispassword -e ${env_name}
        sleep 60s
        kubectl -n ${env_name} scale statefulset nacos-mysql --replicas=0
        kubectl -n ${env_name} scale deployment nacos-server --replicas=0
    done
}

function update_start_env(){
    local env_name
    for i in ${start_env_list};do
        env_name=$i
        echo ${env_name}
        # 修改redis配置
        kubectl -n ${env_name} apply -f configmaps.yaml

        # 重启redis服务
        kubectl -n ${env_name} rollout restart statefulset redis

        sleep 10s

        # 修改nacos配置
        tools -t nacos -f update -K redis.password -V redispassword -e ${env_name}

        sleep 10s

        # 重启所有服务
        kubectl -n ${env_name} get deployments.apps |grep test|awk '{print $1}'| xargs -I {} -t kubectl -n ${env_name} rollout restart deployment {}

        sleep 60s
    done
}
# update_shutdown_env


update_start_env