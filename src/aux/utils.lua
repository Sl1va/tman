--- Platfor dependent stuff and general util functions.
-- @module utils

local posix = require("posix")

--- Create directory.
-- @param dirname directory name
-- @return on success - 0
-- @return on failure - error code
local function create_dir(dirname)
    return os.execute(("mkdir -p %s"):format(dirname))
end

--- Create file/directory.
-- @param dirname directory name
-- @return on success - 0
-- @return on failure - error code
local function remove_dir(dirname)
    return os.execute(("rm -rf %s"):format(dirname))
end

--- Create file.
-- @param fname file name
-- @return on success - 0
-- @return on failure - error code
local function create_file(fname)
    return os.execute(("touch %s"):format(fname))
end

--- Create symlink.
-- @param target target
-- @param linkname link name
-- @param soft true - soft link, false - hard link (default: true)
-- @return on success - 0
-- @return on failure - error code
local function create_symlink(target, linkname, soft)
    soft = soft or true
    return posix.link(target, linkname, soft)
end

--- Check that file/directory exists.
-- @param fname file name
-- @return on success - true
-- @return on failure - false
local function file_exists(fname)
    if posix.access(fname) then
        return true
    end
    return false
end

--- Rename file/directory.
-- @param oldname old name
-- @param newname new name
-- @return on success - 0
-- @return on failure - error code
local function util_rename(oldname, newname)
    if not oldname then
        print("util:rename:error: no oldname")
        return 1
    end
    if not newname then
        print("util:rename:error: no newname")
        return 1
    end
    return os.execute(("mv %s %s"):format(oldname, newname))
end

--- Execute system command.
-- @param cmd command to execute
-- @return on success - 0
-- @return on failure - error code
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
