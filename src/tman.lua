--- Task manager.
-- Simplify workflow when working with many repos.
-- @module TMan

package.path = package.path .. ";/home/roach/personal/prjs/tman/src/?.lua"

local log = require("log")
local help = require("help")
local taskid = require("taskid")
local gitmod = require("git")
local global = require("globals")
local taskunit = require("taskunit")

local TMan = {}
TMan.__index = TMan

--- Class TMan
-- @type TMan

--- Init class TMan.
function TMan.init()
    local self = setmetatable({
        taskid = taskid.init(),
        taskunit = taskunit.init(),
    }, TMan)
    return self
end

--- Check ID is passed and exists in database.
-- @param id task ID
-- @return true on success, otherwise false
function TMan:checkid(id)
    id = id or self.taskid:getcurr()
    if not id then
        log:err("no current task")
        return false
    end
    if not self.taskid:exist(id) then
        log:err("'%s': no such task ID", id)
        return false
    end
    return true
end

--- Add a new task.
-- @param id task ID
-- @param tasktype task type: bugfix, hotfix, feature. Default: bugfix
-- @param prio task priority (default: mid)
-- @treturn true if new task unit is created, otherwise false
function TMan:add(id, tasktype, prio)
    prio = prio or "mid"
    if not id then
        log:err("task ID required")
        os.exit(1)
    end
    if not tasktype then
        log:err("task type required")
        os.exit(1)
    end
    if not self.taskid:add(id) then
        log:err("'%s': already exists", id)
        os.exit(1)
    end
    if not self.taskunit:add(id, tasktype, prio) then
        log:err("colud not create new task unit")
        self.taskid:del(id)
        os.exit(1)
    end
    return true
end

--- Switch to new task.
-- @param id task ID
function TMan:use(id)
    if not self:checkid(id) then
        os.exit(1)
    end
    if self.taskid:getcurr() == id then
        log:warning("'%s': already in use", id)
        os.exit(1)
    end

    local branch = self.taskunit:getunit(id, "branch")
    local git = gitmod.new(id, branch)
    if not git:branch_switch(branch) then
        log:err("repo has uncommited changes")
        os.exit(1)
    end
    self.taskid:update(id)
    return 0
end

--- Switch to previous task.
function TMan:prev()
    local prev = self.taskid:getprev()

    if not prev then
        log:warning("no previous task")
        os.exit(1)
    end
    local branch = self.taskunit:getunit(prev, "branch")
    local git = gitmod.new(prev, branch)
    if not git:branch_switch(branch) then
        log:err("repo has uncommited changes")
        os.exit(1)
    end
    self.taskid:swap()
    return 0
end

--- Get cucrent task ID and other info.
-- @param opt options: -i: task ID, -f: task ID and description. Default: -f
-- @return currentn task ID
function TMan:_curr(opt)
    opt = opt or "-f"
    local id = self.taskid:getcurr()

    if opt == "-i" then
        print(id)
    elseif opt == "-f" then
        local desc = self.taskunit:getunit(id, "desc")
        print(("* %-8s %s"):format(id, desc))
    else
        log:err("curr: '%s': no such option", opt)
        os.exit(1)
    end
    return 0
end

--- List all task IDs.
-- Default: show only active task IDs.
-- @param opt list option
function TMan:list(opt)
    opt = opt or "-a"

    if opt == "-A" then
        print("All tasks:")
        self.taskid:list(true, true)
    elseif opt == "-a" then
        print("Active tasks:")
        self.taskid:list(true, false)
    elseif opt == "-c" then
        print("Completed tasks:")
        self.taskid:list(false, true)
    end
end

--- Show task unit metadata.
-- @param id task ID
function TMan:show(id)
    id = id or self.taskid:getcurr()

    if not self:checkid(id) then
        os.exit(1)
    end
    self.taskunit:show(id)
end

--- Amend task unit.
-- @param id task ID
-- @param opt option
function TMan:amend(id, opt)
    id = id or self.taskid:getcurr()

    if not self:checkid(id) then
        os.exit(1)
    end
    if opt == "-d" then
        io.write("new desc: ")
        local newdesc = io.read("*l")
        self.taskunit:amend_desc(id, newdesc)
    elseif not opt then
        log:err("option missing")
    else
        log:err("'%s': no such option", opt)
    end
end

--- Update git repos.
-- roachme: It doesn't work if there is no current task
function TMan:update()
    local id = self.taskid:getcurr()
    if not id then
        log:warning("no current task")
        os.exit(1)
    end

    local branch = self.taskunit:getunit(id, "branch")
    local git = gitmod.new(branch, "")

    git:branch_switch_default()
    git:branch_update(true)
    git:branch_switch(branch)
    return 0
end

--- Delete task.
-- @param id task ID
function TMan:del(id)
    local desc = self.taskunit:getunit(id, "desc")

    if not self:checkid(id) then
        os.exit(1)
    end
    print(("> %-8s %s"):format(id, desc))
    io.write("Do you want to continue? [Yes/No] ")
    local confirm = io.read("*line")
    if confirm ~= "Yes" then
        print("deletion is cancelled")
        os.exit(1)
    end
    self.taskunit:del(id)
    self.taskid:del(id)
    return 0
end

--- Check current task and push branch for review.
function TMan:review()
    local id = self.taskid:getcurr()
end

--- Move current task to done status.
function TMan:done()
    local id = self.taskid:getcurr()
    if not self:checkid() then
        os.exit(1)
    end
    local git = gitmod.new(id, "develop")
    if not git:branch_switch_default() then
        log:err("repo has uncommited changes")
        os.exit(1)
    end
    self.taskid:move(self.taskid.types.COMP)
end

--- Config util for your workflow
-- @param subcmd subcommand
function TMan:config(subcmd)
    if subcmd == "repo" then
        print("configure repo list")
    end
end

--- Back up util configs into archive.
function TMan:backup()
    print(global.G_tmanpath)
end

--- Restore util configs from archive.
function TMan:restore() end

--- Interface.
function TMan:main(arg)
    local cmd = arg[1] or "help"

    if cmd == "add" then
        self:add(arg[2], arg[3], arg[4])
    elseif cmd == "amend" then
        self:amend(arg[2], arg[3])
    elseif cmd == "use" then
        self:use(arg[2])
    elseif cmd == "show" then
        self:show(arg[2])
    elseif cmd == "del" then
        self:del(arg[2])
    elseif cmd == "_curr" then
        self:_curr(arg[2])
    elseif cmd == "list" then
        self:list(arg[2])
    elseif cmd == "update" then
        self:update()
    elseif cmd == "review" then
        self:review()
    elseif cmd == "done" then
        self:done()
    elseif cmd == "config" then
        self:config(arg[2])
    elseif cmd == "prev" then
        self:prev()
    elseif cmd == "backup" then
        self:backup()
    elseif cmd == "restore" then
        self:restore()
    elseif cmd == "help" then
        help.usage()
    elseif cmd == "ver" then
        print(("%s version %s"):format(help.progname, help.version))
    else
        log:err("'%s': no such command", cmd)
    end
end

log = log.init("tman")
local tman = TMan.init()
return tman:main(arg)
