-- data/jacl.lua
-- JACL definitions

local jacl = {

    --- Player JACL ---
    
        {
            id = "JACL001",
            name = "JACL-S3D2-VALSHAMR",
            deckId = "DCK001",
            tomeId = "BOOKVAL",
            method = {
                { resource = "The Gate", amount = 1 },
            },
            jaclAbilities = {
                {
                    id = "scramble",
                    name = "Scramble",
                    text = "Create a Black Dagger token.",
                    trigger = "method_badge_click",
                    badgeResource = "The Gate",
                    costs = {
                        { resource = "The Gate", amount = 1 },
                    },
                    timing = {
                        phase = "Prelude",
                    },
                    target = {
                        kind = "player_row_cell",
                        rowId = "PlayerRow",
                    },
                    effect = "create_grid_card",
                    effectArgs = {
                        cardId = "TK0001",
                        rowId = "PlayerRow",
                    },
                },
            },
        },
}

return jacl
