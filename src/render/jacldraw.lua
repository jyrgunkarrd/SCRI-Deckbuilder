local carddraw = require("src.render.carddraw")
local envassets = require("src.render.envassets")
local handdraw = require("src.render.handdraw")

local jacldraw = {}

local JACL_LABEL_FONT_PATH = "assets/fonts/Furore.otf"
local RESOURCE_COUNTER_FONT_PATH = "assets/fonts/BITSUMIS.TTF"
local ICON_IMAGE_DIRECTORY = "assets/images/icons/"
local REROLL_ICON_FILE = "reroll.png"
local PANEL_MARGIN = 24
local PANEL_LABEL_HEIGHT = 44
local PANEL_LABEL_PADDING = 14
local REROLL_BUTTON_HEIGHT = 38
local REROLL_BUTTON_GAP = 12
local JACL_SCRATCH_RESOURCE_NAME = "The Scratch"
local JACL_SCRATCH_BADGE_SIZE = 42
local JACL_SCRATCH_FOOTER_HEIGHT = 22
local JACL_SCRATCH_MARGIN = 10
local JACL_METHOD_BADGE_SIZE = 42
local JACL_METHOD_BADGE_MARGIN = 10
local JACL_SPECIAL_CURSOR_ALPHA = 0.72
local JACL_DECK_MODAL_MARGIN = 24
local JACL_DECK_MODAL_PADDING = 22
local JACL_DECK_MODAL_SECTION_GAP = 18
local JACL_DECK_MODAL_HEADER_HEIGHT = 26
local JACL_DECK_MODAL_CARD_GAP = 14
local JACL_DECK_MODAL_CARD_WIDTH = 112
local JACL_DECK_MODAL_MAX_HEIGHT_RATIO = 0.82
local iconImageCache = {}

local function snap(value)
    return math.floor(value + 0.5)
end

local function getIconImage(fileName)
    if not fileName then
        return nil
    end

    if iconImageCache[fileName] ~= nil then
        return iconImageCache[fileName] or nil
    end

    local imagePath = ICON_IMAGE_DIRECTORY .. fileName

    if not love.filesystem.getInfo(imagePath) then
        iconImageCache[fileName] = false
        return nil
    end

    local image = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    image:setFilter("linear", "linear")
    image:setMipmapFilter("linear")
    iconImageCache[fileName] = image
    return image
end

