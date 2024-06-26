local git = require("core.git")
local taskid = require("core.taskid")
local struct = require("core.struct")
local taskunit = require("core.taskunit")
local common = require("core.common")
local getopt = require("posix.unistd").getopt

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
            common.die(1, "unrecognized option\n", arg[optind - 1])
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
        common.die(1, "no current task ID\n", "")
    end
    if not taskid.exist(id) then
        common.die(1, "no such task ID\n", id)
    end

    if fstruct then
        print("sync: struct")
        -- roach:BUG: It's gotta update list of active repos, but can't if
        -- they have uncommited changes. BUT it should be able.
        if not git.check(id) then
            common.die(
                1,
                "errors in repo. Put meaningful desc here\n",
                "REPONAME"
            )
        end
        struct.create(id)
        git.branch_create(id)
        git.branch_switch(id)
        taskunit.set(id, "repos", git.branch_ahead(id))
    end
    if fremote then
        print("sync: remote")
        if not git.check(id) then
            common.die(
                1,
                "errors in repo. Put meaningful desc here\n",
                "REPONAME"
            )
        end
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

return tman_sync
