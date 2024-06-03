--- Auxilary module for taskunit.lua
-- @module unit

local units = {}
local unitfile = ""
local unitkeys = {
    "id",
    "prio",
    "type",
    "desc",

    -- under development
    "link",
    "linked",
    -- under development

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

--- Load task units from the file.
-- @return on success - true
-- @return on failure - false
local function unit_load()
    units = {}
    local f = io.open(unitfile)

    if not f then
        return false
    end

    for line in f:lines() do
        local key, val = string.match(line, "(.*): (.*)")
        key = string.lower(key)
        units[key] = val
    end
    return f:close()
end

--- Save task units into the file.
-- @return on success - true
-- @return on failure - false
local function unit_save()
    local f = io.open(unitfile, "w")

    if not f then
        return false
    end

    for key, val in pairs(units) do
        f:write(key, ": ", val, "\n")
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

--- Get unit from unit file.
-- @param key key to get
-- @return value
local function unit_get(key)
    return units[key]
end

--- Set new value to units.
-- @param key key
-- @param val value
-- @return unit value
local function unit_set(key, val)
    units[key] = val
end

--- Get size of unit file.
-- @return size of unit file
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
