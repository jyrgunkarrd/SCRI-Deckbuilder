-- data/kit.lua
-- kit definitions

local kit = {

    --- B6 Kit ---

    {
        id = "B6CYBLD",
        name = "Thrill Razor",
        type = "kit",
        classname = "Starter",
        subclass = "Kit",
        func = "deathdraw",
        value = 2,
        keyword = { "KWCNTR", "KWKIT" },
        kwval = {
            KWCNTR = 1,
        },
        textbox = "When an attached card is defeated, draw 2 cards.",
        flavor = "Sermon City is never short on deadly surprises.",
    },
}

return kit
