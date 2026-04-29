local hoverpreview = {}

local function copyRenderOptions(renderOptions)
    local copiedOptions = {}

    for key, value in pairs(renderOptions or {}) do
        copiedOptions[key] = value
    end

    return copiedOptions
end

function hoverpreview.clearSpawnPreview(state)
    state.hoveredTomeSpawnPreviewCard = nil
    state.hoveredTomeSpawnPreviewCards = nil
    state.hoveredTomeSpawnPreviewLabel = nil
    state.hoveredTomeSpawnPreviewCardIndex = nil
end

function hoverpreview.clearCardAbilityPreview(state)
    state.hoveredCardAbilityPreviewCards = nil
    state.hoveredCardAbilityPreviewLabel = nil
    state.hoveredCardAbilityPreviewDefinition = nil
    state.hoveredCardAbilityPreviewCardIndex = nil
end

function hoverpreview.getHoveredCardPreview(state, deps)
    local cardIndex = state.hoveredCardIndex
    local card = cardIndex and state.cards[cardIndex] or nil

    if not card
        or deps.isCardDestroyed(card)
        or card.returningToHandAnimation
        or deps.isCardUnavailable(card) then
        return nil
    end

    local drawX, drawY, expansionProgress, renderOptions = deps.getCardDrawPosition(card, cardIndex)
    local cardWidth, collapsedHeight = deps.carddraw.getCardSize(renderOptions)
    local _, expandedHeight = deps.carddraw.getExpandedCardSize(renderOptions)
    local cardHeight = collapsedHeight + ((expandedHeight - collapsedHeight) * (expansionProgress or 0))

    return {
        kind = "card",
        cardIndex = cardIndex,
        card = card,
        sourceRect = {
            x = drawX,
            y = drawY,
            width = cardWidth,
            height = cardHeight,
        },
        setName = card.setName,
        cardId = card.cardId,
        renderOptions = copyRenderOptions(renderOptions),
    }
end

function hoverpreview.getHoveredTopSlotPreview(state, deps)
    local slotId = state.hoveredTopSlotId

    if not slotId then
        return nil
    end

    local slots = deps.envdraw.getTopSlotLayouts(
        deps.turnrules.getCurrentPhase(),
        state.activeChampion,
        state.activeWarzone,
        state.activePoi,
        state.activePrimaryObjective,
        state.activeIntel
    )

    for _, slot in ipairs(slots or {}) do
        if slot.id == slotId and slot.definition and slot.imageRect then
            local displayStates = deps.warrules.getDisplayStates()

            return {
                kind = "topslot",
                sourceRect = {
                    x = slot.imageRect.x,
                    y = slot.imageRect.y,
                    width = slot.imageRect.width,
                    height = slot.imageRect.height,
                },
                slotId = slot.id,
                label = slot.nameText or slot.slotLabel or slot.id,
                image = slot.image,
                definition = slot.definition,
                accentColor = slot.accentColor,
                rollState = displayStates and displayStates[slot.id] or nil,
            }
        end
    end

    return nil
end

function hoverpreview.getHoveredJaclPreview(state, deps, mouseX, mouseY)
    local jaclLayout = deps.envdraw.getBottomLeftPanelLayout(state.playerJacl)

    if not jaclLayout then
        return nil
    end

    local insidePanel = mouseX >= jaclLayout.panelX
        and mouseX <= jaclLayout.panelX + jaclLayout.panelSize
        and mouseY >= jaclLayout.panelY
        and mouseY <= jaclLayout.panelY + jaclLayout.panelSize

    if not insidePanel then
        return nil
    end

    return {
        kind = "jacl",
        sourceRect = {
            x = jaclLayout.panelX,
            y = jaclLayout.panelY,
            width = jaclLayout.panelSize,
            height = jaclLayout.panelSize,
        },
        label = state.playerJacl and state.playerJacl.name or "JACL",
        image = deps.envdraw.getJaclArtImage(state.playerJacl),
    }
end

