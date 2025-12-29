#!/bin/bash
# Date: 2023-07-10 17:28
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: Install Safe Agent,Turn on TLS encryption。
# Version: v1.0

# frpc调整为safe_agent安装

# 注意：通过远程端口连接，执行脚本，请设置后台运行，否则可能会导致失联
# wget http://static.company.xxxxxxxx.cn:9090/shell/frpc2safe_agent.sh
# nohup sudo bash safe_agent_install.sh XXYY-TEST-001 xxyy-test 26927 &>/dev/null &

# clean safe_agent env, M:Manual
# 清理safe_agent
# backup="/opt/safe_agent_bak_M_$(date +%Y_%m_%d_%H:%M:%S)" && sudo systemctl stop safe_agent.service && sudo systemctl disable safe_agent.service && sudo rm -rf /lib/systemd/system/safe_agent* && sudo systemctl daemon-reload && sudo mv /opt/safe_agent ${backup} && sudo mv /usr/local/bin/safe_agent ${backup}

CommandPath=${0}
SAFE_AGENT_DOWNLOAD_URL=http://static.company.xxxxxxxx.cn:9090/packages/safe_agent_0.37.1_linux_amd64.tar.gz

PID=$(pidof frpc)
Date=$(date +%Y_%m_%d_%H:%M:%S)
BakDir=/opt/frp_bak
BakDirLatest=/opt/frp_bak_${Date}

CleanEnv() {
  # 删除安装包
  rm -rf /tmp/safe_agent_0.37.1_linux_amd64.tar.gz
  # 删除安装脚本
  rm -rf "${CommandPath}"
}


CheckSafeAgentInstall() {
  local safe_agent_status
  local safe_agent_pid
  safe_agent_status=$(systemctl status safe_agent.service | grep -c disabled)
  if [ "${safe_agent_status}" -eq 0 ]; then
    echo "Tips: systemctl enable safe_agent successfully"
  else
    echo "Tips: systemctl enable safe_agent failure!"
    exit 1
  fi

  safe_agent_pid=$(pidof safe_agent)

  if [ -n "${safe_agent_pid}" ]; then
    echo "Tips: safe_agent installed successfully"
    CleanEnv
  else
    echo "Error: safe_agent not installed successfully"
    exit 1
  fi
}

UpdateFrpcToSafeAgent() {
  # 配置safe_agent
  cd /tmp || exit
  sudo tar --no-same-owner -xzvf safe_agent_0.37.1_linux_amd64.tar.gz

  # 判断 /opt/safe_agent 是否存在,存在手动处理
  if [ -d /opt/safe_agent ];then
    echo "目录已存在，无法配置 safe_agent ,请手动处理。"
    exit 1
    # mv /opt/safe_agent /opt/safe_agent_bak
    # if [ -f /usr/local/bin/safe_agent ];then
    #   mv /usr/local/bin/safe_agent /opt/safe_agent_bak/
    # fi
  fi

  sudo mv safe_agent_0.37.1_linux_amd64 /opt/safe_agent
  sudo chmod a+r /opt/safe_agent/tls -R
  mv /opt/safe_agent/config.conf /opt/safe_agent/config_template.conf

  # 复制原先配置文件
  cp -a /etc/frp/frpc.ini /opt/safe_agent/config.conf
  # 在原先配置上进行修改
  # 1.调整tls路径
  # 2.添加log
  sed -i 's#/etc/frp/frpc_tls#./tls#g' /opt/safe_agent/config.conf

  if [[ $(grep -c "log_file" /opt/safe_agent/config.conf | cat) -eq 0 ]];then
  sed -i '/tls_trusted_ca_file/ a\
\
# 日志\
# console or real logFile path like ./safe_agent.log\
log_file = ./safe_agent.log\
log_level = info\
log_max_days = 30' /opt/safe_agent/config.conf
  fi


  sudo mv /opt/safe_agent/systemd/* /lib/systemd/system/
  sudo rm -rf /opt/safe_agent/systemd
  sudo mv /opt/safe_agent/safe_agent /usr/local/bin/

  sudo systemctl daemon-reload

  # 卸载frpc
  if [ -d ${BakDir} ]; then
    BakDir=${BakDirLatest}
  fi

  if [ -d /etc/frp ]; then
    mv /etc/frp "${BakDir}"
    mkdir "${BakDir}/systemd"
  fi

  cp /lib/systemd/system/frpc* "${BakDir}/systemd/"

  if [ ! -f /opt/safe_agent/config.conf ] && [ ! -f /usr/local/bin/safe_agent ] && [ ! -f /lib/systemd/system/safe_agent.service ]; then
    echo "检查异常,不进行关闭frpc,启动safe_agent操作"
    echo "请检查配置文件是否存在: /opt/safe_agent/config.conf"
    echo "请检查可执行文件是否存在: /usr/local/bin/safe_agent"
    echo "请检查service文件是否存在: /lib/systemd/system/safe_agent.service"
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

if [ -n "${PID}" ] && [ -d /etc/frp ] && [ -d /etc/frp/frpc_tls ] && [ -f /etc/frp/frpc.ini ] && [ -f /etc/frp/frpc ] && [ -f /lib/systemd/system/frpc.service ]; then
  DownloadSafeAgent
  UpdateFrpcToSafeAgent &
else
  echo "frpc 进程不存在 | /etc/frp 目录不存在 | /etc/frp/frpc_tls 目录不存在 | /etc/frp/frpc.ini 文件不存在 | /etc/frp/frpc 文件不存在 | /lib/systemd/system/frpc.service 文件不存在,无法转成 safe_agent."
  exit 1
fi
