local inputcontroller = {}

local function clearHoverAndExpansion(gameState)
    gameState.expandedGridCardIndex = nil
    gameState.expandedTopSlotId = nil
    gameState.hoveredCardIndex = nil
    gameState.hoveredKeyword = nil
    gameState.hoveredEnhancement = nil
    gameState.hoveredButtonBadge = nil
    gameState.hoveredCardAbilityPreviewCards = nil
    gameState.hoveredCardAbilityPreviewLabel = nil
    gameState.hoveredCardAbilityPreviewDefinition = nil
    gameState.hoveredCardAbilityPreviewCardIndex = nil
end

local function handleModals(x, y, button, deps)
    local modalState = deps.buildModalState()
    local modalDeps = deps.getModalDeps()

    if deps.modals.handleDeckModalMousePressed(x, y, button, modalState, modalDeps)
        or deps.modals.handleSyntacMethodModalMousePressed(x, y, button, modalState, modalDeps)
        or deps.modals.handleResourceExchangeMousePressed(x, y, button, modalState, modalDeps)
        or deps.modals.handlePrimedSpecialMousePressed(x, y, button, modalState, modalDeps) then
        deps.applyModalState(modalState)
        return true
    end

    deps.applyModalState(modalState)
    return false
end

local function isPointInRect(x, y, rect)
    return rect
        and x >= rect.x
        and x <= rect.x + rect.width
        and y >= rect.y
        and y <= rect.y + rect.height
end

local function handleMulligan(gameState, deps, x, y, button)
    if not gameState.mulliganActive then
        return false
    end

    if button ~= 1 then
        return true
    end

    if gameState.mulliganResolving then
        return true
    end

    local layout = deps.envdraw.getMulliganPromptLayout()

    if isPointInRect(x, y, layout.button) then
        deps.resolveOpeningMulligan()
        clearHoverAndExpansion(gameState)
        return true
    end

    deps.updateHoveredCard()

    for cardIndex = #gameState.cards, 1, -1 do
        local card = gameState.cards[cardIndex]

        if card
            and card.location
            and card.location.kind == "hand"
            and not deps.isTomeCard(card) then
            local drawX, drawY, expansionProgress, renderOptions = deps.getCardDrawPosition(card, cardIndex)

            if deps.carddraw.isPointInsideDrawnCard(x, y, drawX, drawY, expansionProgress, nil, renderOptions) then
                gameState.mulliganSelection = gameState.mulliganSelection or {}
                gameState.mulliganSelection[cardIndex] = not gameState.mulliganSelection[cardIndex] or nil
                return true
            end
        end
    end

    return true
end

