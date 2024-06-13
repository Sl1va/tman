--- Parse config file and provide env for the rest of the code.
-- @module config

local tmanconfig = require("tman_conf")
local utils = require("aux.utils")

-- get tmanconf: base and install

local userhome = os.getenv("HOME")

local function find_tmanconf()
    local confpathes = {
        userhome .. "/" .. ".tman/sys.conf",
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
    io.stderr:write("err: no tmanconf file\n")
    os.exit(1)
end

local core, base, install = tmanconf_getvals(tmanconf)

local default_struct = {
    dirs = {},
    files = {},
}
local default_branch = "TYPE/ID_DESC_DATE"

local function tilde_to_home()
    tmanconfig.base = string.gsub(base, "~", userhome or "")
    tmanconfig.core = string.gsub(core, "~", userhome or "")
    tmanconfig.install = string.gsub(install, "~", userhome or "")
end

tilde_to_home()

-- Add default value if they're not defined in the config file
tmanconfig.struct = tmanconfig.struct or default_struct
tmanconfig.repos = tmanconfig.repos or {}
tmanconfig.branchpatt = tmanconfig.branchpatt or default_branch

-- Tman dir structure
tmanconfig.units = tmanconfig.core .. "/units/"
tmanconfig.taskids = tmanconfig.core .. "/taskids"
-- roachme: do we really need it?
tmanconfig.initfile = tmanconfig.core .. "/tmaninit" -- mark tman dir
tmanconfig.tmanbase = tmanconfig.base -- roachme: should be 'base', not 'tmanbase'

tmanconfig.codebase = tmanconfig.base .. "/codebase/"
tmanconfig.taskbase = tmanconfig.base .. "/tasks/"

return tmanconfig
