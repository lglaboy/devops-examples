FROM prom/pushgateway:v1.5.1 AS pushgateway

FROM public.ecr.aws/docker/library/alpine:3.20.2
LABEL maintainer="Authors <developers@xxxxxxxx.cn>"
LABEL description="启动crond和pushgateway服务,每天自动清理pushgateway 数据,默认开启 --web.enable-admin-api"

# 从另一个镜像中复制文件
COPY --from=pushgateway /bin/pushgateway /bin/pushgateway
COPY clean_data.sh /etc/periodic/daily
COPY start.sh /start

EXPOSE 9091
RUN mkdir -p /pushgateway && chown nobody:nobody /pushgateway \
    && chmod +x /etc/periodic/daily/clean_data.sh \
    && chmod +x /start \
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
    && apk add --no-cache curl
WORKDIR /pushgateway

USER 65534

ENTRYPOINT [ "/start", "--web.enable-admin-api" ]