local cardplaycontroller = {}

function cardplaycontroller.canPlayCard(card, ctx)
    local cardDefinition = ctx.cardregistry.getCard(card.setName, card.cardId)

    if ctx.strategyrules.isStrategyDefinition(cardDefinition) then
        return false
    end

    if ctx.kitrules.isKitDefinition(cardDefinition) then
        return false
    end

    if not cardDefinition or not cardDefinition.mcost then
        return true
    end

    return ctx.resourcerules.canAffordCosts(cardDefinition.mcost)
end

function cardplaycontroller.payCardCosts(card, ctx)
    local cardDefinition = ctx.cardregistry.getCard(card.setName, card.cardId)

    if not cardDefinition or not cardDefinition.mcost then
        return true
    end

    return ctx.resourcerules.payCosts(cardDefinition.mcost)
end

function cardplaycontroller.getTomeUseContext(ctx)
    local state = ctx.state

    return {
        cards = state.cards,
        turnrules = ctx.turnrules,
        cardregistry = ctx.cardregistry,
        spawnTokensNearCard = ctx.spawnTokensNearPlayerCard,
        getSyntacCount = function()
            return state.syntacCount or 0
        end,
        spendSyntac = function(amount)
            state.syntacCount = math.max(0, (state.syntacCount or 0) - math.max(0, tonumber(amount) or 0))
        end,
    }
end

function cardplaycontroller.tryUseTomeCard(cardIndex, mouseX, mouseY, ctx)
    local hostCard = cardIndex and ctx.state.cards[cardIndex] or nil

    if not hostCard or mouseX == nil or mouseY == nil then
        return false
    end

    local drawX, drawY, expansionProgress, renderOptions = ctx.getCardDrawPosition(hostCard, cardIndex)
    local kitBadgeRect = ctx.carddraw.getKeywordBadgeRect(
        hostCard.setName,
        hostCard.cardId,
        drawX,
        drawY,
        renderOptions,
        "KWKIT"
    )

    if not kitBadgeRect
        or mouseX < kitBadgeRect.x
        or mouseX > kitBadgeRect.x + kitBadgeRect.size
        or mouseY < kitBadgeRect.y
        or mouseY > kitBadgeRect.y + kitBadgeRect.size then
        return false
    end

    return ctx.tomerules.useAttachedTome(cardIndex, cardplaycontroller.getTomeUseContext(ctx))
end

local function beginPendingStrategySelection(ctx, pendingSelection)
    local hasValidTarget = false

    for cardIndex = 1, #ctx.state.cards do
        if ctx.strategyrules.isValidFunccostTarget(cardIndex, pendingSelection, {
            cards = ctx.state.cards,
            cardregistry = ctx.cardregistry,
        }) then
            hasValidTarget = true
            break
        end
    end

    if not hasValidTarget then
        ctx.notifications.push("Strategy fizzled")
        return true
    end

    ctx.state.pendingStrategySelection = pendingSelection
    ctx.notifications.push("Choose a troop or token to sacrifice")
    return true
end

local function isValidCrewButtonHealTarget(cardIndex, pendingSelection, ctx)
    local card = cardIndex and ctx.state.cards[cardIndex] or nil

    if not pendingSelection
        or pendingSelection.kind ~= "crew_button_heal"
        or not card
        or not card.location
        or card.location.kind ~= "grid"
        or card.location.rowId ~= "PlayerRow"
        or card.destroyed
        or card.destroying
        or (ctx.isCardUnavailable and ctx.isCardUnavailable(card)) then
        return false
    end

    local currentHealth = tonumber(card.currentHealth)
    local maxHealth = tonumber(card.maxHealth)

    return currentHealth ~= nil and maxHealth ~= nil and maxHealth > 0
end

local function cardHasHealthBar(ctx, card)
    if not card then
        return false
    end

    if card.currentHealth ~= nil or card.maxHealth ~= nil then
        return true
    end

    local cardDefinition = ctx.cardregistry and ctx.cardregistry.getCard(card.setName, card.cardId) or nil
    return cardDefinition and cardDefinition.health ~= nil or false
end

