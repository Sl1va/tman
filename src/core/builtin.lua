-- Module to hold all builtin commands.
-- @module builtin

local builtin = {
    add = require("builtin.add"),
    archive = require("builtin.archive"),
    cat = require("builtin.cat"),
    config = require("builtin.config"),
    del = require("builtin.del"),
    env = require("builtin.env"),
    get = require("builtin.get"),
    help = require("builtin.help"),
    init = require("builtin.init"),
    list = require("builtin.list"),
    pack = require("builtin.pack"),
    prev = require("builtin.prev"),
    set = require("builtin.set"),
    sync = require("builtin.sync"),
    use = require("builtin.use"),
    ver = require("builtin.ver"),
}

return builtin
