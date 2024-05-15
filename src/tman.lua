--- Task manager.
-- Simplify workflow when working with many repos.
-- @module TMan


-- Tman main components.
local struct = require("struct")
local config = require("config")
local taskid = require("taskid").init()
local taskunit = require("taskunit").init()

-- Tman misc components.
local gitmod = require("misc/git")
local log = require("misc/log").init("tman")
local help = require("misc/help")
local getopt = require("posix.unistd").getopt

-- Tman Aux components.
local utils = require("aux/utils")



--[[
TODO:
    1. Make all commands alike so they can be put in array and called
       in main().

]]

-- Private functions: start --

--- Check tman dir ain't corrupted and exists.
-- @return true on success, otherwise false
local function _check_tman_struct()
    local files = {
        config.repos,
        config.taskids,
    }
    local dirs = {
        config.ids,
        config.tmanbase,
        config.taskbase,
        config.codebase,
    }

    for _, dir in pairs(dirs) do
        if not utils.access(dir) then
            return false
        end
    end
    for _, file in pairs(files) do
        if not utils.access(file) then
            return false
        end
    end
    return true
end

--- Check ID is passed and exists in database.
-- @param id task ID
-- @return true on success, otherwise false
local function _checkid(id)
    id = id or taskid:getcurr()
    if not id then
        log:err("no current task")
        return false
    end
    if not taskid:exist(id) then
        log:err("'%s': no such task ID", id)
        return false
    end
    return true
end

-- Private functions: end --


-- Public functions: start --

--- Init system to use a util.
local function tman_init()
    print("init tman structure")
    -- dirs
    utils.mkdir(config.ids)
    utils.mkdir(config.tmanbase)
    utils.mkdir(config.taskbase)
    utils.mkdir(config.codebase)

    -- files
    utils.touch(config.taskids)
    utils.touch(config.repos)
end

--- Add a new task.
-- @param id task ID
-- @param tasktype task type: bugfix, hotfix, feature. Default: bugfix
-- @param prio task priority: lowest, low, mid, high, highest. Default: mid
-- @treturn true if new task unit is created, otherwise false
local function tman_add(id, tasktype, prio)
    prio = prio or "mid"
    tasktype = tasktype or "bugfix"

    if not id then
        log:err("task ID required")
        os.exit(1)
    end
    if not taskid:add(id) then
        log:err("'%s': already exists", id)
        os.exit(1)
    end
    if not taskunit:add(id, tasktype, prio) then
        log:err("could not create new task unit")
        taskid:del(id)
        os.exit(1)
    end
    if not struct.create(id) then
        log:err("could not create new task structure")
        taskid:del(id)
        taskunit:del(id)
        os.exit(1)
    end
    --[[
        TODO: this's how it should go?
        git.create_branch()
    ]]
    return true
end

--- Switch to another task.
-- @param id task ID
local function use(id)
    if not _checkid(id) then
        os.exit(1)
    end
    if taskid:getcurr() == id then
        log:warning("'%s': already in use", id)
        os.exit(1)
    end

    local branch = taskunit:getunit(id, "branch")
    local git = gitmod.new(id, branch)
    if not git:branch_switch(branch) then
        log:err("repo has uncommited changes")
        os.exit(1)
    end
    taskid:setcurr(id)
    return 0
end

--- Switch to previous task.
local function tman_prev()
    local prev = taskid:getprev()

    if not prev then
        log:warning("no previous task")
        os.exit(1)
    end
    local branch = taskunit:getunit(prev, "branch")
    local git = gitmod.new(prev, branch)
    if not git:branch_switch(branch) then
        log:err("repo has uncommited changes")
        os.exit(1)
    end
    taskid:swap()
    return 0
end

--- Get cucrent task ID and other info.
-- @return currentn task ID
local function _tman_curr()
    local optstring = "fi"
    local id = taskid:getcurr()

    for optopt, _, optind in getopt(arg, optstring) do
        if optopt == "f" then
            local desc = taskunit:getunit(id, "desc")
            print(("* %-10s %s"):format(id, desc))
        elseif optopt == "i" then
            print(id or "")
        elseif optopt == "?" then
            log:err("unrecognized option '%s'", arg[optind - 1])
            os.exit(1)
        end
    end
end

--- List all task IDs.
-- Default: show only active task IDs.
-- @param opt list option
local function tman_list()
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
            completed = true
        elseif optopt == "a" then
            print("Active tasks:")
            -- use default flags
        elseif optopt == "c" then
            print("Completed tasks:")
            active = false
            completed = true
        end
    end
    taskid:list(active, completed)
end

--- Show task unit metadata.
-- @param id task ID
local function tman_show(id)
    id = id or taskid:getcurr()

    if not _checkid(id) then
        os.exit(1)
    end
    taskunit:show(id)
end

