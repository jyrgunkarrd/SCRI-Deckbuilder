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
    id = "BLK",
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

    --- Basic Sabotage ---

    {
        id = "SAB2",
        type = "Detonator",
        value = 2,
        targ = "Sab",
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
