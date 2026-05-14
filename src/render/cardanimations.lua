local carddraw = require("src.render.carddraw")
local cardinstances = require("src.system.cardinstances")
local deckrules = require("src.system.deckrules")
local keywordrules = require("src.system.keywordrules")

local cardanimations = {}

local function copyRenderOptions(renderOptions)
    local copiedOptions = {}

    for key, value in pairs(renderOptions or {}) do
        copiedOptions[key] = value
    end

    return copiedOptions
end

local function createPilotAttachment(card)
    if not card then
        return nil
    end

    return {
        instanceId = card.instanceId,
        setName = card.setName,
        cardId = card.cardId,
        deckOwner = card.deckOwner,
        displayName = card.displayName,
        portraitPath = card.portraitPath,
        currentHealth = card.currentHealth,
        maxHealth = card.maxHealth,
        keywordValues = card.keywordValues,
        attachedKitCards = card.attachedKitCards,
    }
end

local function finishPilotVehicleAnimation(ctx, animation)
    if not ctx or not animation or not animation.vehicleCard then
        return false
    end

    local cardIndex = animation.cardIndex
    local currentCard = cardIndex and ctx.cards[cardIndex] or nil

    if not currentCard or currentCard ~= animation.sourceCard then
        return false
    end

    currentCard.pilotVehicleAnimation = nil
    ctx.cards[cardIndex] = animation.vehicleCard
    ctx.warrules.clearCardRollState(cardIndex)
    return true
end

function cardanimations.pilotCardWithVehicleAtIndex(ctx, cardIndex, vehicleDefinition)
    local card = cardIndex and ctx.cards[cardIndex] or nil

    if not card or not vehicleDefinition or card.attachedPilotCard then
        return false
    end

    local cardDefinition = ctx.cardregistry.getCard(card.setName, card.cardId)

    if keywordrules.cardHasKeyword(cardDefinition, "KWPILOT", card) then
        return false
    end

    local vehicleCard = cardinstances.createGenerated(
        vehicleDefinition,
        ctx.copyLocation(card.location)
    )

    if not vehicleCard then
        return false
    end

    vehicleCard.deckOwner = card.deckOwner
    vehicleCard.attachedPilotCard = createPilotAttachment(card)
    vehicleCard.keywordValues = vehicleCard.keywordValues or {}
    vehicleCard.keywordValues.KWPILOT = 1
    cardinstances.initializeHealth(vehicleCard)

    local drawX, drawY, expansionProgress, renderOptions = ctx.getCardDrawPosition(card, cardIndex)
    local cardWidth, collapsedHeight = carddraw.getCardSize(renderOptions)
    local _, expandedHeight = carddraw.getExpandedCardSize(renderOptions)
    local cardHeight = collapsedHeight + ((expandedHeight - collapsedHeight) * (expansionProgress or 0))
    local vehicleRenderOptions = copyRenderOptions(renderOptions)
    vehicleRenderOptions.card = vehicleCard
    vehicleRenderOptions.currentHealth = vehicleCard.currentHealth
    vehicleRenderOptions.maxHealth = vehicleCard.maxHealth
    vehicleRenderOptions.keywordValues = keywordrules.getCardKeywordValues(vehicleCard, vehicleDefinition)

    card.pilotVehicleAnimation = true
    ctx.pilotVehicleAnimations[#ctx.pilotVehicleAnimations + 1] = {
        elapsed = 0,
        duration = ctx.pilotVehicleAnimationDuration,
        cardIndex = cardIndex,
        sourceCard = card,
        vehicleCard = vehicleCard,
        pilotSetName = card.setName,
        pilotCardId = card.cardId,
        pilotRenderOptions = copyRenderOptions(renderOptions),
        vehicleSetName = vehicleDefinition.setName,
        vehicleCardId = vehicleDefinition.id,
        vehicleRenderOptions = vehicleRenderOptions,
        drawX = drawX,
        drawY = drawY,
        cardWidth = cardWidth,
        cardHeight = cardHeight,
    }

    return true
end

