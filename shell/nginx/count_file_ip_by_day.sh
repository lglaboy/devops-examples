#!/bin/bash
# Date: 2023-10-09 11:47
# Author: liuguoliang
# Mail: liuguoliang@swifthealth.cn
# Description: 统计nginx日志，按照ip统计，每个文件，每天
# Version: v1.0

LOG_DIR="/var/log/nginx"
TMP_DIR="/var/lib/docker/tmp"
log_file="/tmp/count_nginx_log_ip_by_day.log"
tmp_csv_file=$TMP_DIR/tmp.csv

# 输出结果
output_file_by_day="/tmp/count_nginx_log_ip_by_day.csv"
output_file_by_day_by_hour="/tmp/count_nginx_log_ip_by_day_by_hour_top10.csv"

# 检查文件是否存在,存在则备份
check_file() {
    local filename=$1
    if [ -f "$filename" ]; then
        backup_file="${filename}.backup_$(date +'%Y%m%d%H%M%S')"
        mv "$log_file" "$backup_file"
        echo "已备份日志文件为: $backup_file"
    fi
}

# 删除csv缓存文件
delete_tmp_csv_file() {
    if [ -f $tmp_csv_file ]; then
        rm -rf $tmp_csv_file
    fi
}

# 输入 08/Sep/2023:17:31:41 +0800 格式 返回 2023-09-08 17:31:41
format_date() {
    local local_date=$1
    python3 -c "from datetime import datetime; print(datetime.strptime('$local_date', '%d/%b/%Y:%H:%M:%S %z').strftime('%Y-%m-%d %H:%M:%S'))"
}

# 输入 08/Sep/2023:17:31:41 +0800 格式 返回 2023-09-08,17
format_date_by_csv() {
    local local_date=$1
    python3 -c "from datetime import datetime; print(datetime.strptime('$local_date', '%d/%b/%Y:%H:%M:%S %z').strftime('%Y-%m-%d,%H'))"
}

# 逐个文件处理，输出文件名，起始时间，ip
count_ip() {
    local file=$1
    tmp_file="$TMP_DIR/$(basename "$file")"
    # 复制到临时目录
    cp "$file" "$TMP_DIR"

    # 判断文件类型
    if [[ $(file -b --mime-type "$tmp_file") == "application/gzip" ]]; then
        # 解压Gzip文件,文件名改变 gateway-prod_access.log.2.gz -> gateway-prod_access.log.2
        gzip -d "$tmp_file"
        tmp_file="$(dirname "$tmp_file")/$(basename "$tmp_file" .gz)"
    fi

    # 输出文件名
    basename "$file"

    # 输出时间
    head -n 1 "$tmp_file" | awk -F ',' '{print $4}' | awk -F '":"' '{print $2}' | sed 's/"//g'

    # 输出结果
    # 总量
    awk -F ',' '{print $3}' "$tmp_file" | awk -F ':' '{print $2}' | sed 's/"//g' | sort | wc -l
    # ip top 100
    awk -F ',' '{print $3}' "$tmp_file" | awk -F ':' '{print $2}' | sed 's/"//g' | sort | uniq -c | sort -nk1 -r | head -n 100
    # 输出结束时间
    tail -n 1 "$tmp_file" | awk -F ',' '{print $4}' | awk -F '":"' '{print $2}' | sed 's/"//g'

    # 删除临时文件
    rm -rf "$tmp_file"
}

# 从nginx日志中获取时间和IP
get_date_ip_from_nginx_log() {
    local file=$1
    local tmp_file
    # local file_name
    # echo "$file"
    tmp_file="$TMP_DIR/$(basename "$file")"
    # 复制到临时目录
    cp "$file" "$TMP_DIR"

    # 判断文件类型
    if [[ $(file -b --mime-type "$tmp_file") == "application/gzip" ]]; then
        # 解压Gzip文件,文件名改变 gateway-prod_access.log.2.gz -> gateway-prod_access.log.2
        gzip -d "$tmp_file"
        tmp_file="$(dirname "$tmp_file")/$(basename "$tmp_file" .gz)"
    fi
    awk -F ',' '{print $3 "," $4}' "$tmp_file" | awk -F '"' '{print $8 "," $4}' >>$tmp_csv_file
    # 删除临时文件
    rm -rf "$tmp_file"
}

