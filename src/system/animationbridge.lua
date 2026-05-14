local cardanimations = require("src.render.cardanimations")

local animationbridge = {}

function animationbridge.getContext(c)
    local state = c.gameState

    state.hunterDeckDiscardAnimations = state.hunterDeckDiscardAnimations or {}
    state.haywireDeckAddAnimations = state.haywireDeckAddAnimations or {}

    return {
        cards = state.cards,
        playerDeck = state.playerDeck,
        kitReturnAnimations = state.kitReturnAnimations,
        pilotVehicleAnimations = state.pilotVehicleAnimations,
        hunterAutoPlayAnimations = state.hunterAutoPlayAnimations,
        hunterDeckDiscardAnimations = state.hunterDeckDiscardAnimations,
        haywireDeckAddAnimations = state.haywireDeckAddAnimations,
        mulliganActive = state.mulliganActive,
        mulliganResolving = state.mulliganResolving,
        mulliganPromptAlpha = state.mulliganPromptAlpha,
        mulliganReturnedCards = state.mulliganReturnedCards,
        mulliganCompleted = state.mulliganCompleted,
        cardregistry = c.cardregistry,
        envdraw = c.envdraw,
        sfxrules = c.sfxrules,
        warrules = c.warrules,
        getCardDrawPosition = c.getCardDrawPosition,
        getPlayerHandLayout = c.getPlayerHandLayout,
        copyLocation = c.copyLocation,
        normalizeHandCardSlots = c.normalizeHandCardSlots,
        kitReturnFlashDuration = c.kitReturnFlashDuration,
        kitReturnExpandDuration = c.kitReturnExpandDuration,
        kitReturnFlyDuration = c.kitReturnFlyDuration,
        kitReturnTotalDuration = c.kitReturnTotalDuration,
        pilotVehicleAnimationDuration = c.pilotVehicleAnimationDuration,
        hunterAutoPlayAnimationDuration = c.hunterAutoPlayAnimationDuration,
        mulliganPromptFadeDuration = c.mulliganPromptFadeDuration,
        destructionDuration = c.destructionDuration,
    }
end

local function syncMulliganState(c, animationContext)
    local state = c.gameState

    state.mulliganPromptAlpha = animationContext.mulliganPromptAlpha
    state.mulliganReturnedCards = animationContext.mulliganReturnedCards
    state.mulliganResolving = animationContext.mulliganResolving
    state.mulliganActive = animationContext.mulliganActive
    state.mulliganCompleted = animationContext.mulliganCompleted
end

function animationbridge.pilotCardWithVehicleAtIndex(c, cardIndex, vehicleDefinition)
    return cardanimations.pilotCardWithVehicleAtIndex(
        animationbridge.getContext(c),
        cardIndex,
        vehicleDefinition
    )
end

function animationbridge.beginKitReturnAnimation(c, hostCard, attachedKit, returningCard)
    return cardanimations.beginKitReturnAnimation(
        animationbridge.getContext(c),
        hostCard,
        attachedKit,
        returningCard
    )
end

function animationbridge.beginHunterAutoPlayAnimation(c, card, sourceSlotIndex, rowId, column)
    return cardanimations.beginHunterAutoPlayAnimation(
        animationbridge.getContext(c),
        card,
        sourceSlotIndex,
        rowId,
        column
    )
end

function animationbridge.beginHunterDeckDiscardAnimation(c, card)
    return cardanimations.beginHunterDeckDiscardAnimation(animationbridge.getContext(c), card)
end

function animationbridge.beginHaywireDeckAddAnimation(c, card)
    return cardanimations.beginHaywireDeckAddAnimation(animationbridge.getContext(c), card)
end

function animationbridge.updateKitReturnAnimations(c, dt)
    cardanimations.updateKitReturnAnimations(animationbridge.getContext(c), dt)
end

function animationbridge.updatePilotVehicleAnimations(c, dt)
    cardanimations.updatePilotVehicleAnimations(animationbridge.getContext(c), dt)
end

function animationbridge.updateHunterAutoPlayAnimations(c, dt)
    cardanimations.updateHunterAutoPlayAnimations(animationbridge.getContext(c), dt)
end

function animationbridge.updateHunterDeckDiscardAnimations(c, dt)
    cardanimations.updateHunterDeckDiscardAnimations(animationbridge.getContext(c), dt)
end

function animationbridge.updateHaywireDeckAddAnimations(c, dt)
    cardanimations.updateHaywireDeckAddAnimations(animationbridge.getContext(c), dt)
end

function animationbridge.updateMulliganAnimations(c, dt)
    local animationContext = animationbridge.getContext(c)

    cardanimations.updateMulliganAnimations(animationContext, dt)
    syncMulliganState(c, animationContext)
end

function animationbridge.drawKitReturnAnimations(c)
    cardanimations.drawKitReturnAnimations(animationbridge.getContext(c))
end

function animationbridge.drawPilotVehicleAnimations(c)
    cardanimations.drawPilotVehicleAnimations(animationbridge.getContext(c))
end

function animationbridge.drawHunterAutoPlayAnimations(c)
    cardanimations.drawHunterAutoPlayAnimations(animationbridge.getContext(c))
end

function animationbridge.drawHunterDeckDiscardAnimations(c)
    cardanimations.drawHunterDeckDiscardAnimations(animationbridge.getContext(c))
end

function animationbridge.drawHaywireDeckAddAnimations(c)
    cardanimations.drawHaywireDeckAddAnimations(animationbridge.getContext(c))
end

return animationbridge
