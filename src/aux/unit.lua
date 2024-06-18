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
        -- roachme: unit_set() already sets default value.
        -- so no need to check it again here.
        f:write(unitfmt:format(key, val or unit.defval))
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
-- @param key key to get
-- @return on success - return actial value
-- @return on failure - return default value (N/A)
function unit.get(key)
    return units[key]
end

--- Set new value to units.
-- @param key key
-- @param val value
-- @return unit value
function unit.set(key, val)
    units[key] = val or unit.defval
end

return unit
