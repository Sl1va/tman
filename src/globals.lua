local Globals = {}

-- Chaneg it to where you are gonna keep all your tasks
-- For me it is path below in home directory
Globals.tmanbase = "work/tman/"

Globals.homebase = os.getenv("HOME") .. "/" .. Globals.tmanbase

Globals.G_tmanpath = Globals.homebase .. ".tman/"
Globals.G_taskpath = Globals.homebase .. "tasks/"
Globals.G_codebasepath = Globals.homebase .. "codebase/"
Globals.G_tmanrepos = Globals.G_tmanpath .. "repos"

return Globals
