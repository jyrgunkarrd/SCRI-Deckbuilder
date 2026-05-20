local phasecontroller = {}
local REGEN_KEYWORD_ID = "KWREGEN"
local keywordrules = require("src.system.keywordrules")
local crewrules = require("src.system.crewrules")
local CACHE_CARD_TYPE = "cache"
local MEAT_CACHE_CARD_ID = "MEATTOK"

local function getCardIndexFromEntityKey(entityKey)
    local cardIndex = entityKey and entityKey:match("^card:(%d+)$")
    return cardIndex and tonumber(cardIndex) or nil
end

local function findCardIndex(cards, card)
    if not card then
        return nil
    end

    for cardIndex, candidateCard in ipairs(cards or {}) do
        if candidateCard == card then
            return cardIndex
        end
    end

    return nil
end

local getRetaliationSourceCardIndex

local function applyAreaDamageToAdjacentCards(gameState, deps, retaliation)
    if not retaliation
        or retaliation.area ~= true
        or not retaliation.targetCardIndex then
        return
    end

    local adjacentCardIndices = deps.warrules.getAdjacentSameRowCardIndices(gameState.cards, retaliation.targetCardIndex)

    for _, adjacentCardIndex in ipairs(adjacentCardIndices) do
        local adjacentCard = gameState.cards[adjacentCardIndex]

        if adjacentCard and not deps.isCardUnavailable(adjacentCard) then
            local damageResult = deps.dealDamageToCard(adjacentCard, retaliation.damageValue or 0)

            if damageResult and damageResult.killed then
                local sourceCardIndex = getRetaliationSourceCardIndex(gameState, retaliation)

                if sourceCardIndex and deps.trooprules then
                    deps.trooprules.resolveKill(sourceCardIndex, adjacentCardIndex, {
                        cards = gameState.cards,
                        cardregistry = deps.cardregistry,
                        spawnTokensNearCard = deps.spawnTokensNearCard,
                    })
                end
            end
        end
    end
end

local function applyConditionsToTarget(targetEntity, targetDefinition, rollState)
    local conditionValue = rollState and math.max(0, tonumber(rollState.damageValue) or 0) or 0

    if conditionValue <= 0 or not targetEntity or not targetDefinition or type(rollState.applycond) ~= "table" then
        return nil
    end

    local applied = nil

    for _, conditionId in ipairs(rollState.applycond) do
        if conditionId then
            applied = keywordrules.addCardKeywordValue(targetEntity, targetDefinition, conditionId, conditionValue)
        end
    end

    return applied
end

local function applyMangleToTarget(deps, targetCard, targetDefinition, rollState)
    if rollState
        and rollState.mangle == true
        and deps.warrules
        and deps.warrules.mangleCardFaces then
        return deps.warrules.mangleCardFaces(targetCard, targetDefinition, rollState.damageValue or 0)
    end

    return 0
end

local function findLowestHealthOppRowCard(cards, deps)
    local lowestCardIndex = nil
    local lowestCard = nil
    local lowestHealth = nil
    local lowestColumn = nil

    for cardIndex, card in ipairs(cards or {}) do
        if card
            and not deps.isCardUnavailable(card)
            and card.location
            and card.location.kind == "grid"
            and card.location.rowId == "OppRow" then
            local currentHealth = math.max(0, tonumber(card.currentHealth) or 0)
            local column = card.location.column or cardIndex

            if currentHealth > 0
                and (
                    lowestHealth == nil
                    or currentHealth < lowestHealth
                    or (
                        currentHealth == lowestHealth
                        and (
                            column < lowestColumn
                            or (column == lowestColumn and cardIndex < lowestCardIndex)
                        )
                    )
                ) then
                lowestCardIndex = cardIndex
                lowestCard = card
                lowestHealth = currentHealth
                lowestColumn = column
            end
        end
    end

    return lowestCardIndex, lowestCard
end

