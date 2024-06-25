--- Parse config file and provide env for the rest of the code.
-- @module config

local utils = require("aux.utils")
-- roachme: gotta move these two into aux dir.
local sysconfig = require("misc.sysconfig")
local userconfig = require("misc.userconfig")

local config = {}

local function find_config_file(fname)
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

local fsysconf = find_config_file("sys.conf")
local fusreconf = find_config_file("tman_conf.lua")
local fenv = find_config_file("env.list")

function config.check()
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
end

function config.load()
    local prefix, env
    sysconfig.init(fsysconf)

    -- get system config values
    prefix = sysconfig.get("prefix")
    env = sysconfig.get("env")

    -- load stuff from diff modules
    config.sys = sysconfig.getvars()
    config.user = userconfig.getvars()

    -- roachme: maybe it's better to move it to struct.lua
    config.core = {
        name = ".tman",
        ids = prefix .. "/" .. env .. "/.tman/ids", -- it's a file
        units = prefix .. "/" .. env .. "/.tman/units/",
        path = prefix .. "/" .. env .. "/.tman/",
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
    config.load()
end

config.check() -- roachme: should be done in core.lua or setup.lua
config.load()

return config
