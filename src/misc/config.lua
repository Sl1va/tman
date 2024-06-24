--- Parse config file and provide env for the rest of the code.
-- @module config

--[[
    config.lua consist of two parts:
1. sys.conf  - essential for tman to work
2. user.conf - let user to customize workflow
]]

--[[

commit message pattern
 [<ticket ID>] <изменяемая часть>: <краткое описание>
]]

--local tmanconfig = require("tman_conf")
local utils = require("aux.utils")

-- roachme: gotto move these two into aux dir.
local sysconfig = require("misc.sysconfig")
local userconfig = require("misc.userconfig")

local config = {}


local function find_tmanconf(fname)
    local userhome = os.getenv("HOME")
    local confpathes = {
        userhome .. "/" .. ".tman/" .. fname,
        userhome .. "/" .. ".config/tman/" .. fname,
    }
    for _, conf in pairs(confpathes) do
        if utils.access(conf) then
            return conf
        end
    end
    return nil
end

local fsysconf = find_tmanconf("sys.conf")
local fusreconf = find_tmanconf("tman_conf.lua")
local fenv = find_tmanconf("env.list")

if not fsysconf then
    io.stderr:write("tman: sys.conf: system tmanconf missing\n")
    os.exit(1)
end
if not fusreconf then
    io.stderr:write("tman: user.conf: user config missing\n")
    os.exit(1)
end
if not fenv then
    io.stderr:write("tman: env.list: env file missing\n")
    os.exit(1)
end

local function load_structure()
    local prefix, env
    sysconfig.init(fsysconf)
    userconfig.init(fusreconf)

    -- get system config values
    prefix = sysconfig.get("prefix")
    env = sysconfig.get("env")

    -- load stuff from diff modules
    config.sys = sysconfig.getvars()
    config.user = userconfig.getvars()

    -- roachme: maybe it's better to move it to struct.lua
    config.core = {
        name = ".tman",
        ids = prefix .. "/" .. env .. "/.tman/ids",
        units = prefix .. "/" .. env .. "/.tman/units/",
        path = prefix .. "/" .. env .. "/.tman"
    }

    config.aux = {
        code = prefix .. "/" .. env .. "/code/",
        tasks = prefix .. "/" .. env .. "/tasks/",
    }

    -- roachme: hotfixes
    config.sys.fenv = fenv
end

---@param key string
function config.getsys(key)
    return config.sys[key]
end

---@param key string
---@param val string
function config.setsys(key, val)
    sysconfig.set(key, val)
    load_structure()
end

load_structure()

return config
