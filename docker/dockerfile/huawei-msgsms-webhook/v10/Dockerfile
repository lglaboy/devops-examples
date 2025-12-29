# 支持grafana短信通知服务封装，grafana升级后告警消息结构改变，适配服务重新封装
FROM alpine:3.18.3
# 维护者信息
LABEL authors="lglaboy" \
      description="huawei sms webhook,Compatible with Legacy Alerting&New alerts"

# 设置时区，需要安装tzdata
ENV TZ=Asia/Shanghai

# apk add 提速
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && apk add tzdata --no-cache

WORKDIR /opt/webhook

# app 在宿主机上拥有可执行权限，不需要再次授权
COPY app config.yaml /opt/webhook/

HEALTHCHECK --interval=5s --timeout=3s --start-period=5s \
CMD pgrep app || exit 1

ENTRYPOINT ["/opt/webhook/app"]