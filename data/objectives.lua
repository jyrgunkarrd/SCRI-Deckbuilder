-- data/objectives.lua
-- Objective definitions

--- Primary Objectives ---

local objectives = {

    --- PAM Objective ---

    {
        id = "PRIMOBJ0001",
        name = "Longinus III",
        plan = 0,
        max = 12,
        type = "objective",
        flavor = "...the collisions were inevitable. And in an environment saturated with high velocity debris, only the most nimble and armored spacecraft could survive...",
        emphasis = 2,
        escalate = "PRIMOBJ0003",
        hunterid = "HNTSAT",
        D1 = "EXODMG10",
        D2 = "INF1",
        D3 = "NUL",
        D4 = "NUL",
        D5 = "NUL",
        D6 = "NUL",
    },

    {
        id = "PRIMOBJ0002",
        name = "Saint Nancy Space Center",
        plan = 0,
        max = 6,
        type = "objective",
        flavor = "As Low Earth Orbit filled with vanity projects and weapon platforms of dubious capability, ground-based astronomy became impossible...",
        emphasis = 2,
        escalate = "PRIMOBJ0001",
        hunterid = "HNTROLL",
        D1 = "INF1",
        D2 = "NUL",
        D3 = "NUL",
        D4 = "NUL",
        D5 = "NUL",
        D6 = "NUL",
    },

    {
        id = "PRIMOBJ0003",
        name = "A Flash Of Light",
        plan = 0,
        max = 4,
        type = "objective",
        textbox = "...blind to the stars, any enthusiasm for the night sky usually rests in the minds of those hoping to parlay with one of the old guns still intact up there.",
        emphasis = 2,
        loss = true,
        losstext = "Light and sound slam into the midnight hour across Sermon City, rattling windows and terriifying cats. A clap of thunder? And yet there's no rain.\n\nA shallow tremor stalks the moment to its grave.\n\n\"She got them. She'll want another target.\"",
        D1 = "EXOARDMG10",
        D2 = "EXOARDMG10",
        D3 = "EXODMG10",
        D4 = "EXODMG10",
        D5 = "INF2",
        D6 = "INF1",
    },

    --- Fort Chroma Objective ---

    {
        id = "PRIMOBJACTPNK",
        name = "Project Pink",
        plan = 0,
        max = 4,
        type = "objective",
        flavor = "...the collisions were inevitable. And in an environment saturated with high velocity debris, only the most nimble and armored spacecraft could survive...",
        emphasis = 2,
        escalate = "PRIMOBJ0003",
        hunterid = "HNTINFFM",
        D1 = "EXODMG10",
        D2 = "INF1",
        D3 = "NUL",
        D4 = "NUL",
        D5 = "NUL",
        D6 = "NUL",
    },

--- Intelligence ---

    {
        id = "INT0001",
        name = "WarGaze",
        plan = 3,
        max = 3,
        type = "intel",
        flavor = "\"YOU HAVE 20 SECONDS TO COMPLY.\"",
        D1 = "BDMG3",
        D2 = "ARDMG1",
        D3 = "NUL",
        D4 = "NUL",
        D5 = "NUL",
        D6 = "NUL",
    },

    {
        id = "INT0000",
        name = "No Signal",
        plan = 6,
        max = 6,
        type = "intel",
        flavor = "\"...RECONNECTING...\"",
        D1 = "WARR3",
        D2 = "WARR2",
        D3 = "WARR2",
        D4 = "WARR2",
        D5 = "WARR2",
        D6 = "WARR1",
    },

    {
        id = "INT0002",
        name = "Rat Meat",
        plan = 3,
        max = 3,
        type = "intel",
        flavor = "\"Collaborators earn that moniker in so many more ways than one.\"",
        D1 = "INF1",
        D2 = "THR2",
        D3 = "NUL",
        D4 = "NUL",
        D5 = "NUL",
        D6 = "NUL",
    },

    {
        id = "INT0003",
        name = "Boom Tap",
        plan = 3,
        max = 3,
        type = "intel",
        flavor = "Antique military systems are more primitive in an extremely deadly kind of way.",
        D1 = "EXODMG5",
        D2 = "OBJ2",
        D3 = "NUL",
        D4 = "NUL",
        D5 = "NUL",
        D6 = "NUL",
    },
}

return objectives
