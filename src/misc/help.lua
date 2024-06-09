--- Provide help on commands and general usage.
-- @module help

local version = "0.1.7"
local progname = "tman"

local function show_usage()
    io.stdout:write(([[
Usage: %s COMMAND [OPTION] [ID]
Use '%s help COMMAND' to get command's detailed info.

COMMANDS:
System:
  init    - init util structure.
  archive - backup and restore metadata

Basic:
  use     - mark a task as current
  get     - get parameters like curr, prev tasks, etc
  list    - list tasks
  cat     - cat task info
  prev    - switch to previous task
  done    - move task to completed status

Amend:
  add     - add new task
  del     - delete task
  set     - set task units
  config  - config for your workflow
  update  - update task struct, git branch, repos, etc

Info:
  ver     - show version
  help    - show this help message
]]):format(progname, progname))
end

local cmds = {
    {
        name = "init",
        desc = [[
Usage: tman init
Initialize util.
]],
    },
    {
        name = "archive",
        desc = [[
Usage: tman archive OPTION
Make backup and restore util data.

Options:
    -b FILE     create backup (default extension: .tar)
    -r FILE     restore from archive
    -R          include repos into archive (default: false)
]],
    },
    {
        name = "add",
        desc = [[
Usage: tman add TASKID
Add new task.
]],
    },
    {
        name = "del",
        desc = [[
Usage: tman del [TASKID]
Delete task.
TASKID - default is current task.
]],
    },
    {
        name = "set",
        desc = [[
Usage: tman set OPTION [TASKID]
Amend task items.
TASKID - default is current task.

Options:
    -i      set task ID
    -d      set task description
    -l      set task link
    -p      set task priority. Values: [highest|high|mid|low|lowest]
    -t      set task type. Values: [bugfix|hotfix|feature]
]],
    },
    {
        name = "update",
        desc = [[
Usage: tman update COMMAND
Update task repos, structure, etc. Operates on current task ID.

COMMAND:
    task    create task branch, symlink, etc.
    repos   same as `task', also update branches from remote git repo.
]],
    },

    {
        name = "done",
        desc = [[
Usage: tman done [TASKID]
Move task to completed status.
TASKID - default is current task.
]],
    },

    {
        name = "use",
        desc = [[
Usage: tman use TASKID
Switch to specified task. Use `tman list` to see existing tasks.
TASKID - default is current task.
]],
    },
    {
        name = "get",
        desc = [[
Usage: tman get PARAM
Get parameters like curr, prev tasks, etc

Notes:
PARAM can have one of the next values
    curr    - current task id
    prev    - previous task id
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
        name = "cat",
        desc = [[
Usage: tman cat [TASKID]
Show task units (current task by default).
TASKID - default is current task.

Options:
    -k   cat specific unit key
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
-- @return status code: 0 - ok, otherwise error code
local function help_usage(cmdname)
    local errmsg = "%s: no such command '%s'. Use '%s help' for more info.\n"

    if not cmdname then
        show_usage()
        return 0
    end

    for _, cmd in ipairs(cmds) do
        if cmd.name == cmdname then
            io.stdout:write(cmd.desc)
            return 0
        end
    end
    io.stderr:write(errmsg:format(progname, cmdname, progname))
    return 1
end

return {
    usage = help_usage,
    version = version,
    progname = progname,
}
