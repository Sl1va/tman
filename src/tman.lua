--- Task manager.
-- Simplify workflow when working with many repos.
-- @module TMan

local HOME = os.getenv("HOME")
local tman_path = "personal/prjs/tman/src/?.lua"
package.path = package.path .. ";" .. HOME .. "/" .. tman_path


local log = require("log")
local help = require("help")
local taskid = require("taskid")
local gitmod = require("git")
local global = require("globals")
local taskunit = require("taskunit")
local getopt = require("posix.unistd").getopt


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
-- @return currentn task ID
function TMan:_curr()
    local optstring = "fi"
    local id = self.taskid:getcurr()

    for optopt, _, optind in getopt(arg, optstring) do
        if optopt == "?" then
            log:err("unrecognized option '%s'", arg[optind - 1])
            os.exit(1)
        end
        if optopt == "f" then
            local desc = self.taskunit:getunit(id, "desc")
            print(("* %-8s %s"):format(id, desc))
        elseif optopt == "i" then
            print(id)
        end
    end
end

--- List all task IDs.
-- Default: show only active task IDs.
-- @param opt list option
function TMan:list()
    local active = true
    local completed = false
    local optstring = "Aac"

    for optopt, _, optind in getopt(arg, optstring) do
        if optopt == "?" then
            return log:err("unrecognized option '%s'", arg[optind - 1])
        end
        if optopt == "A" then
            print("All tasks:")
            active = true
            completed= true
        elseif optopt == "a" then
            print("Active tasks:")
            -- use default flags
        elseif optopt == "c" then
            print("Completed tasks:")
            active = false
            completed= true
        end
    end
    self.taskid:list(active, completed)
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

    elseif opt == "-p" then
        io.write("new priority [highest|high|mid|low|lowest]: ")
        local newprio = io.read("*l")
        self.taskunit:amend_prio(id, newprio)

    elseif not opt then
        log:err("option missing")
    else
        log:err("'%s': no such option", opt)
    end
end

--- Update git repos.
-- @param opt options
-- roachme: It doesn't work if there is no current task
function TMan:update(opt)
    opt = opt or "-u"
    local id = self.taskid:getcurr()
    if not id then
        log:warning("no current task")
        os.exit(1)
    end

    local branch = self.taskunit:getunit(id, "branch")
    local git = gitmod.new(id, branch)

    git:branch_switch_default()
    if opt == "-c" then
        git:branch_create()
    elseif opt == "-u" then
        git:branch_update(true)
    else
        log:warning("unknown option '%s'", opt)
    end
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

function TMan:time(oper, val)
    local weeks = ""
    local days = ""
    local hours = ""

    if oper == "set" then
        local timeval = ""
        io.write("weeks (default none): ")
        weeks = io.read("*l")
        io.write("days (default none): ")
        days = io.read("*l")
        io.write("hours (default none): ")
        hours = io.read("*l")

        --[[
        print("weeks", weeks)
        print("days", days)
        print("hours", hours)
        ]]
        timeval = weeks .. " " .. days .. " " .. hours
        print(("timeval '%s'"):format(timeval))
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
    -- posix getopt does not let permutations as GNU version
    table.remove(arg, 1)

    if cmd == "add" then
        self:add(arg[1], arg[2], arg[3])
    elseif cmd == "amend" then
        self:amend(arg[1], arg[2])
    elseif cmd == "use" then
        self:use(arg[1])
    elseif cmd == "show" then
        self:show(arg[1])
    elseif cmd == "del" then
        self:del(arg[1])
    elseif cmd == "_curr" then
        self:_curr()
    elseif cmd == "list" then
        self:list()
    elseif cmd == "update" then
        self:update(arg[1])
    elseif cmd == "review" then
        self:review()
    elseif cmd == "done" then
        self:done()
    elseif cmd == "config" then
        self:config(arg[1])
    elseif cmd == "prev" then
        self:prev()
    elseif cmd == "time" then
        self:time(arg[1], arg[2])
    elseif cmd == "backup" then
        self:backup()
    elseif cmd == "restore" then
        self:restore()
    elseif cmd == "help" then
        help.usage()
    elseif cmd == "info" then
        help:info(arg[1])
    elseif cmd == "ver" then
        print(("%s version %s"):format(help.progname, help.version))
    else
        log:err("'%s': no such command", cmd)
    end
end

log = log.init("tman")
local tman = TMan.init()
return tman:main(arg)
