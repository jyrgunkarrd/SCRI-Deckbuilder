local turnrules = {}

local SETUP_PHASE = "Setup"
local WAR_SUBPHASES = {
    "Roll",
    "Engage",
    "Retaliate",
}
local PHASES = {
    "Start",
    "House",
    "Prelude",
    "War",
    "End",
}

local currentPhase = SETUP_PHASE
local currentWarSubphase = nil

function turnrules.getPhases()
    return PHASES
end

function turnrules.getSetupPhase()
    return SETUP_PHASE
end

function turnrules.getCurrentPhase()
    return currentPhase
end

function turnrules.getWarSubphases()
    return WAR_SUBPHASES
end

function turnrules.getCurrentWarSubphase()
    return currentWarSubphase
end

function turnrules.isWarRollPhase()
    return currentPhase == "War" and currentWarSubphase == WAR_SUBPHASES[1]
end

function turnrules.beginWarPhase()
    currentPhase = "War"
    currentWarSubphase = WAR_SUBPHASES[1]
    return currentPhase, currentWarSubphase
end

function turnrules.advanceWarSubphase()
    if currentPhase ~= "War" then
        return currentWarSubphase
    end

    if currentWarSubphase == nil then
        currentWarSubphase = WAR_SUBPHASES[1]
        return currentWarSubphase
    end

    for subphaseIndex, subphaseName in ipairs(WAR_SUBPHASES) do
        if subphaseName == currentWarSubphase then
            currentWarSubphase = WAR_SUBPHASES[math.min(subphaseIndex + 1, #WAR_SUBPHASES)]
            return currentWarSubphase
        end
    end

    return currentWarSubphase
end

function turnrules.setCurrentPhase(phaseName)
    if phaseName == SETUP_PHASE then
        currentPhase = phaseName
        currentWarSubphase = nil
        return true
    end

    for _, candidate in ipairs(PHASES) do
        if candidate == phaseName then
            currentPhase = phaseName
            currentWarSubphase = phaseName == "War" and WAR_SUBPHASES[1] or nil
            return true
        end
    end

    return false
end

function turnrules.beginStartPhase()
    currentPhase = PHASES[1]
    currentWarSubphase = nil
end

function turnrules.advancePhase()
    if currentPhase == SETUP_PHASE then
        currentPhase = PHASES[1]
        currentWarSubphase = nil
        return currentPhase
    end

    for phaseIndex, phaseName in ipairs(PHASES) do
        if phaseName == currentPhase then
            currentPhase = PHASES[(phaseIndex % #PHASES) + 1]
            currentWarSubphase = currentPhase == "War" and WAR_SUBPHASES[1] or nil
            return currentPhase
        end
    end

    return currentPhase
end

function turnrules.reset()
    currentPhase = SETUP_PHASE
    currentWarSubphase = nil
end

return turnrules
