--- Parse config file and provide env for the rest of the code.

local userhome = os.getenv("HOME")
local fconfig = nil         -- config file


--[[
tman.conf:
    TMANDIR="~/work/tman"
]]

return {
    base = "~/work/tman",
    debug = true,
}
