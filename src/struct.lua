--- Form task filesystem structure.
-- Create repo symlinks, helper dirs, etc.
-- @module struct

local utils = require("aux.utils")
local config = require("misc.config")

local struct = {}

-- Private functions: end --

--- Create dirs.
-- @param base directry structure base
local function _struct_dirs(base)
    for _, dir in pairs(config.struct.dirs) do
        utils.mkdir(base .. "/" .. dir)
    end
end

--- Create files.
-- @param base file structure base
local function _struct_files(base)
    for _, file in pairs(config.struct.files) do
        utils.touch(base .. "/" .. file)
    end
end

--- Create symlinks to repos.
-- @param id task ID
local function _struct_repos(id)
    for _, repo in pairs(config.repos) do
        local reponame = repo.name
        local target = config.codebase .. "/" .. reponame
        local linkname = config.taskbase .. "/" .. id .. "/" .. reponame
        utils.link(target, linkname)
    end
end

-- Private functions: end --

-- Public functions: start --

--- Create task filesystem structure.
-- @param id task ID
-- @return on success - true
-- @return on failure - false
function struct.create(id)
    local taskdir = config.taskbase .. "/" .. id

    utils.mkdir(taskdir)
    _struct_dirs(taskdir)
    _struct_files(taskdir)
    _struct_repos(id)
    return true
end

--- Delete task filesystem structure.
-- @param id task ID
-- @return on success - true
-- @return on failure - false
function struct.delete(id)
    local taskdir = config.taskbase .. "/" .. id
    return utils.rm(taskdir)
end

--- Rename task dir.
-- @param oldid old task ID
-- @param newid new task ID
-- @return on success - true
-- @return on failure - false
function struct.rename(oldid, newid)
    local old_dir = config.units .. oldid
    local new_dir = config.units .. newid
    return utils.rename(old_dir, new_dir) == 0
end

-- Public functions: end --

return struct
