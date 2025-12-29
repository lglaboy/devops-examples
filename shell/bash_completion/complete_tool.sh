# 初始化缓存目录
__tools_init_cache_dir() {
    if [[ ! -d $cache_dir ]]; then
        mkdir -p $cache_dir
    fi
}

# 环境列表补全
__tools_env_list() {
    local cache_file env

    cache_file="$cache_dir/env_list"

    __tools_init_cache_dir

    if [[ ! -f $cache_file ]]; then
        tools -t env | awk -F '|' '{print $2}' | tail -n +4 | grep -v "^$" | xargs -n 1 | sort >$cache_file
    fi

    env=$(cat $cache_file)
    COMPREPLY=($(compgen -W "${env[@]}" -- $cur))
}

# 升级过的库中的job补全
__tools_job_list() {
    local envname cache_file jobname

    envname=${COMP_WORDS[COMP_CWORD - 2]}
    cache_file="$cache_dir/${envname}_job_list"

    __tools_init_cache_dir

    if [[ ! -f $cache_file ]]; then
        tools -t job -e ${envname} | grep ${envname} | sed "s/[\']/\n/g" | sed '/[,\|]/d' | sort >"$cache_file"
    fi

    jobname=$(cat "$cache_file")
    COMPREPLY=($(compgen -W "${jobname[@]}" -- $cur))
}

# jenkins上的job补全
__tools_jenkins_jobs() {
    local envname cache_file jobname

    envname=$1

    cache_file="$cache_dir/${envname}_jenkins_job_list"

    __tools_init_cache_dir

    if [[ ! -f $cache_file ]]; then
        tools -t build -e ${envname} -l | awk -F "|" '{print $2}' >"$cache_file"
    fi

    jobname=$(cat "$cache_file")
    COMPREPLY=($(compgen -W "${jobname[@]}" -- $cur))
}

# jenkins上的multijob补全
__tools_jenkins_multijob() {
    local envname cache_file jobname
    envname=${COMP_WORDS[COMP_CWORD - 2]}

    cache_file="$cache_dir/${envname}_jenkins_multijob_list"

    __tools_init_cache_dir

    if [[ ! -f $cache_file ]]; then
        tools -t build -e ${envname} >"$cache_file"

    fi
    jobname=$(cat "$cache_file")
    COMPREPLY=($(compgen -W "${jobname[@]}" -- $cur))
}