function cardanimations.beginKitReturnAnimation(ctx, hostCard, attachedKit, returningCard)
    if not ctx or not hostCard or not attachedKit or not returningCard then
        return false
    end

    local hostCardIndex = nil

    for cardIndex, candidateCard in ipairs(ctx.cards) do
        if candidateCard == hostCard then
            hostCardIndex = cardIndex
            break
        end
    end

    if not hostCardIndex then
        return false
    end

    local drawX, drawY, expansionProgress, renderOptions = ctx.getCardDrawPosition(hostCard, hostCardIndex)
    local badgeRect = carddraw.getKeywordBadgeRect(hostCard.setName, hostCard.cardId, drawX, drawY, renderOptions, "KWKIT")
    local handLayout = ctx.getPlayerHandLayout()
    local slot = handLayout and handLayout.slots[returningCard.location and returningCard.location.slotIndex or 0] or nil

    if not badgeRect or not slot then
        return false
    end

    local previewOptions = {
        width = slot.width,
        showLabelWhenCollapsed = true,
        showHealthOnPortrait = false,
        showBadgesInTextbox = true,
        displayName = returningCard.displayName,
        portraitPath = returningCard.portraitPath,
    }
    local cardWidth, cardHeight = carddraw.getCardSize(previewOptions)

    ctx.kitReturnAnimations[#ctx.kitReturnAnimations + 1] = {
        elapsed = 0,
        duration = ctx.kitReturnTotalDuration,
        badgeRect = {
            x = badgeRect.x,
            y = badgeRect.y,
            size = badgeRect.size,
        },
        startX = badgeRect.x + (badgeRect.size / 2),
        startY = badgeRect.y + (badgeRect.size / 2),
        targetX = slot.x + (cardWidth / 2),
        targetY = slot.y + (cardHeight / 2),
        peakY = math.min(badgeRect.y, slot.y) - math.max(34, badgeRect.size * 1.8),
        setName = attachedKit.setName,
        cardId = attachedKit.cardId,
        renderOptions = previewOptions,
        cardWidth = cardWidth,
        cardHeight = cardHeight,
        returningCard = returningCard,
    }

    returningCard.returningToHandAnimation = true
    return true
end

function cardanimations.updateKitReturnAnimations(ctx, dt)
    for animationIndex = #ctx.kitReturnAnimations, 1, -1 do
        local animation = ctx.kitReturnAnimations[animationIndex]
        animation.elapsed = animation.elapsed + dt

        if animation.elapsed >= animation.duration then
            if animation.returningCard then
                animation.returningCard.returningToHandAnimation = nil
            end

            table.remove(ctx.kitReturnAnimations, animationIndex)
        end
    end
end

function cardanimations.drawKitReturnAnimations(ctx)
    for _, animation in ipairs(ctx.kitReturnAnimations) do
        local elapsed = math.max(0, animation.elapsed)
        local flashProgress = math.min(1, elapsed / ctx.kitReturnFlashDuration)
        local expandProgress = math.min(1, math.max(0, elapsed - ctx.kitReturnFlashDuration) / ctx.kitReturnExpandDuration)
        local flyProgress = math.min(1, math.max(0, elapsed - ctx.kitReturnFlashDuration - ctx.kitReturnExpandDuration) / ctx.kitReturnFlyDuration)

        if flashProgress < 1 then
            local glowAlpha = (1 - flashProgress) * 0.55
            local glowInset = 2 + (flashProgress * 6)

            love.graphics.setColor(1, 0.92, 0.52, glowAlpha)
            love.graphics.rectangle(
                "fill",
                animation.badgeRect.x - glowInset,
                animation.badgeRect.y - glowInset,
                animation.badgeRect.size + (glowInset * 2),
                animation.badgeRect.size + (glowInset * 2),
                6,
                6
            )
        end

        local centerX = animation.startX
        local centerY = animation.startY
        local scale = 0.22

        if flyProgress > 0 then
            local t = 1 - ((1 - flyProgress) * (1 - flyProgress))
            local invT = 1 - t
            centerX = (invT * invT * animation.startX) + (2 * invT * t * ((animation.startX + animation.targetX) / 2)) + (t * t * animation.targetX)
            centerY = (invT * invT * animation.startY) + (2 * invT * t * animation.peakY) + (t * t * animation.targetY)
            scale = 0.5 + (0.5 * t)
        elseif expandProgress > 0 then
            local t = 1 - ((1 - expandProgress) * (1 - expandProgress))
            centerY = animation.startY - (18 * t)
            scale = 0.22 + (0.42 * t)
        end

        love.graphics.push()
        love.graphics.translate(centerX, centerY)
        love.graphics.scale(scale, scale)
        carddraw.drawCardState(
            animation.setName,
            animation.cardId,
            -animation.cardWidth / 2,
            -animation.cardHeight / 2,
            0,
            animation.renderOptions
        )
        love.graphics.pop()
    end

    love.graphics.setColor(1, 1, 1, 1)
