-- data/keywords.lua
-- keyword definitions

local keywords = {

        {
            id = "KEY0001",
            name = "Conscript",
            text = "When this card is played, the Champion immediately plays another card.",
            effect = "enemy_champion_play_another_card",
        },

        {
            id = "KWFLY",
            name = "Flying",
            text = "This card can only be attacked by other cards with Flying.",
        },

        {
            id = "KWTIME",
            name = "Time Limit",
            text = "This card will only remain in play area for a limited time.",
            hasvalue = 1,
        },
}

return keywords
