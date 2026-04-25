-- data/tomes.lua
-- Tome definitions

local tomes = {

    --- Player JACL ---
    
        {
            id = "BOOKVAL",
            name = "Book of Valshamr",
            classname = "Starter",
            subclass = "Tome",
            type = "kit",
            syncost = 5,
            func = "Spawn",
            keyword = { "KWKIT" },
            textbox = "Summon a Freyja token.",
            flavor = "Contact with the ship is intermittent and difficult to maintain. All successful Lexurgical phrases shall be logged here.", 
            value = 1,
            target = { "AEGFREYTOK" }
        },
}

return tomes