end

local function easeOutCubic(t)
    t = math.max(0, math.min(1, t or 0))
    local invT = 1 - t
    return 1 - (invT * invT * invT)
end

local function easeInOutCubic(t)
    t = math.max(0, math.min(1, t or 0))

    if t < 0.5 then
        return 4 * t * t * t
    end

    local shifted = (-2 * t) + 2
    return 1 - ((shifted * shifted * shifted) / 2)
end

local function drawAnimatedCard(setName, cardId, centerX, centerY, scale, alpha, renderOptions)
    if (alpha or 0) <= 0.12 then
        return
    end

    local cardWidth, cardHeight = carddraw.getCardSize(renderOptions)

    love.graphics.push()
    love.graphics.translate(centerX, centerY)
    love.graphics.scale(scale, scale)
    carddraw.drawCardState(
        setName,
        cardId,
        -cardWidth / 2,
        -cardHeight / 2,
        0,
        renderOptions
    )

    if alpha < 1 then
        love.graphics.setColor(0.02, 0.025, 0.03, 1 - alpha)
        love.graphics.rectangle("fill", -cardWidth / 2, -cardHeight / 2, cardWidth, cardHeight, 8, 8)
    end

    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end

function cardanimations.updatePilotVehicleAnimations(ctx, dt)
    for animationIndex = #ctx.pilotVehicleAnimations, 1, -1 do
        local animation = ctx.pilotVehicleAnimations[animationIndex]
        animation.elapsed = animation.elapsed + dt

        if animation.elapsed >= animation.duration then
            finishPilotVehicleAnimation(ctx, animation)
            table.remove(ctx.pilotVehicleAnimations, animationIndex)
        end
    end
end

function cardanimations.updateMulliganAnimations(ctx, dt)
    local promptTarget = ctx.mulliganActive and not ctx.mulliganResolving and 1 or 0
    local promptStep = dt / ctx.mulliganPromptFadeDuration

    if ctx.mulliganPromptAlpha < promptTarget then
        ctx.mulliganPromptAlpha = math.min(promptTarget, ctx.mulliganPromptAlpha + promptStep)
    elseif ctx.mulliganPromptAlpha > promptTarget then
        ctx.mulliganPromptAlpha = math.max(promptTarget, ctx.mulliganPromptAlpha - promptStep)
    end

    if not ctx.mulliganResolving then
        return
    end

    local animationsRemaining = false

    for _, card in ipairs(ctx.cards) do
        local animation = card and (card.mulliganInAnimation or card.mulliganOutAnimation) or nil

        if animation then
            animation.elapsed = math.min(animation.duration, (animation.elapsed or 0) + dt)

            if animation.elapsed < animation.duration then
                animationsRemaining = true
            end
        end
    end

    if animationsRemaining then
        return
    end

    if ctx.mulliganPromptAlpha > 0.01 then
        return
    end

    for cardIndex = #ctx.cards, 1, -1 do
        local card = ctx.cards[cardIndex]

        if card and card.mulliganOutAnimation then
            table.remove(ctx.cards, cardIndex)
        elseif card then
            card.mulliganInAnimation = nil
        end
    end

    deckrules.shuffleCardsIntoDeck(ctx.playerDeck, ctx.mulliganReturnedCards or {})
    ctx.normalizeHandCardSlots()

    ctx.mulliganReturnedCards = nil
    ctx.mulliganResolving = false
    ctx.mulliganActive = false
    ctx.mulliganCompleted = true
end

