# Date: 2022-10-31 09:36
# Author: lglaboy
# GitHub: https://github.com/lglaboy
# Description:
# Version: v1.0
# bash completion for tools                              -*- shell-script -*-

export BASH_COMP_DEBUG_FILE=/tmp/test.log

__tools_debug()
{
    if [[ -n ${BASH_COMP_DEBUG_FILE} ]]; then
        echo "$*" >> "${BASH_COMP_DEBUG_FILE}"
    fi
}

__tools_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref "$@" cur prev words cword
}

__tools_contains_word()
{
    local w word=$1; shift
    for w in "$@"; do
        [[ $w = "$word" ]] && return
    done
    return 1
}

__tools_index_of_word()
{
    local w word=$1
    shift
    index=0
    for w in "$@"; do
        [[ $w = "$word" ]] && return
        index=$((index+1))
    done
    index=-1
}

__tools_handle_noun()
{
    __tools_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    if __tools_contains_word "${words[c]}" "${must_have_one_noun[@]}"; then
        must_have_one_noun=()
    elif __tools_contains_word "${words[c]}" "${noun_aliases[@]}"; then
        must_have_one_noun=()
    fi

    nouns+=("${words[c]}")
    c=$((c+1))
}

__tools_handle_flag()
{
    __tools_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    # if a command required a flag, and we found it, unset must_have_one_flag()
    local flagname=${words[c]}
    local flagvalue
    # if the word contained an =
    if [[ ${words[c]} == *"="* ]]; then
        flagvalue=${flagname#*=} # take in as flagvalue after the =
        flagname=${flagname%=*} # strip everything after the =
        flagname="${flagname}=" # but put the = back
    fi
    __tools_debug "${FUNCNAME[0]}: looking for ${flagname}"
    if __tools_contains_word "${flagname}" "${must_have_one_flag[@]}"; then
        __tools_debug "${FUNCNAME[0]}: looking for ${flagname}"
        must_have_one_flag=()
    fi

    # if you set a flag which only applies to this command, don't show subcommands
    if __tools_contains_word "${flagname}" "${local_nonpersistent_flags[@]}"; then
        __tools_debug "${FUNCNAME[0]}: looking for ${flagname}"
        commands=()
    fi

    # keep flag value with flagname as flaghash
    # flaghash variable is an associative array which is only supported in bash > 3.
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        __tools_debug "${FUNCNAME[0]}: found a flag ${words[c]}, BASH_VERSION"
        if [ -n "${flagvalue}" ] ; then
            flaghash[${flagname}]=${flagvalue}
        elif [ -n "${words[ $((c+1)) ]}" ] ; then
            flaghash[${flagname}]=${words[ $((c+1)) ]}
        else
            flaghash[${flagname}]="true" # pad "true" for bool flag
        fi
    fi

    # skip the argument to a two word flag
    if [[ ${words[c]} != *"="* ]] && __tools_contains_word "${words[c]}" "${two_word_flags[@]}"; then
		__tools_debug "${FUNCNAME[0]}: found a flag ${words[c]}, skip the next argument"
        c=$((c+1))
        # if we are looking for a flags value, don't show commands
        if [[ $c -eq $cword ]]; then
            commands=()
        fi
    fi

    c=$((c+1))

}

_tools_-t_host()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_host"

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    commands=()
    commands+=("-h")

    must_have_one_flag=()

    flags+=("-h")
    local_nonpersistent_flags+=("-h")
}

_tools_-t_host_-h()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_host_-h"

    must_have_one_flag=()

    commands=()
    # for host in $(grep "Host " /etc/ssh/ssh_config | grep -v [*\#]|awk '{print $2}')
    # do
    #     commands+=("$host")
    # done
    while IFS= read -r host
    do
        commands+=("$host")
    done < <(grep "Host " /etc/ssh/ssh_config | grep -v [*\#]|awk '{print $2}')
    # commands+=("host")

    # must_have_one_flag+=("-h")
    local_nonpersistent_flags+=("host")
}

_tools_-t_env()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_env"

    commands=()
    commands+=("-e")
    commands+=("-a")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()
    must_have_one_flag=()

    flags+=("-e")
    local_nonpersistent_flags+=("-e")
    flags+=("-a")
    local_nonpersistent_flags+=("-a")
}

