local Globals = {}

-- Chaneg it to where you are gonna keep all your tasks
-- For me it is path below in home directory
Globals.tmandir = "work/tman/"

Globals.tmanhome = os.getenv("HOME") .. "/" .. Globals.tmandir
Globals.tmandb = Globals.tmanhome .. ".tman/"
Globals.repos = Globals.tmandb .. "repos"
Globals.tasks = Globals.tmanhome .. "tasks/"
Globals.cdbase = Globals.tmanhome .. "codebase/"

return Globals