function cardanimations.drawPilotVehicleAnimations(ctx)
    for _, animation in ipairs(ctx.pilotVehicleAnimations) do
        local progress = math.min(1, math.max(0, animation.elapsed / animation.duration))
        local centerX = animation.drawX + (animation.cardWidth / 2)
        local centerY = animation.drawY + (animation.cardHeight / 2)
        local vehicleProgress = easeOutCubic(math.min(1, progress / 0.45))
        local dockProgress = easeInOutCubic(math.max(0, math.min(1, (progress - 0.22) / 0.58)))
        local settleProgress = easeOutCubic(math.max(0, math.min(1, (progress - 0.76) / 0.24)))
        local pilotStartX = centerX
        local pilotStartY = centerY
        local pilotEndX = animation.drawX + (animation.cardWidth * 0.22)
        local pilotEndY = animation.drawY + (animation.cardHeight * 0.24)
        local pilotCenterX = pilotStartX + ((pilotEndX - pilotStartX) * dockProgress)
        local pilotCenterY = pilotStartY + ((pilotEndY - pilotStartY) * dockProgress) - (14 * math.sin(dockProgress * math.pi))
        local pilotScale = 1 - (0.68 * dockProgress)
        local pilotAlpha = 1 - (0.82 * dockProgress)
        local vehicleScale = 0.86 + (0.2 * vehicleProgress) - (0.06 * settleProgress)
        local vehicleAlpha = math.min(1, vehicleProgress * 1.15)
        local pulseAlpha = math.max(0, 1 - progress)
        local pulseInset = 10 + (26 * progress)

        love.graphics.setColor(0.5, 0.82, 1, 0.24 * pulseAlpha)
        love.graphics.rectangle(
            "line",
            animation.drawX - pulseInset,
            animation.drawY - pulseInset,
            animation.cardWidth + (pulseInset * 2),
            animation.cardHeight + (pulseInset * 2),
            8,
            8
        )

        drawAnimatedCard(
            animation.vehicleSetName,
            animation.vehicleCardId,
            centerX,
            centerY,
            vehicleScale,
            vehicleAlpha,
            animation.vehicleRenderOptions
        )

        if pilotAlpha > 0.02 then
            drawAnimatedCard(
                animation.pilotSetName,
                animation.pilotCardId,
                pilotCenterX,
                pilotCenterY,
                pilotScale,
                pilotAlpha,
                animation.pilotRenderOptions
            )
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function cardanimations.beginHunterAutoPlayAnimation(ctx, card, sourceSlotIndex, rowId, column)
    if not ctx or not card or not sourceSlotIndex or not rowId or not column then
        return false
    end

    local handLayout = ctx.getPlayerHandLayout and ctx.getPlayerHandLayout() or nil
    local sourceSlot = handLayout and handLayout.slots and handLayout.slots[sourceSlotIndex] or nil
    local targetRow = ctx.envdraw and ctx.envdraw.getGridRow and ctx.envdraw.getGridRow(rowId) or nil
    local targetCell = nil

    for _, cell in ipairs(targetRow and targetRow.cells or {}) do
        if cell.column == column then
            targetCell = cell
            break
        end
    end

    if not sourceSlot or not targetCell then
        return false
    end

    local renderOptions = {
        width = sourceSlot.width,
        showLabelWhenCollapsed = true,
        showHealthOnPortrait = true,
        showBadgesInTextbox = true,
        displayName = card.displayName,
        portraitPath = card.portraitPath,
        card = card,
        currentHealth = card.currentHealth,
        maxHealth = card.maxHealth,
    }
    local cardWidth, cardHeight = carddraw.getCardSize(renderOptions)
    local targetX = targetCell.x + ((targetCell.width - cardWidth) / 2)
    local targetY = targetCell.y + ((targetCell.height - cardHeight) / 2)

    card.hunterAutoPlayAnimation = true
    ctx.hunterAutoPlayAnimations[#ctx.hunterAutoPlayAnimations + 1] = {
        elapsed = 0,
        duration = ctx.hunterAutoPlayAnimationDuration or 0.46,
        card = card,
        setName = card.setName,
        cardId = card.cardId,
        renderOptions = renderOptions,
        startX = sourceSlot.x,
        startY = sourceSlot.y,
        targetX = targetX,
        targetY = targetY,
        peakY = math.min(sourceSlot.y, targetY) - math.max(42, cardHeight * 0.18),
        cardWidth = cardWidth,
        cardHeight = cardHeight,
    }

    return true
