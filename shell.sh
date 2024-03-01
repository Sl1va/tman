function tman()
{
    TASKS="${HOME}/work/tman/tasks"
    TMAN="${HOME}/personal/prjs/tman/src/tman.lua"
    lua $TMAN $@
    RET=$?

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
        TASKID=$(lua $TMAN _curr -i)
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
    fi
}
