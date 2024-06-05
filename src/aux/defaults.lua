--- Default values so util doesn't break if no config is presented.
-- @module defaults

local def_tasktypes = { "bugfix", "feature", "hotfix" }
local def_commit_pattern = "PART: [ID] MSG"
local def_commit_size = 50

return {
    tasktypes = def_tasktypes,
    commitpatt = def_commit_pattern,
    commitsize = def_commit_size,
}
