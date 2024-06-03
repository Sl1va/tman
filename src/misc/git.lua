--- Git wrapper.
-- @module Git

local config = require("config")
local log = require("misc/log").init("git")
local taskunit = require("taskunit")

-- local git = "git -C %s " -- roachme: how to use it in here
local gdiff_word = "git -C %s diff --quiet --exit-code"
local gcheckout = "git -C %s checkout --quiet %s"
local gcheckoutb = "git -C %s checkout --quiet -b %s 2>/dev/null"
local gpull = "git -C %s pull --quiet origin %s"
local gpull_generic = "git -C %s pull --quiet"
local gbranchD = "git -C %s branch --quiet -D %s"
local gbranchm = "git -C %s branch --quiet -m %s"
local grebase = "git -C %s rebase --quiet %s 2> /dev/null > /dev/null"
local grebaseabort = "git -C %s rebase --abort"
local repos = config.repos

-- Private functions: end --

--- Check that repo has no uncommited changes.
-- @param reponame repo name
-- @return true on success, otherwise false
local function change_check_repo(reponame)
    local repopath = config.codebase .. reponame
    local cmd = string.format(gdiff_word, repopath)
    return os.execute(cmd) == 0
end

--- Check repos for uncommited chanegs.
local function changes_check()
    for _, repo in pairs(repos) do
        if not change_check_repo(repo.name) then
            log:err("repo '%s' has uncommited changes", repo.name)
            return false
        end
    end
    return true
end

-- Private functions: end --

-- Public functions: start --

--- Switch to repo default branch.
-- @treturn bool true on success, otherwise false
local function git_branch_switch_default()
    if not changes_check() then
        return false
    end
    for _, repo in pairs(repos) do
        local repopath = config.codebase .. repo.name
        os.execute(gcheckout:format(repopath, repo.branch))
    end
    return true
end

--- Switch branch.
-- @param id task ID
-- @treturn bool true on success, otherwise false
local function git_branch_switch(id)
    local branch = taskunit.getunit(id, "branch")

    if not changes_check() then
        return false
    end
    for _, repo in pairs(repos) do
        local repopath = config.codebase .. repo.name
        os.execute(gcheckout:format(repopath, branch))
    end
    return true
end

--- Git pull command.
-- @param all true pull all branches, otherwise only default branch
local function git_branch_update(all)
    if not changes_check() then
        return false
    end
    for _, repo in pairs(repos) do
        local repopath = config.codebase .. repo.name
        os.execute(gcheckout:format(repopath, repo.branch))
        if all then
            os.execute(gpull_generic:format(repopath))
        else
            os.execute(gpull:format(repopath, repo.branch))
        end
    end
end

--- Rebase task branch against default.
local function git_branch_rebase()
    if not changes_check() then
        return false
    end
    for _, repo in pairs(repos) do
        local repopath = config.codebase .. repo.name
        if os.execute(grebase:format(repopath, repo.branch)) ~= 0 then
            local errmsg = "repo '%s': rebase conflic. Resolve it manually.\n"
            io.stderr:write((errmsg):format(repo.name))
            os.execute(grebaseabort:format(repopath))
        end
    end
end

--- Create a branch for task.
-- Also symlinks repos for a task.
-- @param id task ID
-- @return true on success, otherwise false
local function git_branch_create(id)
    local branch = taskunit.getunit(id, "branch")

    if not changes_check() then
        return 1
    end

    for _, repo in pairs(repos) do
        local repopath = config.codebase .. repo.name
        os.execute(gcheckout:format(repopath, repo.branch))
        os.execute(gcheckoutb:format(repopath, branch))
    end
    return 0
end

--- Rename task branch.
-- @param id task ID
-- @return true on success, otherwise false
local function git_branch_rename(id)
    local newbranch = taskunit.getunit(id, "branch")

    if not changes_check() then
        return 1
    end
    for _, repo in pairs(repos) do
        local repopath = config.codebase .. repo.name
        os.execute(gbranchm:format(repopath, newbranch))
    end
    return 0
end

--- Delete task branch.
-- @param id task ID
-- @return true on success, otherwise false
local function git_branch_delete(id)
    local branch = taskunit.getunit(id, "branch")

    if not changes_check() then
        return false
    end
    for _, repo in pairs(repos) do
        local repopath = config.codebase .. repo.name
        os.execute(gcheckout:format(repopath, repo.branch))
        os.execute(gbranchD:format(repopath, branch))
    end
    return true
end

-- Public functions: end --

return {
    branch_create = git_branch_create,
    branch_delete = git_branch_delete,
    branch_switch = git_branch_switch,
    branch_update = git_branch_update,
    branch_rename = git_branch_rename,
    branch_rebase = git_branch_rebase,
    branch_switch_default = git_branch_switch_default,
}
