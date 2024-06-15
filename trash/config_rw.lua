local function _config_check_key(key)
    local config_keys = {"base", "core", "install"}

    for _, k in pairs(config_keys) do
        if k == key then
            return true
        end
    end
    return false
end

local function _config_check_val()
end

local function config_read(fname)
    local res = {}
    local f = io.open(fname)

    if not f then
        return res
    end

    for line in f:lines() do
        if not string.match(line, "^#") then
            local key, val = string.match(line, "(.*)%s=%s(.*)")
            print(key, val)
            res[key] = val
        end
    end
    return res
end

local function config_write(fname, conf)
    --[[
    local f = io.open(fname, "w")
    if not f then
        return false
    end
    ]]
    for key, val in pairs(conf) do
        print(key, val)
    end
end

local function config_set(fname, key, val)
end

local fname = "/home/roach/.config/tman/sys.conf"
local res = config_read(fname)
config_write(fname, res)
