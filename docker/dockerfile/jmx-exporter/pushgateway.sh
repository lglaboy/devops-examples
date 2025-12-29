#!/bin/sh
docker_ip=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/')
pushgateway_url=${pushgateway_url:-"http://pushgateway-prod:12588"}
jmx_port=${JMX_PORT:-12345}

echo 'crond start' > /tmp/cron_start_log

# k8s env
if [ -n "${POD_NAMESPACE}" ]; then
    # app_name=${POD_NAME}
    NAMESPACE=${POD_NAMESPACE}
    docker_ip=${POD_IP}
else
    NAMESPACE='default'
fi

while true
do
  curl "0.0.0.0:$jmx_port/metrics" -s | curl --data-binary @- "${pushgateway_url}/metrics/job/jmx/env/${env}/app/${app_name}/namespace/${NAMESPACE}/docker_ip/${docker_ip}"
  sleep 15
done