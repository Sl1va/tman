--- Operate on task unit inside meta data.
-- Metadata like branch name, date, description and so on.
-- @module TaskUnit

local gitmod = require("misc/git")
local log = require("misc/log").init("taskunit")
local config = require("config")
local utils = require("aux/utils")

--- FIXME: If description has a colon (:) in itself this regex causes problems
local unitregex = "(%w*): (.*)"

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
    -- "link",
    -- "linked",

    "time",
    "date",
    "status",
    "branch",
}

-- Private functions: end --

local function get_input(prompt)
    io.write(prompt, ": ")
    return io.read("*line")
end

--- String separator.
-- @param inputstr input string
-- @param sep separator
-- @return table op tokens
local function pattsplit(inputstr, sep)
    local res = {}

    if sep == nil then
        sep = "%s"
    end
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(res, str)
    end
    return res
end

--- Check branch pattern is valid.
-- @param task task unit
-- @return true on success, otherwise false
local function check_branchpatt(items)
    local separators = "/_-"
    local sepcomponents = pattsplit(config.branchpatt, separators)
    local branch = config.branchpatt

    -- roachme: it should be somewhere else:
    -- HOTFIX: corrently transform description
    items.desc.value = string.gsub(items.desc.value, " ", "_")

    for _, item in pairs(sepcomponents) do
        if not items[string.lower(item)] then
            local errmsg = "error: branch formatiton: unknown pattern '%s'\n"
            io.stderr:write(errmsg:format(item))
            return false
        end
    end
    return true
end

--- Form branch according to pattern.
-- @param task task unit
local function format_branch(items)
    local separators = "/_-"
    local sepcomponents = pattsplit(config.branchpatt, separators)
    local branch = config.branchpatt

    -- roachme: it should be somewhere else:
    -- HOTFIX: corrently transform description
    items.desc.value = string.gsub(items.desc.value, " ", "_")

    for _, item in pairs(sepcomponents) do
        if not items[string.lower(item)] then
            local errmsg = "error: branch formatiton: unknown pattern '%s'\n"
            io.stderr:write(errmsg:format(item))
            return nil
        end
        branch = string.gsub(branch, item, items[string.lower(item)].value)
    end
    return branch
end

--- Check that user specified task type exists.
-- @tparam string type user specified type
-- @treturn bool true if exists, otherwise false
local function check_tasktype(type)
    local tasktypes = { "bugfix", "feature", "hotfix" }

    for _, dtype in pairs(tasktypes) do
        if type == dtype then
            return true
        end
    end
    return false
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

--- Get task units.
-- @param id task ID
-- @treturn table task units {{key, value}, ...}
local function load_units(id)
    local taskunits = {}
    local fname = config.ids .. id
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
-- @param id task ID
-- @param taskunits task units to save
-- @return true on success, otherwise false
local function save_units(id, taskunits)
    local i = 1
    local fname = config.ids .. id
    local f = io.open(fname, "w")

    if not f then
        log:err("could not create file note", fname)
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

-- Private functions: end --

-- Public functions: start --

--- Add a new unit for a task.
-- @param id task id
-- @param tasktype task type: bugfix, hotfix, feature
-- @param prio task priority
local function taskunit_add(id, tasktype, prio)
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

    if not check_branchpatt(unit) then
        return false
    end

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
    if not save_units(id, unit) then
        return false
    end
    return true
end

--- Get unit from task metadata.
-- @param id task ID
-- @param key unit key
-- @return unit value
-- @return nil if key doesn't exist
local function taskunit_getunit(id, key)
    local taskunits = load_units(id)

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
local function taskunit_setunit(id, key, value)
    local taskunits = load_units(id)

    if not next(taskunits) or not check_unit_keys(key) then
        log:err("couldn't set key '%s' to task ID '%s'", key, id)
        return false
    end
    taskunits[key].value = value
    return save_units(id, taskunits)
end

--- Show task unit metadata.
-- @param id task ID
-- @param count how many items to show (default: 4)
local function taskunit_show(id, count)
    local i = 1
    local taskunits = load_units(id)
    count = count or unit_ids.basic

    for _, _ in pairs(taskunits) do
        if i > count then
            break
        end
        local unit = taskunits[unit_keys[i]]
        print(("%-8s: %s"):format(unit.key, unit.value))
        i = i + 1
    end
end

--- Delete task unit.
-- @param id task ID
local function taskunit_del(id)
    local unitfile = config.ids .. id
    return utils.rm(unitfile)
end

--- Amend task description.
-- @param id task ID
-- @param newdesc new description
-- @return true on success, otherwise false
local function taskunt_amend_desc(id, newdesc)
    taskunit_setunit(id, "desc", newdesc)

    local taskunits = load_units(id)
    if not next(taskunits) then
        log:err("task '%s' unit is empty", id)
        return false
    end
    if not check_branchpatt(taskunits) then
        return false
    end

    local newbranch = format_branch(taskunits)
    taskunit_setunit(id, "branch", newbranch)

    local git = gitmod.new(id, newbranch)
    return git:branch_rename(newbranch)
end

--- Amend (add) link to work task manager.
-- @param id task ID
-- @param newlink link the task
local function taskunit_amend_link(id, newlink)
    print("under development")
end

--- Chaneg task ID.
-- @param id current task ID
-- @param newid new ID
local function taskunit_amend_id(id, newid)
    local old_taskdir = config.taskbase .. id
    local new_taskdir = config.taskbase .. newid

    taskunit_setunit(id, "id", newid)
    local taskunits = load_units(id)

    if not next(taskunits) then
        log:err("task '%s' unit is empty", id)
        return false
    end
    if not check_branchpatt(taskunits) then
        return false
    end

    local newbranch = format_branch(taskunits)
    taskunit_setunit(id, "branch", newbranch)

    local git = gitmod.new(id, newbranch)
    git:branch_rename(newbranch)

    -- rename task folder
    local cmd = ("mv %s %s"):format(old_taskdir, new_taskdir)
    os.execute(cmd)

    -- rename task ID file in .tman
    local old_file_task = config.ids .. id
    local new_file_task = config.ids .. newid
    return utils.rename(old_file_task, new_file_task)
end

--- Change task priority.
-- @param id task ID
-- @param newprio new task priority
local function taskunit_amend_prio(id, newprio)
    local key = "prio"

    if not check_unit_prios(newprio) then
        log:err("task priority '%s' does not exist", newprio)
        return false
    end
    return taskunit_setunit(id, key, newprio)
end

-- Public functions: end --

return {
    add = taskunit_add,
    del = taskunit_del,
    show = taskunit_show,
    getunit = taskunit_getunit,
    setunit = taskunit_setunit,
    amend_id = taskunit_amend_id,
    amend_desc = taskunt_amend_desc,
    amend_prio = taskunit_amend_prio,
    amend_link = taskunit_amend_link,
}
