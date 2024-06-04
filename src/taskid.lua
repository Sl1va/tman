--- Operate on task units in database.
-- Like add, delete, list task IDs and so on.
-- @module TaskID

local taskunit = require("taskunit")
local db = require("aux.db")

--- Types of task IDs.
local status = {
    CURR = 0, -- current task
    PREV = 1, -- previous task
    ACTV = 2, -- active task
    COMP = 3, -- complete task
}

-- Private functions: start --

--- Class TaskID
-- @type TaskID

--- Unset previous task ID.
-- Assumes that ID exists in database.
-- @param taskstatus task status to move a previous ID to
-- @return true on success, otherwise false
local function unsetprev(taskstatus)
    local size = db.size()
    taskstatus = taskstatus or status.ACTV

    for i = 1, size do
        local unit = db.getidx(i)
        if unit.status == status.PREV then
            return db.set(unit.id, taskstatus)
        end
    end
    return false
end

--- Set previous task ID.
-- Unset old previous task ID.
-- @param id task ID
-- @treturn bool true if previous task is set, otherwise false
local function setprev(id)
    unsetprev()
    return db.set(id, status.PREV)
end

--- Unset current task ID.
-- Assumes that ID exists in database.
-- @param taskstatus task status to move a current ID to
-- @return true on success, otherwise false
local function unsetcurr(taskstatus)
    local size = db.size()
    taskstatus = taskstatus or status.ACTV

    for i = 1, size do
        local unit = db.getidx(i)
        if unit.status == status.CURR then
            return db.set(unit.id, taskstatus)
        end
    end
    return false
end

--- Set current task ID.
-- @param id task ID
-- @treturn bool true if previous task is set, otherwise false
local function setcurr(id)
    unsetcurr()
    return db.set(id, status.CURR)
end

-- Private functions: end --

-- Public functions: start --

--- Get current task ID from database.
-- @return current task ID
-- @return nil if there's no current task ID
local function taskid_getcurr()
    local size = db.size()

    for i = 1, size do
        local unit = db.getidx(i)
        if unit.status == status.CURR then
            return unit.id
        end
    end
    return nil
end

--- Get previous task ID from database.
-- @return previous task ID
-- @return nil if there's no previous task ID
local function taskid_getprev()
    local size = db.size()

    for i = 1, size do
        local unit = db.getidx(i)
        if unit.status == status.PREV then
            return unit.id
        end
    end
    return nil
end

--- Add a new task ID.
-- @param id task ID to add to database
-- @treturn bool true on success, otherwise false
local function taskid_add(id)
    local prev = taskid_getcurr()

    if db.add(id, status.CURR) == false then
        return false
    end

    setprev(prev)
    setcurr(id)
    return db.save()
end

--- Delete a task ID.
-- @param id task ID
-- @treturn bool true on success, otherwise false
local function taskid_del(id)
    local prev = taskid_getprev()
    local curr = taskid_getcurr()

    if db.del(id) == false then
        return false
    end

    -- update special task IDs
    if id == curr then
        unsetprev()
        setcurr(prev)
    elseif id == prev then
        unsetprev()
    end

    return db.save()
end

--- Check that task ID exist.
-- @param id task ID to look up
-- @treturn bool true if task ID exist, otherwise false
local function taskid_exist(id)
    return db.exist(id)
end

--- Swap current and previous task IDs.
local function taskid_swap()
    local prev = taskid_getprev()
    local curr = taskid_getcurr()

    setprev(curr)
    setcurr(prev)
    return db.save()
end

--- Set current task ID.
-- Set previous task ID if needed.
-- roachme: NO clue what's goin' on.
local function taskid_setcurr(id)
    local prev = taskid_getcurr()

    -- roachme: a lil bit vague check...
    if setcurr(id) == true then
        setprev(prev)
        return db.save()
    end
    return false
end

--- Unset current task ID.
-- @see unsetcurr
local function taskid_unsetcurr(taskstatus)
    return unsetcurr(taskstatus)
end

--- Move task ID to new status.
-- roachme: Under development.
-- @param taskid task ID
-- @param taskstatus task new status (default: active)
-- @return true on success, otherwise false
local function taskid_move(taskid, taskstatus)
    local prev = taskid_getprev()
    local curr = taskid_getcurr()

    if taskid == curr then
        unsetprev(status.ACTV)
        db.set(prev, status.CURR)
        db.set(curr, taskstatus)
    elseif taskid == prev then
        db.set(prev, status.COMP)
    else
        db.set(taskid, taskstatus)
    end

    return db.save()
end

--- List task IDs.
-- There are 4 statuses: current, previous, active and completed. Default: active
-- @param active list only active task IDs
-- @param completed list only completed task IDs
-- @return count of task IDs
local function taskid_list(active, completed)
    local size = db.size()

    for idx = 1, size do
        local unit = db.getidx(idx)
        if unit.status == status.CURR and active then
            local desc = taskunit.getunit(unit.id, "desc")
            print(("* %-10s %s"):format(unit.id, desc))
        elseif unit.status == status.PREV and active then
            local desc = taskunit.getunit(unit.id, "desc")
            print(("- %-10s %s"):format(unit.id, desc))
        elseif unit.status == status.ACTV and active then
            local desc = taskunit.getunit(unit.id, "desc")
            print(("  %-10s %s"):format(unit.id, desc))
        elseif unit.status == status.COMP and completed then
            local desc = taskunit.getunit(unit.id, "desc")
            print(("  %-10s %s"):format(unit.id, desc))
        end
    end
    return size
end

-- Public functions: end --

db.init()

return {
    -- roachme: should it be public?
    status = status,

    add = taskid_add,
    del = taskid_del,
    swap = taskid_swap,
    list = taskid_list,
    exist = taskid_exist,
    getcurr = taskid_getcurr,
    getprev = taskid_getprev,
    setcurr = taskid_setcurr,
    unsetcurr = taskid_unsetcurr,

    -- roachme: under development & tests
    move = taskid_move,
}
