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

local function util_rename(oldname, newname)
    if not oldname then
        print("util:rename:error: no oldname")
        return false
    end
    if not newname then
        print("util:rename:error: no newname")
        return false
    end
    return os.execute(("mv %s %s"):format(oldname, newname))
end

local function util_exec(cmd)
    return os.execute(cmd)
end


return {
    rm = remove_dir,
    link = create_symlink,
    exec = util_exec,
    mkdir = create_dir,
    touch = create_file,
    access = file_exists,
    rename = util_rename,
}