function inputcontroller.mousepressed(gameState, deps, x, y, button)
    if button ~= 1 and button ~= 2 and button ~= 3 then
        return
    end

    if gameState.fullArtImage then
        if button == 1 then
            gameState.fullArtImage = nil
        end

        return
    end

    if handleMulligan(gameState, deps, x, y, button) then
        return
    end

    if gameState.primedSyntacAbility and button == 2 then
        if deps.refundPrimedSyntacAbility then
            deps.refundPrimedSyntacAbility()
        end

        clearHoverAndExpansion(gameState)
        return
    end

    if button == 2
        and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl"))
        and deps.tryOpenFullArt(x, y) then
        return
    end

    if handleModals(x, y, button, deps) then
        return
    end

    deps.updateHoveredCard()
    gameState.hoveredTopSlotId = deps.getHoveredTopSlotId(x, y)
    local hoveredPlayerRollBadgeCardIndex = deps.getHoveredPlayerRollBadgeCardIndex(x, y)
    local hoveredTopSlotRollBadgeId = deps.getHoveredTopSlotRollBadgeId and deps.getHoveredTopSlotRollBadgeId(x, y) or nil
    local clickedScratchBadge = deps.isPointInsideJaclScratchBadge(x, y)
    local clickedJaclPortrait = deps.isPointInsideJaclPortrait(x, y)
    local clickedJaclMethodBadge = deps.envdraw.getJaclMethodBadgeAt(x, y, gameState.playerJacl)
    local clickedCardButtonBadge = deps.getCardButtonBadgeTarget and deps.getCardButtonBadgeTarget(x, y) or nil
    local clickedCardMethodBadge = deps.getCardMethodBadgeTarget and deps.getCardMethodBadgeTarget(x, y) or nil

    if gameState.primedSyntacAbility then
        if button == 2 then
            if deps.refundPrimedSyntacAbility then
                deps.refundPrimedSyntacAbility()
            end

            clearHoverAndExpansion(gameState)
            return
        end

        if button == 1 then
            if deps.tryResolvePrimedSyntacAbility
                and deps.tryResolvePrimedSyntacAbility(gameState.hoveredCardIndex, gameState.hoveredTopSlotId) then
                clearHoverAndExpansion(gameState)
                return
            end

            deps.sfxrules.playPlayReject()
            return
        end

        return
    end

    if deps.hasPendingStrategySelection and deps.hasPendingStrategySelection() then
        local pendingSelection = deps.getPendingSelection and deps.getPendingSelection() or nil

        if button == 2
            and deps.cancelPendingStrategySelection
            and (not pendingSelection or pendingSelection.kind ~= "hand_limit_discard") then
            deps.cancelPendingStrategySelection()
            clearHoverAndExpansion(gameState)
            return
        end

        if button == 1 and deps.tryResolvePendingStrategySelection then
            if deps.tryResolvePendingStrategySelection(gameState.hoveredCardIndex, gameState.hoveredTopSlotId) then
                clearHoverAndExpansion(gameState)
            end

            return
        end

        return
    end

    if button == 1 and deps.tryUseEngageReroll(x, y) then
        return
    end

    if button == 1 and deps.tryPrimeSyntacAbility and deps.tryPrimeSyntacAbility(x, y) then
        clearHoverAndExpansion(gameState)
        return
    end

    if button == 1 and deps.tryUseSyntacRewardButton and deps.tryUseSyntacRewardButton(x, y) then
        clearHoverAndExpansion(gameState)
        return
    end

    if button == 1 and clickedCardButtonBadge then
        if deps.tryUseCardButtonBadge(clickedCardButtonBadge.cardIndex) then
            deps.sfxrules.playResourcePlay()
            clearHoverAndExpansion(gameState)
            return
        end

        deps.sfxrules.playPlayReject()
        return
    end

    if button == 1 and clickedCardMethodBadge then
        if deps.primeCardMethodAbility(clickedCardMethodBadge.cardIndex, clickedCardMethodBadge.resource) then
            clearHoverAndExpansion(gameState)
            return
        end

        deps.sfxrules.playPlayReject()
        return
    end

    if button == 1 and clickedJaclMethodBadge then
        if deps.primeJaclSpecial(clickedJaclMethodBadge.resource) then
            clearHoverAndExpansion(gameState)
            return
        end

        deps.sfxrules.playPlayReject()
    end

    if button == 2 and clickedScratchBadge and deps.turnrules.getCurrentPhase() == "Prelude" then
        gameState.isResourceExchangeModalOpen = true
        clearHoverAndExpansion(gameState)
        return
    end

    if button == 3 and clickedJaclPortrait and deps.canOpenPlayerDeckModal() then
        local openModalState = deps.buildModalState()
        deps.modals.resetAndOpenJaclDeck(openModalState, gameState.playerDeck)
        deps.applyModalState(openModalState)
        clearHoverAndExpansion(gameState)
        return
    end

    if button == 3 and gameState.hoveredTopSlotId == "champion" and gameState.championDeck then
        local openModalState = deps.buildModalState()
        deps.modals.resetAndOpenJaclDeck(openModalState, gameState.championDeck)
        deps.applyModalState(openModalState)
        clearHoverAndExpansion(gameState)
        return
    end

    if button == 2 and deps.tryCancelSelectedEngageAttacker() then
        return
    end

    if button == 2 and hoveredPlayerRollBadgeCardIndex then
        deps.warrules.toggleCardLock(hoveredPlayerRollBadgeCardIndex)
        return
    end

    if button == 2
        and hoveredTopSlotRollBadgeId
        and deps.isAlliedTopSlot
        and deps.isAlliedTopSlot(hoveredTopSlotRollBadgeId) then
        deps.warrules.toggleTopSlotLock(hoveredTopSlotRollBadgeId)
        return
    end

    if button == 1
        and not gameState.selectedAttackerCardIndex
        and not gameState.selectedAttackerTopSlotId
        and gameState.hoveredCardIndex
        and deps.tryUseTomeCard(gameState.hoveredCardIndex, x, y) then
        deps.sfxrules.playResourcePlay()
        return
    end

    if button == 1 and deps.tryResolveEngageClick(gameState.hoveredTopSlotId) then
        return
    end

    if gameState.expandedGridCardIndex then
        if button == 2 and (gameState.hoveredTopSlotId or (gameState.hoveredCardIndex and deps.canExpandCard(gameState.cards[gameState.hoveredCardIndex]))) then
            if gameState.hoveredTopSlotId then
                gameState.expandedGridCardIndex = nil
                gameState.expandedTopSlotId = gameState.hoveredTopSlotId
                deps.sfxrules.playCharSelect()
            elseif hoveredPlayerRollBadgeCardIndex then
                return
            elseif gameState.hoveredCardIndex == gameState.expandedGridCardIndex then
                gameState.expandedGridCardIndex = nil
                gameState.hoveredCardIndex = nil
            else
                gameState.expandedGridCardIndex = gameState.hoveredCardIndex
                deps.sfxrules.playCharSelect()
            end

            return
        end

        gameState.expandedGridCardIndex = nil
        gameState.hoveredCardIndex = nil
        return
    end

    if gameState.expandedTopSlotId then
        if button == 2 and (gameState.hoveredTopSlotId or (gameState.hoveredCardIndex and deps.canExpandCard(gameState.cards[gameState.hoveredCardIndex]))) then
            if gameState.hoveredTopSlotId then
                if gameState.hoveredTopSlotId == gameState.expandedTopSlotId then
                    gameState.expandedTopSlotId = nil
                else
                    gameState.expandedTopSlotId = gameState.hoveredTopSlotId
                    deps.sfxrules.playCharSelect()
                end
            else
                gameState.expandedTopSlotId = nil
                gameState.expandedGridCardIndex = gameState.hoveredCardIndex
                deps.sfxrules.playCharSelect()
            end

            return
        end

        gameState.expandedTopSlotId = nil
        gameState.hoveredCardIndex = nil
        return
    end

    if button == 2 then
        if gameState.hoveredTopSlotId then
            gameState.expandedTopSlotId = gameState.hoveredTopSlotId
            deps.sfxrules.playCharSelect()
        elseif hoveredPlayerRollBadgeCardIndex then
            return
        elseif gameState.hoveredCardIndex and deps.canExpandCard(gameState.cards[gameState.hoveredCardIndex]) then
            gameState.expandedGridCardIndex = gameState.hoveredCardIndex
            deps.sfxrules.playCharSelect()
        end

        return
    end

    if not gameState.hoveredCardIndex then
        return
    end

    if gameState.cards[gameState.hoveredCardIndex].location.kind == "hand" then
        local hoveredCard = gameState.cards[gameState.hoveredCardIndex]
        local canDragStrategy = deps.isStrategyCard(hoveredCard)
            and deps.isStrategyPhase
            and deps.isStrategyPhase()

        if deps.turnrules.getCurrentPhase() ~= "Prelude" and not canDragStrategy then
            return
        end
    end

    if deps.isGridCard(gameState.cards[gameState.hoveredCardIndex]) then
        return
    end

    if deps.turnrules.getCurrentPhase() == deps.turnrules.getSetupPhase()
        and not deps.isSetupCard(gameState.cards[gameState.hoveredCardIndex]) then
        return
    end

    gameState.draggedCardIndex = gameState.hoveredCardIndex
    gameState.draggedCardOrigin = deps.copyLocation(gameState.cards[gameState.draggedCardIndex].location)
    gameState.expandedGridCardIndex = nil
    gameState.expandedTopSlotId = nil

    local drawX, drawY = deps.getCardDrawPosition(gameState.cards[gameState.draggedCardIndex], gameState.draggedCardIndex)
    gameState.dragOffsetX = x - drawX
    gameState.dragOffsetY = y - drawY
    gameState.cardExpansion[gameState.draggedCardIndex] = 0
    gameState.hoveredCardIndex = nil
