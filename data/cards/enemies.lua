-- data/enemies.lua
-- enemy definitions

local enemies = {

    --- Enemies ---
    
    {
        id = "EN0001",
        keyword = {"KEY0001"},
        name = "Forgiven",
        classname = "Enemy",
        subclass = "Troop",
        textbox = "Plunder or strike: Create a Flair in hand if you don't already have one.",
        health = 3,
        max = 3,
        D1 = "BDMG3",
        D2 = "BDMG2",
        D3 = "BDMG2",
        D4 = "BDMG1",
        D5 = "NUL",
        D6 = "NUL",
    },

    {
        id = "EN0002",
        name = "Confessor",
        classname = "Enemy",
        subclass = "Troop",
        keyword = { "KWTOUGH"},
        textbox = "Plunder or strike: Create a Flair in hand if you don't already have one.",
        health = 3,
        max = 3,
        D1 = "ARDMG1",
        D2 = "BDMG3",
        D3 = "BDMG2",
        D4 = "BDMG2",
        D5 = "BDMG2",
        D6 = "BDMG1",
    },

}

return enemies
