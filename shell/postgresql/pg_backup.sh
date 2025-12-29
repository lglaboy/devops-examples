#!/bin/bash

# 备份:
# 每7天为一个周期，第一次备份一份全量数据
# 第二天开始增量备份
# 恢复：
# 先恢复全量数据
# 再恢复增量数据

HOSTNAME=$(hostname)
HostName=${HOSTNAME,,}
bak_file=/tmp/pg_data_backup
file_ssd=/data/ssd
file_swdb=/data/swdb
file_var_main=/var/lib/postgresql/11/main
file_etc_main=/etc/postgresql/11/main

DockerBaseImage=registry.xxxxxxxx.cn/common-server/busybox
DockerAllImage=registry.xxxxxxxx.cn/backup/pg-data-backup/${HostName}
DockerAddImage=registry.xxxxxxxx.cn/backup/pg-data-backup/${HostName}

file_date=`date +%Y-%m-%d`
backup_file_date=`ls ${bak_file}/*full* | awk -F '_' '{print $6}'`
week_day=$(date +%w)

if [ ! -d ${bak_file} ];then
    mkdir -p ${bak_file}
fi

# 判断是否有基础镜像
ImageBaseNum=$(docker images ${DockerBaseImage} | wc -l)
if [ ${ImageBaseNum} -gt 1 ]; then
    :
else
    docker pull ${DockerBaseImage}
fi

### 启动基础容器
docker run --name pg_data_backup -itd ${DockerBaseImage} /bin/sh

### 全量、增量备份方案
full_backup_days=`date +'%Y-%m-%d' -d "+7 day ${backup_file_date}"`

#if [ ! -f ${bak_file}/*full* ] || [ ${file_date} == ${full_backup_days} ];then
#    rm -rf ${bak_file}/*full*
#    tar -g ${bak_file}/snapshot -zcvf ${bak_file}/pg_data_backup_${file_date}_full.tar.gz ${file_ssd} ${file_swdb} ${file_var_main} ${file_etc_main}
#    docker cp ${bak_file}/pg_data_backup_${file_date}_full.tar.gz pg_data_backup:/
#    docker commit -a "" -m "pg_data_backup" pg_data_backup ${DockerAllImage}:latest
#    docker push ${DockerAllImage}:latest
#else
#    tar -g ${bak_file}/snapshot -zcvf ${bak_file}/pg_data_backup_${file_date}_add.tar.gz ${file_ssd} ${file_swdb} ${file_var_main} ${file_etc_main}
#    docker cp ${bak_file}/pg_data_backup_${file_date}_full.tar.gz pg_data_backup:/
#    docker commit -a "" -m "pg_data_backup" pg_data_backup ${DockerAddImage}:${week_day}
#    docker push ${DockerAddImage}:${week_day}
#fi

### 容器打包
#docker commit -a "" -m "pg_data_backup" pg_data_backup ${DockerImage}:latest
#docker commit -a "" -m "pg_data_backup" pg_data_backup ${DockerImage}:${week_day}
#
## docker push image
#docker push ${DockerImage}:latest
#docker push ${DockerImage}:${file_date}

# 全量备份所有文件
rm -rf ${bak_file}/*full*
tar -zcvf ${bak_file}/pg_data_backup_${file_date}_full.tar.gz ${file_ssd} ${file_swdb} ${file_var_main} ${file_etc_main}
docker cp ${bak_file}/pg_data_backup_${file_date}_full.tar.gz pg_data_backup:/
docker commit -a "" -m "pg_data_backup" pg_data_backup ${DockerAllImage}:latest
docker push ${DockerAllImage}:latest

# 删除本地镜像
ImageNum=$(docker images ${DockerImage} | wc -l)
if [ ${ImageNum} -gt 1 ]; then
    docker rmi -f $(docker images ${DockerImage} -q)
else
    echo 'Error Build Docker Image'
    exit 1
fi

# 关闭容器
docker stop pg_data_backup
# 删除容器
docker rm pg_data_backup