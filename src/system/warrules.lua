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
local SAVIOR_KEYWORD_ID = "KWSAV"
local RELOADING_KEYWORD_ID = "KWRLD"
local TOME_CARD_TYPE = "tome"
local CACHE_CARD_TYPE = "cache"
local ENEMY_CARD_TARGET_TYPES = { "Atk", "AtkSab", "TAtk", "closeatk", "maulatk" }
local PLAYER_WARZONE_TARGET_TYPES = { "WZPlayer", "InfTac" }

local function hasFlyingKeyword(definition, card)
    return keywordrules.cardHasKeyword(definition, FLYING_KEYWORD_ID, card)
end

local function hasReloadingKeyword(definition, card)
    return keywordrules.cardHasKeyword(definition, RELOADING_KEYWORD_ID, card)
end

local function getCardIndexFromEntityKey(entityKey)
    local cardIndex = entityKey and entityKey:match("^card:(%d+)$")
    return cardIndex and tonumber(cardIndex) or nil
end

local function canAttackTarget(attackerDefinition, targetDefinition, attackerCard, targetCard)
    if targetDefinition and (targetDefinition.type == TOME_CARD_TYPE or targetDefinition.type == CACHE_CARD_TYPE) then
        return false
    end

    if hasFlyingKeyword(targetDefinition, targetCard) and not hasFlyingKeyword(attackerDefinition, attackerCard) then
        return false
    end

    return true
end

