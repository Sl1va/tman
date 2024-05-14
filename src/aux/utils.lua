--- Platfor dependent stuff and general util functions.
-- @module utils

local posix = require("posix")

local function create_dir(dirname)
    return os.execute(("mkdir -p %s"):format(dirname))
end

local function remove_dir(dirname)
    return os.execute(("rm -rf %s"):format(dirname))
end

local function create_file(fname)
    return os.execute(("touch %s"):format(fname))
end

local function create_symlink(target, linkname, soft)
    soft = soft or true
    return posix.link(target, linkname, soft)
end

local function file_exists(fname)
    if posix.access(fname) then
        return true
    end
    return false
end

return {
    mkdir = create_dir,
    rm = remove_dir,
    touch = create_file,
    link = create_symlink,
    access = file_exists,
}
