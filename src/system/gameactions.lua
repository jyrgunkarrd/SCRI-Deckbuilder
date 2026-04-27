local cardinstances = require("src.system.cardinstances")
local damagerules = require("src.system.damagerules")
local objectiveprogressrules = require("src.system.objectiveprogressrules")
local warzonecontrolrules = require("src.system.warzonecontrolrules")

local gameactions = {}

function gameactions.addObjectiveProgress(ctx, objectiveDefinition, amount, slotId)
    local state = ctx.state
    local result = objectiveprogressrules.addProgress(objectiveDefinition, amount, {
        slotId = slotId,
        activePrimaryObjective = state.activePrimaryObjective,
        objectiveEscalationActive = ctx.topsloteffects.isObjectiveEscalationActive(),
    })

    if result.progressEffect and result.progressEffect.overlayName == "progress" then
        ctx.topsloteffects.beginObjectiveProgress(result.progressEffect.overlayName, result.progressEffect.slotId)
        ctx.sfxrules.playProgress()
    elseif result.progressEffect and result.progressEffect.overlayName == "sabotage" then
        ctx.topsloteffects.beginObjectiveProgress(result.progressEffect.overlayName, result.progressEffect.slotId)
        ctx.sfxrules.playSabotage()
    end

    if result.shouldDestroyIntel then
        ctx.startIntelDestruction()
    end

    if result.escalationId then
        ctx.beginObjectiveEscalation(objectiveDefinition, result.escalationId)
    end

    if result.hunterId then
        ctx.beginObjectiveHunterDeckTransformation(objectiveDefinition, result.hunterId)
    end

    return result.appliedChange
end

function gameactions.canApplyObjectiveProgress(objectiveDefinition, amount)
    return objectiveprogressrules.canApplyProgress(objectiveDefinition, amount)
end

function gameactions.buildWarzoneControlContext(ctx, slotId)
    local state = ctx.state

    return {
        slotId = slotId,
        activeWarzone = state.activeWarzone,
        activePoi = state.activePoi,
        poiHunterTransformationActive = ctx.topsloteffects.isPoiHunterTransformationActive(),
        preloadTopStripAssets = ctx.envdraw.preloadTopStripAssets,
        beginWarzoneTransformation = ctx.beginWarzoneTransformation,
        beginPoiEmergenceEffect = ctx.beginPoiEmergenceEffect,
        beginPoiFlipEffect = ctx.beginPoiFlipEffect,
        beginPoiGeneratedCardTransformation = ctx.beginPoiGeneratedCardTransformation,
        setActiveWarzone = function(warzoneDefinition)
            state.activeWarzone = warzoneDefinition
        end,
        setActivePoi = function(poiDefinition)
            state.activePoi = poiDefinition
        end,
        onControlChanged = function(changedSlotId)
            state.damageJitters[changedSlotId or "warzone"] = {
                elapsed = 0,
                duration = ctx.damageJitterDuration,
                magnitude = ctx.damageJitterMagnitude,
            }
            ctx.sfxrules.playInfluence()
        end,
    }
end

function gameactions.addWarzoneControl(ctx, warzoneDefinition, amount, slotId)
    return warzonecontrolrules.addControl(
        warzoneDefinition,
        amount,
        gameactions.buildWarzoneControlContext(ctx, slotId)
    )
end

function gameactions.initializeCardHealthState(card)
    return cardinstances.initializeHealth(card)
end

function gameactions.initializeCardsHealthState(cardList)
    return cardinstances.initializeAllHealth(cardList)
end

function gameactions.dealDamageToCard(ctx, card, amount, suppressFeedback)
    local damageResult = damagerules.dealDamageToCard(card, amount)

    if damageResult and damageResult.changed and not suppressFeedback then
        local damagedCardIndex = nil

        for cardIndex, candidateCard in ipairs(ctx.state.cards) do
            if candidateCard == card then
                damagedCardIndex = cardIndex
                break
            end
        end

        if damagedCardIndex then
            ctx.triggerDamageFeedback(ctx.getDamageJitterKeyForCard(damagedCardIndex))

            if damageResult.killed then
                ctx.startCardDestruction(damagedCardIndex)
            end
        end
    end

    return damageResult
end

function gameactions.addBlockingToCard(card, amount)
    return damagerules.addBlockingToCard(card, amount)
end

function gameactions.healCard(card, amount)
    if not card or amount == nil then
        return nil
    end

    gameactions.initializeCardHealthState(card)

    if card.currentHealth == nil then
        return nil
    end

    local previousHealth = math.max(0, tonumber(card.currentHealth) or 0)
    local maxHealth = math.max(previousHealth, math.max(0, tonumber(card.maxHealth) or 0))
    local healAmount = math.max(0, tonumber(amount) or 0)

    card.currentHealth = math.min(maxHealth, previousHealth + healAmount)

    return {
        previousHealth = previousHealth,
        currentHealth = card.currentHealth,
        healed = card.currentHealth - previousHealth,
        changed = card.currentHealth > previousHealth,
    }
end

function gameactions.clearAllBlocking(ctx)
    return damagerules.clearAllBlocking(ctx.state.cards)
end

function gameactions.dealDamageToChampion(ctx, amount, suppressFeedback)
    local damageResult = damagerules.dealDamageToChampion(ctx.state.activeChampion, amount)

    if damageResult and damageResult.changed and not suppressFeedback then
        ctx.triggerDamageFeedback("champion")

        if damageResult.killed then
            ctx.startChampionDestruction()
        end
    end

    return damageResult
end

return gameactions
