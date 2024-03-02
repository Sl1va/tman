--- Operate on task unit inside meta data.
-- Metadata like branch name, date, description and so on.
-- @module TaskUnit

local posix = require("posix")
local gitmod = require("git")
local globals = require("globals")
local log = require("log"):init("taskunit")

local unitregex = "(.*): (.*)"

--[[
1 - main ones
2 - a bit more info about task
3 - mantadory stuff

1. ID
2. Type
2. Prio
2. Status
1. Desc

3. Date
3. Branch
]]






--[[
Public functions:
    add     - add new unit file
    del     - delete unit file
    show    - show unit file
    amend   - amend unit file (under development)
    getunit - get unit value from unit file
]]



local TaskUnit = {}
TaskUnit.__index = TaskUnit

local function get_input(prompt)
    io.write(prompt, ": ")
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

--- Init class TaskUnit.
function TaskUnit.new()
    local self = setmetatable({}, TaskUnit)
    return self
end

--- Add a new unit for a task.
-- @param id task id
-- @param tasktype task type: bugfix, hotfix, feature
function TaskUnit:add(id, tasktype)
    local file = nil
    local taskdir = globals.G_taskpath .. id
    local fname = globals.G_tmanpath .. id

    local unit = {
        id = { mark = false, inptext = "ID", value = id },
        type = { mark = true, inptext = "Type", value = tasktype },
        desc = { mark = true, inptext = "Desc", value = "" },
        date = { mark = false, inptext = "Date", value = os.date("%Y%m%d") },
        branch = { mark = false, inptext = "Branch", value = "" },
        status = { mark = false, inptext = "Status", value = "progress" },
    }
    unit.desc.value = get_input(unit.desc.inptext)
    unit.branch.value = format_branch(unit)

    -- Check user input
    if not check_tasktype(tasktype) then
        print("taskunit: error: unknown task type: " .. tasktype)
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
    local git = gitmod.new(unit.id.value, unit.branch.value)
    return git:branch_create()
end

--- Get unit from task metadata.
-- @param id task ID
-- @param key unit key
-- @return unit value
function TaskUnit:getunit(id, key)
    local fname = globals.G_tmanpath .. id
    local f = io.open(fname)

    if not f then
        log:err("could not open task unit file")
        return nil
    end
    for line in f:lines() do
        local ukey, uval = string.match(line, unitregex)
        if string.lower(ukey) == key then
            return uval
        end
    end
    return nil
end

--- Amend task unit.
-- Like branch name, ID, etc.
function TaskUnit:amend(id) end

--- Show task unit metadata.
-- @param id task ID
function TaskUnit:show(id)
    local fname = globals.G_tmanpath .. id
    local f = io.open(fname)

    if not f then
        print("taskunit: could not open file", fname)
        return false
    end
    for line in f:lines() do
        local key, val = string.match(line, unitregex)
        print(("%-8s: %s"):format(key, val))
    end
    f:close()
    return true
end

--- Delete task unit.
-- @param id task ID
function TaskUnit:del(id)
    local unitfile = globals.G_taskpath .. id
    local branch = self:getunit(id, "branch")
    local git = gitmod.new(id, branch)

    git:branch_delete()
    os.remove(unitfile)
    return true
end

return TaskUnit
