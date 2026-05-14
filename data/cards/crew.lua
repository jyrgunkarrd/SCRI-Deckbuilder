-- data/crew.lua
-- crew definitions

local crew = {

{
    id = "CREWCPT",
    type = "crew",
    name = "Captain",
    classname = "Crew",
    subclass = "JACL Staff",
    func = "CREWCPTFUNC",
    btn = true,
    btnheader = "Make It Happen",
    btntext = "Draw a card. Burn a System.",
    flavor = "No vessel can exceed the worth of its captain.",
    health = 1,
    max = 1,
},

{
    id = "CREWSRG",
    type = "crew",
    name = "Surgeon",
    classname = "Crew",
    subclass = "JACL Staff",
    func = "CREWSRGFUNC",
    btn = true,
    btnheader = "Sewn Up",
    btntext = "Heal a card and remove all negative conditions from it. Burn a System.",
    flavor = "Good medical hygiene is the backbone of any operation.",
    health = 1,
    max = 1,
},

{
    id = "CREWSHR",
    type = "crew",
    name = "Sheriff",
    classname = "Crew",
    subclass = "JACL Staff",
    func = "CREWSHRFUNC",
    btn = true,
    btnheader = "Book 'Em",
    btntext = "Discard a random Hunter from your deck. Burn a System.",
    flavor = "It takes a certain type of personality to sniff out Fool's Meat.",
    health = 1,
    max = 1,
},

{
    id = "CREWTAC",
    type = "crew",
    name = "Tactician",
    classname = "Crew",
    subclass = "JACL Staff",
    func = "CREWTACFUNC",
    btn = true,
    btnheader = "Lit Up",
    btntext = "Defeat an enemy with exactly 2 health. Burn a System.",
    flavor = "\"Bullseye.\"",
    health = 1,
    max = 1,
},

{
    id = "CREWENG",
    type = "crew",
    name = "Engineer",
    classname = "Crew",
    subclass = "JACL Staff",
    func = "CREWENGFUNC",
    btn = true,
    btnheader = "Blast Doors",
    btntext = "Add 2 block to a card. Burn a System.",
    flavor = "Working miracles is just what they do.",
    health = 1,
    max = 1,
},

}

return crew
