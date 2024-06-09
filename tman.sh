PROGNAME="tman"
TMAN_BASE=""
TMAN_INSTALL=""
TMAN_CONFIG_FILE=""
TASKS=""
TMANCMD=""
CONFNAME="tman_conf.lua"

# Error codes
TMANERR_OK=0
TMANERR_NOT_INITED=1
TMANERR_CORRUPTED=2
TMANERR_COMMAND_FAILED=3
TMANERR_COMMAND_NOT_FOUND=4



function _tman_find_config()
{
    local tman_config_files=(
        "${HOME}/.tman/${CONFNAME}"
        "${HOME}/.config/tman/${CONFNAME}"
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

    if [ -z "$TMAN_BASE" ]; then
        echo "err: no TMANBase path in the config"
        return 1
    elif [ ! -d $TMAN_BASE ]; then
        echo "err:TMANBase: no such directory $TMAN_BASE"
        return 1
    fi

    if [ -z "$TMAN_INSTALL" ]; then
        echo "err: no TMANInstall path in config"
        return 1
    elif [ ! -d $TMAN_INSTALL ]; then
        echo "err:TMANInstall: no such directory $TMAN_INSTALL"
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
    local command="$1"
    local taskdir="$2"

    # roachme: maybe it's better to use cases?
    if [ "$command" = "add" ]; then
        cd "$TASKS/$taskdir"
        wd -q rm task
        wd -q add task
        wd task

    elif [ "$command" = "use" ]; then
        cd "$TASKS/$taskdir"
        wd -q rm task
        wd -q add task
        wd task

    elif [ "$command" = "prev" ]; then
        TASKID=$(eval $TMANCMD get curr)
        cd "$TASKS/$TASKID"
        wd -q rm task
        wd -q add task
        wd task

    elif [ "$command" = "move" ]; then
        if [ ! -z "$4" ] && [ "$3" = "progress" ]; then
            cd "$TASKS/$taskdir"
            wd -q -f add task
            wd task
        fi

    elif [ "$command" = "done" ]; then
        cd "$TASKS"
        wd -q -f add task

    elif [ "$command" = "set" ]; then
        # FIXME: switch only when changing task ID, not always.
        # Fix a good way to parse option '-i' for renaming task ID.
        TASKID=$(eval $TMANCMD get curr)
        cd $TASKS/${TASKID}
        wd -q rm task
        wd -q add task

    elif [ "$command" = "del" ]; then
        TASKID="$(eval $TMANCMD get curr)"
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
        echo "${PROGNAME}: not found: '$CONFNAME'"
        return 1
    fi

    _tman_get_config
    if [ $? -ne 0 ]; then
        return 1
    fi

    _tman_form_command
    eval $TMANCMD $@
    if [ "$?" -ne 0 ]; then
        return 1
    fi
    _tman_handle_commands $@
    return $?
}
