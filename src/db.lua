--- Simple database for task IDs.
-- @module db

local config = require("config")

--[[

Qs:
    1. Should db or user save data into file?
]]

--[[
TODO:
    1. Check taskids before saving 'em into the file. Thus to prevent data lost.
]]

--[[

List of DB commands:
Private:
    _db_load    - load task units from database
    _db_sort    - sort task units in database
    _db_exist   - check that task ID exist in database
    _db_check   - check `taskids` content is safe to save

Public:
    init        - init database
    add         - add a new task ID to database
    del         - del a task ID from database
    save        - save task units into database
    size        - get size of taks units in database

    get         - get task unit from database (by task ID)
    set         - set status to task unit
    getixd      - get task unit from database (by task ID index)
]]

--[[
taskid file structure:
    'TaskID Status'

    TaskID - task ID name
    Status - task status: 0, 1, 2, 3

    0 - Current
    1 - Previous
    2 - kkActive
    3 - Complete
]]


local taskids = {}
local meta = config.taskids


-- Private functions: start --

--- Sort task IDs in database.
local function _db_sort()
    table.sort(taskids, function(a, b)
        return a.status < b.status
    end)
end

--- Check that variable `taskids` is safe to save.
--TODO: use it in code
-- @return true `taskids` ok, otherwise false
local function _db_check()
    for _, unit in pairs(taskids) do
        if unit.id == nil or unit.status == nil then
            return false
        end
    end
    return true
end

--- Load task IDs from file.
local function _db_load()
    local f = io.open(meta, "r")

    if not f then
        return false
    end

    for line in f:lines() do
        local id, idstatus = string.match(line, "(.*) (.*)")
        table.insert(taskids, { id = id, status = tonumber(idstatus) })
    end
    f:close()
    return true
end

-- Private functions: end --


-- Public functions: start ---

--- Init database.
local function db_init(ftaskids)
    meta = ftaskids or meta
    _db_load()
end

--- Check that task ID exist in database.
-- @param id task ID to check
local function db_exist(id)
    for _, unit in pairs(taskids) do
        if unit.id == id then
            return true
        end
    end
    return false
end

--- Save task IDs to file.
local function db_save()
    local f = io.open(meta, "w")

    if not f then
        return false
    end
    if not _db_check() then
        return false
    end

    _db_sort() -- sort task IDs according to their statuses
    for _, unit in pairs(taskids) do
        f:write(unit.id, " ", unit.status, "\n")
    end
    f:close()
    return true
end

--- Add new task ID into database.
-- @param id taskid task ID
-- @param status task status
local function db_add(id, status)
    if db_exist(id) then
        return false
    end
    table.insert(taskids, { id = id, status = status })
    return true
end

--- Delete task ID from database.
-- @param id task id
local function db_del(id)
    for i, unit in pairs(taskids) do
        if unit.id == id then
            table.remove(taskids, i)
            return true
        end
    end
    return false
end

--- Get size database units.
-- @return number of units in database
local function db_size()
    local size = 0

    for _, _ in pairs(taskids) do
        size = size + 1
    end
    return size
end

--- Get unit from database by task ID.
-- @param id task ID
-- @return task ID unit
-- @return table {id, status}
-- @return empty table if task ID doesn't exist
local function db_get(id)
    for _, unit in pairs(taskids) do
        if unit.id == id then
            return { id = unit.id, status = unit.status }
        end
    end
    return {}
end

--- Get a unit from database by task ID index.
-- @param idx task ID index
-- @return table {id, status}
-- @return empty table if task ID doesn't exist
local function db_getidx(idx)
    local unit = taskids[idx]

    if unit ~= nil then
        return { id = unit.id, status = unit.status }
    end
    return {}
end

--- Set new status to task ID.
-- @param id task ID
-- @param status new task status
-- @return true on success, otherwise false
local function db_set(id, status)
    for _, unit in pairs(taskids) do
        if unit.id == id then
            unit.status = status
            return true
        end
    end
    return false
end

-- Public functions: end --

return {
    init = db_init,
    size = db_size,
    exist = db_exist,

    add = db_add,
    del = db_del,
    save = db_save,

    set = db_set,
    get = db_get,
    getidx = db_getidx,
}
