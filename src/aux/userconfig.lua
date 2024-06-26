--- Module to parse, check and load user config.
-- @module userconfig

local main_user_config = require("tman_conf")

local userconfig = {}

local defualt_branchpatt = "TYPE/ID_DESC_DATE"
local default_struct = {
    dirs = {},
    files = {},
}
local default_repos = {}

--function userconfig.init(fname) end

function userconfig.getvars()
    return {
        repos = main_user_config.repos or default_repos,
        struct = main_user_config.struct or default_struct,
        branchpatt = main_user_config.branchpatt or defualt_branchpatt,
    }
end

return userconfig
