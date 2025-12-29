#!/bin/sh

# 添加到 /etc/cron.daily 中,命名为 backup_data，每天定时执行

BACKUP_DIR="/var/backups/xxxxxxxx"

# 获取当前日期和时间，格式为 YYYYMMDD_HHMMSS
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 检查目录是否存在，不存在创建
test -d $BACKUP_DIR || mkdir -p $BACKUP_DIR


# 备份nginx配置
if [ -d /etc/nginx/conf.d ];then
    cd $BACKUP_DIR || exit 0
    tar -czf "$BACKUP_DIR/nginx_conf_backup_$TIMESTAMP.tar.gz" -C /etc/nginx/conf.d .
fi

# 备份prometheus配置
if [ -d /opt/prometheus ];then
    cd $BACKUP_DIR || exit 0
    tar -czf "$BACKUP_DIR/prometheus_conf_backup_$TIMESTAMP.tar.gz" -C /opt/prometheus conf prometheus.yml
fi

# 备份nacos配置
if [ -d /opt/nacos ];then
    cd $BACKUP_DIR || exit 0
    curl -X GET "http://local-nacos:8848/nacos/v1/cs/configs?export=true&group=&tenant=&appName=&ids=&dataId=" -o "nacos_config_$TIMESTAMP.zip" -s
fi

# 备份rocketmq配置
if [ -f /opt/rocketmq/store/config/topics.json ];then
    cd $BACKUP_DIR || exit 0
    cp -p /opt/rocketmq/store/config/topics.json "topics_$TIMESTAMP.json"
fi

# 备份xxljob配置
if [ -d /opt/xxljob-mysql ];then
    cd $BACKUP_DIR || exit 0
    docker exec -i xxljob-mysql /bin/sh -c "mysqldump -uroot -h 127.0.0.1 xxl_job xxl_job_group xxl_job_info xxl_job_lock xxl_job_logglue xxl_job_registry > /tmp/xxl_job_prod_nolog.sql"
    docker cp xxljob-mysql:/tmp/xxl_job_prod_nolog.sql "xxl_job_$TIMESTAMP.sql"
fi

# 备份审计日志
if [ -d /var/log/audit ];then
    cd $BACKUP_DIR || exit 0
    tar -czf "$BACKUP_DIR/audit_log_$TIMESTAMP.tar.gz" -C /var/log audit
fi

# 备份nginx日志
if [ -d /var/log/nginx ];then
    cd $BACKUP_DIR || exit 0
    tar -czf "$BACKUP_DIR/nginx_log_$TIMESTAMP.tar.gz" -C /var/log/nginx ./*.log.1
fi
