#!/bin/bash
# Date: 2021-9-27 09:42
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: Ubuntu 16.04, update openssh to Openssh-X.YpZ
# Version: v1.0

# 联网机器更新openssh版本脚本

# install shell
# wget http://company.xxxxxxxx.cn:61999/shell/update_openssh.sh
# Execute script，记得要加nohup，不然可能连接中断，脚本也会中断。
# nohup sudo bash update_openssh.sh
# nohup sudo bash update_openssh.sh &>/tmp/update_openssh.log &

# 变量定义

# 各个包的下载地址

# 获取最新openssh 版本
# curl http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/ -s |grep -o 'openssh-[0-9]\+\.[0-9p]\+\.tar\.gz'|tail -n 1

# 不需要dns解析下载示例
# wget -q -N --header="Host:static.xxxx-prod.xxxxxxxx.cn" http://xxx.xxx.xxx.xxx/packages/{{download_image_name}} -O /tmp/{{download_image_name}}

# 官方下载地址
# https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-10.0p2.tar.gz


# 任何非0错误，脚本就会退出
set -e

# 参数 ssh版本，如: 10.0p2 
SSH_VERSION=${1}
OPENSSL_VERSION="1.1.1w"

PUBLIC_URL="http://static.company.xxxxxxxx.cn:8090/packages/openssh"
LOCAL_URL="http://192.168.1.51/packages/openssh"

ZLIB="zlib-1.2.11.tar.gz"
OPENSSL="openssl-${OPENSSL_VERSION}.tar.gz"
OPENSSH="openssh-${SSH_VERSION}.tar.gz"

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
            echo "网络不通，无法直接下载！"
            echo "请手动将${ZLIB}传包至${WORK_DIR}目录。"
            echo "请手动将${OPENSSL}传包至${WORK_DIR}目录。"
            echo "请手动将${OPENSSH}传包至${WORK_DIR}目录。"
            exit 1
        else
            if wget -q ${GET_URL}/${ZLIB} ; then
                echo "下载${ZLIB}成功！"
            else
                echo "下载${ZLIB}失败！"
                exit 1
            fi
            
            if wget -q ${GET_URL}/${OPENSSL}; then
                echo "下载${OPENSSL}成功！"
            else
                echo "下载${OPENSSL}失败！"
                exit 1
            fi
            if wget -q ${GET_URL}/${OPENSSH}; then
                echo "下载${OPENSSH}成功！"
            else
                echo "下载${OPENSSH}失败！"
                exit 1
            fi
        fi
    fi

    # 判断是否下载完成
    if [[ -f ${ZLIB} ]] && [[ -f ${OPENSSL} ]] && [[ -f ${OPENSSH} ]]; then
        #statements
        tar -xzf ${ZLIB} && tar -xzf ${OPENSSL} && tar -xzf ${OPENSSH} --strip-components=1 --one-top-level=openssh-${SSH_VERSION}
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
    # 若已经安装，判断是否启动
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

    libzip_dev_dpkg=$(dpkg -l | grep -c libzip-dev || true)
    libssl_dev_dpkg=$(dpkg -l | grep -c libssl-dev || true)
    autoconf_dpkg=$(dpkg -l | grep -c autoconf || true)
    gcc_dpkg=$(dpkg -l | grep -c gcc || true)
    libxml2_dpkg=$(dpkg -l | grep -c libxml2 || true)
    make_dpkg=$(dpkg -l | grep -c make || true)
    if [[ ${libzip_dev_dpkg} -ge 1 ]] && [[ ${libssl_dev_dpkg} -ge 1 ]] && [[ ${autoconf_dpkg} -ge 1 ]] && [[ ${gcc_dpkg} -ge 1 ]] && [[ ${libxml2_dpkg} -ge 1 ]] && [[ ${make_dpkg} -ge 1 ]]; then
        :
    else
        if [[ $(sudo apt-get update) ]]; then
            sudo apt install libzip-dev libssl-dev autoconf gcc libxml2 make libpam0g-dev -y
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
    # make -j 线程全开，快，但是可能会因为内存问题导致kill
    make
    sudo make install
    cd ..
}

