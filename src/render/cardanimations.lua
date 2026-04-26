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

return cardanimations
