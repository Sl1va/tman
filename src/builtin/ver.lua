local help = require("core.help")

local function builtin_ver()
    print(("%s version %s"):format(help.progname, help.version))
end

return builtin_ver
