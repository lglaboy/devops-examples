基于 swr.cn-east-2.myhuaweicloud.com/common-server/rocketmq-console:1 镜像，更新wget,git和git-man软件包，打包并上传为 swr.cn-east-2.myhuaweicloud.com/common-server/rocketmq-console:1-fix

修复漏洞:

Wget缓冲区溢出漏洞(CVE-2017-13089)

Wget缓冲区溢出漏洞(CVE-2017-13090)

Git命令注入漏洞(CVE-2017-14867)


打包

```shell
docker build -t swr.cn-east-2.myhuaweicloud.com/common-server/rocketmq-console:1-fix .
```


容器内的源

```
root@localhost:/# cat /etc/apt/sources.list
deb http://deb.debian.org/debian jessie main
deb http://deb.debian.org/debian jessie-updates main
deb http://security.debian.org jessie/updates main
```

参考: https://developer.aliyun.com/mirror/debian

将以下内容插入到文件最前面

debian 8.x (jessie)

编辑/etc/apt/sources.list文件(需要使用sudo), 在文件最前面添加以下条目(操作前请做好相应备份)

```
deb https://mirrors.aliyun.com/debian-archive/debian/ jessie main non-free contrib
deb-src https://mirrors.aliyun.com/debian-archive/debian/ jessie main non-free contrib
```

使用https的地址，安装报错

```
E: The method driver /usr/lib/apt/methods/https could not be found.
N: Is the package apt-transport-https installed?
```

调整为http的地址

```
deb http://mirrors.aliyun.com/debian-archive/debian/ jessie main non-free contrib
deb-src http://mirrors.aliyun.com/debian-archive/debian/ jessie main non-free contrib
```


build 卡住

```
100% [Waiting for headers]
100% [Connecting to deb.debian.org (151.101.90.132)]

```

查看/etc/apt/下还有那个文件中使用了 deb.debian.org ,还有一个/etc/apt/sources.list.d/jessie-backports.list

```
root@localhost:/# grep deb.debian.org /etc/apt/* -R
/etc/apt/sources.list:deb http://deb.debian.org/debian jessie main
/etc/apt/sources.list:deb http://deb.debian.org/debian jessie-updates main
/etc/apt/sources.list.d/jessie-backports.list:deb http://deb.debian.org/debian jessie-backports main
```


报错

```
W: GPG error: http://mirrors.aliyun.com jessie Release: The following signatures were invalid: KEYEXPIRED 1587841717
/bin/sh: 1: sudo: not found
```

Dockerfile 中的命令有问题，不需要使用sudo，容器内没有这个命令，取消即可


报错

```
WARNING: The following packages cannot be authenticated!
  wget git
E: There are problems and -y was used without --force-yes
```

`apt-get install --only-upgrade -y git wget` 中添加 --force-yes ,即 `apt-get install --only-upgrade --force-yes -y git wget`


成功日志

```
swift@JENKINS-003:/tmp/test_rocketmq_console$ docker build -t swr.cn-east-2.myhuaweicloud.com/common-server/rocketmq-console:1-fix .
Sending build context to Docker daemon   2.56kB
Step 1/2 : FROM swr.cn-east-2.myhuaweicloud.com/common-server/rocketmq-console:1
 ---> a2ec2341aa9e
Step 2/2 : RUN echo 'deb http://mirrors.aliyun.com/debian-archive/debian/ jessie main non-free contrib' > /etc/apt/sources.list     && echo 'deb-src http://mirrors.aliyun.com/debian-archive/debian/ jessie main non-free contrib' >> /etc/apt/sources.list     && rm -rf /etc/apt/sources.list.d/jessie-backports.list     && DEBIAN_FRONTEND=noninteractive apt-get update     && DEBIAN_FRONTEND=noninteractive apt-get install --only-upgrade --force-yes -y git wget
 ---> Running in 9a4f5ead8b49
Ign http://mirrors.aliyun.com jessie InRelease
Get:1 http://mirrors.aliyun.com jessie Release.gpg [2420 B]
Get:2 http://mirrors.aliyun.com jessie Release [148 kB]
Ign http://mirrors.aliyun.com jessie Release
Get:3 http://mirrors.aliyun.com jessie/main Sources [9169 kB]
Get:4 http://mirrors.aliyun.com jessie/non-free Sources [119 kB]
Get:5 http://mirrors.aliyun.com jessie/contrib Sources [58.9 kB]
Get:6 http://mirrors.aliyun.com jessie/main amd64 Packages [9098 kB]
Get:7 http://mirrors.aliyun.com jessie/non-free amd64 Packages [101 kB]
Get:8 http://mirrors.aliyun.com jessie/contrib amd64 Packages [59.2 kB]
Fetched 18.8 MB in 7s (2598 kB/s)
Reading package lists... Done
W: GPG error: http://mirrors.aliyun.com jessie Release: The following signatures were invalid: KEYEXPIRED 1587841717
Reading package lists... Done
Building dependency tree
Reading state information... Done
Suggested packages:
  gettext-base git-daemon-run git-daemon-sysvinit git-doc git-el git-email
  git-gui gitk gitweb git-arch git-cvs git-mediawiki git-svn
Recommended packages:
  patch less rsync
The following packages will be upgraded:
  git wget
2 upgraded, 0 newly installed, 0 to remove and 88 not upgraded.
Need to get 4203 kB of archives.
After this operation, 367 kB of additional disk space will be used.
WARNING: The following packages cannot be authenticated!
  wget git
Get:1 http://mirrors.aliyun.com/debian-archive/debian/ jessie/main wget amd64 1.16-1+deb8u5 [496 kB]
Get:2 http://mirrors.aliyun.com/debian-archive/debian/ jessie/main git amd64 1:2.1.4-2.1+deb8u6 [3707 kB]
Fetched 4203 kB in 0s (4405 kB/s)
debconf: delaying package configuration, since apt-utils is not installed
(Reading database ... 17571 files and directories currently installed.)
Preparing to unpack .../wget_1.16-1+deb8u5_amd64.deb ...
Unpacking wget (1.16-1+deb8u5) over (1.16-1+deb8u1) ...
Preparing to unpack .../git_1%3a2.1.4-2.1+deb8u6_amd64.deb ...
Unpacking git (1:2.1.4-2.1+deb8u6) over (1:2.1.4-2.1+deb8u2) ...
Setting up wget (1.16-1+deb8u5) ...
Setting up git (1:2.1.4-2.1+deb8u6) ...
Removing intermediate container 9a4f5ead8b49
 ---> 6c7c6bbc88d8
Successfully built 6c7c6bbc88d8
Successfully tagged swr.cn-east-2.myhuaweicloud.com/common-server/rocketmq-console:1-fix
```


对比添加清理命令，是否会使镜像最终变小

```
    # && apt-get clean \
    # && rm -rf /var/lib/apt/lists/*
```

```
# 无apt-get clean和rm -rf
swr.cn-east-2.myhuaweicloud.com/common-server/rocketmq-console                                1-fix                          94ab3fd81dfb        3 minutes ago       781MB

# 有apt-get clean和rm -rf
swr.cn-east-2.myhuaweicloud.com/common-server/rocketmq-console                                1-fix                          4cb5fcbe4066        14 seconds ago      763MB

# 能少一部份
```