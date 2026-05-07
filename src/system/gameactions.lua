local cardinstances = require("src.system.cardinstances")
local damagerules = require("src.system.damagerules")
local objectiveprogressrules = require("src.system.objectiveprogressrules")
local warzonecontrolrules = require("src.system.warzonecontrolrules")
local cardregistry = require("src.system.cardregistry")
local keywordrules = require("src.system.keywordrules")
local temporaryeffects = require("src.system.temporaryeffects")

local EVASION_KEYWORD_ID = "KWEVA"
local FAIR_WEATHER_KEYWORD_ID = "KWFAIR"
local FLYING_KEYWORD_ID = "KWFLY"
local ENEMY_ROW_ID = "OppRow"
local MARKER_CARD_TYPE = "marker"

local function getCardDefinition(card)
    if not card then
        return nil
    end

    return cardregistry.getCard(card.setName, card.cardId)
end

local function cardHasKeyword(card, keywordId)
    local cardDefinition = getCardDefinition(card)
    return keywordrules.cardHasKeyword(cardDefinition, keywordId, card)
end

local function isMarkerCard(card)
    local cardDefinition = getCardDefinition(card)
    return cardDefinition and cardDefinition.type == MARKER_CARD_TYPE or false
end

local function isLiveGridCard(card)
    if not card
        or not card.location
        or card.location.kind ~= "grid"
        or card.destroyed
        or card.destroying
    then
        return false
    end

    local currentHealth = tonumber(card.currentHealth)
    if currentHealth ~= nil and currentHealth <= 0 then
        return false
    end

    return true
end

local function isLiveEnemyGridCard(card)
    return isLiveGridCard(card)
        and card.location.rowId == ENEMY_ROW_ID
end

local function findCardIndex(cards, card)
    for cardIndex, candidateCard in ipairs(cards or {}) do
        if candidateCard == card then
            return cardIndex
        end
    end

    return nil
end

local function countLiveEnemyCardsInRow(cards, rowId)
    local count = 0

    for _, card in ipairs(cards or {}) do
        if isLiveEnemyGridCard(card) and card.location.rowId == rowId then
            count = count + 1
        end
    end

    return count
end

local function applyEvasionIfNeeded(card, damageResult)
    if not card
        or not damageResult
        or (tonumber(damageResult.healthDamage) or 0) <= 0
    then
        return false
    end

    if not cardHasKeyword(card, EVASION_KEYWORD_ID) then
        return false
    end

    temporaryeffects.addCardKeyword(card, FLYING_KEYWORD_ID)
    return true
end

local gameactions = {}

function gameactions.resolveFairWeatherEnemies(ctx)
    local state = ctx and ctx.state or nil
    if not state or not state.cards then
        return 0
    end

    local defeatedCount = 0

    for cardIndex, card in ipairs(state.cards) do
        if isLiveEnemyGridCard(card)
            and cardHasKeyword(card, FAIR_WEATHER_KEYWORD_ID)
        then
            local rowId = card.location.rowId
            local rowEnemyCount = countLiveEnemyCardsInRow(state.cards, rowId)

            if rowEnemyCount == 1 then
                ctx.startCardDestruction(cardIndex)
                defeatedCount = defeatedCount + 1
            end
        end
    end

    return defeatedCount
end

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
    if isMarkerCard(card) then
        return {
            previousHealth = card and card.currentHealth or nil,
            currentHealth = card and card.currentHealth or nil,
            previousBlocking = card and math.max(0, tonumber(card.blocking) or 0) or 0,
            currentBlocking = card and math.max(0, tonumber(card.blocking) or 0) or 0,
            blockedDamage = 0,
            preventedByKeywordDamage = math.max(0, tonumber(amount) or 0),
            healthDamage = 0,
            killed = false,
            changed = false,
        }
    end

    local damageResult = damagerules.dealDamageToCard(card, amount)
    applyEvasionIfNeeded(card, damageResult)

    if damageResult and damageResult.changed then
        local damagedCardIndex = findCardIndex(ctx.state.cards, card)

        if damagedCardIndex and ctx.warrules and ctx.warrules.refreshCardRollValue then
            ctx.warrules.refreshCardRollValue(damagedCardIndex, ctx.state.cards)
        end

        if damagedCardIndex and not suppressFeedback then
            ctx.triggerDamageFeedback(ctx.getDamageJitterKeyForCard(damagedCardIndex))

            if damageResult.killed then
                ctx.startCardDestruction(damagedCardIndex)
            end
        end
    end

    if damageResult and damageResult.changed then
        gameactions.resolveFairWeatherEnemies(ctx)
    end

    return damageResult
end

function gameactions.dealDirectDamageToCard(ctx, card, amount, suppressFeedback)
    if isMarkerCard(card) then
        return {
            previousHealth = card and card.currentHealth or nil,
            currentHealth = card and card.currentHealth or nil,
            previousBlocking = card and math.max(0, tonumber(card.blocking) or 0) or 0,
            currentBlocking = card and math.max(0, tonumber(card.blocking) or 0) or 0,
            blockedDamage = 0,
            preventedByKeywordDamage = math.max(0, tonumber(amount) or 0),
            healthDamage = 0,
            killed = false,
            changed = false,
        }
    end

    local damageResult = damagerules.dealDirectDamageToCard(card, amount)
    applyEvasionIfNeeded(card, damageResult)

    if damageResult and damageResult.changed then
        local damagedCardIndex = findCardIndex(ctx.state.cards, card)

        if damagedCardIndex and ctx.warrules and ctx.warrules.refreshCardRollValue then
            ctx.warrules.refreshCardRollValue(damagedCardIndex, ctx.state.cards)
        end

        if damagedCardIndex and not suppressFeedback then
            ctx.triggerDamageFeedback(ctx.getDamageJitterKeyForCard(damagedCardIndex))

            if damageResult.killed then
                ctx.startCardDestruction(damagedCardIndex)
            end
        end

        gameactions.resolveFairWeatherEnemies(ctx)
    end

    return damageResult
end

function gameactions.addBlockingToCard(card, amount, options)
    return damagerules.addBlockingToCard(card, amount, options)
end

function gameactions.healCard(ctx, card, amount)
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

    local healResult = {
        previousHealth = previousHealth,
        currentHealth = card.currentHealth,
        healed = card.currentHealth - previousHealth,
        changed = card.currentHealth > previousHealth,
    }

    if ctx
        and ctx.cardlifecycle
        and ctx.cardlifecycle.restoreIncapAgentIfRecovered then
        healResult.restoredIncapAgent = ctx.cardlifecycle.restoreIncapAgentIfRecovered(ctx, card)
    end

    return healResult
end

function gameactions.clearAllBlocking(ctx)
    return damagerules.clearAllBlocking(ctx.state.cards)
end

function gameactions.clearEnemyGuardCarryBlocking(ctx)
    return damagerules.clearEnemyGuardCarryBlocking(ctx.state.cards)
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
