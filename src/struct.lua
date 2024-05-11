--- From task filesystem structure.
-- create symlinks, helper dirs, etc.
-- @module struct

local utils = require("utils")

-- TODO: load repos from config
local struct_base = "./"
local repos = {}
local taskid = nil


-- Private functions: end --

--- Create dirs.
local function _struct_dirs()
    local dirs = { "logs", "lab" }

    for _, dir in pairs(dirs) do
        utils.mkdir(struct_base .. dir)
    end
end

--- Create files.
local function _struct_files()
    local files = { "note" }

    for _, file in pairs(files) do
        utils.touch(struct_base .. file)
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
    taskid = _taskid
end

--- Create dir for new task.
local function struct_add()
    utils.mkdir(struct_base .. taskid)
    _struct_dirs()
    _struct_files()
    _struct_repos()
end

--- Delete task dir.
local function struct_del()
    utils.rm(struct_base .. taskid)
end

-- Public functions: end --

return {
    init = struct_init,
    add = struct_add,
    del = struct_del,
}
