local modals = {}

local function isPointInsideRect(mouseX, mouseY, rect)
    return rect
        and mouseX >= rect.x
        and mouseX <= rect.x + rect.width
        and mouseY >= rect.y
        and mouseY <= rect.y + rect.height
end

function modals.isPointInsideJaclScratchBadge(mouseX, mouseY, envdraw, playerJacl)
    local layout = envdraw.getBottomLeftPanelLayout(playerJacl)

    return layout
        and mouseX >= layout.scratchBadgeX
        and mouseX <= layout.scratchBadgeX + layout.scratchBadgeSize
        and mouseY >= layout.scratchBadgeY
        and mouseY <= layout.scratchBadgeY + layout.scratchBadgeSize
end

function modals.isPointInsideJaclPortrait(mouseX, mouseY, envdraw, playerJacl)
    local layout = envdraw.getBottomLeftPanelLayout(playerJacl)

    return layout
        and mouseX >= layout.contentX
        and mouseX <= layout.contentX + layout.contentWidth
        and mouseY >= layout.contentY
        and mouseY <= layout.contentY + layout.contentHeight
end

function modals.isPointInsideResourceExchangeModal(mouseX, mouseY, envdraw)
    return isPointInsideRect(mouseX, mouseY, envdraw.getResourceExchangeModalLayout())
end

function modals.isPointInsideSyntacMethodModal(mouseX, mouseY, envdraw)
    return isPointInsideRect(mouseX, mouseY, envdraw.getSyntacMethodModalLayout())
end

function modals.isPointInsideJaclDeckModal(mouseX, mouseY, envdraw, activeDeckModalDeck, jaclDeckModalScroll)
    return isPointInsideRect(mouseX, mouseY, envdraw.getJaclDeckModalLayout(activeDeckModalDeck, {
        top = { scrollY = jaclDeckModalScroll.deck },
        bottom = { scrollY = jaclDeckModalScroll.discard },
    }))
end

local function getDeckPreview(card, deps)
    local cardDefinition = card
        and deps.cardregistry
        and deps.cardregistry.getCard(card.setName, card.cardId)
        or nil

    return deps.previewrules
        and deps.previewrules.getDefinitionPreview(cardDefinition)
        or nil
end

function modals.isPointInsideJaclDeckPreviewModal(mouseX, mouseY, deps, card)
    local preview = getDeckPreview(card, deps)
    return isPointInsideRect(
        mouseX,
        mouseY,
        deps.envdraw.getJaclDeckPreviewModalLayout(preview and preview.cardDefinitions or nil)
    )
end

function modals.getHoveredJaclDeckModalCard(mouseX, mouseY, envdraw, activeDeckModalDeck, jaclDeckModalScroll)
    return envdraw.getJaclDeckModalCardAt(mouseX, mouseY, activeDeckModalDeck, {
        top = { scrollY = jaclDeckModalScroll.deck },
        bottom = { scrollY = jaclDeckModalScroll.discard },
    })
end

function modals.primeJaclSpecial(resourceName, state, deps)
    return deps.abilityrules.primeJaclMethodAbility(resourceName, state, deps)
end

function modals.tryUsePrimedActivatedAbility(mouseX, mouseY, state, deps)
    if not state.primedActivatedAbility or not state.primedActivatedAbility.definition then
        return false
    end

    local targetRules = state.primedActivatedAbility.definition.target or nil

    if targetRules and targetRules.kind == "player_row_cell" then
        local targetCell = deps.getValidJaclSpecialTargetCell(mouseX, mouseY)

        if not targetCell then
            return false
        end

        targetCell.rowId = targetCell.rowId or targetRules.rowId
        return deps.abilityrules.resolvePrimedAbility(targetCell, state, deps)
    end

    if targetRules and targetRules.kind == "enemy_card_or_champion" then
        local topSlotId = deps.getHoveredTopSlotId and deps.getHoveredTopSlotId(mouseX, mouseY) or nil

        if topSlotId == "champion" then
            return deps.abilityrules.resolvePrimedAbility({
                kind = "top_slot",
                slotId = topSlotId,
            }, state, deps)
        end
    end

    local targetCardIndex = deps.getGridCardAt(mouseX, mouseY)
    if not targetCardIndex then
        return false
    end

    return deps.abilityrules.resolvePrimedAbility(targetCardIndex, state, deps)
end

function modals.tryExchangeScratchForModalResource(mouseX, mouseY, state, deps)
    local targetResource = deps.envdraw.getResourceExchangeModalResourceAt(mouseX, mouseY)

    if not targetResource then
        return false
    end

    if not deps.resourcerules.exchangeScratchForResource(targetResource) then
        deps.sfxrules.playPlayReject()
        return true
    end

    deps.addObjectiveProgress(state.activePrimaryObjective, 2)
    return true
end

function modals.tryExchangeModalResourceForScratch(mouseX, mouseY, state, deps)
    local sourceResource = deps.envdraw.getResourceExchangeModalResourceAt(mouseX, mouseY)

    if not sourceResource then
        return false
    end

    if not deps.resourcerules.exchangeResourceForScratch(sourceResource) then
        deps.sfxrules.playPlayReject()
        return true
    end

    deps.addObjectiveProgress(state.activePrimaryObjective, 1)
    return true
end

