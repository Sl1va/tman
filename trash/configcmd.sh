#!/bin/bash

FCONFIG="config"

function check_config_var()
{
    local var="$1"
    local config_vars=("base" "core" "install")

    for cvar in "${config_vars[@]}"; do
        if [ "$var" = "$cvar" ]; then
            return 1
        fi
    done
    return 0
}

function set_config_option()
{
    local var="$1"
    local val="$2"

    #sed "s/\($var *= *\).*/\1$val/" $FCONFIG
    # replace / wih @, cuz path has slashes
    sed "s@\($var *= *\).*@\1$val@" $FCONFIG
}

function get_config_option()
{
    local var="$1"
    grep "$var" "$FCONFIG"
}

function _tman_config()
{
    echo "configcmd.sh"

    while getopts "b:i:s" arg "${@}"; do
        case "$arg" in
            b)
                echo "optarg: $OPTARG"
                set_config_option "base" "$OPTARG"
                set_config_option "core" "${OPTARG}/.tman"
                ;;
            i)
                echo "optarg: $OPTARG"
                set_config_option "install" "$OPTARG"
                ;;
            s)
                get_config_option "base"
                get_config_option "core"
                get_config_option "install"
                ;;
            *)
                echo "usage: unrecognized opton $OPTOPT"
                ;;
        esac
    done
}

