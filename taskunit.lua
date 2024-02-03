--- Operate on task unit inside meta data.
-- Metadata like branch name, date, description and so on.
-- @module TaskUnit

local posix = require("posix")
local git = require("git")


local TaskUnit = {}
TaskUnit.__index = TaskUnit




local function log(fmt, ...)
    local msg = "taskunit: " .. fmt:format(...)
    print(msg)
end

local function get_input(promtp)
    io.write(promtp, ": ")
    return io.read("*line")
end

local function format_branch(task)
    local branch = task.type.value .. "/" .. task.id.value
    branch = branch .. "_" .. task.desc.value:gsub(" ", "_")
    branch = branch .. "_" .. task.date.value
    return branch
end

--- Check that user specified task type exists.
-- @tparam string type user specified type
-- @treturn bool true if exists, otherwise false
local function check_tasktype(type)
    local tasktypes = { "bugfix", "feature", "hotfix" }
    local found = false
    for _, dtype in pairs(tasktypes) do
        if type == dtype then
            found = true
        end
    end
    return found
end


--- Class TaskUnit
-- type TaskUnit

function TaskUnit:formnote(id)
    return self.taskpath .. "/" .. id .. "/.note"
end

--- Init class TaskUnit.
function TaskUnit.newobj(gtaskpath)
    local self = setmetatable({
        taskpath = gtaskpath or "/home/roach/work/tasks",
    }, TaskUnit)
    return self
end


--- Create a new unit for a task.
-- @param id task id
function TaskUnit:new(id)
    local file    = nil
    local taskdir = self.taskpath .. "/" .. id
    local fname   = taskdir .. "/.note"

    local unit = {
        id     = { mark = false, inptext = "ID",     value = id },
        type   = { mark = true,  inptext = "Type",   value = "" },
        desc   = { mark = true,  inptext = "Desc",   value = "" },
        date   = { mark = false, inptext = "Date",   value = os.date("%Y%m%d") },
        branch = { mark = false, inptext = "Branch", value = "" },
        status = { mark = false, inptext = "Status", value = "progress" },
    }

    -- roachme: sort table
    -- Get user input
    for _, item in pairs(unit) do
        if item.mark then
            item.value = get_input(item.inptext)
        end
    end
    unit.branch.value = format_branch(unit)

    -- Check user input
    if not check_tasktype(unit.type.value) then
        print("taskunit: error: unknown task type: " .. unit.type.value)
        return false
    end

    -- Save task info
    posix.mkdir(taskdir)
    --- roachme: git: create symlinks to repos
    file = io.open(fname, "w")
    if not file then
        print("taskunit: error: could not create file note", fname)
        return false
    end
    for _, item in pairs(unit) do
        file:write(("%s: %s\n"):format(item.inptext, item.value))
    end
    file:close()

    --- create task branches in repos
    git = git.new(unit.id.value, unit.branch.value)
    git:repolink()
    git:branch_create()
    return true
end

--- Get unit from task metadata.
-- @param id task ID
-- @param unit unit key we need value of
-- @treturn string unit value
function TaskUnit:getunit(id, key)
    local res = nil
    local fname = self.taskpath .. "/" .. id .. "/.note"
    local f = io.open(fname)
    if not f then
        log("could not open task unit file")
        return nil
    end
    for line in f:lines() do
        if string.match(line, "(%w+)"):lower() == key then
            res = string.match(line, "%w+%s*:%s+(.*)")
        end
    end
    return res
end

--- Update task status.
-- @param id task ID
-- @param key key
-- @param val value
-- @treturn bool true if could change task status, otherwise false
function TaskUnit:setunit(id, key, val)
    local lines = {}
    local fname = self:formnote(id)
    local f = io.open(fname, "r+")
    if not f then
        log("could not open file '%s'", fname)
        return false
    end
    for line in f:lines() do
        if string.match(line, key) then
            line = key .. ": " .. val
        end
        table.insert(lines, line)
    end
    f:close()

    f = io.open(fname, "w")
    if not f then
        log("could not open file '%s'", fname)
        return false
    end
    for _, line in pairs(lines) do
        f:write(line, "\n")
    end
    f:close()
    return true
end

--[[
local taskunit = TaskUnit.newobj()
local key = "Status"
local val = "backlog"
taskunit:setunit("DE-me", key, val)
]]




--- Amend task unit.
-- Like branch name, ID, etc.
function TaskUnit:amend(id)
end

--- Show task unit metadata.
-- @param id task ID
function TaskUnit:show(id)
    local fname = self.taskpath .. "/" .. id .. "/.note"
    local f = io.open(fname)
    if not f then
        print("taskunit: could not open file", fname)
        return false
    end
    for line in f:lines() do
        print(line)
    end
    f:close()
    return true
end

--- Delete task unit.
-- @param id task ID
function TaskUnit:del(id)
    git = git.new(id, self:getunit(id, "branch"))
    git:branch_delete()
    os.execute("rm -rf " .. self.taskpath .. "/" .. id)
    return true
end

return TaskUnit
