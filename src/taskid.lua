--- Operate on task units in database.
-- Like add, delete, list task IDs and so on.
-- @module TaskID

--[[
Private functions:
    setcurr
    setprev
    unsetcurr
    unsetprev

    load_taskids
    save_taskids

Public functions:
    add         - add a new task ID to database
    del         - del a task ID from database
    swap        - swap current and previous task IDs
    exist       - check that task ID exist in database
    getcurr     - get current task ID value from database
    getprev     - get previous task ID value from database

    setcurr     - mark new ID as current, mark old current as previous if needed (cmd: move (depricated))
    movecurr    - move current ID to new status, make previous a current ID
    unsetcurr   - unset current task

    -- roachme: questionable thingy
    list        - list all task IDs in database (roachme: redicilous API command)

]]

local taskunit = require("taskunit")
local globals = require("globals")
local log = require("log").init("taskid")

local TaskID = {}
TaskID.__index = TaskID
taskunit = taskunit.init()

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
-- @treturn table table like {id, type}
function TaskID:load_taskids()
    local taskids = {}
    local f = io.open(self.meta)

    if not f then
        log:err("couldn't open file '%s'", self.meta)
        return taskids
    end
    for line in f:lines() do
        local id, idtype = string.match(line, "(.*) (.*)")
        table.insert(taskids, { id = id, type = tonumber(idtype) })
    end
    f:close()
    return taskids
end

--- Save task IDs to the file.
function TaskID:save_taskids()
    local f = io.open(self.meta, "w")

    if not f then
        log:err("couldn't open meta file")
        return false
    end

    table.sort(self.taskids, function(a, b)
        return a.type < b.type
    end)
    for _, unit in pairs(self.taskids) do
        f:write(unit.id, " ", unit.type, "\n")
    end
    return f:close()
end

--- Get taskid by index.
-- @param id task ID by index from the database.
-- @return task ID
-- @return nil if there's no current task ID
function TaskID:getid(idx)
    local taskid = self.taskids[idx]

    if taskid and taskid.type == status.CURR then
        return taskid.id
    end
    return nil
end

--- Get current task ID from database.
-- @return task ID
-- @return nil if there's no current task ID
function TaskID:getcurr()
    local idxcurr = 1
    return self:getid(idxcurr)
end

--- Get previous task ID from database.
-- @return task ID
-- @return nil if there's no previous task ID
function TaskID:getprev()
    local idxprev = 2
    return self:getid(idxprev)
end

--- Set current task ID.
-- Assumes that ID exists in database.
-- @param id task ID
-- @return true on success, otherwise false
function TaskID:setcurr(id)
    local idxcurr = 1
    local curr = self.taskids[idxcurr]

    -- unset old current task ID
    if curr and curr.type == status.CURR then
        curr.type = status.ACTV
    end
    for _, unit in pairs(self.taskids) do
        if unit.id == id then
            unit.type = status.CURR
            break
        end
    end
end

--- Set previous task ID.
-- Assumes that ID exists in database.
-- @param id task ID
-- @treturn bool true if previous task is set, otherwise false
function TaskID:setprev(id)
    local idxprev = 2
    local prev = self.taskids[idxprev]

    -- unset old previous task ID
    if prev and prev.type == status.PREV then
        prev.type = status.ACTV
    end
    for _, unit in pairs(self.taskids) do
        if unit.id == id then
            unit.type = status.PREV
            break
        end
    end
end

--- Unset current task ID.
-- Assumes that ID exists in database.
-- @param id task ID
-- @param tasktype task type to move a current ID to
-- @return true on success, otherwise false
function TaskID:unsetcurr(tasktype)
    local idxcurr = 1
    local curr = self.taskids[idxcurr]
    tasktype = tasktype or status.ACTV

    if curr and curr.type == status.CURR then
        curr.type = tasktype
    end
end

--- Unset previous task ID.
-- Assumes that ID exists in database.
-- @param id task ID
-- @param tasktype task type to move a previous ID to
-- @return true on success, otherwise false
function TaskID:unsetprev(tasktype)
    local idxcurr = 1
    local curr = self.taskids[idxcurr]
    tasktype = tasktype or status.ACTV

    if curr and curr.type == status.PREV then
        curr.type = tasktype
    end
end

-- Private functions: end --

-- Public functions: start --

--- Init class TaskID.
-- @return new object
function TaskID.init()
    local self = setmetatable({}, TaskID)
    self.meta = globals.tmandb .. "taskids"
    self.taskids = self:load_taskids()
    self.types = status
    return self
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

--- Add a new task ID.
-- @param id task ID to add to database
-- @treturn bool true on success, otherwise false
function TaskID:add(id)
    if self:exist(id) then
        return false
    end
    -- roachme: shoudn't we swap these commands?
    self:update(id)
    table.insert(self.taskids, { id = id, type = status.CURR })
    return self:save_taskids()
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
    self:unsetprev()
    self:setcurr(prev)
    return self:save_taskids()
end

--- List task IDs.
-- There are 4 types: current, previous, active and completed. Default: active
-- @param active list only active task IDs
-- @param completed list only completed task IDs
-- @return count of task IDs
function TaskID:list(active, completed)
    local count = 1

    for _, unit in pairs(self.taskids) do
        if unit.type == status.CURR and active then
            local desc = taskunit:getunit(unit.id, "desc")
            print(("* %-10s %s"):format(unit.id, desc))
        elseif unit.type == status.PREV and active then
            local desc = taskunit:getunit(unit.id, "desc")
            print(("- %-10s %s"):format(unit.id, desc))
        elseif unit.type == status.ACTV and active then
            local desc = taskunit:getunit(unit.id, "desc")
            print(("  %-10s %s"):format(unit.id, desc))
        elseif unit.type == status.COMP and completed then
            local desc = taskunit:getunit(unit.id, "desc")
            print(("  %-10s %s"):format(unit.id, desc))
        end
        count = count + 1
    end
    return count
end

--- Update current task ID, update previous one subsequently.
-- Assumes that tasi ID exists in database.
-- @param id new current task ID
function TaskID:update(id)
    local curr = self:getcurr()

    self:setprev(curr)
    self:setcurr(id)
    return self:save_taskids()
end

--- Swap current and previous task IDs.
function TaskID:swap()
    local prev = self:getprev()
    local curr = self:getcurr()

    self:setprev(curr)
    self:setcurr(prev)
    return self:save_taskids()
end

--- Move current task to new status.
-- Update previous one if needed.
-- @param tasktype task type
-- @return true on success, otherwise false
function TaskID:move(tasktype)
    local prev = self:getprev()

    self:unsetcurr(tasktype)
    self:unsetprev(status.ACTV)
    self:setcurr(prev)
    return self:save_taskids()
end

-- Public functions: end --

return TaskID
