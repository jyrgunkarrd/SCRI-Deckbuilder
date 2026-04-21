local gamestatedraw = {}

function gamestatedraw.draw(ctx)
    local currentPhase = ctx.turnrules.getCurrentPhase()
    local drawTopStripOnTop = ctx.expandedTopSlotId ~= nil
    local warRollDisplayStates = ctx.warrules.getDisplayStates()
    local warzonePreviewState = ctx.warrules.getWarzoneControlPreview(
        ctx.activeWarzone and ctx.activeWarzone.id or nil,
        ctx.activeWarzone and ctx.activeWarzone.control or nil,
        ctx.activeWarzone and ctx.activeWarzone.max or nil,
        ctx.isWarRollSourceActive
    )
    local objectivePreviewPips = ctx.warrules.getObjectiveProgressPreview(
        ctx.activePrimaryObjective and ctx.activePrimaryObjective.id or nil,
        ctx.isWarRollSourceActive
    )
    local intelPreviewPips = ctx.warrules.getIntelProgressPreview(
        ctx.activeIntel and ctx.activeIntel.id or nil,
        ctx.isWarRollSourceActive
    )
    local championJitterOffsetX, championJitterOffsetY = ctx.getDamageJitterOffset("champion")
    local warzoneJitterOffsetX, warzoneJitterOffsetY = ctx.getDamageJitterOffset("warzone")
    local objectiveJitterOffsetX, objectiveJitterOffsetY = ctx.getObjectiveProgressJitterOffset()
    local objectiveProgressEffectSlotId = ctx.getObjectiveProgressEffectSlotId()
    local topSlotEffectRenderStates = ctx.topsloteffects.getRenderStates()
    local topSlotJitterOffsets = {
        champion = {
            x = championJitterOffsetX,
            y = championJitterOffsetY,
        },
        warzone = {
            x = warzoneJitterOffsetX,
            y = warzoneJitterOffsetY,
        },
    }

    if objectiveProgressEffectSlotId then
        topSlotJitterOffsets[objectiveProgressEffectSlotId] = {
            x = objectiveJitterOffsetX,
            y = objectiveJitterOffsetY,
        }
    end

    local topSlotDestructionStates = topSlotEffectRenderStates.destructionStates
    local objectiveProgressEffectProgress = topSlotEffectRenderStates.objectiveProgressProgress
    local objectiveProgressOverlayName = topSlotEffectRenderStates.objectiveProgressOverlayName
    local objectiveEscalationRenderState = topSlotEffectRenderStates.objectiveEscalation
    local warzoneTransformationRenderState = topSlotEffectRenderStates.warzoneTransformation
    local poiEmergenceRenderState = topSlotEffectRenderStates.poiEmergence
    local poiFlipRenderState = topSlotEffectRenderStates.poiFlip
    local poiHunterTransformationRenderState = topSlotEffectRenderStates.poiHunterTransformation

    ctx.envdraw.drawPhaseTracker(currentPhase)
    ctx.envdraw.drawResourceTracker(ctx.resourcerules.getResourceCounts())
    ctx.envdraw.drawGrid(currentPhase)

    if not drawTopStripOnTop then
        ctx.envdraw.drawChampion(
            ctx.activeChampion,
            currentPhase,
            ctx.activeWarzone,
            ctx.activePoi,
            ctx.activePrimaryObjective,
            ctx.activeIntel,
            ctx.expandedTopSlotId,
            ctx.topSlotExpansion[ctx.expandedTopSlotId] or 0,
            warRollDisplayStates,
            topSlotJitterOffsets,
            topSlotDestructionStates,
            warzonePreviewState,
            objectivePreviewPips,
            intelPreviewPips,
            objectiveProgressEffectProgress,
            objectiveProgressOverlayName,
            objectiveProgressEffectSlotId,
            objectiveEscalationRenderState,
            warzoneTransformationRenderState,
            poiEmergenceRenderState,
            poiFlipRenderState,
            poiHunterTransformationRenderState
        )
    end

    if currentPhase == "War" and ctx.turnrules.getCurrentWarSubphase() == "Engage" then
        ctx.envdraw.drawRerollButton(ctx.playerJacl, ctx.engageRerollCount, ctx.engageRerollCount > 0)
    end

    ctx.envdraw.drawSyntacBox(ctx.playerJacl, ctx.syntacCount)
    ctx.envdraw.drawBottomLeftPanel(ctx.playerJacl, ctx.resourcerules.getResourceCounts())
    ctx.envdraw.drawPlayerHand()

    if currentPhase == ctx.turnrules.getSetupPhase() and ctx.getSetupCardCount() > 0 then
        ctx.envdraw.drawSetupModal(ctx.getSetupCardCount())
    end

    for cardIndex, card in ipairs(ctx.cards) do
        if not ctx.isCardDestroyed(card)
            and not card.returningToHandAnimation
            and cardIndex ~= ctx.hoveredCardIndex
            and cardIndex ~= ctx.draggedCardIndex
            and cardIndex ~= ctx.expandedGridCardIndex then
            local drawX, drawY, expansionProgress, renderOptions = ctx.getCardDrawPosition(card, cardIndex)
            ctx.carddraw.drawCardState(card.setName, card.cardId, drawX, drawY, expansionProgress, renderOptions)
            ctx.drawCardStateOverlays(card, cardIndex, drawX, drawY, expansionProgress, renderOptions)
        end
    end

    if ctx.hoveredCardIndex
        and ctx.hoveredCardIndex ~= ctx.expandedGridCardIndex
        and not ctx.cards[ctx.hoveredCardIndex].returningToHandAnimation
        and not ctx.isCardDestroyed(ctx.cards[ctx.hoveredCardIndex]) then
        local hoveredCard = ctx.cards[ctx.hoveredCardIndex]
        local drawX, drawY, expansionProgress, renderOptions = ctx.getCardDrawPosition(hoveredCard, ctx.hoveredCardIndex)
        ctx.carddraw.drawCardState(hoveredCard.setName, hoveredCard.cardId, drawX, drawY, expansionProgress, renderOptions)
        ctx.drawCardStateOverlays(hoveredCard, ctx.hoveredCardIndex, drawX, drawY, expansionProgress, renderOptions)
    end

    if ctx.expandedGridCardIndex
        and ctx.expandedGridCardIndex ~= ctx.draggedCardIndex
        and not ctx.cards[ctx.expandedGridCardIndex].returningToHandAnimation
        and not ctx.isCardDestroyed(ctx.cards[ctx.expandedGridCardIndex]) then
        local expandedCard = ctx.cards[ctx.expandedGridCardIndex]

        if expandedCard then
            local drawX, drawY, expansionProgress, renderOptions = ctx.getCardDrawPosition(expandedCard, ctx.expandedGridCardIndex)
            ctx.carddraw.drawCardState(expandedCard.setName, expandedCard.cardId, drawX, drawY, expansionProgress, renderOptions)
            ctx.drawCardStateOverlays(expandedCard, ctx.expandedGridCardIndex, drawX, drawY, expansionProgress, renderOptions)
        end
    end

    if ctx.draggedCardIndex then
        local draggedCard = ctx.cards[ctx.draggedCardIndex]
        local mouseX, mouseY = love.mouse.getPosition()
        local dropCell = ctx.getDropCell(mouseX, mouseY)
        local drawX, drawY = ctx.getCardDrawPosition(draggedCard, ctx.draggedCardIndex)

        if dropCell then
            ctx.carddraw.drawPortraitPreview(draggedCard.setName, draggedCard.cardId, dropCell.x, dropCell.y, dropCell.width, dropCell.height, 0.45, {
                portraitPath = draggedCard.portraitPath,
            })
        end

        ctx.carddraw.drawCardState(
            draggedCard.setName,
            draggedCard.cardId,
            drawX,
            drawY,
            0,
            ctx.getCardRenderOptions(draggedCard, ctx.draggedCardIndex)
        )
    end

    if ctx.drawKitReturnAnimations then
        ctx.drawKitReturnAnimations()
    end

    if drawTopStripOnTop then
        ctx.envdraw.drawChampion(
            ctx.activeChampion,
            currentPhase,
            ctx.activeWarzone,
            ctx.activePoi,
            ctx.activePrimaryObjective,
            ctx.activeIntel,
            ctx.expandedTopSlotId,
            ctx.topSlotExpansion[ctx.expandedTopSlotId] or 0,
            warRollDisplayStates,
            topSlotJitterOffsets,
            topSlotDestructionStates,
            warzonePreviewState,
            objectivePreviewPips,
            intelPreviewPips,
            objectiveProgressEffectProgress,
            objectiveProgressOverlayName,
            objectiveProgressEffectSlotId,
            objectiveEscalationRenderState,
            warzoneTransformationRenderState,
            poiEmergenceRenderState,
            poiFlipRenderState,
            poiHunterTransformationRenderState
        )
    end

    ctx.drawTopSlotHoverTargetBrackets(currentPhase, warzonePreviewState, objectivePreviewPips, intelPreviewPips)
    ctx.drawInfiltrationEffect()

    if poiHunterTransformationRenderState
        and poiHunterTransformationRenderState.targetLocation
        and poiHunterTransformationRenderState.targetLocation.kind == "hand" then
        ctx.envdraw.drawPoiHunterTransformationOverlay(
            currentPhase,
            ctx.activeChampion,
            ctx.activeWarzone,
            ctx.activePoi,
            ctx.activePrimaryObjective,
            ctx.activeIntel,
            poiHunterTransformationRenderState,
            topSlotJitterOffsets
        )
    end

    ctx.envdraw.drawResourceTransfers(ctx.resourcerules.getActiveTransfers())

    if ctx.isJaclDeckModalOpen then
        ctx.envdraw.drawJaclDeckModal(ctx.activeDeckModalDeck, {
            top = { scrollY = ctx.jaclDeckModalScroll.deck },
            bottom = { scrollY = ctx.jaclDeckModalScroll.discard },
        })

        if ctx.jaclDeckPreviewCard then
            ctx.envdraw.drawJaclDeckPreviewModal(ctx.jaclDeckPreviewCard)
        end
    elseif ctx.isResourceExchangeModalOpen then
        ctx.envdraw.drawResourceExchangeModal(ctx.resourcerules.getResourceCounts())
    elseif ctx.hoveredDiceFace then
        ctx.carddraw.drawDiceFaceTooltip(ctx.hoveredDiceFace)

        if ctx.hoveredDiceFace.previewCardDefinitions and #ctx.hoveredDiceFace.previewCardDefinitions > 0 then
            ctx.envdraw.drawSummonPreviewTooltip(
                ctx.hoveredDiceFace.previewCardDefinitions,
                ctx.hoveredDiceFace.cardX,
                ctx.hoveredDiceFace.cardY,
                ctx.hoveredDiceFace.cardWidth,
                ctx.hoveredDiceFace.cardHeight
            )
        elseif ctx.hoveredDiceFace.previewCardDefinition then
            ctx.envdraw.drawTomeSpawnTooltip(
                ctx.hoveredDiceFace.previewCardDefinition,
                ctx.hoveredDiceFace.cardX,
                ctx.hoveredDiceFace.cardY,
                ctx.hoveredDiceFace.cardWidth,
                ctx.hoveredDiceFace.cardHeight
            )
        end
    elseif ctx.hoveredTomeSpawnPreviewCard then
        local hoveredCard = ctx.hoveredCardIndex and ctx.cards[ctx.hoveredCardIndex] or nil

        if hoveredCard then
            local drawX, drawY, expansionProgress, renderOptions = ctx.getCardDrawPosition(hoveredCard, ctx.hoveredCardIndex)
            local cardWidth, collapsedHeight = ctx.carddraw.getCardSize(renderOptions)
            local _, expandedHeight = ctx.carddraw.getExpandedCardSize(renderOptions)
            local cardHeight = collapsedHeight + ((expandedHeight - collapsedHeight) * (expansionProgress or 0))

            ctx.envdraw.drawTomeSpawnTooltip(ctx.hoveredTomeSpawnPreviewCard, drawX, drawY, cardWidth, cardHeight)
        end
    elseif ctx.hoveredKeyword and ctx.hoveredKeyword.previewCardDefinition then
        local hoveredCard = ctx.hoveredCardIndex and ctx.cards[ctx.hoveredCardIndex] or nil

        if hoveredCard then
            local drawX, drawY, expansionProgress, renderOptions = ctx.getCardDrawPosition(hoveredCard, ctx.hoveredCardIndex)
            local cardWidth, collapsedHeight = ctx.carddraw.getCardSize(renderOptions)
            local _, expandedHeight = ctx.carddraw.getExpandedCardSize(renderOptions)
            local cardHeight = collapsedHeight + ((expandedHeight - collapsedHeight) * (expansionProgress or 0))

            ctx.envdraw.drawSummonPreviewTooltip(
                { ctx.hoveredKeyword.previewCardDefinition },
                drawX,
                drawY,
                cardWidth,
                cardHeight,
                ctx.hoveredKeyword.previewLabel or "KIT"
            )
        end
    elseif ctx.hoveredKeyword then
        local mouseX, mouseY = love.mouse.getPosition()
        ctx.carddraw.drawKeywordTooltip(ctx.hoveredKeyword, mouseX, mouseY)
    elseif ctx.hoveredJaclSpecialDefinition then
        local jaclLayout = ctx.envdraw.getBottomLeftPanelLayout(ctx.playerJacl)
        ctx.envdraw.drawJaclSpecialTooltip(
            ctx.hoveredJaclSpecialDefinition,
            ctx.hoveredJaclSpecialPreviewCard,
            jaclLayout.panelX,
            jaclLayout.panelY,
            jaclLayout.panelSize,
            jaclLayout.panelSize
        )
    end

    if ctx.primedJaclSpecial and ctx.primedJaclSpecial.resourceName then
        local mouseX, mouseY = love.mouse.getPosition()
        ctx.envdraw.drawFloatingMethodBadge(ctx.primedJaclSpecial.resourceName, mouseX + 16, mouseY + 16)
    end

    if ctx.fullArtImage then
        ctx.envdraw.drawFullArtOverlay(ctx.fullArtImage)
    end

    ctx.notifications.draw()
end

return gamestatedraw