local function isValidCrewButtonBlockTarget(cardIndex, pendingSelection, ctx)
    local card = cardIndex and ctx.state.cards[cardIndex] or nil

    return pendingSelection
        and pendingSelection.kind == "crew_button_block_2"
        and card
        and card.location
        and card.location.kind == "grid"
        and card.location.rowId == "PlayerRow"
        and not card.destroyed
        and not card.destroying
        and not (ctx.isCardUnavailable and ctx.isCardUnavailable(card))
        and cardHasHealthBar(ctx, card)
        or false
end

local function getCardCurrentHealth(ctx, card)
    if not card then
        return nil
    end

    if card.currentHealth == nil then
        local cardDefinition = ctx.cardregistry and ctx.cardregistry.getCard(card.setName, card.cardId) or nil
        card.currentHealth = tonumber(cardDefinition and cardDefinition.health)
        card.maxHealth = tonumber(cardDefinition and (cardDefinition.max or cardDefinition.health))
    end

    return tonumber(card.currentHealth)
end

local function isValidCrewButtonDefeatTarget(cardIndex, pendingSelection, ctx)
    local card = cardIndex and ctx.state.cards[cardIndex] or nil

    if not pendingSelection
        or pendingSelection.kind ~= "crew_button_defeat_2"
        or not card
        or not card.location
        or card.location.kind ~= "grid"
        or card.location.rowId ~= "OppRow"
        or card.destroyed
        or card.destroying
        or (ctx.isCardUnavailable and ctx.isCardUnavailable(card)) then
        return false
    end

    return getCardCurrentHealth(ctx, card) == 2
end

local function isValidCrewButtonDefeatTopSlotTarget(topSlotId, pendingSelection, ctx)
    local champion = ctx.state and ctx.state.activeChampion or nil

    return pendingSelection
        and pendingSelection.kind == "crew_button_defeat_2"
        and topSlotId == "champion"
        and champion
        and champion.hidden ~= true
        and tonumber(champion.health) == 2
        or false
end

function cardplaycontroller.tryPlayStrategyCard(strategyCardIndex, targetCardIndex, ctx)
    return ctx.strategyrules.playStrategy(strategyCardIndex, targetCardIndex, {
        cards = ctx.state.cards,
        turnrules = ctx.turnrules,
        warrules = ctx.warrules,
        cardregistry = ctx.cardregistry,
        discardCard = ctx.discardCardFromPlay,
        startCardDestruction = ctx.startCardDestruction,
        dealDamageToCard = ctx.dealDamageToCard,
        dealDamageToChampion = ctx.dealDamageToChampion,
        spawnTokensNearCard = ctx.spawnTokensNearCard,
        beginPendingStrategySelection = function(pendingSelection)
            return beginPendingStrategySelection(ctx, pendingSelection)
        end,
    })
end

function cardplaycontroller.tryPlayKitCard(kitCardIndex, targetCardIndex, ctx)
    return ctx.kitrules.playKit(kitCardIndex, targetCardIndex, {
        cards = ctx.state.cards,
        cardregistry = ctx.cardregistry,
        canAffordCosts = function(costEntries)
            return ctx.resourcerules.canAffordCosts(costEntries)
        end,
        payCosts = function(costEntries)
            return ctx.resourcerules.payCosts(costEntries)
        end,
        removeCardFromPlay = ctx.removeCardFromPlay,
    })
end

function cardplaycontroller.getPendingSelection(state)
    return state.pendingStrategySelection
        or state.pendingSacrificeSelection
        or state.pendingHandLimitDiscardSelection
        or state.pendingButtonSelection
end

function cardplaycontroller.hasPendingStrategySelection(state)
    return cardplaycontroller.getPendingSelection(state) ~= nil
end

