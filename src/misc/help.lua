--- Provide help.
-- @module help


local log = require("misc/log").init("help")

local version = "0.2.0"
local progname = "tman"

local function help_usage()
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
  link    - create task symlinks
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
  check   - check paths and configs for proper work
  backup  - backup configs and metadata
  restore - restore configs and metadata

For utils:
  _curr    - show current task
]]):format(progname))
end

local cmds = {
    {
        name = "add",
        desc = [[
Usage: tman add TASKID TASKTYPE PRIORITY
Add new task.

Notes:
    TASKID      task ID
    TASKTYPE    task type (available: feature, bugfix, hotfix).
    PRIORITY    task priority (available: lowest, low, mid, high, highest).
]],
    },
    {
        name = "del",
        desc = [[
Usage: tman del TASKID
Delete task.

Notes:
    TASKID      task ID
]],
    },
    {
        name = "amend",
        desc = [[
Usage: tman amend TASKID OPTION
Amend task.

Options:
    -d      amend task description
    -p      amend task priority
    -i      amend task ID
]],
    },

    {
        name = "done",
        desc = [[
Usage: tman done TASKID
Move task to done status.
]],
    },

    {
        name = "use",
        desc = [[
Usage: tman use TASKID
Switch to specified task. Use `tman list` to see existing tasks.
]],
    },
    {
        name = "prev",
        desc = [[
Usage: tman prev
Switch to previous task. If no previous task exist informs about it.
]],
    },
    {
        name = "list",
        desc = [[
Usage: tman list [OPTION]
List task IDs with description.

Options:
    -c   List only complete tasks.
    -a   List only active tasks (default).
    -A   List all tasks: active and complete.
Notes:
    *   Marks current task.
    -   Makrs previous task.
]],
    },
    {
        name = "link",
        desc = [[
Usage: tman link TASKID
Create task symlinks.
]],
    },
    {
        name = "show",
        desc = [[
Usage: tman show [TASKID]
Show task units (current task by default).
]],
    },
    {
        name = "help",
        desc = [[
Usage: tman help
Show list of commands with description.
]],
    },
    {
        name = "ver",
        desc = [[
Usage: tman ver
Show tman version.
]],
    },
}

--- Get detailed info about command.
-- @param cmdname command name to get info about
local function help_info(cmdname)
    if not cmdname then
        log:warning("command to look up is missing")
        return false
    end

    for _, cmd in ipairs(cmds) do
        if cmd.name == cmdname then
            return print(cmd.desc)
        end
    end
    return log:warning("no such command '%s'", cmdname)
end

return {
    usage = help_usage,
    info = help_info,
    version = version,
    progname = progname,
}
