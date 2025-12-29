#!/bin/bash
# Date: 2022-8-22 14:15
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description: Generate hosts file
# Version: v1.0

# ENVNAME=${ENVNAME}
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
WORKSPACE=/tmp/hosts_list
# HOST_GROUP=${HOST_GROUP:-test_hosts}
ANSIBLE_PLAYBOOK=${ANSIBLE_PLAYBOOK:-/home/swift/k8s-test/check_internet_network_port_connectivity.yml}


# set color
echoRed() { echo -e $'\e[0;31m'"$1"$'\e[0m'; }
echoGreen() { echo -e $'\e[1;32m'"$1"$'\e[0m'; }
echoYellow() { echo -e $'\e[0;33m'"$1"$'\e[0m'; }
echoDarkGreen() { echo -e $'\033[36m'"$1"$'\033[0m'; }

usage() {
    echo "usage:"
    echo "${0}  [-e EnvNAME]"
    echo -e "\nOptions:"
    echo -e "-e xxyy-prod                       env name(default \"All env\")"
    echo -e "-i check_internet_network_port_host    host group"
    echo -e "-j ansible-playbook.yml                ansible playbook(default \"/home/swift/k8s-test/check_internet_network_port_connectivity.yml\")"
    exit 1
}

while getopts 'e:i:j:' opt; do
    case $opt in
    e)
        ENVNAME=$OPTARG
        ;;
    i)
        HOST_GROUP=$OPTARG
        ;;
    j)
        ANSIBLE_PLAYBOOK=$OPTARG
        ;;
    ?)
        usage
        exit 1
        ;;
    esac
done

if [[ -z $HOST_GROUP ]]; then
    echo "-i parameter (required)"
    exit 1
fi

generate_file() {
    local env_name=$1
    local host_group=$2
    local file_name="$WORKSPACE/hosts_$env_name"
    echo "[${host_group}]" >>"$file_name"

    grep "${env_name^^}" /etc/ssh/ssh_config | grep Host | grep -v "^#" | awk '{print $2}' | grep APP | sort >>"$file_name"

    echo "$file_name"

}

if [ ! -d "$WORKSPACE" ]; then
    mkdir -p "$WORKSPACE"
else
    mv "$WORKSPACE" "$WORKSPACE"_"$DATE"
    mkdir -p "$WORKSPACE"
fi

if [[ -n $ENVNAME ]]; then
    generate_file "${ENVNAME%%-*}" "$HOST_GROUP"
else
    # 生成配置文件
    for env_name in $(tools -t env | awk -F '|' '{print $2}' | tail -n +4 | grep -v "^$" | grep prod | sort); do
        env_name=${env_name%%-*}
        generate_file "${env_name}" "$HOST_GROUP"
    done
fi

for host in "$WORKSPACE"/*;do
    [[ -e "$host" ]] || break
    ansible-playbook -i "$host" "$ANSIBLE_PLAYBOOK" 2>/dev/null
done
