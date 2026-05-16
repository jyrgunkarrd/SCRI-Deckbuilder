-- data/haywire.lua
-- haywire definitions

local haywire = {
    
    {
        id = "HWBSC",
        type = "Haywire",
        name = "Malfunction",
        classname = "Haywire",
        subclass = "Basic",
        textbox = "When this card is defeated by an enemy attack, add 2 progress to the enemy objective.",
        flavor = "\"FATAL ERROR\"",
        mcost = {
            { resource = "The Scratch", amount = 1 },
        },
        keyword = { "KWTIME" },
        kwval = {
            KWTIME = 2,
        },
        emphasis = 2,
        health = 1,
        max = 1,
    },

}

return haywire
