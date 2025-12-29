#!/bin/bash
# 生成排版列表，用于 huawei-voicecall-webhook服务，语音通知使用
# 使用说明：根据自身情况调整排版顺序及内容
# 生成规则:
# 1.所需格式: 2024-11-21,张某,138********
# 2.周六，指定某人
# 3.周日，两人轮着来
# 4.周内，三人轮着来

# 获取当前年份
year=$(date +%Y)
name=("张某,138********" "刘某某,178********" "张某某,180********")
week_flag=0
sun_name=("刘某某,178********" "张某某,180********")
sun_flag=0

# 遍历从1月1日到12月31日的所有日期
for month in {1..12}; do
    for day in {1..31}; do
        # 判断日期是否存在
        if date -d "$year-$month-$day" +"%Y-%m-%d" 1>/dev/null 2>&1; then
            # 使用date命令将日期格式化为指定格式
            formatted_date=$(date -d "$year-$month-$day" +"%Y-%m-%d")

            # 周六指定某人
            if [[ $(date -d "$year-$month-$day" +"%A") == "Saturday" ]]; then
                echo "$formatted_date,张某,138********"
            # 周日，两人轮着来
            elif [[ $(date -d "$year-$month-$day" +"%A") == "Sunday" ]]; then
                if [[ $sun_flag == 0 ]]; then
                    echo "$formatted_date,${sun_name[$sun_flag]}"
                    sun_flag=1
                elif [[ $sun_flag == 1 ]]; then
                    echo "$formatted_date,${sun_name[$sun_flag]}"
                    sun_flag=0
                fi
            # 周内，三人轮着来
            else
                if [[ $week_flag == 0 ]]; then
                    echo "$formatted_date,${name[$week_flag]}"
                    week_flag=1
                elif [[ $week_flag == 1 ]]; then
                    echo "$formatted_date,${name[$week_flag]}"
                    week_flag=2
                elif [[ $week_flag == 2 ]]; then
                    echo "$formatted_date,${name[$week_flag]}"
                    week_flag=0
                fi

            fi
        fi
    done
done