end

function cardanimations.updateHunterAutoPlayAnimations(ctx, dt)
    for animationIndex = #ctx.hunterAutoPlayAnimations, 1, -1 do
        local animation = ctx.hunterAutoPlayAnimations[animationIndex]
        animation.elapsed = animation.elapsed + (dt or 0)

        if animation.elapsed >= animation.duration then
            if animation.card then
                animation.card.hunterAutoPlayAnimation = nil
            end

            table.remove(ctx.hunterAutoPlayAnimations, animationIndex)
        end
    end
end

function cardanimations.drawHunterAutoPlayAnimations(ctx)
    for _, animation in ipairs(ctx.hunterAutoPlayAnimations or {}) do
        local progress = easeInOutCubic((animation.elapsed or 0) / math.max(0.01, animation.duration or 0.46))
        local invProgress = 1 - progress
        local controlX = (animation.startX + animation.targetX) / 2
        local controlY = animation.peakY
        local drawX = (invProgress * invProgress * animation.startX)
            + (2 * invProgress * progress * controlX)
            + (progress * progress * animation.targetX)
        local drawY = (invProgress * invProgress * animation.startY)
            + (2 * invProgress * progress * controlY)
            + (progress * progress * animation.targetY)
        local pulseAlpha = math.sin(progress * math.pi)

        love.graphics.setColor(0.84, 0.12, 0.16, 0.22 * pulseAlpha)
        love.graphics.rectangle(
            "fill",
            drawX - 5,
            drawY - 5,
            animation.cardWidth + 10,
            animation.cardHeight + 10,
            8,
            8
        )

        carddraw.drawCardState(
            animation.setName,
            animation.cardId,
            drawX,
            drawY,
            0,
            animation.renderOptions
        )
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function cardanimations.beginHunterDeckDiscardAnimation(ctx, card)
    if not ctx or not card then
        return false
    end

    local cardDefinition = ctx.cardregistry and ctx.cardregistry.getCard(card.setName, card.cardId) or nil
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local renderOptions = {
        width = math.max(150, math.min(210, screenWidth * 0.12)),
        showLabelWhenCollapsed = true,
        showHealthOnPortrait = false,
        showBadgesInTextbox = true,
        displayName = card.displayName,
        portraitPath = card.portraitPath,
        currentHealth = card.currentHealth,
        maxHealth = card.maxHealth,
        keywordValues = card.keywordValues,
    }
    local cardWidth, cardHeight = carddraw.getCardSize(renderOptions)

    ctx.hunterDeckDiscardAnimations[#ctx.hunterDeckDiscardAnimations + 1] = {
        elapsed = 0,
        duration = ctx.destructionDuration or 0.6,
        setName = card.setName,
        cardId = card.cardId,
        renderOptions = renderOptions,
        cardWidth = cardWidth,
        cardHeight = cardHeight,
        x = (screenWidth - cardWidth) / 2,
        y = (screenHeight - cardHeight) / 2,
        destructionSeed = love.math.random() * 1000,
    }

    if ctx.sfxrules and ctx.sfxrules.playDestroy then
        ctx.sfxrules.playDestroy()
    end

    return cardDefinition ~= nil
end

function cardanimations.updateHunterDeckDiscardAnimations(ctx, dt)
    for animationIndex = #(ctx.hunterDeckDiscardAnimations or {}), 1, -1 do
        local animation = ctx.hunterDeckDiscardAnimations[animationIndex]

        animation.elapsed = (animation.elapsed or 0) + (dt or 0)

        if animation.elapsed >= (animation.duration or 0.6) then
            table.remove(ctx.hunterDeckDiscardAnimations, animationIndex)
        end
    end
end

