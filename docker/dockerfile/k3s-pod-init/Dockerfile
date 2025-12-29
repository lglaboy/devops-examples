FROM alpine:3.19.1

ADD start_latest.sh /start.sh

# install curl bash 
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && apk add curl bash --no-cache \
    && chmod 755 /start.sh

ENTRYPOINT ["/start.sh"]