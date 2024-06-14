--- Provide help on commands and general usage.
-- @module help

local version = "0.1.9"
local progname = "tman"

local function show_usage()
    io.stdout:write(([[
Usage: %s COMMAND [OPTION] [ID]
Use '%s help COMMAND' to get command's detailed info.

COMMANDS:
System:
  archive - backup and restore metadata
  config  - config for your workflow
  init    - init util structure.

Basic:
  cat     - cat task info
  get     - get parameters like curr, prev tasks, etc
  list    - list tasks
  prev    - switch to previous task
  use     - mark a task as current

Change:
  add     - add new task
  del     - delete task
  pack    - pack commits in repos for review.
  set     - set task units
  sync    - synchronize task struct, git branch, repos, etc

Info:
  help    - show this help message
  ver     - show version

'%s help COMMAND' to get detailed info about command.
'%s help %s' to get info about util itself.
]]):format(progname, progname, progname, progname, progname))
end

local cmds = {
    {
        name = progname,
        desc = [[
tman stands for task manager. Used to switch between tasks, git branches and
make the workflow and nice and painless.
]],
    },
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
        name = "config",
        desc = [[
Usage: tman config OPTION
Work with config files.

Options:
    -b      - set base path
    -i      - set install path
              questionable, cuz util gotta change path in .shellrc
    -s      - show config: system & user
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
        name = "sync",
        desc = [[
Usage: tman sync COMMAND
Update task repos, structure, etc. Operates on current task ID.

Options:
    -s      - task structure (default)
    -r      - git pull from remote repo
    -t      - synchronize task status
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
        name = "pack",
        desc = [[
Usage: tman pack OPTION [TASKID]
Pack commits in repos for review.

Options:
    -c      - create commit (default)
    -m      - run commands from the Makefile
    -p      - push branch to remote repo
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
Usage: tman cat [OPTION] [TASKID]
Show task units (current task by default).
TASKID - default is current task.

Options:
    -k   cat specific unit key
]],
    },
    {
        name = "help",
        desc = [[
Usage: tman help [COMMAND]
Show help message. If `COMMAND' applied then show info about command.
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
