local mapnodes = {
    {
        id = "REGFOR",
        name = "Regular Forces",
        type = "combat",
        icon = "regfor",
        accentColor = { 0.5, 0.5, 0.5, 1 },
        pos = "bottom",
        preview = {
            title = "Regular Forces",
            summary = "Standard combat encounter.",
            details = {
                "Moderate enemy pressure.",
                "Reliable upgrade rewards.",
            },
        },
        encounterPool = "A1C1",
        prize = 100, 
        cardrw = "regular",
    },

}

return mapnodes
