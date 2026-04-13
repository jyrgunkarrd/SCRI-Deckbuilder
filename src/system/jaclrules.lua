local jaclDefinitions = require("data.jacl")

local jaclrules = {}

local jaclsById = nil

local function loadJacls()
    if jaclsById ~= nil then
        return
    end

    jaclsById = {}

    for _, definition in ipairs(jaclDefinitions) do
        if definition.id then
            jaclsById[definition.id] = definition
        end
    end
end

function jaclrules.getJacl(jaclId)
    loadJacls()
    return jaclsById[jaclId]
end

return jaclrules
