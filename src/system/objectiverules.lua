local objectiveDefinitions = require("data.objectives")

local objectiverules = {}

local objectivesById = nil

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

local function resolveObjectiveValue(value)
    if type(value) == "table"
        and type(value.random) == "table"
        and value.random.min ~= nil
        and value.random.max ~= nil then
        local minValue = tonumber(value.random.min) or 0
        local maxValue = tonumber(value.random.max) or minValue

        if maxValue < minValue then
            minValue, maxValue = maxValue, minValue
        end

        return love.math.random(minValue, maxValue)
    end

    return cloneValue(value)
end

local function instantiateObjective(definition)
    if not definition then
        return nil
    end

    local instance = {}

    for key, value in pairs(definition) do
        instance[key] = resolveObjectiveValue(value)
    end

    return instance
end

local function loadObjectives()
    if objectivesById ~= nil then
        return
    end

    objectivesById = {}

    for _, definition in ipairs(objectiveDefinitions) do
        if definition.id then
            objectivesById[definition.id] = definition
        end
    end
end

function objectiverules.getObjective(objectiveId)
    loadObjectives()
    return instantiateObjective(objectivesById[objectiveId])
end

return objectiverules
