#!/bin/bash
# 系统安全加固（System Security Hardening）


function info {
        echo ""
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>系统基本信息<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
        hostname=$(uname -n)
        system=$(cat /etc/os-release | grep "^NAME" | awk -F\" '{print $2}')
        version=$(cat /etc/os-release | grep "VERSION_ID" | awk -F'"' '{print $2}')
        kernel=$(uname -r)
        platform=$(uname -p)
        address=$(ip addr | grep inet | grep -v "inet6" | grep -v "127.0.0.1" | awk '{ print $2; }' | tr '\n' '\t' )
        cpumodel=$(cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq)
        cpu=$(cat /proc/cpuinfo | grep 'processor' | sort | uniq | wc -l)
        machinemodel=$(sudo dmidecode | grep "Product Name" | sed 's/^[ \t]*//g' |head -n 1| tr '\n' '\t' )
        date=$(date)

        echo "主机名:           $hostname"
        echo "系统名称:         $system"
        echo "系统版本:         $version"
        echo "内核版本:         $kernel"
        echo "系统类型:         $platform"
        echo "本机IP地址:       $address"
        echo "CPU型号:         $cpumodel"
        echo "CPU核数:          $cpu"
        echo "机器型号:         $machinemodel"
        echo "系统时间:         $date"
        echo " "
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>资源使用情况<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
        summemory=$(free -h |grep "Mem:" | awk '{print $2}')
        freememory=$(free -h |grep "Mem:" | awk '{print $4}')
        usagememory=$(free -h |grep "Mem:" | awk '{print $3}')
        uptime=$(uptime | awk '{print $2" "$3" "$4" "$5}' | sed 's/,$//g')
        loadavg=$(uptime | awk '{print $9" "$10" "$11" "$12" "$13}')

        echo "总内存大小:           $summemory"
        echo "已使用内存大小:       $usagememory"
        echo "可使用内存大小:       $freememory"
        echo "系统运行时间:         $uptime"
        echo "系统负载:             $loadavg"
}

echoGreen() { echo $'\e[1;32m'"$1"$'\e[0m'; }
echoYellow() { echo $'\e[0;33m'"$1"$'\e[0m'; }
echoRed() { echo $'\e[0;31m'"$1"$'\e[0m'; }

# info
version=$(cat /etc/os-release | grep "VERSION_ID" | awk -F'"' '{print $2}'|awk -F '.' '{print $1}')

# 修改指定key的value
function set_key_value() {
    local conf_file=${1} 
    local key=${2}
    local value=${3}   
    if [ -n $value ]; then
      local current=$(sed -n -e "s/^\($key = \)\([^ ']*\)\(.*\)$/\2/p" ${conf_file})
      local current_key=$(grep ^$key ${conf_file})
      if [ -n $current ];then
        value="$(echo "${value}" | sed 's|[&]|\\&|g')"
        if [[ ${current_key} =~ "=" ]];then
            sudo sed -i "s|^${key}\([ ]*\)=.*|${key} = ${value}|" ${conf_file}
        elif [[ ! ${current_key} =~ "=" ]];then
            sudo sed -i "s|^${key}\([ ]*\).*|${key}   ${value}|" ${conf_file}
        fi
        current_key_a=$(grep ^$key ${conf_file})
        echoGreen "已修改为${current_key_a}"
      fi
    fi
}

function ubuntu_check(){
    if [[ ${version} -eq 16 ]];then
        echo 1604
    elif [[ ${version} -eq 18 ]];then
        echo 1804
    elif [[ ${version} -eq 20 ]];then
        echo 2004
    fi
}

### 检查是否设置口令生存周期
function pass_max_days(){
    #PASS_MAX_DAYS 表示密码最长使用期限
    local cfgfile=/etc/login.defs
    pass_max_days_value=`grep -i ^PASS_MAX_DAYS ${cfgfile} | awk '{print $2}' |sed 's/^[ \t]*//g'`
    if [ ${pass_max_days_value} == "" ];then
        echoRed "不存在PASS_MAX_DAYS参数 需要添加"
        sudo sed -i '$aPASS_MAX_DAYS 90' ${cfgfile}
    elif [ ${pass_max_days_value} != "" ] && [ ${pass_max_days_value} -ne 90 ];then
        echoYellow "存在PASS_MAX_DAYS参数 值为：${pass_max_days_value},需要整改"
        set_key_value ${cfgfile} PASS_MAX_DAYS 90
    elif [ ${pass_max_days_value} -eq 90 ];then
        echoGreen "存在PASS_MAX_DAYS参数 值为： ${pass_max_days_value},符合等保要求"
    fi
}

### 检查是否设置口令更改最小间隔天数
function pass_min_days(){
    #PASS_MIN_DAYS 表示密码最短使用期限
    local cfgfile=/etc/login.defs
    pass_min_days_value=`grep -i ^PASS_MIN_DAYS ${cfgfile} | awk '{print $2}' |sed 's/^[ \t]*//g'`
    if [ ${pass_min_days_value} == "" ];then
        echoRed "不存在PASS_MIN_DAYS参数 需要添加"
        sudo sed -i '$aPASS_MIN_DAYS 90' ${cfgfile}
    elif [ ${pass_min_days_value} != "" ] && [ ${pass_min_days_value} -le 2 ];then
        echoYellow "存在PASS_MIN_DAYS参数 值为：${pass_min_days_value},需要整改"
        set_key_value ${cfgfile} PASS_MIN_DAYS 10
    elif [ ${pass_min_days_value} -le 90 ];then
        echoGreen "存在PASS_MIN_DAYS参数 值为： ${pass_min_days_value},符合等保要求"
    fi
}

### 检查用户目录缺省访问权限设置
function login_umask(){
    #获取umask值
    local cfgfile=/etc/login.defs
    local umask=`grep -i ^umask ${cfgfile} | awk '{print $2}' |sed 's/^[ \t]*//g'`
    
    if [[ ${umask} == "" ]];then
        echoRed "不存在umask参数 需要添加"
        sudo sed -i '$aUMASK 027' ${cfgfile}
    elif [[ ${umask} != "" ]] && [[ ${umask} != "027" ]];then
        echoYellow "存在umask参数 值为：${umask},需要整改"
        set_key_value ${cfgfile} UMASK 027
    elif [[ ${umask} == "027" ]];then
        echoGreen "存在umask参数 值为： ${umask},符合等保要求"
    fi
    ### 获取文件权限数值
    local permission_value=$(stat -c %a ${cfgfile})
    # local permission_value=$(ls -l ${cfgfile} | cut -c1-10|tr "rwx-" "4210"|awk -F "" '{print $1+$2+$3$4+$5+$6$7+$8+$9}')
    if [[ ${permission_value} == "750" ]];then
        echoGreen "${cfgfile} 文件权限为：${permission_value}，符合等保要求" 
    else
        echoYellow "${cfgfile} 文件权限为：${permission_value}，需要整改"
        sudo chmod 750 ${cfgfile}
    fi
}

### 检查是否使用PAM认证模块禁止wheel组之外的用户su为root
function wheel(){
    local cfgfile=/etc/pam.d/su
    local wheel_a=$(grep -i ^auth.*sufficient.*pam_rootok.so ${cfgfile} | wc -l)
    local wheel_b=$(grep -i ^auth.*required.*pam_wheel.so.*group=wheel ${cfgfile} | wc -l)
    local wheel_c=$(grep -i ^auth.*required.*pam_wheel.so.*use_uid ${cfgfile} | wc -l)
    if [ ${wheel_a} -eq 0 ];then
        echoYellow "su文件${cfgfile}中需要添加 auth sufficient pam_rootok.so配置"
        sudo sed -i '$aauth sufficient pam_rootok.so' ${cfgfile}
    fi
    if [ ${wheel_a} -eq 1 ];then
        if [ ${wheel_b} -eq 0 ] && [ ${wheel_c} -eq 0 ];then
            echoYellow "su文件${cfgfile}中需要添加 auth required pam_wheel.so group=wheel 或 auth required pam_wheel.so use_uid 配置"
            sudo sed -i '$aauth required pam_wheel.so group=wheel' ${cfgfile}
        elif [ ${wheel_b} -eq 1 ] || [ ${wheel_c} -eq 1 ];then
            echoGreen "符合等保要求"
        fi
    fi
}

### 检查是否设置口令过期前警告天数
function pass_warn_age(){
    local cfgfile=/etc/login.defs
    pass_warn_age_value=`grep -i ^PASS_WARN_AGE ${cfgfile} | awk '{print $2}' |sed 's/^[ \t]*//g'`
    if [ ${pass_warn_age_value} == "" ];then
        echoRed "不存在PASS_WARN_AGE参数 需要添加"
        sudo sed -i '$aPASS_WARN_AGE 45' ${cfgfile}
    elif [ ${pass_warn_age_value} != "" ] && [ ${pass_warn_age_value} -le 30 ];then
        echoYellow "存在PASS_WARN_AGE参数 值为：${pass_warn_age_value},需要整改"
        set_key_value ${cfgfile} PASS_WARN_AGE 45
    elif [ ${pass_warn_age_value} -gt 30 ];then
        echoGreen "存在PASS_WARN_AGE参数 值为： ${pass_warn_age_value},符合等保要求"
    fi
}

### 检查是否禁止root用户远程登录
function sshd_PermitRootLogin(){
    local cfgfile=/etc/ssh/sshd_config
    local cfgfile_a=/etc/pam.d/login
    sshd_PermitRootLogin_value=`grep -i ^PermitRootLogin ${cfgfile} | awk '{print $2}' |sed 's/^[ \t]*//g'`
    login_pam_securetty=`grep -i ^auth.*required.*pam_securetty.so ${cfgfile_a} | wc -l`
    if [[ ${sshd_PermitRootLogin_value} == "" ]];then
        echoRed "不存在PermitRootLogin参数 需要添加"
        sudo sed -i '$aPermitRootLogin no' ${cfgfile}
        sudo systemctl restart sshd.service
    elif [[ ${sshd_PermitRootLogin_value} != "no" ]];then
        echoYellow "存在PermitRootLogin参数 值为：${sshd_PermitRootLogin_value},需要整改"
        set_key_value ${cfgfile} PermitRootLogin no
        sudo systemctl restart sshd.service
    elif [[ ${sshd_PermitRootLogin_value} == "no" ]];then
        echoGreen "存在PermitRootLogin参数 值为： ${sshd_PermitRootLogin_value},符合等保要求"
    fi
    if [ ${login_pam_securetty} -eq 0 ];then
        echoYellow "login文件${cfgfile_a}中需要添加 auth required pam_securetty.so 配置"
        sudo sed -i '$aauth required pam_securetty.so' ${cfgfile_a}
    else
        echoGreen "login文件${cfgfile_a}中有auth required pam_securetty.so参数，符合等保要求"
    fi
}

### 配置cron、at的安全性
function cron_at(){
    local files=(/etc/cron.allow /etc/at.allow)
    local user_name=(root swift)
    for i in ${files[@]};do
        if [ ! -f $i ];then
            sudo touch $i
        fi
        if [ -f $i ];then
            echoGreen "$i 已存在"
        else
            echoRed "$i 不存在，请手动创建"
        fi
        for j in ${user_name[@]};do
            if [[ ! $(grep $j $i) ]];then
                echo $j >> $i
            fi
            if [[ $(grep $j $i) ]];then
                echoGreen "$i 中包含 $j 用户"
            else
                echoYellow "$i 中不包含 $j 用户，请手动添加"
            fi
        done
    done

}


### 是否开启SELinux
function selinux(){
    echo selinux
}

### 查看是否启用了主机防火墙、TCP SYN保护机制设置
function ufw(){
    echo ufw
}

### 检查重要文件属性设置
function chattr_file(){
    local files=(gshadow shadow group passwd)
    for i in ${files[@]};do
        a=$(sudo lsattr /etc/${i} | awk '{print $1}' | awk '{print $1}')
        if [[ ${a} =~ i ]];then
            echoGreen "/etc/$i 权限已存在，符合等保要求"
        else
            sudo chattr +i /etc/${i}
            echoGreen "新增加了/etc/${i}的 i 权限"
        fi
    done 
}

### 检查用户umask设置
function umask(){
    local csh_cshrc_file=/etc/csh.cshrc
    local csh_login_file=/etc/csh.login
    local profile_file=/etc/profile
    local bashrc_file=/etc/bashrc
    local files=(${csh_cshrc_file} ${csh_login_file} ${profile_file} ${bashrc_file})
    for i in ${files[@]};do
        if [ -f $i ];then
            umask=`grep -i ^umask $i | awk '{print $2}' |sed 's/^[ \t]*//g'`
            if [[ ${umask} == "" ]];then
                echoRed "不存在umask参数 需要添加"
                sudo sed -i '$aumask 077' ${i}
            elif [[ ${umask} != "" ]] && [[ ${umask} != "077" ]];then
                echoYellow "存在umask参数 值为：${umask},需要整改"
                set_key_value ${cfgfile} umask 077
            elif [[ ${umask} == "077" ]];then
                echoGreen "存在umask参数 值为： ${umask},符合等保要求"
            fi
        fi
    done

}

### 检查密码重复使用次数限制(需要安装pam的cracklib组件)
function pam_remember(){
    local cfgfile=/etc/pam.d/common-password
    local pass_pam_unix=$(grep -i ^password.*pam_unix.so.* ${cfgfile} | wc -l)
    local pass_pam_unix_a=$(grep -i ^password.*pam_unix.so.* ${cfgfile})
    local pass_pam_unix_b=$(grep -ni ^password.*pam_unix.so.* ${cfgfile} | sed -e 's/:.*//g')
    if [ ${pass_pam_unix} -eq 0 ];then
        echoRed "不存在remember参数 需要添加"

    elif [ ${pass_pam_unix} -eq 1 ];then
        if [[ ${pass_pam_unix_a} =~ "remember" ]];then
            for i in ${pass_pam_unix_a};do
                if [[ $i =~ "remember" ]];then
                    echoGreen "已配置 remember,参数 ${i}，符合等保要求"
                fi
            done
        else
            echoYellow "不存在remember参数 值为：${pass_pam_unix_a},需要整改"
            ### 添加remember=5
            sudo sed -i "${pass_pam_unix_b}{s/$/ remember=5/}" ${cfgfile}
            if [ ${pass_pam_unix} -eq 1 ];then
                echoGreen "已配置 remember,参数 ${i}，符合等保要求"
            else
                echoYellow "未修改成功，请手动修改"
            fi
        fi
    fi
}

### 检查重要目录或文件权限设置
function chmod_file(){
    local files=(
        /etc/rc0.d
        /etc/rc1.d
        /etc/rc2.d
        /etc/rc3.d
        /etc/rc4.d
        /etc/rc5.d
        /etc/rc6.d
        /etc/security
        /etc/passwd
        /etc/group
        /tmp
        /etc/services
        /etc/inetd.conf
        /etc/grub.conf
        /etc/lilo.conf
        /etc/grub2.cfg
        /boot/grub2/grub.cfg
        /etc/init.d
        /etc/shadow
        )
    for i in ${files[@]};do
        permission_value=$(ls -l $i | cut -c1-10|tr "rwx-" "4210"|awk -F "" '{print $1+$2+$3$4+$5+$6$7+$8+$9}')
        if [ -d $i ] || [ -f $i ];then
            if [[ $i =~ rc.*.d ]];then
                if [[ ${permission_value} != 750 ]];then
                    sudo chmod 750 $i
                    echoGreen "已修改 ${i} 权限，符合等保要求"
                fi
            elif [[ $i =~ security ]] || [[ $i =~ inetd.conf ]] || [[ $i =~ grub.conf ]] || [[ $i =~ lilo.conf ]] || [[ $i =~  grub2.cfg ]] || [[ $i =~ shadow ]];then
                if [[ ${permission_value} != 600 ]];then
                    sudo chmod 600 $i
                    echoGreen "已修改 ${i} 权限，符合等保要求"
                fi
            elif [[ $i =~ passwd ]] || [[ $i =~ group ]] || [[ $i =~ services ]];then
                if [[ ${permission_value} != 644 ]];then
                    sudo chmod 644 $i
                    echoGreen "已修改 ${i} 权限，符合等保要求"
                fi
            fi
        else
            echoYellow "$i 不存在"
        fi
    done
}

### 检查系统openssh安全配置
function openssh(){
    local cfgfile=/etc/ssh/sshd_config
    local protocol_sshd=`grep -i ^Protocol* ${cfgfile} |awk '{print $2}' |sed 's/^[ \t]*//g'`
    if [ ! -f ${cfgfile} ];then
        echoRed "系统中没有 ${cfgfile} 文件，需要手动安装openssh"
    fi
    if [[ ${protocol_sshd} == "" ]];then
        echoYellow "Protocol 不存在，需要添加"
        sudo sed -i '$aProtocol 2' ${cfgfile}
    fi
    if [[ ${protocol_sshd} != 2 ]];then
        echoYellow "Protocol 配置不为2，应修改为2"
        set_key_value  ${cfgfile} Protocol 2
    fi
    if [[ ${protocol_sshd} == 2 ]];then
        echoGreen "Protocol 值为2，符合等保要求"
    fi
}

function check(){
    echoGreen "准备检查中..."
    for i in {1..3};do
        sleep 1
        echoGreen "$i" 
    done
    pass_max_days
    pass_min_days
    login_umask
    #wheel
    pass_warn_age
    sshd_PermitRootLogin
    chattr_file
    umask
    pam_remember
    chmod_file
    openssh
    cron_at
}

function main(){
        echo  -e "\033[1;31m
#########################################################################################
#                                        Menu                                           #
#         0:系统基本信息                                                                #
#         1:全部加固                                                                    #
#         2:设置口令生存周期                                                            #
#         3:设置口令最小间隔天数                                                        #
#         4:用户目录缺省访问权限设置                                                    #
#         5:PAM认证模块禁止wheel组之外的用户                                            #
#         6:设置口令过期前警告天数                                                      #
#         7:禁止root用户远程登录                                                        #
#         8:重要文件属性设置                                                            #
#         9:检查用户umask设置                                                           #
#         10:检查密码重复使用次数限制                                                   #
#         11:检查重要目录或文件权限设置                                                 #
#         12:检查系统openssh安全配置                                                    #
#         13:selinux（暂不处理）                                                        #
#         14:ufw（暂不处理）                                                            #
#         15:cron_at（暂不处理）                                                        #
#         16:检查                                                                       #
#         17:Exit                                                                       #
######################################################################################### \033[0m"
    read -p "Please choice[0-16]:"
    for i in $REPLY;do
        case $i in
            0)
                info
                main
                ;;
            1)
                pass_max_days
                pass_min_days
                login_umask
                #wheel
                pass_warn_age
                sshd_PermitRootLogin
                umask
                pam_remember
                chmod_file
                openssh
                chattr_file
                cron_at
                check
                ;;
            2)
                pass_max_days
                ;;
            3)
                pass_min_days
                ;;
            4)
                login_umask
                ;;
            5)
                wheel
                ;;
            6)
                pass_warn_age
                ;;
            7)
                sshd_PermitRootLogin
                ;;
            8)
                chattr_file
                ;;
            9)
                umask
                ;;
            10)
                pam_remember
                ;;
            11)
                chmod_file
                ;;
            12)
                openssh
                ;;
            13)
                selinux
                ;;
            14)
                ufw
                ;;
            15)
                cron_at
                ;;
            16)
                check
                ;;
            17)
                exit 0
                ;;
            *)
                echo -e "\033[31;5m	invalid input	    \033[0m"
                main
        esac
    done
}
main
