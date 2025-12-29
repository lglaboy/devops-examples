#!/bin/bash

# 与crontab结合，每分钟同步一次，实时同步数据

# SOURCE_DIR="/path/to/source_dir"
DEST_USER="swift"
DEST_HOST="local-backup-host"
DEST_DIR="/swiftData/$(hostname)"

# 同步nginx配置
if [ -d /etc/nginx/conf.d ];then
    rsync -az --delete /etc/nginx/conf.d "$DEST_USER@$DEST_HOST:$DEST_DIR"
fi

# 同步nacos配置
if [ -d /opt/nacos-mysql ];then
    rsync -az --delete /opt/nacos-mysql "$DEST_USER@$DEST_HOST:$DEST_DIR"
fi