_tools_-t_env_-e()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_env_-e"

    must_have_one_flag=()

    commands=()


    for env_name in $(tools -t env | awk -F '|' '{print $2}' | tail -n +4 | grep -v "^$")
    do
        commands+=("$env_name")
    done

}

_tools_-t_job()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_job"

    commands=()
    # commands+=("-j")
    commands+=("-e")
    # commands+=("-a")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()
    must_have_one_flag=()

    # flags+=("-j")
    flags+=("-e")
    # local_nonpersistent_flags+=("-e")
    # flags+=("-a")
    # local_nonpersistent_flags+=("-a")
}

_tools_-t_job_-e()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_job_-e"

    must_have_one_flag=()
    commands=()
    flags=()

    for env_name in $(tools -t env | awk -F '|' '{print $2}' | tail -n +4 | grep -v "^$")
    do
        commands+=("$env_name")
    done
    flags+=("-j")
    flags+=("-a")
}

_tools_-t_job_-e_-j()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_job_-e_-j"

    must_have_one_flag=()
    commands=()
    local envname="${words[4]}"
    for jobname in $(tools -t job -e ${envname} | grep ${envname} | sed "s/[\']/\n/g"|sed '/[,\|]/d'|sort)
    do
        commands+=("$jobname")
    done
}

_tools_-t_rollback()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_rollback"

    commands=()
    commands+=("-e")

    flags=()
    flags+=("-e")
}

_tools_-t_rollback_-e()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_rollback_-e"

    must_have_one_flag=()
    commands=()
    flags=()

    for env_name in $(tools -t env | awk -F '|' '{print $2}' | tail -n +4 | grep -v "^$")
    do
        commands+=("$env_name")
    done
    # flags+=("-j")
    # must_have_one_flag+=("-j")
    flags+=("-v")
    # must_have_one_flag+=("-v")
}

_tools_-t_rollback_-e_-j()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_rollback_-e_-j"

    must_have_one_flag=()
    commands=()
    local envname="${words[4]}"
    # for jobname in $(tools -t build -e ${envname} -l | awk -F "|" '{print $2}')
    for jobname in $(tools -t job -e "${envname}" | grep "${envname}" | sed "s/[\']/\n/g"|sed '/[,\|]/d'|sort)
    do
        commands+=("$jobname")
    done
}

_tools_-t_restart()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_restart"

    commands=()
    commands+=("-e")

    flags=()
    flags+=("-e")
}

_tools_-t_restart_-e()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_restart_-e"

    commands=()
    flags=()

    for env_name in $(tools -t env | awk -F '|' '{print $2}' | tail -n +4 | grep -v "^$")
    do
        commands+=("$env_name")
    done
    flags+=("-j")
}

_tools_-t_restart_-e_-j()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_restart_-e_-j"

    must_have_one_flag=()
    commands=()
    local envname="${words[4]}"
    for jobname in $(tools -t job -e ${envname} | grep ${envname} | sed "s/[\']/\n/g"|sed '/[,\|]/d'|sort)
    do
        commands+=("$jobname")
    done
}

_tools_-t_branch()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_branch"

    commands=()
    # commands+=("-e")
    must_have_one_flag=()
    # commands+=("-e")

    flags=()
    flags+=("-e")
    must_have_one_flag+=("-e")

    has_completion_function=1
}

_tools_-t_branch_-e()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_branch_-e"

    commands=()
    flags=()

    for env_name in $(tools -t env | awk -F '|' '{print $2}' | tail -n +4 | grep -v "^$")
    do
        commands+=("$env_name")
    done
    flags+=("-b")
    must_have_one_flag+=("-b")
    flags+=("-j")
    must_have_one_flag+=("-j")
    flags+=("-w")
    must_have_one_flag+=("-w")
}

_tools_-t_branch_-e_-j()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_branch_-e_-j"

    must_have_one_flag=()
    commands=()
    local envname="${words[4]}"
    for jobname in $(tools -t build -e ${envname} -l | awk -F "|" '{print $2}')
    do
        commands+=("$jobname")
    done
}

