# 文件说明

## xxljob mysql
setup_origin.sh         控制MySQL初始化启动脚本

privileges_origin.sql   用户权限

schema.sql              xxljob 2.4.0 对应数据库配置

## nacos mysql

nacos-init.sql  nacos数据库初始化sql 2.2.1


## nacos & xxljob mysql整合

setup.sh         控制MySQL初始化启动脚本

privileges.sql   用户权限sql


# 3.0环境 xxljob和nacos共用一个mysql

## 1.通过自定义脚本初始化
### 1.1调整setup.sh,将nacos初始化sql导入

```bash
echo '2.start importing data....'
mysql < /mysql/schema.sql
mysql < /mysql/nacos-init.sql
echo '3.end importing data....'
```

### 1.2调整privileges.sql,将xxljob用户和nacos用户创建


```sql
grant all privileges on *.* to xxljob@'%' identified by 'xxljob';
grant all privileges on *.* to nacos@'%' identified by 'nacos';

flush privileges;
```



### 1.3 dockerfile

```dockerfile
FROM mysql:5.7-debian
#设置免密登录
ENV MYSQL_ALLOW_EMPTY_PASSWORD yes
#将所需文件放到容器中
COPY setup.sh privileges.sql schema.sql nacos-init.sql /mysql/
#设置容器启动时执行的命令
CMD ["sh", "/mysql/setup.sh"]

```

### 1.4 构建镜像

```bash
docker build -t mysql:5.7-debian-custom .
```

### 1.5 验证镜像

```bash
docker rmi mysql:5.7-debian-custom
docker build -t mysql:5.7-debian-custom .

docker run -itd --name testtest  mysql:5.7-debian-custom
docker logs -f testtest

```


### 1.6 问题记录

启动构建后的镜像，查看日志，发现报错，导入 nacos-init.sql 异常

```
CREATE database if' at line 2
ERROR 1133 (42000) at line 18: Can't find any matching row in the user table
```
该报错会导致导入sql中断，后续该数据库中的表全部未创建
```
mysql> use nacos_config;
Database changed
mysql> show tables;
Empty set (0.00 sec)

```

查看对应第18行内容
```
GRANT ALL PRIVILEGES ON `nacos_config`.* TO 'nacos'@'%';
```

这个报错是由于将权限分配给一个不存在的用户导致的，会中断sql的导入

解决方法：

需要先创建用户，再执行授权

先导入 privileges.sql，再初始化数据库

调整执行的setup.sh脚本

```bash
#!/bin/bash

echo 'checking mysql status.'
service mysql status

echo '1.start mysql....'
service mysql start
sleep 10
service mysql status

echo '2.start changing password....'
mysql < /mysql/privileges.sql
echo '3.end changing password....'

sleep 3
service mysql status

echo '4.start importing data....'
mysql < /mysql/schema.sql
mysql < /mysql/nacos-init.sql
echo '5.end importing data....'

sleep 3
service mysql status
echo 'mysql is ready'

tail -f /dev/null
```




## 2.通过mysql镜像的docker-entrypoint.sh初始化

### 2.1 初始化逻辑

会根据 /docker-entrypoint-initdb.d 目录中的文件执行初始化操作

### 2.2 dockerfile

```dockerfile
FROM mysql:5.7-debian
#设置免密登录
ENV MYSQL_ALLOW_EMPTY_PASSWORD yes
#将所需文件放到容器中
COPY privileges.sql schema.sql nacos-init.sql /docker-entrypoint-initdb.d/
```

### 2.3 构建镜像

```bash
docker build -t mysql:5.7-debian-custom .
```

### 2.4 问题

通过自身的entrypoint脚本运行，需要指定变量
```
swift@JENKINS-003:/tmp/middleware-mysql$ docker logs -f testtest
2024-01-31 11:29:01+00:00 [Note] [Entrypoint]: Entrypoint script for MySQL Server 5.7.42-1debian10 started.
2024-01-31 11:29:01+00:00 [Note] [Entrypoint]: Switching to dedicated user 'mysql'
2024-01-31 11:29:01+00:00 [Note] [Entrypoint]: Entrypoint script for MySQL Server 5.7.42-1debian10 started.
2024-01-31 11:29:01+00:00 [ERROR] [Entrypoint]: Database is uninitialized and password option is not specified
    You need to specify one of the following as an environment variable:
    - MYSQL_ROOT_PASSWORD
    - MYSQL_ALLOW_EMPTY_PASSWORD
    - MYSQL_RANDOM_ROOT_PASSWORD
```

设置免密变量 MYSQL_ALLOW_EMPTY_PASSWORD

删除容器
删除镜像
修改dockerfile
重新build
启动容器

查看日志

```bash
docker rm -f testtest

docker rmi mysql:5.7-debian-custom

docker build -t mysql:5.7-debian-custom .

docker run -itd --name testtest  mysql:5.7-debian-custom

docker logs -f testtest
```


无法启动，导入sql失败，还是由于nacos-init.sql导致的，估计三个sql文件排序，nacos-init.sql排第一个了
```
Warning: Unable to load '/usr/share/zoneinfo/zone1970.tab' as time zone. Skipping it.

2024-01-31 11:31:43+00:00 [Note] [Entrypoint]: /usr/local/bin/docker-entrypoint.sh: running /docker-entrypoint-initdb.d/nacos-init.sql
ERROR 1133 (42000) at line 18: Can't find any matching row in the user table

Status information:
```

查看排序
```
$ ls *.sql|sort
nacos-init.sql
privileges.sql
schema.sql
```

如果要采用这种方式，两种解决方案
1.整合sql

2.想办法调整导入顺序
