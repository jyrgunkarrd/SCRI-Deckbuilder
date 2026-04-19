local carddraw = {}
local diceDefinitions = require("data.dice")
local keywordDefinitions = require("data.keywords")
local jaclDefinitions = require("data.jacl")
local cardregistry = require("src.system.cardregistry")

local CARD_IMAGE_DIRECTORY = "assets/images/cards/"
local KEYWORD_IMAGE_DIRECTORY = "assets/images/cards/keywords/"
local DICE_IMAGE_DIRECTORY = "assets/images/dice/"
local METHOD_IMAGE_DIRECTORY = "assets/images/method/"
local OBJECTIVE_IMAGE_DIRECTORY = "assets/images/objectives/"
local WARZONE_IMAGE_DIRECTORY = "assets/images/warzone/"
local JACL_IMAGE_DIRECTORY = "assets/images/jacl/"
local OVERLAY_IMAGE_DIRECTORY = "assets/images/cards/overlays/"
local CARD_FONT_PATH = "assets/fonts/Furore.otf"
local CARD_FLAVOR_FONT_PATH = "assets/fonts/DejaVuSans-Oblique.ttf"
local CARD_WIDTH = 220
local CARD_LABEL_HEIGHT = 44
local CARD_TEXTBOX_HEIGHT = CARD_WIDTH
local CARD_COLLAPSED_HEIGHT = CARD_WIDTH + CARD_LABEL_HEIGHT
local CARD_EXPANDED_HEIGHT = CARD_COLLAPSED_HEIGHT + CARD_TEXTBOX_HEIGHT
local CARD_PADDING = 14
local CARD_TEXTBOX_FOOTER_HEIGHT = 34
local CARD_FLAVOR_GAP = 8
local HAND_BADGE_SCALE = 1.12
local GRID_ROLL_BADGE_SCALE = 1.15
local BADGE_HEADER_FONT_SCALE = 1.12
local PORTRAIT_BADGE_HEADER_FONT_SCALE = 0.92
local GRID_LABEL_FONT_SCALE = 1.1
local GRID_TEXTBOX_FONT_SCALE = 1.1
local GRID_HEALTH_FONT_SCALE = 1.1
local CARD_LABEL_MIN_FONT_SIZE = 8
local CARD_CLASS_LABEL_MIN_FONT_SIZE = 7
local COST_BADGE_SIZE_RATIO = 0.18
local COST_BADGE_GAP_RATIO = 0.03
local COST_BADGE_MARGIN_RATIO = 0.03
local BADGE_DOT_BODY_BUFFER_RATIO = 0.08
local HEALTH_PIP_COLUMNS = 20
local HEALTH_PIP_MAX_SIZE_RATIO = 0.18
local BADGE_TOP_PIP_MAX_SIZE_RATIO = 0.1
local BADGE_BOTTOM_PIP_MAX_SIZE_RATIO = 0.09
local HAND_BADGE_BOTTOM_PIP_MAX_SCALE = 0.88
local KEYWORD_TOOLTIP_NAME_FONT_SIZE = 14
local KEYWORD_TOOLTIP_TEXT_FONT_SIZE = 12
local KEYWORD_TOOLTIP_MAX_WIDTH = 260
local KEYWORD_TOOLTIP_PADDING = 10
local KEYWORD_TOOLTIP_OFFSET_X = 18
local KEYWORD_TOOLTIP_OFFSET_Y = 18
local BADGE_PIP_COLOR_ONE = { 1, 1, 1, 1 }
local BADGE_PIP_COLOR_FIVE = { 1, 0.847, 0.219, 1 }
local BADGE_PIP_COLOR_TWENTY_FIVE = { 1, 0.369, 0.369, 1 }
local DAMAGE_PREVIEW_PIP_COLOR = { 1, 0.298, 0.298, 1 }
local KIA_BADGE_TEXT_COLOR = { 0.902, 0.2, 0.416, 1 }
local STRATEGIST_KEYWORD_ID = "KWSTRAT"
local TOME_CARD_TYPE = "tome"
local TROOP_HEALTH_PIP_COLOR = { 0, 1, 0.839 }
local SYNTAC_PIP_COLOR = { 0.58, 0.9, 0.96 }
local HUNTER_OUTLINE_COLOR = { 0.82, 0.16, 0.16, 1 }
local HUNTER_LABEL_FILL_COLOR = { 0.02, 0.02, 0.03, 1 }
local HUNTER_LABEL_TEXT_COLOR = { 0.9, 0.22, 0.22, 1 }
local HUNTER_EMPHASIS_BADGE_FILL_COLOR = { 0.02, 0.02, 0.03, 0.96 }
local HUNTER_EMPHASIS_BADGE_TEXT_COLOR = { 0.92, 0.24, 0.24, 1 }
local ALLY_OUTLINE_COLOR = { 0, 0.9176, 0.7647, 1 }
local ALLY_LABEL_FILL_COLOR = { 0.02, 0.02, 0.03, 1 }
local ALLY_LABEL_TEXT_COLOR = { 0, 0.9176, 0.7647, 1 }
local KIA_BADGE_PULSE_SPEED = 4.5
local KIA_BADGE_PULSE_MIN = 0.92
local KIA_BADGE_PULSE_MAX = 1.06
local PROGRESS_OVERLAY_PULSE_MIN = 0.92
local PROGRESS_OVERLAY_PULSE_MAX = 1.08

local portraitCache = {}
local keywordImageCache = {}
local diceImageCache = {}
local methodImageCache = {}
local overlayImageCache = {}
local objectiveImageCache = {}
local warzoneImageCache = {}
local jaclImageCache = {}
local fontCache = {}
local keywordsById = nil
local getCardFont
local getFont

local function lerp(a, b, t)
    return a + ((b - a) * t)
end

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function snap(value)
    return math.floor(value + 0.5)
end

local function getRenderOptions(options)
    options = options or {}

    return {
        width = options.width or CARD_WIDTH,
        showLabelWhenCollapsed = options.showLabelWhenCollapsed ~= false,
        showHealthOnPortrait = options.showHealthOnPortrait == true,
        showEmphasisOnPortrait = options.showEmphasisOnPortrait == true,
        healthFontScale = options.healthFontScale or 1,
        showBadgesInTextbox = options.showBadgesInTextbox == true,
        damagePreviewCount = options.damagePreviewCount or 0,
        blockedDamagePreviewCount = options.blockedDamagePreviewCount or 0,
        currentHealth = options.currentHealth,
        maxHealth = options.maxHealth,
        blocking = options.blocking,
        keywordValues = options.keywordValues,
        lethalPreviewOverkill = options.lethalPreviewOverkill,
        destructionProgress = options.destructionProgress,
        destructionSeed = options.destructionSeed,
        displayName = options.displayName,
        portraitPath = options.portraitPath,
    }
end

local function getCardMetrics(options)
    local renderOptions = getRenderOptions(options)
    local scale = renderOptions.width / CARD_WIDTH
    local labelHeight = CARD_LABEL_HEIGHT * scale
    local textboxHeight = CARD_TEXTBOX_HEIGHT * scale
    local padding = CARD_PADDING * scale
    local footerHeight = CARD_TEXTBOX_FOOTER_HEIGHT * scale
    local collapsedHeight = renderOptions.width

    if renderOptions.showLabelWhenCollapsed then
        collapsedHeight = collapsedHeight + labelHeight
    end

    return {
        width = renderOptions.width,
        portraitHeight = renderOptions.width,
        labelHeight = labelHeight,
        textboxHeight = textboxHeight,
        padding = padding,
        footerHeight = footerHeight,
        collapsedHeight = collapsedHeight,
        expandedHeight = renderOptions.width + labelHeight + textboxHeight,
        showLabelWhenCollapsed = renderOptions.showLabelWhenCollapsed,
        showHealthOnPortrait = renderOptions.showHealthOnPortrait,
        showEmphasisOnPortrait = renderOptions.showEmphasisOnPortrait == true,
        healthFontScale = renderOptions.healthFontScale,
        showBadgesInTextbox = renderOptions.showBadgesInTextbox,
        damagePreviewCount = renderOptions.damagePreviewCount,
        blockedDamagePreviewCount = renderOptions.blockedDamagePreviewCount,
        currentHealth = renderOptions.currentHealth,
        maxHealth = renderOptions.maxHealth,
        blocking = renderOptions.blocking,
        keywordValues = renderOptions.keywordValues,
        lethalPreviewOverkill = renderOptions.lethalPreviewOverkill,
        destructionProgress = renderOptions.destructionProgress,
        destructionSeed = renderOptions.destructionSeed,
        displayName = renderOptions.displayName,
        portraitPath = renderOptions.portraitPath,
    }
end

local function getCardStyle(cardDefinition)
    if cardDefinition and cardDefinition.type == "hunter" then
        return {
            outlineColor = HUNTER_OUTLINE_COLOR,
            labelFillColor = HUNTER_LABEL_FILL_COLOR,
            labelTextColor = HUNTER_LABEL_TEXT_COLOR,
        }
    end

    if cardDefinition and cardDefinition.type == "ally" then
        return {
            outlineColor = ALLY_OUTLINE_COLOR,
            labelFillColor = ALLY_LABEL_FILL_COLOR,
            labelTextColor = ALLY_LABEL_TEXT_COLOR,
        }
    end

    return {
        outlineColor = { 0.87, 0.87, 0.9, 1 },
        labelFillColor = { 0.22, 0.22, 0.26, 1 },
        labelTextColor = { 0.93, 0.93, 0.95, 1 },
    }
end

