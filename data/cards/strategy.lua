-- data/strategy.lua
-- strategy definitions

local strategy = {

    --- Player Strategy ---
    
    --- AEGIS Srategy Cards ---

        {
            id = "AEGPSYRAP",
            name = "Rappelling Psychos",
            type = "strategy",
            func = "Spawn",
            value = 2,
            target = { "AEGPSYCOMM" }
        },
}

return strategy
