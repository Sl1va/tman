--- Simple database for task IDs.
-- @module db

local taskids = {}
local idfile = ""
local idregex = "(.*) (.*)"
local idfmt = "%s %s\n"

-- Private functions: start --

--- Sort task IDs in database.
local function _db_sort()
    table.sort(taskids, function(a, b)
        return a.status < b.status
    end)
end

--- Check that variable `taskids` is safe to save.
-- @return true `taskids` ok, otherwise false
local function _db_check()
    for _, unit in pairs(taskids) do
        if unit.id == nil or unit.status == nil then
            return false
        end
    end
    return true
end

--- Load task IDs from database.
-- @return on success - true
-- @return on failure - false
local function _db_load()
    local f = io.open(idfile, "r")

    if not f then
        return false
    end

    for line in f:lines() do
        local id, idstatus = string.match(line, idregex)
        table.insert(taskids, { id = id, status = tonumber(idstatus) })
    end
    f:close()
    return true
end

-- Private functions: end --

-- Public functions: start ---

--- Init database (load task IDs from the file).
-- @param fname filename
local function db_init(fname)
    idfile = fname
    _db_load()
end

--- Check that task ID exist in database.
-- @param id task ID to check
-- @return on success - true
-- @return on failure - false
local function db_exist(id)
    for _, unit in pairs(taskids) do
        if unit.id == id then
            return true
        end
    end
    return false
end

--- Save task IDs to file.
-- @return on success - true
-- @return on failure - false
local function db_save()
    local f = io.open(idfile, "w")

    if not f then
        return false
    end
    if not _db_check() then
        return false
    end

    _db_sort() -- sort task IDs according to their statuses
    for _, unit in pairs(taskids) do
        f:write(idfmt:format(unit.id, unit.status))
    end
    f:close()
    return true
end

--- Add new task ID into database.
-- @param id taskid task ID
-- @param status task status
-- @return on success - true
-- @return on failure - false
local function db_add(id, status)
    if db_exist(id) then
        return false
    end
    table.insert(taskids, { id = id, status = status })
    return true
end

--- Delete task ID from database.
-- @param id task id
-- @return on success - true
-- @return on failure - false
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

    -- roachme: others can use db.get(id) instead of db.exist
    --          Maybe it's better to delete db.exist() from the API?
    exist = db_exist,

    add = db_add,
    del = db_del,
    save = db_save,

    set = db_set,
    get = db_get,
    getidx = db_getidx,
}
