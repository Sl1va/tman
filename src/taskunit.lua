--- Operate on task unit inside meta data.
-- Metadata like branch name, date, description and so on.
-- @module TaskUnit

local gitmod = require("git")
local globals = require("globals")
local log = require("log").init("taskunit")

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


local unit_ids = {
    basic = 4, -- id, prio, type, desc
    full = 8,  -- basic + time, date, status, branch
}

local unit_prios = {
    highest = "highest",
    high = "high",
    mid = "mid",
    low = "low",
    lowest = "lowest",
}

--- Get table size (hash part).
-- @param tab a toble to operate on
-- @return table size
function table.size(tab)
    local size = 0

    for _, _ in pairs(tab) do
        size = size + 1
    end
    return size
end

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

--- Save task units into file.
-- @param unit units to save
-- @param fname filename to save units into
local function save_units(units, fname)
    local i = 0
    local len = table.size(units)
    local file = io.open(fname, "w")

    if not file then
        print("taskunit: error: could not create file note", fname)
        return false
    end

    while i < len do
        for _, item in pairs(units) do
            if i == item.prio then
                file:write(("%s: %s\n"):format(item.inptext, item.value))
            end
        end
        i = i + 1
    end
    file:close()
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
function TaskUnit:add(id, tasktype, prio)
    prio = prio or unit_prios.mid
    local fname = globals.G_tmanpath .. id
    -- roachme: refactor it, don't like prios. Just don't.
    local unit = {
        id = { prio = 0, inptext = "ID", value = id },
        prio = { prio = 1, inptext = "Prio", value = prio},
        type = { prio = 2, inptext = "Type", value = tasktype },
        desc = { prio = 3, inptext = "Desc", value = "" },

        -- roachme: find a way to include it properly
        --time = { prio = 0, inptext = "Time", value = {capac = "N/A", left = "N/A"}},
        time = { prio = 5, inptext = "Time", value = "N/A"},
        date = { prio = 4, inptext = "Date", value = os.date("%Y%m%d") },
        status = { prio = 6, inptext = "Status", value = "progress" },
        branch = { prio = 7, inptext = "Branch", value = "" },
    }
    unit.desc.value = get_input(unit.desc.inptext)
    unit.branch.value = format_branch(unit)

    -- Check user input
    if not check_tasktype(tasktype) then
        log:err("unknown task type: '%s'", tasktype)
        return false
    end

    save_units(unit, fname)

    -- create task repos and branches in them
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
function TaskUnit:show(id, prio)
    prio = prio or unit_ids.basic
    local fname = globals.G_tmanpath .. id
    local f = io.open(fname)

    if not f then
        print("taskunit: could not open file", fname)
        return false
    end
    for line in f:lines() do
        if prio == 0 then
            break
        end
        local key, val = string.match(line, unitregex)
        print(("%-8s: %s"):format(key, val))
        prio = prio - 1
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
