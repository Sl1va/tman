--- Module to edit and manipulate environment.
-- @module env

local config = require("misc.config")
local sysconfig = require("misc.sysconfig")
local envdb = require("aux.envdb")

local env = {}

-- Hold current and previous env names to minimize lookup.
local curr, prev

local status = {
    CURR = 0,
    PREV = 1,
    OTHER = 2, -- roachme: rename it.
}

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

function env.add(name, desc)
    if envdb.exists(name) then
        return false
    end

    -- update curr and prev env names.
    prev = curr
    curr = name
    return envdb.add(name, desc)
end

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

function env.swap()
    local tmpprev = prev

    prev = curr
    curr = tmpprev

    -- roachme:BUG: gotta unset old prev.
    envdb.set(prev, status.PREV)
    envdb.set(curr, status.CURR)
    return true
end

function env.del(name)
    if not envdb.exists(name) then
        return false
    end

    if name == curr then
        prev = curr
    end
end

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
envdb.init(config.fenv)
load_spec_envs()


return env
