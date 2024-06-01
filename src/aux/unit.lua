--- Auxilary module for taskunit.lua
-- @module unit

local units = {}
local unitind = 1
local unitfile = ""
local unitkeys = {
    "id",
    "prio",
    "type",
    "desc",
    -- "link",
    -- "linked",

    "time",
    "date",
    "status",
    "branch",
}

local unitprios = {
    highest = "highest",
    high = "high",
    mid = "mid",
    low = "low",
    lowest = "lowest",
}

local function unit_load()
    local f = io.open(unitfile)

    -- reset
    units = {}
    unitind = 1

    if not f then
        return false
    end

    for line in f:lines() do
        local key, val = string.match(line, "(.*): (.*)")
        key = string.lower(key)
        units[key] = { val = val, ind = unitind }
        unitind = unitind + 1
    end

    -- reset index
    unitind = 1
    return f:close()
end

local function unit_save()
    local f = io.open(unitfile, "w")

    if not f then
        return false
    end

    for key, value in pairs(units) do
        f:write(key, ": ", value.val, "\n")
    end
    f:close()
    return true
end

--- Init task unit database.
-- @param fname task ID filename
local function unit_init(fname)
    unitfile = fname
    unit_load()
end

local function unit_get(key)
    return units[key].val
end

--- Set new value to units.
-- @param key key
-- @param val value
local function unit_set(key, val)
    units[key] = { val = val, ind = unitind }
    unitind = unitind + 1
end

local function unit_size()
    local size = 0

    for _, _ in pairs(units) do
        size = size + 1
    end
    return size
end

return {
    keys = unitkeys,
    prios = unitprios,

    init = unit_init,
    save = unit_save,
    get = unit_get,
    set = unit_set,
    size = unit_size,
}