# 编译openssl
# TODO: 添加编译前判断是否已安装
InstallOpenssl() {
    if [[ ! -d openssl-${OPENSSL_VERSION} ]]; then
        echo "openssl-${OPENSSL_VERSION} 目录不存在，请检查${WORK_DIR}目录！"
        exit 1
    fi
    cd openssl-${OPENSSL_VERSION}/ || exit
    ./config shared --prefix=/usr/local/ssl
    make
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
        sudo mv /usr/lib/libssl.so.1.1 /tmp
    fi
    if [[ -f "/usr/lib/libcrypto.so.1.1" ]]; then
        echo "/usr/lib/libcrypto.so.1.1文件已存在，移动到/tmp。"
        sudo mv /usr/lib/libcrypto.so.1.1 /tmp
    fi
    sudo ln -s /usr/local/ssl/lib/libssl.so.1.1 /usr/lib/libssl.so.1.1
    sudo ln -s /usr/local/ssl/lib/libcrypto.so.1.1 /usr/lib/libcrypto.so.1.1

    # sudo mv /usr/bin/openssl /usr/bin/openssl.bak
    # sudo ln -s /usr/local/ssl/bin/openssl /usr/bin/openssl

    # openssl version -a

}

# 编译openssh
# TODO: 添加编译前判断是否已安装
InstallOpenssh() {
    mkdir /tmp/ssh_bak -p
    mkdir /tmp/ssh_bak/init.d -p
    sudo cp -r /etc/ssh /tmp/ssh_bak
    sudo cp /etc/init.d/ssh /tmp/ssh_bak/init.d

    if [[ ! -d openssh-${SSH_VERSION} ]]; then
        # openssh-10.0p2.tar.gz 解压目录 openssh-10.0p1 非标准
        echo "openssh-${SSH_VERSION} 目录不存在，请检查${WORK_DIR}目录！"
        exit 1
    fi

    cd "openssh-${SSH_VERSION}/" || exit
    ./configure --prefix=/usr/local --sysconfdir=/etc/ssh --with-ssl-dir=/usr/local/ssl --with-pam
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
    # 创建工作目录，创建前先判断
    if [[ -d ${WORK_DIR} ]]; then
        #statements
        mv "${WORK_DIR}" "${WORK_DIR_OLD}"
        mkdir "${WORK_DIR}"
    else
        mkdir "${WORK_DIR}"
    fi
    chmod 777 "${WORK_DIR}"

    # 切换到主目录
    cd "${WORK_DIR}" || exit
    # 下载源码包
    DownloadAllPackages

    # 安装 telnetd服务和依赖
    InstallTelnetd
    InstallDependentPackage

    # TODO: 内网如何安装deb包？

    # 编译
    # 不需要编译zlib，版本符合要求（Zlib 1.1.4 或 1.2.1.2 或更高版本（早期的 1.2.x 版本存在问题））
    # InstallZlib
    InstallOpenssl
    InstallOpenssh
}

# 检查参数
if [[ -z ${SSH_VERSION} ]]; then
    echo "未指定要安装的OpenSSH版本。"
    exit 1
fi

if [[ ${GET_SYSTEM_TYPE} =~ ${SYSTEM_UBUNTU} ]]; then
    # ubunt系统可执行
    GET_UBUNTU_CODENAME=$(lsb_release -c)
    GET_SSH_VERSION=$(ssh -V 2>&1)
    GET_SSHD_VERSION=$(sshd -V 2>&1 | sed -n '2p')
    if [[ ${GET_UBUNTU_CODENAME} =~ ${UBUNTU_CODENAME} ]]; then
        # ubuntu 16.04 才可执行
        if [[ ${GET_SSH_VERSION} == *"OpenSSH_${SSH_VERSION}"* ]] || [[ ${GET_SSHD_VERSION} == *"OpenSSH_${SSH_VERSION}"* ]]; then
            echo "Openssh已经更新到OpenSSH_${SSH_VERSION}版本!"
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
