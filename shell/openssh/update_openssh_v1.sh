#!/bin/bash
# Date: 2021-9-27 09:42
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: Ubuntu 16.04, update openssh to Openssh-8.7p1
# Version: v1.0

# install shell
# wget http://company.xxxxxxxx.cn:61999/shell/update_openssh.sh
# Execute script，记得要加nohup，不然连接中断，脚本也会中断。
# nohup sudo bash update_openssh.sh
# nohup sudo bash update_openssh.sh &>/tmp/update_openssh.log &

# 变量定义

# 各个包的下载地址

PUBLIC_URL="http://static.company.xxxxxxxx.cn:9090/packages/openssh"
LOCAL_URL="http://192.168.1.51/packages/openssh"

ZLIB="zlib-1.2.11.tar.gz"
OPENSSL="openssl-1.1.1.tar.gz"
OPENSSH="openssh-8.7p1.tar.gz"

# GET_URL=""

# DOWNLOAD_ZLIB="${GET_URL}/"
# DOWNLOAD_OPENSSL=""
# DOWNLOAD_OPENSSH=""
# DOWNLOAD_MD5=""

# 系统判断
# ubuntu系统，再判断版本
# 判断系统
GET_SYSTEM_TYPE=$(uname -a)
# SYSTEM_MAC="Darwin"
# SYSTEM_CENTOS="Centos"
SYSTEM_UBUNTU="Ubuntu"

UBUNTU_CODENAME="xenial"

DATE=$(date +%Y_%m_%d_%H:%M:%S)

# 工作目录
WORK_DIR=$HOME/openssh
WORK_DIR_OLD=$HOME/openssh_${DATE}

# 网络检测
CheckNetwork() {
    local timeout
    local local_return_code
    local public_return_code
    timeout=1
    local_return_code=$(curl ${LOCAL_URL} -I -s --connect-timeout ${timeout} -w %\{http_code\} | tail -n1)
    public_return_code=$(curl ${PUBLIC_URL} -I -s --connect-timeout ${timeout} -w %\{http_code\} | tail -n1)
    if [[ "${local_return_code}" == "200" ]]; then
        GET_URL=${LOCAL_URL}
    elif [[ ${public_return_code} == "301" ]]; then
        #statements
        GET_URL=${PUBLIC_URL}
    else
        return 1
    fi
}

# 下载源码包
DownloadAllPackages() {
    # 判断旧目录是否有文件
    if [[ -d ${WORK_DIR_OLD} ]] && [[ -f ${WORK_DIR_OLD}/${ZLIB} ]] && [[ -f ${WORK_DIR_OLD}/${OPENSSL} ]] && [[ -f ${WORK_DIR_OLD}/${OPENSSH} ]]; then
        cp -p "${WORK_DIR_OLD}/${ZLIB}" "${WORK_DIR}"
        cp -p "${WORK_DIR_OLD}/${OPENSSL}" "${WORK_DIR}"
        cp -p "${WORK_DIR_OLD}/${OPENSSH}" "${WORK_DIR}"
    else
        cd "${WORK_DIR}" || exit
        # 下载
        CheckNetwork
        if [[ $? -eq 1 ]]; then
            echo "网络不通，无法直接下载！请手动传包至${WORK_DIR}目录。"
            exit 1
        else
            wget -q ${GET_URL}/${ZLIB}
            wget -q ${GET_URL}/${OPENSSL}
            wget -q ${GET_URL}/${OPENSSH}
        fi
    fi

    # 判断是否下载完成
    if [[ -f ${ZLIB} ]] && [[ -f ${OPENSSL} ]] && [[ -f ${OPENSSH} ]]; then
        #statements
        tar -xzvf ${ZLIB} && tar -xzvf ${OPENSSL} && tar -xzvf ${OPENSSH}
        echo "文件已经准备好了！"
    else
        echo "文件未准备好，请检查${WORK_DIR}目录，是否存在以下文件：${ZLIB}, ${OPENSSL}, ${OPENSSH}."
        exit 1
    fi

    # 若下载不下来包的话，提示手动传包到指定目录，但是，如果此时中断，再次执行脚本的时候将旧的工作目录就mv走了，新建的目录下还是没有包，避免这种情况，进行判断

    # 下载的包需要进行md5比对吗？

}

