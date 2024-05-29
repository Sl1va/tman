local function tman_time(oper, val)
    local weeks = ""
    local days = ""
    local hours = ""

    if oper == "set" then
        local timeval = ""
        io.write("weeks (default none): ")
        weeks = io.read("*l")
        io.write("days (default none): ")
        days = io.read("*l")
        io.write("hours (default none): ")
        hours = io.read("*l")

        print("weeks", weeks)
        print("days", days)
        print("hours", hours)
        timeval = weeks .. " " .. days .. " " .. hours
        print(("timeval '%s'"):format(timeval))
    end
end
