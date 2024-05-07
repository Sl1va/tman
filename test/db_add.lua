local db = require("../src/db")
local file_taskids = "test/taskids_add"

local function add_clean()
    os.remove(file_taskids)
end

local function table_size(tab)
    local size = 0

    for _, _ in pairs(tab) do
        size = size + 1
    end
    return size
end

local function add_single(taskid, status)
    local res = db.add(taskid, status)
    if res ~= nil then
        return true
    end
    return false
end

local function add_multiple()
    local taskids = {"DE-1", "DE-2", "DE-3", "DE-4"}
    local statuses = {2, 2, 2, 2}
    local size = table_size(taskids)

    add_clean()
    db.init(file_taskids)
    for i = 1, size do
        if add_single(taskids[i], statuses[i]) == false then
            print("add_multiple: error")
        end
    end
    print("add_multiple: ok")
    add_clean()
end

add_multiple()

