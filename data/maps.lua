local maps = {
    {
        id = "A1BURN",
        name = "Act I - Burn It Down",
        start = {
            id = "START",
            nodeId = "START",
        },
        clusters = {
            {
                id = "C1",
                nodes = {
                    { id = "C1N1", nodeId = "BATTLE", branches = { "REGFOR", "GLORYFOR" } },
                    { id = "C1N2", nodeId = "BATTLE", branches = { "REGFOR", "GLORYFOR" } },
                    { id = "C1N3", nodeId = "EVENT", branches = { "CITY_EVENT", "JUNGLE_EVENT" } },
                    { id = "C1N4", nodeId = "PENULTIMATE", branches = { "GLORYFOR", "JUNGLE_EVENT" } },
                    { id = "C1N5", nodeId = "BOSS" },
                },
            },
        },
    },
}

return maps
