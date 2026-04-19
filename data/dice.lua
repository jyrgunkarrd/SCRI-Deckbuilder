-- data/card/dice.lua
-- Dice card type definitions

local dice = {

    --- Demo Dice ---
    
        {
            id = "D001",
            type = "BasicDmg",
            value = 3,
            targ = "Atk",
        },

        {
            id = "D002",
            type = "Blank",
        },

        {
            id = "D003",
            type = "BasicDmg",
            value = 72,
        },

        {
            id = "D004",
            type = "RedButton",
            value = 1,
            targ = "Obj",
        },

        {
            id = "D005",
            type = "RedButton",
            value = 2,
            targ = "Obj",
        },

        {
            id = "D006",
            type = "Detonator",
            value = 6,
            targ = "Sab",
        },

        {
            id = "D007",
            type = "Warrant",
            value = 1,
            targ = "IntCD",
        },

        {
            id = "D008",
            type = "Warrant",
            value = 2,
            targ = "IntCD",
        },

        {
            id = "D009",
            type = "Warrant",
            value = 6,
            targ = "IntCD",
        },

        {
            id = "D010",
            type = "Threat",
            value = 2,
            targ = "WZOpp",
        },

        {
            id = "D011",
            type = "BlackTap",
            value = 8,
            targ = "WZPlayer",
        },

--- Blank Die ---

{
    id = "NUL",
    type = "Blank",
},

 --- Basic Damage ---

        {
            id = "BDMG3",
            type = "BasicDmg",
            value = 3,
            targ = "Atk",
        },

        {
            id = "BDMG2",
            type = "BasicDmg",
            value = 2,
            targ = "Atk",
        },

        {
            id = "BDMG1",
            type = "BasicDmg",
            value = 1,
            targ = "Atk",
        },

    -- Pain Damage ---

    {
        id = "PDMG3",
        type = "PainDmg",
        value = 3,
        targ = "Atk",
        pain = 1,
    },

    {
        id = "PDMG2",
        type = "PainDmg",
        value = 2,
        targ = "Atk",
        pain = 1,

    },

    {
        id = "PDMG1",
        type = "PainDmg",
        value = 1,
        targ = "Atk",
        pain = 1,

    },

    --- Basic Block ---

    {
        id = "BBLK1",
        type = "BasicBlk",
        value = 1,
        targ = "Blk",
    },

    --- Advanced Block ---

    {
        id = "DIV3",
        type = "Divert",
        value = 3,
        targ = "Div",
    },

    --- Basic SynTac

    {
        id = "TAC1",
        type = "SynTac",
        value = 1,
        targ = "Tac",
    },

    {
        id = "TAC2",
        type = "SynTac",
        value = 2,
        targ = "Tac",
    },


    --- Basic Sabotage ---

    {
        id = "SAB2",
        type = "Detonator",
        value = 2,
        targ = "Sab",
    },

    --- Basic Influence ---

    {
        id = "BINF1",
        type = "BlackTap",
        value = 1,
        targ = "WZPlayer",
    },

    {
        id = "BINF2",
        type = "BlackTap",
        value = 2,
        targ = "WZPlayer",
    },

    --- Advanced Influence ---

    {
        id = "INFTAC1",
        type = "TacAndInf",
        value = 1,
        targ = "InfTac",
    },

    --- Infiltration ---

    {
        id = "INF1",
        type = "BasicInf",
        value = 5,
        targ = "Inf",
        cardgen = "HNTINFFM",
    },

    --- Attack / Sabotage Hybrid ---

    {
        id = "ATKORSAB1",
        type = "AttackOrSabotage",
        value = 1,
        targ = { "Atk", "Sab" }
    },

    {
        id = "ATKANDSAB1",
        type = "AttackAndSabotage",
        value = 1,
        targ = { "AtkSab" }
    },
    
    
    }
    
    return dice
