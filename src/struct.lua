--- Form task filesystem structure.
-- Create repo symlinks, helper dirs, etc.
-- @module struct

local utils = require("aux/utils")
local config = require("config")

local repos = config.repos
local struct_codebase = config.codebase
local struct_taskbase = config.taskbase


-- Private functions: end --

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
    for _, repo in pairs(repos) do
        local reponame = repo.name
        local target = struct_codebase .. "/" .. reponame
        local linkname = struct_taskbase .. "/" .. id .. "/" .. reponame
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
