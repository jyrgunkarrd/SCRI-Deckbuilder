local carddraw = require("src.render.carddraw")
local envassets = require("src.render.envassets")

local previewdraw = {}

local JACL_LABEL_FONT_PATH = "assets/fonts/Furore.otf"
local JACL_DECK_MODAL_MARGIN = 24
local JACL_DECK_MODAL_CARD_WIDTH = 112
local SPECIAL_TOOLTIP_WIDTH = 300
local SPECIAL_TOOLTIP_PADDING = 12
local SPECIAL_TOOLTIP_TITLE_SIZE = 16
local SPECIAL_TOOLTIP_BODY_SIZE = 12
local SPECIAL_TOOLTIP_OFFSET_X = 18
local SPECIAL_TOOLTIP_PREVIEW_GAP = 16
local SPECIAL_TOOLTIP_BACKDROP_PADDING = 8
local HOVER_PREVIEW_MARGIN_X = 48
local HOVER_PREVIEW_FRAME_PADDING = 12
local HOVER_PREVIEW_CARD_MAX_WIDTH = 360
local HOVER_PREVIEW_CARD_MAX_HEIGHT_RATIO = 0.74
local HOVER_PREVIEW_ART_MAX_WIDTH_RATIO = 0.34
local HOVER_PREVIEW_ART_MAX_HEIGHT_RATIO = 0.58
local HOVER_PREVIEW_LABEL_HEIGHT = 38
local HOVER_PREVIEW_BADGE_SCALE = 1.2

local function snap(value)
    return math.floor(value + 0.5)
end

local function normalizeSummonPreviewEntries(previewCards)
    local previewEntries = {}

    for _, previewCard in ipairs(previewCards or {}) do
        if previewCard.definition then
            previewEntries[#previewEntries + 1] = {
                definition = previewCard.definition,
                count = math.max(1, math.floor(tonumber(previewCard.count or previewCard.quantity) or 1)),
            }
        elseif previewCard.cardDefinition then
            previewEntries[#previewEntries + 1] = {
                definition = previewCard.cardDefinition,
                count = math.max(1, math.floor(tonumber(previewCard.count or previewCard.quantity) or 1)),
            }
        else
            previewEntries[#previewEntries + 1] = {
                definition = previewCard,
                count = math.max(1, math.floor(tonumber(previewCard.count or previewCard.quantity) or 1)),
            }
        end
    end

    return previewEntries
end

local function getSummonPreviewEntryWidth(previewWidth, previewEntry)
    local count = math.max(1, tonumber(previewEntry and previewEntry.count) or 1)
    local visibleStackCount = math.min(count, 5)
    local stackOffset = previewWidth * 0.24

    return previewWidth + ((visibleStackCount - 1) * stackOffset)
end

local function getSummonPreviewEntriesWidth(previewEntries, previewWidth, previewGap)
    local totalWidth = 0

    for previewIndex, previewEntry in ipairs(previewEntries or {}) do
        if previewIndex > 1 then
            totalWidth = totalWidth + previewGap
        end

        totalWidth = totalWidth + getSummonPreviewEntryWidth(previewWidth, previewEntry)
    end

    return totalWidth
end

