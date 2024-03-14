local Help = {}

local log = require("log").init("help")

Help.version = "0.1.0"
Help.progname = "tman"

function Help.usage()
    print(([[
Usage: %s COMMAND [ID]
Basic:
  use     - mark a task as current
  prev    - switch to previous task
  list    - list all tasks. Default: active tasks
  show    - show task info. Default: current task
  time    - time spent on task

Amend:
  add     - add new task
  del     - delete task
  amend   - amend task units
  config  - config for your workflow
  update  - update git repos

Info:
  ver     - show version
  help    - show this help message
  info    - show detailed info about commands and important info

Contribute:
  review  - push commits for review
  done    - move task to status complete

For developers:
  init    - download repos and create symlinks for all of them
  backup  - backup configs and metadata
  restore - restore configs and metadata

For utils:
  _curr    - show current task
]]):format(Help.progname))
end

local cmds = {
    {
        name = "add",
        desc = [[
Usage: tman add TASKID PRIORITY
Add new task.

Notes:
    TASKID      task ID
    PRIORITY    task priority (available: feature, bugfix, hotfix).
]]
    },
    {
        name = "del",
        desc = [[
Usage: tman del TASKID
Delete task.

Notes:
    TASKID      task ID
]]
    },

    {
        name = "use",
        desc = [[
Usage: tman use TASKID
Switch to specified task. Use `tman list` to see existing tasks.
]]
    },
    {
        name = "prev",
        desc = [[
Usage: tman prev
Switch to previous task. If no previous task exist informs about it.
]]
    },
    {
        name = "list",
        desc = [[
Usage: tman list [OPTION]
List task IDs with description (active tasks by default). See section Options.

Options:
    -a   List only active tasks.
    -c   List only complete tasks.
    -A   List all tasks (active and complete).
Notes:
    *   Marks current task.
    -   Makrs previous task.
]]
    },
    {
        name = "show",
        desc = [[
Usage: tman show [TASKID]
Show task units (current task by default).
]]
    },
    {
        name = "help",
        desc = [[
Usage: tman help
Show list of commands with description.
]]
    },
    {
        name = "ver",
        desc = [[
Usage: tman ver
Show tman version.
]]
    },
}

--- Get detailed info about command.
-- @param cmdname command name to get info about
function Help:info(cmdname)
    for _, cmd in ipairs(cmds) do
        if cmd.name == cmdname then
           return print(cmd.desc)
        end
    end
    if cmdname then
        log:warning("no such command '%s'", cmdname)
    else
        log:warning("command to look up is missing")
    end
end

return Help
