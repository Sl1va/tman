--- Operate on task units in database.
-- Like add, delete, list task IDs and so on.
-- @module TaskID


local TaskID = {}
TaskID.__index = TaskID

local TaskIDPrivate = {}
TaskIDPrivate.__index = TaskIDPrivate


--[[ TODO
    1. Make a function to create files for current and previous taskid's
    2. Set and update vars curr and prev not to calculate 'em all over again.
]]


local function log(fmt, ...)
    local msg = "taskid: " .. fmt:format(...)
    print(msg)
end


--- Class TaskIDPrivate
-- type TaskIDPrivate


--- Init class TaskIDPrivate.
-- @param gtaskpath path where tasks are located
function TaskIDPrivate.new()
    local self = setmetatable({
        taskpath = "/home/roach/work/tasks",
        meta  = "/home/roach/work/tasks" .. "/.tasks",
        curr  = nil,
        prev  = nil,
    }, TaskIDPrivate)
    self.curr = self:getcurr()
    self.prev = self:getprev()
    return self
end

--- Get task ID (private).
-- @param val `curr` or `prev` for current or previous task id
-- @return task ID or nil if task doesn't exist
function TaskIDPrivate:_gettaskid(type)
    local id = nil
    local fname = self.taskpath .. "/." .. type
    local f = io.open(fname)
    if not f then
        log("could not open file", fname)
        return nil
    end
    id = f:read("*l")
    f:close()
    return id
end

--- Get current task ID (private).
-- @return current task ID.
function TaskIDPrivate:getcurr()
    return self:_gettaskid("curr")
end

--- Get previous task ID (private).
-- @returtn previous task ID.
function TaskIDPrivate:getprev()
    return self:_gettaskid("prev")
end

--- Set task ID (private).
-- @param taskid task ID to set
-- @param val `curr` or `prev` for current or previous task id
-- @treturn bool true if task id was set, otherwise false
function TaskIDPrivate:_settaskid(id, type)
    local fname = self.taskpath .. "/." .. type
    local f = io.open(fname, "w")
    if not f then
        log("could not open file", fname)
        return false
    end
    if id then
        f:write(id, "\n")
    end
    f:close()
    return true
end


--- Class TaskID
-- type TaskID


local taskid_pr = TaskIDPrivate.new()

--- Init class TaskID.
function TaskID.new()
    local self = setmetatable({
        curr = taskid_pr:getcurr(),
        prev = taskid_pr:getprev(),
    }, TaskID)
    return self
end

--- Add a new task ID.
-- @param taskid task ID to add to database
-- @treturn bool true if task ID was adde, otherwise false
function TaskID:add(taskid)
    local f = io.open(taskid_pr.meta, "a+")
    if self:exist(taskid) then
        log(("task '%s' already exists"):format(taskid))
        return false
    end
    if not f then
        log("could not open meta file")
        return false
    end
    f:write(taskid, "\n")
    f:close()

    self:setcurr(taskid)
    self.curr = taskid_pr:getcurr()
    if self.curr then
        self:setprev(self.curr)
    end
    return true
end

--- Check that task ID exist in database (private).
-- @param taskid task ID to look up
-- @treturn bool true if task ID exist, otherwise false
function TaskID:exist(taskid)
    local res = false
    local f = io.open(taskid_pr.meta, "r")
    if not f then
        log("could not open meta file")
        return
    end
    for line in f:lines() do
        if line == taskid then
            res = true
            break
        end
    end
    f:close()
    return res
end

--- Delete a task ID.
-- @treturn bool true if deleting task ID was successful, otherwise false
function TaskID:del(taskid)
    local f = io.open(taskid_pr.meta, "r")
    local lines = {}
    if not self:exist(taskid) then
        log("task '%s' doesn't exist", taskid)
        return false
    end
    if not f then
        log("could not open meta file")
        return false
    end
    for line in f:lines() do
        if line ~= taskid then
            table.insert(lines, line)
        end
    end
    f:close()

    -- Update database file
    f = io.open(taskid_pr.meta, "w")
    if not f then
        log("could not open meta file")
        return false
    end
    for _, line in pairs(lines) do
        f:write(line, "\n")
    end
    f:close()
    self:unsetcurr()
    return true
end

--- Set current task ID.
-- @param id task ID
-- @treturn bool true if current task is set, otherwise false
function TaskID:setcurr(id)
    if not self:exist(id) then
        log("can't set current task ID '%s' (doesn't exist in database)", id)
        return false
    end
    taskid_pr.curr = id
    return taskid_pr:_settaskid(id, "/.curr")
end

--- Set previous task ID.
-- @param id task ID
-- @treturn bool true if previous task is set, otherwise false
function TaskID:setprev(id)
    if not self:exist(id) then
        log("can't set previous task ID '%s' (doesn't exist in database)", id)
        return false
    end
    taskid_pr.prev = id
    return taskid_pr:_settaskid(id, "/.prev")
end

--- Clear current task ID.
-- @treturn bool true if current task is unset, otherwise false
function TaskID:unsetcurr()
    taskid_pr.curr = nil
    return taskid_pr:_settaskid(nil, "/.curr")
end

--- Clear current task ID.
-- @treturn bool true if previous task is unset, otherwise false
function TaskID:unsetprev()
    taskid_pr.prev = nil
    return taskid_pr:_settaskid(nil, "/.prev")
end

--- List all task IDs from the database.
-- @param fn callback function
function TaskID:list(fn)
    local f = io.open(taskid_pr.meta)
    if not f then
        log("could not open meta file")
        return
    end
    if self.curr then
        print(("* %-8s %s"):format(self.curr, fn()))
    end
    for id in f:lines() do
        if self.curr ~= id then
            print(("  %-8s %s"):format(id, fn()))
        end
    end
    f:close()
end

return TaskID