local function drawSummonPreviewStack(previewEntry, previewX, previewY, previewWidth, previewHeight, labelFont)
    local previewCardDefinition = previewEntry.definition

    if not previewCardDefinition then
        return
    end

    local count = math.max(1, math.floor(tonumber(previewEntry.count) or 1))
    local visibleStackCount = math.min(count, 5)
    local stackOffset = previewWidth * 0.24

    for stackIndex = visibleStackCount, 1, -1 do
        local offset = (stackIndex - 1) * stackOffset
        local cardX = previewX + offset

        if stackIndex > 1 then
            love.graphics.setColor(0.02, 0.025, 0.03, 0.72)
            love.graphics.rectangle("fill", cardX - 4, previewY + 4, previewWidth, previewHeight, 8, 8)
            love.graphics.setColor(0.86, 0.88, 0.93, 0.64)
            love.graphics.rectangle("line", cardX, previewY, previewWidth, previewHeight, 8, 8)
        end

        carddraw.drawCardState(previewCardDefinition.setName, previewCardDefinition.id, cardX, previewY, 1, {
            width = previewWidth,
            showBadgesInTextbox = true,
        })
    end

    if count > 1 then
        local badgeText = "x" .. tostring(count)
        local badgePaddingX = SPECIAL_TOOLTIP_PADDING * 0.7
        local badgeHeight = labelFont:getHeight() + 8
        local badgeWidth = math.max(labelFont:getWidth(badgeText) + (badgePaddingX * 2), badgeHeight)
        local badgeX = previewX + getSummonPreviewEntryWidth(previewWidth, previewEntry) - badgeWidth - 8
        local badgeY = previewY + previewHeight - badgeHeight - 8

        love.graphics.setColor(0.04, 0.045, 0.055, 0.94)
        love.graphics.rectangle("fill", badgeX, badgeY, badgeWidth, badgeHeight, 5, 5)
        love.graphics.setColor(0.92, 0.94, 0.98, 0.92)
        love.graphics.rectangle("line", badgeX, badgeY, badgeWidth, badgeHeight, 5, 5)
        love.graphics.setFont(labelFont)
        love.graphics.setColor(0.96, 0.97, 1, 1)
        love.graphics.printf(
            badgeText,
            badgeX,
            badgeY + ((badgeHeight - labelFont:getHeight()) / 2),
            badgeWidth,
            "center"
        )
    end
end

local function drawSummonPreviewEntries(previewEntries, previewX, previewY, previewWidth, previewHeight, previewGap, labelFont)
    for _, previewEntry in ipairs(previewEntries or {}) do
        drawSummonPreviewStack(previewEntry, previewX, previewY, previewWidth, previewHeight, labelFont)
        previewX = previewX + getSummonPreviewEntryWidth(previewWidth, previewEntry) + previewGap
    end
end

function previewdraw.getJaclDeckPreviewModalLayout(previewCards)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local cardWidth, cardHeight = carddraw.getExpandedCardSize()
    local previewEntries = normalizeSummonPreviewEntries(previewCards)
    local previewCount = #previewEntries
    local previewGap = SPECIAL_TOOLTIP_PREVIEW_GAP
    local previewWidth = cardWidth
    local previewHeight = cardHeight

    if previewCount > 0 then
        local previewGapWidth = (previewCount - 1) * previewGap
        local availablePreviewWidth = math.max(
            JACL_DECK_MODAL_CARD_WIDTH,
            windowWidth - (JACL_DECK_MODAL_MARGIN * 2) - cardWidth - previewGap - previewGapWidth
        )

        local stackWidthFactor = 0

        for _, previewEntry in ipairs(previewEntries) do
            local count = math.max(1, tonumber(previewEntry and previewEntry.count) or 1)
            stackWidthFactor = stackWidthFactor + 1 + ((math.min(count, 5) - 1) * 0.24)
        end

        previewWidth = math.min(cardWidth, (availablePreviewWidth - previewGapWidth) / math.max(1, stackWidthFactor))
        previewWidth = math.max(JACL_DECK_MODAL_CARD_WIDTH, previewWidth)
        _, previewHeight = carddraw.getExpandedCardSize({
            width = previewWidth,
        })
    end

    local previewTotalWidth = previewCount > 0
        and getSummonPreviewEntriesWidth(previewEntries, previewWidth, previewGap)
        or 0
    local labelFont = envassets.getFont(JACL_LABEL_FONT_PATH, SPECIAL_TOOLTIP_TITLE_SIZE)
    local labelHeight = previewCount > 0
        and ((SPECIAL_TOOLTIP_PADDING * 2) + labelFont:getHeight())
        or 0
    local previewTotalHeight = previewCount > 0
        and (previewHeight + SPECIAL_TOOLTIP_PREVIEW_GAP + labelHeight)
        or 0
    local totalWidth = cardWidth + (previewCount > 0 and (previewGap + previewTotalWidth) or 0)
    local x = (windowWidth - totalWidth) / 2
    local cardY = (windowHeight - cardHeight) / 2
    local previewX = x + cardWidth + previewGap
    local previewY = (windowHeight - previewTotalHeight) / 2
    local labelY = previewY + previewHeight + SPECIAL_TOOLTIP_PREVIEW_GAP
    local y = math.min(cardY, previewCount > 0 and previewY or cardY)
    local bottomY = math.max(cardY + cardHeight, previewCount > 0 and (previewY + previewTotalHeight) or (cardY + cardHeight))

    return {
        x = x,
        y = y,
        width = totalWidth,
        height = bottomY - y,
        cardX = x,
        cardY = cardY,
        cardWidth = cardWidth,
        cardHeight = cardHeight,
        previewX = previewX,
        previewY = previewY,
        previewWidth = previewWidth,
        previewHeight = previewHeight,
        previewGap = previewGap,
        previewTotalWidth = previewTotalWidth,
        labelY = labelY,
        labelHeight = labelHeight,
    }
