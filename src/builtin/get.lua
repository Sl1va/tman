local env = require("core.env")
local taskid = require("core.taskid")
local common = require("core.common")

--- Get tman items.
-- Like prev/ curr task ID, etc.
local function builtin_get()
    local item = arg[1] or "curr"

    if item == "curr" then
        print(taskid.getcurr() or "")
        return 0
    elseif item == "prev" then
        print(taskid.getprev() or "")
        return 0
    elseif item == "env" then
        print(env.getprev() or "")
        return 0
    end

    -- error handling
    common.die(1, "no such task item\n", item)
end

return builtin_get
