--- Back up util configs into archive.
local function tman_backup()
    -- roachme: need some tuning
    local ftar = "tman_db.tar"
    local dtar = ".tman"
    local tar = "tar -C "
    local tarcmd = tar .. config.taskbase .. " -cf " .. ftar .. " " .. dtar

    if not utils.access(config.taskids) then
        return io.stderr:write("tman database doesn't exist. Nothing to backup\n")
    end

    if not os.execute(tarcmd) then
        return io.stderr:write("couldn't create tman database backup\n")
    end
    return print(("create backup file: './%s'"):format(ftar))
end

--- Restore util configs from archive.
local function tman_restore()
    local ftar = arg[1]

    if not ftar then
        io.stderr:write("pass config *.tar file\n")
        os.exit(1)
    end

    local dtar = ".tman"
    local tar = "tar"
    local tarcmd = tar .. " -xf " .. ftar .. " " .. dtar
    if not utils.access(ftar) then
        io.stderr:write(("'%s': no archive such file\n"):format(ftar))
        os.exit(1)
    end

    print("tarcmd", tarcmd)
    --os.execute(tarcmd)
end
