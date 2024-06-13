#!/bin/bash

TMAN=""
TMAN_WD=
TMAN_BASE=
TMAN_INSTALL=
TMAN_TMANCONF=


# tman -b basepath -c configpath CMD OPTIONS arg


function _tman_handle_command()
{
    local cmd="$2"
    local base="$TMAN_BASE"
    local envcurr=""

    if [ "$cmd" = "add" ]; then
        local taskid="$3"
        local taskdir="${base}/${envcurr}/tasks/${taskid}"
        cd "$taskdir"
        wd add -q -f task

    elif [ "$cmd" = "del" ]; then
        local taskid="$(eval $TMAN get curr)"
        local taskdir="${base}/${envcurr}/tasks/${taskid}"
        cd "$taskdir"
        if [ -n "$taskid" ]; then
            wd add -q -f task
        else
            wd rm -q task
        fi

    elif [ "$cmd" = "prev" ]; then
        local taskid="$(eval $TMAN get curr)"
        local taskdir="${base}/${envcurr}/tasks/${taskid}"
        cd "$taskdir"
        wd add -q -f task

    elif [ "$cmd" = "set" ]; then
        echo "WARNING:shell: set: under development"

    elif [ "$cmd" = "use" ]; then
        local taskid="$3"
        local taskdir="${base}/${envcurr}/tasks/${taskid}"
        cd "$taskdir"
        wd add -q -f task
    fi
}

function _tman_get_tmanconf()
{
    TMAN_TMANCONF="${HOME}/.tman/sys.conf"
}

function _tman_get_sys_config_vars()
{
    _tman_get_tmanconf
    TMAN_BASE="$(grep base "$TMAN_TMANCONF" | cut -f 2 -d '=' | tr -d ' ' | tr -d '"' | tr -d "'")"
    TMAN_INSTALL="$(grep install "$TMAN_TMANCONF" | cut -f 2 -d '=' | tr -d ' ' | tr -d '"' | tr -d "'")"
}

function _tman_form_full_command()
{
    local script="${TMAN_INSTALL}/src/tman.lua"
    local tman_conf="/home/roach/.config/tman/tman_conf.lua"

    local stat="package.path = package.path"
    stat="$stat .. ';${TMAN_INSTALL}/src/?.lua;'"
    stat="$stat .. '/home/roach/.config/tman/?.lua'"

    TMAN="lua -e \"$stat\" $script"
}

function tman()
{
    local retcode=

    eval $TMAN $@
    retcode="$?"

    if [ $retcode -ne 0 ]; then
        return $retcode
    fi

    _tman_handle_command $@
}


# Run command
_tman_get_sys_config_vars
_tman_form_full_command
tman $@
