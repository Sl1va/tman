--- Form task filesystem structure.
-- Create repo symlinks, helper dirs, etc.
-- @module struct

local utils = require("aux/utils")
local config = require("config")

local struct_repos = config.repos
local struct_codebase = config.codebase
local struct_taskbase = config.taskbase
local repos = {}


-- Private functions: end --

local function _load_repos()
    local _repos = {}
    local f = io.open(struct_repos)

    if not f then
        return _repos
    end

    for line in f:lines() do
        -- roachme: don't like this regex
        local repo = line:match("([a-z-A-Z0-9_]*)")
        table.insert(_repos, repo)
    end
    f:close()
    return _repos
end

--- Create dirs.
local function _struct_dirs(base)
    local dirs = { "logs", "lab" }

    for _, dir in pairs(dirs) do
        utils.mkdir(base .. "/" .. dir)
    end
end

--- Create files.
local function _struct_files(base)
    local files = { "note" }

    for _, file in pairs(files) do
        utils.touch(base .. "/" .. file)
    end
end

--- Create symlinks to repos.
-- @param id task ID
local function _struct_repos(id)
    repos = _load_repos()

    for _, repo in pairs(repos) do
        local target = struct_codebase .. "/" .. repo
        local linkname = struct_taskbase .. "/" .. id .. "/" .. repo
        utils.link(target, linkname)
    end
end

-- Private functions: end --


-- Public functions: start --

--- Create new task filesystem structure.
-- @param id task id
local function struct_create(id)
    local taskdir = struct_taskbase .. "/" .. id

    utils.mkdir(taskdir)
    _struct_dirs(taskdir)
    _struct_files(taskdir)
    _struct_repos(id)
    return true
end

--- Delete task filesystem structure.
-- @param id task id
local function struct_delete(id)
    local taskdir = struct_taskbase .. "/" .. id
    return utils.rm(taskdir)
end

-- Public functions: end --


return {
    create = struct_create,
    delete = struct_delete,
}
