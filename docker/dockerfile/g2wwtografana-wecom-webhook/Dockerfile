# 封装企业微信告警转发服务
FROM alpine:3.18.3
# 维护者信息
LABEL authors="lglaboy" \
      description="Webhook for sending information to wecom for Grafana's new version of alerts"

# 设置时区，需要安装tzdata
ENV TZ=Asia/Shanghai \
    DOCKER="docker"

# apk add 提速
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && apk add tzdata --no-cache

EXPOSE 2408

WORKDIR /opt/webhook

# app 在宿主机上拥有可执行权限，不需要再次授权
COPY main /opt/webhook/app

HEALTHCHECK --interval=5s --timeout=3s --start-period=5s \
CMD pgrep app || exit 1

ENTRYPOINT ["/opt/webhook/app"]