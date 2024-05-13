--- Util to read config file.
-- @module readconf


local file_config = nil

local config_vars = {
    "Base",
    "Debug",
}

local function var_exists(varname)
    for _, var in pairs(config_vars) do
        if varname == var then
            return true
        end
    end
    return false
end

local function parse(line)
    local var, val = string.match(line, "(%w*) ([a-zA-Z0-9~/]*)")

    if not var_exists(var) then
        print("no such config variable", var)
        return {}
    end
    return {var = var, val = val}
end

local function read_file(fname)
    local f = io.open(fname)
    local vars = {}

    if not f then
        print("couldn't open file", fname)
        return {}
    end

    for line in f:lines() do
        local pair = parse(line)
        if pair.var == nil or pair.val == nil then
            return vars
        end
        table.insert(vars, pair)
    end
    return vars
end

local function convert(vars)
    local res = {}

    for _, pair in pairs(vars) do
        local var = string.lower(pair.var)

        if pair.var == "Base" then
            res[var] = pair.val

        elseif pair.var == "Debug" then
            if pair.val == "true" then
                pair.val = true
            elseif pair.val == "false" then
                pair.val = false
            else
                print("error: no such option for Debug", pair.val)
                return {}
            end
            res[var] = pair.val
        end
    end
    return res
end


-- Public functions --

local function parser_init(_file_config)
    file_config = _file_config
end

local function parser_parse()
    local vars = read_file(file_config)

    vars = convert(vars)
    return vars
end

return {
    init = parser_init,
    parse = parser_parse,
}
