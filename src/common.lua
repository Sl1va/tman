--- Common module for the rest of commands.
-- @module common

local git = require("git")
local help = require("misc.help")
local struct = require("struct")
local taskid = require("taskid")
local taskunit = require("taskunit")

local common = {}

function common.die(exit_code, errfmt, ...)
    local errmsg = ("%s: %s: " .. errfmt):format(help.progname, ...)
    io.stderr:write(errmsg)
    os.exit(exit_code)
end

function common.die_atomic(id, errfmt, ...)
    taskid.del(id)
    taskunit.del(id)
    git.branch_delete(id)
    struct.delete(id)
    common.die(1, errfmt, ...)
end

return common
