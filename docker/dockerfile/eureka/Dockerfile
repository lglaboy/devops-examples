# eureka 封装容器镜像
FROM swr.cn-east-2.myhuaweicloud.com/common-server/alpine-java-8:2.6
COPY app.jar /opt/
WORKDIR /opt/
CMD java -XX:InitialRAMPercentage=75.0 -XX:MaxRAMPercentage=75.0 -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=512m -XX:+UseAdaptiveSizePolicy -XX:+HeapDumpOnOutOfMemoryError -jar /opt/app.jar