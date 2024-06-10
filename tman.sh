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
    myopts="-e package.path = \"$TMAN_CONFIG_FILE;\" .. package.path; local conf = require('tman_conf')"
    base="$(lua "$myopts; print(conf.base)")"
    inst="$(lua "$myopts; print(conf.install)")"

    base="${base/\~/$HOME}"
    inst="${inst/\~/$HOME}"

    # make sure base is valid and exists
    if [ "$base" = "nil" ]; then
        echo "error: no base varibale in config"
        return 1
    fi
    if [ ! -d "$base" ]; then
        echo "error:${base}: base directory doesn't exist"
        return 1
    fi

    # make sure inst is valid and exists
    if [ "$inst" = "nil" ]; then
        echo "error: no inst varibale in config"
        return 1
    fi
    if [ ! -d "$inst" ]; then
        echo "error:${inst}: inst directory doesn't exist"
        return 1
    fi

    TMAN_BASE="$base"
    TMAN_INSTALL="$inst"
    return 0
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
