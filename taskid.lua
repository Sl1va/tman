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

local function log(fmt, ...)
    local msg = "taskid: " .. fmt:format(...)
    print(msg)
end

--- Class TaskID
-- type TaskID

--- Load task iDs from the file.
-- @treturn table table like {id, type}
function TaskID:load_taskids()
    local f = io.open(self.meta)
    local taskids = {}
    if not f then
        print("error: couldn't open file", self.meta)
        return taskids
    end
    for line in f:lines() do
        local id, idtype = string.match(line, "(.*)%s(.*)")
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

--- Init class TaskID.
function TaskID.new()
    local self = setmetatable({
        taskpath = "/home/roach/work/tasks",
    }, TaskID)
    self.meta = self.taskpath .. "/.tasks"
    self.taskids = self:load_taskids()
    self.curr = self:getcurr()
    self.prev = self:getprev()
    return self
end

--- Add a new task ID.
-- @param id task ID to add to database
-- @treturn bool true on success, otherwise false
function TaskID:add(id)
    local curr = self:getcurr()
    if self:exist(id) then
        log(("task '%s' already exists"):format(id))
        return false
    end
    table.insert(self.taskids, { id = id, type = types.CURR })
    self:setcurr(id)
    self:setprev(curr)
    self:save_taskids()
    return true
end

--- Delete a task ID.
-- @param id task ID
-- @treturn bool true if deleting task ID was successful, otherwise false
function TaskID:del(id)
    if not self:exist(id) then
        log(("task '%s' doesn't exist"):format(id))
        return false
    end
    for i, unit in pairs(self.taskids) do
        if unit.id == id then
            table.remove(self.taskids, i)
        end
    end
    self:save_taskids()
    self.curr = self:getcurr()
    self.prev = self:getprev()
    return true
end

--- List task IDs.
-- @param all if true then show active and complete task. Default: active only
function TaskID:list(all)
    local logmsg = "  %-8s %s"
    local logmsg_curr = "* %-8s %s"
    for _, unit in pairs(self.taskids) do
        local desc = taskunit:getunit(unit.id, "desc")
        if unit.type == types.CURR then
            print((logmsg_curr):format(unit.id, desc))
        elseif all then
            print((logmsg):format(unit.id, desc))
        elseif not all and unit.type ~= types.COMP then
            print((logmsg):format(unit.id, desc))
        end
    end
end

--- Check that task ID exist.
-- @param id task ID to look up
-- @treturn bool true if task ID exist, otherwise false
function TaskID:exist(id)
    local res = false
    for _, unit in pairs(self.taskids) do
        if unit.id == id then
            res = true
            break
        end
    end
    return res
end

--- Get current task ID.
-- @return task ID
function TaskID:getcurr()
    local id = nil
    for _, unit in pairs(self.taskids) do
        if unit.type == types.CURR then
            id = unit.id
            break
        end
    end
    return id
end

--- Get previous task ID.
-- @return task ID
function TaskID:getprev()
    local id = nil
    for _, unit in pairs(self.taskids) do
        if unit.type == types.PREV then
            id = unit.id
            break
        end
    end
    return id
end

--- Set current task ID.
-- @param id task ID
-- @return true on success, otherwise false
function TaskID:setcurr(id)
    if not self:exist(id) then
        log("setcurr: task ID '%s' doesn't exist", id)
        return false
    end
    for _, unit in pairs(self.taskids) do
        if unit.type == types.CURR then
            unit.type = types.ACTV
        end
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
    if not self:exist(id) then
        log("setprev: task ID '%s' doesn't exist", id)
        return false
    end
    for _, unit in pairs(self.taskids) do
        if unit.type == types.PREV then
            unit.type = types.ACTV
            break
        end
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

--- Clear current task ID.
-- @treturn bool true if current task is unset, otherwise false
function TaskID:unsetcurr()
    for _, unit in pairs(self.taskids) do
        if unit.type == types.CURR then
            unit.type = types.ACTV
            self.curr = nil
            break
        end
    end
    return true
end

--- Clear previous task ID.
-- @treturn bool true if previous task is unset, otherwise false
function TaskID:unsetprev()
    for _, unit in pairs(self.taskids) do
        if unit.type == types.PREV then
            unit.type = types.ACTV
            self.curr = nil
            break
        end
    end
    return true
end

return TaskID