function cardplaycontroller.tryResolvePendingStrategySelection(cardIndex, ctx, topSlotId)
    local state = ctx.state
    local pendingSelection = cardplaycontroller.getPendingSelection(state)

    if not pendingSelection then
        return false
    end

    if pendingSelection.kind == "troop_script_sacrifice" then
        local resolved = ctx.trooprules.isValidPendingSacrificeTarget(cardIndex, pendingSelection, {
            cards = state.cards,
            cardregistry = ctx.cardregistry,
        })

        if not resolved then
            return false
        end

        ctx.startCardDestruction(cardIndex)
        state.pendingSacrificeSelection = nil
        ctx.enterCurrentPhase()
        return true
    end

    if pendingSelection.kind == "hand_limit_discard" then
        local card = cardIndex and state.cards[cardIndex] or nil

        if not card
            or not card.location
            or card.location.kind ~= "hand" then
            return false
        end

        if ctx.discardCardFromPlay and ctx.discardCardFromPlay(cardIndex) then
            state.pendingHandLimitDiscardSelection = nil

            if ctx.normalizeHandCardSlots then
                ctx.normalizeHandCardSlots()
            end

            ctx.enterCurrentPhase()
            return true
        end

        return false
    end

    if pendingSelection.kind == "crew_button_heal" then
        if not isValidCrewButtonHealTarget(cardIndex, pendingSelection, ctx) then
            return false
        end

        local card = state.cards[cardIndex]
        local currentHealth = math.max(0, tonumber(card.currentHealth) or 0)
        local maxHealth = math.max(currentHealth, tonumber(card.maxHealth) or 0)

        if ctx.healCard then
            ctx.healCard(card, maxHealth - currentHealth)
        else
            card.currentHealth = maxHealth
        end

        if ctx.keywordrules and ctx.keywordrules.removeNegativeConditionKeywords then
            local cardDefinition = ctx.cardregistry and ctx.cardregistry.getCard(card.setName, card.cardId) or nil
            ctx.keywordrules.removeNegativeConditionKeywords(card, cardDefinition)
        end

        state.pendingButtonSelection = nil
        return true
    end

    if pendingSelection.kind == "crew_button_block_2" then
        if not isValidCrewButtonBlockTarget(cardIndex, pendingSelection, ctx) then
            return false
        end

        if ctx.addBlockingToCard then
            ctx.addBlockingToCard(state.cards[cardIndex], 2)
        end

        state.pendingButtonSelection = nil
        return true
    end

    if pendingSelection.kind == "crew_button_defeat_2" then
        if isValidCrewButtonDefeatTopSlotTarget(topSlotId, pendingSelection, ctx) then
            if ctx.dealDamageToChampion then
                ctx.dealDamageToChampion(math.max(0, tonumber(state.activeChampion.health) or 0))
            end

            state.pendingButtonSelection = nil
            return true
        end

        if not isValidCrewButtonDefeatTarget(cardIndex, pendingSelection, ctx) then
            return false
        end

        if ctx.startCardDestruction then
            ctx.startCardDestruction(cardIndex)
        elseif ctx.dealDamageToCard then
            ctx.dealDamageToCard(state.cards[cardIndex], math.max(0, tonumber(state.cards[cardIndex].currentHealth) or 0))
        end

        state.pendingButtonSelection = nil
        return true
    end

    local resolved = ctx.strategyrules.resolvePendingSelection(cardIndex, pendingSelection, {
        cards = state.cards,
        cardregistry = ctx.cardregistry,
        warrules = ctx.warrules,
        discardCard = ctx.discardCardFromPlay,
        startCardDestruction = ctx.startCardDestruction,
        dealDamageToCard = ctx.dealDamageToCard,
        dealDamageToChampion = ctx.dealDamageToChampion,
    })

    if resolved then
        state.pendingStrategySelection = nil
    end

    return resolved
end

function cardplaycontroller.cancelPendingStrategySelection(ctx)
    if ctx.state.pendingButtonSelection then
        local pendingSelection = ctx.state.pendingButtonSelection

        if pendingSelection.burnedSystemIndex
            and ctx.systemrules
            and ctx.state.missionSystems then
            ctx.systemrules.restoreSystem(ctx.state.missionSystems, pendingSelection.burnedSystemIndex)
        end

        local sourceCard = pendingSelection.sourceCardIndex and ctx.state.cards[pendingSelection.sourceCardIndex] or nil

        if sourceCard then
            sourceCard.buttonBadgeExhausted = nil
        end

        ctx.state.pendingButtonSelection = nil

        if ctx.notifications then
            ctx.notifications.push("Ability cancelled")
        end

        return true
    end

    if not ctx.state.pendingStrategySelection then
        return false
    end

    ctx.state.pendingStrategySelection = nil
    ctx.notifications.push("Strategy fizzled")
    return true
