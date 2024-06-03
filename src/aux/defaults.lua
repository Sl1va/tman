--- Default values so util doesn't break if no config is presented.
-- @module defaults

local def_tasktypes = { "bugfix", "feature", "hotfix" }

return {
    tasktypes = def_tasktypes,
}
