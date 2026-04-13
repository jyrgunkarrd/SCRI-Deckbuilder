local warrules = {}
local carddraw = require("src.render.carddraw")
local cardregistry = require("src.system.cardregistry")
local keywordrules = require("src.system.keywordrules")
local sfxrules = require("src.audio.sfxrules")

local pendingWarRolls = {}
local warRollDisplayStates = {}
local playerAttackTargets = {}
local ROLLS_PER_UPDATE = 1
local ROLL_SETTLE_DELAY = 0.16
local rollSettleTimer = 0
local RETALIATE_STEP_DELAY = 0.18
local pendingRetaliations = {}
local retaliateTimer = 0
local objectiveTargetPreview = nil
local intelTargetPreview = nil
local warzoneTargetPreview = nil
local FLYING_KEYWORD_ID = "KWFLY"

local function hasFlyingKeyword(definition)
    return keywordrules.cardHasKeyword(definition, FLYING_KEYWORD_ID)
end

local function canAttackTarget(attackerDefinition, targetDefinition)
    if hasFlyingKeyword(targetDefinition) and not hasFlyingKeyword(attackerDefinition) then
        return false
    end

    return true
end

local function buildRollState(entityKey, definition, faceIndices, isEnemy, preserveState)
    if not definition or not faceIndices or #faceIndices == 0 then
        return nil
    end

    local selectedFaceIndex = faceIndices[love.math.random(1, #faceIndices)]
    local selectedFaceDefinition = carddraw.getDefinitionFaceBadge(definition, selectedFaceIndex)
    local targetCard = nil
    local targetCardIndex = nil
    local damageValue = math.max(0, tonumber(selectedFaceDefinition and selectedFaceDefinition.value) or 0)
    local targetType = selectedFaceDefinition and selectedFaceDefinition.targ or nil
    local cardgen = selectedFaceDefinition and selectedFaceDefinition.cardgen or nil

    if isEnemy
        and selectedFaceDefinition
        and selectedFaceDefinition.targ == "Atk"
        and #playerAttackTargets > 0 then
        local validTargets = {}

        for _, target in ipairs(playerAttackTargets) do
            if canAttackTarget(definition, target.definition) then
                validTargets[#validTargets + 1] = target
            end
        end

        if #validTargets > 0 then
            local targetIndex = love.math.random(1, #validTargets)
            local target = validTargets[targetIndex]

            targetCardIndex = target.cardIndex
            targetCard = {
                kind = "card",
                setName = target.setName,
                cardId = target.cardId,
                displayName = target.displayName,
                portraitPath = target.portraitPath,
            }
        end
    elseif selectedFaceDefinition
        and selectedFaceDefinition.targ == "Inf" then
        targetCard = {
            kind = "deck",
        }
    elseif selectedFaceDefinition
        and selectedFaceDefinition.targ == "Obj"
        and objectiveTargetPreview then
        targetCard = objectiveTargetPreview
    elseif selectedFaceDefinition
        and selectedFaceDefinition.targ == "IntCD"
        and entityKey == "intel"
        and intelTargetPreview then
        targetCard = intelTargetPreview
    elseif selectedFaceDefinition
        and selectedFaceDefinition.targ == "WZOpp"
        and warzoneTargetPreview then
        targetCard = warzoneTargetPreview
    elseif selectedFaceDefinition
        and selectedFaceDefinition.targ == "WZPlayer"
        and warzoneTargetPreview then
        targetCard = warzoneTargetPreview
    end

    return {
        faceIndex = selectedFaceIndex,
        pulseScale = 1,
        damageValue = damageValue,
        targetType = targetType,
        targetCard = targetCard,
        targetCardIndex = targetCardIndex,
        cardgen = cardgen,
        exhausted = preserveState and preserveState.exhausted or false,
        locked = preserveState and preserveState.locked or false,
    }
end

local function resolveNextWarRoll()
    if #pendingWarRolls == 0 then
        return false
    end

    local activeWarRoll = table.remove(pendingWarRolls, 1)

    sfxrules.playDice()
    warRollDisplayStates[activeWarRoll.entityKey] = buildRollState(
        activeWarRoll.entityKey,
        activeWarRoll.definition,
        activeWarRoll.faceIndices,
        activeWarRoll.isEnemy
    )

    return true
end

function warrules.reset()
    pendingWarRolls = {}
    warRollDisplayStates = {}
    playerAttackTargets = {}
    rollSettleTimer = 0
    pendingRetaliations = {}
    retaliateTimer = 0
    objectiveTargetPreview = nil
    intelTargetPreview = nil
    warzoneTargetPreview = nil
end

function warrules.getCardEntityKey(cardIndex)
    return "card:" .. tostring(cardIndex)
end

function warrules.getDisplayStates()
    return warRollDisplayStates
end

function warrules.getCardRollState(cardIndex)
    return warRollDisplayStates[warrules.getCardEntityKey(cardIndex)]
end

function warrules.canCardAttack(cardIndex)
    local rollState = warrules.getCardRollState(cardIndex)

    return rollState
        and not rollState.exhausted
        and (rollState.targetType == "Atk" or rollState.targetType == "Blk" or rollState.targetType == "Inf" or rollState.targetType == "Sab" or rollState.targetType == "WZPlayer")
        and (rollState.damageValue or 0) > 0
end

function warrules.isCardExhausted(cardIndex)
    local rollState = warrules.getCardRollState(cardIndex)
    return rollState and rollState.exhausted == true or false
end

function warrules.consumeCardAttack(cardIndex)
    local entityKey = warrules.getCardEntityKey(cardIndex)
    local rollState = warRollDisplayStates[entityKey]

    if not rollState then
        return
    end

    rollState.faceIndex = nil
    rollState.pulseScale = 1
    rollState.exhausted = true
    rollState.locked = false
end

function warrules.toggleCardLock(cardIndex)
    local rollState = warrules.getCardRollState(cardIndex)

    if not rollState or not rollState.faceIndex or rollState.exhausted then
        return false
    end

    rollState.locked = not rollState.locked
    return rollState.locked
end

function warrules.rerollUnlockedPlayerCards(cards)
    local rerolledAny = false
    local rowCards = {}

    for cardIndex, card in ipairs(cards or {}) do
        if card.location
            and card.location.kind == "grid"
            and card.location.rowId == "PlayerRow" then
            rowCards[#rowCards + 1] = {
                cardIndex = cardIndex,
                column = card.location.column,
                setName = card.setName,
                cardId = card.cardId,
            }
        end
    end

    table.sort(rowCards, function(a, b)
        return a.column < b.column
    end)

    for _, rowCard in ipairs(rowCards) do
        local entityKey = warrules.getCardEntityKey(rowCard.cardIndex)
        local existingState = warRollDisplayStates[entityKey]

        if existingState
            and existingState.faceIndex
            and not existingState.exhausted
            and not existingState.locked then
            local definition = cardregistry.getCard(rowCard.setName, rowCard.cardId)
            local faceIndices = carddraw.getAssignedFaceIndices(definition)

            if #faceIndices > 0 then
                warRollDisplayStates[entityKey] = buildRollState(entityKey, definition, faceIndices, false, existingState)
                rerolledAny = true
            end
        end
    end

    return rerolledAny
end

function warrules.clearEntityRollState(entityKey)
    if not entityKey then
        return
    end

    warRollDisplayStates[entityKey] = nil
end

function warrules.clearCardRollState(cardIndex)
    warrules.clearEntityRollState(warrules.getCardEntityKey(cardIndex))
end

function warrules.rerollEntity(entityKey, definition, isEnemy)
    if not entityKey or not definition then
        return false
    end

    local faceIndices = carddraw.getAssignedFaceIndices(definition)

    if #faceIndices <= 0 then
        warRollDisplayStates[entityKey] = nil
        return false
    end

    warRollDisplayStates[entityKey] = buildRollState(entityKey, definition, faceIndices, isEnemy == true)
    sfxrules.playDice()
    return true
end

function warrules.clearBlankResults()
    for entityKey, rollState in pairs(warRollDisplayStates) do
        if rollState
            and rollState.faceIndex
            and (rollState.damageValue or 0) <= 0
            and rollState.targetType == nil then
            warRollDisplayStates[entityKey] = nil
        end
    end
end

function warrules.clearAllRollResults()
    warRollDisplayStates = {}
end

function warrules.getIncomingDamagePreview(cardIndex, isSourceActive)
    local incomingDamage = 0
    local cardKey = warrules.getCardEntityKey(cardIndex)

    for entityKey, rollState in pairs(warRollDisplayStates) do
        local sourceIsActive = isSourceActive == nil or isSourceActive(entityKey, rollState)

        if sourceIsActive
            and rollState.targetType == "Atk"
            and rollState.targetCardIndex
            and warrules.getCardEntityKey(rollState.targetCardIndex) == cardKey then
            incomingDamage = incomingDamage + (rollState.damageValue or 0)
        end
    end

    return incomingDamage
end

function warrules.getBlockedDamagePreview(card, incomingDamage)
    local damage = math.max(0, tonumber(incomingDamage) or 0)
    local blocking = math.max(0, tonumber(card and card.blocking) or 0)

    return math.min(blocking, damage)
end

function warrules.getHealthDamagePreview(card, incomingDamage)
    local damage = math.max(0, tonumber(incomingDamage) or 0)
    local blocking = math.max(0, tonumber(card and card.blocking) or 0)

    return math.max(0, damage - blocking)
end

function warrules.getObjectiveProgressPreview(objectiveId, isSourceActive)
    local incomingProgress = 0

    if not objectiveId then
        return incomingProgress
    end

    for entityKey, rollState in pairs(warRollDisplayStates) do
        local sourceIsActive = isSourceActive == nil or isSourceActive(entityKey, rollState)

        if sourceIsActive
            and rollState.targetType == "Obj"
            and rollState.targetCard
            and rollState.targetCard.kind == "objective"
            and rollState.targetCard.objectiveId == objectiveId then
            incomingProgress = incomingProgress + (rollState.damageValue or 0)
        end
    end

    return incomingProgress
end

function warrules.getIntelProgressPreview(intelId, isSourceActive)
    local incomingProgress = 0

    if not intelId then
        return incomingProgress
    end

    for entityKey, rollState in pairs(warRollDisplayStates) do
        local sourceIsActive = isSourceActive == nil or isSourceActive(entityKey, rollState)

        if sourceIsActive
            and rollState.targetType == "IntCD"
            and rollState.targetCard
            and rollState.targetCard.kind == "intel"
            and rollState.targetCard.objectiveId == intelId then
            incomingProgress = incomingProgress + (rollState.damageValue or 0)
        end
    end

    return incomingProgress
end

function warrules.getWarzoneControlPreview(warzoneId, currentControl, maxControl, isSourceActive)
    local incomingThreat = 0

    if not warzoneId then
        return nil
    end

    for entityKey, rollState in pairs(warRollDisplayStates) do
        local sourceIsActive = isSourceActive == nil or isSourceActive(entityKey, rollState)

        if sourceIsActive
            and rollState.targetType == "WZOpp"
            and rollState.targetCard
            and rollState.targetCard.kind == "warzone"
            and rollState.targetCard.warzoneId == warzoneId then
            incomingThreat = incomingThreat + (rollState.damageValue or 0)
        end
    end

    if incomingThreat <= 0 then
        return nil
    end

    local signedControl = tonumber(currentControl) or 0
    local controlCap = math.max(0, tonumber(maxControl) or 0)
    local preview = {
        overlayPips = 0,
        extendPips = 0,
    }

    if signedControl > 0 then
        preview.overlayPips = math.min(signedControl, incomingThreat)

        local overflowIntoNegative = math.max(0, incomingThreat - preview.overlayPips)
        preview.extendPips = math.min(controlCap, overflowIntoNegative)
    else
        local remainingNegativeSpace = math.max(0, controlCap - math.abs(signedControl))
        preview.extendPips = math.min(remainingNegativeSpace, incomingThreat)
    end

    if preview.overlayPips <= 0 and preview.extendPips <= 0 then
        return nil
    end

    return preview
end

function warrules.setWarzoneTargetPreview(warzoneDefinition)
    warzoneTargetPreview = warzoneDefinition and {
        kind = "warzone",
        warzoneId = warzoneDefinition.id,
    } or nil

    for _, rollState in pairs(warRollDisplayStates) do
        if rollState
            and rollState.targetCard
            and rollState.targetCard.kind == "warzone"
            and (rollState.targetType == "WZOpp" or rollState.targetType == "WZPlayer") then
            rollState.targetCard = warzoneTargetPreview
        end
    end
end

function warrules.isRollSequenceComplete()
    return #pendingWarRolls == 0
end

function warrules.beginRetaliatePhase(topSlotTargets, cards)
    pendingRetaliations = {}
    retaliateTimer = 0

    for _, target in ipairs(topSlotTargets or {}) do
        local rollState = warRollDisplayStates[target.id]

        if rollState
            and rollState.faceIndex
            and (rollState.damageValue or 0) > 0
            and (
                (rollState.targetType == "Atk" and rollState.targetCardIndex)
                or (rollState.targetType == "Inf" and rollState.targetCard and rollState.targetCard.kind == "deck")
                or (rollState.targetType == "Obj" and rollState.targetCard and rollState.targetCard.kind == "objective")
                or rollState.targetType == "WZOpp"
                or (rollState.targetType == "IntCD" and rollState.targetCard and rollState.targetCard.kind == "intel")
            ) then
            pendingRetaliations[#pendingRetaliations + 1] = {
                entityKey = target.id,
                targetType = rollState.targetType,
                targetCardIndex = rollState.targetCardIndex,
                targetCard = rollState.targetCard,
                damageValue = rollState.damageValue,
                cardgen = rollState.cardgen,
                isTopSlot = true,
            }
        end
    end

    local rowCards = {}

    for cardIndex, card in ipairs(cards or {}) do
        if card.location
            and card.location.kind == "grid"
            and card.location.rowId == "OppRow" then
            rowCards[#rowCards + 1] = {
                cardIndex = cardIndex,
                column = card.location.column,
            }
        end
    end

    table.sort(rowCards, function(a, b)
        return a.column < b.column
    end)

    for _, rowCard in ipairs(rowCards) do
        local entityKey = warrules.getCardEntityKey(rowCard.cardIndex)
        local rollState = warRollDisplayStates[entityKey]

        if rollState
            and rollState.faceIndex
            and (rollState.damageValue or 0) > 0
            and (
                (rollState.targetType == "Atk" and rollState.targetCardIndex)
                or (rollState.targetType == "Inf" and rollState.targetCard and rollState.targetCard.kind == "deck")
                or (rollState.targetType == "Obj" and rollState.targetCard and rollState.targetCard.kind == "objective")
                or rollState.targetType == "WZOpp"
                or (rollState.targetType == "IntCD" and rollState.targetCard and rollState.targetCard.kind == "intel")
            ) then
            pendingRetaliations[#pendingRetaliations + 1] = {
                entityKey = entityKey,
                targetType = rollState.targetType,
                targetCardIndex = rollState.targetCardIndex,
                targetCard = rollState.targetCard,
                damageValue = rollState.damageValue,
                cardgen = rollState.cardgen,
                isTopSlot = false,
            }
        end
    end
end

function warrules.updateRetaliate(dt, currentPhase, currentWarSubphase)
    if currentPhase ~= "War" or currentWarSubphase ~= "Retaliate" then
        return nil
    end

    if retaliateTimer > 0 then
        retaliateTimer = math.max(0, retaliateTimer - dt)

        if retaliateTimer > 0 then
            return nil
        end
    end

    local retaliation = table.remove(pendingRetaliations, 1)

    if not retaliation then
        return nil
    end

    retaliateTimer = RETALIATE_STEP_DELAY
    return retaliation
end

function warrules.isRetaliationComplete()
    return #pendingRetaliations == 0 and retaliateTimer <= 0
end

function warrules.resetPlayerCardStates(cards)
    for cardIndex, card in ipairs(cards or {}) do
        if card.location
            and card.location.kind == "grid"
            and card.location.rowId == "PlayerRow" then
            local rollState = warrules.getCardRollState(cardIndex)

            if rollState then
                rollState.exhausted = false
                rollState.locked = false
            end
        end
    end
end

function warrules.beginPhase(topSlotTargets, cards, primaryObjectiveDefinition, intelDefinition, warzoneDefinition)
    pendingWarRolls = {}
    warRollDisplayStates = {}
    playerAttackTargets = {}
    rollSettleTimer = 0
    objectiveTargetPreview = primaryObjectiveDefinition and {
        kind = "objective",
        objectiveId = primaryObjectiveDefinition.id,
    } or nil
    intelTargetPreview = intelDefinition and not intelDefinition.hidden and {
        kind = "intel",
        objectiveId = intelDefinition.id,
    } or nil
    warrules.setWarzoneTargetPreview(warzoneDefinition)

    for _, target in ipairs(topSlotTargets or {}) do
        local faceIndices = carddraw.getAssignedFaceIndices(target.definition)

        if #faceIndices > 0 then
            pendingWarRolls[#pendingWarRolls + 1] = {
                entityKey = target.id,
                definition = target.definition,
                isEnemy = true,
                faceIndices = faceIndices,
            }
        end
    end

    local function appendRowCards(rowId)
        local rowCards = {}

        for cardIndex, card in ipairs(cards or {}) do
            if card.location
                and card.location.kind == "grid"
                and card.location.rowId == rowId
                and not card.destroyed
                and not card.destroying then
                local definition = cardregistry.getCard(card.setName, card.cardId)

                if definition then
                    rowCards[#rowCards + 1] = {
                        cardIndex = cardIndex,
                        column = card.location.column,
                        setName = card.setName,
                        cardId = card.cardId,
                        displayName = card.displayName,
                        portraitPath = card.portraitPath,
                        definition = definition,
                    }
                end
            end
        end

        table.sort(rowCards, function(a, b)
            return a.column < b.column
        end)

        for _, rowCard in ipairs(rowCards) do
            local faceIndices = carddraw.getAssignedFaceIndices(rowCard.definition)

            if rowId == "PlayerRow" then
                playerAttackTargets[#playerAttackTargets + 1] = {
                    cardIndex = rowCard.cardIndex,
                    setName = rowCard.setName,
                    cardId = rowCard.cardId,
                    displayName = rowCard.displayName,
                    portraitPath = rowCard.portraitPath,
                    definition = rowCard.definition,
                }
            end

            if #faceIndices > 0 then
                pendingWarRolls[#pendingWarRolls + 1] = {
                    entityKey = warrules.getCardEntityKey(rowCard.cardIndex),
                    definition = rowCard.definition,
                    isEnemy = rowId == "OppRow",
                    faceIndices = faceIndices,
                }
            end
        end
    end

    appendRowCards("OppRow")
    appendRowCards("PlayerRow")
end

function warrules.update(dt, currentPhase)
    if currentPhase ~= "War" then
        return
    end

    if rollSettleTimer > 0 then
        rollSettleTimer = math.max(0, rollSettleTimer - dt)

        if rollSettleTimer > 0 then
            return
        end
    end

    for _ = 1, ROLLS_PER_UPDATE do
        if not resolveNextWarRoll() then
            break
        end

        rollSettleTimer = ROLL_SETTLE_DELAY
    end
end

function warrules.canAttackTarget(attackerDefinition, targetDefinition)
    return canAttackTarget(attackerDefinition, targetDefinition)
end

return warrules
