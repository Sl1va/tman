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

local tmanconfig = require("tman_conf")
local utils = require("aux.utils")

-- roachme: gotto move these two into aux dir.
local sysconfig = require("misc.sysconfig")
local userconfig = require("misc.userconfig")

-- get tmanconf: base and install

local userhome = os.getenv("HOME")
local default_repos = {}
local default_branch = "TYPE/ID_DESC_DATE"
local default_struct = {
    dirs = {},
    files = {},
}

local function find_tmanconf(fname)
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

-- roachme: should be in aux.utils.lua
local function remove_quotes(str)
    local res = ""

    for i = 1, #str do
        local c = string.sub(str, i, i)
        if c ~= '"' and c ~= "'" then
            res = res .. c
        end
    end

    return res
end

local function tmanconf_getvals(fname)
    local prefix, install
    local f = io.open(fname)

    if not f then
        os.exit(1)
    end

    -- parse vars
    for line in f:lines() do
        local mark = string.match(line, "([a-z]*)")
        if mark == "prefix" then
            prefix = string.match(line, ".*%s=%s(.*)")
            prefix = remove_quotes(prefix)
        elseif mark == "install" then
            install = string.match(line, ".*%s=%s(.*)")
            install = remove_quotes(install)
        end
    end

    f:close()
    return prefix, install
    --return prefix .. "/" .. core, prefix .. "/" .. base, install
end

local function sysconfig_show(conf)
end

local function userconfig_show(conf)
end


local tmanconf = find_tmanconf("sys.conf")
local fenv = find_tmanconf("env.list")

if not tmanconf then
    io.stderr:write("tman: sys.conf: system tmanconf missing\n")
    os.exit(1)
end
if not fenv then
    io.stderr:write("tman: env.list: env file missing\n")
    os.exit(1)
end

local prefix, install = tmanconf_getvals(tmanconf)

local function tilde_to_home()
    tmanconfig.prefix = string.gsub(prefix, "~", userhome or "")
    tmanconfig.install = string.gsub(install, "~", userhome or "")
end

tilde_to_home()



local function load_tman_structure(fname)
    sysconfig.init(fname)
    local envcurr = sysconfig.get("env")

    -- Tman core structure
    local envbase = tmanconfig.prefix .. "/" .. envcurr .. "/"
    tmanconfig.tmanconf = tmanconf
    tmanconfig.units = envbase .. ".tman/" .. "/units/"
    tmanconfig.taskids = envbase .. ".tman/".. "/ids" -- it's a file

    -- Tman base structure
    tmanconfig.codebase = envbase .. "/codebase/"
    tmanconfig.taskbase = envbase .. "/tasks/"

    tmanconfig.envcurr = envcurr
end

load_tman_structure(tmanconf)


-- User config.
-- Add default value if they're not defined in the config file
tmanconfig.repos = tmanconfig.repos or default_repos
tmanconfig.struct = tmanconfig.struct or default_struct
tmanconfig.branchpatt = tmanconfig.branchpatt or default_branch

-- Get env file.
tmanconfig.fenv = fenv


function tmanconfig.set(key, val)
    sysconfig.set(key, val)

    -- reload env related variables.
    load_tman_structure(tmanconf)
end

function tmanconfig.get(key)
    return sysconfig.get(key)
end

return tmanconfig
