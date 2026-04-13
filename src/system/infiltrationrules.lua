local infiltrationrules = {}

local INFILTRATION_CARD_DURATION = 0.34
local INFILTRATION_CARD_STAGGER = 0.08

local activeEffect = nil
local effectQueue = {}

function infiltrationrules.reset()
    activeEffect = nil
    effectQueue = {}
end

function infiltrationrules.begin(sourceRect, generatedCardDefinition, count)
    local copyCount = math.max(0, tonumber(count) or 0)

    if not sourceRect or not generatedCardDefinition or copyCount <= 0 then
        return false
    end

    local copies = {}

    for copyIndex = 1, copyCount do
        copies[#copies + 1] = {
            delay = (copyIndex - 1) * INFILTRATION_CARD_STAGGER,
            inserted = false,
            seed = love.math.random() * 1000,
        }
    end

    local effect = {
        elapsed = 0,
        duration = INFILTRATION_CARD_DURATION,
        seed = love.math.random() * 1000,
        sourceRect = sourceRect,
        generatedCardDefinition = generatedCardDefinition,
        copies = copies,
    }

    if activeEffect then
        effectQueue[#effectQueue + 1] = effect
    else
        activeEffect = effect
    end

    return true
end

function infiltrationrules.getActiveEffect()
    return activeEffect
end

function infiltrationrules.update(dt, onCopyComplete)
    if activeEffect then
        activeEffect.elapsed = activeEffect.elapsed + dt
        local allCopiesComplete = true

        for _, copy in ipairs(activeEffect.copies or {}) do
            local localElapsed = activeEffect.elapsed - (copy.delay or 0)

            if not copy.inserted and localElapsed >= activeEffect.duration then
                if onCopyComplete then
                    onCopyComplete(activeEffect.generatedCardDefinition)
                end

                copy.inserted = true
            end

            if not copy.inserted then
                allCopiesComplete = false
            end
        end

        if allCopiesComplete then
            activeEffect = table.remove(effectQueue, 1)
        end
    elseif #effectQueue > 0 then
        activeEffect = table.remove(effectQueue, 1)
    end
end

return infiltrationrules
