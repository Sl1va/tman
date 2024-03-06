--- Git wrapper.
-- @module Git

local posix = require("posix")
local globals = require("globals")
local log = require("log").init("git")

--[[
Private functions:
    load_repos    - load repos from config file
    repo_symlink  - create repo symlinks for a task
    change_check  - check that repo has no unsaved changes


Public functions:
    branch_switch_default - switch to repo default branch
    branch_create - create new branch for a task
    branch_delete - delete task branch
    branch_switch - switch branch (default: repo's default branch)
    branch_update - pull changes from origin and tryna rebase against task branch
    commit_check  - check commit message
]]

local Git = {}
Git.__index = Git

--- Class Git
-- @type Git

-- Private functions: end --

--- Load repos from config file.
function Git:load_repos()
    local repos = {}
    local f = io.open(globals.G_tmanrepos)

    if not f then
        log:err("no file for repos")
        return false
    end
    for line in f:lines() do
        local name, branch, path = string.match(line, "(.*),(.*),(.*)")
        table.insert(repos, { name = name, branch = branch, path = path or "" })
    end
    return repos
end

--- Check that repo has no uncommited changes.
-- @param reponame repo name
-- @return true on success, otherwise false
function Git:change_check_repo(reponame)
    local repopath = globals.G_codebasepath .. reponame
    local cmd = string.format(self.gdiff_word, repopath)
    return os.execute(cmd) == 0
end

--- Check repos for uncommited chanegs.
function Git:changes_check()
    for _, repo in pairs(self.repos) do
        if not self:change_check_repo(repo.name) then
            log:err("repo '%s' has uncommited changes", repo.name)
            return false
        end
    end
    return true
end

--- Create repo symlinks for task unit.
-- @return true on success, otherwise false
function Git:repo_symlink()
    for _, repo in pairs(self.repos) do
        local src = globals.G_codebasepath .. repo.name
        local dst = globals.G_taskpath .. self.taskid .. "/" .. repo.name
        posix.link(src, dst, true)
    end
    return true
end

-- Private functions: end --

-- Public functions: start --

--- Init Git class.
-- @param taskid task ID
-- @param branch branch name
-- @return Git object
function Git.new(taskid, branch)
    local self = setmetatable({
        taskid = taskid,
        branch = branch,
        git = "git -C %s ", -- roachme: how to use it in here?
        gdiff_word = "git -C %s diff --quiet --exit-code",
        gcheckout = "git -C %s checkout --quiet %s",
        gcheckoutb = "git -C %s checkout --quiet -b %s",
        gpull = "git -C %s pull --quiet origin %s",
        gpull_generic = "git -C %s pull --quiet",
        gbranchD = "git -C %s branch --quiet -D %s",
    }, Git)
    self.repos = self:load_repos()
    return self
end

--- Switch to repo default branch.
-- @treturn bool true on success, otherwise false
function Git:branch_switch_default()
    if not self:changes_check() then
        return false
    end
    for _, repo in pairs(self.repos) do
        local repopath = globals.G_codebasepath .. repo.name
        os.execute(self.gcheckout:format(repopath, repo.branch))
    end
    return true
end

--- Switch branch.
-- @param branch task branch name
-- @treturn bool true on success, otherwise false
function Git:branch_switch(branch)
    if not self:changes_check() then
        return false
    end
    for _, repo in pairs(self.repos) do
        local repopath = globals.G_codebasepath .. repo.name
        os.execute(self.gcheckout:format(repopath, branch))
    end
    return true
end

--- Git pull command.
-- @param all true pull all branches, otherwise only default branch
function Git:branch_update(all)
    -- roachme: gotta add branch rebase and conflic handler
    if not self:changes_check() then
        return false
    end
    for _, repo in pairs(self.repos) do
        local repopath = globals.G_codebasepath .. repo.name
        os.execute(self.gcheckout:format(repopath, repo.branch))
        if all then
            os.execute(self.gpull_generic:format(repopath))
        else
            os.execute(self.gpull:format(repopath, repo.branch))
        end
    end
end

--- Create a branch for task.
-- Also symlinks repos for a task.
-- @return true on success, otherwise false
function Git:branch_create()
    local taskdir = globals.G_taskpath .. self.taskid

    if not self:changes_check() then
        return false
    end

    posix.mkdir(taskdir)
    for _, repo in pairs(self.repos) do
        local repopath = globals.G_codebasepath .. repo.name
        os.execute(self.gcheckout:format(repopath, repo.branch))
        os.execute(self.gcheckoutb:format(repopath, self.branch))
    end
    return self:repo_symlink()
end

--- Delete task branch.
-- @return true on success, otherwise false
function Git:branch_delete()
    if not self:changes_check() then
        return false
    end
    for _, repo in pairs(self.repos) do
        local repopath = globals.G_codebasepath .. repo.name
        os.execute(self.gcheckout:format(repopath, repo.branch))
        os.execute(self.gbranchD:format(repopath, self.branch))
    end
    return true
end

--- Check that commit fits messages rules.
function Git:commit_check() end

-- Public functions: end --

return Git
