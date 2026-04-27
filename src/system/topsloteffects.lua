local carddraw = require("src.render.carddraw")
local cardregistry = require("src.system.cardregistry")
local objectiverules = require("src.system.objectiverules")
local sfxrules = require("src.audio.sfxrules")
local warrules = require("src.system.warrules")

local topsloteffects = {}

local DESTRUCTION_DURATION = 0.6
local OBJECTIVE_PROGRESS_EFFECT_DURATION = 0.42
local OBJECTIVE_PROGRESS_JITTER_MAGNITUDE = 5
local OBJECTIVE_ESCALATION_EFFECT_DURATION = 0.95
local OBJECTIVE_ESCALATION_SWAP_PROGRESS = 0.72
local OBJECTIVE_ESCALATION_JITTER_MAGNITUDE = 8
local WARZONE_TRANSFORMATION_EFFECT_DURATION = 0.52
local POI_EMERGENCE_EFFECT_DURATION = 0.56
local POI_FLIP_EFFECT_DURATION = 0.48
local POI_HUNTER_TRANSFORMATION_DURATION = 0.72

local championDestructionState = nil
local intelDestructionState = nil
local objectiveProgressEffect = nil
local objectiveEscalationEffect = nil
local warzoneTransformationEffect = nil
local poiEmergenceEffect = nil
local poiFlipEffect = nil
local poiHunterTransformationEffect = nil

local function progressFor(effect)
    return effect and math.min(1, effect.elapsed / effect.duration) or nil
end

local function preloadTopStripAsset(preloadTopStripAssets, slotId, definition)
    if not preloadTopStripAssets or not definition then
        return
    end

    if slotId == "warzone" then
        preloadTopStripAssets(nil, definition, nil, nil, nil)
    elseif slotId == "poi" then
        preloadTopStripAssets(nil, nil, definition, nil, nil)
    elseif slotId == "objective" then
        preloadTopStripAssets(nil, nil, nil, definition, nil)
    end
end

function topsloteffects.reset()
    championDestructionState = nil
    intelDestructionState = nil
    objectiveProgressEffect = nil
    objectiveEscalationEffect = nil
    warzoneTransformationEffect = nil
    poiEmergenceEffect = nil
    poiFlipEffect = nil
    poiHunterTransformationEffect = nil
end

function topsloteffects.startChampionDestruction(activeChampion)
    if not activeChampion or championDestructionState then
        return false
    end

    championDestructionState = {
        elapsed = 0,
        duration = DESTRUCTION_DURATION,
        seed = love.math.random() * 1000,
    }
    warrules.clearEntityRollState("champion")
    sfxrules.playDestroy()
    return true
end

function topsloteffects.startIntelDestruction(activeIntel)
    if not activeIntel or intelDestructionState or activeIntel.hidden then
        return false
    end

    intelDestructionState = {
        elapsed = 0,
        duration = DESTRUCTION_DURATION,
        seed = love.math.random() * 1000,
    }
    warrules.clearEntityRollState("intel")
    sfxrules.playDestroy()
    return true
end

function topsloteffects.isChampionDestructionActive()
    return championDestructionState ~= nil
end

function topsloteffects.beginObjectiveProgress(overlayName, slotId)
    objectiveProgressEffect = {
        elapsed = 0,
        duration = OBJECTIVE_PROGRESS_EFFECT_DURATION,
        overlayName = overlayName,
        slotId = slotId or "objective",
    }
end

function topsloteffects.getObjectiveProgressJitterOffset()
    local offsetX = 0
    local offsetY = 0

    if objectiveProgressEffect then
        local progress = progressFor(objectiveProgressEffect)
        local remainingRatio = math.max(0, 1 - progress)
        local amplitude = OBJECTIVE_PROGRESS_JITTER_MAGNITUDE * remainingRatio
        offsetX = offsetX + (math.sin(objectiveProgressEffect.elapsed * 84) * amplitude)
        offsetY = offsetY + (math.cos(objectiveProgressEffect.elapsed * 66) * amplitude * 0.45)
    end

    if objectiveEscalationEffect then
        local progress = progressFor(objectiveEscalationEffect)
        local swapWindow = math.max(0, 1 - math.min(1, math.abs(progress - objectiveEscalationEffect.swapProgress) / 0.28))
        local amplitude = OBJECTIVE_ESCALATION_JITTER_MAGNITUDE * swapWindow
        offsetX = offsetX + (math.sin((objectiveEscalationEffect.elapsed + objectiveEscalationEffect.seed) * 92) * amplitude)
        offsetY = offsetY + (math.cos((objectiveEscalationEffect.elapsed + objectiveEscalationEffect.seed) * 71) * amplitude * 0.55)
    end

    return offsetX, offsetY
end

function topsloteffects.getObjectiveProgressEffectSlotId()
    return objectiveProgressEffect and objectiveProgressEffect.slotId or nil
