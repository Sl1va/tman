--- Operate on task unit inside meta data.
-- Metadata like branch name, date, description and so on.
-- @module TaskUnit

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

local function _check_link(link)
    local linkregex = "[a-zA-Z0-9_%s-:/.]*"
    link = link or "" -- roachme: find a better way.

    if string.match(link, linkregex) == link then
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

--- Change task ID.
-- @param id current task ID
-- @param newid new ID
-- @return on success - true
-- @return on failure - false
local function _set_id(id, newid)
    local old_taskdir = config.taskbase .. id
    local new_taskdir = config.taskbase .. newid

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
    local repos = table.concat(taskrepos, " ")

    unit.init(config.units .. id)
    unit.set("repos", repos)
    return unit.save()
end

-- Private functions: end --

-- Public functions: start --

--- Check task units.
-- @param key unit key
-- @param value unit value to check
-- @return on success - true
-- @return on failure - false
function taskunit.check(key, value)
    local params = {
        id = _check_id,
        desc = _check_desc,
        prio = _check_prio,
        type = _check_type,
        link = _check_link,
        branch = function(val)
            return not (val == nil or val == "")
        end,
        status = function(val)
            return not (val == nil or val == "")
        end,
        date = function(val)
            return not (val == nil or val == "")
        end,

        -- roachme: under development.
        time = function()
            return true
        end,
        repos = function()
            return true
        end,
    }

    -- Check a key-value pair.
    for name, func in pairs(params) do
        if name == key then
            return func(value)
        end
    end

    -- Unknown key, return false.
    return false
end

--- Add a new unit for a task.
-- @param id task id
-- @param tasktype task type: bugfix, hotfix, feature
-- @param prio task priority
function taskunit.add(id, tasktype, prio)
    local desc = get_input("Desc")
    prio = prio or unit.prios.mid

    -- Set values.
    unit.init(config.units .. id)
    unit.set("id", id)
    unit.set("prio", prio)
    unit.set("type", tasktype)
    unit.set("desc", desc)
    --unit.set("time", "N/A")
    --unit.set("link", "N/A")
    --unit.set("repos", "N/A")
    unit.set("date", os.date("%Y%m%d"))
    unit.set("status", "progress")
    unit.set("branch", format_branch())

    -- Check input values for validity.
    for _, ukey in pairs(unit.keys) do
        local value = unit.get(ukey)
        if not taskunit.check(ukey, value) then
            return false
        end
    end

    -- Save values into the database.
    return unit.save()
end

--- Set unit key value.
-- Update related units as well.
-- @param id task ID
-- @param key key to look up
-- @param value new value to set
-- @return on success - true
-- @return on failure - false
function taskunit.set(id, key, value)
    if key == "desc" then
        return _set_desc(id, value)
    elseif key == "id" then
        return _set_id(id, value)
    elseif key == "link" then
        return _set_link(id, value)
    elseif key == "prio" then
        return _set_prio(id, value)
    elseif key == "repo" then
        return _set_repo(id, value)
    elseif key == "type" then
        return _set_type(id, value)
    end
    return false
end

--- Delete task unit.
---@param id string
---@return boolean
function taskunit.del(id)
    local unitfile = config.units .. id
    return utils.rm(unitfile)
end

--- Get unit from task metadata.
-- @param id task ID
-- @param key unit key
-- @return on success - value
-- @return on failure - nil
function taskunit.get(id, key)
    unit.init(config.units .. id)
    return unit.get(key)
end

--- Show task unit metadata.
-- @param id task ID
-- @param key show only that key
-- @return true on success
function taskunit.cat(id, key)
    unit.init(config.units .. id)

    -- output only key value
    if key then
        for _, ukey in pairs(unit.keys) do
            if ukey == key then
                local uval = unit.get(key)
                io.write(("%s"):format(uval and uval .. "\n" or ""))
                return true
            end
        end
        return false
    end

    -- output all key values
    for _, ukey in pairs(unit.keys) do
        local value = unit.get(ukey) or ""
        print(("%-8s: %s"):format(ukey, value))
    end
    return true
end

-- Public functions: end --

return taskunit
