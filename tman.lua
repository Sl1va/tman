--- Manage task units.
-- Create a new unit, move to diff statuses and so on.
-- @module TaskMan

local taskid = require("taskid")
local taskunit = require("taskunit")
local gitmod = require("git")

local function log(fmt, ...)
    local msg = "tman: " .. fmt:format(...)
    print(msg)
end

local TaskMan = {}
TaskMan.__index = TaskMan

local function usage()
    print(([[
Usage: %s cmd [TASKID] [STATUS]
Task items related commands:
  new   - create new task item
  use   - mark a task as current
  move  - move a task to new status. Default: backlog
  prev  - switch to previous task
  list  - list all tasks
  show  - show task info. Default: current task (if exists)
  amend - amend task description and branch
  review- push commits for review
  done  - move task unit to .done directory

Task specificly related commands:
  check - check git commit, rebase/ merge, CHANGELOG.md and pass task code through tests in MakefileWimark
  time  - time you spent on task
  dline - show updated deadline

General:
  help  - show this message
  info  - show inner things as list of statuses and other info

For developer:
  init  - download repos and create symlinks for all them
  del   - delete task dir, branch, and meta
]]):format("tman"))
end

--- Class TaskMan
-- type TaskMan

--- Init class TaskMan.
function TaskMan.init()
    local taskpath = "/home/roach/work/tasks"
    local self = setmetatable({
        taskid = taskid.new(taskpath),
        taskunit = taskunit.newobj(taskpath),
    }, TaskMan)
    return self
end

--- Create a new task unit.
-- @param id task ID
-- @treturn true if new task unit is created, otherwise false
function TaskMan:new(id)
    if not id then
        print("tman: missing task ID")
        os.exit(1)
    end
    if not self.taskid:add(id) then
        log("task ID '%s' exists already", id)
        os.exit(1)
    end
    --[[
    if not self.taskunit:new(id) then
        print("taskman: colud not create new task unit")
        self.taskid:del(id)
        os.exit(1)
    end
    ]]
    return true
end

--- Move task to new status.
-- FIXME: case: when new ID and current task ID are the same
-- @param status status to move task to
-- @param id task ID. Default: current task ID
function TaskMan:move(status, id)
    if not status then
        log("missing status")
        os.exit(1)
    end
    if id and id == self.taskid.curr then
        id = nil
    end

    if (id and self.taskid.curr) and status == "progress" then
        print("replace new task with current one (in progress)")
        local git = gitmod.new(id, self.taskunit:getunit(id, "branch"))
        if not git:branch_switch() then
            log("repo has uncommited changes")
            os.exit(1)
        end
        self.taskunit:setunit(self.taskid.curr, "Status", "backlog")
        self.taskunit:setunit(id, "Status", "progress")
        local oldcurr = self.taskid.curr
        self.taskid:setcurr(id)
        self.taskid:setprev(oldcurr)
    elseif id and status == "progress" then
        print("new task to progress")
        local git = gitmod.new(id, self.taskunit:getunit(id, "branch"))
        if not git:branch_switch() then
            log("repo has uncommited changes")
            os.exit(1)
        end
        self.taskunit:setunit(id, "Status", status)
        self.taskid:setcurr(id)
    elseif id and status ~= "progress" then
        print("new task to somewhere else:", id)
        self.taskunit:setunit(id, "Status", status)
    elseif self.taskid.curr and status ~= "progress" then
        print("move current task to somewhere else")
        local git = gitmod.new(
            self.taskid.curr,
            self.taskunit:getunit(self.taskid.curr, "branch")
        )
        if not git:branch_switch() then
            log("repo has uncommited changes")
            os.exit(1)
        end
        self.taskunit:setunit(self.taskid.curr, "Status", status)
        self.taskid:unsetcurr()
    else
        log("no current task exists")
        os.exit(1)
    end
    return true
end

--- Switch to new task.
-- @param id task ID
function TaskMan:use(id)
    if not id then
        log("previous task ID '%s' missing")
        return 1
    end
    if not self.taskid:exist(id) then
        log("task ID '%s' doesn't exist", id)
        return 1
    end
    if self.taskid.curr == id then
        log("task ID '%s' already in use", id)
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
function TaskMan:prev()
    local prev = self.taskid.prev

    if not prev then
        log("no previous task ID")
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
function TaskMan:getcurr()
    print(self.taskid.curr)
end

--- List all task IDs.
-- By default show only active task IDs.
-- @param opt list option
function TaskMan:list(opt)
    if opt == "-A" then
        print("All task IDs")
        self.taskid:list(true, true)
    elseif opt == "-a" then
        print("Active task IDs")
        self.taskid:list(true, false)
    elseif opt == "-c" then
        print("Complete task IDs")
        self.taskid:list(false, true)
    else
        print("Active task IDs")
        self.taskid:list(true)
    end
end

--- Show task unit metadata.
-- @param id task ID
function TaskMan:show(id)
    id = id or self.taskid.curr
    if not id then
        log("neither task ID passed nor current exists")
        os.exit(1)
    end
    if not self.taskid:exist(id) then
        log("'%s': no such task ID", id)
        os.exit(1)
    end
    self.taskunit:show(id)
end

--- Amend task unit.
-- @param id task ID
--function TaskMan:amend(id) end

--- Delete task unit.
-- @param id task ID
function TaskMan:del(id)
    if not self.taskid:exist(id) then
        log("'%s': no such task ID", id)
        os.exit(1)
    end

    io.write("Do you want to continue? [Y/n] ")
    local confirm = io.read("*line")
    if confirm ~= "Y" then
        print("tman: deletion is cancelled")
        return 1
    end
    self.taskunit:del(id)
    self.taskid:del(id)
end

--- Check task and push branch for review.
-- @param id task ID. Default: current task
function TaskMan:review(id)
    id = id or self.taskid.curr
end

--- Move current task to done status.
function TaskMan:done()
    local id = self.taskid.curr

    if not id then
        log("no current task")
        return 1
    end
    local git = gitmod.new(id, "develop")
    if not git:branch_switch() then
        log("repo has uncommited changes")
        return 1
    end
    self.taskid:unsetcurr(true)
end

--- Interface.
function TaskMan:main(arg)
    local cmd = arg[1]

    if cmd == "new" then
        self:new(arg[2])
    elseif cmd == "use" then
        self:use(arg[2])
    elseif cmd == "move" then
        self:move(arg[2], arg[3])
    elseif cmd == "list" then
        self:list(arg[2])
    elseif cmd == "show" then
        self:show(arg[2])
    elseif cmd == "prev" then
        self:prev()
    elseif cmd == "getcurr" then
        self:getcurr()
    elseif cmd == "del" then
        self:del(arg[2])
    elseif cmd == "review" then
        self:review()
    elseif cmd == "done" then
        self:done()
    elseif cmd == "help" then
        usage()
    elseif not cmd then
        log("command expected")
    else
        log("no such command: %s", cmd)
    end
end

local tman = TaskMan.init()
return tman:main(arg)
