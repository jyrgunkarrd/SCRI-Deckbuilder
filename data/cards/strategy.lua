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

        {
            id = "AEGSPMSL",
            name = "Splinter Missile Ambush",
            classname = "Starter",
            subclass = "Strategy",
            type = "strategy",
            funccost = "sactarg",
            target = { "troop", "token" },
            func = "counterstrk",
            value = 3,
            textbox = "Sacrifice a troop or token. Deal 3 damage to all enemies targeting it.",
            flavor = "There ain't a problem that a big enough warhead package can't solve.",
        },
}

return strategy
