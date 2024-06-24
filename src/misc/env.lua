--- Module to edit and manipulate environment.
-- @module env

local envdb = require("aux.envdb")
local utils = require("aux.utils")

local env = {}

-- Hold current and previous env names to minimize lookup.
local curr, prev

local status = {
    CURR = 0,
    PREV = 1,
    OTHER = 2, -- roachme: rename it.
}


local function unset(name)
    envdb.set(name, status.OTHER)
end

--[[
local function update_config(name)
    sysconfig.set("base", name)
    sysconfig.set("core", name .. "/.tman")

    local base = sysconfig.get("base")
    local core = sysconfig.get("core")
    print("env: sysconfig: base", base)
    print("env: sysconfig: core", core)
end
]]

local function load_spec_envs()
    for i = 1, envdb.size() do
        local item = envdb.getix(i)
        if item.status == status.CURR then
            curr = item.name
        elseif item.status == status.PREV then
            prev = item.name
        end
    end
end

function env.exists(name)
    return envdb.exists(name)
end

function env.swap()
    local tmpprev = prev

    prev = curr
    curr = tmpprev

    -- roachme:BUG: gotta unset old prev.
    unset(prev)
    unset(curr)

    -- roachme: it save into file.
    -- Gotta change that logic to minimize writing into file.
    envdb.set(prev, status.PREV)
    envdb.set(curr, status.CURR)
    return true
end

--[[
function env.add(name, desc)
    if envdb.exists(name) then
        return false
    end

    env.swap()
    envdb.add(name, desc)
    update_config(name)

    -- create env dir
    local prefix = sysconfig.get("prefix")
    local base = sysconfig.get("base")
    local envdir = prefix .. "/" .. base

    print("env: envdir", envdir)
    utils.mkdir(envdir)
    utils.mkdir(envdir .. "/.tman")

    -- roachme: doesn't work for some reason
    print("env: init env structure")
    return core.init()
end
]]

function env.get(name)
end

function env.getcurr()
    return curr
end

function env.getprev()
    return prev
end

function env.set(name, status)
end

function env.list()
    if curr then
        local item = envdb.get(curr)
        print(("* %-10s %s"):format(item.name, item.desc))
    end
    if prev then
        local item = envdb.get(prev)
        print(("- %-10s %s"):format(item.name, item.desc))
    end

    for i = 1, envdb.size() do
        local item = envdb.getix(i)
        -- skip special env names (prev & curr)
        if item.name ~= curr and item.name ~= prev then
            print(("  %-10s %s"):format(item.name, item.desc))
        end
    end
    return true
end

--[[
function env.del(name)
    if not envdb.exists(name) then
        return false
    end

    -- delete env dir
    print("env: del: env", name)
    local prefix = sysconfig.get("prefix")
    local base = sysconfig.get("base")
    local envdir = prefix .. "/" .. base
    utils.rm(envdir)

    envdb.del(name)
    if name == curr then
        env.swap()
    end

    -- roachme: might be a problem if the only env's deleted
    print("env: del: newcurr", curr)
    update_config(curr)

    return true
end
]]

--[[
function env.setcurr(name)
    if not envdb.exists(name) then
        return false
    end

    prev = curr
    curr = name

    envdb.set(prev, status.PREV)
    envdb.set(curr, status.CURR)

    -- update sys.conf
    sysconfig.set("base", name)
    sysconfig.set("core", name .. "/.tman")

    -- update current & previous task IDs
    return true
end

sysconfig.init(config.tmanconf)
]]

function env.init(fenv)
    envdb.init(fenv)
    load_spec_envs()
end

return env
