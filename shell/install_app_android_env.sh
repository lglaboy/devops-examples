#!/bin/bash
# Date: 2022-9-26 15:51
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: install Android app build env
# Version: v1.0

#检测脚本日志文件
MONITOR_LOG_FILE=/tmp/install_android_app_env.log
# 安装目录



#log方法
function log() {
  echo "$(date +'%F %T') $*" >>$MONITOR_LOG_FILE
}

install_npm() {
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
    # 需要判断ubuntu系统版本，这个是xenial 16.04的版本
    sudo tee /etc/apt/sources.list <<EOF
deb http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse
EOF
    sudo apt update
    # 安装npm
    sudo apt install npm -y
}

# 安装nvm
install_nvm() {
    # 下载nvm.tar.gz
    if wget -O ~/nvm.tar.gz http://192.168.1.51/packages/app_android_env/nvm.tar.gz; then
        echo ok
    elif wget -O ~/nvm.tar.gz http://static.company.xxxxxxxx.cn:9090/packages/app_android_env/nvm.tar.gz; then
        echo ok
    else
        echo download error
    fi
    cd ~/ || exit
    tar -xzvf nvm.tar.gz
    # 4.激活nvm
    cd ~/.nvm || exit
    . ./nvm.sh
    # 5.添加到~/.bashrc，~/.profile或者~/.zshrc
    tee -a ~/.bashrc <<EOF
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion" # This loads nvm bash_completion
EOF

}

install_sdk() {
    # 下载commandlinetools
    if wget -O ~/commandlinetools-linux-7302050_latest.zip http://192.168.1.51/packages/app_android_env/commandlinetools-linux-7302050_latest.zip; then
        echo ok
    elif wget -O ~/commandlinetools-linux-7302050_latest.zip http://static.company.xxxxxxxx.cn:9090/packages/app_android_env/commandlinetools-linux-7302050_latest.zip; then
        echo ok
    else
        echo download error
    fi
    sudo apt install unzip -y || exit 1
    mkdir "$HOME"/Android/sdk -p && unzip ~/commandlinetools-linux-7302050_latest.zip -d "$HOME"/Android/sdk
    cd "$HOME"/Android/sdk/cmdline-tools/bin/ || exit
    yes | ./sdkmanager --licenses --sdk_root="$HOME"/Android/sdk
}

install_jdk() {
    # 安装jdk-11
    if wget -O ~/jdk-11.0.15_linux-x64_bin.deb http://192.168.1.51/packages/app_android_env/jdk-11.0.15_linux-x64_bin.deb; then
        echo ok
    elif wget -O ~/jdk-11.0.15_linux-x64_bin.deb http://static.company.xxxxxxxx.cn:9090/packages/app_android_env/jdk-11.0.15_linux-x64_bin.deb; then
        echo ok
    else
        echo download error
    fi
    sudo apt install -f ~/jdk-11.0.15_linux-x64_bin.deb -y
    PATH=/usr/lib/jvm/jdk-11/bin:$PATH && export PATH
    echo "PATH=/usr/lib/jvm/jdk-11/bin:$PATH
export PATH" | tee -a /etc/profile
}

kernel_tuning() {
    # 修复环境npm
    npm install inquirer

    #调整系统参数
    # sudo vim /etc/sysctl.conf
    echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
}

# 整理安装
install_all_modules() {
    if ! install_npm; then
        echo "安装npm失败"
    fi

    if ! install_nvm; then
        echo "安装nvm失败"
    fi

    if ! install_jdk; then
        echo "安装jdk失败"
    fi

    if ! install_sdk; then
        echo "安装sdk失败"
    fi

    if ! kernel_tuning; then
        echo "调整内核参数失败"
    fi
}

# 单个安装

# 需要管理员运行
# if [ "$(whoami)" != "root" ]; then
#     echo "Run this shell script with root"
#     exit 1
# fi

# 判断系统环境
# 判断系统
system=$(uname -a)

mac="Darwin"
centos="Centos"
ubuntu="Ubuntu"

if [[ ${system} =~ ${ubuntu} ]]; then
    install_all_modules
# elif [[ ${system} =~ ${centos} ]];then
#     install_all_modules
# elif [[ ${system} =~ ${mac} ]];then
#     install_all_modules
else
    echo "${system}"
    echo "暂时不支持该系统安装"
    exit 1
fi

# 提供单独安装某个模块的功能
# 支持卸载

# while getopts 'e:i:j:' opt; do
#     case $opt in
#     e)
#         ENVNAME=$OPTARG
#         ;;
#     i)
#         HOST_GROUP=$OPTARG
#         ;;
#     j)
#         ANSIBLE_PLAYBOOK=$OPTARG
#         ;;
#     ?)
#         usage
#         exit 1
#         ;;
#     esac
# done
