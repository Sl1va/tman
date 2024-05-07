local globals = require("globals")


--[[

List of DB commands:
Private:
    _sort
    _exist
    _load
    _save

Public:
    add
    del

    get
    set
    size
    getunit
    getidx
    setidx
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
local meta = globals.taskids


-- Private functions: start --

--- Sort task IDs in database.
local function _db_sort()
    table.sort(taskids, function(a, b)
        return a.status < b.status
    end)
end

--- Check that task ID exist in database.
-- @param task ID to check
local function _db_exist(id)
    for _, unit in pairs(taskids) do
        if unit.id == id then
            return true
        end
    end
    return false
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

--- Save task IDs to file.
local function _db_save()
    local f = io.open(meta, "w")

    if not f then
        return false
    end

    _db_sort() -- sort task IDs according to their statuses
    for _, unit in pairs(taskids) do
        f:write(unit.id, " ", unit.status, "\n")
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

--- Add new task ID into database.
-- @param taskid task ID
-- @param taskstatus task status
local function db_add(taskid, taskstatus)
    if _db_exist(taskid) then
        return false
    end
    table.insert(taskids, { id = taskid, status = taskstatus })
    _db_save()
    return true
end

--- Delete task ID from database.
-- @param id task id
local function db_del(id)
    for i, unit in pairs(taskids) do
        if unit.id == id then
            table.remove(taskids, i)
            _db_save()
            return true
        end
    end
    return false
end

--- Get size of units in database.
-- @return number of units in database
local function db_size()
    local size = 0

    for _, _ in pairs(taskids) do
        size = size + 1
    end
    return size
end

--- Get task ID from database.
-- @param id task ID
-- @return task ID
local function db_get(id)
    for _, unit in pairs(taskids) do
        if unit.id == id then
            return unit.id
        end
    end
    return nil
end

--- Get a unit from database.
-- @param idx task ID index
-- @tparam table {id, status}
local function db_getunit(idx)
    local unit = taskids[idx]

    if unit ~= nil then
        return { id = unit.id, status = unit.status }
    end
    return {}
end

--- Get task ID from database by index
-- @param idx task ID index
local function db_getidx(idx)
    local unit = taskids[idx]

    if unit ~= nil then
        return unit.id
    end
    return nil
end

--- Set new status to task ID.
-- @param id task ID
-- @param new task status
-- @param return true on success, otherwise false
local function db_set(id, _status)
    for _, unit in pairs(taskids) do
        if unit.id == id then
            unit.status = _status
            return true
        end
    end
    return false
end

--- Set new status to task ID by its index.
-- @param idx task ID index
-- @param new task status
-- @param return true on success, otherwise false
local function db_setidx(idx, _status)
    local unit = taskids[idx]

    if unit and unit.idx == idx then
        unit.status = _status
        return true
    end
    return false
end

-- Public functions: end --

return {
    init = db_init,
    add = db_add,
    del = db_del,
    get = db_get,
    set = db_set,
    size = db_size,
    getidx = db_getidx,
    setidx = db_setidx,
    getunit = db_getunit,
}
