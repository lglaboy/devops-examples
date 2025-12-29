#!/bin/sh
# Date: 2023-01-09 15:56
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: The machine memory usage is too high. Kill postgresql specifies the process
# Version: v1.0

# 定义变量，指定默认值
PG_IP=${PG_IP:-localhost}
PG_PORT=${PG_PORT:-5432}
PG_DATABASE=${PG_DATABASE:-postgres}
PG_USER=${PG_USER:-monitor}
PG_PASSWD=${PG_PASSWD:-qNO857n0}

# 循环时间(s)
INTERVAL=${INTERVAL:-1}

# 内存使用率(%)
MEM_USAGE=${MEM_USAGE:-98}

# 颜色显示
# set color
# sh 不支持
# echoRed() { echo $'\e[0;31m'"$1"$'\e[0m'; }
# echoGreen() { echo $'\e[1;32m'"$1"$'\e[0m'; }
# echoYellow() { echo $'\e[0;33m'"$1"$'\e[0m'; }
# echoBule() { echo $'\e[0;36m'"Start: $1"$'\e[0m'; }

# 获取毫秒值
get_millisecond() {
    if [ -f /etc/os-release ] && [ "$(grep -c "Alpine Linux" /etc/os-release)" -gt 0 ];then
        nmeter -d0 '%3t' | head -n1 | awk -F '.' '{print $2}'
    else
        echo "000"
    fi
}

# 设置echo 带时间
logging_info() {
    _logging_info_data=$1
    echo "$(date "+%Y-%m-%d %H:%M:%S.$(get_millisecond)") INFO ${_logging_info_data}"
}

logging_error() {
    _logging_error_data=$1
    echo "$(date "+%Y-%m-%d %H:%M:%S.$(get_millisecond)") ERROR ${_logging_error_data}"
}

check_config(){
    # 检查变量
    if [ "$MEM_USAGE" -le 0 ] || [ "$MEM_USAGE" -ge 100 ]; then
        logging_error "Incorrect variable format, MEM_USAGE: ${MEM_USAGE}, 0 < MEM_USAGE < 100"
        exit 1
    fi

    # 检查数据库能否连接
    if ! PGPASSWORD=${PG_PASSWD} psql -h "${PG_IP}" -p "${PG_PORT}" -U "${PG_USER}" "${PG_DATABASE}" -t -c "SELECT version();"; then
        logging_error "Database connection exception."
        exit 1
    fi
}

# 输出相关配置
config_info() {
    logging_info "服务配置信息:"
    logging_info "数据库地址(PG_IP): ${PG_IP}"
    logging_info "数据库端口(PG_PORT): ${PG_PORT}"
    logging_info "数据库名称(PG_DATABASE): ${PG_DATABASE}"
    logging_info "数据库用户(PG_USER): ${PG_USER}"
    logging_info "数据库密码(PG_PASSWD): ${PG_PASSWD}"
    printf "\n"
    logging_info "检查间隔(INTERVAL)(s): ${INTERVAL}"
    logging_info "主机内存使用率(MEM_USAGE)(%): ${MEM_USAGE}"
    printf "\n"
    # 检查配置
    if check_config;then
        logging_info "检查主机内存,当主机内存使用率大于等于指定内存使用率(${MEM_USAGE}%)时, kill查询到的指定进程ID"
        logging_info "服务启动成功"
    fi
}

# 获取可用内存
get_mem_available() {
    grep MemAvailable /proc/meminfo | awk '{print $2}'
}

# 获取指定内存剩余量
get_appoint_mem_remnant() {
    _get_mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    echo $((_get_mem_total * (100 - MEM_USAGE) / 100))
}

# 获取指定idle进程
get_appoint_idle() {
    PGPASSWORD=${PG_PASSWD} psql -h "${PG_IP}" -p "${PG_PORT}" -U "${PG_USER}" "${PG_DATABASE}" -t -c "select pid from pg_stat_activity where state='idle' and (query ='COMMIT' or query='SELECT version()');"
}

# kill 指定进程
kill_idle_process() {
    _idle_process_pid=$1
    PGPASSWORD=${PG_PASSWD} psql -h "${PG_IP}" -p "${PG_PORT}" -U "${PG_USER}" "${PG_DATABASE}" -t -c "select pg_terminate_backend(${_idle_process_pid});" > /dev/null
}

# kill 查询到的指定进程
kill_get_idle_process() {
    PGPASSWORD=${PG_PASSWD} psql -h "${PG_IP}" -p "${PG_PORT}" -U "${PG_USER}" "${PG_DATABASE}" -t -c "select pg_terminate_backend(pid) from pg_stat_activity where state='idle' and (query ='COMMIT' or query='SELECT version()');" > /dev/null
}

# 检查内存，判断是否kill idle pid
check_mem_kill_idle() {
    # 死循环
    while true; do
        # 判断使用内存是否大于等于指定内存使用率
        # 根据可用内存计算 $((总内存*2/100)) >= 可用内存，kill
        if [ "$(get_appoint_mem_remnant)" -ge "$(get_mem_available)" ]; then
            logging_info "限制可用内存: $(get_appoint_mem_remnant), 可用内存: $(get_mem_available), 符合内存剩余不足条件."
            kill_get_idle_process
            # for循环杀掉pid
            # for pid in $(get_appoint_idle); do
            #     if ! kill_idle_process "${pid}"; then
            #         logging_error "Kill postgresql idle process pid(${pid}) error."
            #     else
            #         logging_info "Kill postgresql idle process pid(${pid}) success."
            #     fi
            # done
        else
            logging_info "限制可用内存: $(get_appoint_mem_remnant), 可用内存: $(get_mem_available), 不符合内存剩余不足条件."
        fi
        sleep 1
    done
}

main(){
    # 输出配置信息
    config_info
    # 检查
    check_mem_kill_idle
}

main