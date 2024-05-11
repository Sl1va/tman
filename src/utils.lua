--- Platfor dependent stuff and general util functions.
-- @module utils

local posix = require("posix")

local function create_dir(dirname)
    os.execute(("mkdir -p %s"):format(dirname))
end

local function remove_dir(dirname)
    os.execute(("rm -rf %s"):format(dirname))
end

local function create_file(fname)
    local f = io.open(fname, "w")
    if f then
        f:close()
        return true
    end
    return false
end

local function create_symlink(src, dst, opt)
    opt = opt or true
    return posix.link(src, dst, true)
end

return {
    mkdir = create_dir,
    rm = remove_dir,
    touch = create_file,
    link = create_symlink,
}
