#!/bin/bash
# Date: 2023-07-10 17:28
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: Install Safe Agent,Turn on TLS encryption。
# Version: v1.0

# frpc调整为safe_agent安装

# 注意：通过远程端口连接，执行脚本，请设置后台运行，否则可能会导致失联
# wget http://static.company.xxxxxxxx.cn:9090/shell/safe_agent_install.sh
# nohup sudo bash safe_agent_install.sh XXYY-TEST-001 xxyy-test 26927 &>/dev/null &

# clean safe_agent env, M:Manual
# sudo systemctl stop safe_agent.service && sudo systemctl disable safe_agent.service && sudo rm -rf /lib/systemd/system/safe_agent* && sudo systemctl daemon-reload && sudo mv /opt/safe_agent /opt/safe_agent_bak_M_$(date +%Y_%m_%d_%H:%M:%S)

HostName=${1}
EnvName=${2}
REMOTEPORT=${3}
SERVERADDR=xxx.xxx.xxx.xxx
SERVERPORD=6000
DefaultToken=customtoken
SAFE_AGENT_DOWNLOAD_URL=http://static.company.xxxxxxxx.cn:9090/packages/safe_agent_0.37.1_linux_amd64.tar.gz

PID=$(pidof safe_agent)
Date=$(date +%Y_%m_%d_%H:%M:%S)
BakDir=/opt/safe_agent_bak
BakDirLatest=/opt/safe_agent_bak_${Date}
FrpBakDir=/opt/frp_bak
FrpBakDirLatest=/opt/frp_bak_${Date}

UpdateConfig() {
  if [ "${REMOTEPORT}" ]; then
    sed -i "/^#remote_port.*=/cremote_port = ${REMOTEPORT}" "${1}"
  fi
  if [ ${SERVERADDR} ]; then
    sed -i "/^server_addr.*=/cserver_addr = ${SERVERADDR}" "${1}"
  fi
  if [ ${SERVERPORD} ]; then
    sed -i "/^server_port.*=/cserver_port = ${SERVERPORD}" "${1}"
  fi
  if [ ${DefaultToken} ]; then
    sed -i "/^token.*=/ctoken = ${DefaultToken}" "${1}"
  fi
  if [ "${HostName}" ]; then
    sed -i 's/##HOSTNAME##/'"${HostName}"'/g' "${1}"
  fi
  if [ "${EnvName}" ]; then
    sed -i 's/##ENV_NAME##-prod/'"${EnvName}"'/g' "${1}"
  fi
}

