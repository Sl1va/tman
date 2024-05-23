## Describe code and its philosophy

aux/db.lua:
User's responsible for saving data into the database. This way write operations
strive to minimum.
--[[
List of DB commands:
Private:
    _db_load    - load task units from database
    _db_sort    - sort task units in database
    _db_exist   - check that task ID exist in database
    _db_check   - check `taskids` content is safe to save

Public:
    init        - init database
    add         - add a new task ID to database
    del         - del a task ID from database
    save        - save task units into database
    size        - get size of taks units in database

    get         - get task unit from database (by task ID)
    set         - set status to task unit
    getixd      - get task unit from database (by task ID index)
]]

--[[
taskid file structure:
    'TaskID Status'

    TaskID - task ID name
    Status - task status: 0, 1, 2, 3

    0 - Current
    1 - Previous
    2 - kkActive
    3 - Complete
]]