end

function previewdraw.drawJaclDeckPreviewModal(card, preview)
    if not card then
        return
    end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    local previewCards = preview and (preview.cardDefinitionEntries or preview.cardDefinitions) or nil
    local previewEntries = normalizeSummonPreviewEntries(previewCards)
    local layout = previewdraw.getJaclDeckPreviewModalLayout(previewCards)

    love.graphics.setColor(0.01, 0.01, 0.02, 0.36)
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    carddraw.drawCardState(card.setName, card.cardId, layout.cardX, layout.cardY, 1, {
        displayName = card.displayName,
        portraitPath = card.portraitPath,
        showBadgesInTextbox = true,
        showEmphasisOnPortrait = true,
    })

    if previewEntries and #previewEntries > 0 then
        local previousFont = love.graphics.getFont()
        local labelFont = envassets.getFont(JACL_LABEL_FONT_PATH, SPECIAL_TOOLTIP_TITLE_SIZE)
        drawSummonPreviewEntries(
            previewEntries,
            layout.previewX,
            layout.previewY,
            layout.previewWidth,
            layout.previewHeight,
            layout.previewGap,
            labelFont
        )
        love.graphics.setColor(0.05, 0.05, 0.06, 0.96)
        love.graphics.rectangle("fill", layout.previewX, layout.labelY, layout.previewTotalWidth, layout.labelHeight, 6, 6)
        love.graphics.setColor(0.82, 0.85, 0.89, 0.82)
        love.graphics.rectangle("line", layout.previewX, layout.labelY, layout.previewTotalWidth, layout.labelHeight, 6, 6)

        love.graphics.setFont(labelFont)
        love.graphics.setColor(0.95, 0.96, 0.98, 1)
        love.graphics.printf(
            preview.label or "PREVIEW",
            layout.previewX + SPECIAL_TOOLTIP_PADDING,
            snap(layout.labelY + ((layout.labelHeight - labelFont:getHeight()) / 2)),
            layout.previewTotalWidth - (SPECIAL_TOOLTIP_PADDING * 2),
            "center"
        )
        love.graphics.setFont(previousFont)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function previewdraw.drawFullArtOverlay(image)
    if not image then
        return
    end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    local maxWidth = windowWidth * 0.82
    local maxHeight = windowHeight * 0.82
    local scale = math.min(maxWidth / image:getWidth(), maxHeight / image:getHeight())
    local imageWidth = image:getWidth() * scale
    local imageHeight = image:getHeight() * scale
    local imageX = (windowWidth - imageWidth) / 2
    local imageY = (windowHeight - imageHeight) / 2

    love.graphics.setColor(0.01, 0.01, 0.02, 0.72)
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    love.graphics.setColor(0.82, 0.85, 0.89, 0.9)
    love.graphics.rectangle("line", imageX - 2, imageY - 2, imageWidth + 4, imageHeight + 4)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(image, imageX, imageY, 0, scale, scale)
    love.graphics.setColor(1, 1, 1, 1)
end

local function getHoverPreviewSide(sourceRect)
    local windowWidth = love.graphics.getWidth()
    local sourceCenterX = sourceRect and (sourceRect.x + ((sourceRect.width or 0) / 2)) or (windowWidth / 2)

    if sourceCenterX < (windowWidth / 2) then
        return "right"
    end

    return "left"
end

