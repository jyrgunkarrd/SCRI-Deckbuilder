local systemrules = {}

systemrules.SYSTEM_COUNT = 5

function systemrules.createFreshSystems(count)
    local systems = {}

    for systemIndex = 1, count or systemrules.SYSTEM_COUNT do
        systems[systemIndex] = {
            burned = false,
        }
    end

    return systems
end

function systemrules.ensureSystems(systems, count)
    systems = systems or {}

    for systemIndex = 1, count or systemrules.SYSTEM_COUNT do
        if type(systems[systemIndex]) ~= "table" then
            systems[systemIndex] = {
                burned = systems[systemIndex] == true,
            }
        elseif systems[systemIndex].burned == nil then
            systems[systemIndex].burned = false
        end
    end

    return systems
end

function systemrules.resetSystems(systems)
    systems = systemrules.ensureSystems(systems)

    for _, systemState in ipairs(systems) do
        systemState.burned = false
    end

    return systems
end

function systemrules.isSystemBurned(systems, systemIndex)
    local systemState = systems and systems[systemIndex] or nil

    return systemState == true or (type(systemState) == "table" and systemState.burned == true)
end

function systemrules.burnSystem(systems, systemIndex)
    systems = systemrules.ensureSystems(systems)

    local systemState = systems[systemIndex]

    if not systemState or systemState.burned then
        return false
    end

    systemState.burned = true
    return true
end

function systemrules.burnFreshSystem(systems)
    systems = systemrules.ensureSystems(systems)

    for systemIndex = 1, #systems do
        if not systems[systemIndex].burned then
            systems[systemIndex].burned = true
            return systemIndex
        end
    end

    return nil
end

function systemrules.restoreSystem(systems, systemIndex)
    systems = systemrules.ensureSystems(systems)

    local systemState = systems[systemIndex]

    if not systemState or not systemState.burned then
        return false
    end

    systemState.burned = false
    return true
end

function systemrules.getFreshSystemCount(systems)
    systems = systemrules.ensureSystems(systems)

    local freshCount = 0

    for _, systemState in ipairs(systems) do
        if not systemState.burned then
            freshCount = freshCount + 1
        end
    end

    return freshCount
end

return systemrules
