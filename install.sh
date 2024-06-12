#!/bin/bash

usage()
{
    cat << EOF
Usage: ./install.sh [USERTYPE] [OPTION]

USERTYPE - install for user or developer

Options:
    -c      check system utils and luarocks (default).
    -i      install system utils and luarocks
    -g      generate and install system config
    -h      show this help message
EOF
}

generate_system_config()
{
    local tmanbase="$HOME/tman"
    local tmancore="$HOME/.tman"
    local tmaninst="$(pwd)" # roachme: pro'ly change it to ~/.local/bin
    local tmanconf="$tmancore/sys.conf"

    # create tman core directory
    mkdir -p "$tmancore"

    # create tman base directory
    mkdir -p "$tmanbase"

    # create tman system config
    touch "$tmanconf"

    # fill tman system config
    echo "# NOT recommended to change this file manually." > "$tmanconf"
    echo "base = $tmanbase" >> "$tmanconf"
    echo "core = $tmancore" >> "$tmanconf"
    echo "install = $tmaninst" >> "$tmanconf"

    # create task ID database file
    touch "$tmancore/taskids"

    # create task units database directory
    mkdir -p "$tmancore/units"

    # and finally, create user config file
    touch "$tmancore/user.conf"
}

check_system_utils()
{
    local system_utils=("tar" "luarocks" "cargo")
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

# TODO: add a checker to not install it more than once
install_shell()
{
    # env SHELL might be not set
    local USERSHELL="$(basename $(getent passwd $(whoami) | awk -F: '{print $7}'))"

    if [ "$USERSHELL" == "bash" ]; then
        echo "install into bash"
    elif [ "$USERSHELL" == "zsh" ]; then
        echo "install into zsh"
    else
        echo "Unsupported shell '$USERSHELL'"
        exit 1
    fi
    echo "source $(pwd)/tman.sh" >> "${HOME}/.${USERSHELL}rc"
    echo "'source ~/$USERSHELL' - to restart shell"
}


if [ "$1" = "-i" ]; then
    install_system_utils
    install_lua_rocks
    install_shell
    cargo install stylua # roachme: find a better way
elif [ -z "$1" -o "$1" = "-c" ]; then
    check_system_utils
    check_lua_rocks
elif [ "$1" = "-g" ]; then
    generate_system_config
elif [ "$1" = "-h" ]; then
    usage
else
    echo "unknown option '${1}'. Use option '-h' to get some help."
fi
