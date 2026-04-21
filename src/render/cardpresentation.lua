local carddraw = require("src.render.carddraw")
local targetoverlays = require("src.render.targetoverlays")
local cardregistry = require("src.system.cardregistry")
local keywordrules = require("src.system.keywordrules")
local targetingrules = require("src.system.targetingrules")

local cardpresentation = {}

local function getCardDefinition(card)
    if not card then
        return nil
    end

    return cardregistry.getCard(card.setName, card.cardId)
end

local function getDestructionProgress(card, destructionDuration)
    if not card or not card.destroying then
        return nil
    end

    return math.min(1, (card.destroyElapsed or 0) / destructionDuration)
end

local function buildCommonRenderOptions(card, ctx)
    return {
        currentHealth = card.currentHealth,
        maxHealth = card.maxHealth,
        card = card,
        blocking = card.blocking,
        keywordValues = keywordrules.getCardKeywordValues(card, getCardDefinition(card)),
        displayName = card.displayName,
        portraitPath = card.portraitPath,
        lethalPreviewOverkill = nil,
        destructionProgress = getDestructionProgress(card, ctx.destructionDuration),
        destructionSeed = card.destroySeed,
    }
end

function cardpresentation.getRenderOptions(card, cardIndex, ctx)
    if card.location.kind == "grid" then
        local gridRow = ctx.envdraw.getGridRow(card.location.rowId)
        local cell = gridRow and gridRow.cells[card.location.column]
        local damagePreviewCount = 0
        local blockedDamagePreviewCount = 0
        local healthDamagePreviewCount = 0
        local lethalPreviewOverkill = nil

        if card.location.rowId == "PlayerRow" and cardIndex then
            damagePreviewCount = ctx.warrules.getIncomingDamagePreview(cardIndex, ctx.isWarRollSourceActive)
            blockedDamagePreviewCount = ctx.warrules.getBlockedDamagePreview(card, damagePreviewCount)
            healthDamagePreviewCount = ctx.warrules.getHealthDamagePreview(card, damagePreviewCount)

            if card.currentHealth and healthDamagePreviewCount >= card.currentHealth then
                lethalPreviewOverkill = math.max(0, healthDamagePreviewCount - card.currentHealth)
            end
        end

        if cell then
            local options = buildCommonRenderOptions(card, ctx)
            options.width = cell.width
            options.showLabelWhenCollapsed = false
            options.showHealthOnPortrait = true
            options.healthFontScale = 1.2
            options.showBadgesInTextbox = true
            options.damagePreviewCount = healthDamagePreviewCount
            options.blockedDamagePreviewCount = blockedDamagePreviewCount
            options.lethalPreviewOverkill = lethalPreviewOverkill
            options.dimmed = ctx.warrules.isCardExhausted(cardIndex)
            options.selected = ctx.selectedAttackerCardIndex == cardIndex
            return options
        end
    end

    if card.location.kind == "setup" then
        local setupLayout = ctx.envdraw.getSetupModalLayout(ctx.getSetupCardCount())
        local slot = setupLayout and setupLayout.slots[card.location.slotIndex]

        if slot then
            local options = buildCommonRenderOptions(card, ctx)
            options.width = slot.width
            options.showLabelWhenCollapsed = false
            options.showHealthOnPortrait = true
            options.healthFontScale = 1.2
            options.showBadgesInTextbox = true
            options.dimmed = false
            options.selected = false
            return options
        end
    end

    local options = buildCommonRenderOptions(card, ctx)
    options.showLabelWhenCollapsed = true
    options.showHealthOnPortrait = false
    options.showEmphasisOnPortrait = true
    options.healthFontScale = 1
    options.showBadgesInTextbox = true
    options.dimmed = false
    options.selected = false
    return options
end

function cardpresentation.getAnchorPosition(card, ctx)
    local renderOptions = cardpresentation.getRenderOptions(card, nil, ctx)
    local cardWidth, cardHeight = carddraw.getCardSize(renderOptions)

    if card.location.kind == "grid" then
        local gridRow = ctx.envdraw.getGridRow(card.location.rowId)

        if not gridRow then
            return 0, 0
        end

        local cell = gridRow.cells[card.location.column]

        if not cell then
            return 0, 0
        end

        return cell.x + ((cell.width - cardWidth) / 2), cell.y + (cell.height - cardHeight)
    end

    if card.location.kind == "setup" then
        local setupLayout = ctx.envdraw.getSetupModalLayout(ctx.getSetupCardCount())
        local slot = setupLayout and setupLayout.slots[card.location.slotIndex]

        if not slot then
            return 0, 0
        end

        return slot.x + ((slot.width - cardWidth) / 2), slot.y + (slot.height - cardHeight)
    end

    local handLayout = ctx.getPlayerHandLayout()
    local slot = handLayout.slots[card.location.slotIndex]

    if not slot then
        return 0, 0
    end

    return slot.x, slot.y
end

function cardpresentation.getSlideDistance(card, cardIndex, ctx)
    if card.location.kind ~= "hand" then
        return 0
    end

    local _, anchorY = cardpresentation.getAnchorPosition(card, ctx)
    local entranceProgress = ctx.cardEntranceProgress[cardIndex] or 0
    return (1 - entranceProgress) * (love.graphics.getHeight() - anchorY + 40)
