-- data/strategy.lua
-- strategy definitions

local strategy = {

    --- Player Strategy ---
    
    --- AEGIS Srategy Cards ---

        {
            id = "AEGPSYRAP",
            name = "Rappelling Psychos",
            classname = "Starter",
            subclass = "Strategy",
            type = "strategy",
            func = "Spawn",
            textbox = "Summon 2 Psycho Commando tokens.",
            flavor = "Even those without augs get a little bent around here.", 
            value = 2,
            target = { "AEGPSYCOMM" }
        },
}

return strategy
