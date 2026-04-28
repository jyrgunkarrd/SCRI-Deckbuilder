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

function hoverpreview.updateSpawnPreview(state, deps, card, cardIndex, allowGridPreview)
    hoverpreview.clearSpawnPreview(state)

    local cardDefinition = card and deps.cardregistry.getCard(card.setName, card.cardId) or nil

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

    if deps.tomerules.isSpawnTomeDefinition(cardDefinition) then
        local targetCardId = deps.tomerules.getFirstTargetCardId(cardDefinition)
        local previewCardDefinition = targetCardId and deps.cardregistry.getCardById(targetCardId) or nil

        if previewCardDefinition then
            state.hoveredTomeSpawnPreviewCards = { previewCardDefinition }
            state.hoveredTomeSpawnPreviewCard = previewCardDefinition
            state.hoveredTomeSpawnPreviewLabel = "SUMMON"
            state.hoveredTomeSpawnPreviewCardIndex = cardIndex
        end
    elseif deps.strategyrules.isSpawnStrategyDefinition(cardDefinition) then
        local targetCardId = deps.strategyrules.getFirstTargetCardId(cardDefinition)
        local previewCardDefinition = targetCardId and deps.cardregistry.getCardById(targetCardId) or nil

        if previewCardDefinition then
            state.hoveredTomeSpawnPreviewCards = { previewCardDefinition }
            state.hoveredTomeSpawnPreviewCard = previewCardDefinition
            state.hoveredTomeSpawnPreviewLabel = "SUMMON"
            state.hoveredTomeSpawnPreviewCardIndex = cardIndex
        end
    elseif allowGridPreview or not (card.location and card.location.kind == "grid") then
        local previewCardIds, previewLabel = deps.trooprules.getPreviewCardIds(cardDefinition)

        if previewCardIds and #previewCardIds > 0 then
            local previewCardDefinitions = {}

            for _, previewCardId in ipairs(previewCardIds) do
                local previewCardDefinition = previewCardId and deps.cardregistry.getCardById(previewCardId) or nil

                if previewCardDefinition then
                    previewCardDefinitions[#previewCardDefinitions + 1] = previewCardDefinition
                end
            end

            if #previewCardDefinitions > 0 then
                state.hoveredTomeSpawnPreviewCards = previewCardDefinitions
                state.hoveredTomeSpawnPreviewCard = previewCardDefinitions[1]
                state.hoveredTomeSpawnPreviewLabel = previewLabel
                state.hoveredTomeSpawnPreviewCardIndex = cardIndex
            end
        end
    end
end

function hoverpreview.attachDiceFaceSummonPreview(deps, tooltip)
    if not tooltip then
        return nil
    end

    if deps.previewrules then
        deps.previewrules.applyDefinitionPreviewToTooltip(tooltip.definition or tooltip, tooltip, "SUMMON")
    end

    -- Legacy fallback: keep old dice previews working while definitions migrate.
    if not tooltip.previewCardDefinition and tooltip.summonCardId then
        tooltip.previewCardDefinition = deps.cardregistry.getCardById(tooltip.summonCardId)
    end

    if not tooltip.previewCardDefinitions and tooltip.summonCardIds then
        tooltip.previewCardDefinitions = {}

        for _, summonCardId in ipairs(tooltip.summonCardIds) do
            local previewCardDefinition = deps.cardregistry.getCardById(summonCardId)

            if previewCardDefinition then
                tooltip.previewCardDefinitions[#tooltip.previewCardDefinitions + 1] = previewCardDefinition
            end
        end
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
    
    local previewCardDefinition = nil
    
    if preview then
        state.hoveredCardAbilityPreviewCards = preview.cardDefinitions
        state.hoveredCardAbilityPreviewLabel = preview.label
    else
        -- Legacy fallback: keep existing pilot/transform previews working.
        local effectArgs = abilityDefinition.effectArgs or nil
        local previewCardId = nil
    
        if abilityDefinition.effect == "pilot_vehicle_card" then
            previewCardId = effectArgs and effectArgs.vehicleCardId or nil
        elseif abilityDefinition.effect == "transform_card" then
            previewCardId = effectArgs and effectArgs.targetCardId or nil
        end
    
        previewCardDefinition = previewCardId and deps.cardregistry.getCardById(previewCardId) or nil
        state.hoveredCardAbilityPreviewCards = previewCardDefinition and { previewCardDefinition } or nil
        state.hoveredCardAbilityPreviewLabel = abilityDefinition.previewLabel or "CREATE"
    end
    
    state.hoveredCardAbilityPreviewDefinition = abilityDefinition
    state.hoveredCardAbilityPreviewCardIndex = hoveredMethodBadge.cardIndex
end

local function updateHoveredCardDetails(state, deps, card, cardIndex, drawX, drawY, expansionProgress, renderOptions, mouseX, mouseY)
    state.hoveredDiceFace = hoverpreview.attachDiceFaceSummonPreview(
        deps,
        deps.carddraw.getHoveredDiceFace(card.setName, card.cardId, drawX, drawY, expansionProgress, renderOptions, mouseX, mouseY, deps.warrules.getCardRollState(cardIndex))
    ) or state.hoveredDiceFace
    state.hoveredKeyword = deps.carddraw.getHoveredKeyword(card.setName, card.cardId, drawX, drawY, renderOptions, mouseX, mouseY)
    hoverpreview.updateCardAbilityPreview(state, deps, mouseX, mouseY)
    hoverpreview.updateSpawnPreview(state, deps, card, cardIndex, cardIndex == state.expandedGridCardIndex)
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

    state.hoveredDiceFace = hoverpreview.attachDiceFaceSummonPreview(deps, deps.envdraw.getHoveredTopSlotDiceFace(
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
    ))

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
            state.expandedGridCardIndex,
            true
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
            else
                -- Legacy fallback: keep old JACL previews working.
                local effectArgs = state.hoveredJaclSpecialDefinition
                    and state.hoveredJaclSpecialDefinition.effectArgs
                    or nil
    
                if effectArgs and effectArgs.cardId then
                    state.hoveredJaclSpecialPreviewCard = deps.cardregistry.getCardById(effectArgs.cardId)
                end
            end
        end
    end
end

return hoverpreview
