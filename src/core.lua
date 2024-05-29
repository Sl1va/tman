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
    utils.touch(config.initfile)
    print("tman: core structure inited")
end

--- Check tman dir ain't corrupted and exists.
-- @return true on success, otherwise false
local function core_check()
    local files = {
        config.taskids,
        config.initfile,
    }
    local dirs = {
        config.ids,
        config.tmanbase,
        config.taskbase,
        config.codebase,
    }

    if not utils.access(config.initfile) then
        return 1
    end

    for _, dir in pairs(dirs) do
        if not utils.access(dir) then
            return 2
        end
    end
    for _, file in pairs(files) do
        if not utils.access(file) then
            return 2
        end
    end
    return 0
end

local function core_repair()
end


return {
    init = core_init,
    check = core_check,
    repair = core_repair,
}
