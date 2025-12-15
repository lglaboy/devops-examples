FROM apache/rocketmq:4.9.4

# 使用 sed 修改配置文件
RUN sed -i 's/^calculate_heap_sizes$/#calculate_heap_sizes/' runserver.sh runbroker.sh


# docker build -t swr.cn-east-2.myhuaweicloud.com/common-server/rocketmq:4.9.4-custom  .