function modals.handleDeckModalMousePressed(x, y, button, state, deps)
    if not state.isJaclDeckModalOpen then
        return false
    end

    if button == 2 then
        local hoveredDeckModalCard = modals.getHoveredJaclDeckModalCard(
            x,
            y,
            deps.envdraw,
            state.activeDeckModalDeck,
            state.jaclDeckModalScroll
        )

        if hoveredDeckModalCard then
            state.jaclDeckPreviewCard = hoveredDeckModalCard
            return true
        end
    end

    if state.jaclDeckPreviewCard then
        if not modals.isPointInsideJaclDeckPreviewModal(x, y, deps, state.jaclDeckPreviewCard) then
            state.jaclDeckPreviewCard = nil
        end

        return true
    end

    if not modals.isPointInsideJaclDeckModal(
        x,
        y,
        deps.envdraw,
        state.activeDeckModalDeck,
        state.jaclDeckModalScroll
    ) then
        state.isJaclDeckModalOpen = false
        state.jaclDeckPreviewCard = nil
        state.activeDeckModalDeck = nil
    end

    return true
end

function modals.handleResourceExchangeMousePressed(x, y, button, state, deps)
    if not state.isResourceExchangeModalOpen then
        return false
    end

    if not modals.isPointInsideResourceExchangeModal(x, y, deps.envdraw) then
        state.isResourceExchangeModalOpen = false
    elseif button == 1 then
        modals.tryExchangeScratchForModalResource(x, y, state, deps)
    elseif button == 2 then
        modals.tryExchangeModalResourceForScratch(x, y, state, deps)
    end

    return true
end

function modals.handleSyntacMethodModalMousePressed(x, y, button, state, deps)
    if not state.isSyntacMethodModalOpen then
        return false
    end

    if button == 2 or not modals.isPointInsideSyntacMethodModal(x, y, deps.envdraw) then
        if deps.cancelSyntacMethodChoice then
            deps.cancelSyntacMethodChoice(state)
        else
            state.isSyntacMethodModalOpen = false
        end

        return true
    end

    if button == 1 then
        local resourceName = deps.envdraw.getSyntacMethodModalResourceAt(x, y)

        if resourceName and deps.chooseSyntacMethodResource then
            deps.chooseSyntacMethodResource(resourceName, state)
        end
    end

    return true
end

function modals.handlePrimedSpecialMousePressed(x, y, button, state, deps)
    if not state.primedActivatedAbility then
        return false
    end

    if button == 2 then
        state.primedActivatedAbility = nil
        return true
    end

    if button == 1 then
        local clickedCardMethodBadge = deps.getCardMethodBadgeTarget and deps.getCardMethodBadgeTarget(x, y) or nil

        if clickedCardMethodBadge then
            if not deps.abilityrules.primeCardMethodAbility(clickedCardMethodBadge.cardIndex, clickedCardMethodBadge.resource, state, deps) then
                deps.sfxrules.playPlayReject()
            end

            return true
        end

        local clickedMethodBadge = deps.envdraw.getJaclMethodBadgeAt(x, y, state.playerJacl)

        if clickedMethodBadge then
            if not modals.primeJaclSpecial(clickedMethodBadge.resource, state, deps) then
                deps.sfxrules.playPlayReject()
            end

            return true
        end

        if modals.tryUsePrimedActivatedAbility(x, y, state, deps) then
            return true
        end

        if deps.turnrules.getCurrentPhase() == "Prelude" then
            local validTargetCell = deps.getPlayerRowCellAt(x, y)

            if validTargetCell then
                deps.sfxrules.playPlayReject()
                return true
            end

            local targetCardIndex = deps.getGridCardAt and deps.getGridCardAt(x, y) or nil

            if targetCardIndex then
                deps.sfxrules.playPlayReject()
            end
        end
    end

    return true
end

function modals.resetAndOpenJaclDeck(state, deck)
    state.isJaclDeckModalOpen = true
    state.activeDeckModalDeck = deck
    state.isResourceExchangeModalOpen = false
    state.jaclDeckModalScroll.deck = 0
    state.jaclDeckModalScroll.discard = 0
    state.jaclDeckPreviewCard = nil
end

function modals.handleWheelMoved(y, state, deps)
    if not state.isJaclDeckModalOpen or y == 0 then
        return false
    end

    local mouseX, mouseY = love.mouse.getPosition()
    local sectionId, section = deps.envdraw.getJaclDeckModalSectionAt(mouseX, mouseY, state.activeDeckModalDeck, {
        top = { scrollY = state.jaclDeckModalScroll.deck },
        bottom = { scrollY = state.jaclDeckModalScroll.discard },
    })

    if not sectionId or not section or section.maxScroll <= 0 then
        return true
    end

    local scrollDelta = -y * 56

    if sectionId == "deck" then
        state.jaclDeckModalScroll.deck = math.max(0, math.min(section.maxScroll, state.jaclDeckModalScroll.deck + scrollDelta))
    elseif sectionId == "discard" then
        state.jaclDeckModalScroll.discard = math.max(0, math.min(section.maxScroll, state.jaclDeckModalScroll.discard + scrollDelta))
    end

    return true
end

function modals.handleEscapeKey(state)
    if state.jaclDeckPreviewCard then
        state.jaclDeckPreviewCard = nil
        return true
    end

    if state.isJaclDeckModalOpen then
        state.isJaclDeckModalOpen = false
        state.activeDeckModalDeck = nil
        return true
    end

    if state.isResourceExchangeModalOpen then
        state.isResourceExchangeModalOpen = false
        return true
    end

    return false
end

return modals
