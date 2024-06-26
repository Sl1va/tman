--- Terminal task manager.
-- Simplify workflow when working with many repos.
-- @module TMan

local core = require("core.core")
local setup = require("core.setup")
local builtin = require("core.builtin")
local help = require("core.help")

--- Util interface.
local function main()
    local cmd = arg[1] or "help"
    local corecheck = core.check()

    -- POSIX getopt() does not let permutations as GNU version.
    table.remove(arg, 1)

    setup.setup()

    -- Check that util's ok to run.
    if corecheck == 1 and cmd ~= "init" then
        io.stderr:write("tman: structure not inited\n")
        return 1
    end

    -- Call command.
    for name, func in pairs(builtin) do
        if cmd == name then
            return func()
        end
    end

    -- Command not found. Show some help.
    return help.usage(cmd)
end

os.exit(main())
