ARG RESTY_IMAGE_BASE="ubuntu"
ARG RESTY_IMAGE_TAG="xenial"

FROM ${RESTY_IMAGE_BASE}:${RESTY_IMAGE_TAG}

LABEL maintainer="lgl <lglaboy>"

ARG SWIFTWAF_URL_BASE="http://192.168.1.51/packages"
ARG SWIFTWAF_VERSION="15"
# ARG SWIFTWAF_URL_BASE="http://static.xxxxxxxx.cn:9090/packages"




# TODO: 替换清华源
# mirrors.tuna.tsinghua.edu.cn
# /etc/apt/sources.list
# security.ubuntu.com
# archive.ubuntu.com
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        curl \
        wget \
        net-tools \
        netcat \
        telnet \
        vim \
        ${RESTY_ADD_PACKAGE_BUILDDEPS} \
        ${RESTY_ADD_PACKAGE_RUNDEPS} \
    && cd /tmp \
    && curl -fSL "${SWIFTWAF_URL_BASE}/swiftwaf-${SWIFTWAF_VERSION}.tar.gz" -o swiftwaf-${SWIFTWAF_VERSION}.tar.gz \
    && tar xzf swiftwaf-${SWIFTWAF_VERSION}.tar.gz \
    && cd swiftwaf-${SWIFTWAF_VERSION}/nginx-debs \
    && dpkg -i *.deb \
    && cp -r /tmp/swiftwaf-${SWIFTWAF_VERSION}/nginx_conf/* /etc/nginx/ \
    && mv /etc/nginx/nginxtools /usr/local/bin/nginxtools \
    && mkdir -p /var/cache/nginx/client_temp \
    && chown www-data.www-data /var/cache/nginx/client_temp /etc/nginx/ssl \
    && cp -pr /etc/nginx/nginx/lib/libjemalloc* /usr/local/lib/ \
    && cp -pr /etc/nginx/nginx/lib/libmaxminddb* /usr/lib/x86_64-linux-gnu/ \
    && mkdir -p /var/cache/nginx/proxy_cache_temp /var/cache/nginx/client_temp /var/cache/nginx/proxy_temp /var/cache/nginx/fastcgi_temp /var/cache/nginx/uwsgi_temp /var/cache/nginx/scgi_temp \
    && chown -R www-data.www-data /var/cache/nginx \
    && mv /usr/sbin/nginx /usr/sbin/nginx.bak \
    && mv /etc/nginx/nginx/bin/nginx /usr/sbin/nginx \
    && /sbin/ldconfig \
    && ldd /usr/sbin/nginx \
    && cd /tmp \
    && rm -rf \
        swiftwaf-${SWIFTWAF_VERSION}.tar.gz swiftwaf-${SWIFTWAF_VERSION} \
    && DEBIAN_FRONTEND=noninteractive apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 80

# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
# See https://github.com/openresty/docker-openresty/blob/master/README.md#tips--pitfalls
# 该SIGQUIT信号将被发送到 nginx 以停止该容器，使其有机会正常停止（即完成处理活动连接）。Docker 默认值为SIGTERM，它会立即终止活动连接。
STOPSIGNAL SIGQUIT

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]