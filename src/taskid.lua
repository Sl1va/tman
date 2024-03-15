--- Operate on task units in database.
-- Like add, delete, list task IDs and so on.
-- @module TaskID

--[[
Private functions:
    setcurr
    setprev
    unsetcurr
    unsetprev

Public functions:
    add         - add a new task ID to database
    del         - del a task ID from database
    list        - list all task IDs in database
    swap        - swap current and previous task IDs
    exist       - check that task ID exist in database
    getcurr     - get current task ID value from database
    getprev     - get previous task ID value from database

    update      - mark new ID as current, mark old current as previous
    move        - move current ID to new status, make previous a current ID
]]

local taskunit = require("taskunit")
local globals = require("globals")
local log = require("log").init("taskid")

local TaskID = {}
TaskID.__index = TaskID
taskunit = taskunit.init()

--- Types of task IDs.
local types = {
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

--- Get current task ID from database.
-- @return task ID
-- @return nil if there's no current task ID
function TaskID:getcurr()
    local idxcurr = 1
    local curr = self.taskids[idxcurr]

    if curr and curr.type == types.CURR then
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

    if prev and prev.type == types.PREV then
        return prev.id
    end
    return nil
end

--- Set current task ID.
-- Assumes that ID exists in database.
-- @param id task ID
-- @return true on success, otherwise false
function TaskID:setcurr(id)
    local idxcurr = 1
    local curr = self.taskids[idxcurr]

    -- unset old current task ID
    if curr and curr.type == types.CURR then
        curr.type = types.ACTV
    end
    for _, unit in pairs(self.taskids) do
        if unit.id == id then
            unit.type = types.CURR
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
    if prev and prev.type == types.PREV then
        prev.type = types.ACTV
    end
    for _, unit in pairs(self.taskids) do
        if unit.id == id then
            unit.type = types.PREV
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
    tasktype = tasktype or types.ACTV

    if curr and curr.type == types.CURR then
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
    tasktype = tasktype or types.ACTV

    if curr and curr.type == types.PREV then
        curr.type = tasktype
    end
end

-- Private functions: end --

-- Public functions: start --

--- Init class TaskID.
-- @return new object
function TaskID.init()
    local self = setmetatable({}, TaskID)
    self.meta = globals.G_tmanpath .. "taskids"
    self.taskids = self:load_taskids()
    self.types = types
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
    table.insert(self.taskids, { id = id, type = types.CURR })
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
        if unit.type == types.CURR and active then
            local desc = taskunit:getunit(unit.id, "desc")
            print(("* %-8s %s"):format(unit.id, desc))

        elseif unit.type == types.PREV and active then
            local desc = taskunit:getunit(unit.id, "desc")
            print(("- %-8s %s"):format(unit.id, desc))

        elseif unit.type == types.ACTV and active then
            local desc = taskunit:getunit(unit.id, "desc")
            print(("  %-8s %s"):format(unit.id, desc))

        elseif unit.type == types.COMP and completed then
            local desc = taskunit:getunit(unit.id, "desc")
            print(("  %-8s %s"):format(unit.id, desc))
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
-- @param tasktype task type
-- @return true on success, otherwise false
function TaskID:move(tasktype)
    local prev = self:getprev()

    self:unsetcurr(tasktype)
    self:unsetprev(types.ACTV)
    self:setcurr(prev)
    return self:save_taskids()
end

-- Public functions: start --

return TaskID
