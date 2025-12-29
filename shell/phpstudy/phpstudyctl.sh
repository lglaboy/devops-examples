#!/bin/bash


Check_Root()
{
        #check root
        who=`whoami`
        if [ "$who" != "root" ];then
                echo -e "\033[31m请先切换到root身份再执行此指令\033[0m"
                exit
        fi
}


Start_Phpstudy()
{
        export LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
        echo 'starting..'


        #start phpstudy
    pid=`/usr/local/phpstudy/system/module/getPidByExe /usr/local/phpstudy/system/phpstudy`
    if [[ $pid == "0" ]];then
                chmod +x /usr/local/phpstudy/system/phpstudy
                /usr/local/phpstudy/system/phpstudy -d > /dev/null 2>&1 &
        fi


        #wait
        nCount=20
        run=`/usr/local/phpstudy/system/phpstudy -testping`
        while [[ $run == "0" ]] && [[ $nCount>0 ]]
        do
                sleep 1
                run=`/usr/local/phpstudy/system/phpstudy -testping`
                ((nCount-=1))
        done
        if [[ $run == "0" ]];then
                echo -e "\033[31m phpstudy work process start error,please connect us https://www.xp.cn \033[0m"
        exit
        fi


        #auto start soft
        find /usr/local/phpstudy/soft/* -name status > /usr/local/phpstudy/soft/auto
        cat /usr/local/phpstudy/soft/auto | while read line
        do
                bStart=`cat $line`
                if [[ $bStart == "1" ]];then
                        /bin/bash ${line%/*}/start
                fi
                  if [[ $bStart == "2" ]];then
                        /bin/bash ${line%/*}/start
                fi
        done
        unset bStart
        rm -rf /usr/local/phpstudy/soft/auto


        nCount=20
        pid=`/usr/local/phpstudy/system/module/getPidByExe /usr/local/phpstudy/system/module/xpupdate`
        while [[ $pid != "0" ]] && [[ $nCount>0 ]]
        do
                kill -9 $pid
                pkill xpupdate
                sleep 1
                pid=`/usr/local/phpstudy/system/module/getPidByExe /usr/local/phpstudy/system/module/xpupdate`
        done



        #start webpanel
        nCount=20
        pid=`/usr/local/phpstudy/system/module/getPidByExe /usr/local/phpstudy/web/php-7.3.8/bin/php`
        while [[ $pid == "0" ]] && [[ $nCount>0 ]]
        do
                /bin/bash /usr/local/phpstudy/web/start > /dev/null 2>&1 &
                ((nCount-=1))
                sleep 1
                pid=`/usr/local/phpstudy/system/module/getPidByExe /usr/local/phpstudy/web/php-7.3.8/bin/php`
        done


        Show_Status
        export -n LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends

}

Stop_Phpstudy()
{
        #stop webpanel
        /bin/bash /usr/local/phpstudy/web/stop > /dev/null 2>&1

        #stop phpstudy
        pkill -x phpstudy

        #auto stop soft
        find /usr/local/phpstudy/soft/* -name status > /usr/local/phpstudy/soft/auto
        cat /usr/local/phpstudy/soft/auto | while read line
        do
                bStop=`cat $line`
                if [[ $bStop == "1" ]];then
                        /bin/bash ${line%/*}/stop
                                echo 1 > ${line%/*}/status
                fi
                  if [[ $bStop == "2" ]];then
                        /bin/bash ${line%/*}/stop
                                echo 1 > ${line%/*}/status
                fi
        done
        unset bStop
        rm -rf /usr/local/phpstudy/soft/auto


        sleep 1
        Show_Status
}

Restart_Phpstudy()
{
        echo 'phpstudy restart'
        Stop_Phpstudy
        Start_Phpstudy
}
Show_Status()
{
        echo ''
        echo '==============运行状态========================='
        echo ''

        pid=`/usr/local/phpstudy/system/module/getPidByExe /usr/local/phpstudy/web/php-7.3.8/bin/php`
        if [[ $pid == "0" ]];then
                echo -e "\033[31mwebpanel stop  \033[0m"
        else
                echo -e "\033[32mwebpanel running \033[0m"
        fi


        export LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
        run=`/usr/local/phpstudy/system/phpstudy -testping`
        if [[ $run == "0" ]];then
                echo -e "\033[31mphpstudy stop \033[0m"
        else
                echo -e "\033[32mphpstudy running \033[0m"
        fi
        export -n LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
}

Show_Version()
{
        echo ''
        echo '===============版本信息========================'
        echo ''

        export LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
        /usr/local/phpstudy/system/phpstudy -v
        export -n LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
}

Show_VisitUrl()
{
        echo ''
        echo '==============================================='
        echo ''
        export LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends

        /usr/local/phpstudy/system/phpstudy -visiturl
        user=`/usr/local/phpstudy/system/phpstudy -username`
        echo "登录账号:$user"



        export -n LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
}

Repair_Panel()
{
        export LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
        repairFile=`/usr/local/phpstudy/system/phpstudy -repair`
        $repairFile
        export -n LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
}


Init_Pwd()
{
        if [[ $2 == "" ]];then
        {
                echo '无效的密码'
        }
        else
        {
                export LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
                /usr/local/phpstudy/system/phpstudy -initpwd $2
                export -n LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
        }
        fi
}

Show_InstInfo()
{
        echo ''
        echo '==============================================='
        echo ''

        cat /usr/local/phpstudy/install.result

}

Set_ListenPort()
{
        export LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends

        /usr/local/phpstudy/system/phpstudy -setport $1


        export -n LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
}

ReToken()
{
        export LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends

        /usr/local/phpstudy/system/phpstudy -retoken


        export -n LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends

}
Check_Update()
{
        export LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends

        curVer=`/usr/local/phpstudy/system/phpstudy -v`
        remoteVer=`/usr/local/phpstudy/system/phpstudy -u`


        if [[ $curVer < $remoteVer ]];then
                echo -en "当前版本:$curVer,检测到新版本:\033[31m$remoteVer\033[0m,是否立即升级(Y/N):"
                read -p "" yn
                if [[ $yn == 'Y' || $yn == 'y' ]];then
                  updateFile=`/usr/local/phpstudy/system/phpstudy -update`
                        /bin/bash $updateFile
                  rm -rf $updateFile
                fi
        else
                echo "当前版本:$curVer已经是最新版,无需升级"
        fi

        export -n LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
}

Version()
{
        export LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
        /usr/local/phpstudy/system/phpstudy -v

        export -n LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends


}

Cancel_Domain()
{
        export LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
        /usr/local/phpstudy/system/phpstudy -canceldomain

        export -n LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
}

Cancel_Ip()
{
        export LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
        /usr/local/phpstudy/system/phpstudy -cancelip

        export -n LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends

}

Switch_PhpVer()
{
        if [[ ! -d /usr/local/phpstudy/soft/php ]];then
                echo '请先在面板的软件商店中安装php程序后再继续操作'
                exit
        fi

        ls -F /usr/local/phpstudy/soft/php | grep '/$' > /usr/local/phpstudy/tmp/allphp
        sed -i "s/\///g" /usr/local/phpstudy/tmp/allphp #去掉内容中的\
        nTotal=`cat /usr/local/phpstudy/tmp/allphp |wc -l`  #总行数
        if [[ $nTotal -le 0 ]];then
                echo '请先在面板的软件商店中安装php程序后再继续操作'
                exit
        fi

        for((i=1;i<=$nTotal;i++));
        do
                line=`sed -n "$i"p /usr/local/phpstudy/tmp/allphp`
                echo "$i):$line"
        done

        nSel=0
        while [[ $nSel -gt $nTotal||$nSel -lt 1 ]];
        do
                read -p "请输入数字编号,选定php版本(1~$nTotal):" nSel
                if [[ $nSel -gt $nTotal||$nSel -lt 1 ]];then
                  echo '输入错误,请重新输入:'
                  continue
                fi
        done
        selPhp=`sed -n "$nSel"p /usr/local/phpstudy/tmp/allphp`

        export LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
        /usr/local/phpstudy/system/phpstudy -switchphpver $selPhp

}





Uninstall_Phpstudy()
{
        echo ''
        read -p '请输入面板登录用户名:' user
        read -p '请输入面板登录密码:' pwd
        export LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
        result=`/usr/local/phpstudy/system/phpstudy -checklogin $user $pwd`
        if [[ $result =~ 'success' ]];then
                #stop xpfirewall
                /usr/local/phpstudy/system/module/xpfirewall stop
                sleep 1

                Stop_Phpstudy

                #auto unlock protected files
                pkill filesafe

                #stop webshell
                pkill xpwebshell

                #delete all files
                rm -rf /usr/local/phpstudy
                #delete links
                rm -rf /usr/bin/xp
                rm -rf /usr/bin/XP
                rm -rf /usr/bin/php
                rm -rf /usr/bin/phpstudy
                echo '卸载完成!'

        else
                echo '用户密码校验错误,无法卸载'
        fi

        export -n LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
}


Show_Help()
{
        echo ''
        echo '=================查看命令========================'
        echo ''
        echo '1) phpstudy -start             启动小皮面板'
        echo '2) phpstudy -stop              停止小皮面板'
        echo '3) phpstudy -restart           重启小皮面板'
        echo '4) phpstudy -status            查询面板状态'
        echo '5) phpstudy -initpwd newPwd    修改登录密码'
        echo '6) phpstudy -visiturl          查看面板登录信息'
        echo '7) phpstudy -repair            修复web面板'
        echo '8) phpstudy -instinfo          查看首次安装信息'
        echo '9) phpstudy -setport newPort   修改面板监听端口'
        echo '10) phpstudy -retoken          重置登录授权码'
        echo '11) phpstudy -update           检查更新'
        echo '12) phpstudy -v                查看版本'
        echo '13) phpstudy -canceldomain     取消域名访问'
        echo '14) phpstudy -cancelip         取消授权ip限制'
        echo '98) phpstudy -uninstall        卸载小皮面板'
        echo ''
        echo ''
}

Show_Help_XP()
{
        echo ''
        echo '===============请输入以下指令编号=============='
        echo ''
        echo '1)         启动小皮面板'
        echo '2)         停止小皮面板'
        echo '3)         重启小皮面板'
        echo '4)         查询面板状态'
        echo '5)         修改登录密码'
        echo '6)         查看面板登录信息'
        echo '7)         修复主控web面板'
        echo '8)         查看首次安装信息'
        echo '9)         修改面板监听端口'
        echo '10)        重置登录授权码'
        echo '11)        检查更新'
        echo '12)        查看版本'
        echo '13)        取消域名访问'
        echo '14)        取消授权ip限制'
        echo '16)        切换php环境变量版本'
        echo '98)        卸载小皮面板'
        echo '99)        退出本页'
        echo ''
        echo ''

}

Check_Root
if [[ $1 == "-start" ]];then
        Start_Phpstudy
elif [[ $1 == "-status" ]];then
        Show_Status
elif [[ $1 == "-stop" ]];then
        Stop_Phpstudy
elif [[ $1 == "-restart" ]];then
        Restart_Phpstudy
elif [[ $1 == "-v" ]];then
        Show_Version
elif [[ $1 == "-V" ]];then
        Show_Version
elif [[ $1 == "-initpwd" ]];then
        Init_Pwd $1 $2
elif [[ $1 == "-visiturl"  ]];then
        Show_VisitUrl
elif [[ $1 == "-repair"  ]];then
        Repair_Panel
elif [[ $1 == "-instinfo" ]];then
        Show_InstInfo
elif [[ $1 == "-setport" ]];then
        Set_ListenPort $2
elif [[ $1 == "-retoken" ]];then
        ReToken
elif [[ $1 == "-update" ]];then
        Check_Update
elif [[ $1 == "-v" ]];then
        Version
elif [[ $1 == "-canceldomain" ]];then
        Cancel_Domain
elif [[ $1 == "-cancelip" ]];then
        Cancel_Ip
elif [[ $1 == "-uninstall" ]];then
        Uninstall_Phpstudy
else
        if [[ $0 == "/usr/bin/xp" || $0 == "/bin/xp" || $0 == "/usr/bin/XP" || $0 == "/bin/XP" ]];then
                Show_Help_XP
                read -p "请输入以上指令编号:" code
                if [[ $code == 0 ]];then
                  Show_Help_XP
                  read -p "请输入以上指令编号:" code
                fi
                if [[ $code == 1 ]];then
                  Start_Phpstudy
                fi
                if [[ $code == 2 ]];then
                  Stop_Phpstudy
                fi
                if [[ $code == 3 ]];then
                  Restart_Phpstudy
                fi
                if [[ $code == 4 ]];then
                  Show_Status
                fi
                if [[ $code == 5 ]];then
                  read -p "请输入新密码:" pwd1
                  read -p "请再次输入新密码:" pwd2
                  if [[ $pwd1 == "" ]];then
                        echo '无效的密码'
                        exit
                  fi
                  if [[ $pwd1 != $pwd2 ]];then
                        echo '两次输入不一致'
                        exit
                  fi
                  if [[ $pwd1==$pwd2 ]];then
                        export LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
                        /usr/local/phpstudy/system/phpstudy -initpwd $pwd1
                        export -n LD_LIBRARY_PATH=/usr/local/phpstudy/system/depends
                  fi
                fi
                if [[ $code == 6 ]];then
                  Show_VisitUrl
                fi
                if [[ $code == 7 ]];then
                  Repair_Panel
                fi
                if [[ $code == 8 ]];then
                  Show_InstInfo
                fi
                if [[ $code == 9 ]];then
                  read -p "请输入端口号:" port
                  Set_ListenPort $port
                fi
                if [[ $code == 10 ]];then
                  ReToken
                fi
                if [[ $code == 11 ]];then
                  Check_Update
                fi
                if [[ $code == 12 ]];then
                  Version
                fi
                if [[ $code == 13 ]];then
                  Cancel_Domain
                fi
                if [[ $code == 14 ]];then
                  Cancel_Ip
                fi
                if [[ $code == 16 ]];then
                  Switch_PhpVer
                fi
                if [[ $code == 98 ]];then
                  Uninstall_Phpstudy
                fi
                if [[ $code == 99 ]];then
                  exit
                fi
        else
                Show_Help
        fi
fi