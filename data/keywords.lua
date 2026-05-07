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

        {
            id = "KWRLD",
            name = "Reloading",
            text = "All of this card's die faces are blank while it is reloading.",
            hasvalue = 1,

        },

        {
            id = "KWGRO",
            name = "Growth",
            text = "Increase this card's health and all of its die values.",
            hasvalue = 1,

        },

        {
            id = "KWPILOT",
            name = "Pilot",
            text = "This card is being piloted by the shown card.",
        },

        {
            id = "KWTOUGH",
            name = "Tough",
            text = "Damage dealt to this card is reduced to 1. This keyword is exhausted after being triggered.",
        },

        {
            id = "KWBULLETPROOF",
            name = "Bulletproof",
            text = "Damage dealt to this card is reduced to 1.",
        },

        {
            id = "KWEVA",
            name = "Evasion",
            text = "Whenever this card is damaged, it gains Flying until the End phase.",
        },

        {
            id = "KWFAIR",
            name = "Fair Weather",
            text = "If all other enemies are defeated, this card is automatically defeated.",
        },

        {
            id = "KWRAGE",
            name = "Rage",
            text = "If this card is reduced to half of its health or less, its die faces are multiplied by 2.",
        },

        --- Conditions ---

        {
            id = "KWWOUND",
            name = "Wound",
            text = "Before this card acts each turn it takes damage.",
            hasvalue = 1,
        },

        {
            id = "KWREGEN",
            name = "Regeneration",
            text = "At the beginning of each turn this card heals.",
            hasvalue = 1,
        },

}

return keywords
