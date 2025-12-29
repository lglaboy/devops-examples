FROM swr.cn-east-2.myhuaweicloud.com/common-server/alpine-java-8:2.6
COPY app.jar /opt/
WORKDIR /opt/

RUN mkdir /opt/jmx \
    && wget http://192.168.1.51/packages/jmx_exporter/jmx_prometheus_javaagent-1.0.1.jar -P /opt/jmx \
    && wget http://192.168.1.51/packages/jmx_exporter/config.yaml -P /opt/jmx \
    && wget -O /opt/shells/pushgateway.sh http://192.168.1.51/packages/jmx_exporter/pushgateway.sh

ENV JMX_PORT=12345
ENV JAVA_OPTS_1=-javaagent:./jmx/jmx_prometheus_javaagent-1.0.1.jar=$JMX_PORT:./jmx/config.yaml \
    pushgateway_url="http://192.168.1.236:12588"

CMD crond && java -XX:InitialRAMPercentage=75.0 -XX:MaxRAMPercentage=75.0 -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=512m -XX:+UseAdaptiveSizePolicy -XX:+HeapDumpOnOutOfMemoryError -jar /opt/app.jar
# 1.2 更新了字体
# 1.3 增加unrar
# 1.4 添加时区文件解决时区不一致bug
# 1.5 增加systat
# 1.8 增加arthas  skywalking
# 1.9 添加字体库(省肿瘤需求)
# 2.1 pushgateway 添加
# 2.3 skywalking 更新 8.14 java-agent
# 2.4 添加了kill脚本.可以抓取eureka杀死自身eureka注册
# 2.5 添加了api.mch.weixin.qq.com的证书.
# 2.6 更新api.mch.weixin.qq.com的证书
# echo | openssl s_client -connect api.mch.weixin.qq.com:443 -servername api.mch.weixin.qq.com | openssl x509 -outform PEM > myservercert.pem
# keytool -import -alias "myservercert" -file /tmp/myservercert.pem -keystore $JAVA_HOME/jre/lib/security/cacerts -storepass changeit
# 2.6 删除skywalking-agent文件
#