local function getTargetTypes(targetType)
    if type(targetType) == "table" then
        local targetTypes = {}

        for _, candidate in ipairs(targetType) do
            if candidate then
                targetTypes[#targetTypes + 1] = candidate
            end
        end

        return targetTypes
    end

    if targetType then
        return { targetType }
    end

    return {}
end

local function normalizeTargetType(targetType)
    return type(targetType) == "string" and targetType:lower() or targetType
end

local function hasTargetType(rollStateOrTargetType, targetType)
    local availableTargetType = rollStateOrTargetType

    if type(rollStateOrTargetType) == "table" and rollStateOrTargetType.targetType ~= nil then
        availableTargetType = rollStateOrTargetType.targetType
    end

    local normalizedTargetType = normalizeTargetType(targetType)

    for _, candidate in ipairs(getTargetTypes(availableTargetType)) do
        if normalizeTargetType(candidate) == normalizedTargetType then
            return true
        end
    end

    return false
end

local function getFirstTargetCardId(definition)
    if not definition then
        return nil
    end

    if type(definition.target) == "table" then
        return definition.target[1]
    end

    return definition.target
end

local function getTargetCardIds(definition)
    if not definition then
        return {}
    end

    if type(definition.target) == "table" then
        local targetCardIds = {}

        for _, targetCardId in ipairs(definition.target) do
            if targetCardId then
                targetCardIds[#targetCardIds + 1] = targetCardId
            end
        end

        return targetCardIds
    end

    if definition.target then
        return { definition.target }
    end

    return {}
end

local function firstTargetTypeMatching(rollStateOrTargetType, allowedTargetTypes)
    for _, targetType in ipairs(allowedTargetTypes or {}) do
        if hasTargetType(rollStateOrTargetType, targetType) then
            return targetType
        end
    end

    return nil
end

local function canTargetEnemyCard(rollStateOrTargetType)
    return firstTargetTypeMatching(rollStateOrTargetType, ENEMY_CARD_TARGET_TYPES) ~= nil
end

local function firstEnemyCardTargetType(rollStateOrTargetType)
    return firstTargetTypeMatching(rollStateOrTargetType, { "AtkSab", "TAtk", "Atk", "closeatk", "maulatk" })
        or firstTargetTypeMatching(rollStateOrTargetType, ENEMY_CARD_TARGET_TYPES)
end

local function canTargetPlayerWarzone(rollStateOrTargetType)
    return firstTargetTypeMatching(rollStateOrTargetType, PLAYER_WARZONE_TARGET_TYPES) ~= nil
end

local function getEffectiveTargetType(targetType)
    if type(targetType) == "table" then
        local mappedTargetTypes = {}

        for _, candidate in ipairs(targetType) do
            if normalizeTargetType(candidate) == "exoatk" then
                mappedTargetTypes[#mappedTargetTypes + 1] = "Atk"
            else
                mappedTargetTypes[#mappedTargetTypes + 1] = candidate
            end
        end

        return mappedTargetTypes
    end

    if normalizeTargetType(targetType) == "exoatk" then
        return "Atk"
    end

    return targetType
end

local function buildRollState(entityKey, definition, faceIndices, isEnemy, preserveState, sourceCard)
    if not definition or not faceIndices or #faceIndices == 0 then
        return nil
    end

    local selectedFaceIndex = faceIndices[love.math.random(1, #faceIndices)]
    local selectedFaceDefinition = carddraw.getCardFaceBadge(definition, selectedFaceIndex, sourceCard)
    local effectiveTargetType = getEffectiveTargetType(selectedFaceDefinition and selectedFaceDefinition.targ or nil)
    local autoReload = selectedFaceDefinition and hasTargetType(selectedFaceDefinition.targ, "exoatk") or false
    local isReloading = hasReloadingKeyword(definition, sourceCard)
    local targetCard = nil
    local targetCardIndex = nil
    local targetColumn = nil
    local damageValue = isReloading and 0 or math.max(0, tonumber(selectedFaceDefinition and selectedFaceDefinition.value) or 0)
    local targetType = isReloading and nil or effectiveTargetType
    local cardgen = selectedFaceDefinition and (selectedFaceDefinition.cardgen or getFirstTargetCardId(selectedFaceDefinition)) or nil
    local cardgenPool = selectedFaceDefinition and getTargetCardIds(selectedFaceDefinition) or {}
    local pain = not isReloading and (tonumber(selectedFaceDefinition and selectedFaceDefinition.pain) or 0) > 0

    if isReloading then
        cardgen = nil
        cardgenPool = {}
        autoReload = false
    end

    if isEnemy
        and selectedFaceDefinition
        and not isReloading
        and canTargetEnemyCard(effectiveTargetType)
        and #playerAttackTargets > 0 then
        local validTargets = {}

        for _, target in ipairs(playerAttackTargets) do
            if canAttackTarget(definition, target.definition, sourceCard, target.card) then
                validTargets[#validTargets + 1] = target
            end
        end

        if #validTargets > 0 then
            local targetIndex = love.math.random(1, #validTargets)
            local target = validTargets[targetIndex]

            targetCardIndex = target.cardIndex
            targetColumn = target.column
            targetCard = {
                kind = "card",
                setName = target.setName,
                cardId = target.cardId,
                displayName = target.displayName,
                portraitPath = target.portraitPath,
            }
            targetType = firstTargetTypeMatching(effectiveTargetType, ENEMY_CARD_TARGET_TYPES)
        end
    elseif selectedFaceDefinition
        and not isReloading
        and hasTargetType(effectiveTargetType, "Inf") then
        targetType = "Inf"
        targetCard = {
            kind = "deck",
        }
    elseif selectedFaceDefinition
        and not isReloading
        and hasTargetType(effectiveTargetType, "Obj")
        and objectiveTargetPreview then
        targetType = "Obj"
        targetCard = objectiveTargetPreview
    elseif selectedFaceDefinition
        and not isReloading
        and hasTargetType(effectiveTargetType, "IntCD")
        and entityKey == "intel"
        and intelTargetPreview then
        targetType = "IntCD"
        targetCard = intelTargetPreview
    elseif selectedFaceDefinition
        and not isReloading
        and hasTargetType(effectiveTargetType, "WZOpp")
        and warzoneTargetPreview then
        targetType = "WZOpp"
        targetCard = warzoneTargetPreview
    elseif selectedFaceDefinition
        and not isReloading
        and canTargetPlayerWarzone(effectiveTargetType)
        and warzoneTargetPreview then
        targetType = firstTargetTypeMatching(effectiveTargetType, PLAYER_WARZONE_TARGET_TYPES)
        targetCard = warzoneTargetPreview
    end

    return {
        faceIndex = selectedFaceIndex,
        pulseScale = 1,
        sourceDefinition = definition,
        sourceCard = sourceCard,
        damageValue = damageValue,
        targetType = targetType,
        targetCard = targetCard,
        targetCardIndex = targetCardIndex,
        targetColumn = targetColumn,
        cardgen = cardgen,
        cardgenPool = cardgenPool,
        pain = pain,
        autoReload = autoReload,
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
        activeWarRoll.isEnemy,
        nil,
        activeWarRoll.sourceCard
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
        and (
            canTargetEnemyCard(rollState)
            or hasTargetType(rollState, "Blk")
            or hasTargetType(rollState, "Div")
            or hasTargetType(rollState, "Inf")
            or hasTargetType(rollState, "rsmn")
            or hasTargetType(rollState, "Sab")
            or hasTargetType(rollState, "smn")
            or hasTargetType(rollState, "Tac")
            or hasTargetType(rollState, "TacSab")
            or canTargetPlayerWarzone(rollState)
        )
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
        return false
    end

    rollState.faceIndex = nil
    rollState.pulseScale = 1
    rollState.exhausted = true
    rollState.locked = false
    return true
end

function warrules.exhaustCard(cardIndex)
    local entityKey = warrules.getCardEntityKey(cardIndex)
    local rollState = warRollDisplayStates[entityKey]

    if not rollState then
        return false
    end

    rollState.exhausted = true
    rollState.locked = false
    return true
end

local function cardCanTriggerSavior(cardIndex, cards)
    local card = cards and cards[cardIndex] or nil

    if not card
        or not card.location
        or card.location.kind ~= "grid"
        or card.location.rowId ~= "PlayerRow"
        or card.destroyed
        or card.destroying then
        return false
    end

    local definition = cardregistry.getCard(card.setName, card.cardId)
    return keywordrules.cardHasKeyword(definition, SAVIOR_KEYWORD_ID)
end

local function isPlayerGridCardThreatenedWithDeath(card, cardIndex, isSourceActive)
    if not card
        or not card.location
        or card.location.kind ~= "grid"
        or card.location.rowId ~= "PlayerRow"
        or card.destroyed
        or card.destroying
        or not card.currentHealth then
        return false
    end

    local incomingDamage = warrules.getIncomingDamagePreview(cardIndex, isSourceActive)
    local healthDamage = warrules.getHealthDamagePreview(card, incomingDamage)
    return healthDamage >= card.currentHealth
end

function warrules.beginSaviorCheck(cardIndex, cards, isSourceActive)
    if not cardCanTriggerSavior(cardIndex, cards) then
        return nil
    end

    local threatenedCards = {}

    for targetCardIndex, card in ipairs(cards or {}) do
        if isPlayerGridCardThreatenedWithDeath(card, targetCardIndex, isSourceActive) then
            threatenedCards[targetCardIndex] = true
        end
    end

    if next(threatenedCards) == nil then
        return nil
    end

    return {
        cardIndex = cardIndex,
        threatenedCards = threatenedCards,
    }
end

function warrules.didSaviorPreventDeath(saviorCheck, cards, isSourceActive)
    if not saviorCheck or not saviorCheck.threatenedCards then
        return false
    end

    for cardIndex in pairs(saviorCheck.threatenedCards) do
        local card = cards and cards[cardIndex] or nil

        if card
            and card.location
            and card.location.kind == "grid"
            and card.location.rowId == "PlayerRow"
            and not card.destroyed
            and not card.destroying
            and card.currentHealth
            and not isPlayerGridCardThreatenedWithDeath(card, cardIndex, isSourceActive) then
            return true
        end
    end

    return false
end

local function buildTargetCardPreview(card)
    if not card then
        return nil
    end

    return {
        kind = "card",
        setName = card.setName,
        cardId = card.cardId,
        displayName = card.displayName,
        portraitPath = card.portraitPath,
    }
end

local function isAvailablePlayerAttackTarget(cards, cardIndex)
    local card = cards and cards[cardIndex] or nil

    return card
        and card.location
        and card.location.kind == "grid"
        and card.location.rowId == "PlayerRow"
        and not card.destroyed
        and not card.destroying
end

local function isLegalPlayerAttackTarget(cards, cardIndex, attackerDefinition, attackerCard)
    if not isAvailablePlayerAttackTarget(cards, cardIndex) then
        return false
    end

    local card = cards[cardIndex]
    local definition = cardregistry.getCard(card.setName, card.cardId)
    return canAttackTarget(attackerDefinition, definition, attackerCard, card)
end

local function shouldRetargetPlayerAttack(cards, cardIndex, attackerDefinition, attackerCard)
    if not isAvailablePlayerAttackTarget(cards, cardIndex) then
        return true
    end

    local card = cards[cardIndex]
    local definition = cardregistry.getCard(card.setName, card.cardId)

    return not canAttackTarget(attackerDefinition, definition, attackerCard, card)
end

local function findClosestLegalPlayerAttackTarget(cards, sourceDefinition, sourceCard, originalColumn)
    local bestCardIndex = nil
    local bestDistance = math.huge
    local bestColumn = math.huge

    for cardIndex, card in ipairs(cards or {}) do
        if isLegalPlayerAttackTarget(cards, cardIndex, sourceDefinition, sourceCard) then
            local column = card.location.column or 0
            local distance = math.abs(column - originalColumn)

            if distance < bestDistance or (distance == bestDistance and column < bestColumn) then
                bestCardIndex = cardIndex
                bestDistance = distance
                bestColumn = column
            end
        end
    end

    return bestCardIndex
end

function warrules.retargetIllegalEnemyAttacks(cards)
    local retargetedCount = 0

    for _, rollState in pairs(warRollDisplayStates) do
        if rollState
            and rollState.faceIndex
            and canTargetEnemyCard(rollState)
            and rollState.targetCardIndex then
            local sourceDefinition = rollState.sourceDefinition
            local sourceCard = rollState.sourceCard

            if shouldRetargetPlayerAttack(cards, rollState.targetCardIndex, sourceDefinition, sourceCard) then
                local targetCard = cards and cards[rollState.targetCardIndex] or nil
                local originalColumn = rollState.targetColumn
                    or (targetCard and targetCard.location and targetCard.location.column)
                    or 0
                local newTargetCardIndex = findClosestLegalPlayerAttackTarget(cards, sourceDefinition, sourceCard, originalColumn)

                if newTargetCardIndex then
                    local newTargetCard = cards[newTargetCardIndex]
                    rollState.targetCardIndex = newTargetCardIndex
                    rollState.targetCard = buildTargetCardPreview(newTargetCard)
                    rollState.targetColumn = newTargetCard.location.column
                else
                    rollState.targetCardIndex = nil
                    rollState.targetCard = nil
                    rollState.targetColumn = nil
                end

                retargetedCount = retargetedCount + 1
            end
        end
    end

    return retargetedCount
end

function warrules.redirectIncomingAttacks(cards, fromCardIndex, toCardIndex)
    if not cards or not fromCardIndex or not toCardIndex or fromCardIndex == toCardIndex then
        return 0
    end

    local targetCard = cards[toCardIndex]

    if not targetCard
        or not targetCard.location
        or targetCard.location.kind ~= "grid"
        or targetCard.location.rowId ~= "PlayerRow"
        or targetCard.destroyed
        or targetCard.destroying then
        return 0
    end

    local targetDefinition = cardregistry.getCard(targetCard.setName, targetCard.cardId)

    if targetDefinition and targetDefinition.type == TOME_CARD_TYPE then
        return 0
    end

    local redirectedCount = 0
    local targetPreview = buildTargetCardPreview(targetCard)

    for _, rollState in pairs(warRollDisplayStates) do
        if rollState
            and rollState.faceIndex
            and canTargetEnemyCard(rollState)
            and rollState.targetCardIndex == fromCardIndex
            and canAttackTarget(rollState.sourceDefinition, targetDefinition, rollState.sourceCard, targetCard) then
            rollState.targetCardIndex = toCardIndex
            rollState.targetCard = targetPreview
            rollState.targetColumn = targetCard.location.column
            redirectedCount = redirectedCount + 1
        end
    end

    return redirectedCount
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
                warRollDisplayStates[entityKey] = buildRollState(entityKey, definition, faceIndices, false, existingState, rowCard.card)
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

function warrules.refreshCardRollValue(cardIndex, cards)
    local entityKey = warrules.getCardEntityKey(cardIndex)
    local rollState = warRollDisplayStates[entityKey]
    local card = cards and cards[cardIndex] or nil

    if not rollState or not rollState.faceIndex or not card then
        return false
    end

    local definition = cardregistry.getCard(card.setName, card.cardId)
    local badgeDefinition = definition and carddraw.getCardFaceBadge(definition, rollState.faceIndex, card) or nil

    if not badgeDefinition then
        return false
    end

    rollState.damageValue = math.max(0, tonumber(badgeDefinition.value) or 0)
    return true
end

function warrules.rerollEntity(entityKey, definition, isEnemy, sourceCard)
    if not entityKey or not definition then
        return false
    end

    local faceIndices = carddraw.getAssignedFaceIndices(definition)

    if #faceIndices <= 0 then
        warRollDisplayStates[entityKey] = nil
        return false
    end

    warRollDisplayStates[entityKey] = buildRollState(entityKey, definition, faceIndices, isEnemy == true, nil, sourceCard)
    sfxrules.playDice()
    return true
end

function warrules.clearBlankResults()
    for entityKey, rollState in pairs(warRollDisplayStates) do
        if rollState
            and rollState.faceIndex
            and (rollState.damageValue or 0) <= 0
            and #getTargetTypes(rollState.targetType) == 0 then
            warRollDisplayStates[entityKey] = nil
        end
    end
end

function warrules.hasTargetType(rollStateOrTargetType, targetType)
    return hasTargetType(rollStateOrTargetType, targetType)
end

function warrules.firstTargetTypeMatching(rollStateOrTargetType, allowedTargetTypes)
    return firstTargetTypeMatching(rollStateOrTargetType, allowedTargetTypes)
end

function warrules.canTargetEnemyCard(rollStateOrTargetType)
    return canTargetEnemyCard(rollStateOrTargetType)
end

function warrules.canTargetPlayerWarzone(rollStateOrTargetType)
    return canTargetPlayerWarzone(rollStateOrTargetType)
end

function warrules.clearAllRollResults()
    warRollDisplayStates = {}
end

function warrules.triggerCounterStrikesOnTargeting(cards, activeChampion, dealDamageToCard, dealDamageToChampion)
    if not cards or not dealDamageToCard or not dealDamageToChampion then
        return 0
    end

    local counterStrikeCount = 0

    for entityKey, rollState in pairs(warRollDisplayStates) do
        local targetCard = rollState and rollState.targetCardIndex and cards[rollState.targetCardIndex] or nil

        if rollState
            and rollState.faceIndex
            and canTargetEnemyCard(rollState)
            and targetCard
            and targetCard.location
            and targetCard.location.kind == "grid"
            and targetCard.location.rowId == "PlayerRow"
            and not targetCard.destroyed
            and not targetCard.destroying then
            local targetDefinition = cardregistry.getCard(targetCard.setName, targetCard.cardId)

            if keywordrules.cardHasKeyword(targetDefinition, "KWCNTR", targetCard) then
                local counterDamage = math.max(
                    0,
                    tonumber(keywordrules.getCardKeywordValue(targetCard, targetDefinition, "KWCNTR")) or 0
                )

                if counterDamage > 0 then
                    if entityKey == "champion" then
                        if activeChampion and not activeChampion.hidden then
                            dealDamageToChampion(counterDamage)
                            counterStrikeCount = counterStrikeCount + 1

                            if activeChampion.hidden or (activeChampion.health or 0) <= 0 then
                                warrules.clearEntityRollState(entityKey)
                            end
                        end
                    else
                        local sourceCardIndex = getCardIndexFromEntityKey(entityKey)
                        local sourceCard = sourceCardIndex and cards[sourceCardIndex] or nil

                        if sourceCard and not sourceCard.destroyed and not sourceCard.destroying then
                            dealDamageToCard(sourceCard, counterDamage)
                            counterStrikeCount = counterStrikeCount + 1

                            if sourceCard.destroyed or sourceCard.destroying then
                                warrules.clearEntityRollState(entityKey)
                            end
                        end
                    end
                end
            end
        end
    end

    return counterStrikeCount
end

function warrules.getIncomingDamagePreview(cardIndex, isSourceActive)
    local incomingDamage = 0
    local cardKey = warrules.getCardEntityKey(cardIndex)

    for entityKey, rollState in pairs(warRollDisplayStates) do
        local sourceIsActive = isSourceActive == nil or isSourceActive(entityKey, rollState)

        if sourceIsActive
            and canTargetEnemyCard(rollState)
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
            and hasTargetType(rollState, "Obj")
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
            and hasTargetType(rollState, "IntCD")
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
            and hasTargetType(rollState, "WZOpp")
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
            and (hasTargetType(rollState, "WZOpp") or canTargetPlayerWarzone(rollState)) then
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
                (canTargetEnemyCard(rollState) and rollState.targetCardIndex)
                or (hasTargetType(rollState, "Inf") and rollState.targetCard and rollState.targetCard.kind == "deck")
                or (hasTargetType(rollState, "Obj") and rollState.targetCard and rollState.targetCard.kind == "objective")
                or hasTargetType(rollState, "WZOpp")
                or (hasTargetType(rollState, "IntCD") and rollState.targetCard and rollState.targetCard.kind == "intel")
            ) then
            pendingRetaliations[#pendingRetaliations + 1] = {
                entityKey = target.id,
                targetType = firstEnemyCardTargetType(rollState)
                    or firstTargetTypeMatching(rollState, { "Inf", "Obj", "WZOpp", "IntCD" }),
                targetCardIndex = rollState.targetCardIndex,
                targetCard = rollState.targetCard,
                damageValue = rollState.damageValue,
                cardgen = rollState.cardgen,
                pain = rollState.pain,
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
                (canTargetEnemyCard(rollState) and rollState.targetCardIndex)
                or (hasTargetType(rollState, "Inf") and rollState.targetCard and rollState.targetCard.kind == "deck")
                or (hasTargetType(rollState, "Obj") and rollState.targetCard and rollState.targetCard.kind == "objective")
                or hasTargetType(rollState, "WZOpp")
                or (hasTargetType(rollState, "IntCD") and rollState.targetCard and rollState.targetCard.kind == "intel")
            ) then
            pendingRetaliations[#pendingRetaliations + 1] = {
                entityKey = entityKey,
                targetType = firstEnemyCardTargetType(rollState)
                    or firstTargetTypeMatching(rollState, { "Inf", "Obj", "WZOpp", "IntCD" }),
                targetCardIndex = rollState.targetCardIndex,
                targetCard = rollState.targetCard,
                damageValue = rollState.damageValue,
                cardgen = rollState.cardgen,
                pain = rollState.pain,
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
                sourceCard = nil,
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
                        card = card,
                    }
                end
            end
        end

        table.sort(rowCards, function(a, b)
            return a.column < b.column
        end)

        for _, rowCard in ipairs(rowCards) do
            local faceIndices = carddraw.getAssignedFaceIndices(rowCard.definition)

            if rowId == "PlayerRow" and rowCard.definition.type ~= TOME_CARD_TYPE then
                playerAttackTargets[#playerAttackTargets + 1] = {
                    cardIndex = rowCard.cardIndex,
                    setName = rowCard.setName,
                    cardId = rowCard.cardId,
                    displayName = rowCard.displayName,
                    portraitPath = rowCard.portraitPath,
                    definition = rowCard.definition,
                    card = rowCard.card,
                }
            end

            if #faceIndices > 0 then
                pendingWarRolls[#pendingWarRolls + 1] = {
                    entityKey = warrules.getCardEntityKey(rowCard.cardIndex),
                    definition = rowCard.definition,
                    isEnemy = rowId == "OppRow",
                    faceIndices = faceIndices,
                    sourceCard = rowCard.card,
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

function warrules.canAttackTarget(attackerDefinition, targetDefinition, attackerCard, targetCard)
    return canAttackTarget(attackerDefinition, targetDefinition, attackerCard, targetCard)
end

return warrules
