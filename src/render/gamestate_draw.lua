local gamestatedraw = {}

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function easeOutCubic(t)
    t = clamp(t or 0, 0, 1)
    local invT = 1 - t

    return 1 - (invT * invT * invT)
end

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

    if currentPhase == "Prelude" and ctx.getRetaliationPhaseObjectiveProgress then
        objectivePreviewPips = objectivePreviewPips + math.max(0, tonumber(ctx.getRetaliationPhaseObjectiveProgress()) or 0)
    end

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

    ctx.envdraw.drawSyntacBox(ctx.playerJacl, ctx.syntacCount, ctx.syntacRewardButtons)
    ctx.envdraw.drawBottomLeftPanel(ctx.playerJacl, ctx.resourcerules.getResourceCounts())
    ctx.envdraw.drawPlayerHand()

    if currentPhase == ctx.turnrules.getSetupPhase() and ctx.getSetupCardCount() > 0 then
        ctx.envdraw.drawSetupModal(ctx.getSetupCardCount())
    end

    for cardIndex, card in ipairs(ctx.cards) do
        if not ctx.isCardDestroyed(card)
            and not card.returningToHandAnimation
            and not card.mulliganInAnimation
            and not card.mulliganOutAnimation
            and not card.pilotVehicleAnimation
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
        and not ctx.cards[ctx.hoveredCardIndex].pilotVehicleAnimation
        and not ctx.isCardDestroyed(ctx.cards[ctx.hoveredCardIndex]) then
        local hoveredCard = ctx.cards[ctx.hoveredCardIndex]
        local drawX, drawY, expansionProgress, renderOptions = ctx.getCardDrawPosition(hoveredCard, ctx.hoveredCardIndex)
        ctx.carddraw.drawCardState(hoveredCard.setName, hoveredCard.cardId, drawX, drawY, expansionProgress, renderOptions)
        ctx.drawCardStateOverlays(hoveredCard, ctx.hoveredCardIndex, drawX, drawY, expansionProgress, renderOptions)
    end

    if ctx.expandedGridCardIndex
        and ctx.expandedGridCardIndex ~= ctx.draggedCardIndex
        and not ctx.cards[ctx.expandedGridCardIndex].returningToHandAnimation
        and not ctx.cards[ctx.expandedGridCardIndex].pilotVehicleAnimation
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

    if ctx.drawPilotVehicleAnimations then
        ctx.drawPilotVehicleAnimations()
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

    if ctx.mulliganActive then
        local mulliganAlpha = clamp(ctx.mulliganPromptAlpha or 1, 0, 1)

        love.graphics.setColor(0, 0, 0, 0.62 * mulliganAlpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

        for cardIndex, card in ipairs(ctx.cards) do
            if card
                and card.location
                and card.location.kind == "hand"
                and not ctx.isCardDestroyed(card)
                and not card.returningToHandAnimation then
                local drawX, drawY, expansionProgress, renderOptions = ctx.getCardDrawPosition(card, cardIndex)
                local isTomeCard = ctx.isTomeCard and ctx.isTomeCard(card) or false
                local animation = card.mulliganInAnimation or card.mulliganOutAnimation
                local animationProgress = animation and easeOutCubic((animation.elapsed or 0) / animation.duration) or 1
                local animationOffset = animation and (animation.offset or 0) or 0
                local yOffset = 0
                local coverAlpha = 0

                renderOptions.dimmed = isTomeCard
                renderOptions.selected = ctx.mulliganSelection
                    and ctx.mulliganSelection[cardIndex] == true
                    or false

                if card.mulliganInAnimation then
                    yOffset = animationOffset * (1 - animationProgress)
                    coverAlpha = 0.68 * (1 - animationProgress)
                elseif card.mulliganOutAnimation then
                    yOffset = animationOffset * animationProgress
                    coverAlpha = 0.72 * animationProgress
                    renderOptions.selected = true
                end

                drawY = drawY + yOffset

                ctx.carddraw.drawCardState(card.setName, card.cardId, drawX, drawY, expansionProgress, renderOptions)
                ctx.drawCardStateOverlays(card, cardIndex, drawX, drawY, expansionProgress, renderOptions)

                if coverAlpha > 0 then
                    local cardWidth, collapsedHeight = ctx.carddraw.getCardSize(renderOptions)
                    local _, expandedHeight = ctx.carddraw.getExpandedCardSize(renderOptions)
                    local cardHeight = collapsedHeight + ((expandedHeight - collapsedHeight) * (expansionProgress or 0))

                    love.graphics.setColor(0.01, 0.012, 0.016, coverAlpha)
                    love.graphics.rectangle("fill", drawX, drawY, cardWidth, cardHeight, 8, 8)
                    love.graphics.setColor(1, 1, 1, 1)
                end
            end
        end

        if mulliganAlpha > 0.01 then
            ctx.envdraw.drawMulliganPrompt(mulliganAlpha)
        end
    end

    local mouseX, mouseY = love.mouse.getPosition()
    local syntacHovered = not ctx.primedSyntacAbility
        and ctx.envdraw.isPointInsideSyntacBox(mouseX, mouseY, ctx.playerJacl)

    if ctx.mulliganActive then
        -- Mulligan owns input and hover UI until DONE is clicked.
    elseif ctx.isJaclDeckModalOpen then
        ctx.envdraw.drawJaclDeckModal(ctx.activeDeckModalDeck, {
            top = { scrollY = ctx.jaclDeckModalScroll.deck },
            bottom = { scrollY = ctx.jaclDeckModalScroll.discard },
        })

        if ctx.jaclDeckPreviewCard then
            local previewCardDefinition = ctx.cardregistry
                and ctx.cardregistry.getCard(ctx.jaclDeckPreviewCard.setName, ctx.jaclDeckPreviewCard.cardId)
                or nil
            local preview = ctx.previewrules
                and ctx.previewrules.getDefinitionPreview(previewCardDefinition)
                or nil

            ctx.envdraw.drawJaclDeckPreviewModal(ctx.jaclDeckPreviewCard, preview)
        end
    elseif ctx.isSyntacMethodModalOpen then
        ctx.envdraw.drawSyntacMethodModal()
    elseif ctx.isResourceExchangeModalOpen then
        ctx.envdraw.drawResourceExchangeModal(ctx.resourcerules.getResourceCounts())
    elseif syntacHovered then
        ctx.envdraw.drawSyntacTooltip(ctx.playerJacl)
    elseif ctx.hoveredDiceFace then
        ctx.carddraw.drawDiceFaceTooltip(ctx.hoveredDiceFace)

        local previewCards = ctx.hoveredDiceFace.previewCardDefinitionEntries or ctx.hoveredDiceFace.previewCardDefinitions

        if previewCards and #previewCards > 0 then
            ctx.envdraw.drawSummonPreviewTooltip(
                previewCards,
                ctx.hoveredDiceFace.cardX,
                ctx.hoveredDiceFace.cardY,
                ctx.hoveredDiceFace.cardWidth,
                ctx.hoveredDiceFace.cardHeight,
                ctx.hoveredDiceFace.previewLabel
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
    elseif (ctx.hoveredTomeSpawnPreviewCardEntries and #ctx.hoveredTomeSpawnPreviewCardEntries > 0)
        or (ctx.hoveredTomeSpawnPreviewCards and #ctx.hoveredTomeSpawnPreviewCards > 0) then
        local sourceCardIndex = ctx.hoveredTomeSpawnPreviewCardIndex or ctx.hoveredCardIndex
        local hoveredCard = sourceCardIndex and ctx.cards[sourceCardIndex] or nil

        if hoveredCard then
            local drawX, drawY, expansionProgress, renderOptions = ctx.getCardDrawPosition(hoveredCard, sourceCardIndex)
            local cardWidth, collapsedHeight = ctx.carddraw.getCardSize(renderOptions)
            local _, expandedHeight = ctx.carddraw.getExpandedCardSize(renderOptions)
            local cardHeight = collapsedHeight + ((expandedHeight - collapsedHeight) * (expansionProgress or 0))

            ctx.envdraw.drawSummonPreviewTooltip(
                ctx.hoveredTomeSpawnPreviewCardEntries or ctx.hoveredTomeSpawnPreviewCards,
                drawX,
                drawY,
                cardWidth,
                cardHeight,
                ctx.hoveredTomeSpawnPreviewLabel or "SUMMON"
            )
        end
    elseif ctx.hoveredCardAbilityPreviewDefinition then
        local sourceCardIndex = ctx.hoveredCardAbilityPreviewCardIndex or ctx.hoveredCardIndex
        local sourceCard = sourceCardIndex and ctx.cards[sourceCardIndex] or nil

        if sourceCard then
            local drawX, drawY, expansionProgress, renderOptions = ctx.getCardDrawPosition(sourceCard, sourceCardIndex)
            local cardWidth, collapsedHeight = ctx.carddraw.getCardSize(renderOptions)
            local _, expandedHeight = ctx.carddraw.getExpandedCardSize(renderOptions)
            local cardHeight = collapsedHeight + ((expandedHeight - collapsedHeight) * (expansionProgress or 0))

            ctx.envdraw.drawJaclSpecialTooltip(
                ctx.hoveredCardAbilityPreviewDefinition,
                ctx.hoveredCardAbilityPreviewCardEntries or ctx.hoveredCardAbilityPreviewCards,
                drawX,
                drawY,
                cardWidth,
                cardHeight
            )
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

    if ctx.hoverPreview and not ctx.mulliganActive and not syntacHovered then
        ctx.envdraw.drawHoverPreview(ctx.hoverPreview, ctx.drawCardStateOverlays)
    end

    if ctx.primedActivatedAbility and ctx.primedActivatedAbility.resourceName and not ctx.mulliganActive then
        local mouseX, mouseY = love.mouse.getPosition()
        ctx.envdraw.drawFloatingMethodBadge(ctx.primedActivatedAbility.resourceName, mouseX + 16, mouseY + 16)
    end

    if ctx.primedSyntacAbility and not ctx.mulliganActive then
        local mouseX, mouseY = love.mouse.getPosition()
        ctx.envdraw.drawSyntacCursorIndicator(mouseX, mouseY)
    end

    if ctx.fullArtImage then
        ctx.envdraw.drawFullArtOverlay(ctx.fullArtImage)
    end

    ctx.notifications.draw(ctx.pendingSelectionPrompt)
end

return gamestatedraw
