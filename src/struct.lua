--- Form task filesystem structure.
-- Create repo symlinks, helper dirs, etc.
-- @module struct

local utils = require("utils")
local config = require("config")


-- TODO: load this stuff from config file
--local struct_base = "~/trash/tman"
local userhome = os.getenv("HOME")
local struct_base = userhome .. "/work/tman/"
local file_repos_config = struct_base .. "/.tman/repos"
local repos = {}

local path_taskid = nil
local struct_taskbase = struct_base .. "/" .. "tasks"
local struct_codebase = struct_base .. "/" .. "codebase"

-- Private functions: end --

local function _load_repos()
    local _repos = {}
    local f = io.open(file_repos_config)

    if not f then
        return _repos
    end

    for line in f:lines() do
        -- roachme: don't link this regex
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
local function _struct_repos()
    repos = _load_repos()

    for _, repo in pairs(repos) do
        local target = struct_codebase .. "/" .. repo
        local linkname = path_taskid .. "/" .. repo
        utils.link(target, linkname)
    end
end

-- Private functions: end --


-- Public functions: start --

--- Init strcut.
-- @param fbase
-- @param taskid task ID
local function struct_init(fbase, taskid)
    struct_base = fbase or struct_base
    path_taskid = struct_taskbase .. "/" .. taskid
end

--- Create dir for new task.
local function struct_create()
    utils.mkdir(path_taskid)
    _struct_dirs(path_taskid)
    _struct_files(path_taskid)
    _struct_repos()
    return true
end

--- Delete task dir.
local function struct_delete()
    return utils.rm(path_taskid)
end

-- Public functions: end --


return {
    init = struct_init,
    create = struct_create,
    delete = struct_delete,
}
