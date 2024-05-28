--- Operate on task units in database.
-- Like add, delete, list task IDs and so on.
-- @module TaskID

--[[
TODO:
    1. exist() is duplicated: taskid.lua and db.lua cuz tman.lua uses it
]]


--[[
Private functions:
    _setprev
    _unsetprev
    _setcurr

Public functions:
    list       - list task IDs in database (redicilous implementation?)
    getcurr    - get current task ID value from database
    getprev    - get previous task ID value from database

    swap       - swap current and previous task IDs
    move       - move task ID to new status
    movecurr   - move current task ID to new status, make previous a current ID
    setcurr    - mark new ID as current, mark old current as previous if needed
    unsetcurr  - unset current task (used when task's moved to COMP status)
]]


local taskunit = require("taskunit")
local db = require("aux/db")


local TaskID = {}
TaskID.__index = TaskID
db.init()


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
function TaskID:_unsetprev(taskstatus)
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
function TaskID:_setprev(id)
    self:_unsetprev()
    return db.set(id, status.PREV)
end

--- Set current task ID.
-- @param id task ID
-- @treturn bool true if previous task is set, otherwise false
function TaskID:_setcurr(id)
    self:unsetcurr()
    return db.set(id, status.CURR)
end


--- Private functions: end --


-- Public functions: start --

--- Init class TaskID.
-- @return new object
function TaskID.init()
    local self = setmetatable({}, TaskID)
    self.status = status
    return self
end

--- Add a new task ID.
-- @param id task ID to add to database
-- @treturn bool true on success, otherwise false
function TaskID:add(id)
    local prev = self:getcurr()
    local stat = status.CURR

    if db.add(id, stat) == false then
        return false
    end

    self:_setprev(prev)
    self:_setcurr(id)
    return db.save()
end

--- Delete a task ID.
-- @param id task ID
-- @treturn bool true on success, otherwise false
function TaskID:del(id)
    local prev = self:getprev()
    local curr = self:getcurr()

    if db.del(id) == false then
        return false
    end

    if id == curr then
        self:_unsetprev()
        self:_setcurr(prev)
    elseif id == prev then
        self:_unsetprev()
    end
    return db.save()
end

--- Check that task ID exist.
-- @param id task ID to look up
-- @treturn bool true if task ID exist, otherwise false
function TaskID:exist(id)
    return db.exist(id)
end

--- Get current task ID from database.
-- @return current task ID
-- @return nil if there's no current task ID
function TaskID:getcurr()
    local size =  db.size()

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
function TaskID:getprev()
    local size =  db.size()

    for i = 1, size do
        local unit = db.getidx(i)
        if unit.status == status.PREV then
            return unit.id
        end
    end
    return nil
end

--- Swap current and previous task IDs.
function TaskID:swap()
    local prev = self:getprev()
    local curr = self:getcurr()

    self:_setprev(curr)
    self:_setcurr(prev)
    return db.save()
end

--- Set current task ID.
-- Set previous task ID if needed.
function TaskID:setcurr(id)
    local prev = self:getcurr()

    -- roachme: a lil bit vague check...
    if self:_setcurr(id) == true then
        self:_setprev(prev)
        return db.save()
    end
    return false
end

--- Unset current task ID.
-- Assumes that ID exists in database.
-- @param taskstatus task status to move a current ID to
-- @return true on success, otherwise false
function TaskID:unsetcurr(taskstatus)
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

--- Move task ID to new status.
-- @param id task ID
-- @param _status task new status (default: active)
-- @return true on success, otherwise false
function TaskID:move(id, _status)
    local prev = self:getprev()
    local curr = self:getcurr()
    _status = _status or status.ACTV
    print("taskid:move: _status", _status)

    if id == curr then
        print("id == curr")
        return self:movecurr(_status)
    elseif id == prev then
        print("id == prev")
        self:_unsetprev(_status)
    else
        -- roachme: hadn't tested at all
        print("id == else")
        db.set(id, _status)
    end
end

--- Move current task to new status.
-- Update previous one if needed.
-- @param _status current task new status (default: active)
-- @return true on success, otherwise false
function TaskID:movecurr(_status)
    local prev = self:getprev()
    _status = _status or status.ACTV
    print("movecurr: _status", _status, _status == status.COMP)

    self:_unsetprev(_status)
    self:setcurr(prev)
    return db.save()
end

--- List task IDs.
-- There are 4 statuses: current, previous, active and completed. Default: active
-- @param active list only active task IDs
-- @param completed list only completed task IDs
-- @return count of task IDs
function TaskID:list(active, completed)
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

return TaskID