getRetaliationSourceCardIndex = function(gameState, retaliation)
    local sourceCardIndex = retaliation.sourceCardIndex or getCardIndexFromEntityKey(retaliation.entityKey)

    if sourceCardIndex
        and gameState.cards
        and gameState.cards[sourceCardIndex] == retaliation.sourceCard then
        return sourceCardIndex
    end

    return findCardIndex(gameState.cards, retaliation.sourceCard) or sourceCardIndex
end

local function resolveSummonRetaliation(gameState, deps, retaliation)
    local sourceCardIndex = getRetaliationSourceCardIndex(gameState, retaliation)
    local spawnCount = math.max(0, math.floor(tonumber(retaliation.damageValue) or 0))

    if not sourceCardIndex or spawnCount <= 0 then
        if deps.notifications then
            deps.notifications.push("Summon failed: no source")
        end

        return false
    end

    if (retaliation.targetType == "smn" or retaliation.summonOnAttack == true) and deps.spawnTokensNearCard then
        local generatedCardDefinition = deps.cardregistry.getCardById(retaliation.cardgen)

        if generatedCardDefinition then
            local spawnedCount = deps.spawnTokensNearCard(sourceCardIndex, generatedCardDefinition, spawnCount)

            if spawnedCount > 0 then
                if deps.notifications then
                    deps.notifications.push("Summoned " .. generatedCardDefinition.name)
                end

                return true
            end

            if deps.notifications then
                deps.notifications.push("Summon failed: no open OppRow cell")
            end

            return false
        end

        if deps.notifications then
            deps.notifications.push("Summon failed: missing " .. tostring(retaliation.cardgen))
        end
    elseif retaliation.targetType == "rsmn" and deps.spawnRandomTokensNearCard then
        local generatedCardDefinitions = {}

        for _, cardId in ipairs(retaliation.cardgenPool or {}) do
            local generatedCardDefinition = deps.cardregistry.getCardById(cardId)

            if generatedCardDefinition then
                generatedCardDefinitions[#generatedCardDefinitions + 1] = generatedCardDefinition
            end
        end

        if #generatedCardDefinitions > 0 then
            local spawnedCount = deps.spawnRandomTokensNearCard(sourceCardIndex, generatedCardDefinitions, spawnCount)

            if spawnedCount > 0 then
                if deps.notifications then
                    deps.notifications.push("Summoned enemy")
                end

                return true
            end

            if deps.notifications then
                deps.notifications.push("Summon failed: no open OppRow cell")
            end

            return false
        end

        if deps.notifications then
            deps.notifications.push("Summon failed: no valid pool")
        end
    elseif deps.notifications then
        deps.notifications.push("Summon failed: missing spawn helper")
    end

    return false
end

local function resolveCardWoundDamage(gameState, deps, card)
    local cardDefinition = card and deps.cardregistry.getCard(card.setName, card.cardId) or nil
    local woundValue = keywordrules.getWoundValue(card, cardDefinition)

    if woundValue <= 0 or not deps.dealDirectDamageToCard then
        return nil
    end

    return deps.dealDirectDamageToCard(card, woundValue)
end

local function resolvePlayerWounds(gameState, deps)
    for _, card in ipairs(gameState.cards or {}) do
        if card
            and card.location
            and card.location.kind == "grid"
            and card.location.rowId == "PlayerRow"
            and not deps.isCardUnavailable(card) then
            resolveCardWoundDamage(gameState, deps, card)
        end
    end
end

local function resolveEnemyWounds(gameState, deps)
    local championWoundValue = keywordrules.getWoundValue(gameState.activeChampion, gameState.activeChampion)

    if championWoundValue > 0 then
        deps.dealDamageToChampion(championWoundValue)
    end

    for _, card in ipairs(gameState.cards or {}) do
        if card
            and card.location
            and card.location.kind == "grid"
            and card.location.rowId == "OppRow"
            and not deps.isCardUnavailable(card) then
            resolveCardWoundDamage(gameState, deps, card)
        end
    end
end

local function applyRetaliationSideEffects(gameState, deps, retaliation)
    local sourceCardIndex = getCardIndexFromEntityKey(retaliation.entityKey)
    local sourceCard = sourceCardIndex and gameState.cards[sourceCardIndex] or nil

    if not sourceCard or deps.isCardUnavailable(sourceCard) then
        return
    end

    if retaliation.selfBlock == true then
        deps.addBlockingToCard(sourceCard, retaliation.damageValue or 0, {
            carryEnemyGuard = sourceCard.location
                and sourceCard.location.kind == "grid"
                and sourceCard.location.rowId == "OppRow",
        })
    end

    if retaliation.selfHeal == true and deps.healCard then
        deps.healCard(sourceCard, retaliation.damageValue or 0)
    end
end

local function buildStartPhaseGenerators(gameState, deps)
    local gridCardGenerators = {}

    for cardIndex, card in ipairs(gameState.cards) do
        if deps.isGridCard(card) and not deps.isCardUnavailable(card) then
            local drawX, drawY, expansionProgress, renderOptions = deps.getCardDrawPosition(card, cardIndex)
            local cardDefinition = deps.cardregistry.getCard(card.setName, card.cardId)
            local methodEntries = card.method or cardDefinition and cardDefinition.method or nil
            local methodBadgeCenters = deps.carddraw.getMethodBadgeCenters(card.setName, card.cardId, drawX, drawY, expansionProgress, renderOptions)

            if methodBadgeCenters and #methodBadgeCenters > 0 and methodEntries then
                gridCardGenerators[#gridCardGenerators + 1] = {
                    column = card.location.column,
                    methodBadgeCenters = methodBadgeCenters,
                    methodEntries = methodEntries,
                }
            end
        end
    end

    local topSlotGenerators = {}
    local topSlots = deps.envdraw.getTopSlotLayouts(
        deps.turnrules.getCurrentPhase(),
        gameState.activeChampion,
        gameState.activeWarzone,
        gameState.activePoi,
        gameState.activePrimaryObjective,
        gameState.activeIntel
    )

    for _, slot in ipairs(topSlots or {}) do
        if slot.id == "warzone"
            and slot.definition
            and slot.definition.method
            and slot.methodBadgeCenters
            and #slot.methodBadgeCenters > 0 then
            topSlotGenerators[#topSlotGenerators + 1] = {
                column = slot.x,
                methodBadgeCenters = slot.methodBadgeCenters,
                methodEntries = slot.definition.method,
            }
        end
    end

    for _, topSlotGenerator in ipairs(topSlotGenerators) do
        gridCardGenerators[#gridCardGenerators + 1] = topSlotGenerator
    end

    table.sort(gridCardGenerators, function(a, b)
        return a.column < b.column
    end)

    return gridCardGenerators
end

local function resolveStartPhaseRegen(gameState, deps)
    for _, card in ipairs(gameState.cards or {}) do
        if card
            and deps.isGridCard(card)
            and not deps.isCardUnavailable(card)
            and deps.cardregistry
            and deps.keywordrules
            and deps.healCard then
            local cardDefinition = deps.cardregistry.getCard(card.setName, card.cardId)
            local regenValue = deps.keywordrules.getCardKeywordValue(card, cardDefinition, REGEN_KEYWORD_ID)

            if regenValue and regenValue > 0 then
                deps.healCard(card, regenValue)
            end
        end
    end
end

local function getHandCardCount(cards)
    local count = 0

    for _, card in ipairs(cards or {}) do
        if card
            and card.location
            and card.location.kind == "hand"
            and not card.destroyed
            and not card.destroying then
            count = count + 1
        end
    end

    return count
end

local function beginHandLimitDiscardSelection(gameState, deps)
    if gameState.endPhaseHandLimitDiscardHandled
        or gameState.pendingHandLimitDiscardSelection
        or getHandCardCount(gameState.cards) < 10 then
        return false
    end

    gameState.endPhaseHandLimitDiscardHandled = true
    gameState.pendingHandLimitDiscardSelection = {
        kind = "hand_limit_discard",
        prompt = "Hand limit exceeded. Choose one card in hand to discard.",
    }

    if deps.notifications then
        deps.notifications.push(gameState.pendingHandLimitDiscardSelection.prompt)
    end

    return true
end

local function completeEndPhase(gameState, deps)
    if deps.topsloteffects
        and deps.topsloteffects.isPoiHunterTransformationActive
        and deps.topsloteffects.isPoiHunterTransformationActive() then
        return
    end

    if beginHandLimitDiscardSelection(gameState, deps) then
        return
    end

    deps.clearAllBlocking()
    deps.addObjectiveProgress(gameState.activePrimaryObjective, deps.getEndPhaseObjectiveProgress())
    deps.warrules.resetPlayerCardStates(gameState.cards)
    if deps.clearTemporaryRerollBonus then
        deps.clearTemporaryRerollBonus()
    end
    gameState.engageRerollCount = 2
    deps.turnrules.advancePhase()
    phasecontroller.enterCurrentPhase(gameState, deps)
end

local function resolveEndPhaseHaywire(gameState, deps)
    if gameState.endPhaseHaywireHandled then
        return false
    end

    gameState.endPhaseHaywireHandled = true

    if not deps.haywirerules or not deps.haywirerules.resolveEndPhaseSystemBurn then
        return false
    end

    return deps.haywirerules.resolveEndPhaseSystemBurn(deps)
end

local function shouldFizzleCardRetaliation(gameState, deps, retaliation)
    if not retaliation
        or not deps.warrules.canTargetEnemyCard(retaliation)
        or not retaliation.targetCardIndex
    then
        return false
    end

    local targetCard = gameState.cards and gameState.cards[retaliation.targetCardIndex] or nil

    -- Existing behavior already handles destroyed/unavailable targets by doing nothing.
    -- This helper is only for attacks that became illegal while the target is still there.
    if not targetCard or deps.isCardUnavailable(targetCard) then
        return false
    end

    local targetDefinition = deps.cardregistry.getCard(targetCard.setName, targetCard.cardId)

    return not deps.warrules.canAttackTarget(
        retaliation.sourceDefinition,
        targetDefinition,
        retaliation.sourceCard,
        targetCard,
        retaliation,
        gameState.cards
    )
end

local function resolveRetaliation(gameState, deps, retaliation)
    if retaliation.targetType == "Blk" then
        local sourceCardIndex = getCardIndexFromEntityKey(retaliation.entityKey)
        local targetCardIndex = retaliation.targetCardIndex or sourceCardIndex
        local targetCard = targetCardIndex and gameState.cards[targetCardIndex] or nil

        if not targetCard
            or deps.isCardUnavailable(targetCard)
            or math.max(0, tonumber(targetCard.currentHealth) or 0) <= 0 then
            targetCardIndex, targetCard = findLowestHealthOppRowCard(gameState.cards, deps)
        end

        if targetCard and not deps.isCardUnavailable(targetCard) then
            deps.addBlockingToCard(targetCard, retaliation.damageValue or 0, {
                carryEnemyGuard = targetCard.location
                    and targetCard.location.kind == "grid"
                    and targetCard.location.rowId == "OppRow",
            })
        end

        deps.warrules.clearEntityRollState(retaliation.entityKey)
        return
    end

    if retaliation.pain == true then
        local sourceCardIndex = getCardIndexFromEntityKey(retaliation.entityKey)
        local sourceCard = sourceCardIndex and gameState.cards[sourceCardIndex] or nil

        if sourceCard and not deps.isCardUnavailable(sourceCard) then
            deps.dealDamageToCard(sourceCard, retaliation.damageValue or 0)
        end
    end

    if shouldFizzleCardRetaliation(gameState, deps, retaliation) then
        if deps.notifications then
            deps.notifications.push("Attack fizzled!")
        end

        deps.warrules.clearEntityRollState(retaliation.entityKey)
        return
    end

    if retaliation.targetType == "Obj"
        and retaliation.targetCard
        and retaliation.targetCard.kind == "objective"
        and gameState.activePrimaryObjective
        and gameState.activePrimaryObjective.id == retaliation.targetCard.objectiveId then
        deps.addObjectiveProgress(gameState.activePrimaryObjective, retaliation.damageValue or 0)
        applyRetaliationSideEffects(gameState, deps, retaliation)

    elseif retaliation.targetType == "WZOpp"
        and gameState.activeWarzone then
        deps.addWarzoneControl(gameState.activeWarzone, -(retaliation.damageValue or 0), "warzone")
        applyRetaliationSideEffects(gameState, deps, retaliation)

    elseif retaliation.targetType == "IntCD"
        and retaliation.targetCard
        and retaliation.targetCard.kind == "intel"
        and gameState.activeIntel
        and gameState.activeIntel.id == retaliation.targetCard.objectiveId then
        deps.addObjectiveProgress(gameState.activeIntel, -(retaliation.damageValue or 0), "intel")
        applyRetaliationSideEffects(gameState, deps, retaliation)

    elseif retaliation.targetType == "Inf"
        and retaliation.targetCard
        and retaliation.targetCard.kind == "deck" then
        local generatedCardDefinition = deps.cardregistry.getCardById(retaliation.cardgen)

        if generatedCardDefinition then
            deps.beginInfiltrationEffect(retaliation.entityKey, generatedCardDefinition, retaliation.damageValue or 0)
            applyRetaliationSideEffects(gameState, deps, retaliation)
        end

    elseif retaliation.targetType == "smn" or retaliation.targetType == "rsmn" then
        local resolved = resolveSummonRetaliation(gameState, deps, retaliation)

        if resolved and deps.sfxrules and deps.sfxrules.playUnitPlay then
            deps.sfxrules.playUnitPlay()
        end

    else
        local targetCard = gameState.cards[retaliation.targetCardIndex]
        local shouldApplyAreaDamage = targetCard
            and not deps.isCardUnavailable(targetCard)
            and not crewrules.isCardProtectedByCover(gameState.cards, targetCard)

        if shouldApplyAreaDamage then
            local damageResult = deps.dealDamageToCard(targetCard, retaliation.damageValue or 0)
            if retaliation.sourceCard then
                local targetDefinition = deps.cardregistry.getCard(targetCard.setName, targetCard.cardId)
                applyConditionsToTarget(targetCard, targetDefinition, retaliation)

                if applyMangleToTarget(deps, targetCard, targetDefinition, retaliation) > 0
                    and deps.warrules
                    and deps.warrules.refreshCardRollValue then
                    deps.warrules.refreshCardRollValue(retaliation.targetCardIndex, gameState.cards)
                end
            end
            if damageResult and damageResult.killed then
                local sourceCardIndex = getRetaliationSourceCardIndex(gameState, retaliation)

                if sourceCardIndex and deps.trooprules then
                    deps.trooprules.resolveKill(sourceCardIndex, retaliation.targetCardIndex, {
                        cards = gameState.cards,
                        cardregistry = deps.cardregistry,
                        spawnTokensNearCard = deps.spawnTokensNearCard,
                    })
                end
            end
            applyAreaDamageToAdjacentCards(gameState, deps, retaliation)
            applyRetaliationSideEffects(gameState, deps, retaliation)

            if retaliation.summonOnAttack == true then
                local resolved = resolveSummonRetaliation(gameState, deps, retaliation)

                if resolved and deps.sfxrules and deps.sfxrules.playUnitPlay then
                    deps.sfxrules.playUnitPlay()
                end
            end
        end

        if retaliation.targetType == "AtkSab" and gameState.activePrimaryObjective then
            deps.addObjectiveProgress(gameState.activePrimaryObjective, retaliation.damageValue or 0)
        end
    end

    deps.warrules.clearEntityRollState(retaliation.entityKey)
end

local function resolveEndPhaseCaches(gameState, deps)
    local expiredCacheIndexes = {}

    for cardIndex, card in ipairs(gameState.cards or {}) do
        if card
            and not deps.isCardUnavailable(card)
            and card.location
            and card.location.kind == "grid"
            and card.location.rowId == "PlayerRow" then
            local cardDefinition = deps.cardregistry.getCard(card.setName, card.cardId)

            if cardDefinition and cardDefinition.type == CACHE_CARD_TYPE then
                if card.cardId == MEAT_CACHE_CARD_ID then
                    local previousHealth = math.max(0, tonumber(card.currentHealth) or 0)
                    card.currentHealth = math.max(0, previousHealth - 1)

                    if card.currentHealth < previousHealth and deps.sfxrules and deps.sfxrules.playEat then
                        deps.sfxrules.playEat()
                    end

                    if card.currentHealth < previousHealth and deps.notifyMeatCacheDecayed then
                        deps.notifyMeatCacheDecayed(cardIndex)
                    end

                    for _, playerRowCard in ipairs(gameState.cards or {}) do
                        if playerRowCard
                            and playerRowCard ~= card
                            and not deps.isCardUnavailable(playerRowCard)
                            and playerRowCard.location
                            and playerRowCard.location.kind == "grid"
                            and playerRowCard.location.rowId == "PlayerRow" then
                            local playerRowDefinition = deps.cardregistry.getCard(playerRowCard.setName, playerRowCard.cardId)

                            if playerRowDefinition and playerRowDefinition.type ~= CACHE_CARD_TYPE then
                                deps.healCard(playerRowCard, 1)
                            end
                        end
                    end
                end

                if math.max(0, tonumber(card.currentHealth) or 0) <= 0 then
                    expiredCacheIndexes[#expiredCacheIndexes + 1] = cardIndex
                end
            end
        end
    end

    for _, cardIndex in ipairs(expiredCacheIndexes) do
        deps.removeCardFromPlay(cardIndex)
    end
end

function phasecontroller.enterCurrentPhase(gameState, deps)
    local currentPhase = deps.turnrules.getCurrentPhase()

    if currentPhase ~= "End" then
        gameState.endPhaseSacrificeHandled = false
        gameState.endPhaseHandLimitDiscardHandled = false
        gameState.endPhaseDrawHandled = false
        gameState.endPhasePoiHandled = false
        gameState.endPhaseHaywireHandled = false
    end

    if currentPhase == deps.turnrules.getSetupPhase() then
        local firstCardId = gameState.playerJacl and gameState.playerJacl.tomeId or nil
        local openingHandSize = (firstCardId and 7 or 6)
            + math.max(0, math.floor(tonumber(deps.getOpeningHandBonus and deps.getOpeningHandBonus()) or 0))

        gameState.cards = deps.deckrules.assignCardsToHand(gameState.playerDeck, openingHandSize, {
            firstCardId = firstCardId,
        })
        gameState.mulliganSelection = {}
        gameState.mulliganActive = gameState.mulliganCompleted ~= true
        gameState.mulliganResolving = false
        gameState.mulliganReturnedCards = nil
        gameState.mulliganPromptAlpha = 0
        deps.initializeCardsHealthState(gameState.cards)
        if deps.resolveHuntersInHand then
            deps.resolveHuntersInHand()
        else
            deps.playHunterAddedSfxForCards(gameState.cards)
        end
        if deps.addStartingCrewCards then
            deps.addStartingCrewCards()
        end
        deps.addSetupAgents()
        deps.normalizeSetupCardSlots()
    elseif currentPhase == "Start" then
        if gameState.playerJacl then
            gameState.playerJacl.usedMethodAbilities = nil
        end

        for _, card in ipairs(gameState.cards or {}) do
            if card then
                card.usedMethodAbilities = nil
                card.buttonBadgeExhausted = nil
            end
        end

        resolveStartPhaseRegen(gameState, deps)

        local gridCardGenerators = buildStartPhaseGenerators(gameState, deps)
        deps.resourcerules.enterStartPhase(gameState.playerJacl, deps.envdraw.getBottomLeftPanelLayout(gameState.playerJacl), deps.envdraw.getResourceTrackerLayout(), gridCardGenerators)
        if deps.resolveSyntacRewardButtons then
            deps.resolveSyntacRewardButtons()
        end
        gameState.waitingForStartGeneration = true
    elseif currentPhase == "House" then
        deps.championplayrules.playHouseCardAndQueueKeywords(gameState.championPlayState, deps.getChampionPlayContext())
    elseif currentPhase == "Prelude" then
        deps.sfxrules.playPrelude()
        deps.notifications.push("Mobilize!")
    elseif currentPhase == "War" then
        deps.sfxrules.playPhaseEnd()
        deps.warrules.beginPhase(deps.getTopSlotRollTargets(), gameState.cards, gameState.activePrimaryObjective, gameState.activeIntel, gameState.activeWarzone)
    elseif currentPhase == "End" then
        if deps.clearTemporaryRerollBonus then
            deps.clearTemporaryRerollBonus()
        end

        if deps.beginEndPhaseSacrificeSelection
            and deps.beginEndPhaseSacrificeSelection(gameState) then
            return
        end

        deps.warrules.clearBlankResults()
        deps.warrules.clearAllRollResults()
        deps.clearAllBlocking()
        deps.temporaryeffects.clearAllEndPhaseEffects()
        deps.keywordrules.refreshEndPhaseKeywords(gameState.cards)
        for _, expiredCardIndex in ipairs(deps.keywordrules.decrementEndPhaseKeywords(gameState.cards)) do
            if deps.expireCardFromPlay then
                deps.expireCardFromPlay(expiredCardIndex)
            else
                deps.removeCardFromPlay(expiredCardIndex)
            end
        end
        resolveEndPhaseCaches(gameState, deps)
        resolveEndPhaseHaywire(gameState, deps)

        if not gameState.endPhaseDrawHandled then
            gameState.endPhaseDrawHandled = true
            deps.drawCardFromPlayerDeck()
        end

        if not gameState.endPhasePoiHandled then
            gameState.endPhasePoiHandled = true

            if gameState.activePoi
                and gameState.activePoi.id
                and gameState.activePoi.id:sub(-1) == "B"
                and deps.beginPoiGeneratedCardTransformation(gameState.activePoi, gameState.activePoi.huntID) then
                return
            end
        end

        completeEndPhase(gameState, deps)
    end
end

function phasecontroller.completeSetupPhaseIfReady(gameState, deps)
    if deps.turnrules.getCurrentPhase() ~= deps.turnrules.getSetupPhase() then
        return
    end

    if deps.getSetupCardCount() > 0 then
        return
    end

    if gameState.mulliganActive then
        return
    end

    deps.turnrules.beginStartPhase()
    gameState.pendingSetupCompletion = true
end

function phasecontroller.advancePrelude(gameState, deps)
    deps.turnrules.advancePhase()
    phasecontroller.enterCurrentPhase(gameState, deps)
end

function phasecontroller.beginRetaliateFromEngage(gameState, deps)
    gameState.selectedAttackerCardIndex = nil
    gameState.selectedAttackerTopSlotId = nil
    if deps.clearEnemyGuardCarryBlocking then
        deps.clearEnemyGuardCarryBlocking()
    end
    deps.turnrules.advanceWarSubphase()
    resolveEnemyWounds(gameState, deps)
    if deps.getRetaliationPhaseObjectiveProgress then
        local hunterProgress = math.max(0, tonumber(deps.getRetaliationPhaseObjectiveProgress()) or 0)

        if hunterProgress > 0 then
            deps.addObjectiveProgress(gameState.activePrimaryObjective, hunterProgress)
        end
    end
    deps.warrules.triggerCounterStrikesOnTargeting(
        gameState.cards,
        gameState.activeChampion,
        deps.dealDamageToCard,
        deps.dealDamageToChampion
    )
    deps.warrules.beginRetaliatePhase(deps.getTopSlotRollTargets(), gameState.cards)
end

function phasecontroller.update(gameState, deps, dt)
    if gameState.hasRenderedFirstFrame and gameState.pendingPhaseEntry then
        phasecontroller.enterCurrentPhase(gameState, deps)
        gameState.pendingPhaseEntry = false
    end

    if gameState.pendingSetupCompletion then
        phasecontroller.enterCurrentPhase(gameState, deps)
        gameState.pendingSetupCompletion = false
    end

    deps.championplayrules.updateQueuedPlays(gameState.championPlayState, dt, deps.getChampionPlayContext())

    if deps.turnrules.getCurrentPhase() == "House"
        and deps.championplayrules.isSequenceComplete(gameState.championPlayState) then
        deps.turnrules.advancePhase()
        phasecontroller.enterCurrentPhase(gameState, deps)
    end

    if gameState.waitingForStartGeneration
        and deps.turnrules.getCurrentPhase() == "Start"
        and deps.resourcerules.isGenerationComplete() then
        if deps.clearResolvedSyntacMethodReward then
            deps.clearResolvedSyntacMethodReward()
        end

        gameState.waitingForStartGeneration = false
        deps.turnrules.advancePhase()
        phasecontroller.enterCurrentPhase(gameState, deps)
    end

    local topSlotEffectEvents = deps.topsloteffects.update(dt)

    if topSlotEffectEvents.championDestroyed and gameState.activeChampion then
        gameState.activeChampion.hidden = true
    end

    if topSlotEffectEvents.intelDestroyed then
        local defeatedIntel = gameState.activeIntel

        if gameState.activeIntel then
            gameState.activeIntel.hidden = true
        end

        gameState.activeIntel = deps.getReplacementIntel(defeatedIntel)

        if gameState.activeIntel then
            gameState.activeIntel.hidden = false
        end
    end

    if topSlotEffectEvents.objectiveEscalationSwap then
        gameState.activePrimaryObjective = topSlotEffectEvents.objectiveEscalationSwap or gameState.activePrimaryObjective
    end

    local completedPoiHunterTransformations = topSlotEffectEvents.poiHunterTransformationComplete

    if completedPoiHunterTransformations then
        if completedPoiHunterTransformations.generatedCardDefinition then
            completedPoiHunterTransformations = { completedPoiHunterTransformations }
        end

        local shouldCompleteEndPhase = false

        for _, effect in ipairs(completedPoiHunterTransformations) do
            local generatedCard = deps.createGeneratedSupportCard(
                effect.generatedCardDefinition,
                effect.targetLocation
            )

            if generatedCard then
                if not effect.sourceSlotId or effect.sourceSlotId == "poi" then
                    gameState.activePoi = nil
                end
            end

            if deps.turnrules.getCurrentPhase() == "End" then
                shouldCompleteEndPhase = true
            end
        end

        if shouldCompleteEndPhase then
            completeEndPhase(gameState, deps)
        end
    end

    deps.updateInfiltrationEffect(dt)

    deps.warrules.update(dt, deps.turnrules.getCurrentPhase())

    if deps.turnrules.getCurrentPhase() == "War"
        and deps.turnrules.getCurrentWarSubphase() == "Engage"
        and deps.warrules.retargetIllegalEnemyAttacks then
        deps.warrules.retargetIllegalEnemyAttacks(gameState.cards)
    end

    local retaliation = deps.warrules.updateRetaliate(dt, deps.turnrules.getCurrentPhase(), deps.turnrules.getCurrentWarSubphase())

    if retaliation then
        resolveRetaliation(gameState, deps, retaliation)
    end

    if deps.turnrules.getCurrentPhase() == "War"
        and deps.turnrules.getCurrentWarSubphase() == "Retaliate"
        and deps.warrules.isRetaliationComplete() then
        deps.turnrules.advancePhase()
        phasecontroller.enterCurrentPhase(gameState, deps)
    end

    if deps.turnrules.isWarRollPhase() and deps.warrules.isRollSequenceComplete() then
        local nextWarSubphase = deps.turnrules.advanceWarSubphase()

        if nextWarSubphase == "Engage" then
            gameState.engageRerollCount = 2 + math.max(0, tonumber(deps.getEngageRerollBonus and deps.getEngageRerollBonus()) or 0)
            resolvePlayerWounds(gameState, deps)
            deps.sfxrules.playEngage()
            deps.notifications.push("Engage!")
        end
    end
end

return phasecontroller
