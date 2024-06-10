--- Git wrapper.
-- @module Git

local config = require("misc.config")
local taskunit = require("taskunit")
local log = require("misc.log").init("git")
local utils = require("aux.utils")

local repos = config.repos

-- local git = "git -C %s " -- roachme: how to use it in here
local gdiff_word = "git -C %s diff --quiet --exit-code"
local gcheckout = "git -C %s checkout --quiet %s"
local gcheckoutb = "git -C %s checkout --quiet -b %s 2>/dev/null"
local gpull = "git -C %s pull --quiet origin %s"
local gpull_generic = "git -C %s pull --quiet"
local gbranchD = "git -C %s branch --quiet -D %s"
local gbranchm = "git -C %s branch --quiet -m %s"
local gbranchmrg = "git -C %s branch --merged %s | grep -q %s"
local gbranchprune = "git -C %s remote update origin --prune 1>/dev/null"
local gdiff_commits = "git -C %s diff --quiet --exit-code %s %s"
local grebase = "git -C %s rebase --quiet %s 2> /dev/null > /dev/null"
local grebaseabort = "git -C %s rebase --abort"

-- Private functions: end --

--- Check that repo has no uncommited changes.
-- @param reponame repo name
-- @return true on success, otherwise false
local function change_check_repo(reponame)
    local repopath = config.codebase .. reponame
    local cmd = string.format(gdiff_word, repopath)
    return utils.exec(cmd) == 0
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
local function git_branch_default()
    if not changes_check() then
        return false
    end
    for _, repo in pairs(repos) do
        local repopath = config.codebase .. repo.name
        utils.exec(gcheckout:format(repopath, repo.branch))
    end
    return true
end

--- Switch branch.
-- @param id task ID
-- @treturn bool true on success, otherwise false
local function git_branch_switch(id)
    local branch = taskunit.get(id, "branch")

    if not changes_check() then
        return false
    end
    for _, repo in pairs(repos) do
        local repopath = config.codebase .. repo.name
        utils.exec(gcheckout:format(repopath, branch))
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
        utils.exec(gcheckout:format(repopath, repo.branch))
        if all then
            utils.exec(gpull_generic:format(repopath))
        else
            utils.exec(gpull:format(repopath, repo.branch))
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
        if utils.exec(grebase:format(repopath, repo.branch)) ~= 0 then
            local errmsg = "repo '%s': rebase conflic. Resolve it manually.\n"
            io.stderr:write((errmsg):format(repo.name))
            utils.exec(grebaseabort:format(repopath))
        end
    end
end

--- Create a branch for task.
-- Also symlinks repos for a task.
-- @param id task ID
-- @return on success - true
-- @return on failure - false
local function git_branch_create(id)
    local branch = taskunit.get(id, "branch")

    if not changes_check() then
        return false
    end

    for _, repo in pairs(repos) do
        local repopath = config.codebase .. repo.name
        utils.exec(gcheckout:format(repopath, repo.branch))
        utils.exec(gcheckoutb:format(repopath, branch))
    end
    return true
end

--- Rename task branch.
-- @param id task ID
-- @return true on success, otherwise false
local function git_branch_rename(id)
    local newbranch = taskunit.get(id, "branch")

    if not changes_check() then
        return 1
    end
    for _, repo in pairs(repos) do
        local repopath = config.codebase .. repo.name
        utils.exec(gbranchm:format(repopath, newbranch))
    end
    return 0
end

--- Delete task branch.
-- @param id task ID
-- @return true on success, otherwise false
local function git_branch_delete(id)
    local branch = taskunit.get(id, "branch")

    if not changes_check() then
        return false
    end
    for _, repo in pairs(repos) do
        local repopath = config.codebase .. repo.name
        utils.exec(gcheckout:format(repopath, repo.branch))
        utils.exec(gbranchD:format(repopath, branch))
    end
    return true
end

--- Check that all task's repo branches are merged into the default one.
-- roachme: let a user know if no task commits presented.
-- @return task branch's merged - true
-- @return task branch's not merged - false
local function git_branch_merged(id)
    local retcode = true
    local branch = taskunit.get(id, "branch")

    --  roachme: doesn't work if merge conflic with default branch.
    --  which happens quite often.

    if not changes_check() then
        return false
    end
    for _, repo in pairs(repos) do
        local repopath = config.codebase .. repo.name
        local cmd = gbranchmrg:format(repopath, repo.branch, branch)

        -- update list of local branches with remote one
        utils.exec(gbranchprune:format(repopath))
        if utils.exec(cmd) ~= 0 then
            print(" repo:", repo.name)
            retcode = false
        end
    end
    return retcode
end

--- Get repos having taks commits.
-- roachme: Refactor it.
-- @return table of repos
local function git_branch_ahead(id)
    -- roachme:FIXME: it checks diff between task branch and defaul branch.
    -- it should check uncommited changes instead.
    local res = {}
    local branch = taskunit.get(id, "branch")

    for _, repo in pairs(repos) do
        local repopath = config.codebase .. repo.name
        local cmd = gdiff_commits:format(repopath, repo.branch, branch)
        if not change_check_repo(repo.name) then
            --print("change_check_repo")
            -- has uncommited changes
            table.insert(res, repo.name)
        elseif utils.exec(cmd) ~= 0 then
            --print("exec", cmd)
            -- has uncommited changes
            -- has commits ahead
            table.insert(res, repo.name)
        end
    end
    return res
end

local function git_check(id)
    -- mini-map: check that
    -- 1. task branch exists
    -- 2. task branch has no uncommited changes.
    -- 3. task branch can be rebased against default branch (pro'ly)

    local branch = taskunit.get(id, "branch")
    local gitcmd = "git -C %s "

    -- 1. task branch exists
    for _, repo in pairs(repos) do
        local cmd_branch_exists = gitcmd .. "show-ref --quiet refs/heads/%s"
        local repopath = config.codebase .. repo.name
        local cmd = cmd_branch_exists:format(repopath, branch)
        if utils.exec(cmd) ~= 0 then
            io.stderr:write(("branch '%s' doesn't exist\n"):format(branch))
            return false
        end
    end

    -- 2. task branch has no uncommited changes.
    for _, repo in pairs(repos) do
        local cmd_uncommited_changes = "git -C %s status --porcelain %s"
        local repopath = config.codebase .. repo.name
        local cmd = cmd_uncommited_changes:format(repopath, branch)
        local file = assert(io.popen(cmd))
        local res = file:read()
        file:close()
        if res ~= nil then
            io.stderr:write(
                ("repo '%s' uncommited changes\n"):format(repo.name)
            )
            return false
        end
    end

    -- 3. task branch can be rebased against default branch (pro'ly)
    --[[
    for _, repo in pairs(repos) do
    end
    ]]
    return true
end

-- Public functions: end --

return {
    check = git_check,
    --branch_prune = git_branch_prune,
    branch_create = git_branch_create,
    branch_delete = git_branch_delete,
    branch_switch = git_branch_switch,
    branch_update = git_branch_update,
    branch_rename = git_branch_rename,
    branch_rebase = git_branch_rebase,
    branch_merged = git_branch_merged,
    branch_default = git_branch_default,

    -- under development
    branch_ahead = git_branch_ahead,
}
