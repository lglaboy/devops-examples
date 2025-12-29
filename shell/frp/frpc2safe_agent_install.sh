#!/bin/bash
# Date: 2023-07-10 17:28
# Author:
# Mail: @xxxxxxxx.cn
# Description: Install Safe Agent,Turn on TLS encryption。
# Version: v1.0

# frpc调整为safe_agent安装

# 安装脚本下载
# local
# wget -N --header="Host:static.company.xxxxxxxx.cn" http://xxx.xxx.xxx.xxx:9090/shell/safe_agent_install.sh
# cloud
# wget -N --header="Host:static.xxxx-prod.xxxxxxxx.cn" http://xxx.xxx.xxx.xxx/shell/safe_agent_install.sh
# 示例
# sudo bash safe_agent_install.sh XXYY-TEST-001 xxyy-test 26927

# clean safe_agent env, M:Manual
# backup="/opt/safe_agent_bak_M_$(date +%Y_%m_%d_%H:%M:%S)" && sudo systemctl stop safe_agent.service && sudo systemctl disable safe_agent.service && sudo rm -rf /lib/systemd/system/safe_agent* && sudo systemctl daemon-reload && sudo mv /opt/safe_agent ${backup} && sudo mv /usr/local/bin/safe_agent ${backup}

readonly SERVER_ADDR=xxx.xxx.xxx.xxx
readonly SERVER_PORD=6000
readonly DEFAULT_TOKEN=customtoken
readonly SAFE_AGENT_PACKAGE_NAME=safe_agent_0.37.1_linux_amd64.tar.gz

command_path=${0}
host_name=${1}
env_name=${2}
remote_port=${3}
download_source=${4:-company}

safe_agent_download_url="wget -N -q --header='Host:static.company.xxxxxxxx.cn' http://xxx.xxx.xxx.xxx:9090/packages/${SAFE_AGENT_PACKAGE_NAME}"
safe_agent_download_cloud_url="wget -N -q --header='Host:static.xxxx-prod.xxxxxxxx.cn' http://xxx.xxx.xxx.xxx/packages/${SAFE_AGENT_PACKAGE_NAME}"

safe_agent_pid=$(pidof safe_agent)

usage() {
    echo "Usage:"
    echo "Tips: ${0} host_name env_name remote_port [cloud]"
    echo "${0} XXYY-REMOTETEST-001 xxyy-test 16927"
    echo "从cloud源下载package"
    echo "${0} XXYY-REMOTETEST-001 xxyy-test 16927 cloud"
    exit 1
}

UpdateConfig() {
    if [ "${remote_port}" ]; then
        sed -i "/^#remote_port.*=/cremote_port = ${remote_port}" "${1}"
    fi
    if [ ${SERVER_ADDR} ]; then
        sed -i "/^server_addr.*=/cserver_addr = ${SERVER_ADDR}" "${1}"
    fi
    if [ ${SERVER_PORD} ]; then
        sed -i "/^server_port.*=/cserver_port = ${SERVER_PORD}" "${1}"
    fi
    if [ ${DEFAULT_TOKEN} ]; then
        sed -i "/^token.*=/ctoken = ${DEFAULT_TOKEN}" "${1}"
    fi
    if [ "${host_name}" ]; then
        sed -i 's/##HOSTNAME##/'"${host_name}"'/g' "${1}"
    fi
    if [ "${env_name}" ]; then
        sed -i 's/##ENV_NAME##-prod/'"${env_name}"'/g' "${1}"
    fi
}

CleanEnv() {
    # 删除安装包
    rm -rf /tmp/safe_agent_0.37.1_linux_amd64.tar.gz
    # 删除安装脚本
    rm -rf "${command_path}"
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
    cd /tmp && sudo tar --no-same-owner -xzvf safe_agent_0.37.1_linux_amd64.tar.gz && sudo mv safe_agent_0.37.1_linux_amd64 /opt/safe_agent && sudo chmod a+r /opt/safe_agent/tls -R
    UpdateConfig /opt/safe_agent/config.conf
    sudo mv /opt/safe_agent/systemd/* /lib/systemd/system/ && sudo rm -rf /opt/safe_agent/systemd
    sudo mv /opt/safe_agent/safe_agent /usr/local/bin/
    sudo systemctl daemon-reload && sudo systemctl start safe_agent.service && sudo systemctl enable safe_agent.service
    CheckSafeAgentInstall
}

DownloadSafeAgent() {
    cd /tmp && eval "${safe_agent_download_url}"
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

if [ $# -lt 3 ]; then
    echo "Error: vars not enough"
    usage
fi

if [ -n "$remote_port" ] && [ ! "$remote_port" = "${remote_port//[^0-9]/}" ]; then
    echo "Error: Input parameter error."
    usage
fi

if [ "$download_source" == "cloud" ]; then
    safe_agent_download_url=$safe_agent_download_cloud_url
fi

if [ -z "${safe_agent_pid}" ] && [ ! -d /opt/safe_agent ] && [ ! -f /lib/systemd/system/safe_agent.service ]; then
    # 未安装 safe_agent ，环境干净，直接安装
    DownloadSafeAgent
    InstallSafeAgent &
else
    echo "safe_agent 进程存在 | /opt/safe_agent 目录存在 | /lib/systemd/system/safe_agent.service 文件存在,无法安装 safe_agent."
    exit 1
fi
