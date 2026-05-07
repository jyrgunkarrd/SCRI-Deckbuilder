-- data/decks.lua
-- Deck card type definitions

local decks = {

    --- Player JACL Decks ---
    
        {
            id = "DCK001",
            name = "VALSHAMR",
            cards = {
                {
                    cardId = "AEGBLK",
                    quantity = 4,
                },

                {
                    cardId = "AEGPSYBOM",
                    quantity = 2,
                },

                {
                    cardId = "AEGLXSKY",
                    quantity = 2,
                },

                {
                    cardId = "AEGFZSPEC",
                    quantity = 2,
                },

                {
                    cardId = "AEGTMINGO",
                    quantity = 1,
                },

                {
                    cardId = "AEGPSYRAP",
                    quantity = 2,
                },

                {
                    cardId = "AEGSPMSL",
                    quantity = 1,
                },
            },
        },

    --- Agent dekcs ---

    {
        id = "AGB6",
        name = "BETTY SIX",
        cards = {
            {
                cardId = "B6VIC",
                quantity = 2,
            },

            {
                cardId = "B6CYBLD",
                quantity = 1,
            },

        },
    },

    {
        id = "AGMAM",
        name = "MAMMOTH",
        cards = {
            {
                cardId = "MAMHNT",
                quantity = 2,
            },

            {
                cardId = "MAMGRZ",
                quantity = 1,
            },

        },
    },

    --- Champion decks ---

        {
            id = "BSCDCK",
            name = "Sermon City Basic",
            cards = {
                {
                    cardId = "ENBISH",
                    quantity = 1,
                },
                {
                    cardId = "ENSEEN",
                    quantity = 1,
                },
                {
                    cardId = "ENFEN",
                    quantity = 1,
                },
                {
                    cardId = "EN0002",
                    quantity = 1,
                },
                {
                    cardId = "ENNUNC",
                    quantity = 1,
                },
                {
                    cardId = "ENSEENDRON",
                    quantity = 1,
                },
                {
                    cardId = "ENBISHDEC",
                    quantity = 1,
                },
                {
                    cardId = "ENSTRD",
                    quantity = 1,
                },
            },
        },

        {
            id = "Demo",
            name = "Enemy Testbed",
            cards = {
                {
                    cardId = "ENSTRD",
                    quantity = 10,
                },
            },
        },

        --- Modular Packages ---

        {
            id = "DEMOPKG",
            name = "Demo package",
            cards = {
                {
                    cardId = "ENSTRD",
                    quantity = 10,
                },
            },
        },

        --- Standard Packages ---


        {
            id = "STDPKG",
            name = "Standard Demo package",
            cards = {
                {
                    cardId = "ENSTRD",
                    quantity = 10,
                },
            },
        },

}
    
    return decks
