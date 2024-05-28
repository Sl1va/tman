PROGNAME="tman"
TMAN_BASE=""
TMAN_INSTALL=""
TMAN_CONFIG_FILE=""
TASKS=""
TMANCMD=""


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

function _tman_form_command()
{
    local lua_path_tman="${TMAN_INSTALL}/src/?.lua;"
    local lua_path_conf="$(dirname ${TMAN_CONFIG_FILE})/?.lua;"
    local lua_path="package.path = package.path .. ';${lua_path_tman};${lua_path_conf}'"

    TMAN="${TMAN_INSTALL}/src/tman.lua"
    TASKS="${TMAN_BASE}/tasks"
    TMANCMD="lua -e \"$lua_path\" ${TMAN}"
}

function _tman_handle_commands()
{
    local retcode="$1"
    local command="$2"
    local taskdir="$3"

    if [ $retcode -eq 0 ] && [ "$command" = "add" ]; then
        cd "$TASKS/$taskdir"
        wd -q rm task
        wd -q add task
        wd task

    elif [ $retcode -eq 0 ] && [ "$command" = "use" ]; then
        cd "$TASKS/$taskdir"
        wd -q rm task
        wd -q add task
        wd task

    elif [ $retcode -eq 0 ] && [ "$command" = "prev" ]; then
        TASKID=$(eval $TMANCMD _curr -i)
        cd "$TASKS/$TASKID"
        wd -q rm task
        wd -q add task
        wd task

    elif [ $retcode -eq 0 ] && [ "$command" = "move" ]; then
        if [ ! -z "$4" ] && [ "$3" = "progress" ]; then
            cd "$TASKS/$taskdir"
            wd -q -f add task
            wd task
        fi

    elif [ $retcode -eq 0 ] && [ "$command" = "done" ]; then
        cd "$TASKS"
        wd -q -f add task

    elif [ $retcode -eq 0 ] && [ "$command" = "amend" ] && [ "$4" = "-i" ]; then
        TASKID=$(eval $TMANCMD _curr -i)
        cd $TASKS/${TASKID}
        wd -q rm task
        wd -q add task
        wd task

    elif [ "$command" = "del" ]; then
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

    _tman_form_command
    eval $TMANCMD $@

    _tman_handle_commands $? $@
}
