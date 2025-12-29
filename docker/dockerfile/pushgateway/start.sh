#!/usr/bin/env sh

# 启动 crond 并将其放在后台运行
/usr/sbin/crond

# 启动 pushgateway 并传递所有参数
exec /bin/pushgateway "$@"
