local uibridge = {}

function uibridge.buildModalState(c)
    return c.contextbuilders.buildModalState(c.gameState)
end

function uibridge.applyModalState(c, modalState)
    c.contextbuilders.applyModalState(c.gameState, modalState)
end

function uibridge.getModalDeps(c)
    return c.contextbuilders.getModalDeps(c.getContextBuildersContext())
end

function uibridge.getHoverPreviewDeps(c)
    return c.contextbuilders.getHoverPreviewDeps(c.getContextBuildersContext())
end

function uibridge.getInputControllerDeps(c)
    return c.contextbuilders.getInputControllerDeps(c.getContextBuildersContext())
end

function uibridge.getHoverPreviewState(c)
    return c.hoverpreview.getHoverPreviewState(c.gameState, uibridge.getHoverPreviewDeps(c))
end

function uibridge.isPointInsideJaclScratchBadge(c, mouseX, mouseY)
    return c.modals.isPointInsideJaclScratchBadge(mouseX, mouseY, c.envdraw, c.gameState.playerJacl)
end

function uibridge.isPointInsideJaclPortrait(c, mouseX, mouseY)
    return c.modals.isPointInsideJaclPortrait(mouseX, mouseY, c.envdraw, c.gameState.playerJacl)
end

function uibridge.primeJaclSpecial(c, resourceName)
    local modalState = uibridge.buildModalState(c)
    local primed = c.modals.primeJaclSpecial(resourceName, modalState, uibridge.getModalDeps(c))

    uibridge.applyModalState(c, modalState)
    return primed
end

function uibridge.primeCardMethodAbility(c, cardIndex, resourceName)
    local modalState = uibridge.buildModalState(c)
    local primed = c.abilityrules.primeCardMethodAbility(
        cardIndex,
        resourceName,
        modalState,
        uibridge.getModalDeps(c)
    )

    uibridge.applyModalState(c, modalState)
    return primed
end

function uibridge.tryUseEngageReroll(c, mouseX, mouseY)
    return c.engagerules.tryUseReroll(mouseX, mouseY, c.getEngageContext())
end

function uibridge.getHoveredTopSlotRollBadgeId(c, mouseX, mouseY)
    return c.boardquery.getHoveredTopSlotRollBadgeId(c.getBoardQueryContext(), mouseX, mouseY)
end

function uibridge.tryCancelSelectedEngageAttacker(c)
    return c.engagerules.tryCancelSelectedAttacker(c.getEngageContext())
end

function uibridge.clearHoveredSpawnPreview(c)
    c.hoverpreview.clearSpawnPreview(c.gameState)
end

function uibridge.updateHoveredCard(c)
    c.hoverpreview.updateHoveredCard(c.gameState, uibridge.getHoverPreviewDeps(c))
end

function uibridge.tryOpenFullArt(c, mouseX, mouseY)
    local image = c.getFullArtAt(mouseX, mouseY)

    if not image then
        return false
    end

    c.gameState.fullArtImage = image
    c.gameState.draggedCardIndex = nil
    c.gameState.draggedCardOrigin = nil
    c.gameState.expandedGridCardIndex = nil
    c.gameState.expandedTopSlotId = nil
    return true
end

return uibridge
