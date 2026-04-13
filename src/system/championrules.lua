local championDefinitions = require("data.champions")

local championrules = {}

local championsById = nil

local function loadChampions()
    if championsById ~= nil then
        return
    end

    championsById = {}

    for _, definition in ipairs(championDefinitions) do
        if definition.id then
            championsById[definition.id] = definition
        end
    end
end

function championrules.getChampion(championId)
    loadChampions()
    return championsById[championId]
end

return championrules
