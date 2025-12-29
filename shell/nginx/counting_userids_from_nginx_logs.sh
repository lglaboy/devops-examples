#!/bin/bash
# Date: 2023-10-10 14:18
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: 统计nginx日志，每个文件，每天，每小时，统计date，ip，userid
# Version: v1.0

LOG_DIR="/var/log/nginx"
TMP_DIR="/var/lib/docker/tmp"
log_file="/tmp/count_nginx_log_ip_by_day.log"
tmp_csv_file=$TMP_DIR/tmp.csv

# 输出结果
output_file_by_day_by_hour="/tmp/count_nginx_log_ip_by_day_by_hour.csv"
output_file_by_day_by_hour_top100="/tmp/count_nginx_log_ip_by_day_by_hour_top100.csv"
output_file_by_day_by_hour_userids="/tmp/count_nginx_log_ip_by_day_by_hour_userids.csv"

# 检查文件是否存在,存在则备份
check_file() {
    local filename=$1
    if [ -f "$filename" ]; then
        backup_file="${filename}.backup_$(date +'%Y%m%d%H%M%S')"
        mv "$filename" "$backup_file"
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

# 从nginx日志中获取时间,IP,userid
get_date_ip_userid_from_nginx_log() {
    local file=$1
    local tmp_file
    # local file_name
    # echo "$file"
    # tmp_file="$TMP_DIR/$(basename "$file")"

    # TODO: 如果不copy估计能提速,如果不是压缩文件，直接过滤源文件，输出结果
    # 如果是压缩文件，能否直接解压到指定目录中，进行过滤

    # 复制到临时目录
    # cp "$file" "$TMP_DIR"

    # 判断文件类型
    if [[ $(file -b --mime-type "$file") == "application/gzip" ]]; then
        # 解压Gzip文件,文件名改变 gateway-prod_access.log.2.gz -> gateway-prod_access.log.2
        # gzip -d "$tmp_file"
        tmp_file="$TMP_DIR/$(basename "$file" .gz)"
        gzip -dc <"$file" >"$tmp_file"

        # 10/Oct/2023,06,122.112.176.239,-
        # 10/Oct/2023,06,124.67.18.204,105769148
        awk -F ',"' '{print $4 "," $3","$20}' "$tmp_file" | awk -F '"' '{print $3 "," $6 ","$(NF-1)}' | awk -F ':|,' '{print $1 "," $2 "," $(NF-1)","$NF}' | grep -v "^,,,$" >>$tmp_csv_file

        # 删除临时文件
        rm -rf "$tmp_file"
    else
        awk -F ',"' '{print $4 "," $3","$20}' "$file" | awk -F '"' '{print $3 "," $6 ","$(NF-1)}' | awk -F ':|,' '{print $1 "," $2 "," $(NF-1)","$NF}' | grep -v "^,,,$" >>$tmp_csv_file
    fi

    # 三次awk，第一次过滤使用,"分割,预防有的url中携带,符号
    # awk -F ',"' '{print $4 "," $3","$20}' |awk -F '"' '{print $3 "," $6 ","$(NF-1)}'|awk -F ':|,' '{print $1 "," $2 "," $(NF-1)","$NF}' |grep -v "^,,,$"

    # 两次awk
    # awk -F '","|,"' '{print $3","$4","$20}' | awk -F '"|,|:' '{print $8","$9","$4","$NF}' | grep -v "^,,,$"
}

# 按照指定格式从临时文件中获取数据
get_date_userid_from_tmp_csv_file() {
    local file=$1
    local backup_file
    # 从临时文件中获取指定数据
    # 10/Oct/2023,06,-
    # 10/Oct/2023,06,123560307
    # awk -F ',' '{print $1 "," $2 "," $4}' "$file" >>"$file.tmp"
    cut -d ',' -f 1,2,4 "$file" >>"$file.tmp"

    # 排序，统计访问量，指定格式输出，按照日期，时间 分组升序，按照访问量降序排序
    # sort "$file.tmp" |uniq -c| awk '{print $2","$1}' | sort -t',' -k1.4,1.7M -k1.1,1.2n -k1.8,1.9n -k2,2n -k4,4nr >>"$file.tmp_count_sort"

    # 统计相同行数据
    awk '{count[$0]++} END {for (line in count) print line "," count[line]}' "$file.tmp" >>"$file.tmp_count"

    # 按照日期，时间分组 升序 按照数量降序排列
    sort -t',' -k1.4,1.7M -k1.1,1.2n -k1.8,1.9n -k2,2n -k4,4nr "$file.tmp_count" >>"$file.tmp_count_sort"

    # 统计每天每小时所有Userid访问总量
    grep -v "-" "$file.tmp_count_sort" | awk -F',' '{
        group = $1 "," $2;
        count = $4;

        total_count[group] += count;
    }

    END {
        for (group in total_count) {
            print group "," total_count[group];
        }
    }' | sort -t',' -k1.4,1.7M -k1.1,1.2n -k1.8,1.9n -k2,2n -k4,4nr >>"$output_file_by_day_by_hour"

    # 统计每天每小时top100 Userid 访问量
    grep -v "-" "$file.tmp_count_sort" | awk -F',' '{if ($1","$2 != prev) {count=0; prev=$1","$2} if (count < 100) {print $0; count++}}' >>"$output_file_by_day_by_hour_top100"

    # 统计每天每小时不同 user_id 总量
    grep -v -E "Feb/2023|Mar/2023|-" "$file.tmp_count_sort" | awk -F',' '{
        group = $1 "," $2;
        count = 1;
        
        total_count[group] += count;
    }

    END {
        for (group in total_count) {
            print group "," total_count[group];
        }
    }' | sort -t',' -k1.4,1.7M -k1.1,1.2n -k1.8,1.9n -k2,2n >"$output_file_by_day_by_hour_userids"

    # 清理缓存文件
    cd "$(dirname "$file")" || return

    backup_file="count_nginx_log_backup_$(date +'%Y%m%d%H%M%S').tar.gz"

    tar -czvf "$backup_file" "$(basename "$file").tmp" "$(basename "$file").tmp_count" "$(basename "$file").tmp_count_sort"

    rm -rf "$file.tmp" "$file.tmp_count" "$file.tmp_count_sort"

    # 输出结果
    echo "统计数据备份文件: $backup_file"
    echo "每天每小时所有userid请求量: $output_file_by_day_by_hour"
    echo "每天每小时top100 用户请求: $output_file_by_day_by_hour_top100"
    echo "每天每小时不同userid用户数: $output_file_by_day_by_hour_userids"
}

