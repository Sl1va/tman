TMAN_BASE=""
TMAN_INSTALL=""
TMAN_CONFIG_FILE="${HOME}/.config/tman/config"

TMAN=""


function _tman_get_config()
{
   if [ ! -f $TMAN_CONFIG_FILE ]; then
       echo "err: no config file"
       return 1
   fi

    grep -q '\bInstall\b' $TMAN_CONFIG_FILE
    if [ $? -ne 0 ]; then
        echo "err:config: no installation path in the config"
        return 1
    fi

    grep -q '\bBase\b' $TMAN_CONFIG_FILE
    if [ $? -ne 0 ]; then
        echo "err:config: no base path in the config"
        return 1
    fi

    # Eval config values
    TMAN_INSTALL="$(grep '\bInstall\b' ${TMAN_CONFIG_FILE} | tr -s ' ' | cut -d ' ' -f 2)"
    TMAN_BASE="$(grep '\bBase\b' ${TMAN_CONFIG_FILE} | tr -s ' ' | cut -d ' ' -f 2)"
    eval TMAN_INSTALL="$(echo ${TMAN_INSTALL} | sed -e 's/~/${HOME}/')"
    eval TMAN_BASE="$(echo ${TMAN_BASE} | sed -e 's/~/${HOME}/')"

    # Check config values
   if [ ! -d $TMAN_INSTALL ]; then
       echo "err: no such INSTALL file '$TMAN_INSTALL'"
       return 1
   fi
   if [ ! -d $TMAN_BASE ]; then
       echo "err: no such BASE file '$TMAN_BASE'"
       return 1
   fi

    return 0
}

function tman()
{
    _tman_get_config
    if [ $? -ne 0 ]; then
        return 1
    fi

    # roachme: refactor this piece of shit
    TMAN="${TMAN_INSTALL}/src/tman.lua"
    TASKS="${TMAN_BASE}/tasks"
    MYLUA_PATH="${TMAN_INSTALL}/src/?.lua;"
    MYPATH="package.path = '${MYLUA_PATH}' .. package.path"
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
