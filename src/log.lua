local Log = {}
Log.__index = Log

-- roachme: make log message more appealing

function Log.init(prefix)
    local self = setmetatable({
        prefix = prefix,
    }, Log)
    return self
end

--- Log normal message.
-- @param fmt format message
-- @param ... vararg
function Log:log(fmt, ...)
    print(self.prefix .. ": " .. fmt:format(...))
end

--- Log error message.
-- @param fmt format message
-- @param ... vararg
function Log:err(fmt, ...)
    print(self.prefix .. ":error: " .. fmt:format(...))
end

--- Log debug message.
-- @param fmt format message
-- @param ... vararg
function Log:warning(fmt, ...)
    print(self.prefix .. ":warning: " .. fmt:format(...))
end

--- Log debug message.
-- @param fmt format message
-- @param ... vararg
function Log:debug(fmt, ...)
    print(self.prefix .. ":debug: " .. fmt:format(...))
end

return Log
