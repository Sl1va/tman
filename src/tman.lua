--- Task manager.
-- Simplify workflow when working with many repos.
-- @module TMan

-- Tman main components.
local git = require("git")
local core = require("core")
local struct = require("struct")
local taskid = require("taskid")
local taskunit = require("taskunit")

-- Tman misc components.
local help = require("misc.help")
local getopt = require("posix.unistd").getopt

--[[
    TODO: gotta refactor
    1. update command
    2. set command
]]

--[[
local errcodes = {
    ok = 0,
    not_inited = 1,
    corrupted = 2,
    command_failed = 2,
    command_not_found = 3,
}
]]

--[[
Erorr codes:
    0 - OK
    1 - structure not inited
    2 - structure corrupted
    3 - command failed to execute
    4 - command not found
]]

-- Private functions: start --

-- die (EXIT_TROUBLE, 0, _("the -P option only supports a single pattern"));
-- input
--       die (EXIT_TROUBLE, 0, "%s: %s", str,
-- _("invalid context length argument"));
-- output
-- grep: oeu: invalid context length argument
local function die(exit_code, errfmt, ...)
    local errmsg = ("%s: %s: " .. errfmt):format(help.progname, ...)
    io.stderr:write(errmsg)
    os.exit(exit_code)
end

--- Set task description.
-- @param id task ID
-- @param newdesc new description
-- @return on success - 0
-- @return on failure - error code
local function _set_desc(id, newdesc)
    git.branch_switch(id)
    -- roachme: the only reasons why it might fail
    -- 1. Dir doesn't exist.
    -- 2. Has no permition.
    -- 3. Hardware isssue.
    -- core.lua gotta check that out, so we ain't gotta check, just do it.
    if not taskunit.set(id, "desc", newdesc) then
        return 1
    end
    git.branch_rename(id)
    return 0
end

--- Set task ID.
-- @param id task ID
-- @param newid new task ID
-- @return on success - 0
-- @return on failure - error code
local function _set_id(id, newid)
    local curr = taskid.getcurr()

    if id == newid then
        die(1, "the same task ID\n", newid)
    elseif taskid.exist(newid) then
        die(1, "task ID already exists\n", newid)
    end

    git.branch_switch(id)
    if not taskunit.set(id, "id", newid) then
        return 1
    end
    -- roachme: FIXME: you can't change this order.
    -- It's ok, but not obvious.
    taskid.del(id)
    taskid.add(newid)

    -- mark current task as current back again.
    if curr ~= id then
        taskid.setcurr(curr)
    end

    struct.rename(id, newid)
    git.branch_rename(newid)
    return 0
end

--- Set task link.
-- @param id task ID
-- @param newlink new task link
local function _set_link(id, newlink)
    if not taskunit.set(id, "link", newlink) then
        return 1
    end
    return 0
end

--- Set task priority.
-- @param id task ID
-- @param newprio new priority
local function _set_prio(id, newprio)
    local prio = taskunit.get(id, "prio")

    if newprio == prio then
        die(1, "the same priority\n", newprio)
    end
    if not taskunit.set(id, "prio", newprio) then
        return 1
    end
    return 0
end

--- Set task type.
-- @param id task ID
-- @param newtype new type
local function _set_type(id, newtype)
    if not taskunit.set(id, "type", newtype) then
        return 1
    end
    git.branch_rename(id)
    return 0
end

-- Private functions: end --

-- Public functions: start --

