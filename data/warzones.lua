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
        D1 = "DRAWSAB1",
        D2 = "CASHSAB1",
        D3 = "NUL",
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
        D2 = "BDMG1",
        D3 = "NUL",
        D4 = "NUL",
        D5 = "NUL",
        D6 = "NUL",
    },

--- Persons of Interest ---

    {
        id = "POI0001",
        name = "Rachel",
        control = 10,
        allyID = "ALY0001",
        max = 12,
        type = "poi",
        flavor = "\"Welcome to Rachel's! How can I help?\"",
        D1 = "NUL",
        D2 = "NUL",
        D3 = "NUL",
        D4 = "NUL",
        D5 = "NUL",
        D6 = "NUL",
    },

    {
        id = "POI0001B",
        name = "Rachel",
        control = 10,
        huntID = "HNT0001",
        max = 12,
        type = "poi",
        flavor = "\"I've got a new delivery schedule now.\"",
        D1 = "NUL",
        D2 = "NUL",
        D3 = "NUL",
        D4 = "NUL",
        D5 = "NUL",
        D6 = "NUL",
    },

}

return warzones
