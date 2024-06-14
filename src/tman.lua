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

local errcodes = {
    ok = 0,
    not_inited = 1,
    corrupted = 2,
    command_failed = 2,
    command_not_found = 3,
}

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
    if not git.branch_switch(id) then
        return 1
    end
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
    if id == newid then
        die(1, "the same task ID\n", newid)
    elseif taskid.exist(newid) then
        die(1, "task ID already exists\n", newid)
    end

    if not git.branch_switch(id) then
        return 1
    end
    if not taskunit.set(id, "id", newid) then
        return 1
    end
    -- roachme: FIXME: you can't change this order.
    -- It's ok, but not obvious.
    taskid.del(id)
    taskid.add(newid)
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

--- Check ID is passed and exists in database.
-- @param id task ID
-- @return true on success, otherwise false
local function _checkid(id)
    id = id or taskid.getcurr()
    if not id then
        die(1, "no current task\n", "")
    end
    if not taskid.exist(id) then
        die(1, "no such task ID\n", id)
    end
    return true
end

-- Private functions: end --

-- Public functions: start --

--- Add a new task.
-- Fill the rest with default values.
-- @see tman_set
-- @param id task ID
-- @return on success - true
-- @return on failrue - false
local function tman_add(id)
    local prio = "mid"
    local tasktype = "bugfix"

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
        -- roachme: in case of error deletes previous task ID
        taskid.del(id)
        os.exit(1)
    end
    if not struct.create(id) then
        io.stderr:write("could not create new task structure\n")
        taskid.del(id)
        taskunit.del(id)
        os.exit(1)
    end
    if not git.branch_create(id) then
        io.stderr:write("could not create new branch for a task\n")
        taskid.del(id)
        taskunit.del(id)
        struct.delete(id)
        os.exit(1)
    end
    return 0
end

--- Switch to another task.
local function tman_use()
    local id
    local last_index = 1
    local optstr = ""

    for optopt, optarg, optind in getopt(arg, optstr) do
        if optopt == "?" then
            die(1, "unrecognized option\n", arg[optind - 1])
        end
        if optopt == "h" then
            print("WARNING: fake option", optarg or "NIL")
        end
    end

    id = arg[last_index]
    if not id then
        die(1, "task ID required\n", "")
    end
    if not taskid.exist(id) then
        die(1, "task ID doesn't exist\n", id)
    end
    if taskid.getcurr() == id then
        die(1, "already in use\n", id)
    end
    if not git.branch_switch(id) then
        die(1, "has uncommited changes\n", "repo")
    end
    taskid.setcurr(id)
    return 0
end

--- Switch to previous task.
local function tman_prev()
    local prev = taskid.getprev()

    if not prev then
        die(1, "no previous task\n", "")
    end
    if not git.branch_switch(prev) then
        die(1, "repo has uncommited changes\n", "REPONAME")
    end
    taskid.swap()
    return 0
end

--- List all task IDs.
-- Default: show only active task IDs.
local function tman_list()
    local active = true
    local completed = false
    local optstring = "Aac"

    for optopt, _, optind in getopt(arg, optstring) do
        if optopt == "?" then
            local errmsg = "unrecognized option '%s'\n"
            io.stderr:write(errmsg:format(arg[optind - 1]))
            return 0
        end
        if optopt == "A" then
            print("All tasks:")
            active = true
            completed = true
        --[[
        elseif optopt == "a" then
            -- use default flags
        ]]
        elseif optopt == "c" then
            print("Completed tasks:")
            active = false
            completed = true
        end
    end
    if active == true and completed == false then
        print("Active tasks:")
    end
    taskid.list(active, completed)
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

--- Amend task unit.
-- roachme:FIXME: switches task even when I change random task's unit.
local function tman_set()
    local id
    local last_index = 1
    local optstr = "di:l:p:t:"
    local newdesc, newid, newlink, newprio, newtype

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
        elseif optopt == "i" then
            newid = optarg
        elseif optopt == "l" then
            newlink = optarg
        elseif optopt == "p" then
            if not taskunit.check("prio", optarg) then
                die(1, "invalid priority\n", optarg)
            end
            newprio = optarg
        elseif optopt == "t" then
            if not taskunit.check("type", optarg) then
                die(1, "invalid task type\n", optarg)
            end
            newtype = optarg
        end
    end

    id = arg[last_index] or taskid.getcurr()
    if not id then
        die(1, "no current task ID\n", "")
    elseif not taskid.exist(id) then
        die(1, "no such task ID\n", id)
    end

    if newid and newtype then
        io.stderr:write("BUG: options '-i' and '-t' can't be used togother\n")
        return 1
    end

    if newdesc then
        _set_desc(id, newdesc)
    end
    if newid then
        _set_id(id, newid)
    end
    if newlink then
        _set_link(id, newlink)
    end
    if newprio then
        _set_prio(id, newprio)
    end
    if newtype then
        _set_type(id, newtype)
    end
    return 0
end