local function expandMethodEntries(methodEntries)
    local expandedResources = {}

    for _, methodEntry in ipairs(methodEntries or {}) do
        for _ = 1, (methodEntry.amount or 0) do
            expandedResources[#expandedResources + 1] = methodEntry.resource
        end
    end

    return expandedResources
end

local function buildBottomLeftPanelLayout()
    local handLayout = handdraw.getPlayerHandLayout()
    local firstHandSlot = handLayout.slots[1]
    local panelSize = firstHandSlot and firstHandSlot.height or handdraw.HAND_SLOT_HEIGHT
    local panelX = PANEL_MARGIN
    local panelY = firstHandSlot and firstHandSlot.y or (love.graphics.getHeight() - PANEL_MARGIN - panelSize)
    local scratchBadgeX = panelX + JACL_SCRATCH_MARGIN
    local scratchBadgeY = panelY + panelSize - JACL_SCRATCH_MARGIN - JACL_SCRATCH_BADGE_SIZE - JACL_SCRATCH_FOOTER_HEIGHT

    return {
        panelX = panelX,
        panelY = panelY,
        panelSize = panelSize,
        contentX = panelX,
        contentY = panelY,
        contentWidth = panelSize,
        contentHeight = panelSize,
        scratchBadgeX = scratchBadgeX,
        scratchBadgeY = scratchBadgeY,
        scratchBadgeSize = JACL_SCRATCH_BADGE_SIZE,
        scratchBadgeCenter = {
            x = scratchBadgeX + (JACL_SCRATCH_BADGE_SIZE / 2),
            y = scratchBadgeY + (JACL_SCRATCH_BADGE_SIZE / 2),
        },
    }
end

local function getJaclMethodBadgeLayout(layout, methodEntries)
    local expandedResources = expandMethodEntries(methodEntries)
    local badgeGap = math.max(2, snap(JACL_METHOD_BADGE_SIZE * 0.12))
    local totalWidth = (#expandedResources * JACL_METHOD_BADGE_SIZE) + (math.max(0, #expandedResources - 1) * badgeGap)
    local startX = layout.panelX + layout.panelSize - JACL_METHOD_BADGE_MARGIN - totalWidth
    local startY = layout.panelY + layout.panelSize - JACL_METHOD_BADGE_MARGIN - JACL_METHOD_BADGE_SIZE
    local centers = {}
    local badges = {}

    for badgeIndex, resourceName in ipairs(expandedResources) do
        local badgeX = startX + ((badgeIndex - 1) * (JACL_METHOD_BADGE_SIZE + badgeGap))

        centers[#centers + 1] = {
            resource = resourceName,
            x = badgeX + (JACL_METHOD_BADGE_SIZE / 2),
            y = startY + (JACL_METHOD_BADGE_SIZE / 2),
        }
        badges[#badges + 1] = {
            resource = resourceName,
            x = badgeX,
            y = startY,
            width = JACL_METHOD_BADGE_SIZE,
            height = JACL_METHOD_BADGE_SIZE,
        }
    end

    return startX, startY, badgeGap, centers, badges
end

function jacldraw.getBottomLeftPanelLayout(jaclDefinition)
    local layout = buildBottomLeftPanelLayout()
    local _, _, _, methodBadgeCenters, methodBadges = getJaclMethodBadgeLayout(layout, jaclDefinition and jaclDefinition.method or nil)
    layout.methodBadgeCenters = methodBadgeCenters
    layout.methodBadges = methodBadges
    return layout
end

function jacldraw.getRerollButtonLayout(jaclDefinition)
    local panelLayout = jacldraw.getBottomLeftPanelLayout(jaclDefinition)

    return {
        x = panelLayout.panelX,
        y = panelLayout.panelY - REROLL_BUTTON_GAP - REROLL_BUTTON_HEIGHT,
        width = panelLayout.panelSize,
        height = REROLL_BUTTON_HEIGHT,
    }
end

function jacldraw.drawRerollButton(jaclDefinition, rerollCount, enabled)
    local layout = jacldraw.getRerollButtonLayout(jaclDefinition)
    local labelFont = envassets.getFont(JACL_LABEL_FONT_PATH, 16)
    local rerollIcon = getIconImage(REROLL_ICON_FILE)
    local iconSize = math.max(1, snap(layout.height * 0.58))
    local valueText = tostring(rerollCount or 0)
    local gap = 8
    local valueWidth = labelFont:getWidth(valueText)
    local groupWidth = iconSize + gap + valueWidth
    local startX = snap(layout.x + ((layout.width - groupWidth) / 2))
    local iconY = snap(layout.y + ((layout.height - iconSize) / 2))
    local textY = snap(layout.y + ((layout.height - labelFont:getHeight()) / 2))

    local drawAlpha = enabled == false and 0.46 or 0.92
    local lineAlpha = enabled == false and 0.38 or 0.78
    local textAlpha = enabled == false and 0.5 or 1

    love.graphics.setColor(0.12, 0.13, 0.16, drawAlpha)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height)
    love.graphics.setColor(0.82, 0.85, 0.89, lineAlpha)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height)

    love.graphics.setFont(labelFont)
    love.graphics.setColor(1, 1, 1, textAlpha)
    if rerollIcon then
        love.graphics.draw(
            rerollIcon,
            startX,
            iconY,
            0,
            iconSize / rerollIcon:getWidth(),
            iconSize / rerollIcon:getHeight()
        )
    else
        love.graphics.rectangle("line", startX, iconY, iconSize, iconSize)
    end

    love.graphics.setColor(0.93, 0.93, 0.95, textAlpha)
    love.graphics.print(valueText, startX + iconSize + gap, textY)
    love.graphics.setColor(1, 1, 1, 1)
end

