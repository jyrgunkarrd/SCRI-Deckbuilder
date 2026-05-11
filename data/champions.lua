-- data/champions.lua
-- Champion definitions

local champions = {
    {
        id = "CH0001",
        name = "PAM",
        health = 20,
        max= 20,
        deckId = "PAMDCK",
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
        PrimaryObjective = "PRIMOBJ0002",
        flavor = "\"Her solution to the problem is too crude and bothersome to endorse, but too simple and actionable to prohibit.\"",
        D1 = "BDMG3",
        D2 = "BDMG2",
        D3 = "BDMG2",
        D4 = "BDMG2",
        D5 = "BDMG1",
        D6 = "BDMG1",
    },
}

return champions
