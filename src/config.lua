--- Parse config file and provide env for the rest of the code.

local userhome = os.getenv("HOME")
local fconfig = nil         -- config file


local _base = userhome .. "/work/tman"
local _codebase = _base .. "/codebase"
local _taskbase = _base .. "/tasks"
local _repos = _base .. "/.tman/repos"

--[[
tman.conf:
    TMANDIR="~/work/tman"
]]

return {
    base = _base,
    repos = _repos,
    codebase = _codebase,
    taskbase = _taskbase,
    debug = true,
}
