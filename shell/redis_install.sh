#!/usr/bin/env bash

# ubuntu 下手动安装

set -euxo pipefail

# yum install systemd-devel -y

# ubuntu下安装
# sudo apt install libsystemd-dev

BASE_DIR=/data/redis
SCRIPT_DIR=$(readlink -e $(dirname $0))
VERSION=${VERSION:-7.0.2}
TYPE=${TYPE:-}

# if [ $# -gt 0 ]
# then
#   VERSION=$1
# else
#   VERSION=7.0.2
# fi


# 检查操作系统
# 判断系统
system=$(uname -a)

mac="Darwin"
centos="Centos"
ubuntu="Ubuntu"

if [[ ${system} =~ ${ubuntu} ]]; then
    OS=$ubuntu
    SERVICE_file="/lib/systemd/system/redis.service"
elif [[ ${system} =~ ${centos} ]];then
    OS=$centos
    SERVICE_file="/usr/lib/systemd/system/redis.service"
# elif [[ ${system} =~ ${mac} ]];then
#     OS=$mac
else
    echo "${system}"
    echo "暂时不支持该系统安装"
    exit 1
fi


usage() {
  echo "usage:"
  echo "${0}  [-v version] [-t install|delete]"
  echo -e "\nOptions:"
  echo -e "-t install|delete)"
  echo -e "-v 7.0.2 -t install|delete)"
  exit 1
}

redis_install(){
REDIS_SRC=redis-$VERSION.tar.gz
REDIS_DIR=${REDIS_SRC%.tar.gz}
INSTALL_DIR=$BASE_DIR
DATA_DIR=$BASE_DIR/data


if [ ! -f $REDIS_SRC ]
then
  wget http://download.redis.io/releases/$REDIS_SRC
fi
if [ -d $REDIS_DIR ]
then
  rm -rf $REDIS_DIR
fi
tar zxf $REDIS_SRC
cd $REDIS_DIR
make BUILD_WITH_SYSTEMD=yes USE_SYSTEMD=yes -j
make PREFIX=$INSTALL_DIR USE_SYSTEMD=yes install

mkdir -p $INSTALL_DIR/conf/
cp redis.conf $INSTALL_DIR/conf/

mkdir -p $BASE_DIR/bin
cd $BASE_DIR/bin

mkdir -p $DATA_DIR
cd $INSTALL_DIR

# 创建redis服务
sudo tee $SERVICE_file <<EOF
[Unit]
Description=Redis data structure server
Documentation=https://redis.io/documentation
#Before=your_application.service another_example_application.service
#AssertPathExists=/var/lib/redis
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=$INSTALL_DIR/bin/redis-server $INSTALL_DIR/conf/redis.conf --supervised systemd --daemonize no
LimitNOFILE=10032
NoNewPrivileges=yes
#OOMScoreAdjust=-900
#PrivateTmp=yes
Type=notify
TimeoutStartSec=infinity
TimeoutStopSec=infinity
UMask=0077
#User=redis
#Group=redis
#WorkingDirectory=/var/lib/redis

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable redis.service
systemctl start redis.service
  
}

install_redis() {
  # 安装依赖项
  case $OS in
  "Ubuntu")
      # ubuntu下安装
      sudo apt install libsystemd-dev
      ;;
  "Centos")
      yum install systemd-devel -y
      ;;
  esac

  redis_install
}

delete_redis(){
  systemctl stop redis.service
  systemctl disable redis.service

  rm -rf $SERVICE_file
  systemctl daemon-reload

  rm -rf /data/redis
}

while getopts 'v:t:' opt; do
  case $opt in
  v)
    VERSION=$OPTARG
    ;;
  t)
    TYPE=$OPTARG
    ;;
  ?)
    usage
    ;;
  esac
done


if [[ $TYPE == "delete" ]]; then
  delete_redis
elif [[ $TYPE == "install" ]]; then
  install_redis
else
  usage
fi