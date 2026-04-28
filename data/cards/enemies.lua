-- data/enemies.lua
-- enemy definitions

local enemies = {

    --- Enemies ---
    
    {
        id = "EN0001",
        name = "Forgiven",
        classname = "Enemy",
        subclass = "Troop",
        flavor = "Those who break Sermon City's laws are Forgiven; they repay this act of grace with a life of service, garbed permanently in the image pf Our Lord Father as a display of profound faith and gratitude.",
        health = 3,
        max = 3,
        D1 = "PDMG3",
        D2 = "PDMG2",
        D3 = "PDMG2",
        D4 = "PDMG1",
        D5 = "NUL",
        D6 = "NUL",
    },

    {
        id = "EN0002",
        name = "Confessor",
        classname = "Enemy",
        subclass = "Troop",
        keyword = { "KWTOUGH"},
        textbox = "Squad:\n\nForgiven x2",
        flavor = "Confessors attend to the final rites of the Forgiven, accepting any last words of apology or prayer on behalf of Our Lord Father.",
        health = 7,
        max = 7,
        encounter = {
            spawns = {
                { enemyId = "EN0001", count = 2 },
            },
        },
        D1 = "ARDMG1",
        D2 = "BDMG3",
        D3 = "BDMG2",
        D4 = "BDMG2",
        D5 = "BDMG2",
        D6 = "BDMG1",
    },

    {
        id = "ENSEEN",
        name = "Seen",
        classname = "Enemy",
        subclass = "Troop",
        textbox = "Squad:\n\nForgiven x2",
        flavor = "The Seen are the backbone of Sermon City's volunteer security forces - those who take up arms after witnessing an act of the divine.",
        health = 6,
        max = 6,
        encounter = {
            spawns = {
                { enemyId = "EN0001", count = 2 },
            },
        },
        D1 = "BDMG4",
        D2 = "BDMG4",
        D3 = "BDMG3",
        D4 = "BDMG3",
        D5 = "ARDMG1",
        D6 = "ARDMG1",
    },

}

return enemies
