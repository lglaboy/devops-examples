#!/usr/bin/env bash
set -euxo pipefail

# 1. 下载 clamav1.1.1 版本
curl -L -o ./clamav-1.1.1.linux.x86_64.rpm https://www.clamav.net/downloads/production/clamav-1.1.1.linux.x86_64.rpm

# 2. 安装clamav
rpm -ivh clamav-1.1.1.linux.x86_64.rpm

# 3. 创建clamav用户
groupadd clamav || true
useradd -g clamav -s /bin/false -c "Clam Antivirus" clamav || true

# 4. 创建文件夹
BASEDIR=/data/clamav

mkdir -p $BASEDIR
mkdir -p $BASEDIR/log
mkdir -p $BASEDIR/lib/clamav
mkdir -p $BASEDIR/etc

LOGDIR=$BASEDIR/log
CONFIGDIR=$BASEDIR/etc
LOGDIRREG=$(echo $LOGDIR | sed 's/\//\\\//g')
DATADIR=$BASEDIR/lib/clamav
DATADIRREG=$(echo $DATADIR | sed 's/\//\\\//g')

# 5. 创建clamav日志文件
touch $LOGDIR/clamd.log
touch $LOGDIR/freshclam.log
chown clamav:clamav $LOGDIR/clamd.log
chown clamav:clamav $LOGDIR/freshclam.log
chmod 600 $LOGDIR/clamd.log
chmod 600 $LOGDIR/freshclam.log

# 6.
chown clamav:clamav $DATADIR

# 6. 创建clamav配置文件
cp /usr/local/etc/clamd.conf.sample $CONFIGDIR/clamd.conf
cp /usr/local/etc/freshclam.conf.sample $CONFIGDIR/freshclam.conf

# 7. 修改clamav配置文件
sed -i 's/^Example/#Example/g' $CONFIGDIR/clamd.conf
sed -i 's/^Example/#Example/g' $CONFIGDIR/freshclam.conf
#sed -i 's/^#LocalSocket \/tmp\/clamd.socket/LocalSocket \/var\/run\/clamd.sock/g' $CONFIGDIR/clamd.conf
sed -i 's/^#TCPSocket 3310/TCPSocket 3310/g' $CONFIGDIR/clamd.conf
sed -i 's/^#Foreground yes/Foreground yes/g' $CONFIGDIR/clamd.conf
sed -i 's/^#Foreground yes/Foreground yes/g' $CONFIGDIR/freshclam.conf
sed -i 's/^#DatabaseMirror database.clamav.net/DatabaseMirror database.clamav.net/g' $CONFIGDIR/freshclam.conf
sed -i 's/^#UpdateLogFile \/var\/log\/freshclam.log/UpdateLogFile $LOGDIRREG\/freshclam.log/g' $CONFIGDIR/freshclam.conf
sed -i 's/^#LogFile \/tmp\/clamd.log/LogFile $LOGDIRREG\/clamd.log/g' $CONFIGDIR/clamd.conf
sed -i 's/^#LogTime yes/LogTime yes/g' $CONFIGDIR/clamd.conf
sed -i 's/^#LogTime yes/LogTime yes/g' $CONFIGDIR/freshclam.conf
sed -i 's/^#PidFile \/var\/run\/clamd.pid/PidFile \/var\/run\/clamd.pid/g' $CONFIGDIR/clamd.conf
sed -i 's/^#PidFile \/var\/run\/freshclam.pid/PidFile \/var\/run\/freshclam.pid/g' $CONFIGDIR/freshclam.conf
sed -i 's/^#DatabaseDirectory \/var\/lib\/clamav/DatabaseDirectory '$DATADIRREG'/g' $CONFIGDIR/clamd.conf
sed -i 's/^#DatabaseDirectory \/var\/lib\/clamav/DatabaseDirectory '$DATADIRREG'/g' $CONFIGDIR/freshclam.conf
sed -i 's/^#User clamav/User clamav/g' $CONFIGDIR/clamd.conf
sed -i 's/^#ScanMail yes/ScanMail no/g' $CONFIGDIR/clamd.conf
sed -i 's/^#ScanArchive yes/ScanArchive yes/g' $CONFIGDIR/clamd.conf
sed -i 's/^#MaxDirectoryRecursion 20/MaxDirectoryRecursion 20/g' $CONFIGDIR/clamd.conf
sed -i 's/^#FollowDirectorySymlinks yes/FollowDirectorySymlinks yes/g' $CONFIGDIR/clamd.conf
sed -i 's/^#FollowFileSymlinks yes/FollowFileSymlinks yes/g' $CONFIGDIR/clamd.conf
sed -i 's/^#ReadTimeout 300/ReadTimeout 300/g' $CONFIGDIR/clamd.conf
sed -i 's/^#ReceiveTimeout 300/ReceiveTimeout 300/g' $CONFIGDIR/freshclam.conf
sed -i 's/^#LogClean yes/LogClean yes/g' $CONFIGDIR/clamd.conf
sed -i 's/^#LogVerbose yes/LogVerbose yes/g' $CONFIGDIR/clamd.conf
sed -i 's/^#LogVerbose yes/LogVerbose yes/g' $CONFIGDIR/freshclam.conf
sed -i 's/^#LogSyslog yes/LogSyslog yes/g' $CONFIGDIR/clamd.conf
sed -i 's/^#LogSyslog yes/LogSyslog yes/g' $CONFIGDIR/freshclam.conf
sed -i 's/^#LogRotate yes/LogRotate yes/g' $CONFIGDIR/clamd.conf
sed -i 's/^#LogRotate yes/LogRotate yes/g' $CONFIGDIR/freshclam.conf
sed -i 's/^#LogFileMaxSize 2M/LogFileMaxSize 2M/g' $CONFIGDIR/clamd.conf
sed -i 's/^#LogFileMaxSize 2M/LogFileMaxSize 2M/g' $CONFIGDIR/freshclam.conf

# 8. 创建clamav-freshclam.service
cat > /usr/lib/systemd/system/clamav-freshclam.service <<EOF
[Unit]
Description=ClamAV virus database updater
Documentation=man:freshclam(1) man:freshclam.conf(5) https://docs.clamav.net/
# If user wants it run from cron, don't start the daemon.
# ConditionPathExists=!/etc/cron.d/clamav-update
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/local/bin/freshclam -d --foreground=true --config-file=$CONFIGDIR/freshclam.conf

[Install]
WantedBy=multi-user.target
EOF

# 8. 创建 clamd.service
cat > /usr/lib/systemd/system/clamd.service <<EOF
[Unit]
Description = clamd scanner daemon
Documentation=man:clamd(8) man:clamd.conf(5) https://www.clamav.net/documents/
After = syslog.target nss-lookup.target network.target

[Service]
Type=forking
ExecStart = /usr/local/sbin/clamd -c $CONFIGDIR/clamd.conf
# Reload the database
ExecReload=/bin/kill -USR2 \$MAINPID
Restart = on-failure
TimeoutStartSec=420

[Install]
WantedBy = multi-user.target
EOF

# 9. 启动 clamav-freshclam.service clamd.service
systemctl daemon-reload

systemctl start clamav-freshclam.service
systemctl start clamd.service

# 10. 设置 clamav-freshclam.service clamd.service 开机启动
systemctl enable clamav-freshclam.service
systemctl enable clamd.service


# 更新病毒库
# cd /var/lib/clamav
# curl -L -o main.cvd http://database.clamav.net/main.cvd
# curl -L -o daily.cvd http://database.clamav.net/daily.cvd
# curl -L -o bytecode.cvd http://database.clamav.net/bytecode.cvd

