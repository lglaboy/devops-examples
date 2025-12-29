#!/usr/bin/env bash

# 监控 docker应用的异常日志
# 发送异常日志时重启对应容器

#检测脚本日志文件
MONITOR_LOG_FILE=/opt/monitor.log
#检测的错误信息 默认是: 获取连接超时错误
ERROR_MSG=${ERROR_MSG:-com.alibaba.druid.pool.GetConnectionTimeoutException}
# 匹配关键字数量
ErrorCounts=${ErrorCounts:-3}
# 默认5分钟内的容器日志
CHECK_TIME=${CHECK_TIME:-5m}
INTERVAL=${INTERVAL:-30}
JobName=${JobName:-_test$|_mysql$}

usage() {
  echo "usage:"
  echo "${0}  [-j JobName] [-m keyword] [-c count] [-i second(s)] [-t time(5m)]"
  echo -e "\nOptions:"
  echo -e "-j gateway_prod  Monitoring container name(default \"All containers ending with _test and _prod\")"
  echo -e "-m keyword       Matching keywords(default \"com.alibaba.druid.pool.GetConnectionTimeoutException\")"
  echo -e "-c 3             Number of matches to keyword(default \"3\")"
  echo -e "-i 10            Matching interval(default \"30(s)\")"
  echo -e "-t 5m            Check the docker log time (default \"5m\")"
  echo -e "\nEg:"
  echo "监控gateway_prod服务, 匹配关键字\"ERROR\".(默认每次检查间隔: 30(s), 日志区间: 5m, 匹配条数: 3)"
  echo "${0} -j gateway_prod -m ERROR"
  echo "同时监控gateway_prod和patient_prod服务, 匹配关键字: ERROR .(默认每次检查间隔: 30(s), 日志区间: 5m, 匹配条数: 3)"
  echo "${0} -j \"gateway_prod|patient_prod\" -m ERROR"
  echo "监控gateway_prod服务, 匹配关键字: ERROR, 匹配条数: 3, 检查间隔: 10(s), 检查日志区间: 3m"
  echo "${0} -j gateway_prod -m ERROR -c 3 -i 10 -t 3m"
  exit 1
}

while getopts 'j:m:c:i:t:' opt; do
  case $opt in
  j)
    JobName=$OPTARG
    ;;
  m)
    ERROR_MSG=$OPTARG
    ;;
  c)
    ErrorCounts=$OPTARG
    ;;
  i)
    INTERVAL=$OPTARG
    ;;
  t)
    CHECK_TIME=$OPTARG
    ;;
  ?)
    usage
    exit 1
    ;;
  esac
done

#log方法
function log() {
  echo "$(date +'%F %T') $*" >>$MONITOR_LOG_FILE
}

#检测异常并重启应用
function check() {
  # local counts=$1
  #循环所有docker实例
  for name in $(docker ps --format {{.Names}} | grep -E "$JobName"); do
    check_job "$name" "$ErrorCounts"
  done
}

# 指定项目名称检测
function check_job() {
  local jobname=$1
  local counts=$2

  #检查最近5分钟日志是否存在指定错误信息
  if [ "$(docker logs --since "$CHECK_TIME" "$jobname" | grep -c "$ERROR_MSG")" -ge "$counts" ]; then
    log "检测到错误信息，需要重启应用实例:$jobname"
    docker restart "$jobname"
    log "重启命令完成:$jobname"
  else
    log "执行检测中:$jobname"
  fi

}

#入口
while :; do

  check
  log "本次检查完成"
  sleep "$INTERVAL"
done
