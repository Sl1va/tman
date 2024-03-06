local Help = {}

Help.version = "0.1.0"
Help.progname = "tman"

function Help:usage()
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
  amend   - amend task
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

--- Get detailed info about command.
-- @param command command to info about
function Help:info(cmd) end

return Help
