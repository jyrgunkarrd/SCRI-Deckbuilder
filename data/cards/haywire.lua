-- data/haywire.lua
-- haywire definitions

local haywire = {
    
    {
        id = "HWBSC",
        type = "Haywire",
        name = "Malfunction",
        classname = "Haywire",
        subclass = "Basic",
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
