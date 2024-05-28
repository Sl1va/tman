PROGNAME="tman"
TMAN_BASE=""
TMAN_INSTALL=""
TMAN_CONFIG_FILE=""
TMAN=""

function _tman_find_config()
{
    local confname="tman_conf.lua"
    local tman_config_files=(
        "${HOME}/.tman/${confname}"
        "${HOME}/.config/tman/${confname}"
    )

    for file in ${tman_config_files[@]}; do
        if [ -f "$file" ]; then
            TMAN_CONFIG_FILE="${file}"
            return 0
        fi
    done
    return 1
}

function _tman_get_config()
{
    TMAN_BASE="$(cat "$TMAN_CONFIG_FILE" | grep "^\bTMANBase\b" | awk '{print $3}' | tr -d '"')"
    TMAN_INSTALL="$(cat "$TMAN_CONFIG_FILE" | grep -E "^\bTMANInstall\b" | awk '{print $3}' | tr -d '"')"

    # Expand tilde to $HOME
    TMAN_INSTALL="${TMAN_INSTALL/#\~/$HOME}"
    TMAN_BASE="${TMAN_BASE/#\~/$HOME}"

    if [ -z "$TMAN_BASE" ] || [ ! -d $TMAN_BASE ]; then
        echo "err: no BASE path in the config"
        return 1
    fi
    if [ -z "$TMAN_INSTALL" ] || [ ! -d $TMAN_INSTALL ]; then
        echo "err: no such INSTALL file '$TMAN_INSTALL'"
        return 1
    fi
}

function tman()
{
    _tman_find_config
    if [ $? -ne 0 ]; then
        echo "${PROGNAME}: no config file found"
        return 1
    fi

    _tman_get_config
    if [ $? -ne 0 ]; then
        return 1
    fi

    # roachme: refactor this piece of shit
    TMAN="${TMAN_INSTALL}/src/tman.lua"
    TASKS="${TMAN_BASE}/tasks"

    MYLUA_PATH="${TMAN_INSTALL}/src/?.lua;"
    MYCONF_PATH="$(dirname ${TMAN_CONFIG_FILE})/?.lua"

    MYPATH="package.path = package.path .. ';${MYLUA_PATH};${MYCONF_PATH}'"


    MYLUA="lua -e \"$MYPATH\""
    TMANCMD="$MYLUA ${TMAN}"

    eval $TMANCMD $@
    RET=$?

    if [ $RET -eq 0 ] && [ "$1" = "add" ]; then
        cd $TASKS/${2}
        wd -q rm task
        wd -q add task
        wd task

    elif [ $RET -eq 0 ] && [ "$1" = "use" ]; then
        cd $TASKS/${2}
        wd -q rm task
        wd -q add task
        wd task

    elif [ $RET -eq 0 ] && [ "$1" = "prev" ]; then
        TASKID=$(eval $TMANCMD _curr -i)
        cd $TASKS/${TASKID}
        wd -q rm task
        wd -q add task
        wd task

    elif [ $RET -eq 0 ] && [ "$1" = "move" ]; then
        if [ ! -z "$3" ] && [ "$2" = "progress" ]; then
            cd $TASKS/${3}
            wd -q -f add task
            wd task
        fi

    elif [ $RET -eq 0 ] && [ "$1" = "done" ]; then
        cd $TASKS
        wd -q -f add task

    # tman amend DE-me4 -i
elif [ $RET -eq 0 ] && [ "$1" = "amend" ] && [ "$3" = "-i" ]; then
    TASKID=$(eval $TMANCMD _curr -i)
    cd $TASKS/${TASKID}
    wd -q rm task
    wd -q add task
    wd task

elif [ "$1" = "del" ]; then
    TASKID="$(eval $TMANCMD _curr -i)"
    if [ -n "$TASKID" ]; then
        cd $TASKS/$TASKID
        wd -q -f add task
        wd task
    else
        wd -q rm task
        cd $TASKS
    fi
    fi
}
