#!/bin/bash

# 判断系统
UBUNTU_CODENAME="xenial"
GET_UBUNTU_CODENAME=$(lsb_release -c)

if [[ ${GET_UBUNTU_CODENAME} =~ ${UBUNTU_CODENAME} ]]; then
    :
else
    echo "Ubuntu系统非${UBUNTU_CODENAME}，退出执行！"
    exit 1
fi

# install telnetd
sudo dpkg -i -R telnetd-deb

# install openssh 服务
sudo dpkg -i -R openssh-deep

# install openssl
tar -xzf openssl-1.1.1w.tar.gz
cd openssl-1.1.1w || exit 1
./config shared --prefix=/usr/local/ssl
make -j
make test
sudo make install
cd ..

sudo ln -s /usr/local/ssl/lib/libssl.so.1.1 /usr/lib/libssl.so.1.1
sudo ln -s /usr/local/ssl/lib/libcrypto.so.1.1 /usr/lib/libcrypto.so.1.1

# install openssh
mkdir /tmp/ssh_bak -p
mkdir /tmp/ssh_bak/init.d -p
sudo cp -r /etc/ssh /tmp/ssh_bak
sudo cp /etc/init.d/ssh /tmp/ssh_bak/init.d

tar -xzf openssh-9.8p1.tar.gz
cd openssh-9.8p1 || exit 1
./configure --prefix=/usr/local --sysconfdir=/etc/ssh --with-ssl-dir=/usr/local/ssl --with-pam
make -j
sudo make install
cd ..

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

echo "安装成功"
