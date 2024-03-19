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
    full = 8, -- basic + time, date, status, branch
}

local unit_prios = {
    highest = "highest",
    high = "high",
    mid = "mid",
    low = "low",
    lowest = "lowest",
}

local unit_keys = {
    "id",
    "prio",
    "type",
    "desc",

    "time",
    "date",
    "status",
    "branch",
}

--[[
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
]]


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

--- Check that priority exists.
-- @param priority priority to check
-- @return true on success, otherwise false
local function check_unit_prios(priority)
    for _, prio in pairs(unit_prios) do
        if prio == priority then
            return true
        end
    end
    return false
end

--- Check that unit key exist.
-- @param keyvalue key to check
-- @return true on success, otherwise false
local function check_unit_keys(keyvalue)
    for _, kval in pairs(unit_keys) do
        if kval == keyvalue then
            return true
        end
    end
    return false
end

--- Class TaskUnit
-- type TaskUnit

--- Init class TaskUnit.
function TaskUnit.init()
    local self = setmetatable({}, TaskUnit)
    return self
end

--- Check that task unit is not corrupted.
-- roachme: it should check user key as well, but i just don't know
-- @param id task id
-- @param true on success, otherwise false
function TaskUnit:check_unitfile(id)
    local i = 1
    local taskunits = self:load_units(id)

    if not next(taskunits) then
        return false
    end

    for _, _ in pairs(taskunits) do
        local key = unit_keys[i]
        if not taskunits[key] or taskunits[key].value then
            return false
        end
        i = i + 1
    end
    return true
end

--- Add a new unit for a task.
-- @param id task id
-- @param tasktype task type: bugfix, hotfix, feature
function TaskUnit:add(id, tasktype, prio)
    prio = prio or unit_prios.mid
    local unit = {
        id = { key = "ID", value = id },
        prio = { key = "Prio", value = prio },
        type = { key = "Type", value = tasktype },
        desc = { key = "Desc", value = "" },

        -- roachme: find a way to include it properly
        --time = { prio = 0, key = "Time", value = {capac = "N/A", left = "N/A"}},
        time = { key = "Time", value = "N/A" },
        date = { key = "Date", value = os.date("%Y%m%d") },
        status = { key = "Status", value = "progress" },
        branch = { key = "Branch", value = "" },
    }
    unit.desc.value = get_input(unit.desc.key)
    unit.branch.value = format_branch(unit)

    -- Check user input
    if not check_tasktype(tasktype) then
        log:err("unknown task type: '%s'", tasktype)
        return false
    end
    if not check_unit_prios(prio) then
        log:err("unknown task priority: '%s'", prio)
        return false
    end

    -- save stuff
    if not self:save_units(id, unit) then
        return false
    end

    -- create task repos and branches in them
    local git = gitmod.new(unit.id.value, unit.branch.value)
    return git:branch_create()
end

--- Get task units.
-- @param id task ID
-- @treturn table task units {{key, value}, ...}
function TaskUnit:load_units(id)
    local taskunits = {}
    local fname = globals.tmandb .. id
    local f = io.open(fname)
    local i = 1

    if not f then
        log:err("'%s': could not open task unit file", id)
        return {}
    end
    for line in f:lines() do
        local ukey, uval = string.match(line, unitregex)
        taskunits[unit_keys[i]] = { key = string.lower(ukey), value = uval }
        i = i + 1
    end
    f:close()
    return taskunits
end

--- Save task units into file.
-- @param unit units to save
-- @param fname filename to save units into
-- @param true on success, otherwise false
function TaskUnit:save_units(id, taskunits)
    local i = 1
    local fname = globals.tmandb .. id
    local f = io.open(fname, "w")

    if not f then
        log("error: could not create file note", fname)
        return false
    end

    for _, _ in pairs(unit_keys) do
        local unit = taskunits[unit_keys[i]]
        f:write(("%s: %s\n"):format(unit.key, unit.value))
        i = i + 1
    end
    f:close()
    return true
end

--- Get unit from task metadata.
-- @param id task ID
-- @param key unit key
-- @return unit value
-- @return nil if key doesn't exist
function TaskUnit:getunit(id, key)
    local taskunits = self:load_units(id)

    if not next(taskunits) or not check_unit_keys(key) then
        log:err("couldn't get unit from task ID '%s'", id)
        return nil
    end
    return taskunits[key].value
end

--- Set unit key value.
-- @param id task ID
-- @param key key to look up
-- @param value new value to set
-- @return true on success, otherwise false
function TaskUnit:setunit(id, key, value)
    local taskunits = self:load_units(id)

    if not next(taskunits) or not check_unit_keys(key) then
        log:err("couldn't set key '%s' to task ID '%s'", key, id)
        return false
    end
    taskunits[key].value = value
    return self:save_units(id, taskunits)
end

--- Show task unit metadata.
-- @param id task ID
-- @param count how many items to show (default: 4)
function TaskUnit:show(id, count)
    local i = 1
    count = count or unit_ids.basic
    local taskunits = self:load_units(id)

    for _, _ in pairs(taskunits) do
        if count == 0 then
            break
        end
        local unit = taskunits[unit_keys[i]]
        print(("%-8s: %s"):format(unit.key, unit.value))
        count = count - 1
        i = i + 1
    end
end

--- Delete task unit.
-- @param id task ID
function TaskUnit:del(id)
    local unitfile = globals.tasks .. id
    local branch = self:getunit(id, "branch")
    local git = gitmod.new(id, branch)

    git:branch_delete()
    os.remove(unitfile)
    return true
end

--- Amend task description.
-- @param id task ID
-- @param newdesc new description
-- @return true on success, otherwise false
function TaskUnit:amend_desc(id, newdesc)
    self:setunit(id, "desc", newdesc)

    local taskunits = self:load_units(id)
    if not next(taskunits) then
        log:err("task '%s' unit is empty", id)
        return false
    end

    local newbranch = format_branch(taskunits)
    self:setunit(id, "branch", newbranch)

    local git = gitmod.new(id, newbranch)
    return git:branch_rename(newbranch)
end

--- Chaneg task ID.
-- @param id current task ID
-- @param newid new ID
function TaskUnit:amend_id(id, newid)
    local old_taskdir = globals.tasks .. id
    local new_taskdir = globals.tasks .. newid

    self:setunit(id, "id", newid)
    local taskunits = self:load_units(id)

    if not next(taskunits) then
        log:err("task '%s' unit is empty", id)
        return false
    end

    local newbranch = format_branch(taskunits)
    self:setunit(id, "branch", newbranch)

    local git = gitmod.new(id, newbranch)
    git:branch_rename(newbranch)

    -- rename task folder
    local cmd = ("mv %s %s"):format(old_taskdir, new_taskdir)
    os.execute(cmd)

    -- rename task ID file in .tman
    local old_file_task = globals.tmandb .. id
    local new_file_task = globals.tmandb .. newid
    local cmd_db = ("mv %s %s"):format(old_file_task, new_file_task)
    return os.execute(cmd_db)
end

--- Change task priority.
-- @param id task ID
-- @param newprio new task priority
function TaskUnit:amend_prio(id, newprio)
    local key = "prio"

    if not check_unit_prios(newprio) then
        log:err("task priority '%s' does not exist", newprio)
        return false
    end
    return self:setunit(id, key, newprio)
end

return TaskUnit
