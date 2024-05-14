#!/bin/bash

usage()
{
    cat << EOF
Usade: ./install.sh [OPTION]

Options:
    -c      check system utils and luarocks (default).
    -i      install system utils and luarocks
    -h      show this help message
EOF
}

check_system_utils()
{
    local system_utils=("tar" "luarocks")
    for sutil in ${system_utils[@]}; do
        which -s $sutil > /dev/null
        if [ $? -ne 0 ]; then
            echo "- System util '$sutil' is missing"
        fi
    done
    echo "check: System utils is done" && echo
}

check_lua_rocks()
{
    local lua_rocks=("luaposix")
    for lutil in ${lua_rocks[@]}; do
        luarocks list | grep -q "$lutil"
        if [ $? -ne 0 ]; then
            echo "- Luarock '$lutil' is missing"
        fi
    done
    echo "check: Lua rocks check is done" && echo
}

install_lua_rocks()
{
    local lua_rocks=("luaposix")
    for lutil in ${lua_rocks[@]}; do
        echo "- install Lua rock: $lutil"
        luarocks install $lutil
    done
    echo "Necessary Lua rocks installed"
}

install_system_utils()
{
    local system_utils="tar luarocks"
    sudo apt install -y ${system_utils}
}

if [ "$1" = "-i" ]; then
    install_system_utils
    install_lua_rocks
elif [ -z "$1" -o "$1" = "-c" ]; then
    check_system_utils
    check_lua_rocks
elif [ "$1" = "-h" ]; then
    usage
else
    echo "unknown option '${1}'. Use option '-h' to get some help."
fi
