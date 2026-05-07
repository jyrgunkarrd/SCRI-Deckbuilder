local lifecyclebridge = {}

function lifecyclebridge.getCardLifecycleContext(c)
    return c.contextbuilders.getCardLifecycleContext(c.getContextBuildersContext())
end

function lifecyclebridge.getGameActionsContext(c)
    return c.contextbuilders.getGameActionsContext(c.getContextBuildersContext())
end

function lifecyclebridge.getDamageJitterKeyForCard(cardIndex)
    return "card:" .. tostring(cardIndex)
end

function lifecyclebridge.startCardDestruction(c, cardIndex)
    return c.cardlifecycle.startCardDestruction(lifecyclebridge.getCardLifecycleContext(c), cardIndex)
end

function lifecyclebridge.startChampionDestruction(c)
    c.topsloteffects.startChampionDestruction(c.gameState.activeChampion)
end

function lifecyclebridge.startIntelDestruction(c)
    c.topsloteffects.startIntelDestruction(c.gameState.activeIntel)
end

function lifecyclebridge.triggerDamageFeedback(c, entityKey)
    if not entityKey then
        return
    end

    c.gameState.damageJitters[entityKey] = {
        elapsed = 0,
        duration = c.appconfig.DAMAGE_JITTER_DURATION,
        magnitude = c.appconfig.DAMAGE_JITTER_MAGNITUDE,
    }
    c.sfxrules.playDamage()
end

function lifecyclebridge.getDamageJitterOffset(c, entityKey)
    local jitter = c.gameState.damageJitters[entityKey]

    if not jitter then
        return 0, 0
    end

    local remainingRatio = math.max(0, 1 - (jitter.elapsed / jitter.duration))
    local amplitude = jitter.magnitude * remainingRatio
    local offsetX = math.sin(jitter.elapsed * 90) * amplitude
    local offsetY = math.cos(jitter.elapsed * 72) * amplitude * 0.5

    return offsetX, offsetY
end

function lifecyclebridge.releaseAttachedKits(c, card)
    return c.cardlifecycle.releaseAttachedKits(lifecyclebridge.getCardLifecycleContext(c), card)
end

function lifecyclebridge.removeCardFromPlay(c, cardIndex)
    return c.cardlifecycle.removeCardFromPlay(lifecyclebridge.getCardLifecycleContext(c), cardIndex)
end

function lifecyclebridge.expireCardFromPlay(c, cardIndex)
    return c.cardlifecycle.expireCardFromPlay(lifecyclebridge.getCardLifecycleContext(c), cardIndex)
end

function lifecyclebridge.discardCardFromPlay(c, cardIndex)
    return c.cardlifecycle.discardCardFromPlay(lifecyclebridge.getCardLifecycleContext(c), cardIndex)
end

function lifecyclebridge.initializeCardHealthState(c, card)
    return c.gameactions.initializeCardHealthState(card)
end

function lifecyclebridge.initializeCardsHealthState(c, cardList)
    return c.gameactions.initializeCardsHealthState(cardList)
end

function lifecyclebridge.addObjectiveProgress(c, objectiveDefinition, amount, slotId)
    return c.gameactions.addObjectiveProgress(
        lifecyclebridge.getGameActionsContext(c),
        objectiveDefinition,
        amount,
        slotId
    )
end

function lifecyclebridge.canApplyObjectiveProgress(c, objectiveDefinition, amount)
    return c.gameactions.canApplyObjectiveProgress(objectiveDefinition, amount)
end

function lifecyclebridge.addWarzoneControl(c, warzoneDefinition, amount, slotId)
    return c.gameactions.addWarzoneControl(
        lifecyclebridge.getGameActionsContext(c),
        warzoneDefinition,
        amount,
        slotId
    )
end

function lifecyclebridge.dealDamageToCard(c, card, amount, suppressFeedback)
    return c.gameactions.dealDamageToCard(
        lifecyclebridge.getGameActionsContext(c),
        card,
        amount,
        suppressFeedback
    )
end

function lifecyclebridge.dealDirectDamageToCard(c, card, amount, suppressFeedback)
    return c.gameactions.dealDirectDamageToCard(
        lifecyclebridge.getGameActionsContext(c),
        card,
        amount,
        suppressFeedback
    )
end

function lifecyclebridge.addBlockingToCard(c, card, amount, options)
    return c.gameactions.addBlockingToCard(card, amount, options)
end

function lifecyclebridge.healCard(c, card, amount)
    return c.gameactions.healCard(lifecyclebridge.getGameActionsContext(c), card, amount)
end

function lifecyclebridge.clearAllBlocking(c)
    return c.gameactions.clearAllBlocking(lifecyclebridge.getGameActionsContext(c))
end

function lifecyclebridge.clearEnemyGuardCarryBlocking(c)
    return c.gameactions.clearEnemyGuardCarryBlocking(lifecyclebridge.getGameActionsContext(c))
end

function lifecyclebridge.dealDamageToChampion(c, amount, suppressFeedback)
    return c.gameactions.dealDamageToChampion(
        lifecyclebridge.getGameActionsContext(c),
        amount,
        suppressFeedback
    )
end

return lifecyclebridge
