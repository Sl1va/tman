#!/bin/bash


usage()
{
    cat << EOF
Usage: ./install.sh [USERTYPE] [OPTION]

USERTYPE - install for user or developer

Options:
    -c      check system utils and luarocks (default).
    -i      install system utils and luarocks
    -h      show this help message
EOF
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
elif [ "$1" = "-h" ]; then
    usage
else
    echo "unknown option '${1}'. Use option '-h' to get some help."
fi
