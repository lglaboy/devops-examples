#!/usr/bin/env sh
PUSHGATEWAY_PORT=${PUSHGATEWAY_PORT:-9091}
LOG_FILE="/tmp/clean_data.log"

echo "$(date +"%Y-%m-%d %H:%M:%S") clean data" >> $LOG_FILE
curl -X PUT "http://0.0.0.0:$PUSHGATEWAY_PORT/api/v1/admin/wipe" -s >> $LOG_FILE
