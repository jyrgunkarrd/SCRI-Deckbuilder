local spawnrules = require("src.system.spawnrules")

local spawncontroller = {}

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
        cardregistry = ctx.cardregistry,
        envdraw = ctx.envdraw,
        turnrules = ctx.turnrules,
        warrules = ctx.warrules,
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

function spawncontroller.drawCardFromPlayerDeck(ctx)
    local state = ctx.state
    local nextSlotIndex = spawncontroller.getNextOpenHandSlot(ctx)

    if not nextSlotIndex then
        return nil
    end

    local drawnCard = ctx.deckrules.drawCardToHand(state.playerDeck, nextSlotIndex)

    if not drawnCard then
        return nil
    end

    ctx.initializeCardHealthState(drawnCard)
    state.cards[#state.cards + 1] = drawnCard
    state.cardExpansion[#state.cards] = 0
    state.cardEntranceProgress[#state.cards] = 1
    ctx.playHunterAddedSfxForCard(drawnCard)

    local drawnCardDefinition = ctx.cardregistry.getCard(drawnCard.setName, drawnCard.cardId)

    if drawnCardDefinition
        and drawnCardDefinition.type == "ally"
        and spawncontroller.getNextOpenHandSlot(ctx) then
        spawncontroller.drawCardFromPlayerDeck(ctx)
    end

    return drawnCard
end

return spawncontroller
