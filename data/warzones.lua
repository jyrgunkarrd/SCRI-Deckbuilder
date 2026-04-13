-- data/warzones.lua
-- Warzone definitions

--- Warzones ---

local warzones = {
    {
        id = "WZ0001",
        name = "Rachel's\nPizzeria",
        control = 5,
        max = 12,
        type = "warzone",
        poi = "POI0001",
        textbox = "Plunder or strike: Create a Flair in hand if you don't already have one.",
        D1 = "D002",
        D2 = "D002",
        D3 = "D002",
        D4 = "D002",
        D5 = "D002",
        D6 = "D002",
    },

    {
        id = "WZ0001B",
        name = "Security Checkpoint",
        control = -4,
        max = 12,
        type = "warzone",
        textbox = "Plunder or strike: Create a Flair in hand if you don't already have one.",
        D1 = "INF1",
        D2 = "INF1",
        D3 = "INF1",
        D4 = "INF1",
        D5 = "INF1",
        D6 = "INF1",
    },

--- Persons of Interest ---

    {
        id = "POI0001",
        name = "Rachel",
        control = 10,
        allyID = "ALY0001",
        max = 12,
        type = "poi",
        textbox = "Plunder or strike: Create a Flair in hand if you don't already have one.",
        D1 = "D002",
        D2 = "D002",
        D3 = "D002",
        D4 = "D002",
        D5 = "D002",
        D6 = "D002",
    },

    {
        id = "POI0001B",
        name = "Rachel",
        control = 10,
        huntID = "HNT0001",
        max = 12,
        type = "poi",
        textbox = "Plunder or strike: Create a Flair in hand if you don't already have one.",
        D1 = "D002",
        D2 = "D002",
        D3 = "D002",
        D4 = "D002",
        D5 = "D002",
        D6 = "D002",
    },

}

return warzones