function jacldraw.drawBottomLeftPanel(jaclDefinition, resourceCounts)
    local layout = jacldraw.getBottomLeftPanelLayout(jaclDefinition)
    local labelFont = envassets.getFont(JACL_LABEL_FONT_PATH, 16)
    local counterFont = envassets.getFont(RESOURCE_COUNTER_FONT_PATH, 22)
    local scratchImage = envassets.getMethodImage(JACL_SCRATCH_RESOURCE_NAME)
    local methodBadgeX, methodBadgeY, methodBadgeGap, methodBadgeCenters = getJaclMethodBadgeLayout(layout, jaclDefinition and jaclDefinition.method or nil)
    local resourceValues = resourceCounts or {}
    local jaclImage = jaclDefinition and envassets.getJaclImage(jaclDefinition.name) or nil

    love.graphics.setColor(0.12, 0.13, 0.16, 0.9)
    love.graphics.rectangle("fill", layout.panelX, layout.panelY, layout.panelSize, layout.panelSize)

    if jaclImage then
        local scale = math.max(layout.contentWidth / jaclImage:getWidth(), layout.contentHeight / jaclImage:getHeight())
        local imageWidth = jaclImage:getWidth() * scale
        local imageHeight = jaclImage:getHeight() * scale
        local imageX = layout.contentX + ((layout.contentWidth - imageWidth) / 2)
        local imageY = layout.contentY + ((layout.contentHeight - imageHeight) / 2)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(jaclImage, imageX, imageY, 0, scale, scale)
    end

    love.graphics.setColor(0.82, 0.85, 0.89, 0.7)
    love.graphics.rectangle("line", layout.panelX, layout.panelY, layout.panelSize, layout.panelSize)

    if jaclDefinition and jaclDefinition.name then
        love.graphics.setColor(0.22, 0.22, 0.26, 0.94)
        love.graphics.rectangle("fill", layout.panelX, layout.panelY, layout.panelSize, PANEL_LABEL_HEIGHT)
        love.graphics.setColor(0.93, 0.93, 0.95, 0.94)
        love.graphics.rectangle("line", layout.panelX, layout.panelY, layout.panelSize, PANEL_LABEL_HEIGHT)
        love.graphics.setColor(0.93, 0.93, 0.95, 1)
        love.graphics.setFont(labelFont)
        love.graphics.printf(
            jaclDefinition.name,
            layout.panelX + PANEL_LABEL_PADDING,
            layout.panelY + ((PANEL_LABEL_HEIGHT - labelFont:getHeight()) / 2),
            layout.panelSize - (PANEL_LABEL_PADDING * 2),
            "center"
        )
    end

    for badgeIndex, badgeCenter in ipairs(methodBadgeCenters) do
        local badgeX = methodBadgeX + ((badgeIndex - 1) * (JACL_METHOD_BADGE_SIZE + methodBadgeGap))
        local methodImage = envassets.getMethodImage(badgeCenter.resource)
        local isUsedMethodAbility = jaclDefinition
            and jaclDefinition.usedMethodAbilities
            and jaclDefinition.usedMethodAbilities[badgeCenter.resource] == true
            or false
        local badgeAlpha = isUsedMethodAbility and 0.34 or 1

        love.graphics.setColor(0.12, 0.13, 0.16, 0.95 * badgeAlpha)
        love.graphics.rectangle("fill", badgeX, methodBadgeY, JACL_METHOD_BADGE_SIZE, JACL_METHOD_BADGE_SIZE)
        love.graphics.setColor(0.87, 0.87, 0.9, 0.9 * badgeAlpha)
        love.graphics.rectangle("line", badgeX, methodBadgeY, JACL_METHOD_BADGE_SIZE, JACL_METHOD_BADGE_SIZE)

        if methodImage then
            local imageScale = math.min(JACL_METHOD_BADGE_SIZE / methodImage:getWidth(), JACL_METHOD_BADGE_SIZE / methodImage:getHeight())
            local imageWidth = methodImage:getWidth() * imageScale
            local imageHeight = methodImage:getHeight() * imageScale
            local imageX = badgeX + ((JACL_METHOD_BADGE_SIZE - imageWidth) / 2)
            local imageY = methodBadgeY + ((JACL_METHOD_BADGE_SIZE - imageHeight) / 2)

            love.graphics.setColor(1, 1, 1, badgeAlpha)
            love.graphics.draw(methodImage, imageX, imageY, 0, imageScale, imageScale)
        end

        if isUsedMethodAbility then
            love.graphics.setColor(0, 0, 0, 0.42)
            love.graphics.rectangle("fill", badgeX, methodBadgeY, JACL_METHOD_BADGE_SIZE, JACL_METHOD_BADGE_SIZE)
            love.graphics.setColor(0.42, 0.44, 0.48, 0.78)
            love.graphics.line(
                badgeX + 4,
                methodBadgeY + JACL_METHOD_BADGE_SIZE - 4,
                badgeX + JACL_METHOD_BADGE_SIZE - 4,
                methodBadgeY + 4
            )
        end
    end

    love.graphics.setColor(0.12, 0.13, 0.16, 0.95)
    love.graphics.rectangle("fill", layout.scratchBadgeX, layout.scratchBadgeY, JACL_SCRATCH_BADGE_SIZE, JACL_SCRATCH_BADGE_SIZE)
    love.graphics.setColor(0.87, 0.87, 0.9, 0.9)
    love.graphics.rectangle("line", layout.scratchBadgeX, layout.scratchBadgeY, JACL_SCRATCH_BADGE_SIZE, JACL_SCRATCH_BADGE_SIZE)

    if scratchImage then
        local imageScale = math.min(JACL_SCRATCH_BADGE_SIZE / scratchImage:getWidth(), JACL_SCRATCH_BADGE_SIZE / scratchImage:getHeight())
        local imageWidth = scratchImage:getWidth() * imageScale
        local imageHeight = scratchImage:getHeight() * imageScale
        local imageX = layout.scratchBadgeX + ((JACL_SCRATCH_BADGE_SIZE - imageWidth) / 2)
        local imageY = layout.scratchBadgeY + ((JACL_SCRATCH_BADGE_SIZE - imageHeight) / 2)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(scratchImage, imageX, imageY, 0, imageScale, imageScale)
    end

    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", layout.scratchBadgeX, layout.scratchBadgeY + JACL_SCRATCH_BADGE_SIZE, JACL_SCRATCH_BADGE_SIZE, JACL_SCRATCH_FOOTER_HEIGHT)
    love.graphics.setColor(0.87, 0.87, 0.9, 0.9)
    love.graphics.rectangle("line", layout.scratchBadgeX, layout.scratchBadgeY + JACL_SCRATCH_BADGE_SIZE, JACL_SCRATCH_BADGE_SIZE, JACL_SCRATCH_FOOTER_HEIGHT)
    love.graphics.setColor(0.95, 0.96, 0.98, 1)
    love.graphics.setFont(counterFont)
    love.graphics.printf(
        tostring(resourceValues[JACL_SCRATCH_RESOURCE_NAME] or 0),
        layout.scratchBadgeX,
        math.floor(layout.scratchBadgeY + JACL_SCRATCH_BADGE_SIZE + ((JACL_SCRATCH_FOOTER_HEIGHT - counterFont:getHeight()) / 2) - 0.5),
        JACL_SCRATCH_BADGE_SIZE,
        "center"
    )
    love.graphics.setColor(1, 1, 1, 1)
