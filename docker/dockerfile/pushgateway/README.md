# 说明

1.通过start.sh 运行crond和pushgateway，从而使 docker run的时候，最后能跟cmd参数，自动添加到 Entrypoint 指定的命令后

```
#!/usr/bin/env sh

# 启动 crond 并将其放在后台运行
/usr/sbin/crond

# 启动 pushgateway 并传递所有参数
exec /bin/pushgateway "$@"

```


因为直接通过entpypoint指定 crond && /bin/pushgateway,实际就是 /bin/sh -c "crond && /bin/pushgateway",在docker run的时候最后跟的参数 如: --web.enable-admin-api ,不生效，不会添加到 /bin/pushgateway的后面，变成 /bin/pushgateway --web.enable-admin-api 执行

```
# ENTRYPOINT crond && /bin/pushgateway
# ENTRYPOINT ["/bin/sh", "-c", "crond && /bin/pushgateway"]
```

2.由于目的是每天自动删除所有数据，删除所有数据的接口需要添加 --web.enable-admin-api 参数才能启用，所以这里直接添加到了内部

```
ENTRYPOINT [ "/start", "--web.enable-admin-api" ]
```



# build

```bash
docker build -t my-pushgateway:1 .
```

# 上传华为云

```
docker tag my-pushgateway:1 swr.cn-east-2.myhuaweicloud.com/common-server/pushgateway:2

# 已确认华为云无pushgateway:2 镜像，不会覆盖掉
docker push swr.cn-east-2.myhuaweicloud.com/common-server/pushgateway:2
```

# run

```shell
docker run -itd --cap-add=SYS_PTRACE \
--name pushgateway \
-h $(hostname) \
-u root \
-v /etc/hosts:/etc/hosts \
-v /usr/share/zoneinfo/Asia/Shanghai:/etc/localtime \
--cpus 1 -m 1G \
--cap-add=SYS_PTRACE \
--restart=unless-stopped \
--log-opt max-size=512m \
--log-opt max-file=3 \
-p 12588:9091 \
swr.cn-east-2.myhuaweicloud.com/common-server/pushgateway:2
```

环境变量：

-e PUSHGATEWAY_PORT=9091 默认9091,如果通过--web.listen-address=:9091 修改了默认端口，则应该指定环境变量，用于自动清理脚本

如果内部端口调整为8080，则需要
```bash
docker run -itd --cap-add=SYS_PTRACE \
--name pushgateway \
-h $(hostname) \
-u root \
-v /etc/hosts:/etc/hosts \
-v /usr/share/zoneinfo/Asia/Shanghai:/etc/localtime \
--cpus 1 -m 1G \
--cap-add=SYS_PTRACE \
--restart=unless-stopped \
--log-opt max-size=512m \
--log-opt max-file=3 \
-p 12588:8080 \
-e PUSHGATEWAY_PORT=8080 \
swr.cn-east-2.myhuaweicloud.com/common-server/pushgateway:2 \
--web.listen-address=:8080
```