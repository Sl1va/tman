local env = require("core.env")
local taskid = require("core.taskid")
local common = require("core.common")
local help = require("core.help")
local getopt = require("posix.unistd").getopt

--- List all task IDs.
-- Default: show only active task IDs.
local function builtin_list()
    local cmdname = "list"
    local active = true
    local completed = false
    local optstring = "Aaech"
    local keyhelp
    local envname = env.getcurr()

    for optopt, _, optind in getopt(arg, optstring) do
        if optopt == "?" then
            common.die(1, "unrecognized option\n", arg[optind - 1])
        end

        if optopt == "A" then
            active = true
            completed = true
        elseif optopt == "a" then
            active = true
            completed = false
        elseif optopt == "c" then
            active = false
            completed = true
        elseif optopt == "h" then
            keyhelp = true
        end
    end

    if keyhelp then
        help.usage(cmdname)
        return 0
    end

    -- output header.
    print(("Current env: %s"):format(envname))
    if active == true and completed == true then
        print("All tasks:")
    elseif active == true and completed == false then
        print("Active tasks:")
    elseif active == false and completed == true then
        print("Completed tasks:")
    end

    taskid.list(active, completed)
    return 0
end

return builtin_list
