local HOME = os.getenv("HOME")
local tman_path = "personal/prjs/tman/src/?.lua"
local tman_test = "personal/prjs/tman/test/?.lua"
package.path = package.path .. ";" .. HOME .. "/" .. tman_path
package.path = package.path .. ";" .. HOME .. "/" .. tman_test


local test_db = require("test_db")

test_db.add()
