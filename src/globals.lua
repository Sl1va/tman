-- Chaneg it to where you are gonna keep all your tasks
-- For me it is path below in home directory
local tmanbase = "work/tman/"

local homebase = os.getenv("HOME") .. "/" .. tmanbase
G_tmanpath = homebase .. ".tman/"
G_taskpath = homebase .. "tasks/"
G_codebasepath = homebase .. "codebase/"
