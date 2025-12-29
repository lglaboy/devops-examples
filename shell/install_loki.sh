#!/bin/bash
# Date: 2022-8-31 09:15
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: install loki ,redis,cassandra,minio
# Version: v1.0

# 清理环境
# docker rm -f $(docker ps |grep logging|awk '{print $NF}') && sudo rm -rf /opt/loki && docker network rm  logging

create_docker_network() {
    docker network create logging --driver bridge
}

install_cassandra() {
    mkdir -p /opt/loki/cassandra/cassandra-server
    docker run -d --name logging-cassandra-server \
        --user root \
        --network logging \
        --network-alias cassandra-server \
        --cpus 1 -m 4G \
        --restart=unless-stopped \
        --log-opt max-size=512m \
        --log-opt max-file=3 \
        -v /etc/hosts:/etc/hosts \
        -v /etc/localtime:/etc/localtime \
        -p 9042:9042 \
        -v /opt/loki/cassandra/cassandra-server:/var/lib/cassandra \
        -e TZ=Asia/Shanghai \
        -e CASSANDRA_PASSWORD_SEEDER=yes \
        -e CASSANDRA_USER=cassandra \
        -e CASSANDRA_PASSWORD=cassandra \
        -e MAX_HEAP_SIZE=2G \
        -e HEAP_NEWSIZE=200M \
        swr.cn-east-2.myhuaweicloud.com/common-server/cassandra:4.0.6
}

install_redis() {
    mkdir /opt/loki/redis/data/ -p && mkdir /opt/loki/redis/logs -p && sudo chmod 777 /opt/loki/redis/data/ && chmod 777 /opt/loki/redis/logs
    cat >>/opt/loki/redis/redis.conf <<EOF
daemonize no
pidfile /tmp/redis.pid
port 6379
bind 0.0.0.0
timeout 300
loglevel warning
logfile /opt/redis/logs/redis-server.log
syslog-enabled no
databases 16
save 900 1
save 300 10
save 60 10000
rdbcompression yes
dir /opt/redis/data
dbfilename dump.rdb
requirepass 123456
appendonly no
appendfilename appendonly.aof
no-appendfsync-on-rewrite no
activerehashing yes
maxclients 4096
# 限制内存
maxmemory 2048000000
EOF
    docker run -itd --name logging-redis -h localhost \
        --network logging \
        --network-alias logging-redis \
        --restart=unless-stopped \
        --cpus 1 -m 4G \
        --memory-swappiness=0 \
        -p 6379:6379 \
        -v /etc/hosts:/etc/hosts \
        -v /etc/localtime:/etc/localtime \
        -v /opt/loki/redis/redis.conf:/etc/redis/redis.conf \
        -v /opt/loki/redis/data:/opt/redis/data \
        -v /opt/loki/redis/logs:/opt/redis/logs \
        --cap-add=SYS_PTRACE \
        --log-opt max-size=512m --log-opt max-file=3 \
        swr.cn-east-2.myhuaweicloud.com/common-server/redis:6.0.14 /etc/redis/redis.conf
}

install_minio() {
    mkdir -p /opt/loki/minio/data
    docker run -itd \
        --name logging-minio \
        --network logging \
        --network-alias logging-minio \
        --cpus 1 -m 4G \
        --restart=unless-stopped \
        --log-opt max-size=512m \
        --log-opt max-file=3 \
        -v /etc/hosts:/etc/hosts \
        -v /etc/localtime:/etc/localtime \
        -p 9000:9000 \
        -p 9001:9001 \
        -v /opt/loki/minio/data:/data \
        -e "MINIO_ROOT_USER=1KJ6CCZ7JFXRJ6ALLXEL" \
        -e "MINIO_ROOT_PASSWORD=xYcAYnJMWxVvI8XRy37H1whLsNmPdjoINMZyp+LK" \
        swr.cn-east-2.myhuaweicloud.com/common-server/minio:RELEASE.2022-08-22T23-53-06Z.fips server /data --console-address ":9001"

    # 启动mc容器，创建桶
    docker run -itd \
        --name logging-minio-mc \
        --network logging \
        --network-alias logging-minio-mc \
        --cpus 1 -m 1G \
        --restart=unless-stopped \
        --log-opt max-size=512m \
        --log-opt max-file=3 \
        -v /etc/hosts:/etc/hosts \
        -v /etc/localtime:/etc/localtime \
        --entrypoint=/bin/sh \
        swr.cn-east-2.myhuaweicloud.com/common-server/minio-mc:RELEASE.2022-08-28T20-08-11Z

    # 创建连接信息
    docker exec logging-minio-mc mc alias set myminio http://logging-minio:9000 1KJ6CCZ7JFXRJ6ALLXEL xYcAYnJMWxVvI8XRy37H1whLsNmPdjoINMZyp+LK

    # 创建桶
    docker exec logging-minio-mc mc mb myminio/loki-data
}

