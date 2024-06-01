

local function pattsplit(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

local function form_branch(items)
    local separators = "/_-"
    local branchpatt = "TYPE/ID_DESC_TIME"
    local sepcomponents = pattsplit(branchpatt, separators)

    for _, item in pairs(sepcomponents) do
        branchpatt = string.gsub(branchpatt, item, items[string.lower(item)])
    end
    return branchpatt
end


local items = {
    type = "bugfix",
    id = "TEST",
    desc = "test_task",
    time = "20240601",
}
local branch = form_branch(items)
print("branch", branch)