local function getHoverPreviewCardLayout(sourceRect)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local previewSide = getHoverPreviewSide(sourceRect)
    local availableSideWidth = math.max(220, (windowWidth / 2) - (HOVER_PREVIEW_MARGIN_X * 2))
    local maxCardHeight = windowHeight * HOVER_PREVIEW_CARD_MAX_HEIGHT_RATIO
    local previewWidth = math.min(
        HOVER_PREVIEW_CARD_MAX_WIDTH,
        availableSideWidth,
        maxCardHeight / 2.2
    )
    local _, previewHeight = carddraw.getExpandedCardSize({
        width = previewWidth,
    })
    local previewX = previewSide == "left"
        and HOVER_PREVIEW_MARGIN_X
        or (windowWidth - HOVER_PREVIEW_MARGIN_X - previewWidth)
    local previewY = (windowHeight - previewHeight) / 2

    return {
        side = previewSide,
        x = snap(previewX),
        y = snap(previewY),
        width = snap(previewWidth),
        height = snap(previewHeight),
    }
end

local function getHoverPreviewArtLayout(sourceRect, image)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local previewSide = getHoverPreviewSide(sourceRect)
    local maxWidth = math.max(180, (windowWidth * HOVER_PREVIEW_ART_MAX_WIDTH_RATIO))
    local maxHeight = math.max(180, (windowHeight * HOVER_PREVIEW_ART_MAX_HEIGHT_RATIO))
    local imageWidth = maxWidth
    local imageHeight = maxHeight

    if image then
        local scale = math.min(maxWidth / image:getWidth(), maxHeight / image:getHeight())
        imageWidth = image:getWidth() * scale
        imageHeight = image:getHeight() * scale
    end

    local frameWidth = imageWidth + (HOVER_PREVIEW_FRAME_PADDING * 2)
    local frameHeight = imageHeight + HOVER_PREVIEW_LABEL_HEIGHT + (HOVER_PREVIEW_FRAME_PADDING * 2)
    local frameX = previewSide == "left"
        and HOVER_PREVIEW_MARGIN_X
        or (windowWidth - HOVER_PREVIEW_MARGIN_X - frameWidth)
    local frameY = (windowHeight - frameHeight) / 2

    return {
        side = previewSide,
        x = snap(frameX),
        y = snap(frameY),
        width = snap(frameWidth),
        height = snap(frameHeight),
        imageX = snap(frameX + HOVER_PREVIEW_FRAME_PADDING),
        imageY = snap(frameY + HOVER_PREVIEW_LABEL_HEIGHT + HOVER_PREVIEW_FRAME_PADDING),
        imageWidth = snap(imageWidth),
        imageHeight = snap(imageHeight),
    }
end

local function drawHoverPreviewArtPanel(preview)
    local layout = getHoverPreviewArtLayout(preview.sourceRect, preview.image)
    local accentColor = preview.accentColor or { 0.82, 0.85, 0.89 }
    local labelFont = envassets.getFont(JACL_LABEL_FONT_PATH, 16)
    local imageRect = {
        x = layout.imageX,
        y = layout.imageY,
        width = layout.imageWidth,
        height = layout.imageHeight,
    }

    love.graphics.setColor(0.02, 0.025, 0.03, 0.48)
    love.graphics.rectangle(
        "fill",
        layout.x - 6,
        layout.y - 6,
        layout.width + 12,
        layout.height + 12,
        10,
        10
    )
    love.graphics.setColor(0.06, 0.07, 0.09, 0.96)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height, 10, 10)
    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.92)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height, 10, 10)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, HOVER_PREVIEW_LABEL_HEIGHT, 10, 10)

    if preview.image then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            preview.image,
            imageRect.x,
            imageRect.y,
            0,
            imageRect.width / preview.image:getWidth(),
            imageRect.height / preview.image:getHeight()
        )
    else
        love.graphics.setColor(0.16, 0.17, 0.2, 1)
        love.graphics.rectangle("fill", imageRect.x, imageRect.y, imageRect.width, imageRect.height, 8, 8)
    end

    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.9)
    love.graphics.rectangle("line", imageRect.x, imageRect.y, imageRect.width, imageRect.height, 8, 8)

    if preview.definition and preview.rollState and preview.rollState.faceIndex then
        local badgeInset = math.max(4, snap(imageRect.width * 0.035))
        local badgeWidth = math.max(20, snap(imageRect.width * 0.115 * HOVER_PREVIEW_BADGE_SCALE))
        local badgeHeaderHeight = snap(badgeWidth * 0.44)
        local badgeBodyHeight = badgeWidth
        local badgeHeight = badgeHeaderHeight + badgeBodyHeight
        local badgeX = snap(imageRect.x + imageRect.width - badgeInset - badgeWidth)
        local badgeY = snap(imageRect.y + badgeInset)

        carddraw.drawDefinitionRollBadge(
            preview.definition,
            badgeX,
            badgeY,
            badgeWidth,
            badgeHeight,
            preview.rollState.faceIndex,
            preview.rollState.pulseScale
        )
    end

    love.graphics.setColor(0.06, 0.07, 0.09, 0.96)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, HOVER_PREVIEW_LABEL_HEIGHT, 10, 10)
    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.92)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, HOVER_PREVIEW_LABEL_HEIGHT, 10, 10)
    love.graphics.setFont(labelFont)
    love.graphics.setColor(0.95, 0.96, 0.98, 1)
    love.graphics.printf(
        preview.label or preview.slotId or "Preview",
        layout.x + 12,
        layout.y + ((HOVER_PREVIEW_LABEL_HEIGHT - labelFont:getHeight()) / 2),
        layout.width - 24,
        "center"
    )

    love.graphics.setColor(1, 1, 1, 1)