function hoverpreview.getHoverPreviewState(state, deps)
    if state.draggedCardIndex
        or state.primedSyntacAbility
        or state.fullArtImage
        or state.isJaclDeckModalOpen
        or state.isSyntacMethodModalOpen
        or state.isResourceExchangeModalOpen
        or love.keyboard.isDown("lshift")
        or love.keyboard.isDown("rshift") then
        return nil
    end

    local hoveredCardPreview = hoverpreview.getHoveredCardPreview(state, deps)

    if hoveredCardPreview then
        return hoveredCardPreview
    end

    local hoveredTopSlotPreview = hoverpreview.getHoveredTopSlotPreview(state, deps)

    if hoveredTopSlotPreview then
        return hoveredTopSlotPreview
    end

    local mouseX, mouseY = love.mouse.getPosition()
    return hoverpreview.getHoveredJaclPreview(state, deps, mouseX, mouseY)
end

function hoverpreview.updateSpawnPreview(state, deps, card, cardIndex)
    hoverpreview.clearSpawnPreview(state)

    local cardDefinition = card and deps.cardregistry.getCard(card.setName, card.cardId) or nil
    local isUnexpandedGridCard = card
        and card.location
        and card.location.kind == "grid"
        and cardIndex ~= state.expandedGridCardIndex

    if isUnexpandedGridCard then
        return
    end

    if deps.previewrules then
        local preview = deps.previewrules.getDefinitionPreview(cardDefinition)
    
        if preview then
            state.hoveredTomeSpawnPreviewCards = preview.cardDefinitions
            state.hoveredTomeSpawnPreviewCard = preview.cardDefinition
            state.hoveredTomeSpawnPreviewLabel = preview.label
            state.hoveredTomeSpawnPreviewCardIndex = cardIndex
            return
        end
    end
end

function hoverpreview.attachDefinitionPreview(deps, tooltip, fallbackLabel)
    if not tooltip then
        return nil
    end

    if deps.previewrules then
        deps.previewrules.applyDefinitionPreviewToTooltip(tooltip.definition or tooltip, tooltip, fallbackLabel)
    end

    if tooltip.previewCardDefinition and not tooltip.previewCardDefinitions then
        tooltip.previewCardDefinitions = { tooltip.previewCardDefinition }
    end

    if tooltip.previewCardDefinitions and not tooltip.previewCardDefinition then
        tooltip.previewCardDefinition = tooltip.previewCardDefinitions[1]
    end

    return tooltip
end

function hoverpreview.updateCardAbilityPreview(state, deps, mouseX, mouseY)
    hoverpreview.clearCardAbilityPreview(state)

    local hoveredMethodBadge = deps.getCardMethodBadgeTarget(mouseX, mouseY)

    if not hoveredMethodBadge then
        return
    end

    local abilityDefinition = deps.abilityrules.getCardMethodAbility(
        hoveredMethodBadge.cardIndex,
        hoveredMethodBadge.resource,
        deps.getModalDeps()
    )
    if not abilityDefinition then
        return
    end
    
    local preview = deps.previewrules
        and deps.previewrules.getDefinitionPreview(abilityDefinition, abilityDefinition.previewLabel or "CREATE")
        or nil
    
    if preview then
        state.hoveredCardAbilityPreviewCards = preview.cardDefinitions
        state.hoveredCardAbilityPreviewLabel = preview.label
    end
    
    state.hoveredCardAbilityPreviewDefinition = abilityDefinition
    state.hoveredCardAbilityPreviewCardIndex = hoveredMethodBadge.cardIndex
end

local function updateHoveredCardDetails(state, deps, card, cardIndex, drawX, drawY, expansionProgress, renderOptions, mouseX, mouseY)
    state.hoveredDiceFace = hoverpreview.attachDefinitionPreview(
        deps,
        deps.carddraw.getHoveredDiceFace(card.setName, card.cardId, drawX, drawY, expansionProgress, renderOptions, mouseX, mouseY, deps.warrules.getCardRollState(cardIndex)),
        "SUMMON"
    ) or state.hoveredDiceFace
    state.hoveredKeyword = deps.carddraw.getHoveredKeyword(card.setName, card.cardId, drawX, drawY, renderOptions, mouseX, mouseY)
    hoverpreview.updateCardAbilityPreview(state, deps, mouseX, mouseY)
    hoverpreview.updateSpawnPreview(state, deps, card, cardIndex)
end

