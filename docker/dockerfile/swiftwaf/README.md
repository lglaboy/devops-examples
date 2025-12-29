# 编译命令
```
docker build -t swiftwaf:15 .
```


# 部署命令

```
# 配置环境
mkdir /opt/swiftwaf/logs -p

docker run -itd --name swiftwaf-test swiftwaf:15 /bin/bash

docker cp swiftwaf-test:/etc/nginx/nginx.conf /opt/swiftwaf/
docker cp swiftwaf-test:/etc/nginx/conf.d /opt/swiftwaf/

docker rm -f swiftwaf-test



# 启动容器
docker run -itd --name swiftwaf \
-p 10080:80 \
--cpus 2 -m 4G \
--restart=unless-stopped \
--memory-swappiness=0 \
--log-opt max-size=512m \
--log-opt max-file=3 \
-v /etc/hosts:/etc/hosts \
-v /etc/localtime:/etc/localtime \
-v /opt/swiftwaf/nginx.conf:/etc/nginx/nginx.conf \
-v /opt/swiftwaf/conf.d:/etc/nginx/conf.d \
-v /opt/swiftwaf/logs:/var/log/nginx \
swr.cn-east-2.myhuaweicloud.com/common-server/swiftwaf:15
```