_tools_-t_branch_-e_-b()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_branch_-e_-b"

    must_have_one_flag=()
    commands=()
    commands+=("release-2.4.0")
}

_tools_-t_branch_-e_-j_-b()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_branch_-e_-j_-b"

    must_have_one_flag=()
    commands=()
    commands+=("release-2.4.0")
}

_tools_-t_build()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_build"

    commands=()
    commands+=("-e")

    flags=()
    flags+=("-e")
}

_tools_-t_build_-e()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_build_-e"

    commands=()
    flags=()

    for env_name in $(tools -t env | awk -F '|' '{print $2}' | tail -n +4 | grep -v "^$")
    do
        commands+=("$env_name")
    done
    flags+=("-j")
    flags+=("-k")
    flags+=("-l")
}

_tools_-t_build_-e_-j()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_build_-e_-j"

    must_have_one_flag=()
    commands=()
    local envname="${words[4]}"
    for jobname in $(tools -t build -e ${envname})
    do
        commands+=("$jobname")
    done
}

_tools_-t_gitlab()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_gitlab"

    commands=()
    commands+=("-e")

    flags=()
    flags+=("-e")
}

_tools_-t_gitlab_-e()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_gitlab_-e"

    commands=()
    flags=()

    for env_name in $(tools -t env | awk -F '|' '{print $2}' | tail -n +4 | grep -v "^$")
    do
        commands+=("$env_name")
    done
    flags+=("-g")
    flags+=("-w")
}

_tools_-t_deljenkins()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_deljenkins"

    commands=()
    commands+=("-e")

    flags=()
    flags+=("-e")
}

_tools_-t_deljenkins_-e()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_deljenkins_-e"

    commands=()
    flags=()

    for env_name in $(tools -t env | awk -F '|' '{print $2}' | tail -n +4 | grep -v "^$")
    do
        commands+=("$env_name")
    done
    flags+=("-j")
}

_tools_-t_deljenkins_-e_-j()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_deljenkins_-e_-j"

    must_have_one_flag=()
    commands=()
    local envname="${words[4]}"
    for jobname in $(tools -t build -e ${envname})
    do
        commands+=("$jobname")
    done
}

_tools_-t_addjenkins()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_addjenkins"

    commands=()
    commands+=("-e")
    commands+=("-g")
    commands+=("-b")
    commands+=("-j")

    flags=()
    flags+=("-e")
    flags+=("-g")
    flags+=("-b")
    flags+=("-j")
}

_tools_-t_grafana()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_grafana"

    commands=()
    commands+=("-e")

    flags=()
    flags+=("-e")
}

_tools_-t_grafana_-e()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_grafana_-e"

    commands=()
    flags=()

    for env_name in $(tools -t env | awk -F '|' '{print $2}' | tail -n +4 | grep -v "^$")
    do
        commands+=("$env_name")
    done
    flags+=("-g")
    flags+=("-d")
}

_tools_-t_nacosjdbc()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_nacosjdbc"

    commands=()
    commands+=("-g")
    commands+=("-b")
    commands+=("-h")

    flags=()
    flags+=("-g")
    flags+=("-b")
    flags+=("-h")
}

_tools_-t_backup()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_backup"

    commands=()
    commands+=("-f")

    flags=()
    flags+=("-f")
}

_tools_-t_backup_-f()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_backup_-f"

    commands=()
    commands+=("project")
    commands+=("nacos")

    flags=()
    flags+=("-e")
}

_tools_-t_backup_-f_-e()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_backup_-f_-e"

    commands=()
    for env_name in $(tools -t env | awk -F '|' '{print $2}' | tail -n +4 | grep -v "^$")
    do
        commands+=("$env_name")
    done

    flags=()
    # flags+=("-e")
}

_tools_-t_rollbackplus()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_rollbackplus"

    commands=()
    commands+=("-e")

    flags=()
    flags+=("-e")
}