end

function topsloteffects.isObjectiveEscalationActive()
    return objectiveEscalationEffect ~= nil
end

function topsloteffects.beginObjectiveEscalation(objectiveDefinition, escalationId, preloadTopStripAssets)
    local targetObjective = escalationId and objectiverules.getObjective(escalationId) or nil

    if not objectiveDefinition or not targetObjective then
        return false
    end

    objectiveEscalationEffect = {
        elapsed = 0,
        duration = OBJECTIVE_ESCALATION_EFFECT_DURATION,
        swapProgress = OBJECTIVE_ESCALATION_SWAP_PROGRESS,
        seed = love.math.random() * 1000,
        sourceObjective = objectiveDefinition,
        targetObjective = targetObjective,
        swapApplied = false,
    }
    preloadTopStripAsset(preloadTopStripAssets, "objective", targetObjective)
    return true
end

function topsloteffects.beginWarzoneTransformation(sourceWarzone, targetWarzone, preloadTopStripAssets)
    if not sourceWarzone or not targetWarzone then
        return false
    end

    warzoneTransformationEffect = {
        elapsed = 0,
        duration = WARZONE_TRANSFORMATION_EFFECT_DURATION,
        seed = love.math.random() * 1000,
        sourceWarzone = sourceWarzone,
        targetWarzone = targetWarzone,
        mode = targetWarzone.id and targetWarzone.id:sub(-1) == "B" and "breach" or "restore",
    }
    sfxrules.playFlip()
    preloadTopStripAsset(preloadTopStripAssets, "warzone", targetWarzone)
    return true
end

function topsloteffects.beginPoiEmergence()
    poiEmergenceEffect = {
        elapsed = 0,
        duration = POI_EMERGENCE_EFFECT_DURATION,
        seed = love.math.random() * 1000,
    }
end

function topsloteffects.beginPoiFlip(sourcePoi, targetPoi, preloadTopStripAssets)
    if not sourcePoi or not targetPoi then
        return false
    end

    poiFlipEffect = {
        elapsed = 0,
        duration = POI_FLIP_EFFECT_DURATION,
        seed = love.math.random() * 1000,
        sourcePoi = sourcePoi,
        targetPoi = targetPoi,
    }
    preloadTopStripAsset(preloadTopStripAssets, "poi", targetPoi)
    return true
end

function topsloteffects.beginPoiGeneratedCardTransformation(poiDefinition, generatedCardId, getNextOpenHandSlot)
    if not poiDefinition or not generatedCardId then
        return false
    end

    local generatedCardDefinition = cardregistry.getCardById(generatedCardId)

    if not generatedCardDefinition then
        return false
    end

    local openHandSlot = getNextOpenHandSlot and getNextOpenHandSlot() or nil
    local targetLocation = openHandSlot and {
        kind = "hand",
        slotIndex = openHandSlot,
    } or {
        kind = "deck",
    }

    carddraw.preloadPortrait(generatedCardDefinition.setName, generatedCardDefinition.id)
    poiHunterTransformationEffect = {
        elapsed = 0,
        duration = POI_HUNTER_TRANSFORMATION_DURATION,
        seed = love.math.random() * 1000,
        sourceSlotId = "poi",
        sourcePoi = poiDefinition,
        generatedCardDefinition = generatedCardDefinition,
        targetLocation = targetLocation,
    }
    return true
end

function topsloteffects.beginObjectiveHunterDeckTransformation(objectiveDefinition, generatedCardId)
    if not objectiveDefinition or not generatedCardId then
        return false
    end

    local generatedCardDefinition = cardregistry.getCardById(generatedCardId)

    if not generatedCardDefinition then
        return false
    end

    carddraw.preloadPortrait(generatedCardDefinition.setName, generatedCardDefinition.id)
    poiHunterTransformationEffect = {
        elapsed = 0,
        duration = POI_HUNTER_TRANSFORMATION_DURATION,
        seed = love.math.random() * 1000,
        sourceSlotId = "objective",
        sourceObjective = objectiveDefinition,
        generatedCardDefinition = generatedCardDefinition,
        targetLocation = {
            kind = "deck",
        },
    }
    return true
end

function topsloteffects.isPoiHunterTransformationActive()
    return poiHunterTransformationEffect ~= nil
end

