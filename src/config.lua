--- Parse config file and provide env for the rest of the code.
-- @module config

local log = require("misc/log").init("config")
local utils = require("aux/utils")
local readconf = require("aux/readconf")


local userhome = os.getenv("HOME")

-- Default places to search config file.
local fconfig_files = {
    "/.tman/config",
    "/.config/tman/config",
}

--- Search config file.
-- @return true if found, otherwise false
local function search_config_file()
    for _, confile in pairs(fconfig_files) do
        confile = userhome .. "/" .. confile
        if utils.access(confile) then
            return confile
        end
    end
    return nil
end

-- TODO: where should `tman` look for config file?
local fconfig = search_config_file()

if not fconfig then
    log:err("config file not found")
    os.exit(1)
end

readconf.init(fconfig)
local configvars = readconf.parse()


-- tman main dirs
local _base = configvars.base .. "/"
local _tmanbase = _base .. ".tman/"
local _codebase = _base .. "codebase/"
local _taskbase = _base .. "tasks/"
local _ids = _tmanbase .. "ids/"

local _repos = _tmanbase .. "repos"
local _taskids = _tmanbase .. "taskids"

return {
    -- files
    repos = _repos,
    taskids = _taskids,

    -- dirs
    tmanbase = _tmanbase,
    codebase = _codebase,
    taskbase = _taskbase,
    ids = _ids,

    -- util flags to change behavior
    debug = true,
}
