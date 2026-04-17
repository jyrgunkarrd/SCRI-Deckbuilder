local phasecontroller = {}

local function buildStartPhaseGenerators(gameState, deps)
    local gridCardGenerators = {}

    for cardIndex, card in ipairs(gameState.cards) do
        if deps.isGridCard(card) and not deps.isCardUnavailable(card) then
            local drawX, drawY, expansionProgress, renderOptions = deps.getCardDrawPosition(card, cardIndex)
            local cardDefinition = deps.cardregistry.getCard(card.setName, card.cardId)
            local methodBadgeCenters = deps.carddraw.getMethodBadgeCenters(card.setName, card.cardId, drawX, drawY, expansionProgress, renderOptions)

            if methodBadgeCenters and #methodBadgeCenters > 0 and cardDefinition and cardDefinition.method then
                gridCardGenerators[#gridCardGenerators + 1] = {
                    column = card.location.column,
                    methodBadgeCenters = methodBadgeCenters,
                    methodEntries = cardDefinition.method,
                }
            end
        end
    end

    table.sort(gridCardGenerators, function(a, b)
        return a.column < b.column
    end)

    return gridCardGenerators
end

local function completeEndPhase(gameState, deps)
    deps.clearAllBlocking()
    deps.addObjectiveProgress(gameState.activePrimaryObjective, deps.getEndPhaseObjectiveProgress())
    deps.warrules.resetPlayerCardStates(gameState.cards)
    gameState.engageRerollCount = 2
    deps.turnrules.advancePhase()
    phasecontroller.enterCurrentPhase(gameState, deps)
end

local function resolveRetaliation(gameState, deps, retaliation)
    if retaliation.targetType == "Obj"
        and retaliation.targetCard
        and retaliation.targetCard.kind == "objective"
        and gameState.activePrimaryObjective
        and gameState.activePrimaryObjective.id == retaliation.targetCard.objectiveId then
        deps.addObjectiveProgress(gameState.activePrimaryObjective, retaliation.damageValue or 0)
    elseif retaliation.targetType == "WZOpp"
        and gameState.activeWarzone then
        deps.addWarzoneControl(gameState.activeWarzone, -(retaliation.damageValue or 0), "warzone")
    elseif retaliation.targetType == "IntCD"
        and retaliation.targetCard
        and retaliation.targetCard.kind == "intel"
        and gameState.activeIntel
        and gameState.activeIntel.id == retaliation.targetCard.objectiveId then
        deps.addObjectiveProgress(gameState.activeIntel, -(retaliation.damageValue or 0), "intel")
    elseif retaliation.targetType == "Inf"
        and retaliation.targetCard
        and retaliation.targetCard.kind == "deck" then
        local generatedCardDefinition = deps.cardregistry.getCardById(retaliation.cardgen)

        if generatedCardDefinition then
            deps.beginInfiltrationEffect(retaliation.entityKey, generatedCardDefinition, retaliation.damageValue or 0)
        end
    else
        local targetCard = gameState.cards[retaliation.targetCardIndex]

        if targetCard and not deps.isCardUnavailable(targetCard) then
            deps.dealDamageToCard(targetCard, retaliation.damageValue or 0)
        end
    end

    deps.warrules.clearEntityRollState(retaliation.entityKey)
end

function phasecontroller.enterCurrentPhase(gameState, deps)
    local currentPhase = deps.turnrules.getCurrentPhase()

    if currentPhase == deps.turnrules.getSetupPhase() then
        gameState.cards = deps.deckrules.assignCardsToHand(gameState.playerDeck, deps.envrules.getPlayerHand().slots)
        deps.initializeCardsHealthState(gameState.cards)
        deps.playHunterAddedSfxForCards(gameState.cards)
        deps.addSetupAgents()
        deps.normalizeSetupCardSlots()
    elseif currentPhase == "Start" then
        local gridCardGenerators = buildStartPhaseGenerators(gameState, deps)
        deps.resourcerules.enterStartPhase(gameState.playerJacl, deps.envdraw.getBottomLeftPanelLayout(gameState.playerJacl), deps.envdraw.getResourceTrackerLayout(), gridCardGenerators)
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
        deps.warrules.clearBlankResults()
        deps.warrules.clearAllRollResults()
        deps.clearAllBlocking()
        for _, expiredCardIndex in ipairs(deps.keywordrules.decrementEndPhaseKeywords(gameState.cards)) do
            deps.removeCardFromPlay(expiredCardIndex)
        end
        deps.drawCardFromPlayerDeck()
        if gameState.activePoi
            and gameState.activePoi.id
            and gameState.activePoi.id:sub(-1) == "B"
            and deps.beginPoiGeneratedCardTransformation(gameState.activePoi, gameState.activePoi.huntID) then
            return
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

    deps.turnrules.beginStartPhase()
    gameState.pendingSetupCompletion = true
end

function phasecontroller.advancePrelude(gameState, deps)
    deps.turnrules.advancePhase()
    phasecontroller.enterCurrentPhase(gameState, deps)
end

function phasecontroller.beginRetaliateFromEngage(gameState, deps)
    gameState.selectedAttackerCardIndex = nil
    deps.turnrules.advanceWarSubphase()
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

    if topSlotEffectEvents.poiHunterTransformationComplete then
        local effect = topSlotEffectEvents.poiHunterTransformationComplete
        local generatedCard = deps.createGeneratedSupportCard(
            effect.generatedCardDefinition,
            effect.targetLocation
        )

        if generatedCard then
            gameState.activePoi = nil
        end

        if deps.turnrules.getCurrentPhase() == "End" then
            completeEndPhase(gameState, deps)
        end
    end

    deps.updateInfiltrationEffect(dt)

    deps.warrules.update(dt, deps.turnrules.getCurrentPhase())

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
            gameState.engageRerollCount = 2
            deps.sfxrules.playEngage()
            deps.notifications.push("Engage!")
        end
    end
end

return phasecontroller
