local envfile
local myenvdb = {}
local envdbregex = "(.*) (.*): (.*)"
local envdbfmt = "%d %s: %s\n"
local env_def_name = "work"
--local def_envdesc = "no description"

local statuses = {
    CURR = 0,
    PREV = 1,
    ACTV = 2,
}

local function _envdb_load()
    myenvdb = {}
    local f = io.open(envfile)

    if not f then
        return false
    end
    for line in f:lines() do
        local stat, name, desc = string.match(line, envdbregex)
        table.insert(
            myenvdb,
            { status = tonumber(stat), name = name, desc = desc }
        )
    end
    return f:close()
end

local function _envdb_save()
    local f = io.open(envfile, "w")

    if not f then
        return false
    end

    for _, item in pairs(myenvdb) do
        f:write(envdbfmt:format(item.status, item.name, item.desc))
    end
    return f:close()
end

local function envdb_init(fname)
    envfile = fname
    if not envfile or envfile == "" then
        return false
    end
    return _envdb_load()
end

local function envdb_exists(name)
    if not name then
        return false
    end
    for _, item in pairs(myenvdb) do
        if item.name == name then
            return true
        end
    end
    return false
end

local function envdb_size()
    local size = 0

    for _, _ in pairs(myenvdb) do
        size = size + 1
    end
    return size
end

local function envdb_get(name)
    for _, item in pairs(myenvdb) do
        if item.name == name then
            return { status = item.status, name = item.name, desc = item.desc }
        end
    end
    return {}
end

local function envdb_getidx(idx)
    local item = myenvdb[idx]
    if not item then
        return {}
    end
    return { status = item.status, name = item.name, desc = item.desc }
end

local function unset_curr()
    for _, item in pairs(myenvdb) do
        if item.status == statuses.CURR then
            item.status = statuses.ACTV
        end
    end
end

local function envdb_setcurr(name, desc)
    if envdb_exists(name) then
        return false
    end
    unset_curr()
    for _, item in pairs(myenvdb) do
        if item.name == name then
            item.name = name
            item.desc = desc
            return _envdb_save()
        end
    end
    return false
end

local function envdb_getcurr()
    for _, item in pairs(myenvdb) do
        print(item.name)
        if item.status == statuses.CURR then
            return item.name
        end
    end
    print("envdb: return default env name")
    return env_def_name
end

local function envdb_add(name, desc)
    if envdb_exists(name) then
        return false
    end
    unset_curr()
    table.insert(myenvdb, { status = statuses.CURR, name = name, desc = desc })
    return _envdb_save()
end

local function envdb_del(name)
    if not envdb_exists(name) then
        return false
    end
    for i, item in pairs(myenvdb) do
        if item.name == name then
            table.remove(myenvdb, i)
            break
        end
    end
    return _envdb_save()
end

local function envdb_set(name, status)
    for i, item in pairs(myenvdb) do
        if item.name == name then
            item.status = status
            return _envdb_save()
        end
    end
    return false
end

return {
    init = envdb_init,
    size = envdb_size,

    get = envdb_get,
    getix = envdb_getidx,

    add = envdb_add,
    del = envdb_del,

    setcurr = envdb_setcurr,
    getcurr = envdb_getcurr,

    set = envdb_set,
    getidx = envdb_getidx,
    exists = envdb_exists,
}
