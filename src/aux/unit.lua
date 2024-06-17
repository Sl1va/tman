--- Auxilary module for taskunit.lua
-- @module unit

local units = {}
local defval = "N/A"
local unitfile = ""
local unitregex = "(.*): (.*)"
local unitfmt = "%s: %s\n"
local unitkeys = {
    "id",
    "prio",
    "type",
    "desc",
    "time",
    "date",
    "link",
    "repos",
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
local function _unit_load()
    units = {}
    local f = io.open(unitfile)

    if not f then
        return false
    end

    for line in f:lines() do
        local key, val = string.match(line, unitregex)
        -- for backward compatibily: old task has capitalized keys
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
        -- roachme: unit_set() already sets default value.
        -- so no need to check it again here.
        f:write(unitfmt:format(key, val or defval))
    end
    return f:close()
end

--- Init task unit database.
-- @param fname task ID filename
local function unit_init(fname)
    unitfile = fname
    _unit_load()
end

--- Get unit from unit file.
-- @param key key to get
-- @return on success - return actial value
-- @return on failure - return default value (N/A)
local function unit_get(key)
    return units[key]
end

--- Set new value to units.
-- @param key key
-- @param val value
-- @return unit value
local function unit_set(key, val)
    units[key] = val or defval
end

return {
    keys = unitkeys,
    prios = unitprios,
    defval = defval,

    get = unit_get,
    set = unit_set,
    init = unit_init,
    save = unit_save,
}