end

function inputcontroller.wheelmoved(gameState, deps, _, y)
    if gameState.mulliganActive then
        return
    end

    local modalState = deps.buildModalState()

    if deps.modals.handleWheelMoved(y, modalState, {
        envdraw = deps.envdraw,
    }) then
        deps.applyModalState(modalState)
    end
end

function inputcontroller.mousereleased(gameState, deps, x, y, button)
    if gameState.mulliganActive then
        gameState.draggedCardIndex = nil
        gameState.draggedCardOrigin = nil
        return
    end

    if button ~= 1 or not gameState.draggedCardIndex then
        return
    end

    local draggedCard = gameState.cards[gameState.draggedCardIndex]
    local isStrategyCard = deps.isStrategyCard(draggedCard)
    local isKitCard = deps.isKitCard and deps.isKitCard(draggedCard)

    if isStrategyCard then
        local targetCardIndex = deps.getGridCardAt(x, y, gameState.draggedCardIndex)
        local played = deps.tryPlayStrategyCard(gameState.draggedCardIndex, targetCardIndex)

        if played then
            deps.normalizeHandCardSlots()
            deps.sfxrules.playResourcePlay()
        else
            gameState.cards[gameState.draggedCardIndex].location = deps.copyLocation(gameState.draggedCardOrigin)

            if targetCardIndex then
                deps.sfxrules.playPlayReject()
            end
        end

        gameState.draggedCardIndex = nil
        gameState.draggedCardOrigin = nil
        gameState.expandedGridCardIndex = nil
        gameState.hoveredCardIndex = nil
        deps.updateHoveredCard()
        return
    end

    if isKitCard then
        local targetCardIndex = deps.getGridCardAt(x, y, gameState.draggedCardIndex)
        local played = deps.tryPlayKitCard and deps.tryPlayKitCard(gameState.draggedCardIndex, targetCardIndex)

        if played then
            deps.normalizeHandCardSlots()
            deps.sfxrules.playResourcePlay()
        else
            gameState.cards[gameState.draggedCardIndex].location = deps.copyLocation(gameState.draggedCardOrigin)

            if targetCardIndex then
                deps.sfxrules.playPlayReject()
            end
        end

        gameState.draggedCardIndex = nil
        gameState.draggedCardOrigin = nil
        gameState.expandedGridCardIndex = nil
        gameState.hoveredCardIndex = nil
        deps.updateHoveredCard()
        return
    end

    local dropColumn = deps.getValidDropColumn(x, y, gameState.draggedCardIndex, draggedCard)

    local canPlayDrop = dropColumn and deps.canPlayCard(draggedCard)

    if canPlayDrop and deps.payCardCosts(draggedCard) then
        local targetRowId = deps.isHunterCard(draggedCard) and "OppRow" or "PlayerRow"
        gameState.cards[gameState.draggedCardIndex].location = {
            kind = "grid",
            rowId = targetRowId,
            column = dropColumn,
        }
        if deps.resolvePlayedTroopCard then
            deps.resolvePlayedTroopCard(gameState.draggedCardIndex)
        end

        if gameState.draggedCardOrigin.kind == "hand" then
            deps.normalizeHandCardSlots()
        end
        deps.sfxrules.playUnitPlay()
    elseif dropColumn and not canPlayDrop then
        deps.sfxrules.playPlayReject()
        deps.notifications.push("Not Enough Resources")
    else
        gameState.cards[gameState.draggedCardIndex].location = deps.copyLocation(gameState.draggedCardOrigin)
    end

    if gameState.draggedCardOrigin.kind == "setup" then
        deps.normalizeSetupCardSlots()
    end

    gameState.draggedCardIndex = nil
    gameState.draggedCardOrigin = nil
    gameState.expandedGridCardIndex = nil
    gameState.hoveredCardIndex = nil
    deps.completeSetupPhaseIfReady()
    deps.updateHoveredCard()
end

function inputcontroller.keypressed(gameState, deps, key)
    if gameState.mulliganActive then
        if not gameState.mulliganResolving
            and (key == "return" or key == "kpenter" or key == "space") then
            deps.resolveOpeningMulligan()
            clearHoverAndExpansion(gameState)
        end

        return
    end

    if deps.hasPendingStrategySelection and deps.hasPendingStrategySelection() and key == "space" then
        return
    end

    if key == "escape" then
        local modalState = deps.buildModalState()

        if deps.modals.handleEscapeKey(modalState) then
            deps.applyModalState(modalState)
        else
            love.event.quit()
        end
    elseif key == "space" and deps.turnrules.getCurrentPhase() == "Prelude" then
        deps.phasecontroller.advancePrelude(gameState, deps.getPhaseControllerDeps())
    elseif key == "space" and deps.isEngagePhase() then
        deps.phasecontroller.beginRetaliateFromEngage(gameState, deps.getPhaseControllerDeps())
    end
end

return inputcontroller
