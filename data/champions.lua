-- data/champions.lua
-- Champion definitions

local champions = {
    {
        id = "CH0001",
        name = "PAM",
        health = 5,
        max= 10,
        deckId = "DCK002",
        intelDeck = {
            {
                cardId = "INT0001",
                quantity = 1,
            },
            {
                cardId = "INT0002",
                quantity = 1,
            },
            {
                cardId = "INT0003",
                quantity = 1,
            },
        },
        PrimaryObjective = "PRIMOBJ0001",
        textbox = "Plunder or strike: Create a Flair in hand if you don't already have one.",
        D1 = "BDMG3",
        D2 = "BDMG3",
        D3 = "BDMG3",
        D4 = "BDMG3",
        D5 = "BDMG3",
        D6 = "BDMG3",
    },
}

return champions
