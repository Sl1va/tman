--- Operate on task unit inside meta data.
-- Metadata like branch name, date, description and so on.
-- @module TaskUnit

local log = require("misc.log").init("taskunit")
local config = require("misc.config")
local utils = require("aux.utils")
local unit = require("aux.unit")
local die = require("misc.die")

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

--- Check that description has no illegal symbols.
-- @param desc description
-- @return on success - true
-- @return on failure - false
local function check_desc(desc)
    local descregex = "[a-zA-Z0-9_%s-]*"
    if string.match(desc, descregex) == desc then
        return true
    end
    return false
end

--- Check that user specified task type exists.
-- @tparam string type user specified type
-- @treturn bool true if exists, otherwise false
local function check_tasktype(type)
    local tasktypes = { "bugfix", "feature", "hotfix" }

    if not type then
        return false
    end
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

--- Amend task description.
-- @param id task ID
-- @param newdesc new description
-- @return on success - true
-- @return on failure - false
local function _set_desc(id, newdesc)
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
-- @return on success - true
-- @return on failure - false
local function _set_id(id, newid)
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
    return utils.rename(old_taskdir, new_taskdir)
end

--- Change task type.
-- @return on success - true
-- @return on failure - false
local function _set_type(id, newtype)
    if not check_tasktype(newtype) then
        die.die(1, "invalid task type\n", newtype)
    end

    unit.init(config.ids .. id)
    unit.set("type", newtype)
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

--- Change task priority.
-- @param id task ID
-- @param newprio new task priority
-- @return on success - true
-- @return on failure - false
local function _set_prio(id, newprio)
    unit.init(config.ids .. id)

    if not check_unit_prios(newprio) then
        die.die(1, "invalid priority\n", newprio)
    end
    unit.set("prio", newprio)
    return unit.save()
end

--- Change task link to work task manager.
-- @return on success - true
-- @return on failure - false
local function _set_link(id, newlink)
    unit.init(config.ids .. id)

    unit.set("link", newlink)
    return unit.save()
end

--- Change list of repos with task commits.
-- @param id task ID
-- @param taskrepos table of active repos
-- @return on success - true
-- @return on failure - false
local function _set_repo(id, taskrepos)
    local res = "["

    for _, repo in pairs(taskrepos) do
        res = res .. " " .. repo
    end
    res = res .. " ]"

    unit.init(config.ids .. id)
    unit.set("repos", res)
    return unit.save()
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

    if not check_desc(desc) then
        log:err("description isn't valid", config.branchpatt)
        return false
    end
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

--- Delete task unit.
-- @param id task ID
local function taskunit_del(id)
    local unitfile = config.ids .. id
    return utils.rm(unitfile)
end

local function taskunit_check(key, value)
    if key == "desc" then
        return check_desc(value)
    elseif key == "prio" then
        return check_unit_prios(value)
    elseif key == "type" then
        return check_tasktype(value)
    end
    return false
end

--- Get unit from task metadata.
-- @param id task ID
-- @param key unit key
-- @return on success - return actial value
-- @return on failure - return default value ("N/A")
local function taskunit_getunit(id, key)
    unit.init(config.ids .. id)
    return unit.get(key)
end

--- Set unit key value.
-- Update related units as well.
-- @param id task ID
-- @param key key to look up
-- @param value new value to set
-- @return on success - true
-- @return on failure - false
local function taskunit_setunit(id, key, value)
    if key == string.lower("desc") then
        return _set_desc(id, value)
    elseif key == string.lower("id") then
        return _set_id(id, value)
    elseif key == string.lower("link") then
        return _set_link(id, value)
    elseif key == string.lower("prio") then
        return _set_prio(id, value)
    elseif key == string.lower("repo") then
        return _set_repo(id, value)
    elseif key == string.lower("type") then
        return _set_type(id, value)
    end
    -- set new value
    unit.init(config.ids .. id)
    unit.set(key, value)
    return unit.save()
end

--- Show task unit metadata.
-- @param id task ID
-- @param key show only that key
-- @return true on success
local function taskunit_cat(id, key)
    unit.init(config.ids .. id)

    if key then
        -- use defval for backward compatibility with old tasks
        print(("%-8s: %s"):format(key, unit.get(key) or unit.defval))
        return true
    end

    for _, ukey in pairs(unit.keys) do
        -- use defval for backward compatibility with old tasks
        print(("%-8s: %s"):format(ukey, unit.get(ukey) or unit.defval))
    end
    return true
end

-- Public functions: end --

return {
    add = taskunit_add,
    del = taskunit_del,
    cat = taskunit_cat,
    check = taskunit_check,
    getunit = taskunit_getunit,
    setunit = taskunit_setunit,
}
