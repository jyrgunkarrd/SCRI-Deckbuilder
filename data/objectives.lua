-- data/objectives.lua
-- Objective definitions

--- Primary Objectives ---

local objectives = {
    {
        id = "PRIMOBJ0001",
        name = "Longinus III",
        plan = 0,
        max = 18,
        type = "objective",
        textbox = "Plunder or strike: Create a Flair in hand if you don't already have one.",
        emphasis = 2,
        escalate = "PRIMOBJ0002",
        D1 = "D002",
        D2 = "D002",
        D3 = "D002",
        D4 = "D002",
        D5 = "D002",
        D6 = "D002",
    },

    {
        id = "PRIMOBJ0002",
        name = "Longinus III",
        plan = 0,
        max = 18,
        type = "objective",
        textbox = "Plunder or strike: Create a Flair in hand if you don't already have one.",
        emphasis = 2,
        D1 = "D002",
        D2 = "D002",
        D3 = "D002",
        D4 = "D002",
        D5 = "D002",
        D6 = "D002",
    },

--- Intelligence ---

    {
        id = "INT0001",
        name = "WarGaze",
        plan = 4,
        max = 6,
        type = "intel",
        textbox = "Plunder or strike: Create a Flair in hand if you don't already have one.",
        D1 = "D002",
        D2 = "D002",
        D3 = "D002",
        D4 = "D002",
        D5 = "D002",
        D6 = "D002",
    },

    {
        id = "INT0000",
        name = "No Signal",
        plan = 6,
        max = 6,
        type = "intel",
        textbox = "...Reconnecting...",
        D1 = "D008",
        D2 = "D008",
        D3 = "D008",
        D4 = "D008",
        D5 = "D008",
        D6 = "D008",
    },

    {
        id = "INT0002",
        name = "Rat Meat",
        plan = 6,
        max = 6,
        type = "intel",
        textbox = "...Reconnecting...",
        D1 = "D002",
        D2 = "D002",
        D3 = "D002",
        D4 = "D002",
        D5 = "D002",
        D6 = "D002",
    },

    {
        id = "INT0003",
        name = "Boom Tap",
        plan = 6,
        max = 6,
        type = "intel",
        textbox = "...Reconnecting...",
        D1 = "D002",
        D2 = "D002",
        D3 = "D002",
        D4 = "D002",
        D5 = "D002",
        D6 = "D002",
    },
}

return objectives