--- Update git repos.
-- @param cmd command
local function tman_sync(cmd)
    local id = taskid.getcurr()

    if not id then
        io.stderr:write("no current task\n")
        os.exit(1)
    end

    --[[
repo        - git pull from remote repo
task        - update task status
struct      - update task structure: dirs, files, symlinks
]]

    -- create task structure if needed
    struct.create(id)

    -- create git branch if needed
    git.branch_create(id)

    -- update active repos
    local active_repos = git.branch_ahead(id)
    if not taskunit.set(id, "repo", active_repos) then
        return 1
    end

    -- switch to task branch, that's it. Default option.
    if not cmd or cmd == "struct" then
        -- roachme: failes if repo's uncommited changes
        git.branch_switch(id)
        return errcodes.ok
    elseif cmd == "repo" then
        if not git.branch_default() then
            return errcodes.command_failed
        end
        git.branch_update(true)
        git.branch_switch(id)
        git.branch_rebase()
        return errcodes.ok
    end
    local errmsg = "%s: update: command not found '%s'\n"
    io.stderr:write(errmsg:format(help.progname, cmd))
    io.stderr:write("Commands: [struct|task|repo]\n")
    return errcodes.command_failed
end

--- Delete task.
-- @param id task ID
local function tman_del(id)
    id = id or taskid.getcurr()

    if not _checkid(id) then
        os.exit(1)
    end

    taskunit.cat(id, "desc")
    io.write("Do you want to continue? [Yes/No] ")
    local confirm = io.read("*line")
    if confirm ~= "Yes" then
        print("deletion is cancelled")
        os.exit(1)
    end

    -- roachme: when it deletes task branch what branch is it on?
    -- anyway, find a nice logic.
    if not git.branch_delete(id) then
        die(1, "repo has uncommited changes", "")
    end
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

--- Move current task to done status.
-- @param id task id
-- roachme: It moves to ACTV, COMP status.
local function tman_done()
    local retcode
    local curr = taskid.getcurr()
    local prev = taskid.getprev()
    local id = curr

    if id ~= "under development" then
        print("under development. Gotta check that task branch is merged")
        return 2
    end

    if not _checkid() then
        return errcodes.command_failed
    end

    taskid.unsetcurr()

    -- provide retcode for shell command
    if id == curr then
        retcode = 0
    elseif id == prev then
        retcode = 1
    else
        retcode = 2
    end

    if not git.branch_default() then
        io.stderr:write("repo has uncommited changes\n")
        os.exit(1)
    end

    -- roachme:FIXME: switch to previous task branch

    -- roachme: if task's done delete git branch,
    --          MAYBE task dir as well (nah, leave it)
    --          BUT make sure task branch's merged into default branch

    return retcode
end

--- Config util for your workflow
-- @param subcmd subcommand
local function tman_config(subcmd)
    if not subcmd then
        return core.showconf()
    end
end

--- Get special task ID unit.
-- @param unit task unit
local function tman_get(unit)
    unit = unit or "curr"

    if unit == "curr" then
        print(taskid.getcurr() or "")
    elseif unit == "prev" then
        print(taskid.getprev() or "")
    else
        local errmsg = "err: no such ID type '%s'\n"
        io.stderr:write(errmsg:format(unit or "no idtype"))
    end
end

local function tman_test() end

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

--- Pack commits in repos for review.
local function tman_pack(id)
    id = id or taskid.getcurr()

    if not taskid.exist(id) then
        die(1, "task ID doesn't exist\n", id)
    end

    git.commit_create(id)
end

-- Public functions: end --

--- Util interface.
local function main()
    local cmd = arg[1] or "help"
    local corecheck = core.check()

    -- posix getopt does not let permutations as GNU version
    table.remove(arg, 1)

    if corecheck == 1 and cmd ~= "init" then
        io.stderr:write("tman: structure not inited\n")
        return 1
    end

    if cmd == "init" then
        return core.init()
    elseif cmd == "add" then
        return tman_add(arg[1])
    elseif cmd == "set" then
        return tman_set()
    elseif cmd == "use" then
        return tman_use()
    elseif cmd == "cat" then
        return tman_cat()
    elseif cmd == "del" then
        return tman_del(arg[1])
    elseif cmd == "list" then
        return tman_list()
    elseif cmd == "sync" then
        return tman_sync(arg[1])
    elseif cmd == "done" then
        return tman_done()
    elseif cmd == "get" then
        return tman_get(arg[1])
    elseif cmd == "prev" then
        return tman_prev()
    elseif cmd == "config" then
        return tman_config(arg[1])
    elseif cmd == "test" then
        return tman_test()
    elseif cmd == "archive" then
        return tman_archive()
    elseif cmd == "pack" then
        return tman_pack(arg[1])
    elseif cmd == "help" then
        return help.usage(arg[1])
    elseif cmd == "ver" then
        print(("%s version %s"):format(help.progname, help.version))
        return 0
    end
    -- error: command not found. Show usage.
    return help.usage(cmd)
end

os.exit(main())
