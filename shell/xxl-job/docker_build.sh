#!/bin/bash

# 进入build目录
xxl_job_image_build_tmp=$(mktemp -d /tmp/xxl-job-build-XXXXXXXX)
xxl_job_base_container_name=$(mktemp -u xxl-job-XXXXXX)
xxl_job_old_image_name="swr.cn-east-2.myhuaweicloud.com/common-server/xxljob:1-jdk8"
xxl_job_new_image_name="swr.cn-east-2.myhuaweicloud.com/common-server/xxljob:1.4-test"

cd "$xxl_job_image_build_tmp" || exit 1

# 启动容器，copy app.jar 到本地
docker run -itd --name "$xxl_job_base_container_name" --entrypoint /bin/bash $xxl_job_old_image_name

docker cp "$xxl_job_base_container_name":/app.jar app.jar

docker rm -f "$xxl_job_base_container_name"

# 创建 logback.xml 文件
cat > logback.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration debug="false" scan="true" scanPeriod="1 seconds">

    <contextName>logback</contextName>
    <property name="log.path" value="/dev/null"/>

    <appender name="console" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{HH:mm:ss.SSS} %contextName [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>

    <appender name="file" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${log.path}</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${log.path}.%d{yyyy-MM-dd}.zip</fileNamePattern>
        </rollingPolicy>
        <encoder>
            <pattern>%date %level [%thread] %logger{36} [%file : %line] %msg%n
            </pattern>
        </encoder>
    </appender>

    <root level="info">
        <appender-ref ref="console"/>
        <appender-ref ref="file"/>
    </root>

</configuration>
EOF

# 创建 Dockerfile
cat > Dockerfile <<"EOF"
FROM openjdk:8-jre-slim
MAINTAINER xxxxxxxx

ENV JAVA_OPTS="-Dlogging.config=/logback.xml"
ENV PARAMS=""

ENV TZ=PRC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

COPY app.jar logback.xml /

ENTRYPOINT ["sh","-c","java -jar $JAVA_OPTS /app.jar $PARAMS"]
EOF

# 编译

docker build -t $xxl_job_new_image_name .

# 清理tmp
rm -rf "$xxl_job_image_build_tmp"