--- Amend task unit.
-- @param id task ID
-- @param opt option
local function tman_amend(id, opt)
    id = id or taskid:getcurr()

    if not _checkid(id) then
        os.exit(1)
    end
    if opt == "-d" then
        io.write("new desc: ")
        local newdesc = io.read("*l")
        taskunit:amend_desc(id, newdesc)
    elseif opt == "-p" then
        io.write("new priority [highest|high|mid|low|lowest]: ")
        local newprio = io.read("*l")
        taskunit:amend_prio(id, newprio)
    elseif opt == "-i" then
        io.write("new task ID: ")
        local newid = io.read("*l")
        taskunit:amend_id(id, newid)
        taskid:del(id)
        taskid:add(newid)
    elseif not opt then
        log:err("option missing")
    else
        log:err("'%s': no such option", opt)
    end
end

--- Create task symlinks.
local function tman_link(id)
    if not _checkid(id) then
        os.exit(1)
    end
    print("under dev: gotta use struct.lua API")
end

--- Update git repos.
-- @param opt options
-- roachme: It doesn't work if there is no current task
local function tman_update(opt)
    opt = opt or "-u"
    local id = taskid:getcurr()
    if not id then
        log:warning("no current task")
        os.exit(1)
    end

    local branch = taskunit:getunit(id, "branch")
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
local function tman_del(id)
    local desc = taskunit:getunit(id, "desc")

    if not _checkid(id) then
        os.exit(1)
    end
    print(("> %-8s %s"):format(id, desc))
    io.write("Do you want to continue? [Yes/No] ")
    local confirm = io.read("*line")
    if confirm ~= "Yes" then
        print("deletion is cancelled")
        os.exit(1)
    end
    taskunit:del(id)
    taskid:del(id)
    struct.delete(id)
    --[[
    self.git:del(id)        -- delete task branch (need task ID from taskunit.lua)
    self.struct:del(id)     -- delete task dir
    self.taskid:del(id)     -- delete task ID from the database
    self.taskunit:del(id)   -- delete task unit file from .tman
    ]]
    return 0
end

--- Check current task and push branch for review.
local function tman_review()
    local id = taskid:getcurr()
end

--- Move current task to done status.
local function tman_done()
    local id = taskid:getcurr()
    if not _checkid() then
        os.exit(1)
    end
    local git = gitmod.new(id, "develop")
    if not git:branch_switch_default() then
        log:err("repo has uncommited changes")
        os.exit(1)
    end
    taskid:move(taskid.types.COMP)
end

--- Config util for your workflow
-- @param subcmd subcommand
local function tman_config(subcmd)
    if subcmd == "repo" then
        print("configure repo list")
    elseif subcmd == "" then
    end
end

local function tman_time(oper, val)
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
local function tman_backup()
    -- roachme: need some tuning
    local ftar = "tman_db.tar"
    local dtar = ".tman"
    local tar = "tar -C "
    local tarcmd = tar .. config.taskbase .. " -cf " .. ftar .. " " .. dtar

    if not utils.access(config.taskids) then
        return log:err("tman database doesn't exist. Nothing to backup")
    end

    if not os.execute(tarcmd) then
        return log:err("couldn't create tman database backup")
    end
    return print(("create backup file: './%s'"):format(ftar))
end

--- Restore util configs from archive.
local function tman_restore()
    local ftar = arg[1]

    if not ftar then
        log:err("pass config *.tar file")
        os.exit(1)
    end

    local dtar = ".tman"
    local tar = "tar"
    local tarcmd = tar .. " -xf " .. ftar .. " " .. dtar
    if not utils.access(ftar) then
        log:err("'%s': no archive such file", ftar)
        os.exit(1)
    end

    print("tarcmd", tarcmd)
    --os.execute(tarcmd)
end

--- Interface.
local function main()
    local cmd = arg[1] or "help"

    -- posix getopt does not let permutations as GNU version
    table.remove(arg, 1)

    if not _check_tman_struct() and cmd ~= "init" then
        log:err("tman structure not inited or corrupted")
        os.exit(1)
    end

    if cmd == "init" then
        return tman_init()
    elseif cmd == "add" then
        tman_add(arg[1], arg[2], arg[3])
    elseif cmd == "amend" then
        tman_amend(arg[1], arg[2])
    elseif cmd == "link" then
        tman_link(arg[1])
    elseif cmd == "use" then
        use(arg[1])
    elseif cmd == "show" then
        tman_show(arg[1])
    elseif cmd == "del" then
        tman_del(arg[1])
    elseif cmd == "_curr" then
        _tman_curr()
    elseif cmd == "list" then
        tman_list()
    elseif cmd == "update" then
        tman_update(arg[1])
    elseif cmd == "review" then
        tman_review()
    elseif cmd == "done" then
        tman_done()
    elseif cmd == "config" then
        tman_config(arg[1])
    elseif cmd == "prev" then
        tman_prev()
    elseif cmd == "time" then
        tman_time(arg[1], arg[2])
    elseif cmd == "backup" then
        --tman:backup()
        print("under development")
    elseif cmd == "restore" then
        print("under development")
        --tman_restore()
    elseif cmd == "help" then
        help.usage()
    elseif cmd == "info" then
        help.info(arg[1])
    elseif cmd == "ver" then
        print(("%s version %s"):format(help.progname, help.version))
    else
        log:err("'%s': no such command", cmd)
    end
end

-- Public functions: end --

main()