function cardanimations.drawHunterDeckDiscardAnimations(ctx)
    for _, animation in ipairs(ctx.hunterDeckDiscardAnimations or {}) do
        local duration = math.max(0.01, animation.duration or 0.6)
        local progress = math.min(1, math.max(0, (animation.elapsed or 0) / duration))
        local alpha = 1 - math.max(0, (progress - 0.72) / 0.28)
        local renderOptions = copyRenderOptions(animation.renderOptions)

        renderOptions.destructionProgress = progress
        renderOptions.destructionSeed = animation.destructionSeed
        renderOptions.alpha = alpha

        love.graphics.setColor(0.02, 0.02, 0.025, 0.42 * alpha)
        love.graphics.rectangle(
            "fill",
            animation.x - 16,
            animation.y - 16,
            animation.cardWidth + 32,
            animation.cardHeight + 32,
            8,
            8
        )

        carddraw.drawCardState(
            animation.setName,
            animation.cardId,
            animation.x,
            animation.y,
            0,
            renderOptions
        )
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function cardanimations.beginHaywireDeckAddAnimation(ctx, card)
    if not ctx or not card then
        return false
    end

    local cardDefinition = ctx.cardregistry and ctx.cardregistry.getCard(card.setName, card.cardId) or nil
    local systemRect = ctx.envdraw and ctx.envdraw.getSystemBadgeColumnRect and ctx.envdraw.getSystemBadgeColumnRect() or nil
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local renderOptions = {
        width = math.max(150, math.min(210, screenWidth * 0.12)),
        showLabelWhenCollapsed = true,
        showHealthOnPortrait = false,
        showBadgesInTextbox = true,
        displayName = card.displayName,
        portraitPath = card.portraitPath,
        currentHealth = card.currentHealth,
        maxHealth = card.maxHealth,
        keywordValues = card.keywordValues,
    }
    local cardWidth, cardHeight = carddraw.getCardSize(renderOptions)
    local startX = systemRect and (systemRect.x + ((systemRect.width - cardWidth) / 2)) or ((screenWidth - cardWidth) / 2)
    local startY = systemRect and (systemRect.y + ((systemRect.height - cardHeight) / 2)) or ((screenHeight - cardHeight) / 2)

    ctx.haywireDeckAddAnimations[#ctx.haywireDeckAddAnimations + 1] = {
        elapsed = 0,
        duration = 0.46,
        setName = card.setName,
        cardId = card.cardId,
        renderOptions = renderOptions,
        cardWidth = cardWidth,
        cardHeight = cardHeight,
        startX = startX,
        startY = startY,
        targetY = screenHeight + cardHeight + 24,
    }

    if ctx.sfxrules and ctx.sfxrules.playPlayReject then
        ctx.sfxrules.playPlayReject()
    end

    return cardDefinition ~= nil
end

function cardanimations.updateHaywireDeckAddAnimations(ctx, dt)
    for animationIndex = #(ctx.haywireDeckAddAnimations or {}), 1, -1 do
        local animation = ctx.haywireDeckAddAnimations[animationIndex]

        animation.elapsed = (animation.elapsed or 0) + (dt or 0)

        if animation.elapsed >= (animation.duration or 0.46) then
            table.remove(ctx.haywireDeckAddAnimations, animationIndex)
        end
    end
end

function cardanimations.drawHaywireDeckAddAnimations(ctx)
    for _, animation in ipairs(ctx.haywireDeckAddAnimations or {}) do
        local duration = math.max(0.01, animation.duration or 0.46)
        local progress = math.min(1, math.max(0, (animation.elapsed or 0) / duration))
        local easedProgress = progress * progress * progress
        local drawY = ((1 - easedProgress) * animation.startY) + (easedProgress * animation.targetY)
        local alpha = 1 - math.max(0, (progress - 0.78) / 0.22)
        local renderOptions = copyRenderOptions(animation.renderOptions)

        renderOptions.alpha = alpha

        love.graphics.setColor(0.98, 0.24, 0.08, 0.28 * alpha)
        love.graphics.rectangle(
            "fill",
            animation.startX - 8,
            drawY - 8,
            animation.cardWidth + 16,
            animation.cardHeight + 16,
            8,
            8
        )

        carddraw.drawCardState(
            animation.setName,
            animation.cardId,
            animation.startX,
            drawY,
            0,
            renderOptions
        )
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return cardanimations
