--- Auxilary module for taskunit.lua
-- @module unit

local unit = {}
local units = {}
local unitfile = ""
local unitregex = "(.*): (.*)"
local unitfmt = "%s: %s\n"

unit.defval = "N/A"
unit.keys = {
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
unit.prios = {
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
        units[key] = val
    end
    return f:close()
end

--- Save task units into the file.
-- @return on success - true
-- @return on failure - false
function unit.save()
    local f = io.open(unitfile, "w")

    if not f then
        return false
    end

    for key, val in pairs(units) do
        f:write(unitfmt:format(key, val))
    end
    return f:close()
end

--- Init task unit database.
-- @param fname task ID filename
function unit.init(fname)
    unitfile = fname
    _unit_load()
end

--- Get unit from unit file.
-- If no such key, return nil (as does Lua table).
-- @param key key
-- @return on success - value
-- @return on failure - nil
function unit.get(key)
    return units[key]
end

--- Set new value into units.
-- If no value's passed, set default value - `N/A'.
-- @param key key
-- @param val value
function unit.set(key, val)
    units[key] = val or unit.defval
end

return unit
