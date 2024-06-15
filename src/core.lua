--- Tman core module to to init, check and repair itself.
-- @module core

local utils = require("aux.utils")
local config = require("misc.config")
local git = require("git")

--- Init system to use a util.
local function core_init()
    -- dirs
    utils.mkdir(config.units)
    utils.mkdir(config.tmanbase)
    utils.mkdir(config.taskbase)
    utils.mkdir(config.codebase)

    -- files
    utils.touch(config.taskids)
    utils.touch(config.tmanconf)

    -- download repos
    git.repo_clone()
end

--- Check tman dir ain't corrupted and exists.
-- @return true on success, otherwise false
local function core_check()
    -- roachme:
    -- return 1: tman core stuff are corrupted
    -- retrun 2: tman base stuff are corrupted
    -- NOT dirs / files
    local files = {
        config.taskids,
        config.tmanconf,
    }
    local dirs = {
        config.units,
        config.tmanbase,
        config.taskbase,
        config.codebase,
    }

    for _, dir in pairs(dirs) do
        if not utils.access(dir) then
            return 1
        end
    end
    for _, file in pairs(files) do
        if not utils.access(file) then
            return 1
        end
    end
    return 0
end

local function core_repair() end

local function core_show_config()
    print("base", config.base)
    print("install", config.install)
    print("brpanchpatt", config.branchpatt)
    io.write("struct dirs: { ")
    for _, dir in pairs(config.struct.dirs) do
        io.write(dir, " ")
    end
    print("}")
    io.write("struct files: { ")
    for _, file in pairs(config.struct.files) do
        io.write(file, " ")
    end
    print("}")

    print("repos: {")
    for _, item in pairs(config.repos) do
        print("  {", item.name, item.branch, item.path or "", "}")
    end
    print("}")
end

--- Backup data.
-- @param fname archive filename (default extention is .tar)
-- @param repo_included whether or not include repos in archive
-- @return on success - true
-- @return on failure - false
local function core_backup(fname, repo_included)
    -- roachme: run git gc before including repos in archive so it takes less place.
    -- roachme: Replace codebase with value from config
    local cmd

    if repo_included then
        cmd = ("tar -C %s -czf %s.tar ."):format(config.base, fname)
    else
        cmd = ("tar -C %s --exclude=codebase -czf %s.tar ."):format(
            config.base,
            fname
        )
    end
    return utils.exec(cmd)
end

--- Restore archive.
-- @param fname archive fname
-- @return on success - true
-- @return on failure - false
local function core_restore(fname)
    local cmd = ("tar -xf %s -C %s"):format(fname, config.base)

    if not utils.access(fname) then
        io.stderr:write(("'%s': no such tar file\n"):format(fname))
        return false
    end

    print("delete current structure")
    utils.rm(config.taskbase)
    utils.rm(config.codebase)
    utils.rm(config.tmanbase)

    print("copy backup structure")
    if not utils.exec(cmd) then
        io.stderr:write("failed to execute archive command\n")
        return false
    end
    return true
end

return {
    init = core_init,
    check = core_check,
    repair = core_repair,
    showconf = core_show_config,
    backup = core_backup,
    restore = core_restore,
}
