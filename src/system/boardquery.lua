local engagerules = require("src.system.engagerules")

local boardquery = {}

function boardquery.getHoveredTopSlotId(ctx, mouseX, mouseY)
    local state = ctx.state

    return ctx.envdraw.getTopSlotHit(
        mouseX,
        mouseY,
        ctx.turnrules.getCurrentPhase(),
        state.activeChampion,
        state.activeWarzone,
        state.activePoi,
        state.activePrimaryObjective,
        state.activeIntel
    )
end

function boardquery.getGridCardAt(ctx, mouseX, mouseY, ignoredCardIndex)
    for cardIndex = #ctx.state.cards, 1, -1 do
        local card = ctx.state.cards[cardIndex]

        if cardIndex ~= ignoredCardIndex
            and not ctx.isCardUnavailable(card)
            and card.location
            and card.location.kind == "grid" then
            local drawX, drawY, expansionProgress, renderOptions = ctx.getCardDrawPosition(card, cardIndex)

            if ctx.carddraw.isPointInsideDrawnCard(mouseX, mouseY, drawX, drawY, expansionProgress, nil, renderOptions) then
                return cardIndex
            end
        end
    end

    return nil
end

function boardquery.getCardAt(ctx, mouseX, mouseY, ignoredCardIndex)
    for cardIndex = #ctx.state.cards, 1, -1 do
        local card = ctx.state.cards[cardIndex]

        if cardIndex ~= ignoredCardIndex and not ctx.isCardUnavailable(card) then
            local drawX, drawY, expansionProgress, renderOptions = ctx.getCardDrawPosition(card, cardIndex)

            if ctx.carddraw.isPointInsideDrawnCard(mouseX, mouseY, drawX, drawY, expansionProgress, nil, renderOptions) then
                return cardIndex
            end
        end
    end

    return nil
end

function boardquery.getFullArtAt(ctx, mouseX, mouseY)
    local cardIndex = boardquery.getCardAt(ctx, mouseX, mouseY)

    if cardIndex then
        local card = ctx.state.cards[cardIndex]

        return ctx.carddraw.getPortraitImage(card.setName, card.cardId, {
            portraitPath = card.portraitPath,
        })
    end

    if ctx.isPointInsideJaclPortrait(mouseX, mouseY) then
        return ctx.envdraw.getJaclArtImage(ctx.state.playerJacl)
    end

    local topSlotId = boardquery.getHoveredTopSlotId(ctx, mouseX, mouseY)

    if topSlotId then
        local state = ctx.state

        return ctx.envdraw.getTopSlotArtImage(
            topSlotId,
            state.activeChampion,
            state.activeWarzone,
            state.activePoi,
            state.activePrimaryObjective,
            state.activeIntel
        )
    end

    return nil
end

function boardquery.isGridRowColumnOccupied(ctx, rowId, column, ignoredCardIndex)
    return ctx.cardzones.isGridRowColumnOccupied(ctx.state.cards, rowId, column, ignoredCardIndex)
end

function boardquery.getEntitySourceRect(ctx, entityKey)
    return ctx.cardpresentation.getEntitySourceRect(entityKey, ctx.getCardPresentationContext())
end

function boardquery.getValidDropColumn(ctx, mouseX, mouseY, ignoredCardIndex, draggedCard)
    return ctx.cardzones.getValidDropColumn(mouseX, mouseY, ctx.state.cards, ignoredCardIndex, draggedCard, {
        getPlayerRow = ctx.getPlayerRow,
        getOppRow = ctx.getOppRow,
        isHunterCard = ctx.isHunterCard,
    })
end

function boardquery.getDropCell(ctx, mouseX, mouseY)
    return ctx.cardzones.getDropCell(mouseX, mouseY, ctx.state.cards, ctx.state.draggedCardIndex, {
        getPlayerRow = ctx.getPlayerRow,
        getOppRow = ctx.getOppRow,
        isHunterCard = ctx.isHunterCard,
    })
end

function boardquery.getPlayerRowCellAt(ctx, mouseX, mouseY)
    return ctx.cardzones.getCellAt(ctx.getPlayerRow(), mouseX, mouseY)
end

function boardquery.getValidJaclSpecialTargetCell(ctx, mouseX, mouseY)
    return ctx.cardzones.getValidJaclSpecialTargetCell(mouseX, mouseY, ctx.state.cards, {
        getPlayerRow = ctx.getPlayerRow,
    })
end

function boardquery.getCardMethodBadgeTarget(ctx, mouseX, mouseY)
    local cardIndex = boardquery.getGridCardAt(ctx, mouseX, mouseY)
    local card = cardIndex and ctx.state.cards[cardIndex] or nil

    if not card
        or not card.location
        or card.location.kind ~= "grid"
        or card.location.rowId ~= "PlayerRow" then
        return nil
    end

    local drawX, drawY, expansionProgress, renderOptions = ctx.getCardDrawPosition(card, cardIndex)
    local badgeRects = ctx.carddraw.getMethodBadgeRects(
        card.setName,
        card.cardId,
        drawX,
        drawY,
        expansionProgress,
        renderOptions
    )

    for _, badgeRect in ipairs(badgeRects or {}) do
        if mouseX >= badgeRect.x
            and mouseX <= badgeRect.x + badgeRect.width
            and mouseY >= badgeRect.y
            and mouseY <= badgeRect.y + badgeRect.height then
            return {
                cardIndex = cardIndex,
                resource = badgeRect.resource,
            }
        end
    end

    return nil
end

function boardquery.getHoveredPlayerRollBadgeCardIndex(mouseX, mouseY, engageContext)
    return engagerules.getHoveredPlayerRollBadgeCardIndex(mouseX, mouseY, engageContext)
end

function boardquery.getHoveredTopSlotRollBadgeId(ctx, mouseX, mouseY)
    local state = ctx.state

    return ctx.envdraw.getTopSlotRollBadgeHit(
        mouseX,
        mouseY,
        ctx.turnrules.getCurrentPhase(),
        state.activeChampion,
        state.activeWarzone,
        state.activePoi,
        state.activePrimaryObjective,
        state.activeIntel,
        ctx.warrules.getDisplayStates()
    )
end

return boardquery
