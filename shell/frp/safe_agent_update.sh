#!/bin/bash
# Date: 2023-07-10 17:28
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: safe_agent update
# Version: v1.0

# frpc调整为safe_agent安装

# 安装脚本下载
# wget http://static.company.xxxxxxxx.cn:9090/shell/safe_agent_update.sh
# 示例
# sudo bash safe_agent_install.sh XXYY-TEST-001 xxyy-test 26927

# clean safe_agent env, M:Manual
# backup="/opt/safe_agent_bak_M_$(date +%Y_%m_%d_%H:%M:%S)" && sudo systemctl stop safe_agent.service && sudo systemctl disable safe_agent.service && sudo rm -rf /lib/systemd/system/safe_agent* && sudo systemctl daemon-reload && sudo mv /opt/safe_agent ${backup} && sudo mv /usr/local/bin/safe_agent ${backup}

CommandPath=${0}
Date=$(date +%Y_%m_%d_%H_%M_%S)
BakDir=/opt/safe_agent/bak

SafeAgentPackage=safe_agent_0.37.1_linux_amd64.tar.gz
SAFE_AGENT_DOWNLOAD_URL=http://static.company.xxxxxxxx.cn:9090/packages/${SafeAgentPackage}

PID=$(pidof safe_agent)

CleanEnv() {
  # 删除解压后的目录
  rm -rf /tmp/safe_agent_0.37.1_linux_amd64
  # 删除安装包
  rm -rf /tmp/${SafeAgentPackage}
  # 删除安装脚本
  rm -rf "${CommandPath}"
}

UpdateSafeAgent() {
  cd /tmp && sudo tar --no-same-owner -xzvf ${SafeAgentPackage}

  # 备份可执行文件
  if [[ ! -d $BakDir ]];then
    mkdir -p $BakDir
  fi
  mv /usr/local/bin/safe_agent "${BakDir}/safe_agent_${Date}"

  cp -a safe_agent_0.37.1_linux_amd64/safe_agent /usr/local/bin/

  # 确保有可执行权限
  chmod +x /usr/local/bin/safe_agent

  # 判断可执行文件是否更新
  if [[ $(md5sum /usr/local/bin/safe_agent |awk '{print $1}') == $(md5sum /tmp/safe_agent_0.37.1_linux_amd64/safe_agent |awk '{print $1}') ]];then
    echo "/usr/local/bin/safe_agent 已更新"
  else
    echo "/usr/local/bin/safe_agent 未成功更新"
    exit 1
  fi

  sudo systemctl restart safe_agent.service

  # 检查清理
  CleanEnv
}

DownloadSafeAgent() {
  cd /tmp && wget -N ${SAFE_AGENT_DOWNLOAD_URL}
  if [ -f /tmp/${SafeAgentPackage} ]; then
    echo "Tips: Successfully downloaded ${SafeAgentPackage} to /tmp/${SafeAgentPackage}"
  else
    echo "Download ${SafeAgentPackage} failed!"
    exit 1
  fi
}

if [ "$(whoami)" != "root" ]; then
  echo "Run this shell script with root"
  exit 1
fi

if [ -n "${PID}" ] && [ -d /opt/safe_agent ] && [ -f /opt/safe_agent/config.conf ] && [ -f /usr/local/bin/safe_agent ] && [ -f /lib/systemd/system/safe_agent.service ]; then
  # safe_agent 相关文件存在且启动
  # 更新 safe_agent 可执行文件
  DownloadSafeAgent
  UpdateSafeAgent &
else
  echo "条件不符合, 未更新safe_agent."
  exit 1
fi
