--- Simple database for task IDs.
-- @module db

local db = {}
local idfile = ""
local idregex = "(.*) (.*)"
local idfmt = "%s %s\n"
local ids = {}

--- Check that variable entry's safe to save.
-- @return on success - true
-- @return on failure - false
local function _db_check()
    for _, item in pairs(db) do
        if type(item.id) ~= "string" or type(item.status) ~= "number" then
            return false
        end
    end
    return true
end

--- Load task IDs from database.
-- @return on success - true
-- @return on failure - false
local function _db_load()
    db = {} -- reset database.
    local f = io.open(idfile, "r")

    if not f then
        return false
    end

    for line in f:lines() do
        local id, idstatus = string.match(line, idregex)
        table.insert(db, { id = id, status = tonumber(idstatus) })
    end
    return f:close()
end

--- Init database (load task IDs from the file).
-- @param fname database filename
function ids.init(fname)
    idfile = fname
    _db_load()
end

--- Check that task ID exist in database.
-- @param id task ID to check
-- @return on success - true
-- @return on failure - false
function ids.exist(id)
    for _, item in pairs(db) do
        if item.id == id then
            return true
        end
    end
    return false
end

--- Save task IDs to file.
-- @return on success - true
-- @return on failure - false
function ids.save()
    local f = io.open(idfile, "w")

    if not f then
        return false
    end
    if not _db_check() then
        return false
    end

    for _, item in pairs(db) do
        f:write(idfmt:format(item.id, item.status))
    end
    return f:close()
end

--- Add new task ID into database.
-- @param id taskid task ID
-- @param status task status
-- @return on success - true
-- @return on failure - false
function ids.add(id, status)
    if ids.exist(id) then
        return false
    end
    table.insert(db, { id = id, status = status })
    return true
end

--- Delete task ID from database.
-- @param id task id
-- @return on success - true
-- @return on failure - false
function ids.del(id)
    for i, item in pairs(db) do
        if item.id == id then
            table.remove(db, i)
            return true
        end
    end
    return false
end

--- Get size of database entries.
-- @return size of database entries
function ids.size()
    local size = 0

    for _, _ in pairs(db) do
        size = size + 1
    end
    return size
end

--- Get item from database by task ID.
-- roachme: Seems like no one use it at all.
-- @param id task ID
-- @return on success - {id, status}
-- @return on failure - {}
function ids.get(id)
    for _, item in pairs(db) do
        if item.id == id then
            return { id = item.id, status = item.status }
        end
    end
    return {}
end

--- Get an item from database by index.
-- @param idx task ID index
-- @return on success - {id, status}
-- @return on failure - {}
function ids.getidx(idx)
    local item = db[idx] or {}
    return { id = item.id, status = item.status }
end

--- Set new status to task ID.
-- @param id task ID
-- @param status new task status
-- @return true on success, otherwise false
function ids.set(id, status)
    for _, item in pairs(db) do
        if item.id == id then
            item.status = status
            return true
        end
    end
    return false
end

return ids
