--- Parse config file and provide env for the rest of the code.
-- @module config

local log = require("misc/log").init("config")
local utils = require("aux/utils")
local readconf = require("aux/readconf")


local userhome = os.getenv("HOME")
local file_tman_config = nil
local file_tman_repos = nil

-- Default places to search config file.
local tman_config_dir = {
    "/.tman/",
    "/.config/tman/",
}


--- Search config file.
-- @return true if found, otherwise false
local function search_config_file(file)
    for _, confile in pairs(tman_config_dir) do
        confile = userhome .. "/" .. confile .. file
        if utils.access(confile) then
            return confile
        end
    end
    return nil
end

-- TODO: where should `tman` look for config file?
file_tman_config = search_config_file("config")
file_tman_repos = search_config_file("repos")

if not file_tman_config then
    log:err("config file not found")
    os.exit(1)
end

if not file_tman_repos then
    log:err("repos file not found")
    os.exit(1)
end



readconf.init(file_tman_config)
local configvars = readconf.parse()

local function load_repos()
    local repos = {}
    local f = io.open(file_tman_repos)

    if not f then
        log:err("couldn't open repos file")
        return repos
    end
    for line in f:lines() do
        local name, branch, path = string.match(line, "(.*),(.*),(.*)")
        -- roachme: maybe it's better to leave path as nil
        table.insert(repos, { name = name, branch = branch, path = path or "" })
    end
    return repos
end



-- tman main dirs
local _base = configvars.base .. "/"
local _tmanbase = _base .. ".tman/"
local _codebase = _base .. "codebase/"
local _taskbase = _base .. "tasks/"
local _ids = _tmanbase .. "ids/"
local _taskids = _tmanbase .. "taskids"

return {
    -- files
    repos = load_repos(),
    repo_file = file_tman_repos,
    taskids = _taskids,

    -- dirs
    tmanbase = _tmanbase,
    codebase = _codebase,
    taskbase = _taskbase,
    ids = _ids,

    -- util flags to change behavior
    debug = true,
}
