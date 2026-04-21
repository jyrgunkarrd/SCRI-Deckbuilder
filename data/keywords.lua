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

        {
            id = "KWSAV",
            name = "Savior",
            text = "When this card prevents a friendly unit from being defeated, it does not exhaust and may use that die face again.",
        },

        {
            id = "KWSTRAT",
            name = "Strategist",
            text = "Strategy cards may be played by dragging them onto this card. This card exhausts and its die face is cleared.",

        },

        {
            id = "KWELITE",
            name = "Elite",
            text = "This card becomes unexhausted and rerolls its action die every time a Strategy card is played.",

        },

        {
            id = "KWCNTR",
            name = "Counter-Strike",
            hasvalue = 1,
            text = "When this card is attacked it deals damage to its attackers.",
        },

        {
            id = "KWKIT",
            name = "Kit",

        },
}

return keywords
