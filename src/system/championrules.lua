local championDefinitions = require("data.champions")

local championrules = {}

local championsById = nil

local function cloneValue(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}

    for key, nestedValue in pairs(value) do
        copy[key] = cloneValue(nestedValue)
    end

    return copy
end

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
    return cloneValue(championsById[championId])
end

return championrules
