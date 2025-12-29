FROM swr.cn-east-2.myhuaweicloud.com/common-server/rocketmq-console:1
# RUN sed '1i deb https://mirrors.aliyun.com/debian-archive/debian/ jessie main non-free contrib' /etc/apt/sources.list \
#     && sed '1i deb-src https://mirrors.aliyun.com/debian-archive/debian/ jessie main non-free contrib' /etc/apt/sources.list \
RUN echo 'deb http://mirrors.aliyun.com/debian-archive/debian/ jessie main non-free contrib' > /etc/apt/sources.list \
    && echo 'deb-src http://mirrors.aliyun.com/debian-archive/debian/ jessie main non-free contrib' >> /etc/apt/sources.list \
    && rm -rf /etc/apt/sources.list.d/jessie-backports.list \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --only-upgrade --force-yes -y wget git git-man \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*