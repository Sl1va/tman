function tman()
{
    CWD=$(pwd)
    TASKS="$HOME/work/tasks"
    CURRTASK=$(cat "$HOME/work/tasks/.curr")
    cd ${HOME}/personal/prjs/tman/src
    lua tman.lua $@
    RET=$?

    # tman new DE-me
    # tman use DE-me
    # tman prev
    if [ $RET -eq 0 ] && [ "$1" = "new" ]; then
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
        TASKID=$(lua tman.lua curr)
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

    elif [ "$1" = "del" ]; then
        cd $TASKS

    elif [ $RET -ne 0 ]; then
        echo $CURRTASK > $CURRTASK

    else
        cd $CWD
    fi
}