_tools_-t_rollbackplus_-e()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t_rollbackplus_-e"

    commands=()
    for env_name in $(tools -t env | awk -F '|' '{print $2}' | tail -n +4 | grep -v "^$")
    do
        commands+=("$env_name")
    done

    flags=()
    flags+=("-l")
    flags+=("-b")
    flags+=("-a")
    flags+=("-y")
}

_tools_-t()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools_-t"

    commands=()
    commands+=("host")
    commands+=("env")
    commands+=("job")
    commands+=("rollback")
    commands+=("restart")
    commands+=("branch")
    commands+=("build")
    commands+=("gitlab")
    commands+=("deljenkins")
    commands+=("addjenkins")
    commands+=("grafana")
    commands+=("nacosjdbc")
    commands+=("backup")
    commands+=("rollbackplus")

    # has_completion_function=1
}



_tools_root_command()
{
    __tools_debug "${FUNCNAME[0]}"
    last_command="tools"

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    commands=()
    commands+=("-t")
    flags_with_completion+=("-t")

    must_have_one_flag=()
    # must_have_one_flag+=("--image=")
    # must_have_one_flag+=("--schedule=")
    # must_have_one_flag+=("-t")
    # must_have_one_flag+=("-t")

    must_have_one_noun=()
    # must_have_one_noun+=("-t")


    flags+=("-t")
    flags_completion+=("-t")
    # has_completion_function=1
}

__tools_handle_go_custom_completion_test()
{
    __tools_debug "${FUNCNAME[0]}: cur is ${cur}, words[*] is ${words[*]}, #words[@] is ${#words[@]}"
    local out requestComp lastParam lastChar comp directive args
    requestComp=$()
    # _tools_-t

    out=("${commands[@]}")

    while IFS='' read -r comp; do
        COMPREPLY+=("$comp")
    done < <(compgen -W "${out[*]}" -- "$cur")
}

