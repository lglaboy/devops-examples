#!/bin/bash
# 每天定时更新补全
# 更新tab补全tools相关job
# 00 00 * * * bash /usr/local/bin/complete_tool_cron.sh

# 设置环境变量，防止tools命令找不到
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

cache_dir="/tmp/tools_cache"
env_list_cache="$cache_dir/env_list"

# 初始化缓存目录
if [[ ! -d $cache_dir ]]; then
    mkdir -p $cache_dir
fi

# 更新环境列表
tools -t env | awk -F '|' '{print $2}' | tail -n +4 | grep -v "^$" | xargs -n 1 | sort > $env_list_cache

# 更新本地job列表
for envname in $(cat $env_list_cache)
do
	tools -t job -e ${envname} | grep ${envname} | sed "s/[\']/\n/g" | sed '/[,\|]/d' | sort > "$cache_dir/${envname}_job_list"
done

# 更新jenkins上job列表
for envname in $(cat $env_list_cache)
do
	tools -t build -e ${envname} -l | awk -F "|" '{print $2}' > "$cache_dir/${envname}_jenkins_job_list"
done

# 更新jenkins上multijob补全
for envname in $(cat $env_list_cache)
do
	tools -t build -e ${envname} > "$cache_dir/${envname}_jenkins_multijob_list"
done