CheckSafeAgentInstall() {
  local safe_agent_status
  safe_agent_status=$(systemctl status safe_agent.service | grep -c disabled)
  if [ "${safe_agent_status}" -eq 0 ]; then
    echo "Tips: systemctl enable safe_agent successfully"
  else
    echo "Tips: systemctl enable safe_agent failure!"
    exit 1
  fi

  if [ -f /opt/safe_agent/config.conf ] && [ -f /usr/local/bin//safe_agent ] && [ -f /lib/systemd/system/safe_agent.service ]; then
    echo "Tips: safe_agent installed successfully"
  else
    echo "Error: safe_agent not installed successfully"
    exit 1
  fi
}

InstallSafeAgent() {
  cd /tmp && sudo tar --no-same-owner -xzvf safe_agent_0.37.1_linux_amd64.tar.gz && sudo mv safe_agent_0.37.1_linux_amd64 /opt/safe_agent && sudo chmod a+r /opt/safe_agent/tls -R
  UpdateConfig /opt/safe_agent/config.conf
  sudo mv /opt/safe_agent/systemd/* /lib/systemd/system/ && sudo rm -rf /opt/safe_agent/systemd
  sudo mv /opt/safe_agent/safe_agent /usr/local/bin/
  sudo systemctl daemon-reload && sudo systemctl start safe_agent.service && sudo systemctl enable safe_agent.service
  CheckSafeAgentInstall
}

UpdateSafeAgent() {
  local tls_flag
  if [ -d ${BakDir} ]; then
    BakDir=${BakDirLatest}
  fi
  if [ -d /opt/safe_agent ]; then
    mv /opt/safe_agent "${BakDir}"
    mkdir "${BakDir}/systemd"
  fi

  if [ -f /etc/systemd/system/safe_agent.service ]; then
    cp /etc/systemd/system/safe_agent* "${BakDir}/systemd/"
  elif [ -f /lib/systemd/system/safe_agent.service ]; then
    cp /lib/systemd/system/safe_agent* "${BakDir}/systemd/"
  fi
  if [ "$(dpkg -l | grep -c safe_agent)" -eq 1 ]; then
    sudo systemctl stop safe_agent.service
    sudo systemctl disable safe_agent.service
    sudo apt remove safe_agent -y
  elif [ -f /lib/systemd/system/safe_agent.service ]; then
    sudo systemctl stop safe_agent.service
    sudo systemctl disable safe_agent.service
    sudo rm -f /lib/systemd/system/safe_agent*
    sudo systemctl daemon-reload
  fi
  cd /tmp || exit
  sudo tar --no-same-owner -xzvf safe_agent_0.37.1_linux_amd64.tar.gz
  sudo mv safe_agent_0.37.1_linux_amd64 /opt/safe_agent
  sudo chmod a+r /opt/safe_agent/tls -R
  UpdateConfig /opt/safe_agent/config.conf

  if [ -f "${BakDir}/config.conf" ]; then
    sudo mv /opt/safe_agent/config.conf /opt/safe_agent/config_new.ini
    sudo cp "${BakDir}/config.conf" /opt/safe_agent/config.conf
  fi
  sed -i "s/.aliyun.xxxxxxxx.cn/.xxxx.xxxxxxxx.cn/g" /opt/safe_agent/config.conf
  if [ ${SERVERADDR} ]; then
    sed -i "/^server_addr.*=/cserver_addr = ${SERVERADDR}" /opt/safe_agent/config.conf
  fi
  if [ ${SERVERPORD} ]; then
    sed -i "/^server_port.*=/cserver_port = ${SERVERPORD}" /opt/safe_agent/config.conf
  fi
  if [ ${DefaultToken} ]; then
    sed -i "/^token.*=/ctoken = ${DefaultToken}" /opt/safe_agent/config.conf
  fi
  tls_flag=$(grep /opt/safe_agent/tls /opt/safe_agent/config.conf | grep -c -v ^\#)
  if [ ! "${tls_flag}" -ge 3 ]; then
    sed -i '/\[common\]/a\\ \n# 开启tls加密\ntls_enable = true\ntls_cert_file = /opt/safe_agent/tls/client.crt\ntls_key_file = /opt/safe_agent/tls/client.key\ntls_trusted_ca_file = /opt/safe_agent/tls/ca.crt\n' /opt/safe_agent/config.conf
  fi

  sudo mv /opt/safe_agent/systemd/* /lib/systemd/system/
  sudo rm -rf /opt/safe_agent/systemd
  sudo systemctl daemon-reload
  sudo systemctl start safe_agent.service
  sudo systemctl enable safe_agent.service

  CheckSafeAgentInstall
}

UpdateFrpcToSafeAgent() {
  # 配置safe_agent
  cd /tmp || exit
  sudo tar --no-same-owner -xzvf safe_agent_0.37.1_linux_amd64.tar.gz
  sudo mv safe_agent_0.37.1_linux_amd64 /opt/safe_agent
  sudo chmod a+r /opt/safe_agent/tls -R
  mv /opt/safe_agent/config.conf /opt/safe_agent/config_template.conf

  # 复制原先配置文件
  cp -a /etc/frp/frpc.ini /opt/safe_agent/config.conf

  sudo mv /opt/safe_agent/systemd/* /lib/systemd/system/
  sudo rm -rf /opt/safe_agent/systemd
  sudo mv /opt/safe_agent/safe_agent /usr/local/bin/

  # 卸载frpc
  if [ -d ${FrpBakDir} ]; then
    FrpBakDir=${FrpBakDirLatest}
  fi

  if [ -d /etc/frp ]; then
    mv /etc/frp "${FrpBakDir}"
    mkdir "${FrpBakDir}/systemd"
  fi

  cp /lib/systemd/system/frpc* "${FrpBakDir}/systemd/"


  if [ ! -f /opt/safe_agent/config.conf ];then
    echo "无配置文件：/opt/safe_agent/config.conf"
    exit 1
  fi

  # 关闭frpc
  sudo systemctl stop frpc.service
  sudo systemctl disable frpc.service
  sudo rm -f /lib/systemd/system/frpc*

  sudo systemctl daemon-reload

  # 启动 safe_agent
  sudo systemctl start safe_agent.service
  sudo systemctl enable safe_agent.service
  CheckSafeAgentInstall
}

DownloadSafeAgent() {
  cd /tmp && wget -N ${SAFE_AGENT_DOWNLOAD_URL}
  if [ -f /tmp/safe_agent_0.37.1_linux_amd64.tar.gz ]; then
    echo "Tips: Successfully downloaded safe_agent_0.37.1_linux_amd64.tar.gz to /tmp/safe_agent_0.37.1_linux_amd64.tar.gz"
  else
    echo "Download safe_agent_0.37.1_linux_amd64.tar.gz failed!"
    exit 1
  fi
}



if [ "$(whoami)" != "root" ]; then
  echo "Run this shell script with root"
  exit 1
fi

if [ $# == 3 ]; then
  :
else
  echo "vars not enough"
  echo "Usage:"
  echo "${0} HostName EnvName REMOTEPORT"
  echo "${0} XXYY-REMOTETEST-001 xxyy-test 16927"
  exit 1
fi

if [ -n "$REMOTEPORT" ] && [ ! "$REMOTEPORT" = "${REMOTEPORT//[^0-9]/}" ]; then
  echo "Error: Input parameter error."
  echo "Tips:${0} HostName EnvName REMOTEPORT"
  echo "${0} XXYY-REMOTETEST-001 xxyy-test 16927"
  exit 1
fi


if [ -d /etc/frp ] && [ -d /etc/frp/frpc_tls ] &&  [ -f /etc/frp/frpc.ini ] &&  [ -f /etc/frp/frpc ] && [ -f /lib/systemd/system/frpc.service ] ; then
  DownloadSafeAgent
  UpdateFrpcToSafeAgent &
  # 判断是否运行 [ -z $(pidof frpc) ]
elif [ -z "${PID}" ] && [ ! -d /opt/safe_agent ] && [ ! -f /lib/systemd/system/safe_agent.service ] && [ ! -f /etc/systemd/system/safe_agent.service ]; then
  # 未安装旧版 safe_agent ，环境干净，直接安装
  DownloadSafeAgent
  InstallSafeAgent &
else
  # 已安装旧版 safe_agent ，备份配置，对服务进行升级
  # DownloadSafeAgent
  # UpdateSafeAgent &
  echo "safe_agent 进程存在 | /opt/safe_agent 目录存在 | /lib/systemd/system/safe_agent.service 文件存在,无法安装 safe_agent."
  exit 1
fi
