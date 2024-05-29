--- Tman core module to to init, check and repair itself.
-- @module core

local utils = require("aux/utils")
local config = require("config")


--- Init system to use a util.
local function core_init()
    -- dirs
    utils.mkdir(config.ids)
    utils.mkdir(config.tmanbase)
    utils.mkdir(config.taskbase)
    utils.mkdir(config.codebase)

    -- files
    utils.touch(config.taskids)
    print("tman: core structure inited")
end

--- Check tman dir ain't corrupted and exists.
-- @return true on success, otherwise false
local function core_check()
    local files = {
        config.taskids,
    }
    local dirs = {
        config.ids,
        config.tmanbase,
        config.taskbase,
        config.codebase,
    }

    for _, dir in pairs(dirs) do
        if not utils.access(dir) then
            return false
        end
    end
    for _, file in pairs(files) do
        if not utils.access(file) then
            return false
        end
    end
    return true
end

local function core_repair()
end


return {
    init = core_init,
    check = core_check,
    repair = core_repair,
}
