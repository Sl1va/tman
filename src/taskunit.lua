--- Operate on task unit inside meta data.
-- Metadata like branch name, date, description and so on.
-- @module TaskUnit

local log = require("misc.log").init("taskunit")
local config = require("config")
local utils = require("aux.utils")
local unit = require("aux.unit")

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
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(res, str)
    end
    return res
end

--- Form branch according to pattern.
-- @param items task unit
-- @return branch name if branch pattern is valid
-- @return nil if branch pattern isn't valid
local function format_branch(items)
    local separators = "/_-"
    local sepcomponents = pattsplit(config.branchpatt, separators)
    local branch = config.branchpatt

    -- roachme: it should be somewhere else:
    -- HOTFIX: corrently transform description
    items.desc = string.gsub(items.desc, " ", "_")

    -- roachme: use unit.get() to retrieve keys and values
    for _, item in pairs(sepcomponents) do
        if not items[string.lower(item)] then
            local errmsg = "error: branch formatiton: unknown pattern '%s'\n"
            io.stderr:write(errmsg:format(item))
            return nil
        end
        branch = string.gsub(branch, item, items[string.lower(item)])
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
    for _, prio in pairs(unit.prios) do
        if prio == priority then
            return true
        end
    end
    return false
end

-- Private functions: end --

-- Public functions: start --

--- Add a new unit for a task.
-- @param id task id
-- @param tasktype task type: bugfix, hotfix, feature
-- @param prio task priority
local function taskunit_add(id, tasktype, prio)
    local desc = get_input("Desc")
    prio = prio or unit.prios.mid
    unit.init(config.ids .. id)

    unit.set("id", id)
    unit.set("prio", prio)
    unit.set("type", tasktype)
    unit.set("desc", desc)

    unit.set("time", "N/A")
    unit.set("date", os.date("%Y%m%d"))
    unit.set("status", "progress")

    -- roachme: looks a bit messy to me. Outta fix it.
    unit.set(
        "branch",
        format_branch({
            type = tasktype,
            id = id,
            desc = desc,
            date = unit.get("date"),
        })
    )

    if not unit.get("branch") then
        log:err("branch pattern isn't valid", config.branchpatt)
        return false
    end
    if not check_tasktype(tasktype) then
        log:err("unknown task type: '%s'", tasktype)
        return false
    end
    if not check_unit_prios(prio) then
        log:err("unknown task priority: '%s'", prio)
        return false
    end
    return unit.save()
end

--- Get unit from task metadata.
-- @param id task ID
-- @param key unit key
-- @return unit value
-- @return nil if key doesn't exist
local function taskunit_getunit(id, key)
    unit.init(config.ids .. id)
    return unit.get(key)
end

--- Set unit key value.
-- @param id task ID
-- @param key key to look up
-- @param value new value to set
-- @return true on success, otherwise false
local function taskunit_setunit(id, key, value)
    unit.init(config.ids .. id)
    return unit.set(key, value)
end

--- Show task unit metadata.
-- @param id task ID
-- @param key show only that key
-- @return true on success
local function taskunit_show(id, key)
    unit.init(config.ids .. id)

    if key then
        -- use defval for backward compatibility with old tasks
        print(("> %-8s: %s"):format(key, unit.get(key) or unit.defval))
        return true
    end

    for _, ukey in pairs(unit.keys) do
        -- use defval for backward compatibility with old tasks
        print(("%-8s: %s"):format(ukey, unit.get(ukey) or unit.defval))
    end
    return true
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
    unit.init(config.ids .. id)
    unit.set("desc", newdesc)

    -- roachme: looks a bit messy to me. Outta fix it.
    unit.set(
        "branch",
        format_branch({
            id = unit.get("id"),
            type = unit.get("type"),
            desc = unit.get("desc"),
            date = unit.get("date"),
        })
    )
    return unit.save()
end

--- Chaneg task ID.
-- @param id current task ID
-- @param newid new ID
local function taskunit_amend_id(id, newid)
    -- roachme: TOO BUGGY
    -- also gotta move git logic from here
    local old_taskdir = config.taskbase .. id
    local new_taskdir = config.taskbase .. newid

    unit.init(config.ids .. id)

    unit.set("id", newid)
    -- roachme: looks a bit messy to me. Outta fix it.
    unit.set(
        "branch",
        format_branch({
            id = unit.get("id"),
            type = unit.get("type"),
            desc = unit.get("desc"),
            date = unit.get("date"),
        })
    )
    unit.save()

    -- rename task dir
    -- roachme: it's fregile: utils.rename() doesn't work.
    utils.rename(old_taskdir, new_taskdir)

    -- rename task ID file in .tman
    -- roachme: struct.lua should've done that
    utils.rename(config.ids .. id, config.ids .. newid)
    return true
end

--- Change task priority.
-- @param id task ID
-- @param newprio new task priority
local function taskunit_amend_prio(id, newprio)
    unit.init(config.ids .. id)

    if not check_unit_prios(newprio) then
        log:err("task priority '%s' does not exist", newprio)
        return false
    end
    unit.set("prio", newprio)
    return unit.save()
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
}
