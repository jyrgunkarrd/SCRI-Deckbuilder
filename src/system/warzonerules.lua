local warzoneDefinitions = require("data.warzones")

local warzonerules = {}

local warzonesById = nil

local function loadWarzones()
    if warzonesById ~= nil then
        return
    end

    warzonesById = {}

    for _, definition in ipairs(warzoneDefinitions) do
        if definition.id then
            warzonesById[definition.id] = definition
        end
    end
end

function warzonerules.getWarzone(warzoneId)
    loadWarzones()
    return warzonesById[warzoneId]
end

function warzonerules.getRandomWarzoneByIdSuffix(idSuffix)
    loadWarzones()

    local matchingWarzones = {}

    for _, definition in pairs(warzonesById) do
        if definition
            and definition.type == "warzone"
            and definition.id
            and idSuffix
            and definition.id:sub(-#idSuffix) == idSuffix then
            matchingWarzones[#matchingWarzones + 1] = definition
        end
    end

    if #matchingWarzones == 0 then
        return nil
    end

    return matchingWarzones[love.math.random(1, #matchingWarzones)]
end

function warzonerules.getControlVariant(warzoneDefinition)
    loadWarzones()

    if not warzoneDefinition or warzoneDefinition.type ~= "warzone" or not warzoneDefinition.id then
        return nil
    end

    local variantId = nil

    if warzoneDefinition.id:sub(-1) == "B" then
        variantId = warzoneDefinition.id:sub(1, -2)
    else
        variantId = warzoneDefinition.id .. "B"
    end

    return warzonesById[variantId]
end

function warzonerules.getPairedVariant(definition)
    loadWarzones()

    if not definition or not definition.id then
        return nil
    end

    local variantId = nil

    if definition.id:sub(-1) == "B" then
        variantId = definition.id:sub(1, -2)
    else
        variantId = definition.id .. "B"
    end

    return warzonesById[variantId]
end

return warzonerules
