#!/bin/bash
if [[ -z $1 ]]; then
    echo "提供查询接口"
    echo "Example: $0 patient/v1/report/check/detail"
    exit 1
fi
check_uri=$1

#不需要在内部分类
checkTYPE="http_host"
#检查
# checkTYPE=UC
#检验
# checkTYPE=UL

if [[ -n $2 ]]; then
    checkTYPE=$2
fi


result=0  # 初始化统计结果
all_result=0
# 遍历从 0 到 1 的日志文件
sudo cat /var/log/nginx/gateway*_*access.log | \
         grep "${check_uri}"|grep ${checkTYPE}|head -n 1

count0=$(sudo cat /var/log/nginx/gateway*_*access.log | \
         grep ${check_uri} | grep ${checkTYPE} | \
         awk -F 'swift_x_actual_user_id' '{print $2}' | \
         awk -F '"' '{print $3}' | \
         sort | uniq | wc -l)

call_count0=$(sudo cat /var/log/nginx/gateway*_*access.log | \
         grep ${check_uri} |grep ${checkTYPE} | wc -l)
# 遍历从 1 到 14 的日志文件
echo '今天调用人数 '$count0
echo '今天调用次数 '$call_count0

count1=$(sudo cat /var/log/nginx/gateway*_*access.log.1 | \
         grep ${check_uri} | grep ${checkTYPE} |  \
         awk -F 'swift_x_actual_user_id' '{print $2}' | \
         awk -F '"' '{print $3}' | \
         sort | uniq | wc -l)

call_count1=$(sudo cat /var/log/nginx/gateway*_*access.log.1 | \
         grep ${check_uri} | grep ${checkTYPE} | wc -l)

result=$((count0 + count1))
all_result=$((call_count0 + call_count1))

for i in {2..14}; do
    # 使用 ls 查找匹配的文件
    files=$(ls /var/log/nginx/gateway*_*access.log.$i.* 2>/dev/null)

    # 检查是否找到匹配的文件
    if [ -n "$files" ]; then
        # 对匹配的文件进行处理
        for file in $files; do
            # 使用 zcat 解压和处理日志内容
            count=$(sudo zcat "$file" | \
                    grep ${check_uri} | grep ${checkTYPE} | \
                    awk -F 'swift_x_actual_user_id' '{print $2}' | \
                    awk -F '"' '{print $3}' | \
                    sort | uniq | wc -l)
            # 累加统计结果
            result=$((result + count))
        done
    fi
done

for i in {2..14}; do
    # 使用 ls 查找匹配的文件
    files=$(ls /var/log/nginx/gateway*_*access.log.$i.* 2>/dev/null)

    # 检查是否找到匹配的文件
    if [ -n "$files" ]; then
        # 对匹配的文件进行处理
        for file in $files; do
            # 使用 zcat 解压和处理日志内容
            count=$(sudo zcat "$file" | \
                    grep ${check_uri} | grep ${checkTYPE} |wc -l)
            # 累加统计结果
            all_result=$((all_result + count))
        done
    fi
done

echo $check_uri 接口总调用人数 $result
echo $check_uri 总调用次数 $all_result