#!/bin/bash
# Date: 2023-07-10 17:28
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: Install Safe Agent,Turn on TLS encryption。
# Version: v1.0

# frpc调整为safe_agent安装

# 安装脚本下载
# 有dns解析
# wget http://static.xxxx-prod.xxxxxxxx.cn/shell/safe_agent_install.sh
# 无dns解析
# wget -N --header="Host:static.xxxx-prod.xxxxxxxx.cn" http://xxx.xxx.xxx.xxx/shell/safe_agent_install.sh
# 示例
# sudo bash safe_agent_install.sh XXYY-TEST-001 xxyy-test 26927

# clean safe_agent env, M:Manual
# backup="/opt/safe_agent_bak_M_$(date +%Y_%m_%d_%H:%M:%S)" && sudo systemctl stop safe_agent.service && sudo systemctl disable safe_agent.service && sudo rm -rf /lib/systemd/system/safe_agent* && sudo systemctl daemon-reload && sudo mv /opt/safe_agent ${backup} && sudo mv /usr/local/bin/safe_agent ${backup}

# sudo systemctl stop safe_agent.service && sudo systemctl disable safe_agent.service && sudo rm -rf /lib/systemd/system/safe_agent* && sudo systemctl daemon-reload && sudo rm -rf /usr/local/bin/safe_agent && sudo rm -rf /opt/safe_agent

CommandPath=${0}
HostName=${1}
EnvName=${2}
REMOTEPORT=${3}
SERVERADDR=xxx.xxx.xxx.xxx
SERVERPORD=6000
DefaultToken=customtoken
SafeAgentPackage=safe_agent_0.37.1_linux_amd64.tar.gz
SAFE_AGENT_DOWNLOAD="wget -N -q --header='Host:static.xxxx-prod.xxxxxxxx.cn' http://xxx.xxx.xxx.xxx/packages/${SafeAgentPackage}"

PID=$(pidof safe_agent)

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
    # pg 端口
    sed -i "/^#pg_remote_port.*=/cremote_port = $((REMOTEPORT + 10000))" "${1}"
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
    sed -i 's/##ENV_NAME##/'"${EnvName}"'/g' "${1}"
  fi
}

CleanEnv() {
  # 删除安装包
  rm -rf /tmp/$SafeAgentPackage
  # 删除安装脚本
  rm -rf "${CommandPath}"
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

  if [ -f /opt/safe_agent/config.conf ] && [ -f /usr/local/bin/safe_agent ] && [ -f /lib/systemd/system/safe_agent.service ]; then
    echo "Tips: safe_agent installed successfully"
    CleanEnv
  else
    echo "Error: safe_agent not installed successfully"
    exit 1
  fi
}

InstallSafeAgent() {
  cd /tmp && sudo tar --no-same-owner -xzf $SafeAgentPackage && sudo mv safe_agent_0.37.1_linux_amd64 /opt/safe_agent && sudo chmod a+r /opt/safe_agent/tls -R
  UpdateConfig /opt/safe_agent/config.conf
  sudo mv /opt/safe_agent/systemd/* /lib/systemd/system/ && sudo rm -rf /opt/safe_agent/systemd
  sudo mv /opt/safe_agent/safe_agent /usr/local/bin/
  sudo systemctl daemon-reload && sudo systemctl start safe_agent.service && sudo systemctl enable safe_agent.service
  CheckSafeAgentInstall
}

DownloadSafeAgent() {
  # 提示输入用户名密码
  read -r -t 60 -p "请输入下载用户名(user): " user
  read -r -s -t 60 -p "请输入下载密码(password): " password
  echo

  if [ -z "$user" ] || [ -z "$password" ]; then
    echo "ERROR: 下载用户名或密码为空."
    exit 1
  fi

  ARGS="--user=$user --password=$password"

  cd /tmp && eval "${SAFE_AGENT_DOWNLOAD} ${ARGS}"
  if [ -f /tmp/$SafeAgentPackage ]; then
    echo "Tips: Successfully downloaded $SafeAgentPackage to /tmp/$SafeAgentPackage"
  else
    echo "Download $SafeAgentPackage failed!"
    exit 1
  fi
}

if [ -z "${PID}" ] && [ ! -d /opt/safe_agent ] && [ ! -f /lib/systemd/system/safe_agent.service ]; then
  # 未安装 safe_agent ，环境干净，直接安装
  DownloadSafeAgent
  InstallSafeAgent
else
  echo "safe_agent 进程存在 | /opt/safe_agent 目录存在 | /lib/systemd/system/safe_agent.service 文件存在,无法安装 safe_agent."
  exit 1
fi
