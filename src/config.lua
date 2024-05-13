--- Parse config file and provide env for the rest of the code.
-- @module config

local readconf = require("aux/readconf")


local userhome = os.getenv("HOME")

-- roachme: make the util to figure out the location of the config
readconf.init(userhome .. "/.config/tman/config")
local configvars = readconf.parse()

-- TODO: where should `tman` look for config file?
local fconfig = nil         -- config file

-- TODO: can be changes depending on where the user wants to keep it
local _base = userhome .. "/work/tman/"

-- tman main dirs
local _tmanbase = _base .. ".tman/"
local _codebase = _base .. "codebase/"
local _taskbase = _base .. "tasks/"

local _ids = _tmanbase .. "ids/"
local _repos = _tmanbase .. "repos"
local _taskids = _tmanbase .. "taskids"


--[[
local dir_tman = nil
local dir_code = nil
local dir_task = nil

local file_repo = nil
local file_taskid = nil
]]



--[[
tman.conf:
    TMANDIR="~/work/tman"
]]

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