# tmp_csv_file 时间转换
# 处理速度太慢了，pass
format_tmp_csv_file_bak() {
    # 处理CSV文件
    while IFS=, read -r date ip; do
        # 解析日期字符串并重新格式化
        time=$(echo "$date" | sed 's/\// /g' | sed 's/:/ /')

        formatted_date=$(date +"%Y-%m-%d %H:%M:%S" -d "$time")

        # 写入新的CSV文件
        echo "$formatted_date,$ip" >>"test_output.csv"
    done <"test.csv"
}

format_tmp_csv_file() {
    local file=$1
    # 排除空行,按照指定格式输入到临时文件
    grep -v "^,$" "$file" | awk -F ':|,' '{print $1 "," $2 "," $NF}' >>"$file.tmp"
    # 粗排后统计数量并按照指定格式输出
    sort "$file.tmp" | uniq -c | awk '{print $2","$1}' >>"$file.tmp_count"

    # 按照日期，时间分组 升序 按照数量降序排列
    sort -t',' -k1.4,1.7M -k1.1,1.2n -k1.8,1.9n -k2,2n -k4,4nr "$file.tmp_count" >>"$file.tmp_count_sort"

    # 统计每天总的访问量
    awk -F',' '{
        group = $1 "," $2;
        count = $4;

        total_count[group] += count;
    }

    END {
        for (group in total_count) {
            print group "," total_count[group];
        }
    }' "$file.tmp_count_sort" | sort -t',' -k1.4,1.7M -k1.1,1.2n -k1.8,1.9n -k2,2n -k4,4nr >>"$output_file_by_day"

    # 统计每天每小时top10 IP 访问量
    awk -F',' '{if ($1","$2 != prev) {count=0; prev=$1","$2} if (count < 10) {print $0; count++}}' "$file.tmp_count_sort" >>"$output_file_by_day_by_hour"

    # 清理缓存文件
    cd "$(dirname "$file")" || return
    tar -czvf "count_nginx_log_backup_$(date +'%Y%m%d%H%M%S').tar.gz" "$(basename "$file").tmp" "$(basename "$file").tmp_count" "$(basename "$file").tmp_count_sort"

    rm -rf "$file.tmp" "$file.tmp_count" "$file.tmp_count_sort"
}

# 按天统计top 100 IP
main() {
    for file in "$LOG_DIR"/*access*; do
        count_ip "$file"
    done
}

test_main() {
    for file in $LOG_DIR/gateway-prod_access.log.1; do
        count_ip "$file"
    done
}

# 统计所有日志
main_by_hour() {
    delete_tmp_csv_file

    # 统计所有文件中的日志
    # for file in "$LOG_DIR"/*access*
    find "$LOG_DIR"/*access* | sort -t '.' -k 1,1 -k 3,3n | while IFS= read -r file; do
        get_date_ip_from_nginx_log "$file"
    done
    # 从tmp_csv_file中格式化数据
    format_tmp_csv_file $tmp_csv_file

    # 输出结果
    echo "每天每小时请求量: $output_file_by_day"
    echo "每天每小时top10 IP 请求: $output_file_by_day_by_hour"
}

# 测试 main_by_hour 函数
test_main_by_hour() {
    delete_tmp_csv_file

    # 统计指定文件中的日志，测试
    find "$LOG_DIR"/*gateway-prod_access* | sort -t '.' -k 3,3n | while IFS= read -r file; do
        get_date_ip_from_nginx_log "$file"
    done
    # 从tmp_csv_file中格式化数据
    format_tmp_csv_file $tmp_csv_file
}

# 清理输出文件
check_file $log_file
check_file $output_file_by_day
check_file $output_file_by_day_by_hour

# test_main >> $log_file 2>&1
#
# main >> $log_file 2>&1

# get_date_ip_from_nginx_log "/var/log/nginx/manage-web-prod_access.log"
# main_by_hour
test_main_by_hour