local function drawPortraitEmphasisBadge(cardDefinition, drawX, drawY, renderWidth, portraitHeight)
    if not cardDefinition or cardDefinition.emphasis == nil then
        return
    end

    local badgeSize = math.max(20, snap(renderWidth * 0.18))
    local badgeInset = math.max(4, snap(renderWidth * 0.03))
    local badgeX = snap(drawX + renderWidth - badgeInset - badgeSize)
    local badgeY = snap(drawY + portraitHeight - badgeInset - badgeSize)
    local badgeFont = getCardFont(math.max(10, snap(badgeSize * 0.44)))
    local valueText = tostring(cardDefinition.emphasis)
    local textY = snap(badgeY + ((badgeSize - badgeFont:getHeight()) / 2))

    love.graphics.setColor(HUNTER_EMPHASIS_BADGE_FILL_COLOR[1], HUNTER_EMPHASIS_BADGE_FILL_COLOR[2], HUNTER_EMPHASIS_BADGE_FILL_COLOR[3], HUNTER_EMPHASIS_BADGE_FILL_COLOR[4])
    love.graphics.rectangle("fill", badgeX, badgeY, badgeSize, badgeSize, 4, 4)
    love.graphics.setColor(HUNTER_OUTLINE_COLOR[1], HUNTER_OUTLINE_COLOR[2], HUNTER_OUTLINE_COLOR[3], 0.95)
    love.graphics.rectangle("line", badgeX, badgeY, badgeSize, badgeSize, 4, 4)
    love.graphics.setColor(HUNTER_EMPHASIS_BADGE_TEXT_COLOR[1], HUNTER_EMPHASIS_BADGE_TEXT_COLOR[2], HUNTER_EMPHASIS_BADGE_TEXT_COLOR[3], HUNTER_EMPHASIS_BADGE_TEXT_COLOR[4])
    love.graphics.setFont(badgeFont)
    love.graphics.printf(valueText, badgeX, textY, badgeSize, "center")
end

local function getTypographyScale(renderOptions)
    if renderOptions.showHealthOnPortrait then
        return GRID_LABEL_FONT_SCALE, GRID_TEXTBOX_FONT_SCALE, GRID_HEALTH_FONT_SCALE
    end

    return 1, 1, 1
end

getCardFont = function(size)
    if fontCache[size] ~= nil then
        return fontCache[size]
    end

    fontCache[size] = love.graphics.newFont(CARD_FONT_PATH, size)
    return fontCache[size]
end

local function getFittedCardFontForBox(text, targetSize, maxWidth, maxHeight, minSize)
    local minimumSize = minSize or CARD_LABEL_MIN_FONT_SIZE
    local fontSize = math.max(minimumSize, targetSize)
    local fittedFont = getCardFont(fontSize)

    while fontSize > minimumSize do
        local _, wrappedLines = fittedFont:getWrap(text, maxWidth)
        local wrappedHeight = #wrappedLines * fittedFont:getHeight()

        if wrappedHeight <= maxHeight then
            return fittedFont
        end

        fontSize = fontSize - 1
        fittedFont = getCardFont(fontSize)
    end

    return fittedFont
end

local function getFlavorFont(size, fallbackFont)
    local ok, font = pcall(getFont, CARD_FLAVOR_FONT_PATH, size)

    if ok and font then
        return font
    end

    return fallbackFont
end

local function getFittedCardFont(text, targetSize, maxWidth, minSize)
    return getFittedCardFontForBox(text, targetSize, maxWidth, math.huge, minSize)
end

local function getCardClassLine(cardDefinition)
    if not cardDefinition or not cardDefinition.classname or not cardDefinition.subclass then
        return nil
    end

    return tostring(cardDefinition.classname) .. " - " .. tostring(cardDefinition.subclass)
end

function getFont(path, size)
    local cacheKey = path .. ":" .. size

    if fontCache[cacheKey] ~= nil then
        return fontCache[cacheKey]
    end

    fontCache[cacheKey] = love.graphics.newFont(path, size)
    return fontCache[cacheKey]
end

local function getCardDefinition(setName, cardId)
    return cardregistry.getCard(setName, cardId)
end

local function getDiceDefinition(diceId)
    if not diceId then
        return nil
    end

    for _, definition in ipairs(diceDefinitions) do
        if definition.id == diceId then
            return definition
        end
    end

    return nil
end

local function loadKeywords()
    if keywordsById ~= nil then
        return
    end

    keywordsById = {}

    for _, definition in ipairs(keywordDefinitions or {}) do
        if definition.id then
            keywordsById[definition.id] = definition
        end
    end
end

local function getKeywordDefinition(keywordId)
    if not keywordId then
        return nil
    end

    loadKeywords()
    return keywordsById[keywordId]
end