end

function previewdraw.drawHoverPreview(preview, drawCardStateOverlays)
    if not preview or not preview.sourceRect then
        return
    end

    if preview.kind == "card" then
        local layout = getHoverPreviewCardLayout(preview.sourceRect)
        local renderOptions = {}

        for key, value in pairs(preview.renderOptions or {}) do
            renderOptions[key] = value
        end

        renderOptions.width = layout.width
        renderOptions.showBadgesInTextbox = true

        carddraw.drawCardState(preview.setName, preview.cardId, layout.x, layout.y, 1, renderOptions)

        if drawCardStateOverlays and preview.card and preview.cardIndex then
            drawCardStateOverlays(preview.card, preview.cardIndex, layout.x, layout.y, 1, renderOptions)
        end

        if preview.definitionPreview
            and preview.definitionPreview.cardDefinitionEntries
            and #preview.definitionPreview.cardDefinitionEntries > 0 then
            local previewEntries = normalizeSummonPreviewEntries(preview.definitionPreview.cardDefinitionEntries)
            local labelFont = envassets.getFont(JACL_LABEL_FONT_PATH, 14)
            local previewGap = SPECIAL_TOOLTIP_PREVIEW_GAP
            local sideGap = math.max(20, previewGap * 1.35)
            local labelGap = math.max(14, previewGap)
            local previewWidth = math.min(layout.width, 180)
            local previewHeight = select(2, carddraw.getExpandedCardSize({
                width = previewWidth,
            }))
            local previewTotalWidth = getSummonPreviewEntriesWidth(previewEntries, previewWidth, previewGap)
            local previewX = layout.side == "left"
                and (layout.x + layout.width + sideGap)
                or (layout.x - sideGap - previewTotalWidth)
            previewX = math.max(8, math.min(previewX, love.graphics.getWidth() - previewTotalWidth - 8))
            local visualPreviewHeight = select(2, carddraw.getExpandedCardSize({
                width = previewWidth,
                showBadgesInTextbox = true,
            }))
            local labelHeight = labelFont:getHeight() + 10
            local totalPreviewHeight = visualPreviewHeight + labelGap + labelHeight
            local previewY = math.max(8, math.min(layout.y, love.graphics.getHeight() - totalPreviewHeight - 8))
            local labelY = previewY + visualPreviewHeight + labelGap

            drawSummonPreviewEntries(previewEntries, previewX, previewY, previewWidth, previewHeight, previewGap, labelFont)

            love.graphics.setColor(0.05, 0.05, 0.06, 0.96)
            love.graphics.rectangle("fill", previewX, labelY, previewTotalWidth, labelHeight, 6, 6)
            love.graphics.setColor(0.82, 0.85, 0.89, 0.82)
            love.graphics.rectangle("line", previewX, labelY, previewTotalWidth, labelHeight, 6, 6)
            love.graphics.setFont(labelFont)
            love.graphics.setColor(0.95, 0.96, 0.98, 1)
            love.graphics.printf(
                preview.definitionPreview.label or "PREVIEW",
                previewX + SPECIAL_TOOLTIP_PADDING,
                labelY + ((labelHeight - labelFont:getHeight()) / 2),
                previewTotalWidth - (SPECIAL_TOOLTIP_PADDING * 2),
                "center"
            )
        end

        return
    end

    drawHoverPreviewArtPanel(preview)