__tools_handle_go_custom_completion()
{
    __tools_debug "${FUNCNAME[0]}: cur is ${cur}, words[*] is ${words[*]}, #words[@] is ${#words[@]}"

    local shellCompDirectiveError=1
    local shellCompDirectiveNoSpace=2
    local shellCompDirectiveNoFileComp=4
    local shellCompDirectiveFilterFileExt=8
    local shellCompDirectiveFilterDirs=16

    local out requestComp lastParam lastChar comp directive args

    # Prepare the command to request completions for the program.
    # Calling ${words[0]} instead of directly tools allows to handle aliases
    args=("${words[@]:1}")
    requestComp="${words[0]} __completeNoDesc ${args[*]}"

    lastParam=${words[$((${#words[@]}-1))]}
    lastChar=${lastParam:$((${#lastParam}-1)):1}
    __tools_debug "${FUNCNAME[0]}: lastParam ${lastParam}, lastChar ${lastChar}"

    if [ -z "${cur}" ] && [ "${lastChar}" != "=" ]; then
        # If the last parameter is complete (there is a space following it)
        # We add an extra empty parameter so we can indicate this to the go method.
        __tools_debug "${FUNCNAME[0]}: Adding extra empty parameter"
        requestComp="${requestComp} \"\""
    fi

    __tools_debug "${FUNCNAME[0]}: calling ${requestComp}"
    # Use eval to handle any environment variables and such
    out=$(eval "${requestComp}" 2>/dev/null)

    # Extract the directive integer at the very end of the output following a colon (:)
    directive=${out##*:}
    # Remove the directive
    out=${out%:*}
    if [ "${directive}" = "${out}" ]; then
        # There is not directive specified
        directive=0
    fi
    __tools_debug "${FUNCNAME[0]}: the completion directive is: ${directive}"
    __tools_debug "${FUNCNAME[0]}: the completions are: ${out[*]}"

    if [ $((directive & shellCompDirectiveError)) -ne 0 ]; then
        # Error code.  No completion.
        __tools_debug "${FUNCNAME[0]}: received error from custom completion go code"
        return
    else
        if [ $((directive & shellCompDirectiveNoSpace)) -ne 0 ]; then
            if [[ $(type -t compopt) = "builtin" ]]; then
                __tools_debug "${FUNCNAME[0]}: activating no space"
                compopt -o nospace
            fi
        fi
        if [ $((directive & shellCompDirectiveNoFileComp)) -ne 0 ]; then
            if [[ $(type -t compopt) = "builtin" ]]; then
                __tools_debug "${FUNCNAME[0]}: activating no file completion"
                compopt +o default
            fi
        fi
    fi

    if [ $((directive & shellCompDirectiveFilterFileExt)) -ne 0 ]; then
        # File extension filtering
        local fullFilter filter filteringCmd
        # Do not use quotes around the $out variable or else newline
        # characters will be kept.
        for filter in ${out[*]}; do
            fullFilter+="$filter|"
        done

        filteringCmd="_filedir $fullFilter"
        __tools_debug "File filtering command: $filteringCmd"
        $filteringCmd
    elif [ $((directive & shellCompDirectiveFilterDirs)) -ne 0 ]; then
        # File completion for directories only
        local subDir
        # Use printf to strip any trailing newline
        subdir=$(printf "%s" "${out[0]}")
        if [ -n "$subdir" ]; then
            __tools_debug "Listing directories in $subdir"
            __tools_handle_subdirs_in_dir_flag "$subdir"
        else
            __tools_debug "Listing directories in ."
            _filedir -d
        fi
    else
        while IFS='' read -r comp; do
            COMPREPLY+=("$comp")
        done < <(compgen -W "${out[*]}" -- "$cur")
    fi
}

__tools_handle_reply()
{
    __tools_debug "${FUNCNAME[0]} cur: ${cur} prev: ${prev}"
    local comp
    case $cur in
        -*)
            if [[ $(type -t compopt) = "builtin" ]]; then
                compopt -o nospace
            fi
            local allflags
            if [ ${#must_have_one_flag[@]} -ne 0 ]; then
                allflags=("${must_have_one_flag[@]}")
            else
                allflags=("${flags[*]} ${two_word_flags[*]}")
            fi
            __tools_debug "${FUNCNAME[0]} allflags: ${allflags[*]}"
            while IFS='' read -r comp; do
                COMPREPLY+=("$comp")
            done < <(compgen -W "${allflags[*]}" -- "$cur")
            if [[ $(type -t compopt) = "builtin" ]]; then
                [[ "${COMPREPLY[0]}" == *= ]] || compopt +o nospace
            fi

            # complete after --flag=abc
            if [[ $cur == *=* ]]; then
                if [[ $(type -t compopt) = "builtin" ]]; then
                    compopt +o nospace
                fi

                local index flag
                flag="${cur%=*}"
                __tools_index_of_word "${flag}" "${flags_with_completion[@]}"
                COMPREPLY=()
                if [[ ${index} -ge 0 ]]; then
                    PREFIX=""
                    cur="${cur#*=}"
                    ${flags_completion[${index}]}
                    if [ -n "${ZSH_VERSION}" ]; then
                        # zsh completion needs --flag= prefix
                        eval "COMPREPLY=( \"\${COMPREPLY[@]/#/${flag}=}\" )"
                    fi
                fi
            fi
            return 0;
            ;;
    esac

    # check if we are handling a flag with special work handling
    # local index
    # __tools_index_of_word "${prev}" "${flags_with_completion[@]}"
    # if [[ ${index} -ge 0 ]]; then
    #     __tools_debug "${FUNCNAME[0]} index: $index"
    #     ${flags_completion[${index}]}
    #     # return
    # fi

    # we are parsing a flag and don't have a special handler, no completion
    if [[ ${cur} != "${words[cword]}" ]]; then
        __tools_debug "${FUNCNAME[0]} cur"
        return
    fi

    local completions
    completions=("${commands[@]}")
    if [[ ${#must_have_one_noun[@]} -ne 0 ]]; then
        __tools_debug "${FUNCNAME[0]} must_have_one_noun"
        completions+=("${must_have_one_noun[@]}")
    elif [[ -n "${has_completion_function}" ]]; then
        __tools_debug "${FUNCNAME[0]} has_completion_function: ${has_completion_function}"
        # if a go completion function is provided, defer to that function
        __tools_handle_go_custom_completion_test
    fi
    if [[ ${#must_have_one_flag[@]} -ne 0 ]]; then
        __tools_debug "${FUNCNAME[0]} must_have_one_flag"
        completions+=("${must_have_one_flag[@]}")
    fi
    __tools_debug "${FUNCNAME[0]} while "${completions[*]}""
    while IFS='' read -r comp; do
        COMPREPLY+=("$comp")
    done < <(compgen -W "${completions[*]}" -- "$cur")

    if [[ ${#COMPREPLY[@]} -eq 0 && ${#noun_aliases[@]} -gt 0 && ${#must_have_one_noun[@]} -ne 0 ]]; then
        __tools_debug "${FUNCNAME[0]} noun_aliases"
        while IFS='' read -r comp; do
            COMPREPLY+=("$comp")
        done < <(compgen -W "${noun_aliases[*]}" -- "$cur")
    fi

    if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
        __tools_debug "${FUNCNAME[0]} COMPREPLY"
		if declare -F __kubectl_custom_func >/dev/null; then
			# try command name qualified custom func
			__kubectl_custom_func
		else
			# otherwise fall back to unqualified for compatibility
			declare -F __custom_func >/dev/null && __custom_func
		fi
    fi

    # available in bash-completion >= 2, not always present on macOS
    if declare -F __ltrim_colon_completions >/dev/null; then
        __ltrim_colon_completions "$cur"
    fi

    # If there is only 1 completion and it is a flag with an = it will be completed
    # but we don't want a space after the =
    if [[ "${#COMPREPLY[@]}" -eq "1" ]] && [[ $(type -t compopt) = "builtin" ]] && [[ "${COMPREPLY[0]}" == --*= ]]; then
       compopt -o nospace
    fi
}



__tools_handle_command()
{
    __tools_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    local next_command
    local flagname=${words[c]}

    __tools_debug "${FUNCNAME[0]}: looking for ${flagname}"
    if __tools_contains_word "${flagname}" "${must_have_one_flag[@]}"; then
        __tools_debug "${FUNCNAME[0]}: looking for ${flagname}"
        must_have_one_flag=()
    fi

    # if you set a flag which only applies to this command, don't show subcommands
    if __tools_contains_word "${flagname}" "${local_nonpersistent_flags[@]}"; then
        __tools_debug "${FUNCNAME[0]}: looking for ${flagname}"
        commands=()
    fi


    if [[ -n ${last_command} ]]; then
        next_command="_${last_command}_${words[c]//:/__}"
    else
        if [[ $c -eq 0 ]]; then
            next_command="_tools_root_command"
        else
            next_command="_${words[c]//:/__}"
        fi
    fi
    c=$((c+1))
    __tools_debug "${FUNCNAME[0]}: looking for ${next_command}"
    declare -F "$next_command" >/dev/null && $next_command
}

__tools_handle_word()
{
    if [[ $c -ge $cword ]]; then
        __tools_handle_reply
        return
    fi
    __tools_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"
    if [[ "${words[c]}" == - ]]; then
        __tools_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}: -"
        __tools_handle_flag
    elif [[ "${words[c]}" == -* ]] && [[ -z "${words[$((c+2))]}" ]]; then
        __tools_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}: has_completion"
        # __tools_handle_flag
        __tools_handle_command
    elif __tools_contains_word "${words[c]}" "${commands[@]}"; then
        __tools_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}: tools_contans_word"
        __tools_handle_command
    elif [[ $c -eq 0 ]]; then
        __tools_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}: elif -eq 0"
        __tools_handle_command
    else
        __tools_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}: else"
        __tools_handle_noun
    fi
    __tools_handle_word
}

__start_tools()
{
    local cur prev words cword split
    declare -A flaghash 2>/dev/null || :
    declare -A aliashash 2>/dev/null || :
    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion -s || return
    else
        __tools_init_completion -n "=" || return
    fi

    local c=0
    local flags=()
    local two_word_flags=()
    local local_nonpersistent_flags=()
    local flags_with_completion=()
    local flags_completion=()
    local commands=("tools")
    local must_have_one_flag=()
    local must_have_one_noun=()
    local last_command
    local has_completion_function

    __tools_handle_word
}

complete -F __start_tools tools
