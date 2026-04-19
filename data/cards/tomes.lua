-- data/tomes.lua
-- Tome definitions

local tomes = {

    --- Player JACL ---
    
        {
            id = "BOOKVAL",
            name = "Book of Valshamr",
            type = "tome",
            syncost = 1,
            func = "Spawn",
            value = 1,
            target = { "AEGFREYTOK" }
        },
}

return tomes
