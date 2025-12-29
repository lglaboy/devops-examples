#!/bin/bash
# Date: 2021-9-22 12:00
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: Install frp client,Turn on TLS encryption。
# Version: v1.0

# 注意：通过远程端口连接，执行脚本，请设置后台运行，否则可能会导致失联
# wget http://static.company.xxxxxxxx.cn:9090/shell/frpc_install_new.sh
# nohup sudo bash frpc_install_new.sh XXYY-TEST-001 xxyy-test 26927 &>/dev/null &

# clean frpc_new env, M:Manual
# sudo systemctl stop frpc.service && sudo systemctl disable frpc.service && sudo rm -rf /lib/systemd/system/frpc* && sudo systemctl daemon-reload && sudo mv /etc/frp /etc/frp_bak_M_$(date +%Y_%m_%d_%H:%M:%S)

HostName=${1}
EnvName=${2}
REMOTEPORT=${3}
SERVERADDR=xxx.xxx.xxx.xxx
SERVERPORD=6000
Default_Frp_Passwd=customtoken
#FRPC_TAR_GZ=http://company.xxxxxxxx.cn:61999/packages/frpc_0.37.1_linux_amd64.tar.gz
FRPC_TAR_GZ=http://static.company.xxxxxxxx.cn:9090/packages/frpc_0.37.1_linux_amd64.tar.gz

PID=$(pidof frpc)
Date=$(date +%Y_%m_%d_%H:%M:%S)
BakDir=/etc/frp_bak
BakDirLatest=/etc/frp_bak_${Date}

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
  if [ ${Default_Frp_Passwd} ]; then
    sed -i "/^token.*=/ctoken = ${Default_Frp_Passwd}" "${1}"
  fi
  if [ "${HostName}" ]; then
    sed -i 's/##HOSTNAME##/'"${HostName}"'/g' "${1}"
  fi
  if [ "${EnvName}" ]; then
    sed -i 's/##ENV_NAME##-prod/'"${EnvName}"'/g' "${1}"
  fi
}

CheckFrpcInstall() {
  local frpc_status
  frpc_status=$(systemctl status frpc.service | grep -c disabled)
  if [ "${frpc_status}" -eq 0 ]; then
    echo "Tips: systemctl enable frpc successfully"
  else
    echo "Tips: systemctl enable frpc failure!"
    exit 1
  fi

  if [ -f /etc/frp/frpc.ini ] && [ -f /etc/frp/frpc ] && [ -f /lib/systemd/system/frpc.service ]; then
    echo "Tips: FRP client installed successfully"
  else
    echo "Error: FRP client not installed successfully"
    exit 1
  fi
}

InstallFrpc() {
  cd /tmp && sudo tar --no-same-owner -xzvf frpc_0.37.1_linux_amd64.tar.gz && sudo mv frpc_0.37.1_linux_amd64 /etc/frp && sudo chmod a+r /etc/frp/frpc_tls -R
  UpdateConfig /etc/frp/frpc.ini
  sudo mv /etc/frp/systemd/* /lib/systemd/system/ && sudo rm -rf /etc/frp/systemd
  sudo systemctl daemon-reload && sudo systemctl start frpc.service && sudo systemctl enable frpc.service
  CheckFrpcInstall
}

UpdateFrpc() {
  local frpc_tls_flag
  if [ -d ${BakDir} ]; then
    BakDir=${BakDirLatest}
  fi
  if [ -d /etc/frp ]; then
    mv /etc/frp "${BakDir}"
    mkdir "${BakDir}/systemd"
  fi

  if [ -f /etc/systemd/system/frpc.service ]; then
    cp /etc/systemd/system/frp* "${BakDir}/systemd/"
  elif [ -f /lib/systemd/system/frpc.service ]; then
    cp /lib/systemd/system/frp* "${BakDir}/systemd/"
  fi
  if [ "$(dpkg -l | grep -c frp)" -eq 1 ]; then
    sudo systemctl stop frpc.service
    sudo systemctl disable frpc.service
    sudo apt remove frp -y
  elif [ -f /lib/systemd/system/frpc.service ]; then
    sudo systemctl stop frpc.service
    sudo systemctl disable frpc.service
    sudo rm -f /lib/systemd/system/frpc*
    sudo systemctl daemon-reload
  fi
  cd /tmp || exit
  sudo tar --no-same-owner -xzvf frpc_0.37.1_linux_amd64.tar.gz
  sudo mv frpc_0.37.1_linux_amd64 /etc/frp
  sudo chmod a+r /etc/frp/frpc_tls -R
  UpdateConfig /etc/frp/frpc.ini

  if [ -f "${BakDir}/frpc.ini" ]; then
    sudo mv /etc/frp/frpc.ini /etc/frp/frpc_new.ini
    sudo cp "${BakDir}/frpc.ini" /etc/frp/frpc.ini
  fi
  sed -i "s/.aliyun.xxxxxxxx.cn/.xxxx.xxxxxxxx.cn/g" /etc/frp/frpc.ini
  if [ ${SERVERADDR} ]; then
    sed -i "/^server_addr.*=/cserver_addr = ${SERVERADDR}" /etc/frp/frpc.ini
  fi
  if [ ${SERVERPORD} ]; then
    sed -i "/^server_port.*=/cserver_port = ${SERVERPORD}" /etc/frp/frpc.ini
  fi
  if [ ${Default_Frp_Passwd} ]; then
    sed -i "/^token.*=/ctoken = ${Default_Frp_Passwd}" /etc/frp/frpc.ini
  fi
  frpc_tls_flag=$(grep /etc/frp/frpc_tls /etc/frp/frpc.ini | grep -c -v ^\#)
  if [ ! "${frpc_tls_flag}" -ge 3 ]; then
    sed -i '/\[common\]/a\\ \n# 开启tls加密\ntls_enable = true\ntls_cert_file = /etc/frp/frpc_tls/client.crt\ntls_key_file = /etc/frp/frpc_tls/client.key\ntls_trusted_ca_file = /etc/frp/frpc_tls/ca.crt\n' /etc/frp/frpc.ini
  fi

  sudo mv /etc/frp/systemd/* /lib/systemd/system/
  sudo rm -rf /etc/frp/systemd
  sudo systemctl daemon-reload
  sudo systemctl start frpc.service
  sudo systemctl enable frpc.service

  CheckFrpcInstall
}

DownloadFrpc() {
  if [ ! -f /tmp/frpc_0.37.1_linux_amd64.tar.gz ]; then
    cd /tmp && wget ${FRPC_TAR_GZ}
    if [ -f /tmp/frpc_0.37.1_linux_amd64.tar.gz ]; then
      echo "Tips: Successfully downloaded frpc_0.37.1_linux_amd64.tar.gz to /tmp/frpc_0.37.1_linux_amd64.tar.gz"
    else
      echo "Download frpc_0.37.1_linux_amd64.tar.gz failed!"
      exit 1
    fi
  fi
}

if [ -z "${PID}" ] && [ ! -d /etc/frp ] && [ ! -f /lib/systemd/system/frpc.service ] && [ ! -f /etc/systemd/system/frpc.service ]; then
  # 未安装旧版frp，环境干净，直接安装
  DownloadFrpc
  InstallFrpc &
else
  # 已安装旧版frp，备份配置，对服务进行升级
  DownloadFrpc
  UpdateFrpc &
fi