end

function previewdraw.drawJaclSpecialTooltip(specialDefinition, previewCards, anchorX, anchorY, anchorWidth, anchorHeight)
    if not specialDefinition then
        return
    end

    local previousFont = love.graphics.getFont()
    local titleFont = envassets.getFont(JACL_LABEL_FONT_PATH, SPECIAL_TOOLTIP_TITLE_SIZE)
    local bodyFont = envassets.getFont(JACL_LABEL_FONT_PATH, SPECIAL_TOOLTIP_BODY_SIZE)
    local previewEntries = nil
    local previewWidth, previewHeight = 0, 0
    local previewTotalWidth = 0
    local previewGap = SPECIAL_TOOLTIP_PREVIEW_GAP

    if previewCards then
        if previewCards.definition or previewCards.cardDefinition or previewCards.setName then
            previewEntries = normalizeSummonPreviewEntries({ previewCards })
        else
            previewEntries = normalizeSummonPreviewEntries(previewCards)
        end
    end

    if previewEntries and #previewEntries > 0 then
        previewWidth, previewHeight = carddraw.getExpandedCardSize()
        previewTotalWidth = getSummonPreviewEntriesWidth(previewEntries, previewWidth, previewGap)
    end

    local tooltipWidth = previewTotalWidth > 0 and previewTotalWidth or SPECIAL_TOOLTIP_WIDTH
    local textWidth = tooltipWidth - (SPECIAL_TOOLTIP_PADDING * 2)
    local _, wrappedBodyLines = bodyFont:getWrap(specialDefinition.text or "", textWidth)
    local titleHeight = titleFont:getHeight()
    local bodyHeight = math.max(bodyFont:getHeight(), #wrappedBodyLines * bodyFont:getHeight())
    local tooltipHeight = (SPECIAL_TOOLTIP_PADDING * 2) + titleHeight + 6 + bodyHeight
    local totalWidth = tooltipWidth
    local totalHeight = tooltipHeight + (previewEntries and (SPECIAL_TOOLTIP_PREVIEW_GAP + previewHeight) or 0)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local gap = SPECIAL_TOOLTIP_OFFSET_X
    local rightX = (anchorX or 0) + (anchorWidth or 0) + gap
    local leftX = (anchorX or 0) - gap - totalWidth
    local boxX = rightX + totalWidth <= windowWidth - 8 and rightX or leftX
    local boxY = anchorY or 0
    local tooltipY = boxY + (previewEntries and (previewHeight + SPECIAL_TOOLTIP_PREVIEW_GAP) or 0)

    boxX = snap(math.max(8, math.min(boxX, windowWidth - totalWidth - 8)))
    boxY = snap(math.max(8, math.min(boxY, windowHeight - totalHeight - 8)))
    tooltipY = boxY + (previewEntries and (previewHeight + SPECIAL_TOOLTIP_PREVIEW_GAP) or 0)

    love.graphics.setColor(0.02, 0.025, 0.03, 0.42)
    love.graphics.rectangle(
        "fill",
        boxX - SPECIAL_TOOLTIP_BACKDROP_PADDING,
        boxY - SPECIAL_TOOLTIP_BACKDROP_PADDING,
        totalWidth + (SPECIAL_TOOLTIP_BACKDROP_PADDING * 2),
        totalHeight + (SPECIAL_TOOLTIP_BACKDROP_PADDING * 2),
        8,
        8
    )

    if previewEntries then
        drawSummonPreviewEntries(previewEntries, boxX, boxY, previewWidth, previewHeight, previewGap, titleFont)
    end

    love.graphics.setColor(0.05, 0.05, 0.06, 0.96)
    love.graphics.rectangle("fill", boxX, tooltipY, tooltipWidth, tooltipHeight, 6, 6)
    love.graphics.setColor(0.82, 0.85, 0.89, 0.82)
    love.graphics.rectangle("line", boxX, tooltipY, tooltipWidth, tooltipHeight, 6, 6)
    love.graphics.setFont(titleFont)
    love.graphics.setColor(0.95, 0.96, 0.98, 1)
    love.graphics.print(specialDefinition.name or specialDefinition.id or "Special", boxX + SPECIAL_TOOLTIP_PADDING, tooltipY + SPECIAL_TOOLTIP_PADDING)

    love.graphics.setFont(bodyFont)
    love.graphics.setColor(0.82, 0.85, 0.89, 0.98)
    love.graphics.printf(
        specialDefinition.text or "",
        boxX + SPECIAL_TOOLTIP_PADDING,
        tooltipY + SPECIAL_TOOLTIP_PADDING + titleHeight + 6,
        textWidth,
        "left"
    )

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

function previewdraw.drawSummonPreviewTooltip(previewCards, anchorX, anchorY, anchorWidth, anchorHeight, labelText, preferredSide)
    local previewEntries = normalizeSummonPreviewEntries(previewCards)

    if #previewEntries <= 0 then
        return
    end

    local previousFont = love.graphics.getFont()
    local labelFont = envassets.getFont(JACL_LABEL_FONT_PATH, SPECIAL_TOOLTIP_TITLE_SIZE)
    local previewWidth, previewHeight = carddraw.getExpandedCardSize()
    local bubbleHeight = (SPECIAL_TOOLTIP_PADDING * 2) + labelFont:getHeight()
    local previewGap = SPECIAL_TOOLTIP_PREVIEW_GAP
    local totalWidth = getSummonPreviewEntriesWidth(previewEntries, previewWidth, previewGap)

    local totalHeight = previewHeight + SPECIAL_TOOLTIP_PREVIEW_GAP + bubbleHeight
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local gap = SPECIAL_TOOLTIP_OFFSET_X
    local rightX = (anchorX or 0) + (anchorWidth or 0) + gap
    local leftX = (anchorX or 0) - gap - totalWidth
    local boxX = preferredSide == "left"
        and leftX
        or (rightX + totalWidth <= windowWidth - 8 and rightX or leftX)
    local boxY = anchorY or 0
    local bubbleY = boxY + previewHeight + SPECIAL_TOOLTIP_PREVIEW_GAP

    boxX = snap(math.max(8, math.min(boxX, windowWidth - totalWidth - 8)))
    boxY = snap(math.max(8, math.min(boxY, windowHeight - totalHeight - 8)))
    bubbleY = boxY + previewHeight + SPECIAL_TOOLTIP_PREVIEW_GAP

    love.graphics.setColor(0.02, 0.025, 0.03, 0.42)
    love.graphics.rectangle(
        "fill",
        boxX - SPECIAL_TOOLTIP_BACKDROP_PADDING,
        boxY - SPECIAL_TOOLTIP_BACKDROP_PADDING,
        totalWidth + (SPECIAL_TOOLTIP_BACKDROP_PADDING * 2),
        totalHeight + (SPECIAL_TOOLTIP_BACKDROP_PADDING * 2),
        8,
        8
    )

    drawSummonPreviewEntries(previewEntries, boxX, boxY, previewWidth, previewHeight, previewGap, labelFont)

    love.graphics.setColor(0.05, 0.05, 0.06, 0.96)
    love.graphics.rectangle("fill", boxX, bubbleY, totalWidth, bubbleHeight, 6, 6)
    love.graphics.setColor(0.82, 0.85, 0.89, 0.82)
    love.graphics.rectangle("line", boxX, bubbleY, totalWidth, bubbleHeight, 6, 6)

    love.graphics.setFont(labelFont)
    love.graphics.setColor(0.95, 0.96, 0.98, 1)
    love.graphics.printf(
        labelText or "SUMMON",
        boxX + SPECIAL_TOOLTIP_PADDING,
        snap(bubbleY + ((bubbleHeight - labelFont:getHeight()) / 2)),
        totalWidth - (SPECIAL_TOOLTIP_PADDING * 2),
        "center"
    )

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

function previewdraw.drawTomeSpawnTooltip(previewCardDefinition, anchorX, anchorY, anchorWidth, anchorHeight)
    if not previewCardDefinition then
        return
    end

    previewdraw.drawSummonPreviewTooltip({ previewCardDefinition }, anchorX, anchorY, anchorWidth, anchorHeight)
end

return previewdraw