--- Add a new task.
-- Fill the rest with default values.
-- @see tman_set
-- @return on success - true
-- @return on failrue - false
local function tman_add()
    local id = arg[1]
    local prio = "mid"
    local tasktype = "bugfix"

    if not git.branch_isuncommited() then
        -- roachme: would be nice to know what repo.
        io.stderr:write("repo has uncommited changes\n")
        os.exit(1)
    end
    if not id then
        io.stderr:write("task ID required\n")
        os.exit(1)
    end
    if not taskid.add(id) then
        io.stderr:write(("'%s': already exists\n"):format(id))
        os.exit(1)
    end
    if not taskunit.add(id, tasktype, prio) then
        io.stderr:write("could not create new task unit\n")
        -- roachme:BUG: in case of error deletes previous task ID
        taskid.del(id)
        os.exit(1)
    end
    if not struct.create(id) then
        io.stderr:write("could not create new task structure\n")
        taskid.del(id)
        taskunit.del(id)
        os.exit(1)
    end
    git.branch_create(id)
    return 0
end

--- Backup and restore.
local function tman_archive()
    local optstr = "Rb:r:"
    local include_repo = false
    local backup_file, restore_file

    for optopt, optarg, optind in getopt(arg, optstr) do
        if optopt == "?" then
            die(1, "unrecognized option\n", arg[optind - 1])
        end
        if optopt == "b" then
            print("backup")
            backup_file = optarg
        elseif optopt == "r" then
            print("restore")
            restore_file = optarg
        elseif optopt == "R" then
            print("repo included")
            include_repo = true
        end
    end

    if backup_file and restore_file then
        die(1, "backup and restore options can't be used together\n", "")
    end

    if backup_file then
        core.backup(backup_file, include_repo)
    elseif restore_file then
        core.restore(restore_file)
    end
    return 0
end

--- Show task unit metadata.
local function tman_cat()
    local id
    local last_index = 1
    local optstr = "k:"
    local key

    for optopt, optarg, optind in getopt(arg, optstr) do
        if optopt == "?" then
            die(1, "unrecognized option\n", arg[optind - 1])
        end
        last_index = optind
        if optopt == "k" then
            key = optarg
        end
    end

    id = arg[last_index] or taskid.getcurr()
    if not id then
        die(1, "no current task ID\n", "")
    elseif not taskid.exist(id) then
        die(1, "no such task ID\n", id)
    end
    taskunit.cat(id, key)
    return 0
end

--- Config util for your workflow
local function tman_config()
    local optstr = "b:i:s"
    local fshow = true -- default option
    local fbase, finstall
    local vbase, vinstall

    for optopt, optarg, optind in getopt(arg, optstr) do
        if optopt == "?" then
            die(1, "unrecognized option\n", arg[optind - 1])
        end
        if optopt == "b" then
            fbase = true
            vbase = optarg
        elseif optopt == "i" then
            finstall = true
            vinstall = optarg
        elseif optopt == "s" then
            fshow = true
        end
    end

    if fbase then
        print("set base value", vbase)
    elseif finstall then
        print("set install value", vinstall)
    elseif fshow then
        print("show config")
        core.showconf()
    end
    return 0
end

--- Delete task.
local function tman_del()
    local id = arg[1] or taskid.getcurr()

    if not id then
        die(1, "no current task\n", "")
    end
    if not taskid.exist(id) then
        die(1, "no such task ID\n", id)
    end

    io.write("Task: ")
    taskunit.cat(id, "desc")
    io.write("Do you want to continue? [Yes/No] ")
    local confirm = io.read("*line")
    if confirm ~= "Yes" then
        print("deletion is cancelled")
        os.exit(1)
    end

    if not git.branch_isuncommited() then
        die(1, "repo has uncommited changes", "")
    end
    git.branch_delete(id)
    taskunit.del(id)
    taskid.del(id)

    -- roachme: make it pretty and easire to read.
    -- switch back to current task (if exists)
    local curr = taskid.getcurr()
    if curr then
        git.branch_switch(curr)
    end

    -- delete task dir at the end, cuz it causes error for tman.sh
    struct.delete(id)
    return 0
end

--- Get tman items.
-- Like prev/ curr task ID, etc.
local function tman_get()
    local item = arg[1] or "curr"

    if item == "curr" then
        print(taskid.getcurr() or "")
        return 0
    elseif item == "prev" then
        print(taskid.getprev() or "")
        return 0
    end

    -- error handling
    die(1, "no such task item\n", item)
