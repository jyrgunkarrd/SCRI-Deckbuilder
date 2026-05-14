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

    --- Testbed decks ---

        {
            id = "Demo",
            name = "Enemy Testbed",
            cards = {
                {
                    cardId = "HWBSC",
                    quantity = 60,
                },
            },
        },

        --- Champion Decks ---


        {
            id = "PAMDCK",
            name = "PAM",
            cards = {
                {
                    cardId = "ENEXTDRVWSP",
                    quantity = 2,
                },

                {
                    cardId = "ENJNGLWSP",
                    quantity = 2,
                },

                {
                    cardId = "ENCLKMKR",
                    quantity = 1,
                },
            },
        },

        --- Modular Packages ---

        {
            id = "DEMOPKG",
            name = "Demo package",
            cards = {
                {
                    cardId = "ENBISH",
                    quantity = 1,
                },

            },
        },

        {
            id = "ZEKDCK",
            name = "Airship Ezekiel",
            cards = {
                {
                    cardId = "ENZEK",
                    quantity = 1,
                },

                {
                    cardId = "ENFOG",
                    quantity = 1,
                },

                {
                    cardId = "ENADVACE",
                    quantity = 1,
                },
            },
        },

        {
            id = "DOTDCK",
            name = "Red Dot's Gang",
            cards = {
                {
                    cardId = "ENDOT",
                    quantity = 1,
                },

                {
                    cardId = "ENFID",
                    quantity = 1,
                },

                {
                    cardId = "ENFDOH",
                    quantity = 1,
                },

                {
                    cardId = "ENOCTO",
                    quantity = 1,
                },

                {
                    cardId = "ENWAGN",
                    quantity = 1,
                },

            },
        },

        --- Standard Packages ---


        {
            id = "STDPKG",
            name = "Standard Demo package",
            cards = {
                {
                    cardId = "EN0001",
                    quantity = 1,
                },

            },
        },

        {
            id = "BSCDCK",
            name = "Standard Sermon City Deck",
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

}
    
    return decks
