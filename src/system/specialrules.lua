local specialDefinitions = require("data.special")

local specialrules = {}

local specialsById = nil

local function loadSpecials()
    if specialsById ~= nil then
        return
    end

    specialsById = {}

    for _, definition in ipairs(specialDefinitions) do
        if definition.id then
            specialsById[definition.id] = definition
        end
    end
end

function specialrules.getSpecial(specialId)
    loadSpecials()
    return specialsById[specialId]
end

return specialrules
