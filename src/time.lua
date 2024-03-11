

--[[

tman amend time -1h

tman time
Capac: 2w 4h
Spent: 1d
Left : 3h


tman time add 3h
tman time del 4h
]]



local function day_to_hour(dayval)
    local hours_in_day = 8
    return dayval * hours_in_day
end

local function week_to_hour(weekval)
    local day_in_week = 5
    return day_to_hour(weekval * day_in_week)
end


local function time_check(timeval)
    local sep = ' '

    for str in string.gmatch(timeval, "([^" .. sep .. "]+)") do
        local _, unit = string.match(str, "([0-9]*)([wdh])")
        if unit ~= 'w' and unit ~= 'd' and unit ~= 'h' then
            return false
        end
    end
    return true
end

local function time_to_hours(timeval)
    local sep = " "
    local res = 0
    local days_a_week = 5
    local hours_a_day = 8

    for str in string.gmatch(timeval, "([^" .. sep .. "]+)") do
        local val, unit = string.match(str, "([0-9]*)([wdh])")
        val = tonumber(val)
        --print(val, unit)

        if unit == 'w' then
            res = res + val * days_a_week * hours_a_day
        elseif unit == 'd' then
            res = res + val * hours_a_day
        elseif unit == 'h' then
            res = res + val
        end
    end
    return res
end

local function hours_to_time(hourval)
    local res = ""
    local days_a_week = 5
    local hours_a_day = 8
    local weeks = 0
    local days = 0
    local hours = 0

    weeks = math.floor(hourval / (days_a_week * hours_a_day))
    if weeks ~= 0 then
        res = res .. tostring(weeks) .. "w "
    end

    days = hourval - week_to_hour(weeks)
    days = math.floor(days / hours_a_day)
    if days ~= 0 then
        res = res .. tostring(days) .. "d "
    end

    hours = hourval - week_to_hour(weeks) - day_to_hour(days)
    if hours ~= 0 then
        res = res .. tostring(hours) .. "h"
    end

    return res
end





local timeval = "2d 3h"
local hours = 49

local res1 = time_to_hours(timeval)
local res2 = hours_to_time(hours)


print("res1", res1)
print("res2", res2)
print("time_check", time_check(timeval))
