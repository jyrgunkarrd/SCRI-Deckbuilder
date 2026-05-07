local spawncontroller = require("src.system.spawncontroller")

local spawnbridge = {}

function spawnbridge.getContext(c)
    return {
        state = c.gameState,
        cardzones = c.cardzones,
        envrules = c.envrules,
        envdraw = c.envdraw,
        turnrules = c.turnrules,
        warrules = c.warrules,
        deckrules = c.deckrules,
        resourcerules = c.resourcerules,
        cardregistry = c.cardregistry,
        initializeCardHealthState = c.initializeCardHealthState,
        isCardDestroyed = c.isCardDestroyed,
        isCardUnavailable = c.isCardUnavailable,
        addObjectiveProgress = c.addObjectiveProgress,
        beginObjectiveHunterDeckTransformation = c.beginObjectiveHunterDeckTransformation,
        beginReinforcementHunterDeckTransformation = c.beginReinforcementHunterDeckTransformation,
        beginHunterAutoPlayAnimation = c.beginHunterAutoPlayAnimation,
        playHunterAddedSfxForCard = c.playHunterAddedSfxForCard,
        playHunterAddedSfxForCardDefinition = c.playHunterAddedSfxForCardDefinition,
    }
end

function spawnbridge.getNextOpenHandSlot(c)
    return spawncontroller.getNextOpenHandSlot(spawnbridge.getContext(c))
end

function spawnbridge.createGeneratedSupportCard(c, cardDefinition, targetLocation)
    return spawncontroller.createGeneratedSupportCard(spawnbridge.getContext(c), cardDefinition, targetLocation)
end

function spawnbridge.createGeneratedDeckCardShuffled(c, cardDefinition)
    return spawncontroller.createGeneratedDeckCardShuffled(spawnbridge.getContext(c), cardDefinition)
end

function spawnbridge.createGeneratedGridCard(c, cardDefinition, rowId, column)
    return spawncontroller.createGeneratedGridCard(spawnbridge.getContext(c), cardDefinition, rowId, column)
end

function spawnbridge.spawnTokensNearCard(c, sourceCardIndex, tokenDefinition, count, options)
    return spawncontroller.spawnTokensNearCard(
        spawnbridge.getContext(c),
        sourceCardIndex,
        tokenDefinition,
        count,
        options
    )
end

function spawnbridge.spawnRandomTokensNearCard(c, sourceCardIndex, tokenDefinitions, count, options)
    return spawncontroller.spawnRandomTokensNearCard(
        spawnbridge.getContext(c),
        sourceCardIndex,
        tokenDefinitions,
        count,
        options
    )
end

function spawnbridge.spawnTokensNearPlayerCard(c, sourceCardIndex, tokenDefinition, count, options)
    return spawncontroller.spawnTokensNearPlayerCard(
        spawnbridge.getContext(c),
        sourceCardIndex,
        tokenDefinition,
        count,
        options
    )
end

function spawnbridge.createOrStackPlayerCacheNearCard(c, sourceCardIndex, cacheDefinition, count)
    return spawncontroller.createOrStackPlayerCacheNearCard(
        spawnbridge.getContext(c),
        sourceCardIndex,
        cacheDefinition,
        count
    )
end

function spawnbridge.resolveEnemyEncounter(c, sourceCardIndex, enemyDefinition)
    return spawncontroller.resolveEnemyEncounter(spawnbridge.getContext(c), sourceCardIndex, enemyDefinition)
end

function spawnbridge.drawCardFromPlayerDeck(c, preferredSlotIndex, options)
    return spawncontroller.drawCardFromPlayerDeck(spawnbridge.getContext(c), preferredSlotIndex, nil, options)
end

function spawnbridge.resolveHuntersInHand(c)
    return spawncontroller.resolveHuntersInHand(spawnbridge.getContext(c))
end

return spawnbridge
