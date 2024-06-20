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

-- get tmanconf: base and install

local userhome = os.getenv("HOME")
local default_repos = {}
local default_branch = "TYPE/ID_DESC_DATE"
local default_struct = {
    dirs = {},
    files = {},
}

local function find_tmanconf()
    local confpathes = {
        userhome .. "/" .. ".tman/sys.conf",
        userhome .. "/" .. ".config/tman/sys.conf",
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
    local core, base, install
    local f = io.open(fname)

    if not f then
        os.exit(1)
    end

    -- parse vars
    for line in f:lines() do
        local mark = string.match(line, "([a-z]*)")
        if mark == "base" then
            base = string.match(line, ".*%s=%s(.*)")
            base = remove_quotes(base)
        elseif mark == "install" then
            install = string.match(line, ".*%s=%s(.*)")
            install = remove_quotes(install)
        elseif mark == "core" then
            core = string.match(line, ".*%s=%s(.*)")
            core = remove_quotes(core)
        end
    end

    f:close()
    return core, base, install
end

local tmanconf = find_tmanconf()
if not tmanconf then
    io.stderr:write("tman: sys.conf: system tmanconf missing\n")
    os.exit(1)
end

local core, base, install = tmanconf_getvals(tmanconf)

local function tilde_to_home()
    tmanconfig.base = string.gsub(base, "~", userhome or "")
    tmanconfig.core = string.gsub(core, "~", userhome or "")
    tmanconfig.install = string.gsub(install, "~", userhome or "")
end

tilde_to_home()

-- Tman core structure
tmanconfig.tmanconf = tmanconf
tmanconfig.units = tmanconfig.core .. "/units/"
tmanconfig.taskids = tmanconfig.core .. "/ids" -- it's a file

-- Tman base structure
tmanconfig.tmanbase = tmanconfig.base
tmanconfig.codebase = tmanconfig.base .. "/codebase/"
tmanconfig.taskbase = tmanconfig.base .. "/tasks/"

-- User config.
-- Add default value if they're not defined in the config file
tmanconfig.repos = tmanconfig.repos or default_repos
tmanconfig.struct = tmanconfig.struct or default_struct
tmanconfig.branchpatt = tmanconfig.branchpatt or default_branch

return tmanconfig