install_loki() {
    mkdir -p /opt/loki/loki/data && chmod 777 /opt/loki/loki/data
    cat >/opt/loki/loki/loki-config.yaml <<EOF
---
target: all, table-manager
auth_enabled: false
server:
  http_listen_port: 3100
  # http服务器读取超时
  http_server_read_timeout: 600s
  # http服务器写入超时
  http_server_write_timeout: 600s

memberlist:
  # 要加入集群的成员
  #join_members:
  #  - logging-loki:7946

query_scheduler:
  # 最大未完成请求数
  max_outstanding_requests_per_tenant: 2048

ingester:
  # 块的大小(以字节bytes为单位),262144
  chunk_block_size: 262144
  # 用于块的压缩算法(gzip,lz4,snappy)
  chunk_encoding: snappy
  # 在没有更新的情况下，块在内存中保留最长时间
  chunk_idle_period: 15m
  # 块刷新后，在内存中保留时间
  chunk_retain_period: 6m
  wal:
    # 允许写入wal
    enabled: true
    # 存储和恢复wal数据的目录,默认/loki/wal
    dir: /data/wal
    # 是否在关机时将块刷新到长期存储
    flush_on_shutdown: true
    # wal可以使用的最大内存大小
    replay_memory_ceiling: 1GB

chunk_store_config:
    # 用于存储块的缓存配置
    chunk_cache_config:
        redis:
            endpoint: logging-redis:6379
            expiration: 1h
            password: 123456
    # 重复数据消除写入的缓存配置
    write_dedupe_cache_config:
        redis:
            endpoint: logging-redis:6379
            expiration: 1h
            password: 123456
    # 限制可查询的回溯数据的时间
    max_look_back_period: 0

schema_config:
  configs:
    - from: 2021-08-01
      store: cassandra
      object_store: s3
      schema: v11
      index:
        prefix: cassandra_table
        period: 168h

# 配置多个可能使用索引和块的存储,供schema_config中选择
storage_config:
    cassandra:
        username: cassandra
        password: cassandra
        addresses: cassandra-server
        auth: true
        keyspace: loki
        consistency: LOCAL_ONE
        # 在cassandra中使用的复制因子
        replication_factor: 1
    aws:
        s3: s3://key123456:password123456@minio.:9000/loki
        s3forcepathstyle: true
    #如何构建索引查询缓存的配置
    index_queries_cache_config:
        redis:
            endpoint: logging-redis:6379
            expiration: 1h
            password: 123456
# 表管理器
table_manager:
  retention_deletes_enabled: true      # 日志保留周期开关，用于表保留删除
  retention_period: 336h       # 日志保留周期，保留期必须是索引/块的倍数,即schema_config.configs.index.period

query_range:
    align_queries_with_step: true
    # 缓存查询结果
    cache_results: true
    # 单个请求的最大重试次数
    max_retries: 5
    results_cache:
        cache:
            redis:
                endpoint: logging-redis:6379
                # key 在redis中停留的时间
                expiration: 1h
                password: 123456
limits_config:
  # 按间隔拆分查询并并行执行，任何小于零的值都将禁用它。
  split_queries_by_interval: 6h


common:
  path_prefix: /loki
  replication_factor: 1
  storage:
    s3:
      endpoint: logging-minio:9000
      insecure: true
      bucketnames: loki-data
      access_key_id: loki
      secret_access_key: supersecret
      s3forcepathstyle: true
  ring:
    kvstore:
      store: memberlist
#ruler:
#  storage:
#    s3:
#      bucketnames: loki-ruler

EOF

    docker run -itd \
        --name logging-loki \
        --network logging \
        --network-alias logging-loki \
        --cpus 1 -m 2G \
        --restart=unless-stopped \
        --log-opt max-size=512m --log-opt max-file=3 \
        -v /etc/hosts:/etc/hosts \
        -v /etc/localtime:/etc/localtime \
        -v /opt/loki/loki/loki-config.yaml:/etc/loki/loki-config.yaml \
        -v /opt/loki/loki/data:/data \
        -p 3100:3100 \
        swr.cn-east-2.myhuaweicloud.com/common-server/loki:2.6.1 -config.file=/etc/loki/loki-config.yaml -target=all,table-manager
}

if ! create_docker_network; then
    echo "创建docker网络失败"
fi

if ! install_cassandra; then
    echo "安装cassandra失败"
fi

if ! install_redis; then
    echo "安装redis失败"
fi

if ! install_minio; then
    echo "安装minio失败"
fi
sleep 60
if ! install_loki; then
    echo "安装loki失败"
fi
