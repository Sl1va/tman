--- Operate on task units in database.
-- Like add, delete, list task IDs and so on.
-- @module TaskID

--[[
Private functions:
    _load_taskids
    _save_taskids
    _add_new_taskid
    _setprev
    _unsetprev
    _setcurr

Public functions:
    add        - add a new task ID to database
    del        - del a task ID from database
    exist      - check that task ID exist in database

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
local globals = require("globals")
local log = require("log")
local db = require("db")


local TaskID = {}
TaskID.__index = TaskID
taskunit = taskunit.init()
log = log.init("taskid")
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

--- Load task iDs from the file.
-- @treturn table table like {id, idstatus}
function TaskID:_load_taskids()
    local taskids = {}
    local f = io.open(self.meta)

    if not f then
        log:err("couldn't open file '%s'", self.meta)
        return taskids
    end
    for line in f:lines() do
        local id, idstatus = string.match(line, "(.*) (.*)")
        table.insert(taskids, { id = id, status = tonumber(idstatus) })
    end
    f:close()
    return taskids
end

--- Save task IDs to the file.
function TaskID:_save_taskids()
    local f = io.open(self.meta, "w")

    if not f then
        log:err("couldn't open meta file")
        return false
    end

    table.sort(self.taskids, function(a, b)
        return a.status < b.status
    end)
    for _, unit in pairs(self.taskids) do
        f:write(unit.id, " ", unit.status, "\n")
    end
    return f:close()
end

--- Unset previous task ID.
-- Assumes that ID exists in database.
-- @param id task ID
-- @param taskstatus task status to move a previous ID to
-- @return true on success, otherwise false
function TaskID:_unsetprev(taskstatus)
    local idxprev = 2
    local curr = self.taskids[idxprev]
    taskstatus = taskstatus or status.ACTV

    if curr and curr.status == status.PREV then
        curr.status = taskstatus
    end
    return true
end

--- Set previous task ID.
-- Unset old previous task ID.
-- @param id task ID
-- @treturn bool true if previous task is set, otherwise false
function TaskID:_setprev(id)
    self:_unsetprev()
    for _, unit in pairs(self.taskids) do
        if unit.id == id then
            unit.status = status.PREV
            return true
        end
    end
    return false
end

--- Set current task ID.
-- @param id task ID
-- @treturn bool true if previous task is set, otherwise false
function TaskID:_setcurr(id)
    self:unsetcurr()
    for _, unit in pairs(self.taskids) do
        if unit.id == id then
            unit.status = status.CURR
            return true
        end
    end
    return false
end

--- Private functions: end --


-- Public functions: start --

--- Init class TaskID.
-- @return new object
function TaskID.init()
    local self = setmetatable({}, TaskID)
    self.meta = globals.tmandb .. "taskids"
    self.taskids = self:_load_taskids()
    self.status = status
    return self
end

function TaskID:_add_new_taskid(id, _status)
    table.insert(self.taskids, { id = id, status = _status })
    table.sort(self.taskids, function(a, b)
        return a.status < b.status
    end)
end

--- Add a new task ID.
-- @param id task ID to add to database
-- @treturn bool true on success, otherwise false
function TaskID:add(id)
    local prev = self:getcurr()
    local idxcurr = 1

    if self:exist(id) then
        return false
    end

    -- roachme: find a better way to write this piece of code
    self.taskids[idxcurr].status = status.ACTV
    table.insert(self.taskids, { id = id, status = status.CURR })
    table.sort(self.taskids, function(a, b)
        return a.status < b.status
    end)

    self:_setprev(prev)
    self:_setcurr(id)
    return self:_save_taskids()
end

--- Delete a task ID.
-- @param id task ID
-- @treturn bool true on success, otherwise false
function TaskID:del(id)
    local prev = self:getprev()

    if not self:exist(id) then
        return false
    end
    for i, unit in pairs(self.taskids) do
        if unit.id == id then
            table.remove(self.taskids, i)
        end
    end
    self:_unsetprev()
    self:_setcurr(prev)
    return self:_save_taskids()
end

--- Check that task ID exist.
-- @param id task ID to look up
-- @treturn bool true if task ID exist, otherwise false
function TaskID:exist(id)
    for _, unit in pairs(self.taskids) do
        if unit.id == id then
            return true
        end
    end
    return false
end

--- Get current task ID from database.
-- @return task ID
-- @return nil if there's no current task ID
function TaskID:getcurr()
    local idxcurr = 1
    local curr = self.taskids[idxcurr]

    if curr and curr.status == status.CURR then
        return curr.id
    end
    return nil
end

--- Get previous task ID from database.
-- @return task ID
-- @return nil if there's no previous task ID
function TaskID:getprev()
    local idxprev = 2
    local prev = self.taskids[idxprev]

    if prev and prev.status == status.PREV then
        return prev.id
    end
    return nil
end

--- Swap current and previous task IDs.
function TaskID:swap()
    local prev = self:getprev()
    local curr = self:getcurr()

    self:_setprev(curr)
    self:_setcurr(prev)
    return self:_save_taskids()
end

--- Set current task ID.
-- Set previous task ID if needed.
function TaskID:setcurr(id)
    local oldcurr = self:getcurr()

    if not self:exist(id) then
        log:err("no such task ID '%s' or empty", id or "")
        return false
    end
    self:_setprev(oldcurr)
    self:_setcurr(id)
    self:_save_taskids()
    return true
end

--- Unset current task ID.
-- Assumes that ID exists in database.
-- @param id task ID
-- @param taskstatus task status to move a current ID to
-- @return true on success, otherwise false
function TaskID:unsetcurr(taskstatus)
    local idxcurr = 1
    local curr = self.taskids[idxcurr]
    taskstatus = taskstatus or status.ACTV

    if curr and curr.status == status.CURR then
        curr.status = taskstatus
    end
    return true
end

--- Move task ID to new status.
-- @param id task ID
-- @param _status task new status (default: active)
-- @return true on success, otherwise false
function TaskID:move(id, _status)
    local prev = self:getprev()
    local curr = self:getcurr()
    _status = status.ACTV

    if id == curr then
        return self:movecurr()
    elseif id == prev then
        self:_unsetprev(_status)
    else
        -- roachme: maybe it's better to make a generic function for this thnigy?
        -- any other active or complete task ID
        for _, unit in pairs(self.taskids) do
            if unit.id == id then
                unit.status = _status
            end
        end
    end
end

--- Move current task to new status.
-- Update previous one if needed.
-- @param _status current task new status (default: active)
-- @return true on success, otherwise false
function TaskID:movecurr(_status)
    local prev = self:getprev()
    _status = status.ACTV

    self:_unsetprev(_status)
    self:setcurr(prev)
    return self:_save_taskids()
end

--- List task IDs.
-- There are 4 statuses: current, previous, active and completed. Default: active
-- @param active list only active task IDs
-- @param completed list only completed task IDs
-- @return count of task IDs
function TaskID:list(active, completed)
    local size = db.size()

    for idx = 1, size do
        local unit = db.getunit(idx)
        if unit.status == status.CURR and active then
            local desc = taskunit:getunit(unit.id, "desc")
            print(("* %-10s %s"):format(unit.id, desc))
        elseif unit.status == status.PREV and active then
            local desc = taskunit:getunit(unit.id, "desc")
            print(("- %-10s %s"):format(unit.id, desc))
        elseif unit.status == status.ACTV and active then
            local desc = taskunit:getunit(unit.id, "desc")
            print(("  %-10s %s"):format(unit.id, desc))
        elseif unit.status == status.COMP and completed then
            local desc = taskunit:getunit(unit.id, "desc")
            print(("  %-10s %s"):format(unit.id, desc))
        end
    end
    return size
end

-- Public functions: end --

return TaskID
