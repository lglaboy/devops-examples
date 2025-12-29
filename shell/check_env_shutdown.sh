#!/bin/bash
# Date: 2022-12-07 14:39
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: Check whether the environment can be shut down
# Version: v1.0

# 建表shutdown_env_list,存放关停环境信息
# CREATE TABLE public.shutdown_env_list (
#     env_name character varying(255) unique,
#     status boolean,
#     shutdown_date timestamp(0) without time zone NOT NULL,
# 		id SERIAL PRIMARY KEY
# );
# 
# 建表shutdown_white_list,存放白名单环境
# CREATE TABLE public.shutdown_white_list (
#     env_name character varying(255) unique,
#     create_date timestamp(0) without time zone NOT NULL,
# 		id SERIAL PRIMARY KEY
# );


# 定义变量
# WHITE_LIST="/tmp/test.txt"
# 白名单有效期时间,(day)
WHITE_LIST_PERIOD="30"

BACKUP_DIRECTORY="/opt/project/shutdown_backup"
MIDDLEWARE_DATA="/opt/project/project-middleware"
PG_IP=192.168.20.60
PG_PORT=15432
PG_DATABASE="test"
PG_USER=postgres
PG_PASSWD=postgres

usage() {
    echo "Usage:"
    echo "${0}  [-t shutdown|startup|addwhitelist|deletewhitelist|getwhitelist|recovery] [-e envname]"
    echo -e "\nOptions:"
    echo -e "-t        指定操作类型"
    echo -e "-e        指定环境名"
    echo -e "-m        指定中间件"
    echo -e "\nEg:"
    echo "指定环境<xxxx-test>关停,不跟据最近一次升级时间在七天前进行判断"
    echo "${0} -t shutdown -e xxxx-test"
    echo "指定环境<xxxx-test>启动"
    echo "${0} -t startup -e xxxx-test"
    exit 1
}

usage_recovery(){
    echo "Usage:"
    echo "${0} -t recovery [-e envname] [-m middleware_name]"
    echo -e "\nOptions:"
    echo -e "-e        指定环境名"
    echo -e "-m        指定将要恢复的中间件名称"
    echo -e "\nEg:"
    echo "指定环境<xxxx-test>,恢复中间件nacos数据"
    echo "${0} -t recovery -e xxxx-test -m nacos"
    exit 1
}

usage_whitelist(){
    echo "Usage:"
    echo "${0} [-t addwhitelist|deletewhitelist|getwhitelist] [-e envname]"
    echo -e "\nOptions:"
    echo -e "-t        指定操作类型"
    echo -e "-e        指定环境名"
    echo -e "\nEg:"
    echo "查看所有白名单"
    echo "${0} -t getwhitelist"
    echo "添加白名单"
    echo "${0} -t addwhitelist -e xxxx-test"
    echo "删除白名单"
    echo "${0} -t deletewhitelist -e xxxx-test"
    exit 1
}

while getopts 't:e:m:' opt; do
    case $opt in
    t)
        TYPE=$OPTARG
        ;;
    e)
        ENV_NAME=$OPTARG
        ;;
    m)
        MIDDLEWARE=$OPTARG
        ;;
    ?)
        usage
        exit 1
        ;;
    esac
done

# 设置echo 带时间
function logging() {
    local data
    data=$1
    echo "$(date "+%Y-%m-%d %H:%M:%S") : ${data}"
}

function logging_red() {
    echo $'\e[0;31m'"$(date "+%Y-%m-%d %H:%M:%S") : ${1}"$'\e[0m';
}

function logging_green() {
    echo $'\e[1;32m'"$(date "+%Y-%m-%d %H:%M:%S") : ${1}"$'\e[0m';
}

function logging_yellow() {
    echo $'\e[0;33m'"$(date "+%Y-%m-%d %H:%M:%S") : ${1}"$'\e[0m';
}

# pg实例

function pg_control(){
    # param=$*
    PGPASSWORD=${PG_PASSWD} psql -h ${PG_IP} -p ${PG_PORT} -U ${PG_USER} ${PG_DATABASE} "$@"
}

