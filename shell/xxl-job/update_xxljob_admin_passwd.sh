#!/bin/bash
# Date: 2023-05-24 22:15
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: update xxljob user passwd
# Version: v1.0

# 使用说明
usage() {
  echo "usage:"
  echo "${0}  [-i address ] [-u username] [-p password] [-n newpassword]"
  echo -e "\nOptions:"

  echo -e "-i address       xxljob address (default \"all\" 获取所有环境拼接地址)"
  echo -e "-u username      用户名(default \"admin\")"
  echo -e "-p password      密码(default \"123456\")"
  echo -e "-n newpassword   新密码"
  echo -e "\nEg:"
  echo "修改指定地址,指定用户的密码"
  echo "${0} -i http://192.168.1.105:10116/xxl-job-admin -u admin -p 123456 -n newpassword"
  echo ""
  echo "修改指定地址的admin密码,使用默认值,默认用户 admin, 默认密码 123456"
  echo "${0} -i http://192.168.1.105:10116/xxl-job-admin -n newpassword"
  echo ""
  echo "修改所有环境的用户密码, 使用指定用户名, 指定用户密码的方式修改"
  echo "${0} -u admin -p 123456 -n newpassword"
  echo ""
  echo "修改所有环境的admin用户密码, 使用默认值, 用户名: admin, 密码: 123456"
  echo "${0} -n newpassword"
  
  exit 1
}

# 解析和处理命令行参数
while getopts 'i:u:p:n:' opt; do
  case $opt in
  i)
    ADDRESS=$OPTARG
    ;;
  u)
    USER_NAME=$OPTARG
    ;;
  p)
    PASSWD=$OPTARG
    ;;
  n)
    PASSWD_NEW=$OPTARG
    ;;
  ?)
    usage
    ;;
  esac
done

# 定义常量
# 临时管理员用户名
TEMP_NAME=tempuser
# 临时管理员密码
TEMP_PASSWD="5cG7OsR6"
# 日志文件
LOG_FILE="$(pwd)/update_xxljob_passwd.log"

ADDRESS=${ADDRESS:-"all"}
# 定义用户名
USER_NAME=${USER_NAME:-"admin"}
# 定义用户密码
PASSWD=${PASSWD:-"123456"}
# 定义admin用户新密码
# PASSWD_NEW=${PASSWD_NEW}
# admin_passwd_new="newpassword"


# 备份日志文件
bak_log_file() {
    if [ -f "${LOG_FILE}" ];then
        mv "${LOG_FILE}" "${LOG_FILE}_$(date +%s)"
    fi
}

logging() {
    local data
    data=$1
    echo "$(date "+%Y-%m-%d %H:%M:%S") : ${data}"
    echo "$(date "+%Y-%m-%d %H:%M:%S") : ${data}" >> "${LOG_FILE}"
}

