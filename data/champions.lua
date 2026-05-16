-- data/champions.lua
-- Champion definitions

local champions = {
    {
        id = "CH0001",
        name = "PAM", --reminder: PAM = Pilotless Attack Machine
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
        defeat = "fem-defeat.wav",
        surrtext = "PAM transmits terms of surrender, bargaining for her survival. She would be a deprecated war machine now out of your way — but one still gripping the trigger of a gun held to the world's head.\n\nDo you accept her terms?"
    },
}

return champions