# 查询记录
function get_shutdown_env() {
    local env_name
    env_name=$1

    pg_control -t -c "SELECT env_name,status::bool::int,shutdown_date FROM shutdown_env_list WHERE env_name='${env_name}';" | grep "${env_name}" -c

    # PGPASSWORD=postgres psql -h 192.168.20.60 -p 15432 -U postgres test -c "SELECT * FROM shutdown_env_list;" -t
}

# 插入数据
function set_shutdown_env() {
    local env_name

    env_name=$1

    # 如果没有，则新增，如果有，则修改记录
    if [[ $(get_shutdown_env "${env_name}") -eq 0 ]];then
        pg_control -c "INSERT INTO shutdown_env_list VALUES('${env_name}','1','$(date -d @"${Time#*_}" +"%Y-%m-%d %H:%M:%S")');" >/dev/null
    else
        pg_control -c "UPDATE shutdown_env_list SET status='1',shutdown_date='$(date -d @"${Time#*_}" +"%Y-%m-%d %H:%M:%S")' WHERE env_name ='${env_name}';" >/dev/null
    fi
    
}

# 查询数据
function get_shutdown_env_status() {
    local env_name
    env_name=$1

    pg_control -t -c "SELECT env_name,status::bool::int,shutdown_date FROM shutdown_env_list WHERE env_name='${env_name}';" | grep "${env_name}" | awk -F '|' '{print $2}'

    # PGPASSWORD=postgres psql -h 192.168.20.60 -p 15432 -U postgres test -c "SELECT * FROM shutdown_env_list;" -t
}

# 查询关闭时间
function get_shutdown_env_shutdown_date() {
    local env_name
    env_name=$1

    pg_control -t -c "SELECT env_name,status::bool::int,shutdown_date FROM shutdown_env_list WHERE env_name='${env_name}';" | grep "${env_name}" | awk -F '|' '{print $3}'

    # PGPASSWORD=postgres psql -h 192.168.20.60 -p 15432 -U postgres test -c "SELECT * FROM shutdown_env_list;" -t
}

# 环境恢复，删除记录
function delete_shutdown_env() {
    local env_name
    env_name=$1
    pg_control -c "DELETE FROM shutdown_env_list WHERE env_name='${env_name}';" >/dev/null
}

# 环境恢复，更新记录
function update_shutdown_env() {
    local env_name
    env_name=$1
    pg_control -c "UPDATE shutdown_env_list SET status='0' WHERE env_name ='${env_name}';" >/dev/null
}

# 查询当前环境每个服务的最新部署时间
function get_env_job_deploy_time_latest() {
    pg_control -t -c "SELECT name,env,version,job_type,deploy_type,deploy_time,deploy_hosts FROM deploy_info b INNER JOIN (SELECT MAX(id) AS id FROM deploy_info GROUP BY env,name) a ON a.id = b.id where env = '${env}' ORDER by deploy_time DESC;" | head -n 1 | awk -F '|' '{print $6}'
}

# 添加白名单
function add_white_list() {
    local env_name

    env_name=$1

    if [[ $(get_white_list "$env_name") -eq 0 ]];then
        pg_control -c "INSERT INTO shutdown_white_list VALUES('${env_name}','$(date "+%Y-%m-%d %H:%M:%S")');"
    else
        pg_control -c "UPDATE shutdown_white_list SET create_date='$(date "+%Y-%m-%d %H:%M:%S")' WHERE env_name ='${env_name}';"
    fi
}

# 获取白名单
function get_all_white_list() {
    # pg_control -c "SELECT * FROM shutdown_white_list;" | grep "${env_name}"
    pg_control -c "SELECT * FROM shutdown_white_list;"
}

# 查找指定环境是否存在白名单中
function get_white_list() {
    local env_name

    env_name=$1
    pg_control -t -c "SELECT * FROM shutdown_white_list WHERE env_name='${env_name}';" | grep "${env_name}" -c
}

# 查询环境白名单
function get_white_list_create_time() {
    local env_name

    env_name=$1
    pg_control -t -c "SELECT * FROM shutdown_white_list WHERE env_name='${env_name}';" | grep "${env_name}" | awk -F '|' '{print $2}'
}

# 删除白名单
function delete_white_list() {
    local env_name

    env_name=$1
    pg_control -c "DELETE FROM shutdown_white_list WHERE env_name='${env_name}';"
}

# 获取loadbalanceIP
function get_loadbalance_ip() {
    local env_name=$1
    kubectl -n "$env_name" get svc nacos-server-headless | awk '{print $4}' | tail -n 1
}

# 备份nacos
function backup_middleware_nacos() {
    local env_ip=$1
    local authorization
    # 如何获取多个namespace的
    # 1.登录获取authorization，若密码不正确，返回null，可利用其判断是否可以继续执行
    authorization=$(curl -X POST "http://${env_ip}:8848/nacos/v1/auth/login" -d 'username=nacos&password=nacos' -s | jq .data -r)
    if [[ $authorization == "null" ]] || [[ $authorization == "" ]]; then
        logging "nacos账户密码错误或服务异常,请手动验证: curl -X POST http://${env_ip}:8848/nacos/v1/auth/login -d 'username=nacos&password=nacos' -s | jq .data -r"
        return 1
    fi
    # 2.将authorization添加到header中，查询namespace
    for namespace in $(curl "http://${env_ip}:8848/nacos/v1/console/namespaces" -H "authorization: ${authorization}" -s | jq .data[].namespace); do
        curl -X GET "http://${env_ip}:8848/nacos/v1/cs/configs?export=true&group=&tenant=${namespace//\"/}&appName=&ids=&dataId=" -o "${env_backup_directory}/nacos_config_${namespace//\"/}_${Time}".zip -s
    done

    # curl -X GET "http://${env_ip}:8848/nacos/v1/cs/configs?export=true&group=&tenant=&appName=&ids=&dataId=" -o ${env_backup_directory}/nacos_config_"${Time}".zip -s
}

# 恢复nacos
function recovery_middleware_nacos(){
    local env_name
    local env_ip
    local env_backup_time

    env_name=$1
    env_backup_time=$2
    env_backup_time="$(date -d "${env_backup_time}" +"%Y%m%d")_$(date +%s -d "${env_backup_time}")"
    env_ip=$(get_loadbalance_ip "${env_name}")

    authorization=$(curl -X POST "http://${env_ip}:8848/nacos/v1/auth/login" -d 'username=nacos&password=nacos' -s | jq .data -r)
    if [[ $authorization == "null" ]] || [[ $authorization == "" ]]; then
        logging "nacos账户密码错误或服务异常,请手动验证: curl -X POST http://${env_ip}:8848/nacos/v1/auth/login -d 'username=nacos&password=nacos' -s | jq .data -r"
        return 1
    fi
    # 2.将authorization添加到header中，查询namespace
    for namespace in $(curl "http://${env_ip}:8848/nacos/v1/console/namespaces" -H "authorization: ${authorization}" -s | jq .data[].namespace); do
        if [[ -f "${env_backup_directory}/nacos_config_${namespace//\"/}_${env_backup_time}.zip" ]];then
            # 上传配置
            curl -X POST "http://${env_ip}:8848/nacos/v1/cs/configs?import=true&namespace=${namespace//\"/}&policy=OVERWRITE" --form "file=@${env_backup_directory}/nacos_config_${namespace//\"/}_${env_backup_time}.zip"
        else
            logging "文件不存在：${env_backup_directory}/nacos_config_${namespace//\"/}_${env_backup_time}.zip"
        fi
    done
    
}

# 备份eureka
function backup_middleware_eureka_status() {
    local env_ip=$1
    curl -X GET "http://${env_ip}:10100/eureka/apps" -o "${env_backup_directory}/eureka_status_${Time}.xml" -s
}

# 备份elasticserch
function backup_middleware_elasticserch() {
    local pod_name

    pod_name=$(kubectl -n "${env}" get pods | grep elasticsearch | awk '{print $1}')

    if [[ ${pod_name} ]];then
        kubectl -n "${env}" cp "${pod_name}":data "${env_backup_directory}/elasticsearch-data_${Time}" -c elasticsearch
    else
        logging "elasticserch 备份失败: 未找到相关pods"
        return 1
    fi
}

# 备份rocketmq
function backup_middleware_rocketmq() {
    local pod_name

    pod_name=$(kubectl -n "${env}" get pods | grep rocketmq-0 | awk '{print $1}')

    if [[ ${pod_name} ]];then
        kubectl -n "${env}" cp "${pod_name}":/root/store/config/topics.json "${env_backup_directory}/topics_${Time}.json" -c rocketmq-broker 1>/dev/null
    else
        logging "rocketmq 备份失败: 未找到相关pods"
        return 1
    fi
}

# 备份xxl-job
function backup_middleware_xxl_job() {
    local xxl_job_data_sql_name
    xxl_job_data_sql_name=xxl_job_nolog_${Time}.sql
    # 先在容器内导出文件
    kubectl -n "${env}" get pods | grep mysql | grep xxl | awk '{print $1}' | xargs -I {} kubectl -n "${env}" exec {} -c xxl-job-mysql -- sh -c "mysqldump -uroot -h 127.0.0.1 xxl_job xxl_job_group xxl_job_info xxl_job_lock xxl_job_logglue xxl_job_registry > /tmp/${xxl_job_data_sql_name}"
    # 然后copy当当前环境的指定目录下
    kubectl -n "${env}" get pods | grep mysql | grep xxl | awk '{print $1}' | xargs -I {} kubectl -n "${env}" -c xxl-job-mysql cp {}:"tmp/${xxl_job_data_sql_name}" "${env_backup_directory}/${xxl_job_data_sql_name}"
}

# 备份mongo
function backup_middleware_mongo() {
    local pod_name

    pod_name=$(kubectl -n "${env}" get pods | grep mongo-0 | awk '{print $1}')

    if [[ ${pod_name} ]];then
        kubectl -n "${env}" cp "${pod_name}":var/lib/mongodb "${env_backup_directory}/mongo-data-pvc_${Time}"
    else
        logging "mongo 备份失败: 未找到相关pods"
        return 1
    fi
}

# 备份redis
function backup_middleware_redis() {
    local pod_name

    pod_name=$(kubectl -n "${env}" get pods | grep redis-0 | awk '{print $1}')

    if [[ ${pod_name} ]];then
        kubectl -n "${env}" cp "${pod_name}":/opt/redis/data "${env_backup_directory}/redis-data_${Time}" 1>/dev/null
    else
        logging "redis 备份失败: 未找到相关pods"
        return 1
    fi
}

# 备份中间件
function backup_middleware() {
    # local Time
    # Time=$(date +%Y%m%d_%s)

    logging "开始备份所有中间件"
    if backup_middleware_nacos "$loadbalance_ip"; then
        logging "nacos 备份成功"
    fi

    if backup_middleware_elasticserch; then
        logging "elasticsearch 备份成功"
    fi

    if backup_middleware_rocketmq; then
        logging "rocketmq 备份成功"
    fi

    if backup_middleware_xxl_job; then
        logging "xxl-job 备份成功"
    fi

    if backup_middleware_mongo; then
        logging "mongo 备份成功"
    fi

    if backup_middleware_redis; then
        logging "redis 备份成功"
    fi

    backup_middleware_eureka_status "$loadbalance_ip"

    logging "中间件备份结束"
}

# 备份服务日志
function backup_service_log() {
    kubectl -n "${env}" get pods | grep test | awk '{print $1}' | xargs -I {} sh -c "kubectl -n ${env} logs {} > ${env_backup_directory}/{}_${Time}.log"
}

# 备份并关闭单个环境
function backup_and_shutdown_env() {
    local env=$1
    local loadbalance_ip
    local env_backup_directory
    local env_middleware_data
    local Time

    Time=$(date +%Y%m%d_%s)
    env_backup_directory="${BACKUP_DIRECTORY}/${env}"
    env_middleware_data="${MIDDLEWARE_DATA}/${env}"

    # 排除已经关停的环境，通过get pods是否为0，从数据库中查数据是否存在（先判断从数据库中查的，再通过get pods判断）
    if [[ $(get_shutdown_env_status "${env}") -eq 1 ]]; then
        logging "${env} 环境已关闭, 无需再次操作"
        return 0
    elif [[ $(kubectl get pods -n "${env}" 2>/dev/null | wc -l) -eq 0 ]]; then
        set_shutdown_env "${env}"
        logging "${env} 环境已关闭, 无需再次操作"
        return 0
    else
        # 获取 LoadBalancerIP
        loadbalance_ip=$(get_loadbalance_ip "${env}")

        # 创建目录
        if [ ! -d "$env_backup_directory" ]; then
            mkdir -p "${env_backup_directory}"
        fi

        # 备份中间件
        if backup_middleware; then
            logging '备份中间件成功'
        else
            logging "备份中间件失败"
        fi

        # 备份项目日志
        if backup_service_log; then
            logging '备份服务日志成功'
        else
            logging "备份服务日志失败"
        fi

        # 关停服务
        shutdown_env "$env"

        set_shutdown_env "${env}"

        # 进行关停
    fi
}

# 关停单个指定环境服务
function shutdown_env() {
    local env_name=$1

    logging "${env_name}, 开始关停所有服务"
    kubectl -n "${env_name}" get deployments.apps | grep -v NAME | awk '{print $1}' | xargs -I {} kubectl -n "${env_name}" scale deployment {} --replicas=0
    kubectl -n "${env_name}" get statefulsets.apps | grep -v NAME | awk '{print $1}' | xargs -I {} kubectl -n "${env_name}" scale statefulsets {} --replicas=0
    logging "${env_name}, 所有服务已关停"
}

# 恢复指定环境服务
function startup_env() {
    local env_name=$1

    if [[ $(get_shutdown_env_status "${env_name}") -eq 1 ]]; then
        logging "${env_name},存在已关停表中,启动所有服务"
        kubectl -n "${env_name}" get statefulsets.apps | grep -v NAME | awk '{print $1}' | xargs -I {} kubectl -n "${env_name}" scale statefulsets {} --replicas=1
        kubectl -n "${env_name}" get deployments.apps | grep -v NAME | awk '{print $1}' | xargs -I {} kubectl -n "${env_name}" scale deployment {} --replicas=1

        logging "${env_name},服务已启动,更新记录"
        update_shutdown_env "${env_name}"
    elif [[ $(kubectl get pods -n "${env_name}" 2>/dev/null | wc -l) -eq 0 ]]; then
        logging "${env_name},未在关停环境表中查到记录,但所有服务已关闭,启动所有服务"
        kubectl -n "${env_name}" get statefulsets.apps | grep -v NAME | awk '{print $1}' | xargs -I {} kubectl -n "${env_name}" scale statefulsets {} --replicas=1
        kubectl -n "${env_name}" get deployments.apps | grep -v NAME | awk '{print $1}' | xargs -I {} kubectl -n "${env_name}" scale deployment {} --replicas=1
    fi
}

# # 读取白名单
# function get_white_list_env() {
#     local file_path=$1
#     if [[ -f $file_path ]]; then
#         cat "$file_path"
#     else
#         echo "白名单文件不存在：$file_path"
#     fi
# }

# 获取测试环境namespace
function get_k3s_namespaces() {
    # kubectl get namespace | grep -E "test|dev" | awk '{print $1}'
    kubectl get namespace | grep -E "test|dev" | awk '{print $1}' | grep -E "tdyy|xxxx"
}

# 检查测试环境全部是否可以关停
function check_k3s_test_env_shutdown() {
    # local white_list
    local env_job_deploy_time
    local serven_days_time
    local while_list_period_time

    # 7天前的时间
    serven_days_time=$(date --date='7 days ago' +"%Y-%m-%d %H:%M:%S")
    # 白名单过期时间
    while_list_period_time=$(date --date=''${WHITE_LIST_PERIOD}' days ago' +"%Y-%m-%d %H:%M:%S")

    # 首先获取测试环境namespace列表
    for env in $(get_k3s_namespaces); do
        # 获取环境最新升级时间
        env_job_deploy_time=$(get_env_job_deploy_time_latest)
        while_list_create_time=$(get_white_list_create_time "${env}")

        if [[ $(date +%s -d "${serven_days_time}") -gt $(date +%s -d "${env_job_deploy_time}") ]]; then
            if [[ ${while_list_create_time} ]]; then
                if [[ $(date +%s -d "${while_list_period_time}") -gt $(date +%s -d "${while_list_create_time}") ]]; then
                    # 白名单达到过期时间
                    logging "${env}, 在白名单中,达到过期时间,进行关停。"
                    backup_and_shutdown_env "$env"
                    echo "关停$env"
                else
                    logging "${env}, 在白名单中,未达到过期时间,不符合关停条件。"
                fi
            else
                logging "${env}, 符合关停条件,进行关停。"
                backup_and_shutdown_env "$env"
            fi
        else
            # logging "${env}, 不符合关停条件。"
            :
        fi
    done
}


function recovery_middleware(){
    local env_name
    local type

    env_name=$1
    type=$2

    # 获取指定环境是否关闭，关闭时间，
    if [[ $(get_shutdown_env_status "${env_name}") -eq 1 ]];then
        env_shutdown_date=$(get_shutdown_env_shutdown_date "${env_name}")
        # env_shutdown_timestamp=$(date +%s -d "${env_shutdown_date}")
    fi

    if [[ ${type} == "nacos" ]];then
        recovery_middleware_nacos "${env_name}" "${env_shutdown_date}"
    fi

}

# check_k3s_test_env_shutdown

# 需不需要添加一步自检，如检查jq是否安装，数据库中表是否存在，若不满足条件，则提示

# 默认执行该脚本，检查所有测试环境是否能关停

if [[ $# -eq 0 ]]; then
    check_k3s_test_env_shutdown
elif [[ ${TYPE} == "shutdown" ]]; then
    if [[ ${ENV_NAME} ]]; then
        # 关停单个环境
        # shutdown_env "${ENV_NAME}"
        if [[ $(get_k3s_namespaces) =~ (^|[[:space:]])$ENV_NAME($|[[:space:]]) ]]; then
            backup_and_shutdown_env "$ENV_NAME"
        else
            logging "当前k3s环境中不存在该 namespace: $ENV_NAME, 无法关停该环境。"
        fi
    else
        usage
    fi
elif [[ ${TYPE} == "startup" ]]; then
    if [[ ${ENV_NAME} ]]; then
        # 恢复单个环境
        if [[ $(get_k3s_namespaces) =~ (^|[[:space:]])$ENV_NAME($|[[:space:]]) ]]; then
            startup_env "${ENV_NAME}"
        else
            logging "当前k3s环境中不存在该 namespace: $ENV_NAME, 无法启动该环境。"
        fi
    else
        usage
    fi
elif [[ ${TYPE} == "addwhitelist" ]]; then
    if [[ ${ENV_NAME} ]]; then
        # 添加白名单
        add_white_list "${ENV_NAME}"
    else
        usage_whitelist
    fi
elif [[ ${TYPE} == "deletewhitelist" ]]; then
    if [[ ${ENV_NAME} ]]; then
        # 添加白名单
        delete_white_list "${ENV_NAME}"
    else
        usage_whitelist
    fi
elif [[ ${TYPE} == "getwhitelist" ]]; then
    get_all_white_list
elif [[ ${TYPE} == "recovery" ]]; then
    if [[ ${ENV_NAME} ]] && [[ ${MIDDLEWARE} ]]; then
        # 恢复中间件
        if [[ $(get_k3s_namespaces) =~ (^|[[:space:]])$ENV_NAME($|[[:space:]]) ]]; then
            recovery_middleware "${ENV_NAME}" "${MIDDLEWARE}"
        else
            logging "当前k3s环境中不存在该 namespace: $ENV_NAME, 执行结束。"
        fi
    else
        usage_recovery
    fi
else
    usage
fi