function hoverpreview.updateHoveredCard(state, deps)
    local previousHoveredCardIndex = state.hoveredCardIndex
    state.hoveredKeyword = nil
    state.hoveredDiceFace = nil

    if state.draggedCardIndex or state.isResourceExchangeModalOpen or state.isSyntacMethodModalOpen or state.isJaclDeckModalOpen then
        state.hoveredCardIndex = nil
        state.hoveredTopSlotId = nil
        state.hoveredJaclSpecialDefinition = nil
        state.hoveredJaclSpecialPreviewCard = nil
        hoverpreview.clearSpawnPreview(state)
        hoverpreview.clearCardAbilityPreview(state)
        state.hoveredDiceFace = nil
        return
    end

    local mouseX, mouseY = love.mouse.getPosition()
    state.hoveredTopSlotId = deps.getHoveredTopSlotId(mouseX, mouseY)
    state.hoveredJaclSpecialDefinition = nil
    state.hoveredJaclSpecialPreviewCard = nil
    hoverpreview.clearSpawnPreview(state)
    hoverpreview.clearCardAbilityPreview(state)
    state.hoveredDiceFace = nil

    state.hoveredDiceFace = hoverpreview.attachDefinitionPreview(deps, deps.envdraw.getHoveredTopSlotDiceFace(
        mouseX,
        mouseY,
        deps.turnrules.getCurrentPhase(),
        state.activeChampion,
        state.activeWarzone,
        state.activePoi,
        state.activePrimaryObjective,
        state.activeIntel,
        deps.warrules.getDisplayStates(),
        state.expandedTopSlotId,
        state.topSlotExpansion[state.expandedTopSlotId] or 0
    ), "SUMMON")

    if state.hoveredCardIndex then
        local activeCard = state.cards[state.hoveredCardIndex]

        if activeCard and not activeCard.returningToHandAnimation and not deps.isCardUnavailable(activeCard) then
            local drawX, drawY, expansionProgress, renderOptions = deps.getCardDrawPosition(activeCard, state.hoveredCardIndex)

            if deps.carddraw.isPointInsideDrawnCard(mouseX, mouseY, drawX, drawY, expansionProgress, nil, renderOptions) then
                updateHoveredCardDetails(state, deps, activeCard, state.hoveredCardIndex, drawX, drawY, expansionProgress, renderOptions, mouseX, mouseY)
                return
            end
        end
    end

    state.hoveredCardIndex = nil

    for cardIndex = #state.cards, 1, -1 do
        if not state.cards[cardIndex].returningToHandAnimation and not deps.isCardUnavailable(state.cards[cardIndex]) then
            local drawX, drawY, expansionProgress, renderOptions = deps.getCardDrawPosition(state.cards[cardIndex], cardIndex)

            if deps.carddraw.isPointInsideDrawnCard(mouseX, mouseY, drawX, drawY, expansionProgress, nil, renderOptions) then
                state.hoveredCardIndex = cardIndex
                updateHoveredCardDetails(state, deps, state.cards[cardIndex], cardIndex, drawX, drawY, expansionProgress, renderOptions, mouseX, mouseY)
                break
            end
        end
    end

    if not state.hoveredCardIndex and state.expandedGridCardIndex then
        hoverpreview.updateSpawnPreview(
            state,
            deps,
            state.cards[state.expandedGridCardIndex],
            state.expandedGridCardIndex
        )
    end

    if state.hoveredCardIndex ~= nil
        and state.hoveredCardIndex ~= previousHoveredCardIndex
        and state.cards[state.hoveredCardIndex]
        and state.cards[state.hoveredCardIndex].location.kind == "hand" then
        deps.sfxrules.playHover()
    end

    if not state.hoveredKeyword and state.playerJacl then
        local hoveredMethodBadge = deps.envdraw.getJaclMethodBadgeAt(mouseX, mouseY, state.playerJacl)
    
        if hoveredMethodBadge then
            state.hoveredJaclSpecialDefinition = deps.abilityrules.getJaclMethodAbility(
                state.playerJacl,
                hoveredMethodBadge.resource,
                deps.getModalDeps()
            )
    
            local preview = deps.previewrules
                and deps.previewrules.getDefinitionPreview(state.hoveredJaclSpecialDefinition)
                or nil
    
            if preview then
                state.hoveredJaclSpecialPreviewCard = preview.cardDefinition
            end
        end
    end
end

return hoverpreview