_service_tool() {
    cache_dir="/tmp/tools_cache"

    local cur prev prevprev threevar TOOLS_COLS_ALL
    COMPREPLY=()
    cur=${COMP_WORDS[COMP_CWORD]}
    prev=${COMP_WORDS[COMP_CWORD - 1]}
    prevprev=${COMP_WORDS[COMP_CWORD - 3]}
    threevar=${COMP_WORDS[2]}
    fivevar=${COMP_WORDS[4]}

    TOOLS_COLS_ALL="host env job rollback restart branch build gitlab deljenkins addjenkins grafana nacosjdbc backup rollbackplus loki nacos nacos_info shutdown_white_list cmdb"

    case $prev in
    'tools')
        COMPREPLY=($(compgen -W '-t' -- $cur))
        ;;

    '-t')
        COMPREPLY=($(compgen -W "$TOOLS_COLS_ALL" -- $cur))
        ;;

    'host')
        COMPREPLY=($(compgen -W '-h' -- $cur))
        ;;

    'env')
        COMPREPLY=($(compgen -W '-e -a' -- $cur))
        ;;

    'job')
        COMPREPLY=($(compgen -W '-j -e -a' -- $cur))
        ;;

    'rollback')
        COMPREPLY=($(compgen -W '-j -e -v' -- $cur))
        ;;

    'restart')
        COMPREPLY=($(compgen -W '-j -e' -- $cur))
        ;;

    'branch')
        COMPREPLY=($(compgen -W '-j -e -b -w' -- $cur))
        ;;

    'build')
        COMPREPLY=($(compgen -W '-j -e -k -l' -- $cur))
        ;;

    'gitlab')
        COMPREPLY=($(compgen -W '-e -g -w' -- $cur))
        ;;

    'deljenkins')
        COMPREPLY=($(compgen -W '-j -e' -- $cur))
        ;;

    'addjenkins')
        COMPREPLY=($(compgen -W '-j -e -b -g' -- $cur))
        ;;

    'grafana')
        COMPREPLY=($(compgen -W '-e -g -d' -- $cur))
        ;;

    'nacosjdbc')
        COMPREPLY=($(compgen -W '-g -b -h' -- $cur))
        ;;
    'backup')
        COMPREPLY=($(compgen -W '-e -f' -- $cur))
        ;;
    'rollbackplus')
        COMPREPLY=($(compgen -W '-e -l -b -a -y' -- $cur))
        ;;
    'loki')
        COMPREPLY=($(compgen -W '-f -e -g' -- $cur))
        ;;
    'nacos')
        COMPREPLY=($(compgen -W '-f -e -j -K -V -D -F' -- $cur))
        ;;
    'nacos_info')
        COMPREPLY=($(compgen -W '-f -e -D -U -P' -- $cur))
        ;;
    'shutdown_white_list')
        COMPREPLY=($(compgen -W '-f -e' -- $cur))
        ;;
    'cmdb')
        COMPREPLY=($(compgen -W '-f' -- $cur))
        ;;
    '-e')
        local env
        if [[ ${threevar} == "addjenkins" ]]; then
            return 0
        fi

        __tools_env_list
        ;;
    '-j')
        local envname deletechar
        deletechar=",'"
        if [[ ${threevar} == "job" && ${prevprev} == '-e' ]]; then
            __tools_job_list
        elif [[ ${threevar} == "rollback" && ${prevprev} == '-e' ]]; then
            __tools_jenkins_jobs "${COMP_WORDS[COMP_CWORD - 2]}"
        elif [[ ${threevar} == "restart" && ${prevprev} == '-e' ]]; then
            __tools_jenkins_jobs "${COMP_WORDS[COMP_CWORD - 2]}"
        elif [[ ${threevar} == "branch" ]]; then
            if [[ ${prevprev} == '-e' ]]; then
                envname=${COMP_WORDS[COMP_CWORD - 2]}
            elif [[ ${COMP_WORDS[3]} == '-e' ]]; then
                envname=${COMP_WORDS[4]}
            fi
            __tools_jenkins_jobs "$envname"
        elif [[ ${threevar} == "addjenkins" ]]; then
            return 0
        elif [ ${prevprev} == '-e' ]; then
            __tools_jenkins_multijob
        fi
        ;;
    '-h')
        local hostname
        hostname=$(grep "Host " /etc/ssh/ssh_config | grep -v [*\#] | awk '{print $2}')
        COMPREPLY=($(compgen -W "${hostname[@]}" -- $cur))
        ;;
    '-b')
        local branch
        if [[ ${threevar} == branch ]]; then
            branch="release-2.4.0"
            COMPREPLY=($(compgen -W "${branch}" -- $cur))
        elif [[ ${threevar} == rollbackplus ]]; then
            branch="2022-10-20"
            COMPREPLY=($(compgen -W "${branch}" -- $cur))
        fi
        ;;
    '-f')
        if [[ ${threevar} == backup ]]; then
            COMPREPLY=($(compgen -W "project nacos" -- $cur))
        elif [[ ${threevar} == loki ]]; then
            COMPREPLY=($(compgen -W "add delete" -- $cur))
        elif [[ ${threevar} == nacos ]]; then
            COMPREPLY=($(compgen -W "update delete" -- $cur))
        elif [[ ${threevar} == nacos_info ]]; then
            COMPREPLY=($(compgen -W "add delete update get" -- $cur))
        elif [[ ${threevar} == shutdown_white_list ]]; then
            COMPREPLY=($(compgen -W "add delete get" -- $cur))
        elif [[ ${threevar} == cmdb ]]; then
            COMPREPLY=($(compgen -W "update_machine update_machine_ip delete_machine_ip update_machine_service show_machine_info show_ip_info show_base_service show_job_service" -- $cur))
        fi
        ;;
    'update_machine')
        if [[ ${threevar} == cmdb ]]; then
            COMPREPLY=($(compgen -W "-h -e -S -s -M -C -R -D -r -N" -- $cur))
        fi
        ;;
    'update_machine_ip')
        if [[ ${threevar} == cmdb ]]; then
            COMPREPLY=($(compgen -W "-h -i -S -l -I" -- $cur))
        fi
        ;;
    'delete_machine_ip')
        if [[ ${threevar} == cmdb ]]; then
            COMPREPLY=($(compgen -W "-h -i" -- $cur))
        fi
        ;;
    'update_machine_service')
        if [[ ${threevar} == cmdb ]]; then
            COMPREPLY=($(compgen -W "-h -j -T -y -I -D" -- $cur))
        fi
        ;;
    'show_machine_info')
        if [[ ${threevar} == cmdb ]]; then
            COMPREPLY=($(compgen -W "-e" -- $cur))
        fi
        ;;
    'show_ip_info')
        if [[ ${threevar} == cmdb ]]; then
            COMPREPLY=($(compgen -W "-e" -- $cur))
        fi
        ;;
    'show_base_service')
        if [[ ${threevar} == cmdb ]]; then
            COMPREPLY=($(compgen -W "-e" -- $cur))
        fi
        ;;
    'show_job_service')
        if [[ ${threevar} == cmdb ]]; then
            COMPREPLY=($(compgen -W "-e" -- $cur))
        fi
        ;;
    '-s')
        if [[ ${threevar} == cmdb ]]; then
            COMPREPLY=($(compgen -W "online offline maintenance" -- $cur))
        fi
        ;;
    '-r')
        if [[ ${threevar} == cmdb ]] && [[ $fivevar == update_machine ]]; then
            COMPREPLY=($(compgen -W "master slave" -- $cur))
        fi
        ;;
    '-N')
        if [[ ${threevar} == cmdb ]] && [[ $fivevar == update_machine ]]; then
            COMPREPLY=($(compgen -W "external internal" -- $cur))
        fi
        ;;
    '-S')
        if [[ ${threevar} == cmdb ]] && [[ $fivevar == update_machine_ip ]]; then
            COMPREPLY=($(compgen -W "external internal source other" -- $cur))
        fi
        ;;
    '-T')
        if [[ ${threevar} == cmdb ]] && [[ $fivevar == update_machine_service ]]; then
            COMPREPLY=($(compgen -W "docker k8s physical other" -- $cur))
        fi
        ;;
    esac

    return 0
}
complete -F _service_tool tools