local function getCardKeywordIds(cardDefinition)
    if not cardDefinition then
        return {}
    end

    local keywordIds = {}

    if type(cardDefinition.keyword) == "table" then
        for _, keywordId in ipairs(cardDefinition.keyword) do
            if keywordId then
                keywordIds[#keywordIds + 1] = keywordId
            end
        end
    elseif cardDefinition.keyword ~= nil then
        keywordIds[#keywordIds + 1] = cardDefinition.keyword
    end

    if cardDefinition.type == "strategy" then
        local hasStrategistKeyword = false

        for _, keywordId in ipairs(keywordIds) do
            if keywordId == STRATEGIST_KEYWORD_ID then
                hasStrategistKeyword = true
                break
            end
        end

        if not hasStrategistKeyword then
            table.insert(keywordIds, 1, STRATEGIST_KEYWORD_ID)
        end
    end

    return keywordIds
end

local function getCardKeywordDefaultValue(cardDefinition, keywordId)
    if not cardDefinition or not keywordId then
        return nil
    end

    if type(cardDefinition.kwval) == "table" then
        return tonumber(cardDefinition.kwval[keywordId]) or 0
    end

    return tonumber(cardDefinition.kwval) or 0
end

local function getBadgeDefinitions(cardDefinition)
    local badgeDefinitions = {}

    for faceIndex = 1, 6 do
        badgeDefinitions[faceIndex] = getDiceDefinition(cardDefinition["D" .. faceIndex])
    end

    return badgeDefinitions
end

local function getAssignedFaceIndices(cardDefinition)
    local faceIndices = {}

    if not cardDefinition then
        return faceIndices
    end

    for faceIndex = 1, 6 do
        if getDiceDefinition(cardDefinition["D" .. faceIndex]) then
            faceIndices[#faceIndices + 1] = faceIndex
        end
    end

    return faceIndices
end

local function hasDefinitionFaceBadges(cardDefinition)
    return #getAssignedFaceIndices(cardDefinition) > 0
end

local function getDiceImage(diceDefinition)
    if not diceDefinition or not diceDefinition.type then
        return nil
    end

    local cacheKey = diceDefinition.type

    if diceImageCache[cacheKey] ~= nil then
        return diceImageCache[cacheKey]
    end

    local imagePath = DICE_IMAGE_DIRECTORY .. diceDefinition.type .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        diceImageCache[cacheKey] = false
        return nil
    end

    diceImageCache[cacheKey] = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    diceImageCache[cacheKey]:setFilter("linear", "linear")
    return diceImageCache[cacheKey]
end

local function getKeywordImage(keywordId)
    if not keywordId then
        return nil
    end

    if keywordImageCache[keywordId] ~= nil then
        return keywordImageCache[keywordId]
    end

    local imagePath = KEYWORD_IMAGE_DIRECTORY .. keywordId .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        keywordImageCache[keywordId] = false
        return nil
    end

    keywordImageCache[keywordId] = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    keywordImageCache[keywordId]:setFilter("linear", "linear")
    return keywordImageCache[keywordId]
end

local function getObjectiveImage(objectiveId)
    if not objectiveId then
        return nil
    end

    if objectiveImageCache[objectiveId] ~= nil then
        return objectiveImageCache[objectiveId]
    end

    local imagePath = OBJECTIVE_IMAGE_DIRECTORY .. objectiveId .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        objectiveImageCache[objectiveId] = false
        return nil
    end

    objectiveImageCache[objectiveId] = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    objectiveImageCache[objectiveId]:setFilter("linear", "linear")
    return objectiveImageCache[objectiveId]
end

local function getWarzoneImage(warzoneId)
    if not warzoneId then
        return nil
    end

    if warzoneImageCache[warzoneId] ~= nil then
        return warzoneImageCache[warzoneId]
    end

    local imagePath = WARZONE_IMAGE_DIRECTORY .. warzoneId .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        warzoneImageCache[warzoneId] = false
        return nil
    end

    warzoneImageCache[warzoneId] = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    warzoneImageCache[warzoneId]:setFilter("linear", "linear")
    return warzoneImageCache[warzoneId]
end

local function getDefaultJaclName()
    local playerJacl = jaclDefinitions and jaclDefinitions[1] or nil
    return playerJacl and playerJacl.name or nil
end

local function getJaclImage(jaclName)
    if not jaclName then
        return nil
    end

    if jaclImageCache[jaclName] ~= nil then
        return jaclImageCache[jaclName]
    end

    local imagePath = JACL_IMAGE_DIRECTORY .. jaclName .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        jaclImageCache[jaclName] = false
        return nil
    end

    jaclImageCache[jaclName] = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    jaclImageCache[jaclName]:setFilter("linear", "linear")
    return jaclImageCache[jaclName]
end

local function getMethodImage(methodName)
    if not methodName then
        return nil
    end

    if methodImageCache[methodName] ~= nil then
        return methodImageCache[methodName]
    end

    local imagePath = METHOD_IMAGE_DIRECTORY .. methodName .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        methodImageCache[methodName] = false
        return nil
    end

    methodImageCache[methodName] = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    methodImageCache[methodName]:setFilter("linear", "linear")
    return methodImageCache[methodName]
end

local function getOverlayImage(overlayName)
    if not overlayName then
        return nil
    end

    if overlayImageCache[overlayName] ~= nil then
        return overlayImageCache[overlayName]
    end

    local imagePath = OVERLAY_IMAGE_DIRECTORY .. overlayName .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        overlayImageCache[overlayName] = false
        return nil
    end

    overlayImageCache[overlayName] = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    overlayImageCache[overlayName]:setFilter("linear", "linear")
    return overlayImageCache[overlayName]
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

local function getPortraitDirectory(cardDefinition, setName)
    local candidates = {
        setName,
        cardDefinition.type,
        cardDefinition.type and (cardDefinition.type .. "s") or nil,
    }

    for _, candidate in ipairs(candidates) do
        if candidate then
            local path = CARD_IMAGE_DIRECTORY .. candidate .. "/" .. cardDefinition.id .. ".png"

            if love.filesystem.getInfo(path) then
                return candidate
            end
        end
    end

    return nil
end

local function getPortrait(cardDefinition, setName)
    local portraitKey = setName .. ":" .. cardDefinition.id

    if portraitCache[portraitKey] ~= nil then
        return portraitCache[portraitKey]
    end

    local portraitDirectory = getPortraitDirectory(cardDefinition, setName)

    if not portraitDirectory then
        portraitCache[portraitKey] = false
        return nil
    end

    local portraitPath = CARD_IMAGE_DIRECTORY .. portraitDirectory .. "/" .. cardDefinition.id .. ".png"
    portraitCache[portraitKey] = love.graphics.newImage(portraitPath, {
        mipmaps = true,
    })
    portraitCache[portraitKey]:setFilter("linear", "linear")
    return portraitCache[portraitKey]
end

local function getPortraitByPath(portraitPath)
    if not portraitPath then
        return nil
    end

    local portraitKey = "path:" .. portraitPath

    if portraitCache[portraitKey] ~= nil then
        return portraitCache[portraitKey]
    end

    if not love.filesystem.getInfo(portraitPath) then
        portraitCache[portraitKey] = false
        return nil
    end

    portraitCache[portraitKey] = love.graphics.newImage(portraitPath, {
        mipmaps = true,
    })
    portraitCache[portraitKey]:setFilter("linear", "linear")
    return portraitCache[portraitKey]
end

local function getMethodBadgeLayout(width, footerHeight, padding, methodEntries)
    local expandedResources = expandMethodEntries(methodEntries)
    local badgeInset = math.max(2, snap(footerHeight * 0.08))
    local badgeSize = math.max(0, footerHeight - (badgeInset * 2))
    local badgeGap = math.max(2, snap(badgeSize * 0.12))
    local totalWidth = (#expandedResources * badgeSize) + (math.max(0, #expandedResources - 1) * badgeGap)

    return expandedResources, badgeInset, badgeSize, badgeGap, totalWidth
end

local function drawHealthFooter(x, y, width, height, padding, footerHeight, footerFont, healthValue, maxHealthValue, damagePreviewCount, blockedDamagePreviewCount, blockingValue, alpha, methodEntries, pipColor)
    local footerY = y + height - footerHeight
    local expandedResources, badgeInset, badgeSize, badgeGap, totalBadgeWidth = getMethodBadgeLayout(width, footerHeight, padding, methodEntries)
    local badgesStartX = x + width - padding - totalBadgeWidth
    local textWidth = width - (padding * 2)
    local footerPipColor = pipColor or TROOP_HEALTH_PIP_COLOR

    love.graphics.setColor(0, 0, 0, alpha)
    love.graphics.rectangle("fill", x, footerY, width, footerHeight)
    love.graphics.setColor(0.87, 0.87, 0.9, alpha)
    love.graphics.rectangle("line", x, footerY, width, footerHeight)

    if #expandedResources > 0 then
        textWidth = width - (padding * 2) - totalBadgeWidth - badgeInset

        for resourceIndex, resourceName in ipairs(expandedResources) do
            local methodImage = getMethodImage(resourceName)
            local badgeX = badgesStartX + ((resourceIndex - 1) * (badgeSize + badgeGap))
            local badgeY = footerY + badgeInset

            love.graphics.setColor(0.12, 0.13, 0.16, alpha)
            love.graphics.rectangle("fill", badgeX, badgeY, badgeSize, badgeSize, 3, 3)
            love.graphics.setColor(0.87, 0.87, 0.9, alpha)
            love.graphics.rectangle("line", badgeX, badgeY, badgeSize, badgeSize, 3, 3)

            if methodImage then
                local imageScale = math.min(badgeSize / methodImage:getWidth(), badgeSize / methodImage:getHeight())
                local imageWidth = methodImage:getWidth() * imageScale
                local imageHeight = methodImage:getHeight() * imageScale
                local imageX = badgeX + ((badgeSize - imageWidth) / 2)
                local imageY = badgeY + ((badgeSize - imageHeight) / 2)

                love.graphics.setColor(1, 1, 1, alpha)
                love.graphics.draw(methodImage, imageX, imageY, 0, imageScale, imageScale)
            end
        end
    end

    local pipCount = math.max(0, tonumber(healthValue) or 0)
    local maxPipCount = math.max(pipCount, math.max(0, tonumber(maxHealthValue) or 0))
    local blockPipCount = math.max(0, tonumber(blockingValue) or 0)
    local maxTrackPipCount = math.max(maxPipCount, blockPipCount)

    if maxTrackPipCount <= 0 then
        return
    end

    local columnCount = math.min(HEALTH_PIP_COLUMNS, maxTrackPipCount)
    local healthRowCount = math.max(1, math.ceil(maxPipCount / HEALTH_PIP_COLUMNS))
    local blockRowCount = blockPipCount > 0 and math.max(1, math.ceil(blockPipCount / HEALTH_PIP_COLUMNS)) or 0
    local rowCount = healthRowCount + blockRowCount
    local pipGap = math.max(1, snap(footerHeight * 0.08))
    local availableWidth = math.max(1, textWidth)
    local availableHeight = math.max(1, footerHeight - 4)
    local pipSizeByWidth = (availableWidth - ((columnCount - 1) * pipGap)) / columnCount
    local pipSizeByHeight = (availableHeight - ((rowCount - 1) * pipGap)) / rowCount
    local maxDefaultPipSize = math.max(2, snap(footerHeight * HEALTH_PIP_MAX_SIZE_RATIO))
    local pipSize = math.max(2, snap(math.min(pipSizeByWidth, pipSizeByHeight, maxDefaultPipSize)))
    local totalGridWidth = (columnCount * pipSize) + ((columnCount - 1) * pipGap)
    local totalGridHeight = (rowCount * pipSize) + ((rowCount - 1) * pipGap)
    local startX = snap(x + padding + ((availableWidth - totalGridWidth) / 2))
    local startY = snap(footerY + ((footerHeight - totalGridHeight) / 2))

    local function getPipPosition(pipIndex, rowOffset)
        local row = math.floor(pipIndex / HEALTH_PIP_COLUMNS) + (rowOffset or 0)
        local column = pipIndex % HEALTH_PIP_COLUMNS
        local pipX = startX + (column * (pipSize + pipGap))
        local pipY = startY + (row * (pipSize + pipGap))

        return pipX, pipY
    end

    if maxPipCount > 0 then
        love.graphics.setColor(footerPipColor[1], footerPipColor[2], footerPipColor[3], alpha * 0.65)

        for pipIndex = 0, maxPipCount - 1 do
            local pipX, pipY = getPipPosition(pipIndex, 0)

            love.graphics.rectangle("line", pipX, pipY, pipSize, pipSize)
        end
    end

    love.graphics.setColor(footerPipColor[1], footerPipColor[2], footerPipColor[3], alpha)

    for pipIndex = 0, pipCount - 1 do
        local pipX, pipY = getPipPosition(pipIndex, 0)

        love.graphics.rectangle("fill", pipX, pipY, pipSize, pipSize)
    end

    if blockPipCount > 0 then
        love.graphics.setColor(1, 1, 1, alpha)

        for pipIndex = 0, blockPipCount - 1 do
            local pipX, pipY = getPipPosition(pipIndex, healthRowCount)

            love.graphics.rectangle("fill", pipX, pipY, pipSize, pipSize)
        end
    end

    local blockedPreviewCount = math.min(blockPipCount, math.max(0, tonumber(blockedDamagePreviewCount) or 0))

    if blockedPreviewCount > 0 then
        love.graphics.setColor(DAMAGE_PREVIEW_PIP_COLOR[1], DAMAGE_PREVIEW_PIP_COLOR[2], DAMAGE_PREVIEW_PIP_COLOR[3], alpha)

        for pipIndex = blockPipCount - blockedPreviewCount, blockPipCount - 1 do
            local pipX, pipY = getPipPosition(pipIndex, healthRowCount)

            love.graphics.rectangle("fill", pipX, pipY, pipSize, pipSize)
        end
    end

    local previewCount = math.min(pipCount, math.max(0, tonumber(damagePreviewCount) or 0))

    if previewCount > 0 then
        love.graphics.setColor(DAMAGE_PREVIEW_PIP_COLOR[1], DAMAGE_PREVIEW_PIP_COLOR[2], DAMAGE_PREVIEW_PIP_COLOR[3], alpha)

        for pipIndex = pipCount - previewCount, pipCount - 1 do
            local pipX, pipY = getPipPosition(pipIndex, 0)

            love.graphics.rectangle("fill", pipX, pipY, pipSize, pipSize)
        end
    end
end

local function getCostBadgeLayout(cardDefinition, x, y, width, height)
    if not cardDefinition.mcost or #cardDefinition.mcost == 0 then
        return nil
    end

    local baseBadgeSize = width * COST_BADGE_SIZE_RATIO
    local baseBadgeGap = width * COST_BADGE_GAP_RATIO
    local badgeMargin = snap(width * COST_BADGE_MARGIN_RATIO)
    local availableHeight = math.max(1, height - (badgeMargin * 2))
    local groupGapRatio = 0.28
    local costGroups = {}
    local totalBaseHeight = 0
    local maxColumnCount = 0

    for _, costEntry in ipairs(cardDefinition.mcost) do
        local amount = math.max(0, costEntry.amount or 0)

        if amount > 0 then
            local rowCount = math.max(1, math.ceil(amount / 2))
            local columnCount = math.min(2, amount)

            costGroups[#costGroups + 1] = {
                resource = costEntry.resource,
                amount = amount,
                rowCount = rowCount,
            }

            maxColumnCount = math.max(maxColumnCount, columnCount)
            totalBaseHeight = totalBaseHeight + (rowCount * baseBadgeSize) + (math.max(0, rowCount - 1) * baseBadgeGap)
        end
    end

    if #costGroups == 0 then
        return nil
    end

    totalBaseHeight = totalBaseHeight + (math.max(0, #costGroups - 1) * (baseBadgeSize * groupGapRatio))
    local scale = math.min(1, availableHeight / math.max(1, totalBaseHeight))
    local badgeSize = math.max(12, snap(baseBadgeSize * scale))
    local badgeGap = math.max(2, snap(baseBadgeGap * scale))
    local groupGap = math.max(3, snap(badgeSize * groupGapRatio))
    local occupiedWidth = badgeMargin + (maxColumnCount * badgeSize) + (math.max(0, maxColumnCount - 1) * badgeGap)

    return {
        badgeMargin = badgeMargin,
        badgeSize = badgeSize,
        badgeGap = badgeGap,
        costGroups = costGroups,
        groupGap = groupGap,
        occupiedWidth = occupiedWidth,
        x = x,
        y = y,
    }
end

local function drawCostBadges(cardDefinition, x, y, width, height)
    local layout = getCostBadgeLayout(cardDefinition, x, y, width, height)

    if not layout then
        return
    end

    local badgeMargin = layout.badgeMargin
    local badgeSize = layout.badgeSize
    local badgeGap = layout.badgeGap
    local groupGap = layout.groupGap
    local costGroups = layout.costGroups
    local currentY = y + badgeMargin

    for _, costGroup in ipairs(costGroups) do
        local methodImage = getMethodImage(costGroup.resource)

        for badgeIndex = 1, costGroup.amount do
            local column = (badgeIndex - 1) % 2
            local row = math.floor((badgeIndex - 1) / 2)
            local badgeX = x + badgeMargin + (column * (badgeSize + badgeGap))
            local badgeY = currentY + (row * (badgeSize + badgeGap))

            love.graphics.setColor(0, 0, 0, 0.9)
            love.graphics.setColor(0.12, 0.13, 0.16, 0.95)
            love.graphics.rectangle("fill", badgeX, badgeY, badgeSize, badgeSize, 4, 4)
            love.graphics.setColor(0.87, 0.87, 0.9, 0.9)
            love.graphics.rectangle("line", badgeX, badgeY, badgeSize, badgeSize, 4, 4)

            if methodImage then
                local imageInset = math.max(2, snap(badgeSize * 0.1))
                local availableSize = math.max(1, badgeSize - (imageInset * 2))
                local imageScale = math.min(availableSize / methodImage:getWidth(), availableSize / methodImage:getHeight())
                local imageWidth = methodImage:getWidth() * imageScale
                local imageHeight = methodImage:getHeight() * imageScale
                local imageX = badgeX + ((badgeSize - imageWidth) / 2)
                local imageY = badgeY + ((badgeSize - imageHeight) / 2)

                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(methodImage, imageX, imageY, 0, imageScale, imageScale)
            end
        end

        currentY = currentY + (costGroup.rowCount * (badgeSize + badgeGap)) - badgeGap + groupGap
    end
end

local function getKeywordBadgeRects(cardDefinition, x, y, width, reservedLeftWidth)
    local keywordIds = getCardKeywordIds(cardDefinition)
    local badgeSize = math.max(18, snap(width * 0.18))
    local badgeInset = math.max(4, snap(width * 0.03))
    local badgeGap = math.max(4, snap(width * 0.02))
    local badgeRects = {}
    local leftReserve = math.max(0, reservedLeftWidth or 0)
    local rowStartX = x + badgeInset + leftReserve
    local maxX = x + width - badgeInset
    local currentX = rowStartX
    local currentY = y + badgeInset

    if leftReserve > 0 then
        rowStartX = rowStartX + badgeGap
        currentX = rowStartX
    end

    if rowStartX + badgeSize > maxX then
        rowStartX = x + badgeInset
        currentX = rowStartX
    end

    for keywordIndex, keywordId in ipairs(keywordIds) do
        if keywordIndex > 1 and currentX + badgeSize > maxX then
            currentX = rowStartX
            currentY = currentY + badgeSize + badgeGap
        end

        badgeRects[#badgeRects + 1] = {
            keywordId = keywordId,
            x = currentX,
            y = currentY,
            size = badgeSize,
        }

        currentX = currentX + badgeSize + badgeGap
    end

    return badgeRects
end

local function drawKeywordBadge(keywordId, badgeX, badgeY, badgeSize, keywordValue)
    local keywordImage = getKeywordImage(keywordId)
    local keywordDefinition = getKeywordDefinition(keywordId)
    local hasKeywordValue = keywordDefinition and keywordDefinition.hasvalue == 1
    local displayedKeywordValue = hasKeywordValue and math.max(0, tonumber(keywordValue) or 0) or 0
    local reservedTopHeight = 0
    local pipGap = math.max(1, snap(badgeSize * 0.03))

    love.graphics.setColor(0.12, 0.13, 0.16, 0.95)
    love.graphics.rectangle("fill", badgeX, badgeY, badgeSize, badgeSize, 4, 4)
    love.graphics.setColor(0.87, 0.87, 0.9, 0.9)
    love.graphics.rectangle("line", badgeX, badgeY, badgeSize, badgeSize, 4, 4)

    if hasKeywordValue and displayedKeywordValue > 0 then
        local maxPipSizeByWidth = (badgeSize - 4 - (math.max(0, displayedKeywordValue - 1) * pipGap)) / math.max(1, displayedKeywordValue)
        local pipSize = math.max(1, snap(math.min(badgeSize * BADGE_TOP_PIP_MAX_SIZE_RATIO, maxPipSizeByWidth)))
        reservedTopHeight = pipSize + (math.max(1, snap(badgeSize * 0.04)) * 2)

        if pipSize > 0 and reservedTopHeight > 0 then
            local totalPipWidth = (displayedKeywordValue * pipSize) + (math.max(0, displayedKeywordValue - 1) * pipGap)
            local pipStartX = snap(badgeX + ((badgeSize - totalPipWidth) / 2))
            local pipY = snap(badgeY + ((reservedTopHeight - pipSize) / 2))

            love.graphics.setColor(BADGE_PIP_COLOR_ONE)

            for pipIndex = 0, displayedKeywordValue - 1 do
                local pipX = pipStartX + (pipIndex * (pipSize + pipGap))
                love.graphics.rectangle("fill", pipX, pipY, pipSize, pipSize)
            end
        end
    end

    if keywordImage then
        local imageInset = math.max(2, snap(badgeSize * 0.1))
        local availableSize = math.max(1, badgeSize - (imageInset * 2))
        local imageAreaY = badgeY + imageInset + reservedTopHeight
        local imageAreaHeight = math.max(1, badgeSize - (imageInset * 2) - reservedTopHeight)
        local imageScale = math.min(availableSize / keywordImage:getWidth(), imageAreaHeight / keywordImage:getHeight())
        local imageWidth = keywordImage:getWidth() * imageScale
        local imageHeight = keywordImage:getHeight() * imageScale
        local imageX = badgeX + ((badgeSize - imageWidth) / 2)
        local imageY = imageAreaY + ((imageAreaHeight - imageHeight) / 2)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(keywordImage, imageX, imageY, 0, imageScale, imageScale)
    end
end

local function drawKeywordBadges(cardDefinition, x, y, width, keywordValuesOverride, reservedLeftWidth)
    for _, badgeRect in ipairs(getKeywordBadgeRects(cardDefinition, x, y, width, reservedLeftWidth)) do
        local keywordValue = getCardKeywordDefaultValue(cardDefinition, badgeRect.keywordId)

        if keywordValuesOverride and keywordValuesOverride[badgeRect.keywordId] ~= nil then
            keywordValue = keywordValuesOverride[badgeRect.keywordId]
        end

        drawKeywordBadge(badgeRect.keywordId, badgeRect.x, badgeRect.y, badgeRect.size, keywordValue)
    end
end

local function drawBadge(x, y, width, height, headerHeight, badgeDefinition, bottomPipMaxScale)
    local hasBadgeValue = badgeDefinition and badgeDefinition.value ~= nil
    local badgeImage = getDiceImage(badgeDefinition)
    local onePipCount = 0
    local twentyFivePipCount = 0
    local fivePipCount = 0
    local imageInset = math.max(2, snap(width * 0.08))
    local imageBoxX = x + imageInset
    local imageBoxY = y + imageInset
    local imageBoxWidth = math.max(1, width - (imageInset * 2))
    local imageBoxHeight = math.max(1, height - (imageInset * 2))
    local pipLanePadding = math.max(1, snap(height * 0.04))
    local onePipGap = math.max(1, snap(width * 0.03))
    local bottomPipGap = math.max(1, snap(width * 0.03))
    local artX = imageBoxX
    local artY = imageBoxY
    local artWidth = imageBoxWidth
    local artHeight = imageBoxHeight
    local reservedTopHeight = 0
    local reservedBottomHeight = 0
    local effectiveBottomPipMaxRatio = BADGE_BOTTOM_PIP_MAX_SIZE_RATIO * (bottomPipMaxScale or 1)

    if hasBadgeValue then
        local remainingValue = math.max(0, badgeDefinition.value or 0)
        twentyFivePipCount = math.floor(remainingValue / 25)
        remainingValue = remainingValue % 25
        fivePipCount = math.floor(remainingValue / 5)
        onePipCount = remainingValue % 5

        if onePipCount > 0 then
            local oneMaxSizeByWidth = (width - 4 - (math.max(0, onePipCount - 1) * onePipGap)) / math.max(1, onePipCount)
            local targetOnePipSize = math.max(1, snap(math.min(width * BADGE_TOP_PIP_MAX_SIZE_RATIO, oneMaxSizeByWidth)))
            reservedTopHeight = targetOnePipSize + (pipLanePadding * 2)
        end

        if twentyFivePipCount > 0 or fivePipCount > 0 then
            local bottomPipCount = twentyFivePipCount + fivePipCount
            local totalBottomUnits = (twentyFivePipCount * 2) + fivePipCount
            local bottomMaxUnitSizeByWidth = (width - 4 - (math.max(0, bottomPipCount - 1) * bottomPipGap)) / math.max(1, totalBottomUnits)
            local targetBottomUnitSize = math.max(1, snap(math.min(width * effectiveBottomPipMaxRatio, bottomMaxUnitSizeByWidth)))
            reservedBottomHeight = (targetBottomUnitSize * 2) + (pipLanePadding * 2)
        end
    end

    love.graphics.setColor(0, 0, 0, 0.82)
    love.graphics.rectangle("fill", x, y, width, height, 4, 4)
    love.graphics.setColor(0.87, 0.87, 0.9, 0.9)
    love.graphics.rectangle("line", x, y, width, height, 4, 4)

    local artAreaY = imageBoxY + reservedTopHeight
    local artAreaHeight = math.max(1, imageBoxHeight - reservedTopHeight - reservedBottomHeight)

    if badgeImage then
        local imageScale = math.min(imageBoxWidth / badgeImage:getWidth(), artAreaHeight / badgeImage:getHeight())
        artWidth = badgeImage:getWidth() * imageScale
        artHeight = badgeImage:getHeight() * imageScale
        artX = x + ((width - artWidth) / 2)
        artY = artAreaY + ((artAreaHeight - artHeight) / 2)
    else
        local fallbackInset = math.max(2, snap(width * 0.16))
        artX = x + fallbackInset
        artY = artAreaY
        artWidth = math.max(1, width - (fallbackInset * 2))
        artHeight = math.max(1, artAreaHeight)
    end

    if hasBadgeValue then
        if onePipCount > 0 then
            local topLaneHeight = reservedTopHeight
            local oneMaxSizeByWidth = (width - 4 - (math.max(0, onePipCount - 1) * onePipGap)) / math.max(1, onePipCount)
            local maxOnePipSize = math.max(1, snap(width * BADGE_TOP_PIP_MAX_SIZE_RATIO))
            local onePipSize = math.max(1, snap(math.min(topLaneHeight, oneMaxSizeByWidth, maxOnePipSize)))

            if onePipSize > 0 and topLaneHeight > 0 then
                local totalOnePipWidth = (onePipCount * onePipSize) + (math.max(0, onePipCount - 1) * onePipGap)
                local startOneX = snap(x + ((width - totalOnePipWidth) / 2))
                local onePipY = snap(imageBoxY + ((topLaneHeight - onePipSize) / 2))

                love.graphics.setColor(BADGE_PIP_COLOR_ONE)

                for pipIndex = 0, onePipCount - 1 do
                    local pipX = startOneX + (pipIndex * (onePipSize + onePipGap))
                    love.graphics.rectangle("fill", pipX, onePipY, onePipSize, onePipSize)
                end
            end
        end

        if twentyFivePipCount > 0 or fivePipCount > 0 then
            local bottomLaneHeight = reservedBottomHeight
            local bottomPipCount = twentyFivePipCount + fivePipCount
            local totalBottomUnits = (twentyFivePipCount * 2) + fivePipCount
            local bottomMaxUnitSizeByWidth = (width - 4 - (math.max(0, bottomPipCount - 1) * bottomPipGap)) / math.max(1, totalBottomUnits)
            local maxBottomUnitSize = math.max(1, snap(width * effectiveBottomPipMaxRatio))
            local bottomUnitSize = math.max(1, snap(math.min(bottomLaneHeight * 0.5, bottomMaxUnitSizeByWidth, maxBottomUnitSize)))
            local bottomPipHeight = bottomUnitSize * 2

            if bottomUnitSize > 0 and bottomLaneHeight >= bottomPipHeight then
                local totalBottomWidth = (totalBottomUnits * bottomUnitSize) + (math.max(0, bottomPipCount - 1) * bottomPipGap)
                local startBottomX = snap(x + ((width - totalBottomWidth) / 2))
                local bottomLaneY = y + height - imageInset - bottomLaneHeight
                local bottomPipY = snap(bottomLaneY + ((bottomLaneHeight - bottomPipHeight) / 2))
                local pipX = startBottomX

                for pipIndex = 1, twentyFivePipCount do
                    love.graphics.setColor(BADGE_PIP_COLOR_TWENTY_FIVE)
                    love.graphics.rectangle("fill", pipX, bottomPipY, bottomUnitSize * 2, bottomPipHeight)
                    pipX = pipX + (bottomUnitSize * 2) + bottomPipGap
                end

                for pipIndex = 1, fivePipCount do
                    love.graphics.setColor(BADGE_PIP_COLOR_FIVE)
                    love.graphics.rectangle("fill", pipX, bottomPipY, bottomUnitSize, bottomPipHeight)
                    pipX = pipX + bottomUnitSize + bottomPipGap
                end
            end
        end
    end

    if artWidth <= 0 or artHeight <= 0 then
        return
    end

    if badgeImage then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(badgeImage, artX, artY, 0, artWidth / badgeImage:getWidth(), artHeight / badgeImage:getHeight())
    else
        love.graphics.setColor(0.28, 0.28, 0.32, 1)
        love.graphics.rectangle("fill", artX, artY, artWidth, artHeight, 3, 3)
    end
end

local function drawPortraitBadges(cardDefinition, x, y, width, height, footerHeight)
    if not hasDefinitionFaceBadges(cardDefinition) then
        return
    end

    local badgeSize = snap(width * 0.16)
    local headerHeight = snap(badgeSize * 0.44)
    local badgeBodyHeight = badgeSize
    local badgeHeight = headerHeight + badgeBodyHeight
    local badgeGap = snap(width * 0.04)
    local badgeInset = snap(width * 0.03)
    local availableHeight = height - footerHeight - snap(width * 0.03)
    local totalBadgeHeight = (badgeHeight * 3) + (badgeGap * 2)
    local startY = snap(y + ((availableHeight - totalBadgeHeight) / 2))
    local leftX = x + badgeInset
    local rightX = x + width - badgeInset - badgeSize
    local badgeDefinitions = getBadgeDefinitions(cardDefinition)

    for badgeIndex = 0, 2 do
        local badgeY = startY + (badgeIndex * (badgeHeight + badgeGap))

        drawBadge(leftX, badgeY, badgeSize, badgeHeight, headerHeight, badgeDefinitions[badgeIndex + 1])
        drawBadge(rightX, badgeY, badgeSize, badgeHeight, headerHeight, badgeDefinitions[badgeIndex + 4])
    end
end

local function drawTextboxBadges(cardDefinition, x, y, width, height, padding, footerHeight, reserveFooterSpace, expandToWidth, badgeScale)
    if not hasDefinitionFaceBadges(cardDefinition) then
        return nil
    end

    local badgeGap = snap(width * 0.018)
    local badgeSize = snap(width * 0.115 * HAND_BADGE_SCALE)
    local availableWidth = math.max(1, width - (padding * 2))
    local sizeScale = badgeScale or 1

    if expandToWidth then
        badgeGap = math.max(2, snap(width * 0.02))
        badgeSize = math.max(12, snap(((availableWidth - (badgeGap * 5)) / 6) * 1.10 * sizeScale))
    else
        badgeSize = math.max(12, snap(badgeSize * sizeScale))
    end

    local headerHeight = snap(badgeSize * 0.44)
    local badgeBodyHeight = badgeSize
    local badgeHeight = headerHeight + badgeBodyHeight
    local totalBadgeWidth = (badgeSize * 6) + (badgeGap * 5)
    local startX = snap(x + ((width - totalBadgeWidth) / 2))
    local footerReserve = reserveFooterSpace ~= false and footerHeight or 0
    local badgeY = snap(y + height - footerReserve - badgeHeight - snap(padding * 0.5))
    local badgeDefinitions = getBadgeDefinitions(cardDefinition)
    local bottomPipMaxScale = reserveFooterSpace ~= false and HAND_BADGE_BOTTOM_PIP_MAX_SCALE or 1

    for badgeIndex = 0, 5 do
        local badgeX = startX + (badgeIndex * (badgeSize + badgeGap))
        drawBadge(badgeX, badgeY, badgeSize, badgeHeight, headerHeight, badgeDefinitions[badgeIndex + 1], bottomPipMaxScale)
    end

    return badgeY
end

function carddraw.drawDefinitionTextboxBadges(cardDefinition, x, y, width, height, padding, footerHeight, reserveFooterSpace, expandToWidth, badgeScale)
    if not cardDefinition then
        return nil
    end

    return drawTextboxBadges(cardDefinition, x, y, width, height, padding, footerHeight, reserveFooterSpace, expandToWidth, badgeScale)
end

function carddraw.definitionHasDice(cardDefinition)
    return #getAssignedFaceIndices(cardDefinition) > 0
end

function carddraw.getAssignedFaceIndices(cardDefinition)
    return getAssignedFaceIndices(cardDefinition)
end

function carddraw.getDefinitionFaceBadge(cardDefinition, faceIndex)
    if not cardDefinition or not faceIndex then
        return nil
    end

    return getDiceDefinition(cardDefinition["D" .. tostring(faceIndex)])
end

function carddraw.getCardRollBadgeRect(drawX, drawY, options)
    local metrics = getCardMetrics(options)
    local renderWidth = snap(metrics.width)
    local badgeInset = math.max(4, snap(renderWidth * 0.035))
    local badgeScale = HAND_BADGE_SCALE

    if metrics.showHealthOnPortrait then
        badgeScale = badgeScale * GRID_ROLL_BADGE_SCALE
    end

    local badgeWidth = math.max(20, snap(renderWidth * 0.115 * badgeScale))
    local badgeHeaderHeight = snap(badgeWidth * 0.44)
    local badgeBodyHeight = badgeWidth
    local badgeHeight = badgeHeaderHeight + badgeBodyHeight
    local badgeX = snap(drawX) + renderWidth - badgeInset - badgeWidth
    local badgeY = snap(drawY) + badgeInset

    return badgeX, badgeY, badgeWidth, badgeHeight
end

function carddraw.getCardTargetBadgeRect(drawX, drawY, options, placeAboveHealthBar)
    local metrics = getCardMetrics(options)
    local renderWidth = snap(metrics.width)
    local portraitHeight = snap(metrics.portraitHeight)
    local badgeInset = math.max(4, snap(renderWidth * 0.04))
    local badgeSize = math.max(20, snap(renderWidth * 0.19))
    local badgeX = snap(drawX) + renderWidth - badgeInset - badgeSize
    local badgeY = snap(drawY) + portraitHeight - badgeInset - badgeSize

    if placeAboveHealthBar and metrics.showHealthOnPortrait then
        local footerHeight = snap(metrics.footerHeight)
        badgeY = snap(drawY) + portraitHeight - footerHeight - badgeInset - badgeSize
    end

    return badgeX, badgeY, badgeSize
end

function carddraw.drawTargetPreviewBadge(targetPreview, badgeX, badgeY, badgeSize, alpha)
    local portrait = nil
    local drawAlpha = alpha or 1

    if targetPreview and (targetPreview.kind == "objective" or targetPreview.kind == "intel") then
        portrait = getObjectiveImage(targetPreview.objectiveId)
    elseif targetPreview and targetPreview.kind == "warzone" then
        portrait = getWarzoneImage(targetPreview.warzoneId)
    elseif targetPreview and (targetPreview.kind == "deck" or targetPreview.kind == "hand") then
        portrait = getJaclImage(targetPreview.jaclName or getDefaultJaclName())
    elseif targetPreview and targetPreview.setName and targetPreview.cardId then
        local cardDefinition = getCardDefinition(targetPreview.setName, targetPreview.cardId)
        portrait = getPortraitByPath(targetPreview.portraitPath) or (cardDefinition and getPortrait(cardDefinition, targetPreview.setName) or nil)
    end

    love.graphics.setColor(0.05, 0.05, 0.06, 0.94 * drawAlpha)
    love.graphics.rectangle("fill", badgeX, badgeY, badgeSize, badgeSize, 4, 4)

    if portrait then
        local availableSize = math.max(1, badgeSize - 2)
        local imageScale = math.max(availableSize / portrait:getWidth(), availableSize / portrait:getHeight())
        local imageWidth = portrait:getWidth() * imageScale
        local imageHeight = portrait:getHeight() * imageScale
        local imageX = badgeX + ((badgeSize - imageWidth) / 2)
        local imageY = badgeY + ((badgeSize - imageHeight) / 2)

        love.graphics.setColor(1, 1, 1, drawAlpha)
        love.graphics.draw(portrait, imageX, imageY, 0, imageScale, imageScale)
    else
        love.graphics.setColor(0.28, 0.28, 0.32, drawAlpha)
        love.graphics.rectangle("fill", badgeX + 1, badgeY + 1, badgeSize - 2, badgeSize - 2, 3, 3)
    end

    love.graphics.setColor(0.87, 0.87, 0.9, 0.95 * drawAlpha)
    love.graphics.rectangle("line", badgeX, badgeY, badgeSize, badgeSize, 4, 4)
end

function carddraw.drawTargetPortraitBadge(setName, cardId, badgeX, badgeY, badgeSize, alpha)
    carddraw.drawTargetPreviewBadge({
        setName = setName,
        cardId = cardId,
    }, badgeX, badgeY, badgeSize, alpha)
end

function carddraw.drawSignalLossImage(image, x, y, width, height, progress, seed, alpha, fallbackColor)
    local glitchProgress = clamp(progress or 0, 0, 1)
    local drawAlpha = alpha or 1
    local slices = math.max(8, snap(height / 12))
    local sliceHeight = height / slices
    local baseSeed = seed or 0
    local imageScaleX = image and (width / image:getWidth()) or nil
    local imageScaleY = image and (height / image:getHeight()) or nil
    local blankThreshold = math.max(0, (glitchProgress - 0.18) * 1.2)

    love.graphics.setColor(0.04, 0.05, 0.06, 0.92 * drawAlpha)
    love.graphics.rectangle("fill", x, y, width, height)

    for sliceIndex = 0, slices - 1 do
        local sliceY = y + (sliceIndex * sliceHeight)
        local pseudo = (math.sin(baseSeed + (sliceIndex * 17.173)) + 1) / 2
        local shouldBlank = pseudo < blankThreshold
        local offsetX = math.sin(baseSeed + (sliceIndex * 9.31) + (glitchProgress * 28)) * width * 0.16 * glitchProgress
        local offsetY = math.cos(baseSeed + (sliceIndex * 4.73) + (glitchProgress * 21)) * 1.5 * glitchProgress

        if not shouldBlank then
            love.graphics.setScissor(snap(x), snap(sliceY), snap(width), math.max(1, snap(sliceHeight + 1)))

            if image then
                love.graphics.setColor(1, 1, 1, drawAlpha)
                love.graphics.draw(image, x + offsetX, y + offsetY, 0, imageScaleX, imageScaleY)
            else
                local fillColor = fallbackColor or { 0.23, 0.23, 0.27, 1 }
                love.graphics.setColor(fillColor[1], fillColor[2], fillColor[3], drawAlpha)
                love.graphics.rectangle("fill", x + offsetX, y + offsetY, width, height)
            end
        end
    end

    love.graphics.setScissor()
    love.graphics.setColor(0, 0, 0, 0.25 * glitchProgress * drawAlpha)

    for sliceIndex = 0, slices do
        local lineY = y + (sliceIndex * sliceHeight)
        love.graphics.rectangle("fill", x, snap(lineY), width, 1)
    end

    if glitchProgress > 0.55 then
        love.graphics.setColor(0, 0, 0, (glitchProgress - 0.55) / 0.45 * drawAlpha)
        love.graphics.rectangle("fill", x, y, width, height)
    end
end

function carddraw.drawOverlayPulse(overlayName, x, y, width, height, progress, alpha)
    local overlayImage = getOverlayImage(overlayName)

    if not overlayImage then
        return
    end

    local clampedProgress = clamp(progress or 0, 0, 1)
    local drawAlpha = (alpha or 1) * (1 - clampedProgress)
    local pulseScale = lerp(PROGRESS_OVERLAY_PULSE_MIN, PROGRESS_OVERLAY_PULSE_MAX, math.sin(clampedProgress * math.pi))
    local centerX = x + (width / 2)
    local centerY = y + (height / 2)
    local drawWidth = width * pulseScale
    local drawHeight = height * pulseScale
    local drawX = centerX - (drawWidth / 2)
    local drawY = centerY - (drawHeight / 2)

    love.graphics.setColor(1, 1, 1, drawAlpha)
    love.graphics.draw(
        overlayImage,
        drawX,
        drawY,
        0,
        drawWidth / overlayImage:getWidth(),
        drawHeight / overlayImage:getHeight()
    )
    love.graphics.setColor(1, 1, 1, 1)
end

local function drawLethalPreviewBadge(drawX, drawY, portraitWidth, portraitHeight, overkillValue, alpha)
    local badgeSize = snap(math.min(portraitWidth, portraitHeight) * 0.5)
    local badgeX = snap(drawX + ((portraitWidth - badgeSize) / 2))
    local badgeY = snap(drawY + ((portraitHeight - badgeSize) / 2))
    local pulseRange = KIA_BADGE_PULSE_MAX - KIA_BADGE_PULSE_MIN
    local pulseScale = KIA_BADGE_PULSE_MIN + (((math.sin(love.timer.getTime() * KIA_BADGE_PULSE_SPEED) + 1) / 2) * pulseRange)
    local centerX = badgeX + (badgeSize / 2)
    local centerY = badgeY + (badgeSize / 2)
    local kiaImage = getOverlayImage("kia")
    local badgeFont = getCardFont(math.max(10, snap(badgeSize * 0.18)))
    local drawAlpha = alpha or 1

    love.graphics.push()
    love.graphics.translate(centerX, centerY)
    love.graphics.scale(pulseScale, pulseScale)

    local localX = -badgeSize / 2
    local localY = -badgeSize / 2
    local text = tostring(math.max(0, overkillValue or 0))

    love.graphics.setColor(0, 0, 0, 0.96 * drawAlpha)
    love.graphics.rectangle("fill", localX, localY, badgeSize, badgeSize, 8, 8)
    love.graphics.setColor(0.87, 0.87, 0.9, 0.95 * drawAlpha)
    love.graphics.rectangle("line", localX, localY, badgeSize, badgeSize, 8, 8)

    if kiaImage then
        local imageInset = math.max(6, snap(badgeSize * 0.14))
        local footerReserve = math.max(18, snap(badgeSize * 0.22))
        local availableWidth = badgeSize - (imageInset * 2)
        local availableHeight = badgeSize - (imageInset * 2) - footerReserve
        local imageScale = math.min(availableWidth / kiaImage:getWidth(), availableHeight / kiaImage:getHeight())
        local imageWidth = kiaImage:getWidth() * imageScale
        local imageHeight = kiaImage:getHeight() * imageScale
        local imageX = localX + ((badgeSize - imageWidth) / 2)
        local imageY = localY + imageInset + ((availableHeight - imageHeight) / 2)

        love.graphics.setColor(1, 1, 1, drawAlpha)
        love.graphics.draw(kiaImage, imageX, imageY, 0, imageScale, imageScale)
    end

    love.graphics.setColor(KIA_BADGE_TEXT_COLOR[1], KIA_BADGE_TEXT_COLOR[2], KIA_BADGE_TEXT_COLOR[3], drawAlpha)
    love.graphics.setFont(badgeFont)
    love.graphics.printf(
        text,
        localX,
        snap(localY + badgeSize - badgeFont:getHeight() - math.max(4, snap(badgeSize * 0.08))),
        badgeSize,
        "center"
    )

    love.graphics.pop()
end

function carddraw.drawDefinitionRollBadge(cardDefinition, badgeX, badgeY, badgeWidth, badgeHeight, faceIndex, pulseScale)
    local badgeDefinition = carddraw.getDefinitionFaceBadge(cardDefinition, faceIndex)

    if not badgeDefinition then
        return
    end

    local scale = pulseScale or 1
    local drawWidth = math.max(1, snap(badgeWidth))
    local drawHeight = math.max(1, snap(badgeHeight))
    local centerX = badgeX + (drawWidth / 2)
    local centerY = badgeY + (drawHeight / 2)

    love.graphics.push()
    love.graphics.translate(centerX, centerY)
    love.graphics.scale(scale, scale)
    drawBadge(-drawWidth / 2, -drawHeight / 2, drawWidth, drawHeight, snap(drawWidth * 0.44), badgeDefinition)
    love.graphics.pop()
end

function carddraw.getHoveredKeyword(setName, cardId, drawX, drawY, options, mouseX, mouseY)
    local cardDefinition = getCardDefinition(setName, cardId)

    if not cardDefinition then
        return nil
    end

    local metrics = getCardMetrics(options)
    local costBadgeLayout = cardDefinition.mcost
        and not metrics.showHealthOnPortrait
        and getCostBadgeLayout(cardDefinition, snap(drawX), snap(drawY), snap(metrics.width), snap(metrics.portraitHeight))
        or nil
    local reservedLeftWidth = costBadgeLayout and costBadgeLayout.occupiedWidth or 0

    for _, badgeRect in ipairs(getKeywordBadgeRects(cardDefinition, snap(drawX), snap(drawY), snap(metrics.width), reservedLeftWidth)) do
        if mouseX >= badgeRect.x
            and mouseX <= badgeRect.x + badgeRect.size
            and mouseY >= badgeRect.y
            and mouseY <= badgeRect.y + badgeRect.size then
            return getKeywordDefinition(badgeRect.keywordId)
        end
    end

    return nil
end

function carddraw.drawKeywordTooltip(keywordDefinition, mouseX, mouseY)
    if not keywordDefinition then
        return
    end

    local previousFont = love.graphics.getFont()
    local nameFont = getFont(CARD_FONT_PATH, KEYWORD_TOOLTIP_NAME_FONT_SIZE)
    local textFont = getFont(CARD_FONT_PATH, KEYWORD_TOOLTIP_TEXT_FONT_SIZE)
    local textWidth = KEYWORD_TOOLTIP_MAX_WIDTH - (KEYWORD_TOOLTIP_PADDING * 2)
    local _, wrappedTextLines = textFont:getWrap(keywordDefinition.text or "", textWidth)
    local nameHeight = nameFont:getHeight()
    local textHeight = #wrappedTextLines * textFont:getHeight()
    local boxWidth = KEYWORD_TOOLTIP_MAX_WIDTH
    local boxHeight = (KEYWORD_TOOLTIP_PADDING * 2) + nameHeight + 6 + textHeight
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local boxX = snap(math.min(mouseX + KEYWORD_TOOLTIP_OFFSET_X, windowWidth - boxWidth - 8))
    local boxY = snap(math.min(mouseY + KEYWORD_TOOLTIP_OFFSET_Y, windowHeight - boxHeight - 8))

    love.graphics.setColor(0.05, 0.05, 0.06, 0.96)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 6, 6)
    love.graphics.setColor(0.87, 0.87, 0.9, 0.95)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 6, 6)

    love.graphics.setColor(0.95, 0.95, 0.97, 1)
    love.graphics.setFont(nameFont)
    love.graphics.print(keywordDefinition.name or keywordDefinition.id or "", boxX + KEYWORD_TOOLTIP_PADDING, boxY + KEYWORD_TOOLTIP_PADDING)

    love.graphics.setColor(0.88, 0.89, 0.92, 1)
    love.graphics.setFont(textFont)
    love.graphics.printf(
        keywordDefinition.text or "",
        boxX + KEYWORD_TOOLTIP_PADDING,
        boxY + KEYWORD_TOOLTIP_PADDING + nameHeight + 6,
        textWidth,
        "left"
    )

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

function carddraw.drawCard(setName, cardId, x, y, options)
    return carddraw.drawCardState(setName, cardId, x, y, 0, options)
end

function carddraw.preloadPortrait(setName, cardId)
    local cardDefinition = getCardDefinition(setName, cardId)

    if not cardDefinition then
        return nil
    end

    return getPortrait(cardDefinition, setName)
end

function carddraw.getPortraitImage(setName, cardId, options)
    local cardDefinition = getCardDefinition(setName, cardId)

    if not cardDefinition then
        return nil
    end

    options = options or {}
    return getPortraitByPath(options.portraitPath) or getPortrait(cardDefinition, setName)
end

function carddraw.drawPortraitPreview(setName, cardId, x, y, width, height, alpha, options)
    local cardDefinition = getCardDefinition(setName, cardId)

    if not cardDefinition then
        return
    end

    options = options or {}

    local portrait = carddraw.getPortraitImage(setName, cardId, options)
    alpha = alpha or 0.45

    if portrait then
        local portraitScaleX = width / portrait:getWidth()
        local portraitScaleY = height / portrait:getHeight()
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.draw(portrait, x, y, 0, portraitScaleX, portraitScaleY)
    else
        love.graphics.setColor(0.23, 0.23, 0.27, alpha)
        love.graphics.rectangle("fill", x, y, width, height)
    end

    love.graphics.setColor(0.87, 0.87, 0.9, alpha)
    love.graphics.rectangle("line", x, y, width, height)
    love.graphics.setColor(1, 1, 1, 1)
end

function carddraw.drawCardState(setName, cardId, x, y, expansionProgress, options)
    local cardDefinition = getCardDefinition(setName, cardId)

    if not cardDefinition then
        return
    end

    expansionProgress = clamp(expansionProgress or 0, 0, 1)

    local metrics = getCardMetrics(options)
    local renderWidth = snap(metrics.width)
    local portraitHeight = snap(metrics.portraitHeight)
    local labelHeight = snap(metrics.labelHeight)
    local textboxHeight = snap(metrics.textboxHeight * expansionProgress)
    local cardHeight = snap(lerp(metrics.collapsedHeight, metrics.expandedHeight, expansionProgress))
    local showLabel = metrics.showLabelWhenCollapsed or expansionProgress > 0
    local labelProgress = showLabel and 1 or 0

    local portrait = getPortraitByPath(metrics.portraitPath) or getPortrait(cardDefinition, setName)
    local drawX = snap(x)
    local drawY = snap(y)
    local portraitY = drawY
    local labelY = portraitY + portraitHeight
    local textY = labelY + labelHeight
    local previousFont = love.graphics.getFont()
    local labelScale, textboxScale, healthScale = getTypographyScale(metrics)
    local labelFontTargetSize = math.max(10, math.floor(16 * (renderWidth / CARD_WIDTH) * labelScale))
    local labelTextWidth = renderWidth - (snap(metrics.padding) * 2)
    local displayName = metrics.displayName or cardDefinition.name or cardDefinition.id
    local classLine = getCardClassLine(cardDefinition)
    local classGap = classLine and math.max(1, snap(2 * (renderWidth / CARD_WIDTH))) or 0
    local classFontTargetSize = math.max(CARD_CLASS_LABEL_MIN_FONT_SIZE, math.floor(10 * (renderWidth / CARD_WIDTH) * labelScale))
    local classFont = classLine and getFittedCardFontForBox(classLine, classFontTargetSize, labelTextWidth, labelHeight, CARD_CLASS_LABEL_MIN_FONT_SIZE) or nil
    local nameMaxHeight = labelHeight

    if classFont then
        nameMaxHeight = math.max(CARD_LABEL_MIN_FONT_SIZE, labelHeight - classFont:getHeight() - classGap)
    end

    local labelFont = getFittedCardFontForBox(displayName, labelFontTargetSize, labelTextWidth, nameMaxHeight, CARD_LABEL_MIN_FONT_SIZE)
    local textboxFont = getCardFont(math.max(9, math.floor(12 * (renderWidth / CARD_WIDTH) * textboxScale)))
    local footerFont = getCardFont(math.max(9, math.floor(14 * (renderWidth / CARD_WIDTH) * metrics.healthFontScale * healthScale)))
    local displayedHealth = metrics.currentHealth
    local displayedMaxHealth = metrics.maxHealth
    local footerPipColor = TROOP_HEALTH_PIP_COLOR
    local style = getCardStyle(cardDefinition)

    if displayedHealth == nil then
        displayedHealth = cardDefinition.health
    end

    if displayedMaxHealth == nil then
        displayedMaxHealth = cardDefinition.max
    end

    if cardDefinition.type == TOME_CARD_TYPE and cardDefinition.syncost ~= nil then
        displayedHealth = math.max(0, tonumber(cardDefinition.syncost) or 0)
        displayedMaxHealth = displayedHealth
        footerPipColor = SYNTAC_PIP_COLOR
    end

    love.graphics.setColor(0.15, 0.15, 0.18, 0.96)
    love.graphics.rectangle("fill", drawX, drawY, renderWidth, cardHeight, 8, 8)

    if metrics.destructionProgress and metrics.destructionProgress > 0 then
        carddraw.drawSignalLossImage(portrait, drawX, portraitY, renderWidth, portraitHeight, metrics.destructionProgress, metrics.destructionSeed, 1, { 0.23, 0.23, 0.27, 1 })
    elseif portrait then
        local portraitScaleX = renderWidth / portrait:getWidth()
        local portraitScaleY = portraitHeight / portrait:getHeight()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(portrait, drawX, portraitY, 0, portraitScaleX, portraitScaleY)
    else
        love.graphics.setColor(0.23, 0.23, 0.27, 1)
        love.graphics.rectangle("fill", drawX, portraitY, renderWidth, portraitHeight)
    end

    local costBadgeLayout = cardDefinition.mcost
        and not metrics.showHealthOnPortrait
        and getCostBadgeLayout(cardDefinition, drawX, portraitY, renderWidth, portraitHeight)
        or nil
    local keywordReservedLeftWidth = costBadgeLayout and costBadgeLayout.occupiedWidth or 0

    drawKeywordBadges(cardDefinition, drawX, portraitY, renderWidth, metrics.keywordValues, keywordReservedLeftWidth)

    love.graphics.setColor(style.outlineColor[1], style.outlineColor[2], style.outlineColor[3], 1)
    love.graphics.rectangle("line", drawX, portraitY, renderWidth, portraitHeight)

    if displayedHealth ~= nil and metrics.showHealthOnPortrait then
        if not metrics.showBadgesInTextbox then
            drawPortraitBadges(cardDefinition, drawX, portraitY, renderWidth, portraitHeight, snap(metrics.footerHeight))
        end

        drawHealthFooter(drawX, portraitY, renderWidth, portraitHeight, snap(metrics.padding), snap(metrics.footerHeight), footerFont, displayedHealth, displayedMaxHealth, metrics.damagePreviewCount, metrics.blockedDamagePreviewCount, metrics.blocking, 1, cardDefinition.method, footerPipColor)
    elseif cardDefinition.mcost and not metrics.showHealthOnPortrait then
        drawCostBadges(cardDefinition, drawX, portraitY, renderWidth, portraitHeight)
    end

    if metrics.showEmphasisOnPortrait and cardDefinition.type == "hunter" then
        drawPortraitEmphasisBadge(cardDefinition, drawX, portraitY, renderWidth, portraitHeight)
    end

    if metrics.lethalPreviewOverkill ~= nil and metrics.damagePreviewCount >= displayedHealth then
        drawLethalPreviewBadge(drawX, portraitY, renderWidth, portraitHeight, metrics.lethalPreviewOverkill, 1)
    end

    if showLabel then
        love.graphics.setColor(style.labelFillColor[1], style.labelFillColor[2], style.labelFillColor[3], labelProgress)
        love.graphics.rectangle("fill", drawX, labelY, renderWidth, labelHeight)
        love.graphics.setColor(style.outlineColor[1], style.outlineColor[2], style.outlineColor[3], labelProgress)
        love.graphics.rectangle("line", drawX, labelY, renderWidth, labelHeight)
        love.graphics.setFont(labelFont)
        local _, wrappedLabelLines = labelFont:getWrap(displayName, labelTextWidth)
        local wrappedLabelHeight = #wrappedLabelLines * labelFont:getHeight()
        local classHeight = classFont and classFont:getHeight() or 0
        local totalLabelTextHeight = wrappedLabelHeight + classHeight

        if classFont then
            totalLabelTextHeight = totalLabelTextHeight + classGap
        end

        local labelTextY = snap(labelY + ((labelHeight - totalLabelTextHeight) / 2))
        love.graphics.setColor(style.labelTextColor[1], style.labelTextColor[2], style.labelTextColor[3], labelProgress)
        love.graphics.printf(
            displayName,
            drawX + snap(metrics.padding),
            labelTextY,
            labelTextWidth,
            "center"
        )

        if classFont then
            love.graphics.setFont(classFont)
            love.graphics.setColor(style.labelTextColor[1], style.labelTextColor[2], style.labelTextColor[3], labelProgress * 0.62)
            love.graphics.printf(
                classLine,
                drawX + snap(metrics.padding),
                snap(labelTextY + wrappedLabelHeight + classGap),
                labelTextWidth,
                "center"
            )
        end
    end

    if expansionProgress > 0 then
        love.graphics.setColor(0.18, 0.18, 0.22, 1)
        love.graphics.rectangle("fill", drawX, textY, renderWidth, textboxHeight)
        love.graphics.setColor(0.87, 0.87, 0.9, 1)
        love.graphics.rectangle("line", drawX, textY, renderWidth, textboxHeight)

        if textboxHeight > (snap(metrics.padding) * 2) then
            local textBottomY = textY + textboxHeight
            local textWidth = renderWidth - (snap(metrics.padding) * 2)
            local textStartY = snap(textY + metrics.padding)

            if metrics.showBadgesInTextbox and textboxHeight > snap(metrics.footerHeight) then
                local badgeTopY = drawTextboxBadges(cardDefinition, drawX, textY, renderWidth, textboxHeight, snap(metrics.padding), snap(metrics.footerHeight), not metrics.showHealthOnPortrait, metrics.showHealthOnPortrait)

                if badgeTopY then
                    textBottomY = badgeTopY - snap(metrics.padding * 0.75)
                end
            elseif displayedHealth ~= nil and textboxHeight > snap(metrics.footerHeight) and not metrics.showHealthOnPortrait then
                textBottomY = textY + textboxHeight - snap(metrics.footerHeight) - snap(metrics.padding * 0.5)
            end

            love.graphics.setColor(0.93, 0.93, 0.95, expansionProgress)
            love.graphics.setFont(textboxFont)
            local _, wrappedTextboxLines = textboxFont:getWrap(cardDefinition.textbox or "", textWidth)
            local textboxTextHeight = #wrappedTextboxLines * textboxFont:getHeight()
            love.graphics.printf(cardDefinition.textbox or "", drawX + snap(metrics.padding), textStartY, textWidth, "left")

            if cardDefinition.flavor then
                local flavorFont = getFlavorFont(math.max(9, math.floor(11 * (renderWidth / CARD_WIDTH) * textboxScale)), textboxFont)
                local flavorY = textStartY + textboxTextHeight + CARD_FLAVOR_GAP

                if flavorY + flavorFont:getHeight() <= textBottomY then
                    love.graphics.setColor(0.78, 0.8, 0.86, expansionProgress)
                    love.graphics.setFont(flavorFont)
                    love.graphics.printf(cardDefinition.flavor, drawX + snap(metrics.padding), flavorY, textWidth, "left")
                end
            end

            if displayedHealth ~= nil and textboxHeight > snap(metrics.footerHeight) and not metrics.showHealthOnPortrait then
                drawHealthFooter(drawX, textY, renderWidth, textboxHeight, snap(metrics.padding), snap(metrics.footerHeight), footerFont, displayedHealth, displayedMaxHealth, metrics.damagePreviewCount, metrics.blockedDamagePreviewCount, metrics.blocking, expansionProgress, cardDefinition.method, footerPipColor)
            end
        end
    end

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

function carddraw.getCardSize(options)
    local metrics = getCardMetrics(options)
    return metrics.width, metrics.collapsedHeight
end

function carddraw.getExpandedCardSize(options)
    local metrics = getCardMetrics(options)
    return metrics.width, metrics.expandedHeight
end

function carddraw.getDrawPosition(x, y, expansionProgress, options)
    local metrics = getCardMetrics(options)
    expansionProgress = clamp(expansionProgress or 0, 0, 1)
    return x, lerp(y, y - (metrics.expandedHeight - metrics.collapsedHeight), expansionProgress)
end

function carddraw.isPointInsideCard(x, y, cardX, cardY, expansionProgress, options)
    local metrics = getCardMetrics(options)
    expansionProgress = clamp(expansionProgress or 0, 0, 1)
    local drawX, drawY = carddraw.getDrawPosition(cardX, cardY, expansionProgress, options)
    local cardHeight = lerp(metrics.collapsedHeight, metrics.expandedHeight, expansionProgress)

    return carddraw.isPointInsideDrawnCard(x, y, drawX, drawY, expansionProgress, cardHeight, options)
end

function carddraw.isPointInsideDrawnCard(x, y, drawX, drawY, expansionProgress, cardHeight, options)
    local metrics = getCardMetrics(options)
    expansionProgress = clamp(expansionProgress or 0, 0, 1)
    cardHeight = cardHeight or lerp(metrics.collapsedHeight, metrics.expandedHeight, expansionProgress)

    return x >= drawX
        and x <= drawX + metrics.width
        and y >= drawY
        and y <= drawY + cardHeight
end

function carddraw.getMethodBadgeCenters(setName, cardId, drawX, drawY, expansionProgress, options)
    local cardDefinition = getCardDefinition(setName, cardId)

    if not cardDefinition or not cardDefinition.method then
        return nil
    end

    local metrics = getCardMetrics(options)

    if not metrics.showHealthOnPortrait or cardDefinition.health == nil then
        return nil
    end

    local renderWidth = snap(metrics.width)
    local portraitHeight = snap(metrics.portraitHeight)
    local footerHeight = snap(metrics.footerHeight)
    local padding = snap(metrics.padding)
    local footerY = snap(drawY) + portraitHeight - footerHeight
    local expandedResources, badgeInset, badgeSize, badgeGap, totalBadgeWidth = getMethodBadgeLayout(renderWidth, footerHeight, padding, cardDefinition.method)
    local badgesStartX = snap(drawX) + renderWidth - padding - totalBadgeWidth
    local centers = {}

    for resourceIndex, resourceName in ipairs(expandedResources) do
        local badgeX = badgesStartX + ((resourceIndex - 1) * (badgeSize + badgeGap))
        local badgeY = footerY + badgeInset

        centers[#centers + 1] = {
            resource = resourceName,
            x = badgeX + (badgeSize / 2),
            y = badgeY + (badgeSize / 2),
        }
    end

    return centers
end

return carddraw