end

--- List all task IDs.
-- Default: show only active task IDs.
local function tman_list()
    local active = true
    local completed = false
    local optstring = "Aac"

    for optopt, _, optind in getopt(arg, optstring) do
        if optopt == "?" then
            die(1, "unrecognized option\n", arg[optind - 1])
        end

        if optopt == "A" then
            active = true
            completed = true
        elseif optopt == "a" then
            active = true
            completed = false
        elseif optopt == "c" then
            active = false
            completed = true
        end
    end

    -- output header.
    if active == true and completed == true then
        print("All tasks:")
    elseif active == true and completed == false then
        print("Active tasks:")
    elseif active == false and completed == true then
        print("Completed tasks:")
    end

    taskid.list(active, completed)
    return 0
end

--- Pack commits in repos for review.
local function tman_pack()
    local id
    local optstr = "cmp"
    local last_index = 1
    local fcommit = true -- default option
    local fmake, fpush

    for optopt, _, optind in getopt(arg, optstr) do
        if optopt == "?" then
            die(1, "unrecognized option\n", arg[optind - 1])
        end

        last_index = optind
        if optopt == "c" then
            fcommit = true
        elseif optopt == "m" then
            fmake = true
        elseif optopt == "p" then
            fpush = true
        end
    end

    id = arg[last_index] or taskid.getcurr()

    if not id then
        die(1, "no current task\n", "")
    end
    if not taskid.exist(id) then
        die(1, "no such task ID\n", id)
    end
    if not git.branch_exists(id) then
        die(1, "task branch doesn't exist\n", "REPONAME")
    end

    if fpush then
        print("push branch to remote repo: under development")
    elseif fmake then
        print("run commands from the Makefile: under development")
    elseif fcommit then
        print("create commits")
        git.commit_create(id)
    end
    return 0
end

--- Switch to previous task.
local function tman_prev()
    local prev = taskid.getprev()

    if not prev then
        die(1, "no previous task\n", "")
    end
    if not git.check(prev) then
        die(1, "errors in repo. Put meaningful desc here\n", "REPONAME")
    end

    git.branch_switch(prev)
    taskid.swap()
    return 0
end

--- Amend task unit.
-- roachme:FIXME: switches task even when I change random task's unit.
local function tman_set()
    local id
    local last_index = 1
    local optstr = "di:l:p:t:"
    local newdesc -- roachme: get rid of this variable
    local options = {
        newid = { arg = nil, func = _set_id },
        newdesc = { arg = nil, func = _set_desc },
        newlink = { arg = nil, func = _set_link },
        newprio = { arg = nil, func = _set_prio },
        newtype = { arg = nil, func = _set_type },
    }

    -- roachme: It'd be better to show what task ID's changing. Maybe?

    for optopt, optarg, optind in getopt(arg, optstr) do
        if optopt == "?" then
            die(1, "unrecognized option\n", arg[optind - 1])
        end

        last_index = optind
        if optopt == "d" then
            io.write(("New description (%s): "):format(""))
            newdesc = io.read("*l")
            if not taskunit.check("desc", newdesc) then
                die(1, "description has illegal symbols\n", "")
            end
            -- roachme: be careful when delete newdesc variable.
            options.newdesc.arg = newdesc
        elseif optopt == "i" then
            if not taskunit.check("id", optarg) then
                die(1, "invalid id\n", optarg)
            end
            options.newid.arg = optarg
        elseif optopt == "l" then
            options.newlink.arg = optarg
        elseif optopt == "p" then
            if not taskunit.check("prio", optarg) then
                die(1, "invalid priority\n", optarg)
            end
            options.newprio.arg = optarg
        elseif optopt == "t" then
            if not taskunit.check("type", optarg) then
                die(1, "invalid task type\n", optarg)
            end
            options.newtype.arg = optarg
        end
    end

    id = arg[last_index] or taskid.getcurr()
    if not id then
        die(1, "no current task ID\n", "")
    end
    if not taskid.exist(id) then
        die(1, "no such task ID\n", id)
    end
    if not git.check(id) then
        die(1, "errors in repo. Put meaningful desc here\n", "REPONAME")
    end

    -- roachme: error if no arguments're passed

    if options.newid.arg and options.newtype.arg then
        io.stderr:write("BUG: options '-i' and '-t' can't be used togother\n")
        return 1
    end

    -- set values
    for _, item in pairs(options) do
        if item.arg then
            -- no worries, a function exit if there're any errors.
            item.func(id, item.arg)
        end
    end
    return 0
