--- Operate on task unit inside meta data.
-- Metadata like branch name, date, description and so on.
-- @module TaskUnit

local log = require("misc.log").init("taskunit")
local config = require("misc.config")
local utils = require("aux.utils")
local unit = require("aux.unit")

local taskunit = {}

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
-- @return branch name if branch pattern is valid
-- @return nil if branch pattern isn't valid
local function format_branch()
    local separators = "/_-"
    local sepcomponents = pattsplit(config.branchpatt, separators)
    local branch = config.branchpatt

    for _, item in pairs(sepcomponents) do
        local uitem = unit.get(string.lower(item))

        if not uitem then
            local errmsg = "error: branch formatiton: '%s': unit not found\n"
            io.stderr:write(errmsg:format(item))
            return nil
        end

        -- roachme: HOTFIX: desc: replace whitespace with undrescore
        if item == "DESC" then
            uitem = string.gsub(uitem, " ", "_")
        end
        branch = string.gsub(branch, item, uitem)
    end
    return branch
end

--- Check that task ID has no illegal symbols.
-- @param id task ID
-- @return on success - true
-- @return on failure - false
local function _check_id(id)
    local descregex = "[a-zA-Z0-9_%s-]*"
    if string.match(id, descregex) == id then
        return true
    end
    return false
end

--- Check that description has no illegal symbols.
-- @param desc description
-- @return on success - true
-- @return on failure - false
local function _check_desc(desc)
    local descregex = "[a-zA-Z0-9_%s-]*"
    if string.match(desc, descregex) == desc then
        return true
    end
    return false
end

--- Check that priority exists.
-- @param priority priority to check
-- @return true on success, otherwise false
local function _check_prio(priority)
    for _, prio in pairs(unit.prios) do
        if prio == priority then
            return true
        end
    end
    return false
end

--- Check that user specified task type exists.
-- @tparam string type user specified type
-- @treturn bool true if exists, otherwise false
local function _check_type(type)
    local tasktypes = { "bugfix", "feature", "hotfix" }

    -- roachme: gotta delete this check cuz algorithm takes it into account.
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

--- Amend task description.
-- @param id task ID
-- @param newdesc new description
-- @return on success - true
-- @return on failure - false
local function _set_desc(id, newdesc)
    unit.init(config.units .. id)
    unit.set("desc", newdesc)
    unit.set("branch", format_branch())
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

    if not _check_id(newid) then
        return false
    end

    unit.init(config.units .. id)
    unit.set("id", newid)
    unit.set("branch", format_branch())
    unit.save()
    return utils.rename(old_taskdir, new_taskdir)
end

--- Change task type.
-- @return on success - true
-- @return on failure - false
local function _set_type(id, newtype)
    if not _check_type(newtype) then
        return false
    end

    unit.init(config.units .. id)
    unit.set("type", newtype)
    unit.set("branch", format_branch())
    return unit.save()
end

--- Change task priority.
-- @param id task ID
-- @param newprio new task priority
-- @return on success - true
-- @return on failure - false
local function _set_prio(id, newprio)
    unit.init(config.units .. id)

    if not _check_prio(newprio) then
        return false
    end
    unit.set("prio", newprio)
    return unit.save()
end

--- Change task link to work task manager.
-- @return on success - true
-- @return on failure - false
local function _set_link(id, newlink)
    unit.init(config.units .. id)

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

    unit.init(config.units .. id)
    unit.set("repos", res)
    return unit.save()
end

-- Private functions: end --

-- Public functions: start --

--- Add a new unit for a task.
-- @param id task id
-- @param tasktype task type: bugfix, hotfix, feature
-- @param prio task priority
function taskunit.add(id, tasktype, prio)
    local desc = get_input("Desc")
    prio = prio or unit.prios.mid
    unit.init(config.units .. id)

    unit.set("id", id)
    unit.set("prio", prio)
    unit.set("type", tasktype)
    unit.set("desc", desc)

    --unit.set("time", "N/A")
    unit.set("date", os.date("%Y%m%d"))
    unit.set("status", "progress")
    unit.set("branch", format_branch())

    if not _check_id(id) then
        log:err("task ID isn't valid", config.branchpatt)
        return false
    end
    if not _check_desc(desc) then
        log:err("description isn't valid", config.branchpatt)
        return false
    end
    if not unit.get("branch") then
        log:err("branch pattern isn't valid", config.branchpatt)
        return false
    end
    if not _check_type(tasktype) then
        log:err("unknown task type: '%s'", tasktype)
        return false
    end
    if not _check_prio(prio) then
        log:err("unknown task priority: '%s'", prio)
        return false
    end
    return unit.save()
end

--- Delete task unit.
-- @param id task ID
function taskunit.del(id)
    local unitfile = config.units .. id
    return utils.rm(unitfile)
end

--- Show task unit metadata.
-- @param id task ID
-- @param key show only that key
-- @return true on success
function taskunit.cat(id, key)
    local defval = "N/A"
    unit.init(config.units .. id)

    -- output only key value
    if key then
        for _, ukey in pairs(unit.keys) do
            if ukey == key then
                print(unit.get(key) or defval)
                return true
            end
        end
        return false
    end

    -- output all key values
    for _, ukey in pairs(unit.keys) do
        local value = unit.get(ukey) or defval
        print(("%-8s: %s"):format(ukey, value))
    end
    return true
end

--- Get unit from task metadata.
-- @param id task ID
-- @param key unit key
-- @return on success - return actial value
-- @return on failure - return default value ("N/A")
function taskunit.get(id, key)
    unit.init(config.units .. id)
    return unit.get(key)
end

--- Set unit key value.
-- Update related units as well.
-- @param id task ID
-- @param key key to look up
-- @param value new value to set
-- @return on success - true
-- @return on failure - false
function taskunit.set(id, key, value)
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
    return false
end

--- Check task units.
-- @param key unit key
-- @param value unit value to check
-- @return on success - true
-- @return on failure - false
function taskunit.check(key, value)
    if key == "id" then
        return _check_id(value)
    elseif key == "desc" then
        return _check_desc(value)
    elseif key == "prio" then
        return _check_prio(value)
    elseif key == "type" then
        return _check_type(value)
    end
    return false
end

-- Public functions: end --

return taskunit
