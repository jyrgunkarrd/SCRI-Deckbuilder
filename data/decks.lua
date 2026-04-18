-- data/decks.lua
-- Deck card type definitions

local decks = {

    --- Player Decks ---
    
        {
            id = "DCK001",
            name = "Demo",
            cards = {
                {
                    cardId = "AEGBLK",
                    quantity = 3,
                },

                {
                    cardId = "AEGPSYBOM",
                    quantity = 3,
                },
            },
        },

    --- Champion decks

        {
            id = "DCK002",
            name = "DemoChamp",
            cards = {
                {
                    cardId = "EN0001",
                    quantity = 10,
                },
                {
                    cardId = "EN0002",
                    quantity = 5,
                },
            },
        },

}
    
    return decks
