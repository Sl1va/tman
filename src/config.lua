--- Parse config file and provide env for the rest of the code.

local userhome = os.getenv("HOME")

-- TODO: where should `tman` look for config file?
local fconfig = nil         -- config file

-- TODO: can be changes depending on where the user wants to keep it
local _base = userhome .. "/work/tman/"

-- tman main dirs
local _tmanbase = _base .. ".tman/"
local _codebase = _base .. "codebase/"
local _taskbase = _base .. "tasks/"

local _repos = _tmanbase .. "repos"
local _taskids = _tmanbase .. "taskids"


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

    -- util flags to change behavior
    debug = true,
}
