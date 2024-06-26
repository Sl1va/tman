local git = require("core.git")
local taskid = require("core.taskid")
local common = require("core.common")

--- Switch to task.
local function tman_use()
    local id = arg[1]
    -- roachme: can't use help option cuz tman.sh fails.

    if not id then
        common.die(1, "task ID required\n", "")
    end
    if not taskid.exist(id) then
        common.die(1, "task ID doesn't exist\n", id)
    end
    if taskid.getcurr() == id then
        common.die(1, "already in use\n", id)
    end
    if not git.check(id) then
        common.die(1, "one of the repos has uncommited changes", "REPONAME")
    end

    git.branch_switch(id)
    taskid.setcurr(id)
    return 0
end

return tman_use
