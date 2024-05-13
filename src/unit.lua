--- Core thingy for taskunit.lua.
-- Status: under development.
-- @module unit


local config = require("config")

local unitregex = "(%w*): (.*)"

local unit_keys = {
    "id",
    "prio",
    "type",
    "desc",

    "time",
    "date",
    "status",
    "branch",
}


--[[

check:
    tasktype
    unit file
    unit key
    unit priority

]]


local function check_unit_file()
end

--- Check that user specified task type exists.
-- @tparam string utype user specified type
-- @treturn bool true if exists, otherwise false
local function unit_check_type(utype)
    local tasktypes = { "bugfix", "feature", "hotfix" }

    for _, _type in pairs(tasktypes) do
        if utype == _type then
            return true
        end
    end
    return false
end

local function unit_check_key(key)
end

local function unit_check_prio()
end

--- Get task units.
-- @param id task ID
-- @treturn table task units {{key, value}, ...}
local function unit_load(id)
    local taskunits = {}
    local fname = config.tmanbase .. id
    local f = io.open(fname)
    local i = 1

    if not f then
        return {}
    end
    for line in f:lines() do
        local ukey, uval = string.match(line, unitregex)
        taskunits[unit_keys[i]] = { key = string.lower(ukey), value = uval }
        i = i + 1
    end
    f:close()
    return taskunits
end

--- Save task units into file.
-- @param id task ID
-- @param taskunits task units to save
-- @return true on success, otherwise false
local function unit_save(id, taskunits)
    local i = 1
    local fname = config.tmanbase .. id
    local f = io.open(fname, "w")

    if not f then
        return false
    end

    for _, _ in pairs(unit_keys) do
        local unit = taskunits[unit_keys[i]]
        f:write(("%s: %s\n"):format(unit.key, unit.value))
        i = i + 1
    end
    return f:close()
end

--- Get unit from task metadata.
-- @param id task ID
-- @param key unit key
-- @return unit value
-- @return nil if key doesn't exist
local function unit_getunit(id, key)
    local taskunits = unit_load(id)

    if not next(taskunits) or not unit_check_key(key) then
        return nil
    end
    return taskunits[key].value
end

return {
    load = unit_load,
    save = unit_save,

    check_key = unit_check_key,
    check_type = unit_check_type,
    check_prio = unit_check_prio,

    getunit = unit_getunit,
}
