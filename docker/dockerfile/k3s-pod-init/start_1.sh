#! /bin/sh

function check_nacos(){
  nacos_result=`curl -X POST "http://nacos-server-headless:8848/nacos/v1/cs/configs?dataId=nacos.cfg.dataId&group=test&content=HelloWorld"`
  until [ ${nacos_result} == true ]; do
    nacos_result=`curl -X POST "http://nacos-server-headless:8848/nacos/v1/cs/configs?dataId=nacos.cfg.dataId&group=test&content=HelloWorld"`
    sleep 2
    echo -e '\033[31m nacos-server is not ready \033[0m'
  done
  echo -e '\033[32m nacos-server is ready \033[0m'
}


function check_eureka(){
  eureka_result=`curl http://eureka-0:10100/actuator/health`
  eureka_result=`echo ${eureka_result} | awk -F ':|"' '{print $(NF-1)}' | tail -1`
  until [ ${eureka_result} == UP ]; do
    eureka_result=`curl http://eureka-0:10100/actuator/health`
    eureka_result=`echo ${eureka_result} | awk -F ':|"' '{print $(NF-1)}' | tail -1`
    sleep 2
    echo -e '\033[31m eureka is not ready \033[0m'
  done
  echo -e '\033[32m eureka is ready \033[0m'
}

server_name=`echo $POD_NAME | awk -F '-' '{print $2}'`

if [[ "${server_name}" == p2o || "${server_name}" == o2p ]]; then
  exit 0
  echo -e '\033[32m Initing is finished \033[0m'
else
  check_eureka
fi

check_nacos