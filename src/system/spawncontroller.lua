local spawnrules = require("src.system.spawnrules")

local spawncontroller = {}
local HUNTER_CARD_TYPE = "hunter"
local HUNTER_CHAIN_LIMIT = 100

local function getCardDefinition(ctx, card)
    return card and ctx.cardregistry.getCard(card.setName, card.cardId) or nil
end

local function isHunterDefinition(cardDefinition)
    return cardDefinition and cardDefinition.type == HUNTER_CARD_TYPE or false
end

local function getCenterBiasedOppRowColumn(ctx)
    local oppRow = ctx.envdraw.getGridRow("OppRow")

    if not oppRow then
        return nil
    end

    local center = (#oppRow.cells + 1) / 2
    local bestColumn = nil
    local bestDistance = nil

    for _, cell in ipairs(oppRow.cells or {}) do
        if cell.column
            and not ctx.cardzones.isGridRowColumnOccupied(ctx.state.cards, "OppRow", cell.column) then
            local distance = math.abs(cell.column - center)

            if bestDistance == nil
                or distance < bestDistance
                or (distance == bestDistance and cell.column > bestColumn) then
                bestColumn = cell.column
                bestDistance = distance
            end
        end
    end

    return bestColumn
end

local function playDrawnHunter(ctx, drawnCard, cardDefinition)
    if not drawnCard or not cardDefinition then
        return false
    end

    if ctx.resourcerules and ctx.resourcerules.deductCosts then
        ctx.resourcerules.deductCosts(cardDefinition.mcost)
    end

    if ctx.addObjectiveProgress and ctx.state.activePrimaryObjective then
        ctx.addObjectiveProgress(
            ctx.state.activePrimaryObjective,
            math.max(0, tonumber(cardDefinition.emphasis) or 0),
            "objective"
        )
    end

    local targetColumn = getCenterBiasedOppRowColumn(ctx)
    local sourceSlotIndex = drawnCard.location and drawnCard.location.slotIndex or nil

    if targetColumn then
        drawnCard.location = {
            kind = "grid",
            rowId = "OppRow",
            column = targetColumn,
        }
        ctx.initializeCardHealthState(drawnCard)
        ctx.state.cards[#ctx.state.cards + 1] = drawnCard
        ctx.state.cardExpansion[#ctx.state.cards] = 0
        ctx.state.cardEntranceProgress[#ctx.state.cards] = 1

        if ctx.beginHunterAutoPlayAnimation then
            ctx.beginHunterAutoPlayAnimation(drawnCard, sourceSlotIndex, "OppRow", targetColumn)
        end
    else
        local generatedCard = spawncontroller.createGeneratedGridCard(ctx, cardDefinition, "OppRow", 1)
        local generatedColumn = generatedCard and generatedCard.location and generatedCard.location.column or nil

        if generatedCard and ctx.beginHunterAutoPlayAnimation then
            ctx.beginHunterAutoPlayAnimation(generatedCard, sourceSlotIndex, "OppRow", generatedColumn)
        end
    end

    ctx.playHunterAddedSfxForCard(drawnCard)
    return true
end

function spawncontroller.getNextOpenHandSlot(ctx)
    return ctx.cardzones.getNextOpenHandSlot(
        ctx.state.cards,
        ctx.envrules.getPlayerHand().slots,
        ctx.isCardDestroyed
    )
end

function spawncontroller.getSpawnContext(ctx)
    return {
        cards = ctx.state.cards,
        cardExpansion = ctx.state.cardExpansion,
        cardEntranceProgress = ctx.state.cardEntranceProgress,
        playerDeck = ctx.state.playerDeck,
        championDeck = ctx.state.championDeck,
        activePrimaryObjective = ctx.state.activePrimaryObjective,
        cardregistry = ctx.cardregistry,
        deckrules = ctx.deckrules,
        envdraw = ctx.envdraw,
        turnrules = ctx.turnrules,
        warrules = ctx.warrules,
        addObjectiveProgress = ctx.addObjectiveProgress,
        beginObjectiveHunterDeckTransformation = ctx.beginObjectiveHunterDeckTransformation,
        beginReinforcementHunterDeckTransformation = ctx.beginReinforcementHunterDeckTransformation,
        isCardUnavailable = ctx.isCardUnavailable,
        playHunterAddedSfxForCardDefinition = ctx.playHunterAddedSfxForCardDefinition,
    }
end

function spawncontroller.createGeneratedSupportCard(ctx, cardDefinition, targetLocation)
    return spawnrules.createGeneratedSupportCard(
        spawncontroller.getSpawnContext(ctx),
        cardDefinition,
        targetLocation
    )
end

function spawncontroller.createGeneratedDeckCardShuffled(ctx, cardDefinition)
    return spawnrules.createGeneratedDeckCardShuffled(spawncontroller.getSpawnContext(ctx), cardDefinition)
end

function spawncontroller.createGeneratedGridCard(ctx, cardDefinition, rowId, column)
    return spawnrules.createGeneratedGridCard(spawncontroller.getSpawnContext(ctx), cardDefinition, rowId, column)
end

function spawncontroller.spawnTokensNearCard(ctx, sourceCardIndex, tokenDefinition, count, options)
    return spawnrules.spawnTokensNearCard(
        spawncontroller.getSpawnContext(ctx),
        sourceCardIndex,
        tokenDefinition,
        count,
        options
    )
end

function spawncontroller.spawnRandomTokensNearCard(ctx, sourceCardIndex, tokenDefinitions, count, options)
    return spawnrules.spawnRandomTokensNearCard(
        spawncontroller.getSpawnContext(ctx),
        sourceCardIndex,
        tokenDefinitions,
        count,
        options
    )
end

function spawncontroller.spawnTokensNearPlayerCard(ctx, sourceCardIndex, tokenDefinition, count, options)
    return spawnrules.spawnTokensNearPlayerCard(
        spawncontroller.getSpawnContext(ctx),
        sourceCardIndex,
        tokenDefinition,
        count,
        options
    )
end

function spawncontroller.createOrStackPlayerCacheNearCard(ctx, sourceCardIndex, cacheDefinition, count)
    return spawnrules.createOrStackPlayerCacheNearCard(
        spawncontroller.getSpawnContext(ctx),
        sourceCardIndex,
        cacheDefinition,
        count
    )
end

function spawncontroller.resolveEnemyEncounter(ctx, sourceCardIndex, enemyDefinition)
    local sourceCard = sourceCardIndex and ctx.state.cards[sourceCardIndex] or nil

    if not sourceCard
        or not sourceCard.location
        or sourceCard.location.kind ~= "grid"
        or sourceCard.location.rowId ~= "OppRow"
        or not enemyDefinition
        or not enemyDefinition.encounter
        or not enemyDefinition.encounter.spawns then
        return 0
    end

    local spawnedCount = 0

    for _, spawnEntry in ipairs(enemyDefinition.encounter.spawns or {}) do
        local enemyId = spawnEntry.enemyId or spawnEntry.cardId or spawnEntry.id
        local count = math.max(0, math.floor(tonumber(spawnEntry.count) or 0))
        local spawnDefinition = enemyId and ctx.cardregistry.getCardById(enemyId) or nil

        if spawnDefinition and count > 0 then
            spawnedCount = spawnedCount + spawncontroller.spawnTokensNearCard(
                ctx,
                sourceCardIndex,
                spawnDefinition,
                count
            )
        end
    end

    return spawnedCount
end

function spawncontroller.drawCardFromPlayerDeck(ctx, preferredSlotIndex, chainDepth, options)
    local state = ctx.state
    local nextSlotIndex = preferredSlotIndex or spawncontroller.getNextOpenHandSlot(ctx)

    if (chainDepth or 0) >= HUNTER_CHAIN_LIMIT then
        return nil
    end

    if not nextSlotIndex then
        return nil
    end

    local drawnCard = ctx.deckrules.drawCardToHand(state.playerDeck, nextSlotIndex)

    if not drawnCard then
        return nil
    end

    local drawnCardDefinition = getCardDefinition(ctx, drawnCard)

    if isHunterDefinition(drawnCardDefinition) then
        playDrawnHunter(ctx, drawnCard, drawnCardDefinition)
        return spawncontroller.drawCardFromPlayerDeck(ctx, nextSlotIndex, (chainDepth or 0) + 1, options)
    end

    ctx.initializeCardHealthState(drawnCard)
    state.cards[#state.cards + 1] = drawnCard
    state.cardExpansion[#state.cards] = 0
    state.cardEntranceProgress[#state.cards] = options and options.animate == false and 1 or 0
    ctx.playHunterAddedSfxForCard(drawnCard)

    if drawnCardDefinition
        and drawnCardDefinition.type == "ally"
        and spawncontroller.getNextOpenHandSlot(ctx) then
        spawncontroller.drawCardFromPlayerDeck(ctx, nil, (chainDepth or 0) + 1, options)
    end

    return drawnCard
end

function spawncontroller.resolveHuntersInHand(ctx)
    local resolvedCount = 0

    while resolvedCount < HUNTER_CHAIN_LIMIT do
        local hunterCardIndex = nil
        local hunterCard = nil
        local hunterDefinition = nil

        for cardIndex, card in ipairs(ctx.state.cards or {}) do
            local cardDefinition = getCardDefinition(ctx, card)

            if card
                and card.location
                and card.location.kind == "hand"
                and isHunterDefinition(cardDefinition) then
                hunterCardIndex = cardIndex
                hunterCard = card
                hunterDefinition = cardDefinition
                break
            end
        end

        if not hunterCardIndex then
            break
        end

        local replacementSlotIndex = hunterCard.location.slotIndex

        table.remove(ctx.state.cards, hunterCardIndex)

        if ctx.state.cardExpansion and #ctx.state.cardExpansion >= hunterCardIndex then
            table.remove(ctx.state.cardExpansion, hunterCardIndex)
        end

        if ctx.state.cardEntranceProgress and #ctx.state.cardEntranceProgress >= hunterCardIndex then
            table.remove(ctx.state.cardEntranceProgress, hunterCardIndex)
        end

        playDrawnHunter(ctx, hunterCard, hunterDefinition)
        spawncontroller.drawCardFromPlayerDeck(ctx, replacementSlotIndex, resolvedCount + 1)
        resolvedCount = resolvedCount + 1
    end

    return resolvedCount
end

return spawncontroller
