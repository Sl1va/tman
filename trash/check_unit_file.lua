--- Check that task unit is not corrupted.
-- roachme: it should check user key as well, but i just don't know.
-- roachme: TODO: use it in code.
-- @param id task id
-- @return true on success, otherwise false
local function check_unitfile(id)
    local i = 1
    local taskunits = load_units(id)

    if not next(taskunits) then
        print("next")
        return false
    end

    for _, _ in pairs(taskunits) do
        local key = unit_keys[i]
        if not taskunits[key] or taskunits[key].value then
            print("unit")
            return false
        end
        i = i + 1
    end
    return true
end