end

--- Synchronize task dir: structure, task status, remote repo.
-- With no options jump to task dir.
-- TODO: if wd util not supported then add its features here. Optioon `-w'.
local function tman_sync()
    local id
    local optstr = "rst"
    local fremote, fstruct, ftask
    local last_index = 1

    for optopt, _, optind in getopt(arg, optstr) do
        if optopt == "?" then
            die(1, "unrecognized option\n", arg[optind - 1])
        end

        last_index = optind
        if optopt == "r" then
            fremote = true
        elseif optopt == "s" then
            fstruct = true
        elseif optopt == "t" then
            ftask = true
        end
    end

    id = arg[last_index] or taskid.getcurr()
    if not id then
        die(1, "no current task ID\n", "")
    end
    if not taskid.exist(id) then
        die(1, "no such task ID\n", id)
    end
    if not git.branch_isuncommited() then
        die(1, "errors in repo. Put meaningful desc here\n", "REPONAME")
    end

    -- base case: other options might depend on it.
    if not git.branch_exists(id) then
        git.branch_create(id)
    end

    if fstruct then
        print("sync: struct")
        struct.create(id)
        git.branch_create(id)
        git.branch_switch(id)
        -- update list of active repos
        taskunit.set(id, "repo", git.branch_ahead(id))
    end
    if fremote then
        print("sync: remote")
        git.branch_default()
        git.branch_update(true)
        git.branch_switch(id)
        git.branch_rebase()
    end
    if ftask then
        print("sync: task status: under development")
    end
    return 0
end

--- Switch to task.
local function tman_use()
    local id = arg[1]

    if not id then
        die(1, "task ID required\n", "")
    end
    if not taskid.exist(id) then
        die(1, "task ID doesn't exist\n", id)
    end
    if taskid.getcurr() == id then
        die(1, "already in use\n", id)
    end
    if not git.check(id) then
        die(1, "one of the repos has uncommited changes", "REPONAME")
    end

    git.branch_switch(id)
    taskid.setcurr(id)
    return 0
end

-- Public functions: end --

local funcs = {
    add = tman_add,
    archive = tman_archive,
    cat = tman_cat,
    config = tman_config,
    del = tman_del,
    get = tman_get,
    help = function()
        return help.usage(arg[1])
    end,
    init = function()
        return core.init()
    end,
    list = tman_list,
    pack = tman_pack,
    prev = tman_prev,
    set = tman_set,
    sync = tman_sync,
    use = tman_use,
    ver = function()
        print(("%s version %s"):format(help.progname, help.version))
    end,
}

--- Util interface.
local function main()
    local cmd = arg[1] or "help"
    local corecheck = core.check()

    -- POSIX getopt() does not let permutations as GNU version.
    table.remove(arg, 1)

    -- Check that util's ok to run.
    if corecheck == 1 and cmd ~= "init" then
        io.stderr:write("tman: structure not inited\n")
        return 1
    end

    -- Call command.
    for name, func in pairs(funcs) do
        if cmd == name then
            return func()
        end
    end

    -- Command not found. Show some help.
    return help.usage(cmd)
end

os.exit(main())