end

function cardplaycontroller.isPendingSelectionTarget(cardIndex, pendingSelection, ctx)
    if pendingSelection and pendingSelection.kind == "crew_button_heal" then
        return isValidCrewButtonHealTarget(cardIndex, pendingSelection, ctx)
    end

    if pendingSelection and pendingSelection.kind == "crew_button_block_2" then
        return isValidCrewButtonBlockTarget(cardIndex, pendingSelection, ctx)
    end

    if pendingSelection and pendingSelection.kind == "crew_button_defeat_2" then
        return isValidCrewButtonDefeatTarget(cardIndex, pendingSelection, ctx)
    end

    return nil
end

function cardplaycontroller.isPendingSelectionTopSlotTarget(topSlotId, pendingSelection, ctx)
    if pendingSelection and pendingSelection.kind == "crew_button_defeat_2" then
        return isValidCrewButtonDefeatTopSlotTarget(topSlotId, pendingSelection, ctx)
    end

    return nil
end

function cardplaycontroller.resolvePlayedTroopCard(troopCardIndex, ctx)
    return ctx.trooprules.resolvePlay(troopCardIndex, {
        cards = ctx.state.cards,
        cardregistry = ctx.cardregistry,
        spawnTokensNearPlayerCard = ctx.spawnTokensNearPlayerCard,
    })
end

function cardplaycontroller.resolveDestroyedTroopCard(troopCardIndex, attachedKitCards, ctx)
    return ctx.trooprules.resolveDeath(troopCardIndex, {
        cards = ctx.state.cards,
        cardregistry = ctx.cardregistry,
        attachedKitCards = attachedKitCards,
        drawCardFromPlayerDeck = ctx.drawCardFromPlayerDeck,
        spawnTokensNearCard = function(sourceCardIndex, tokenDefinition, count)
            local sourceCard = sourceCardIndex and ctx.state.cards[sourceCardIndex] or nil

            if not sourceCard or not sourceCard.location or sourceCard.location.kind ~= "grid" then
                return 0
            end

            return ctx.spawnTokensNearCard(sourceCardIndex, tokenDefinition, count, {
                ignoredCardIndex = sourceCardIndex,
                preferredColumn = sourceCard.location.column,
            })
        end,
        spawnTokensNearPlayerCard = function(sourceCardIndex, tokenDefinition, count)
            local sourceCard = sourceCardIndex and ctx.state.cards[sourceCardIndex] or nil

            if not sourceCard or not sourceCard.location or sourceCard.location.kind ~= "grid" then
                return 0
            end

            return ctx.spawnTokensNearPlayerCard(sourceCardIndex, tokenDefinition, count, {
                ignoredCardIndex = sourceCardIndex,
                preferredColumn = sourceCard.location.column,
            })
        end,
    })
end

function cardplaycontroller.resolveKilledEnemyByPlayerCard(attackerCardIndex, targetCardIndex, ctx)
    return ctx.trooprules.resolveKill(attackerCardIndex, targetCardIndex, {
        cards = ctx.state.cards,
        cardregistry = ctx.cardregistry,
        createOrStackPlayerCacheNearCard = ctx.createOrStackPlayerCacheNearCard,
        spawnTokensNearCard = ctx.spawnTokensNearCard,
    })
end

function cardplaycontroller.addCardKeywordValue(cardIndex, keywordId, amount, ctx)
    local card = cardIndex and ctx.state.cards[cardIndex] or nil
    local cardDefinition = card and ctx.cardregistry.getCard(card.setName, card.cardId) or nil

    if not card or not cardDefinition then
        return nil
    end

    local nextValue = ctx.keywordrules.addCardKeywordValue(card, cardDefinition, keywordId, amount)

    if nextValue ~= nil then
        ctx.warrules.refreshCardRollValue(cardIndex, ctx.state.cards)
    end

    return nextValue
end

return cardplaycontroller
