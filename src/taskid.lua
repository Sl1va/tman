--- Operate on task units in database.
-- Like add, delete, list task IDs and so on.
-- @module TaskID

local taskunit = require("taskunit")

local TaskID = {}
TaskID.__index = TaskID
taskunit = taskunit.newobj()

--- Types of task IDs.
local types = {
    CURR = 0, -- current task
    PREV = 1, -- previous task
    ACTV = 2, -- active task
    COMP = 3, -- complete task
}

-- Private functions: start --

local function log(fmt, ...)
    local msg = "taskid: " .. fmt:format(...)
    print(msg)
end

--- Class TaskID
-- @type TaskID

--- Load task iDs from the file.
-- @treturn table table like {id, type}
function TaskID:load_taskids()
    local taskids = {}
    local f = io.open(self.meta)

    if not f then
        log("couldn't open file '%s'", self.meta)
        return taskids
    end
    for line in f:lines() do
        local id, idtype = string.match(line, "(.*) (.*)")
        table.insert(taskids, { id = id, type = tonumber(idtype) })
    end
    f:close()
    table.sort(taskids, function(a, b)
        return a.type < b.type
    end)
    return taskids
end

--- Save task iDs to the file.
function TaskID:save_taskids()
    local f = io.open(self.meta, "w")

    if not f then
        log("couldn't open meta file")
        return false
    end
    for _, unit in pairs(self.taskids) do
        f:write(unit.id, " ", unit.type, "\n")
    end
    f:close()
end

--- Get current task ID.
-- @return task ID
function TaskID:getcurr()
    for _, unit in pairs(self.taskids) do
        if unit.type == types.CURR then
            return unit.id
        end
    end
    return nil
end

--- Get previous task ID.
-- @return task ID
function TaskID:getprev()
    for _, unit in pairs(self.taskids) do
        if unit.type == types.PREV then
            return unit.id
        end
    end
    return nil
end

--- Set current task ID.
-- @param id task ID
-- @return true on success, otherwise false
function TaskID:setcurr(id)
    local curridx = 1

    if self.taskids[curridx].type == types.CURR then
        self.taskids[curridx].type = types.ACTV
    end
    for _, unit in pairs(self.taskids) do
        if unit.id == id then
            unit.type = types.CURR
        end
    end
    self:save_taskids()
    self.curr = id
    return true
end

--- Set previous task ID.
-- @param id task ID
-- @treturn bool true if previous task is set, otherwise false
function TaskID:setprev(id)
    local previdx = 2

    if self.taskids[previdx].type == types.PREV then
        self.taskids[previdx].type = types.ACTV
    end
    for _, unit in pairs(self.taskids) do
        if unit.id == id then
            unit.type = types.PREV
            break
        end
    end
    self:save_taskids()
    self.prev = id
    return true
end

-- Private functions: end --


-- Public functions: start --

--- Init class TaskID.
-- @return new object
function TaskID.new()
    local self = setmetatable({}, TaskID)
    self.meta = G_tmanpath .. "taskids"
    self.taskids = self:load_taskids()
    self.curr = self:getcurr()
    self.prev = self:getprev()
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
    self:updcurr(id)
    table.insert(self.taskids, { id = id, type = types.CURR })
    self:save_taskids()
    return true
end

--- Delete a task ID.
-- @param id task ID
-- @treturn bool true on success, otherwise false
function TaskID:del(id)
    if not self:exist(id) then
        return false
    end
    for i, unit in pairs(self.taskids) do
        if unit.id == id then
            table.remove(self.taskids, i)
        end
    end
    self:save_taskids()
    self:updcurr(id)
    return true
end

--- List task IDs.
-- There are 4 types: current, previous, active and completed. Default: active
-- @param active list only active task IDs
-- @param completed list only completed task IDs
-- @return true on success, otherwise false
function TaskID:list(active, completed)
    for _, unit in pairs(self.taskids) do
        if unit.type == types.CURR and (active and completed or active) then
            local desc = taskunit:getunit(unit.id, "desc")
            print(("* %-8s %s"):format(unit.id, desc))
        elseif unit.type == types.PREV and (active and completed or active) then
            local desc = taskunit:getunit(unit.id, "desc")
            print(("- %-8s %s"):format(unit.id, desc))
        elseif unit.type ~= types.COMP and active then
            local desc = taskunit:getunit(unit.id, "desc")
            print(("  %-8s %s"):format(unit.id, desc))
        elseif unit.type == types.COMP and completed then
            local desc = taskunit:getunit(unit.id, "desc")
            print(("  %-8s %s"):format(unit.id, desc))
        end
    end
    return true
end

--- Update current task ID, update previous one subsequently.
-- @param id new current task ID
function TaskID:updcurr(id)
    -- roachme: self.taskid stays outdated.
    local curr = self:getcurr()

    if curr then
        self:setprev(curr)
    end
    self:setcurr(id)
end

--- Swap current and previous task IDs.
function TaskID:swap()
    -- roachme: self.taskid stays outdated.
    local prev = self.prev
    local curr = self.curr

    self:setprev(curr)
    self:setcurr(prev)
end

--- Clear current task ID.
-- @tparam bool isdone if set move task to done, otherwise to active
-- @treturn bool true if current task is unset, otherwise false
function TaskID:unsetcurr(isdone)
    local tasktype = types.ACTV
    if isdone then
        tasktype = types.COMP
    end
    for _, unit in pairs(self.taskids) do
        if unit.type == types.CURR then
            unit.type = tasktype
            self.curr = nil
            break
        end
    end
    self:save_taskids()
    return true
end

-- Public functions: start --

return TaskID
