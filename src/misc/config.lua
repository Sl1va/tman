--- Parse config file and provide env for the rest of the code.
-- @module config

local tmanconfig = require("tman_conf")

local userhome = os.getenv("HOME")
local default_struct = {
    dirs = {},
    files = {},
}

local function tilde_to_home()
    tmanconfig.base = string.gsub(tmanconfig.base, "~", userhome or "")
    tmanconfig.install = string.gsub(tmanconfig.install, "~", userhome or "")
end

tilde_to_home()

-- Add default value if they're not defined in the config file
tmanconfig.struct = tmanconfig.struct or default_struct
tmanconfig.repos = tmanconfig.repos or {}

-- Tman dir structure
local tmandb = tmanconfig.base
tmanconfig.tmanbase = tmandb .. "/.tman/"
tmanconfig.initfile = tmanconfig.tmanbase .. ".tmaninit" -- mark tman dir
tmanconfig.taskids = tmanconfig.tmanbase .. "taskids"
tmanconfig.units = tmanconfig.tmanbase .. "units/"

tmanconfig.codebase = tmandb .. "/codebase/"
tmanconfig.taskbase = tmandb .. "/tasks/"

return tmanconfig
