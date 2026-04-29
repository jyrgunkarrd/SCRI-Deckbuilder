-- data/enemies.lua
-- enemy definitions

local enemies = {

    --- Enemies ---
    
    --- Subordinate ---

    {
        id = "EN0001",
        name = "Forgiven",
        classname = "Enemy",
        subclass = "Troop",
        flavor = "Those who break Sermon City's laws are forgiven; they repay this act of grace with a life of service, garbed permanently in the image pf Our Lord Father as a display of profound faith and gratitude.",
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
        id = "ENMISS",
        name = "Missionary",
        classname = "Enemy",
        subclass = "Troop",
        flavor = "\"The Exterminator brings fire. The Lawman brings steel. The Missionary brings forgiveness.\"",
        health = 5,
        max = 5,
        D1 = "BDMG4",
        D2 = "BDMG4",
        D3 = "ARDMG1",
        D4 = "ARDMG1",
        D5 = "OBJ1",
        D6 = "OBJ1",
    },

    {
        id = "ENFALC",
        name = "Falconer",
        classname = "Enemy",
        subclass = "Troop",
        keyword = { "KWEVA"},
        flavor = "\"They are whole cloth mercenaries. The act of employing them condemns and refutes more than we ever could.\"",
        health = 3,
        max = 3,
        D1 = "BDMG3",
        D2 = "BDMG3",
        D3 = "BDMG2",
        D4 = "BDMG2",
        D5 = "BDMG2",
        D6 = "BDMG2",
    },

    {
        id = "ENOWL",
        name = "Spectral Raptor",
        classname = "Enemy",
        subclass = "Troop",
        keyword = { "KWFLY"},
        flavor = "\"Of course I can talk. I can sing too. No, I don't want a 'treat'.\n\n...Actually, well, maybe just a little nibble...\"",
        health = 2,
        max = 2,
        D1 = "PDMG2",
        D2 = "PDMG2",
        D3 = "PDMG2",
        D4 = "PDMG2",
        D5 = "PDMG1",
        D6 = "PDMG1",
    },

    {
        id = "ENFEN",
        name = "Fenrir",
        classname = "Enemy",
        subclass = "Troop",
        keyword = { "KWRAGE"},
        flavor = "\"I used to say there were no bad dogs. I don't say that anymore.\"",
        health = 16,
        max = 16,
        D1 = "CQDMG3",
        D2 = "CQDMG3",
        D3 = "CQDMG3",
        D4 = "ARPDMG2",
        D5 = "ARPDMG2",
        D6 = "AWDMG2",
    },

    {
        id = "ENNUN",
        name = "Messenger",
        classname = "Enemy",
        subclass = "Troop",
        keyword = { "KWFLY"},
        flavor = "\"Our Lord Father's messengers always have much to say, but they only speak in one particular language.\"",
        health = 2,
        max = 2,
        D1 = "BDMG3",
        D2 = "BDMG3",
        D3 = "BDMG2",
        D4 = "BDMG2",
        D5 = "BDMG2",
        D6 = "BDMG2",
    },



    --- Captain ---

    {
        id = "EN0002",
        name = "Confessor",
        classname = "Enemy",
        subclass = "Troop",
        keyword = { "KWTOUGH"},
        flavor = "Confessors attend to the final rites of the Forgiven, accepting any last words of apology or prayer on behalf of Our Lord Father.",
        health = 7,
        max = 7,
        encounter = {
            spawns = {
                { enemyId = "EN0001", count = 2 },
            },
        },
        preview = {
            label = "SQUAD",
            cardIds = { "EN0001", "EN0001" },
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
        flavor = "The Seen are the backbone of Sermon City's volunteer security forces - those who take up arms after witnessing an act of the divine.",
        health = 6,
        max = 6,
        encounter = {
            spawns = {
                { enemyId = "EN0001", count = 2 },
            },
        },
        preview = {
            label = "SQUAD",
            cardIds = { "EN0001", "EN0001" },
        },
        D1 = "BDMG4",
        D2 = "BDMG4",
        D3 = "BDMG3",
        D4 = "BDMG3",
        D5 = "ARDMG1",
        D6 = "ARDMG1",
    },

    {
        id = "ENBISH",
        name = "Bishop",
        classname = "Enemy",
        subclass = "Troop",
        flavor = "\"Two hundred years of justice, honesty, security. Two hundred years! And it should all end now? Over twelve seconds of doubt? Absurd.\"",
        health = 3,
        max = 3,
        keyword = { "KWBULLETPROOF", "KWFAIR"},
        encounter = {
            spawns = {
                { enemyId = "ENFALC", count = 1 },
                { enemyId = "ENMISS", count = 1 },
                { enemyId = "ENOWL", count = 1 },
            },
        },
        preview = {
            label = "SQUAD",
            cardIds = { "ENFALC", "ENMISS", "ENOWL" },
        },
        D1 = "OBJ3",
        D2 = "OBJ3",
        D3 = "THR3",
        D4 = "THR3",
        D5 = "OBJ1",
        D6 = "THR1",
    },

}

return enemies
