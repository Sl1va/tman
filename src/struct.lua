--- From task filesystem structure.
-- create symlinks, helper dirs, etc.
-- @module struct

local utils = require("utils")

-- TODO: load this stuff from config file
--local struct_base = "~/work/tman/"
local struct_base = "~/trash/tman"

local struct_codebase = struct_base .. "/" .. "codebase"
local struct_taskbase = struct_base .. "/" .. "tasks"
local repos = {}
local tasks_base = nil


-- Private functions: end --

--- Create dirs.
local function _struct_dirs(_base)
    local dirs = { "logs", "lab" }

    for _, dir in pairs(dirs) do
        utils.mkdir(_base .. "/" .. dir)
    end
end

--- Create files.
local function _struct_files(_base)
    local files = { "note" }

    for _, file in pairs(files) do
        utils.touch(_base .. "/" .. file)
    end
end

--- Create symlinks to repos.
local function _struct_repos()
    for _, repo in pairs(repos) do
        utils.link()
    end
end

-- Private functions: end --


-- Public functions: start --

--- Init strcut.
local function struct_init(fbase, _taskid)
    struct_base = fbase or struct_base
    tasks_base = struct_taskbase .. "/" .. _taskid
end

--- Create dir for new task.
local function struct_create()
    utils.mkdir(tasks_base)
    _struct_dirs(tasks_base)
    _struct_files(tasks_base)
    _struct_repos()
end

--- Delete task dir.
local function struct_delete()
    utils.rm(tasks_base)
end

-- Public functions: end --

return {
    init = struct_init,
    create = struct_create,
    delete = struct_delete,
}
