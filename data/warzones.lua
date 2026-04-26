-- data/warzones.lua
-- Warzone definitions

--- Warzones ---

local warzones = {
    {
        id = "WZ0001",
        name = "Rachel's\nPizzeria",
        control = 0,
        max = 6,
        type = "warzone",
        poi = "POI0001",
        allied = true, 
        method = {
            { resource = "The Trigger", amount = 1 },
        },
        flavor = "\"At Rachel's, we never forgot the little miracle that was 2-for-1 pizza.\"",
        D1 = "SAB2",
        D2 = "SAB1",
        D3 = "SAB1",
        D4 = "NUL",
        D5 = "NUL",
        D6 = "NUL",
    },

    {
        id = "WZ0001B",
        name = "Security Checkpoint",
        control = -3,
        max = 6,
        type = "warzone",
        flavor = "\"...Cause no trouble. Next.\"",
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
