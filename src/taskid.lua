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
-- @type TaskID

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

--- Clear previous task ID.
-- @treturn bool true if previous task is unset, otherwise false
function TaskID:unsetprev()
    local previdx = 2

    if self.taskids[previdx].type == types.PREV then
        self.taskids[previdx].type = types.ACTV
    end
    return true
end

--[[

public:
    curr - member
    prev - member
    add()
    del()
    list()
    updcurr() - update current and previous task ID
    unsetcurr()
    swap()

private:
    getcurr()
    getprev()
    exist()
]]

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

--- Update current task ID, update previous one subsequently.
-- @param id new current task ID
function TaskID:updcurr(id)
    local curr = self:getcurr()

    if curr then
        self:setprev(curr)
    end
    self:setcurr(id)
end

--- Swap current and previous task IDs.
function TaskID:swap()
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
    self.curr = self:getcurr()
    self.prev = self:getprev()
    return true
end

--- List task IDs.
-- @param active list only active task IDs
-- @param complete list only complete task IDs
function TaskID:list(active, complete)
    local fmt = "  %-8s %s"
    local fmt_curr = "* %-8s %s"
    local fmt_prev = "- %-8s %s"

    for _, unit in pairs(self.taskids) do
        local desc = taskunit:getunit(unit.id, "desc")

        if unit.type == types.CURR and (active and complete or active) then
            print((fmt_curr):format(unit.id, desc))
        elseif unit.type == types.PREV and (active and complete or active) then
            print((fmt_prev):format(unit.id, desc))
        elseif active and unit.type ~= types.COMP then
            print((fmt):format(unit.id, desc))
        elseif complete and unit.type == types.COMP then
            print((fmt):format(unit.id, desc))
        end
    end
end

return TaskID