# 通过创建临时管理员用户修改admin用户密码
# TODO(mrmonkey): 功能不合理,暂未使用,未统一调整 (bug ####)
update_xxljob_admin_passwd() {
    local url=$1
    local admin_name=admin
    local admin_passwd=123456
    local admin_passwd_new=newpassword
    logging "操作地址: ${url}"

    # 判断地址是否正确，http://xxljob-prod.xxxx.xxxxxxxx.cn/xxl-job-admin/toLogin 判断状态码是不是200
    if [ $(curl ${url}/toLogin -w '%{http_code}\n' -s -o /dev/null) != "200" ]; then
        logging "地址无法访问: ${url}/toLogin"
        return 1
    fi

    # 1.获取admin管理员的cookie
    logging "获取管理员用户: ${admin_name} 的cookie"
    admin_cookie=$(curl -X POST --form 'userName='${admin_name}'' --form 'password='${admin_passwd}'' "${url}/login" -i -s | grep Cookie | awk '{print $2}')

    if [ -z "$admin_cookie" ]; then
        logging "密码不正确: ${admin_passwd}"
        return 1
    fi

    # 2.创建另一个管理员用户
    logging "创建管理员用户: ${TEMP_NAME}"
    curl -X POST -H "Cookie: ${admin_cookie}" --form 'username='${TEMP_NAME}'' --form 'password='${TEMP_PASSWD}'' --form 'role="1"' --form 'permission=""' ${url}/user/add -w '\n'

    # 3.获取另一个管理员用户的cookie
    logging "获取管理员用户: ${TEMP_NAME} 的cookie"
    temp_admin_cookie=$(curl -X POST --form 'userName='${TEMP_NAME}'' --form 'password='${TEMP_PASSWD}'' ${url}/login -i -s | grep Cookie | awk '{print $2}')

    # 4.获取修改用户的id
    logging "获取管理员用户: ${admin_name} 的id"
    admin_user_id=$(curl -X POST -H "Cookie: ${temp_admin_cookie}" --form 'username='${admin_name}'' --form 'role=-1' --form 'start=0' --form 'length=10' ${url}/user/pageList -s | jq | grep id | awk '{print $NF}' | awk -F "," '{print $1}')

    # 5.利用另一个管理员用户的cookie修改admin管理员的密码
    logging "修改管理员用户: ${admin_name} 的密码为: ${admin_passwd_new}"
    curl -X POST -H "Cookie: ${temp_admin_cookie}" --form 'username='${admin_name}'' --form 'password='${admin_passwd_new}'' --form 'id='${admin_user_id}'' --form 'role="1"' --form 'permission=""' ${url}/user/update -w '\n'

    # TODO: 暂时不删除创建的用户
    # # 6.获取admin用户cookie
    # admin_cookie=$(curl -X POST  --form 'userName='${admin_name}'' --form 'password='${admin_passwd_new}'' ${url}/login -i -s|grep Cookie|awk '{print $2}')

    # # 7.获取tempadmin用户id
    # temp_user_id=$(curl -X POST -H "Cookie: ${admin_cookie}" --form 'username='${TEMP_NAME}'' --form 'role=-1' --form 'start=0' --form 'length=10' ${url}/user/pageList -s|jq|grep id|awk '{print $NF}'|awk -F "," '{print $1}')
    # logging "获取tempadmin用户: ${temp_user_id}"

    # # 8.删除tempadmin用户
    # logging "删除tempadmin用户"
    # curl -X POST -H "Cookie: ${admin_cookie}" --form 'id='${temp_user_id}'' ${url}/user/remove
}

# 修改当前用户的密码
update_user_passwd() {
    local url=$1

    logging "操作地址: ${url}"

    # 判断地址是否正确，http://xxljob-prod.xxxx.xxxxxxxx.cn/xxl-job-admin/toLogin 判断状态码是不是200
    if [ $(curl ${url}/toLogin -w '%{http_code}\n' -s -o /dev/null) != "200" ]; then
        logging "地址无法访问: ${url}/toLogin"
        return 1
    fi

    # 1.获取用户cookie
    logging "获取用户: ${USER_NAME} 的cookie"
    cookie=$(curl -X POST --form 'userName='"${USER_NAME}"'' --form 'password='"${PASSWD}"'' "${url}/login" -i -s | grep Cookie | awk '{print $2}')

    if [ -z "$cookie" ]; then
        logging "密码不正确: ${PASSWD}"
        return 1
    fi

    # 2.修改当前用户密码
    logging "修改用户: ${USER_NAME} 的密码为: ${PASSWD_NEW}"
    curl -X POST -H "Cookie: ${cookie}" --form 'password='"${PASSWD_NEW}"'' "${url}/user/updatePwd" -w '\n'
}

# get_env_xxljob_address
get_env_xxljob_address() {
    for i in $(tools -t env | grep prod | grep -v sit | awk -F "|" '{print $2}' | sed 's/ //g' | sort); do 
        echo "http://xxljob-$i.xxxx.xxxxxxxx.cn/xxl-job-admin"
    done
}

main(){
    bak_log_file

    for i in $(get_env_xxljob_address);do
        update_user_passwd "$i" "$USER_NAME" "$PASSWD" "$PASSWD_NEW"
    done
}

if [ -z "${PASSWD_NEW}" ];then
    echo "-n newpassword 为必填项."
    exit 1
fi

if [ "$ADDRESS" == "all" ];then
    logging "自动获取所有环境地址进行修改"
    main
else
    update_user_passwd "$ADDRESS"
fi