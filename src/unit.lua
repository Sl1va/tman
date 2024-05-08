
--[[

check:
    tasktype
    unit file
    unit key
    unit priority

]]


local function check_unit_file()
end

--- Check that user specified task type exists.
-- @tparam string utype user specified type
-- @treturn bool true if exists, otherwise false
local function check_unit_type(utype)
    local tasktypes = { "bugfix", "feature", "hotfix" }

    for _, _type in pairs(tasktypes) do
        if utype == _type then
            return true
        end
    end
    return false
end

local function check_unit_key()
end

local function check_unit_prio()
end




return {
    check_type = check_unit_type,
}
