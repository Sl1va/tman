--- Task manager.
-- Simplify workflow when working with many repos.
-- @module TMan

require("globals")

local taskid = require("taskid")
local taskunit = require("taskunit")
local gitmod = require("git")

local version = "v0.1"

local TMan = {}
TMan.__index = TMan

local function usage()
    print(([[
Usage: %s COMMAND [ID]
Basic:
  new     - create new task
  use     - mark a task as current
  prev    - switch to previous task
  list    - list all tasks. Default: active tasks
  show    - show task info. Default: current task
  time    - time spent on task
  amend   - amend task unit
  update  - git pull for all repos

Contribute:
  review  - push commits for review
  done    - move task to status complete

For developers:
  init    - download repos and create symlinks for all of them
  del     - delete task unit
  curr    - get current task ID
]]):format("tman"))
end

local function log(fmt, ...)
    local msg = "tman: " .. fmt:format(...)
    print(msg)
end

--- Class TMan
-- @type TMan

--- Init class TMan.
function TMan.init(taskpath)
    taskpath = taskpath or "/home/roach/work/tasks"
    local self = setmetatable({
        taskid = taskid.new(taskpath),
        taskunit = taskunit.newobj(taskpath),
    }, TMan)
    return self
end

--- Check ID is passed and exists in database.
-- @param id task ID
-- @return true on success, otherwise false
function TMan:checkid(id)
    id = id or self.taskid.curr
    if not id then
        log("no current task")
        return false
    end
    if not self.taskid:exist(id) then
        log("'%s': no such task ID", id)
        return false
    end
    return true
end

--- Create a new task.
-- @param id task ID
-- @treturn true if new task unit is created, otherwise false
function TMan:new(id)
    if not id then
        log("task ID required")
        os.exit(1)
    end
    if not self.taskid:add(id) then
        log("'%s': already exists", id)
        os.exit(1)
    end
    if not self.taskunit:new(id) then
        log("colud not create new task unit")
        self.taskid:del(id)
        os.exit(1)
    end
    return true
end

--- Switch to new task.
-- @param id task ID
function TMan:use(id)
    if not self:checkid(id) then
        return 1
    end
    if self.taskid.curr == id then
        log("'%s': already in use", id)
        return 1
    end

    local branch = self.taskunit:getunit(id, "branch")
    local git = gitmod.new(id, branch)
    if not git:branch_switch() then
        log("repo has uncommited changes")
        return 1
    end
    self.taskid:updcurr(id)
    return 0
end

--- Switch to previous task.
function TMan:prev()
    local prev = self.taskid.prev

    if not prev then
        log("no previous task")
        return 1
    end
    local branch = self.taskunit:getunit(prev, "branch")
    local git = gitmod.new(prev, branch)
    if not git:branch_switch() then
        log("repo has uncommited changes")
        return 1
    end
    self.taskid:swap()
    return 0
end

--- Get cucrent task ID.
-- @return currentn task ID
function TMan:curr()
    print(self.taskid.curr)
end

--- List all task IDs.
-- By default show only active task IDs.
-- @param opt list option
function TMan:list(opt)
    if opt == "-A" then
        print("All task IDs")
        self.taskid:list(true, true)
    elseif not opt or opt == "-a" then
        print("Active task IDs")
        self.taskid:list(true, false)
    elseif opt == "-c" then
        print("Complete task IDs")
        self.taskid:list(false, true)
    end
end

--- Show task unit metadata.
-- @param id task ID
function TMan:show(id)
    id = id or self.taskid.curr
    if not self:checkid(id) then
        return 1
    end
    self.taskunit:show(id)
end

--- Amend task unit.
-- @param id task ID
-- @param opt option
function TMan:amend(id, opt)
    id = id or self.taskid.curr

    if not self:checkid(id) then
        return 1
    end
    if opt == "-d" then
        io.write("new desc: ")
        local desc = io.read("*l")
    else
        log("'%s': no such option", opt)
    end
end

--- Update git repos.
function TMan:update()
    local git = gitmod.new("", "")

    git:branch_default()
    git:pull(true)
    git:branch_switch()
    return 0
end

--- Delete task.
-- @param id task ID
function TMan:del(id)
    if not self:checkid(id) then
        return 1
    end

    io.write("Do you want to continue? [Y/n] ")
    local confirm = io.read("*line")
    if confirm ~= "Y" then
        print("deletion is cancelled")
        return 1
    end
    self.taskunit:del(id)
    self.taskid:del(id)
    return 0
end

--- Check current task and push branch for review.
function TMan:review()
    local id = self.taskid.curr
end

--- Move current task to done status.
function TMan:done()
    local id = self.taskid.curr
    if not self:checkid() then
        return 1
    end
    local git = gitmod.new(id, "develop")
    if not git:branch_default() then
        log("repo has uncommited changes")
        return 1
    end
    self.taskid:unsetcurr(true)
end

--- Interface.
function TMan:main(arg)
    local cmd = arg[1] or "help"

    if cmd == "new" then
        self:new(arg[2])
    elseif cmd == "use" then
        self:use(arg[2])
    elseif cmd == "list" then
        self:list(arg[2])
    elseif cmd == "show" then
        self:show(arg[2])
    elseif cmd == "prev" then
        self:prev()
    elseif cmd == "curr" then
        self:curr()
    elseif cmd == "amend" then
        self:amend(arg[2], arg[3])
    elseif cmd == "update" then
        self:update()
    elseif cmd == "del" then
        self:del(arg[2])
    elseif cmd == "review" then
        self:review()
    elseif cmd == "done" then
        self:done()
    elseif cmd == "help" then
        usage()
    elseif cmd == "ver" then
        print(("tman version: %s"):format(version))
    else
        log("'%s': no such command", cmd)
    end
end

local tman = TMan.init()
return tman:main(arg)