# 统计所有日志
main_by_hour() {
    delete_tmp_csv_file

    # 统计所有文件中的日志
    # for file in "$LOG_DIR"/*access*
    find "$LOG_DIR"/*access* | sort -t '.' -k 1,1 -k 3,3n | while IFS= read -r file; do
        get_date_ip_userid_from_nginx_log "$file"
    done
    # TODO: 从tmp_csv_file中格式化数据
    # get_date_userid_from_tmp_csv_file $tmp_csv_file
}

# 测试 main_by_hour 函数
test_main_by_hour() {
    delete_tmp_csv_file

    # 统计指定文件中的日志，测试
    # for file in "$LOG_DIR"/*gateway-prod_access*
    find "$LOG_DIR"/*gateway-prod_access* | sort -t '.' -k 3,3n | while IFS= read -r file; do
        get_date_ip_userid_from_nginx_log "$file"
    done
    # 从tmp_csv_file中格式化数据
    # get_date_userid_from_tmp_csv_file $tmp_csv_file
}

# 清理输出文件
check_file $log_file
check_file $output_file_by_day_by_hour
check_file $output_file_by_day_by_hour_top100

# test_main >> $log_file 2>&1
#
# main >> $log_file 2>&1

# get_date_ip_userid_from_nginx_log "/var/log/nginx/manage-web-prod_access.log"
# main_by_hour
get_date_userid_from_tmp_csv_file $tmp_csv_file
# test_main_by_hour


# TODO: 命令执行
# 1.自动过滤日志，获取输出结果
# 2.指定文件过滤输出结果
# 3.指定类型，从所有日志获取指定格式内容


