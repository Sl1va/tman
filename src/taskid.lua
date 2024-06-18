--- Operate on task units in database.
-- Like add, delete, list task IDs and so on.
-- @module TaskID

local taskunit = require("taskunit")
local config = require("misc.config")
local db = require("aux.db")

--- Types of task IDs.
local status = {
    CURR = 0, -- current task
    PREV = 1, -- previous task
    ACTV = 2, -- active task
    COMP = 3, -- complete task
}

-- Private functions: start --

--- Get special task ID by status.
-- @param taskstatus special task ID's status
-- @return on success - task ID
-- @return on failure - nil
local function _getspec(taskstatus)
    local size = db.size()

    for i = 1, size do
        local entry = db.getidx(i)
        if entry.status == taskstatus then
            return entry.id
        end
    end
    return nil
end

--- Unset previous task ID.
-- Assumes that ID exists in database.
-- @param taskstatus task status to move a previous ID to
-- @return true on success, otherwise false
local function unsetprev(taskstatus)
    local size = db.size()
    taskstatus = taskstatus or status.ACTV

    for i = 1, size do
        local entry = db.getidx(i)
        if entry.status == status.PREV then
            return db.set(entry.id, taskstatus)
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
        local entry = db.getidx(i)
        if entry.status == status.CURR then
            return db.set(entry.id, taskstatus)
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

--- Check that task ID exist.
-- @param id task ID to look up
-- @treturn bool true if task ID exist, otherwise false
local function taskid_exist(id)
    return db.exist(id)
end

--- Get previous task ID from database.
-- @return previous task ID
-- @return on success - previous task ID
-- @return on failure - nil
local function taskid_getprev()
    return _getspec(status.PREV)
end

--- Get current task ID from database.
-- @return current task ID
-- @return on success - current task ID
-- @return on failure - nil
local function taskid_getcurr()
    return _getspec(status.CURR)
end

--- Swap current and previous task IDs.
local function taskid_swap()
    local prev = taskid_getprev()
    local curr = taskid_getcurr()

    setprev(curr)
    setcurr(prev)
    return db.save()
end

--- Add a new task ID.
-- @param id task ID to add to database
-- @treturn bool true on success, otherwise false
local function taskid_add(id)
    -- roacme: Don't make it current.
    --         Add it to database with status: ACTV
    --         There's setcurr() for it.
    local curr = taskid_getcurr()

    if db.add(id, status.CURR) == false then
        return false
    end

    setprev(curr)
    setcurr(id)
    return db.save()
end

--- Delete a task ID.
-- @param id task ID
-- @treturn bool true on success, otherwise false
local function taskid_del(id)
    local curr = taskid_getcurr()

    if not taskid_exist(id) then
        return false
    end

    db.del(id)
    if id == curr then
        return taskid_swap()
    end
    return db.save()
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

--- Move current task to completed status.
local function taskid_unsetcurr()
    unsetcurr(status.COMP)
    return taskid_swap()
end

--- Set task ID as current.
-- Set previous task ID if needed.
local function taskid_setcurr(id)
    local curr = taskid_getcurr()

    -- don't do unnecessary work.
    if not id or id == curr then
        return false
    end
    setcurr(id)
    setprev(curr)
    return db.save()
end

--- List task IDs.
-- There are 4 statuses: current, previous, active and completed. Default: active
-- @param active list only active task IDs
-- @param completed list only completed task IDs
-- @return count of task IDs
local function taskid_list(active, completed)
    local desc
    local size = db.size()
    local curr = taskid_getcurr()
    local prev = taskid_getprev()

    if active and curr then
        desc = taskunit.get(curr, "desc")
        print(("* %-10s %s"):format(curr, desc))
    end
    if active and prev then
        desc = taskunit.get(prev, "desc")
        print(("- %-10s %s"):format(prev, desc))
    end

    for idx = 1, size do
        local entry = db.getidx(idx)
        if entry.id ~= curr and entry.id ~= prev then
            if entry.status == status.ACTV and active then
                desc = taskunit.get(entry.id, "desc")
                print(("  %-10s %s"):format(entry.id, desc))
            elseif entry.status == status.COMP and completed then
                desc = taskunit.get(entry.id, "desc")
                print(("  %-10s %s"):format(entry.id, desc))
            end
        end
    end
    return size
end

-- Public functions: end --

db.init(config.taskids)

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

    -- roachme: seems like no one uses this API command.
    -- but `tman done' command will use it.
    unsetcurr = taskid_unsetcurr,

    -- roachme: under development & tests
    move = taskid_move,
}
