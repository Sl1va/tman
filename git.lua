--- Git wrapper
-- @module Git

local posix = require("posix")


local Git = {}
Git.__index = Git

local codebase = "/home/roach/work/codebase"
local taskbase = "/home/roach/work/tasks"

local function log(fmt, ...)
    local msg = "git: " .. fmt:format(...)
    print(msg)
end

--- Class Git
-- type Git


--- Init Git class.
-- @param taskid task ID
-- @param branch branch name
function Git.new(taskid, branch)
    local self = setmetatable({
        repos = {
            "cpeagent",
            "lede-feeds",
            "wmsnmpd",
        },
        taskid = taskid,
        branch = branch,
    }, Git)
    return self
end

function Git:uncommited(repo)
    local repopath = codebase .. "/" .. repo
    local cmd = ("git -C %s diff --quiet --exit-code"):format(repopath)
    if os.execute(cmd) == 0 then
        return false -- ok
    end
    return true -- error
end

--- Switch to another git branch.
-- @param branch branch to switch to. Default: task unit branch
function Git:branch_switch(branch)
    branch = branch or self.branch
    -- check no repo has uncommited changes
    for _, repo in pairs(self.repos) do
        if self:uncommited(repo) then
            log("repo '%s' has uncommited changes", repo)
            return false
        end
    end
    --- actually switch to specified branch
    for _, repo in pairs(self.repos) do
        local repopath = codebase .. "/" .. repo
        os.execute("git -C " .. repopath .. " checkout --quiet " .. branch)
    end
    return true
end

function Git:branch_create()
    -- check no repo has uncommited changes
    for _, repo in pairs(self.repos) do
        if self:uncommited(repo) then
            log("repo '%s' has uncommited changes", repo)
            return false
        end
    end
    --- actually switch to specified branch
    for _, repo in pairs(self.repos) do
        local repopath = codebase .. "/" .. repo
        os.execute("git -C " .. repopath .. " checkout --quiet develop")
        os.execute("git -C " .. repopath .. " checkout --quiet -b " .. self.branch)
    end
end

function Git:branch_delete()
    -- check no repo has uncommited changes
    for _, repo in pairs(self.repos) do
        if self:uncommited(repo) then
            log("repo '%s' has uncommited changes", repo)
            return false
        end
    end
    --- actually switch to specified branch
    for _, repo in pairs(self.repos) do
        local repopath = codebase .. "/" .. repo
        os.execute("git -C " .. repopath .. " checkout --quiet develop")
        os.execute("git -C " .. repopath .. " branch --quiet -D " .. self.branch)
    end
end

function Git:check_commit()
end

--- Create repo symlinks for task unit.
function Git:repolink()
    for _, repo in pairs(self.repos) do
        local src = codebase .. "/" .. repo
        local dst = taskbase .. "/" .. self.taskid .. "/" .. repo
        posix.link(src, dst, true)
    end
end

return Git