function topsloteffects.update(dt)
    local events = {}

    if championDestructionState then
        championDestructionState.elapsed = championDestructionState.elapsed + dt

        if championDestructionState.elapsed >= championDestructionState.duration then
            events.championDestroyed = true
            championDestructionState = nil
        end
    end

    if intelDestructionState then
        intelDestructionState.elapsed = intelDestructionState.elapsed + dt

        if intelDestructionState.elapsed >= intelDestructionState.duration then
            events.intelDestroyed = true
            intelDestructionState = nil
        end
    end

    if objectiveProgressEffect then
        objectiveProgressEffect.elapsed = objectiveProgressEffect.elapsed + dt

        if objectiveProgressEffect.elapsed >= objectiveProgressEffect.duration then
            objectiveProgressEffect = nil
        end
    end

    if objectiveEscalationEffect then
        objectiveEscalationEffect.elapsed = objectiveEscalationEffect.elapsed + dt
        local progress = progressFor(objectiveEscalationEffect)

        if not objectiveEscalationEffect.swapApplied
            and progress >= objectiveEscalationEffect.swapProgress then
            events.objectiveEscalationSwap = objectiveEscalationEffect.targetObjective
            objectiveEscalationEffect.swapApplied = true
        end

        if objectiveEscalationEffect.elapsed >= objectiveEscalationEffect.duration then
            objectiveEscalationEffect = nil
        end
    end

    if warzoneTransformationEffect then
        warzoneTransformationEffect.elapsed = warzoneTransformationEffect.elapsed + dt

        if warzoneTransformationEffect.elapsed >= warzoneTransformationEffect.duration then
            warzoneTransformationEffect = nil
        end
    end

    if poiEmergenceEffect then
        poiEmergenceEffect.elapsed = poiEmergenceEffect.elapsed + dt

        if poiEmergenceEffect.elapsed >= poiEmergenceEffect.duration then
            poiEmergenceEffect = nil
        end
    end

    if poiFlipEffect then
        poiFlipEffect.elapsed = poiFlipEffect.elapsed + dt

        if poiFlipEffect.elapsed >= poiFlipEffect.duration then
            poiFlipEffect = nil
        end
    end

    if poiHunterTransformationEffect then
        poiHunterTransformationEffect.elapsed = poiHunterTransformationEffect.elapsed + dt

        if poiHunterTransformationEffect.elapsed >= poiHunterTransformationEffect.duration then
            events.poiHunterTransformationComplete = {
                sourceSlotId = poiHunterTransformationEffect.sourceSlotId,
                generatedCardDefinition = poiHunterTransformationEffect.generatedCardDefinition,
                targetLocation = poiHunterTransformationEffect.targetLocation,
            }
            poiHunterTransformationEffect = nil
        end
    end

    return events
end

function topsloteffects.getRenderStates()
    local states = {
        objectiveProgressProgress = objectiveProgressEffect and progressFor(objectiveProgressEffect) or nil,
        objectiveProgressOverlayName = objectiveProgressEffect and objectiveProgressEffect.overlayName or nil,
        objectiveProgressSlotId = objectiveProgressEffect and objectiveProgressEffect.slotId or nil,
    }

    if championDestructionState or intelDestructionState then
        states.destructionStates = {}

        if championDestructionState then
            states.destructionStates.champion = {
                progress = progressFor(championDestructionState),
                seed = championDestructionState.seed,
            }
        end

        if intelDestructionState then
            states.destructionStates.intel = {
                progress = progressFor(intelDestructionState),
                seed = intelDestructionState.seed,
            }
        end
    end

    if objectiveEscalationEffect then
        states.objectiveEscalation = {
            progress = progressFor(objectiveEscalationEffect),
            swapProgress = objectiveEscalationEffect.swapProgress,
            seed = objectiveEscalationEffect.seed,
            sourceObjective = objectiveEscalationEffect.sourceObjective,
            targetObjective = objectiveEscalationEffect.targetObjective,
            swapApplied = objectiveEscalationEffect.swapApplied,
        }
    end

    if warzoneTransformationEffect then
        states.warzoneTransformation = {
            progress = progressFor(warzoneTransformationEffect),
            seed = warzoneTransformationEffect.seed,
            sourceWarzone = warzoneTransformationEffect.sourceWarzone,
            targetWarzone = warzoneTransformationEffect.targetWarzone,
            mode = warzoneTransformationEffect.mode,
        }
    end

    if poiEmergenceEffect then
        states.poiEmergence = {
            progress = progressFor(poiEmergenceEffect),
            seed = poiEmergenceEffect.seed,
        }
    end

    if poiFlipEffect then
        states.poiFlip = {
            progress = progressFor(poiFlipEffect),
            seed = poiFlipEffect.seed,
            sourcePoi = poiFlipEffect.sourcePoi,
            targetPoi = poiFlipEffect.targetPoi,
        }
    end

    if poiHunterTransformationEffect then
        states.poiHunterTransformation = {
            progress = progressFor(poiHunterTransformationEffect),
            seed = poiHunterTransformationEffect.seed,
            sourceSlotId = poiHunterTransformationEffect.sourceSlotId,
            sourcePoi = poiHunterTransformationEffect.sourcePoi,
            sourceObjective = poiHunterTransformationEffect.sourceObjective,
            generatedCardDefinition = poiHunterTransformationEffect.generatedCardDefinition,
            targetLocation = poiHunterTransformationEffect.targetLocation,
        }
    end

    return states
end

return topsloteffects