end

function cardpresentation.getDrawPosition(card, cardIndex, ctx)
    local expansionProgress = ctx.cardExpansion[cardIndex] or 0
    local renderOptions = cardpresentation.getRenderOptions(card, cardIndex, ctx)

    if ctx.draggedCardIndex == cardIndex then
        local mouseX, mouseY = love.mouse.getPosition()
        return mouseX - ctx.dragOffsetX, mouseY - ctx.dragOffsetY, 0, renderOptions
    end

    local anchorX, anchorY = cardpresentation.getAnchorPosition(card, ctx)
    local drawX, drawY = carddraw.getDrawPosition(anchorX, anchorY, expansionProgress, renderOptions)
    local jitterOffsetX, jitterOffsetY = ctx.getDamageJitterOffset(ctx.getDamageJitterKeyForCard(cardIndex))
    drawX = drawX + jitterOffsetX
    drawY = drawY + jitterOffsetY
    drawY = drawY + cardpresentation.getSlideDistance(card, cardIndex, ctx)
    return drawX, drawY, expansionProgress, renderOptions
end

function cardpresentation.getTopSlotRect(slotId, ctx)
    if not slotId then
        return nil
    end

    local slots = ctx.envdraw.getTopSlotLayouts(
        ctx.turnrules.getCurrentPhase(),
        ctx.activeChampion,
        ctx.activeWarzone,
        ctx.activePoi,
        ctx.activePrimaryObjective,
        ctx.activeIntel
    )

    for _, slot in ipairs(slots or {}) do
        if slot.id == slotId then
            return {
                x = slot.imageRect and slot.imageRect.x or slot.x,
                y = slot.imageRect and slot.imageRect.y or slot.y,
                width = slot.imageRect and slot.imageRect.width or slot.width,
                height = slot.imageRect and slot.imageRect.height or (slot.labelHeight + slot.height),
            }
        end
    end

    return nil
end

function cardpresentation.getEntitySourceRect(entityKey, ctx)
    local cardIndex = entityKey and entityKey:match("^card:(%d+)$")

    if cardIndex then
        local numericCardIndex = tonumber(cardIndex)
        local card = ctx.cards[numericCardIndex]

        if card and not ctx.isCardUnavailable(card) then
            local drawX, drawY, expansionProgress, renderOptions = cardpresentation.getDrawPosition(card, numericCardIndex, ctx)
            local cardWidth, collapsedHeight = carddraw.getCardSize(renderOptions)
            local _, expandedHeight = carddraw.getExpandedCardSize(renderOptions)

            return {
                x = drawX,
                y = drawY,
                width = cardWidth,
                height = collapsedHeight + ((expandedHeight - collapsedHeight) * expansionProgress),
            }
        end
    end

    return cardpresentation.getTopSlotRect(entityKey, ctx)
end

function cardpresentation.drawStateOverlays(card, cardIndex, drawX, drawY, expansionProgress, renderOptions, ctx)
    local rollState = ctx.warrules.getCardRollState(cardIndex)
    local cardWidth, collapsedHeight = carddraw.getCardSize(renderOptions)
    local _, expandedHeight = carddraw.getExpandedCardSize(renderOptions)
    local cardHeight = collapsedHeight + ((expandedHeight - collapsedHeight) * expansionProgress)
    local targetingContext = ctx.getTargetingContext()

    if targetingrules.shouldBracketCard(cardIndex, targetingContext) then
        local bracketColorName = targetingrules.getCardBracketColor(cardIndex, targetingContext)
        local bracketColor = bracketColorName == "strategy"
            and targetoverlays.getStrategyBracketColor()
            or targetoverlays.getDefaultBracketColor()

        targetoverlays.drawBrackets(drawX, drawY, cardWidth, cardHeight, bracketColor)
    end

    if renderOptions.selected then
        love.graphics.setColor(1, 0.847, 0.219, 0.95)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", drawX - 2, drawY - 2, cardWidth + 4, cardHeight + 4, 10, 10)
        love.graphics.setLineWidth(1)
    end

    if renderOptions.dimmed then
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill", drawX, drawY, cardWidth, cardHeight, 8, 8)
    end

    if rollState and rollState.faceIndex then
        local badgeX, badgeY, badgeWidth, badgeHeight = carddraw.getCardRollBadgeRect(drawX, drawY, renderOptions)
        carddraw.drawDefinitionRollBadge(getCardDefinition(card), badgeX, badgeY, badgeWidth, badgeHeight, rollState.faceIndex, rollState.pulseScale)

        if rollState.locked then
            love.graphics.setColor(1, 0.847, 0.219, 0.95)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", badgeX - 1, badgeY - 1, badgeWidth + 2, badgeHeight + 2)
            love.graphics.setLineWidth(1)
        end

        if rollState.targetCard and card.location.rowId == "OppRow" then
            local targetBadgeX, targetBadgeY, targetBadgeSize = carddraw.getCardTargetBadgeRect(drawX, drawY, renderOptions, card.location.rowId == "OppRow")
            carddraw.drawTargetPreviewBadge(rollState.targetCard, targetBadgeX, targetBadgeY, targetBadgeSize)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return cardpresentation
