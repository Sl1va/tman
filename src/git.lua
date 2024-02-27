--- Git wrapper
-- @module Git

local posix = require("posix")

local Git = {}
Git.__index = Git

local function log(fmt, ...)
    local msg = "git: " .. fmt:format(...)
    print(msg)
end

--- Class Git
-- @type Git


--- Init Git class.
-- @param taskid task ID
-- @param branch branch name
function Git.new(taskid, branch)
    local self = setmetatable({
        repos = {
            { name = "lede-feeds", branch = "develop" },
            { name = "cpeagent", branch = "master" },
            { name = "wmsnmpd", branch = "master" },
        },
        taskid = taskid,
        branch = branch,
    }, Git)
    return self
end

--- Check that repo has no uncommited changes.
-- roachme: it's discombabulated: true's false and vice versa
-- @param repo repo name
-- @return true on success, otherwise false
function Git:uncommited(reponame)
    local repopath = G_codebasepath .. reponame
    local cmd = ("git -C %s diff --quiet --exit-code"):format(repopath)
    if os.execute(cmd) == 0 then
        return false -- ok
    end
    return true -- error
end

--- Check repos for uncommited chanegs.
-- roachme: it's discombabulated: true's false and vice versa
function Git:check_uncommited()
    for _, repo in pairs(self.repos) do
        if self:uncommited(repo.name) then
            log("repo '%s' has uncommited changes", repo.name)
            return true
        end
    end
    return false
end

--- Switch to task branch.
-- @param branch branch to switch to. Default: task unit branch
function Git:branch_switch()
    if self:check_uncommited() then
        return false
    end
    -- actually switch to specified branch
    for _, repo in pairs(self.repos) do
        local repopath = G_codebasepath .. repo.name
        os.execute("git -C " .. repopath .. " checkout --quiet " .. self.branch)
    end
    return true
end

--- Switch to repo default branch.
function Git:branch_default()
    if self:check_uncommited() then
        return false
    end
    -- actually switch to specified branch
    for _, repo in pairs(self.repos) do
        local repopath = G_codebasepath .. repo.name
        os.execute("git -C " .. repopath .. " checkout --quiet " .. repo.branch)
    end
    return true
end

--- Git pull command.
-- @param all true pull all branches, otherwise only default branch
function Git:pull(all)
    if self:check_uncommited() then
        return false
    end
    for _, repo in pairs(self.repos) do
        local repopath = G_codebasepath .. repo.name
        os.execute("git -C " .. repopath .. " checkout --quiet " .. repo.branch)
        if all then
            os.execute("git -C " .. repopath .. " pull --quiet")
        else
            os.execute("git -C " .. repopath .. " pull --quiet origin " .. repo.branch)
        end
    end
end

function Git:branch_create()
    if self:check_uncommited() then
        return false
    end
    for _, repo in pairs(self.repos) do
        local repopath = G_codebasepath .. repo.name
        os.execute("git -C " .. repopath .. " checkout --quiet " .. repo.branch)
        os.execute(
            "git -C " .. repopath .. " checkout --quiet -b " .. self.branch
        )
    end
end

function Git:branch_delete()
    if self:check_uncommited() then
        return false
    end
    for _, repo in pairs(self.repos) do
        local repopath = G_codebasepath .. repo.name
        os.execute("git -C " .. repopath .. " checkout --quiet " .. repo.branch)
        os.execute(
            "git -C " .. repopath .. " branch --quiet -D " .. self.branch
        )
    end
end

function Git:check_commit() end

--- Create repo symlinks for task unit.
function Git:repolink()
    for _, repo in pairs(self.repos) do
        local src = G_codebasepath .. repo.name
        local dst = G_taskpath .. self.taskid .. "/" .. repo.name
        posix.link(src, dst, true)
    end
end

return Git