# 安装inetd服务
InstallTelnetd() {
    if [[ ! $(dpkg -l | grep -c openbsd-inetd) -ge 1 ]]; then
        if [[ $(sudo apt-get update) ]]; then
            sudo apt install -y openbsd-inetd
        else
            echo "安装 openbsd-inetd 服务失败！请手动安装：sudo apt install -y openbsd-inetd"
            exit 1
        fi
    fi
    if [[ ! $(dpkg -l | grep -c telnetd) -ge 1 ]]; then
        if [[ $(sudo apt-get update) ]]; then
            sudo apt install -y telnetd
        else
            echo "安装 telnetd 服务失败！请手动安装：sudo apt install -y telnetd"
            exit 1
        fi
    fi
}

# 安装依赖包
InstallDependentPackage() {
    local libzip_dev_dpkg
    local libssl_dev_dpkg
    local autoconf_dpkg
    local gcc_dpkg
    local libxml2_dpkg
    local make_dpkg

    libzip_dev_dpkg=$(dpkg -l | grep -c libzip-dev)
    libssl_dev_dpkg=$(dpkg -l | grep -c libssl-dev)
    autoconf_dpkg=$(dpkg -l | grep -c autoconf)
    gcc_dpkg=$(dpkg -l | grep -c gcc)
    libxml2_dpkg=$(dpkg -l | grep -c libxml2)
    make_dpkg=$(dpkg -l | grep -c make)
    if [[ ${libzip_dev_dpkg} -ge 1 ]] && [[ ${libssl_dev_dpkg} -ge 1 ]] && [[ ${autoconf_dpkg} -ge 1 ]] && [[ ${gcc_dpkg} -ge 1 ]] && [[ ${libxml2_dpkg} -ge 1 ]] && [[ ${make_dpkg} -ge 1 ]]; then
        :
    else
        if [[ $(sudo apt-get update) ]]; then
            sudo apt install libzip-dev libssl-dev autoconf gcc libxml2 make -y
        else
            echo "安装依赖包失败，请手动安装！< sudo apt update && sudo apt install libzip-dev libssl-dev autoconf gcc libxml2 make -y >"
            exit 1
        fi
    fi
}

# 编译zlib
InstallZlib() {
    if [[ ! -d zlib-1.2.11 ]]; then
        echo "zlib-1.2.11 目录不存在，请检查${WORK_DIR}目录！"
        exit 1
    fi
    cd zlib-1.2.11/ || exit
    ./configure --prefix=/usr/local
    make
    sudo make install
    cd ..
}

# 编译openssl
InstallOpenssl() {
    if [[ ! -d openssl-1.1.1 ]]; then
        echo "openssl-1.1.1 目录不存在，请检查${WORK_DIR}目录！"
        exit 1
    fi
    cd openssl-1.1.1/ || exit
    ./config shared --prefix=/usr/local/ssl
    make test
    sudo make install
    cd ..

    if [[ ! -f /usr/local/ssl/bin/openssl ]]; then
        echo "openssl编译失败，无可执行文件，/usr/local/ssl/bin/openssl！"
        exit 1
    fi

    # 若文件已经存在怎么办
    if [[ -f "/usr/lib/libssl.so.1.1" ]]; then
        echo "/usr/lib/libssl.so.1.1文件已存在，移动到/tmp。"
        mv /usr/lib/libssl.so.1.1 /tmp
    fi
    if [[ -f "/usr/lib/libcrypto.so.1.1" ]]; then
        echo "/usr/lib/libcrypto.so.1.1文件已存在，移动到/tmp。"
        mv /usr/lib/libcrypto.so.1.1 /tmp
    fi
    sudo ln -s /usr/local/ssl/lib/libssl.so.1.1 /usr/lib/libssl.so.1.1
    sudo ln -s /usr/local/ssl/lib/libcrypto.so.1.1 /usr/lib/libcrypto.so.1.1

    sudo mv /usr/bin/openssl /usr/bin/openssl.bak
    sudo ln -s /usr/local/ssl/bin/openssl /usr/bin/openssl

    # openssl version -a

}

