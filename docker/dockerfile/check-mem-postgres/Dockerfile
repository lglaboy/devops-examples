FROM alpine:3.17.0
# 维护者信息
LABEL authors="lglaboy" \
      description="Automatically detect host memory and kill postgresql idle process"

# 设置时区，需要安装tzdata
ENV TZ=Asia/Shanghai

# apk add 提速
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && apk add postgresql-client tzdata --no-cache
WORKDIR /app
COPY check_mem_postgres.sh /app/start

HEALTHCHECK --interval=5s --timeout=3s --start-period=5s \
CMD pgrep -f start || exit 1

CMD /app/start
