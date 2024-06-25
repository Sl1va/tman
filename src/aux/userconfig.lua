--- Module to parse, check and load user config.
-- @module userconfig

local main_user_config = require("tman_conf")

local userconfig = {}

--function userconfig.init(fname) end

function userconfig.getvars()
    return {
        repos = main_user_config.repos,
        struct = main_user_config.struct,
        branchpatt = main_user_config.branchpatt,
    }
end

return userconfig
