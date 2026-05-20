-- data/champions.lua
-- Champion definitions

local champions = {
    
    --- Regfor Champions ---
    
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

    --- Gloryfor Champions ---

    {
        id = "CHFTPLYCHR",
        name = "Fort Chroma",
        health = 60,
        max= 60,
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
        flavor = "\"Everyone already wants to be a hero. The Chroma Corps... simplifies the fulfillment of that fantasy.\"",
        D1 = "CHROMATKSMN",
        D2 = "CHROMATKSMN",
        D3 = "GRYSCLATKSMN",
        D4 = "GRYSCLATKSMN",
        D5 = "OBJBLK2",
        D6 = "OBJBLK2",
        defeat = "fem-defeat.wav",
        surrtext = "The fort's guns go silent. White flags flap in the wind. If you wish to be done here, you are - though the conscription machinery of the Chroma Corps will remain intact.\n\nDo you accept their terms?"
    },
}

return champions
