--- Exit util with some error explanation error.
-- Copied from grep source code.
-- @module die

local progname = "tman"
local errcodes = {}

-- die (EXIT_TROUBLE, 0, _("the -P option only supports a single pattern"));

-- input
--       die (EXIT_TROUBLE, 0, "%s: %s", str,
-- _("invalid context length argument"));
-- output
-- grep: oeu: invalid context length argument
local function die(exit_code, errfmt, ...)
    local errmsg = ("%s: %s: " .. errfmt):format(progname, ...)
    io.stderr:write(errmsg)
    os.exit(exit_code)
end

return {
    die = die,
    ecode = errcodes,
}
