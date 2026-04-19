-- data/card/troops.lua
-- Troop card type definitions

local troops = {

    --- Player Agents ---

    {
        id = "AGT0001",
        type = "agent",
        name = "Betty Six",
        textbox = "Plunder or strike: Create a Flair in hand if you don't already have one.",
        flavor = "Sample text.",
        health = 6,
        max = 6,
        method = {
            { resource = "The Trigger", amount = 2 },
        },
        D1 = "D011",
        D2 = "D011",
        D3 = "D011",
        D4 = "D011",
        D5 = "D011",
        D6 = "D011",
    },

    {
        id = "AGT0002",
        type = "agent",
        name = "Mammoth",
        textbox = "Plunder or strike: Create a Flair in hand if you don't already have one.",
        health = 2,
        max = 2,
        method = {
            { resource = "The Beast", amount = 2 },
        },
        D1 = "D011",
        D2 = "D011",
        D3 = "D011",
        D4 = "D011",
        D5 = "D011",
        D6 = "D011",
    },

    --- Player Troops ---

    {
        id = "0001",
        type = "troop",
        name = "Tomorrow",
        textbox = "Plunder or strike: Create a Flair in hand if you don't already have one.",
        health = 20,
        max = 20,
        mcost = {
            { resource = "The Gate", amount = 5 },
            { resource = "The Scratch", amount = 5 },
        },
        D1 = "D001",
        D2 = "D001",
        D3 = "D002",
        D4 = "D003",
        D5 = "D001",
        D6 = "D001",
    },

    {
        id = "0002",
        type = "troop",
        name = "Samantha and\nMaximus",
        textbox = "Plunder or strike: Create a Flair in hand if you don't already have one.",
        health = 10,
        max = 20,
        D1 = "D001",
        D2 = "D001",
        D3 = "D002",
        D4 = "D001",
        D5 = "D001",
        D6 = "D001",
    },

    {
        id = "0003",
        type = "troop",
        name = "Apex",
        textbox = "Plunder or strike: Create a Flair in hand if you don't already have one.",
        health = 20,
        max = 20,
        D1 = "D001",
        D2 = "D001",
        D3 = "D002",
        D4 = "D001",
        D5 = "D001",
        D6 = "D001",
    },

    --- === Basic Troops === ---

    --- Washers ---

    {
        id = "BDWASHM",
        type = "troop",
        rname = "masc",
        rclass = "HIT",
        classname = "Washer",
        subclass = "Hitman",
        flavor = "Dressed for a funeral or two.",
        health = 5,
        max = 5,
        D1 = "BDMG2",
        D2 = "BDMG2",
        D3 = "BBLK1",
        D4 = "BBLK1",
        D5 = "BLK",
        D6 = "BLK",
    },

    --- Yankers

    {
        id = "BOMYANKM",
        type = "troop",
        rname = "masc",
        rclass = "BOM",
        classname = "Yanker",
        subclass = "Bomber",
        flavor = "Dressed for a funeral or two.",
        health = 5,
        max = 5,
        D1 = "BDMG2",
        D2 = "BDMG2",
        D3 = "BBLK1",
        D4 = "BBLK1",
        D5 = "BLK",
        D6 = "BLK",
    },

    {
        id = "BOMYANKF",
        type = "troop",
        rname = "fem",
        rclass = "BOM",
        classname = "Yanker",
        subclass = "Bomber",
        flavor = "Dressed for a funeral or two.",
        health = 5,
        max = 5,
        D1 = "BDMG2",
        D2 = "BDMG2",
        D3 = "BBLK1",
        D4 = "BBLK1",
        D5 = "BLK",
        D6 = "BLK",
    },

    --- === Aegis Troops === ---

    {
        id = "AEGBLK",
        type = "troop",
        name = "Black Beret",
        health = 1,
        max = 1,
        keyword = { "KWSAV"},
        flavor = "Not a moment of ceremony here. Just a job to do and the steel to get it done.",
        mcost = {
            { resource = "The Scratch", amount = 1 },
        },
        D1 = "BDMG3",
        D2 = "BDMG2",
        D3 = "BDMG2",
        D4 = "BDMG1",
        D5 = "BLK",
        D6 = "BLK",
    },

    {
        id = "AEGPSYBOM",
        type = "troop",
        name = "Psycho Bomber",
        health = 2,
        max = 2,
        D1 = "SAB2",
        D2 = "ATKANDSAB1",
        D3 = "ATKANDSAB1",
        D4 = "DIV3",
        D5 = "NUL",
        D6 = "NUL",
    },

    {
        id = "AEGLXSKY",
        type = "troop",
        name = "Lex Skydiver",
        health = 2,
        max = 2,
        keyword = { "KWSTRAT"},
        D1 = "TAC2",
        D2 = "BINF2",
        D3 = "INFTAC1",
        D4 = "INFTAC1",
        D5 = "NUL",
        D6 = "NUL",
    },


    --- === Token Troops === ---

    {
        id = "TK0001",
        type = "token",
        name = "Black Dagger",
        flavor = "The Black Daggers trace their history back to the Petro Age. Their most veteran aces are the only direct link back to that time - a source of stories too wonderful and horrific to really believe.",
        health = 2,
        max = 2,
        keyword = { "KWFLY", "KWTIME" },
        kwval = {
            KWTIME = 2,
        },
        D1 = "BDMG3",
        D2 = "BDMG2",
        D3 = "BDMG3",
        D4 = "NUL",
        D5 = "NUL",
        D6 = "NUL",
    },

    {
        id = "AEGPSYCOMM",
        type = "token",
        name = "Psycho Commando",
        health = 3,
        max = 3,
        D1 = "PDMG3",
        D2 = "PDMG2",
        D3 = "PDMG2",
        D4 = "NUL",
        D5 = "NUL",
        D6 = "NUL",
    },

    {
        id = "AEGFREYTOK",
        type = "token",
        name = "Freyja",
        health = 3,
        max = 3,
        D1 = "PDMG3",
        D2 = "PDMG2",
        D3 = "PDMG2",
        D4 = "NUL",
        D5 = "NUL",
        D6 = "NUL",
    },

}

return troops