end

function jacldraw.getJaclMethodBadgeAt(mouseX, mouseY, jaclDefinition)
    local layout = jacldraw.getBottomLeftPanelLayout(jaclDefinition)

    for _, badge in ipairs(layout.methodBadges or {}) do
        if mouseX >= badge.x
            and mouseX <= badge.x + badge.width
            and mouseY >= badge.y
            and mouseY <= badge.y + badge.height then
            return badge
        end
    end

    return nil
end

function jacldraw.drawFloatingMethodBadge(resourceName, centerX, centerY)
    local methodImage = envassets.getMethodImage(resourceName)
    local badgeX = centerX - (JACL_METHOD_BADGE_SIZE / 2)
    local badgeY = centerY - (JACL_METHOD_BADGE_SIZE / 2)

    love.graphics.setColor(0.12, 0.13, 0.16, JACL_SPECIAL_CURSOR_ALPHA)
    love.graphics.rectangle("fill", badgeX, badgeY, JACL_METHOD_BADGE_SIZE, JACL_METHOD_BADGE_SIZE)
    love.graphics.setColor(0.87, 0.87, 0.9, JACL_SPECIAL_CURSOR_ALPHA)
    love.graphics.rectangle("line", badgeX, badgeY, JACL_METHOD_BADGE_SIZE, JACL_METHOD_BADGE_SIZE)

    if methodImage then
        local imageScale = math.min(JACL_METHOD_BADGE_SIZE / methodImage:getWidth(), JACL_METHOD_BADGE_SIZE / methodImage:getHeight())
        local imageWidth = methodImage:getWidth() * imageScale
        local imageHeight = methodImage:getHeight() * imageScale
        local imageX = badgeX + ((JACL_METHOD_BADGE_SIZE - imageWidth) / 2)
        local imageY = badgeY + ((JACL_METHOD_BADGE_SIZE - imageHeight) / 2)

        love.graphics.setColor(1, 1, 1, JACL_SPECIAL_CURSOR_ALPHA)
        love.graphics.draw(methodImage, imageX, imageY, 0, imageScale, imageScale)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function jacldraw.getJaclDeckModalLayout(playerDeck, scrollState)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local deckCards = playerDeck and playerDeck.cards or {}
    local discardCards = playerDeck and playerDeck.discard or {}
    local sectionWidth = math.max(
        JACL_DECK_MODAL_CARD_WIDTH,
        windowWidth - ((JACL_DECK_MODAL_MARGIN + JACL_DECK_MODAL_PADDING) * 2)
    )
    local cardWidth, cardHeight = carddraw.getCardSize({
        width = JACL_DECK_MODAL_CARD_WIDTH,
        showLabelWhenCollapsed = true,
    })
    local cardsPerRow = math.max(1, math.floor((sectionWidth + JACL_DECK_MODAL_CARD_GAP) / (cardWidth + JACL_DECK_MODAL_CARD_GAP)))
    local usedSectionWidth = (cardsPerRow * cardWidth) + ((cardsPerRow - 1) * JACL_DECK_MODAL_CARD_GAP)
    local contentWidth = math.min(sectionWidth, usedSectionWidth)
    local availableModalHeight = math.max(
        (JACL_DECK_MODAL_PADDING * 2) + (JACL_DECK_MODAL_HEADER_HEIGHT * 2) + JACL_DECK_MODAL_SECTION_GAP + cardHeight,
        math.min(windowHeight - (JACL_DECK_MODAL_MARGIN * 2), windowHeight * JACL_DECK_MODAL_MAX_HEIGHT_RATIO)
    )
    local sectionViewportHeight = math.max(
        cardHeight,
        (availableModalHeight - (JACL_DECK_MODAL_PADDING * 2) - JACL_DECK_MODAL_SECTION_GAP) / 2
    )

    local function buildSection(cards, sectionScrollState)
        local rows = math.max(1, math.ceil(math.max(1, #cards) / cardsPerRow))
        local bodyContentHeight = (rows * cardHeight) + ((rows - 1) * JACL_DECK_MODAL_CARD_GAP)
        local viewportHeight = JACL_DECK_MODAL_HEADER_HEIGHT + sectionViewportHeight
        local maxScroll = math.max(0, bodyContentHeight - sectionViewportHeight)
        local scrollY = math.max(0, math.min(maxScroll, (sectionScrollState and sectionScrollState.scrollY) or 0))

        return {
            x = 0,
            y = 0,
            width = contentWidth,
            height = viewportHeight,
            cards = cards,
            cardLayouts = {},
            viewportHeight = viewportHeight,
            bodyViewportHeight = sectionViewportHeight,
            bodyContentHeight = bodyContentHeight,
            maxScroll = maxScroll,
            scrollY = scrollY,
        }
    end

    local topSection = buildSection(deckCards, scrollState and scrollState.top or nil)
    local bottomSection = buildSection(discardCards, scrollState and scrollState.bottom or nil)
    local contentHeight = topSection.height + JACL_DECK_MODAL_SECTION_GAP + bottomSection.height
    local modalWidth = contentWidth + (JACL_DECK_MODAL_PADDING * 2)
    local modalHeight = contentHeight + (JACL_DECK_MODAL_PADDING * 2)
    local modalX = (windowWidth - modalWidth) / 2
    local modalY = (windowHeight - modalHeight) / 2

    topSection.x = modalX + JACL_DECK_MODAL_PADDING
    topSection.y = modalY + JACL_DECK_MODAL_PADDING
    bottomSection.x = modalX + JACL_DECK_MODAL_PADDING
    bottomSection.y = topSection.y + topSection.height + JACL_DECK_MODAL_SECTION_GAP

    for _, section in ipairs({ topSection, bottomSection }) do
        for cardIndex, card in ipairs(section.cards) do
            local rowIndex = math.floor((cardIndex - 1) / cardsPerRow)
            local columnIndex = (cardIndex - 1) % cardsPerRow

            section.cardLayouts[#section.cardLayouts + 1] = {
                card = card,
                x = section.x + (columnIndex * (cardWidth + JACL_DECK_MODAL_CARD_GAP)),
                y = section.y + JACL_DECK_MODAL_HEADER_HEIGHT + (rowIndex * (cardHeight + JACL_DECK_MODAL_CARD_GAP)) - section.scrollY,
                width = cardWidth,
            }
        end
    end

    return {
        x = modalX,
        y = modalY,
        width = modalWidth,
        height = modalHeight,
        topSection = topSection,
        bottomSection = bottomSection,
        cardWidth = cardWidth,
        cardHeight = cardHeight,
    }
end

function jacldraw.drawJaclDeckModal(playerDeck, scrollState)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local layout = jacldraw.getJaclDeckModalLayout(playerDeck, scrollState)
    local previousFont = love.graphics.getFont()
    local headerFont = envassets.getFont(JACL_LABEL_FONT_PATH, 18)

    local function drawSection(section, title, cards)
        love.graphics.setColor(0.09, 0.1, 0.13, 0.94)
        love.graphics.rectangle("fill", section.x, section.y, section.width, section.height, 8, 8)
        love.graphics.setColor(0.82, 0.85, 0.89, 0.42)
        love.graphics.rectangle("line", section.x, section.y, section.width, section.height, 8, 8)
        love.graphics.setFont(headerFont)
        love.graphics.setColor(0.93, 0.93, 0.95, 1)
        love.graphics.print(title .. " (" .. tostring(#cards) .. ")", section.x + 10, section.y + ((JACL_DECK_MODAL_HEADER_HEIGHT - headerFont:getHeight()) / 2))

        love.graphics.setScissor(
            math.floor(section.x),
            math.floor(section.y + JACL_DECK_MODAL_HEADER_HEIGHT),
            math.max(1, math.floor(section.width)),
            math.max(1, math.floor(section.bodyViewportHeight))
        )
        for _, cardLayout in ipairs(section.cardLayouts) do
            carddraw.drawCardState(cardLayout.card.setName, cardLayout.card.cardId, cardLayout.x, cardLayout.y, 0, {
                width = cardLayout.width,
                showLabelWhenCollapsed = true,
                showHealthOnPortrait = false,
                showBadgesInTextbox = true,
                showEmphasisOnPortrait = true,
                displayName = cardLayout.card.displayName,
                portraitPath = cardLayout.card.portraitPath,
            })
        end
        love.graphics.setScissor()

        if section.maxScroll > 0 then
            local trackHeight = math.max(24, section.bodyViewportHeight)
            local thumbHeight = math.max(20, trackHeight * (section.bodyViewportHeight / section.bodyContentHeight))
            local thumbTravel = math.max(0, trackHeight - thumbHeight)
            local thumbY = section.y + JACL_DECK_MODAL_HEADER_HEIGHT + (thumbTravel * (section.scrollY / section.maxScroll))

            love.graphics.setColor(0.22, 0.24, 0.29, 0.9)
            love.graphics.rectangle("fill", section.x + section.width - 6, section.y + JACL_DECK_MODAL_HEADER_HEIGHT + 4, 3, trackHeight - 8, 2, 2)
            love.graphics.setColor(0.88, 0.9, 0.94, 0.8)
            love.graphics.rectangle("fill", section.x + section.width - 7, thumbY + 4, 5, math.max(12, thumbHeight - 8), 2, 2)
        end
    end

    love.graphics.setColor(0.01, 0.01, 0.02, 0.72)
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    love.graphics.setColor(0.06, 0.07, 0.09, 0.96)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height, 10, 10)
    love.graphics.setColor(0.82, 0.85, 0.89, 0.78)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height, 10, 10)
    drawSection(layout.topSection, "Deck", playerDeck and playerDeck.cards or {})
    drawSection(layout.bottomSection, "Discard", playerDeck and playerDeck.discard or {})
    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

function jacldraw.getJaclDeckModalSectionAt(mouseX, mouseY, playerDeck, scrollState)
    local layout = jacldraw.getJaclDeckModalLayout(playerDeck, scrollState)

    for sectionId, section in pairs({
        deck = layout.topSection,
        discard = layout.bottomSection,
    }) do
        if mouseX >= section.x
            and mouseX <= section.x + section.width
            and mouseY >= section.y
            and mouseY <= section.y + section.height then
            return sectionId, section
        end
    end

    return nil, nil
end

function jacldraw.getJaclDeckModalCardAt(mouseX, mouseY, playerDeck, scrollState)
    local layout = jacldraw.getJaclDeckModalLayout(playerDeck, scrollState)

    for _, section in ipairs({ layout.topSection, layout.bottomSection }) do
        for _, cardLayout in ipairs(section.cardLayouts) do
            if carddraw.isPointInsideCard(mouseX, mouseY, cardLayout.x, cardLayout.y, 0, {
                width = cardLayout.width,
                showLabelWhenCollapsed = true,
                showHealthOnPortrait = false,
                showBadgesInTextbox = true,
            }) then
                return cardLayout.card
            end
        end
    end

    return nil
end

return jacldraw
