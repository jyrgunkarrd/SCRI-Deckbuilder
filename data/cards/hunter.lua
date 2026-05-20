-- data/hunter.lua
-- hunter definitions

local hunter = {
    
    {
        id = "HNT0001",
        type = "hunter",
        name = "Rachel",
        flavor = "\"I've got a new delivery schedule now.\"",
        health = 5,
        max = 5,
        emphasis = 3,
        rfc = 3,
        D1 = "OBJ3",
        D2 = "BDMG3",
        D3 = "OBJ2",
        D4 = "BDMG2",
        D5 = "OBJ2",
        D6 = "BDMG2",
    },

    --- Infiltrators ---

    {
        id = "HNTINFFM",
        type = "hunter",
        subtype = "infiltrator",
        name = "Fool's Meat",
        flavor = "INTRUDER ALERT!\n\nINTRUDER ALERT!",
        health = 3,
        max = 3,
        emphasis = 2,
        rfc = 2,
        D1 = "BDMG3",
        D2 = "BDMG3",
        D3 = "BDMG3",
        D4 = "BDMG3",
        D5 = "BDMG2",
        D6 = "BDMG2",
    },

    {
        id = "HNTROLL",
        type = "hunter",
        subtype = "infiltrator",
        name = "Roller",
        flavor = "INTRUDER ALERT!\n\nINTRUDER ALERT!",
        health = 2,
        max = 2,
        emphasis = 2,
        rfc = 1,
        keyword = { "KWCNTR" },
        kwval = {
            KWCNTR = 1,
        },
        D1 = "OBJ3",
        D2 = "OBJ3",
        D3 = "OBJ2",
        D4 = "OBJ2",
        D5 = "BDMG2",
        D6 = "BDMG2",
    },

    {
        id = "HNTSAT",
        type = "hunter",
        subtype = "infiltrator",
        name = "The Eye of God",
        flavor = "They'll always be watching, now.",
        emphasis = 3,
        rfc = 1,
        keyword = { "KWTIME" },
        kwval = {
            KWCNTR = 2,
        },
        D1 = "OBJ3",
        D2 = "THR3",
        D3 = "OBJ2",
        D4 = "THR2",
        D5 = "OBJ1",
        D6 = "THR1",
    },

    
}

return hunter
