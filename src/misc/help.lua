--- Provide help on commands and general usage.
-- @module help

local version = "0.2.0"
local progname = "tman"

local function show_usage()
    io.stdout:write(([[
Usage: %s COMMAND [OPTION] [ID]
Use '%s help COMMAND' to get detailed info about command and its options.

COMMANDS:
Kickoffs:
  init    - init util structure.
  backup  - backup configs and metadata
  restore - restore configs and metadata

Basic:
  list    - list tasks
  show    - show task info
  use     - mark a task as current
  prev    - switch to previous task

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

For utils:
  _curr   - show current task
]]):format(progname, progname))
end

local cmds = {
    {
        name = "add",
        desc = [[
Usage: tman add TASKID [TASKTYPE] [PRIORITY]
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
Usage: tman del [TASKID]
Delete task.

Notes:
    TASKID      task ID. Default current task ID
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

--- Get general and detailed info about command.
-- @param cmdname command name to get info about
local function help_usage(cmdname)
    local errmsg = "%s: no such command '%s'. Use '%s help' for more info.\n"

    if not cmdname then
        show_usage()
        return true
    end

    for _, cmd in ipairs(cmds) do
        if cmd.name == cmdname then
            return io.stdout:write(cmd.desc)
        end
    end
    io.stderr:write(errmsg:format(progname, cmdname, progname))
    return false
end

return {
    usage = help_usage,
    version = version,
    progname = progname,
}
