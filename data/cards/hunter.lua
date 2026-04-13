-- data/hunter.lua
-- hunter definitions

local hunter = {
    
    {
        id = "HNT0001",
        type = "hunter",
        name = "Rachel",
        textbox = "Plunder or strike: Create a Flair in hand if you don't already have one.",
        health = 2,
        max = 2,
        mcost = {
            { resource = "The Scratch", amount = 2 },
        },
        emphasis = 8,
        D1 = "D001",
        D2 = "D001",
        D3 = "D001",
        D4 = "D001",
        D5 = "D001",
        D6 = "D001",
    },

    --- Infiltrators ---

    {
        id = "HNTINFFM",
        type = "hunter",
        subtype = "infiltrator",
        name = "Fool's Meat",
        textbox = "Plunder or strike: Create a Flair in hand if you don't already have one.",
        health = 2,
        max = 2,
        mcost = {
            { resource = "The Scratch", amount = 2 },
        },
        emphasis = 8,
        D1 = "D001",
        D2 = "D001",
        D3 = "D001",
        D4 = "D001",
        D5 = "D001",
        D6 = "D001",
    },
}

return hunter