# 编译openssh
InstallOpenssh() {
    mkdir /tmp/ssh_bak -p
    mkdir /tmp/ssh_bak/init.d -p
    sudo cp -r /etc/ssh /tmp/ssh_bak
    sudo cp /etc/init.d/ssh /tmp/ssh_bak/init.d

    if [[ ! -d openssh-8.7p1 ]]; then
        echo "openssh-8.7p1 目录不存在，请检查${WORK_DIR}目录！"
        exit 1
    fi

    cd openssh-8.7p1/ || exit
    ./configure --prefix=/usr/local --sysconfdir=/etc/ssh --with-ssl-dir=/usr/local/ssl
    make
    sudo make install
    cd ..

    # 判断编译是否成功
    if [[ ! -f "/usr/local/sbin/sshd" ]] || [[ ! -f "/usr/local/bin/ssh" ]]; then
        echo "openssh编译失败，无可执行文件，/usr/local/sbin/sshd, /usr/local/bin/ssh ！"
        exit 1
    else
        # 替换sshd_config文件中不支持的选项
        sudo sed -i '/^UsePrivilegeSeparation.*/ s/^/#/;/^KeyRegenerationInterval.*/ s/^/#/;/^ServerKeyBits.*/ s/^/#/;/^RSAAuthentication.*/ s/^/#/;/^RhostsRSAAuthentication.*/ s/^/#/;/^UsePAM.*/ s/^/#/;' /etc/ssh/sshd_config
    fi

    sudo service sshd stop

    mkdir /tmp/ssh_bak/bin -p
    sudo mv /usr/bin/scp /tmp/ssh_bak/bin
    sudo mv /usr/bin/ssh* /tmp/ssh_bak/bin

    sudo ln -s /usr/local/bin/ssh /usr/bin/ssh
    sudo ln -s /usr/local/bin/scp /usr/bin/scp
    sudo ln -s /usr/local/bin/ssh-add /usr/bin/ssh-add
    sudo ln -s /usr/local/bin/ssh-agent /usr/bin/ssh-agent
    sudo ln -s /usr/local/bin/ssh-keygen /usr/bin/ssh-keygen
    sudo ln -s /usr/local/bin/ssh-keyscan /usr/bin/ssh-keyscan

    mkdir /tmp/ssh_bak/sbin -p
    sudo mv /usr/sbin/sshd /tmp/ssh_bak/sbin
    sudo ln -s /usr/local/sbin/sshd /usr/sbin/sshd

    sudo mv /lib/systemd/system/ssh.service /lib/systemd/system/ssh.service.bak
    cat <<EOF | sudo tee /lib/systemd/system/ssh.service
[Unit]
Description=OpenSSH server daemon
[Service]
ExecStart=/usr/sbin/sshd -f /etc/ssh/sshd_config -D
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl restart ssh.service
    sudo systemctl enable ssh.service
}

# 修改配置文件，将不支持的选项注释掉

# 判断sshd服务是否启动成功

# 判断系统是否符合
# 判断是否安装inetd
# 判断是否安装依赖
# 判断是否下载好安装包
# 判断每一步是否编译成功

# 任何步骤出错，及时中断，进行手动检查

# 更新Openssh主函数名称
UpdateOpensshMain() {
    # 安装 telnetd服务和依赖
    InstallTelnetd
    InstallDependentPackage
    # 创建工作目录，创建前先判断
    if [[ -d ${WORK_DIR} ]]; then
        #statements
        mv "${WORK_DIR}" "${WORK_DIR_OLD}"
        mkdir "${WORK_DIR}"
    else
        mkdir "${WORK_DIR}"
    fi
    # 切换到主目录
    cd "${WORK_DIR}" || exit
    # 下载源码包
    DownloadAllPackages

    # 编译
    InstallZlib
    InstallOpenssl
    InstallOpenssh
}

if [[ ${GET_SYSTEM_TYPE} =~ ${SYSTEM_UBUNTU} ]]; then
    # ubunt系统可执行
    GET_UBUNTU_CODENAME=$(lsb_release -c)
    GET_SSH_VERSION=$(ssh -V 2>&1)
    GET_SSHD_VERSION=$(sshd -V 2>&1 | sed -n '2p')
    if [[ ${GET_UBUNTU_CODENAME} =~ ${UBUNTU_CODENAME} ]]; then
        # ubuntu 16.04 才可执行
        if [[ ${GET_SSH_VERSION} == *"OpenSSH_8.7p1"* ]] || [[ ${GET_SSHD_VERSION} == *"OpenSSH_8.7p1"* ]]; then
            echo "Openssh已经更新到OpenSSH_8.7p1版本!"
            echo "ssh版本详情：${GET_SSH_VERSION}"
            echo "sshd版本详情：${GET_SSHD_VERSION}"
            exit 1
        else
            UpdateOpensshMain
        fi
    else
        echo "Ubuntu系统非${UBUNTU_CODENAME}，退出执行！"
        exit 1
    fi
else
    echo "该系统为${GET_SYSTEM_TYPE}，非Ubuntu系统，退出执行！"
    exit 1
fi
