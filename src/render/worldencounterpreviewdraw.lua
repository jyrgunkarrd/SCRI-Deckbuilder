local worldencounterpreviewdraw = {}

local objectiveDefinitions = require("data.objectives")
local worldfuelrules = require("src.system.worldfuelrules")
local crewrules = require("src.system.crewrules")
local warzoneDefinitions = require("data.warzones")

local FONT_PATH = "assets/fonts/Furore.otf"
local MAP_IMAGE_DIRECTORY = "assets/images/map/"
local ICON_IMAGE_DIRECTORY = "assets/images/icons/"
local CREW_IMAGE_DIRECTORY = "assets/images/crew/"
local CHAMP_IMAGE_DIRECTORY = "assets/images/champ/"
local STDPKG_IMAGE_DIRECTORY = "assets/images/stdpkg/"
local MODULARPKG_IMAGE_DIRECTORY = "assets/images/modularpkg/"
local WARZONE_IMAGE_DIRECTORY = "assets/images/warzone/"

local MAP_CLUSTER_COUNT = 3
local MAP_CLUSTER_SIZE = 5
local MARGIN_X = 34
local WIDTH = 560
local PADDING = 18
local LINE_GAP = 8
local THUMBNAIL_SIZE = 54
local ROW_GAP = 10
local CHAMPION_RAIL_WIDTH = 188
local CHAMPION_IMAGE_HEIGHT = 246
local COLUMN_GAP = 18
local CHAMPION_HEALTH_HEIGHT = 22
local PRIZE_ROW_HEIGHT = 34
local PRIZE_ICON_SIZE = 22
local PRIZE_ROW_GAP = 8
local OBJECTIVE_THUMBNAIL_SIZE = 58
local OBJECTIVE_ROW_GAP = 12
local PLAY_BUTTON_SIZE = 34
local PLAY_BUTTON_MARGIN = 10
local PLAY_BUTTON_COLOR = { 0.906, 0.102, 0.176, 1 }
local PLAY_BUTTON_DISABLED_COLOR = { 0.22, 0.235, 0.25, 1 }
local CORNER_ICON_SIZE = 34
local LOADING_FLASH_INTERVAL = 0.06
local FUEL_COST_PULSE_SPEED = 4.2
local ALMS_COLOR = { 0.976, 0.761, 0.169, 1 }
local DOMAIN_PANEL_WIDTH = 250
local DOMAIN_PANEL_GAP = 12
local DOMAIN_PANEL_PADDING = 14
local DOMAIN_PORTRAIT_SIZE = 88
local DOMAIN_BUTTON_HEIGHT = 44
local DOMAIN_BUTTON_GAP = 10
local DOMAIN_ACCENT_COLOR = { 1, 0.725, 0.337, 1 }

local fontCache = {}
local mapImageCache = {}
local iconImageCache = {}
local crewImageCache = {}
local encounterImageCache = {}
local objectiveImageCache = {}
local warzoneImageCache = {}

local function getFont(size)
    local key = tostring(size)

    if fontCache[key] then
        return fontCache[key]
    end

    fontCache[key] = love.graphics.newFont(FONT_PATH, size)
    return fontCache[key]
end

local function getMapImage(fileName)
    if not fileName then
        return nil
    end

    if mapImageCache[fileName] ~= nil then
        return mapImageCache[fileName] or nil
    end

    local imagePath = MAP_IMAGE_DIRECTORY .. fileName

    if not love.filesystem.getInfo(imagePath) then
        mapImageCache[fileName] = false
        return nil
    end

    local image = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    image:setFilter("linear", "linear")
    image:setMipmapFilter("linear")
    mapImageCache[fileName] = image
    return image
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

local function getCrewImage(fileName)
    if not fileName then
        return nil
    end

    if crewImageCache[fileName] ~= nil then
        return crewImageCache[fileName] or nil
    end

    local imagePath = CREW_IMAGE_DIRECTORY .. fileName

    if not love.filesystem.getInfo(imagePath) then
        crewImageCache[fileName] = false
        return nil
    end

    local image = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    image:setFilter("linear", "linear")
    image:setMipmapFilter("linear")
    crewImageCache[fileName] = image
    return image
end

local function getObjectiveDefinitionById(objectiveId)
    if not objectiveId then
        return nil
    end

    for _, objectiveDefinition in ipairs(objectiveDefinitions or {}) do
        if objectiveDefinition.id == objectiveId then
            return objectiveDefinition
        end
    end

    return nil
end

local function getWarzoneDefinitionById(warzoneId)
    if not warzoneId then
        return nil
    end

    for _, warzoneDefinition in ipairs(warzoneDefinitions or {}) do
        if warzoneDefinition.id == warzoneId then
            return warzoneDefinition
        end
    end

    return nil
end

local function getPairedWarzoneVariant(warzoneDefinition)
    if not warzoneDefinition or not warzoneDefinition.id then
        return nil
    end

    local variantId = warzoneDefinition.id:sub(-1) == "B"
        and warzoneDefinition.id:sub(1, -2)
        or (warzoneDefinition.id .. "B")

    return getWarzoneDefinitionById(variantId)
end

local function getObjectivePreviewImage(objectiveId)
    if not objectiveId then
        return nil
    end

    if objectiveImageCache[objectiveId] ~= nil then
        return objectiveImageCache[objectiveId] or nil
    end

    local imagePath = "assets/images/objectives/" .. objectiveId .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        objectiveImageCache[objectiveId] = false
        return nil
    end

    local image = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    image:setFilter("linear", "linear")
    image:setMipmapFilter("linear")
    objectiveImageCache[objectiveId] = image
    return image
end

local function getWarzonePreviewImage(warzoneId)
    if not warzoneId then
        return nil
    end

    if warzoneImageCache[warzoneId] ~= nil then
        return warzoneImageCache[warzoneId] or nil
    end

    local imagePath = WARZONE_IMAGE_DIRECTORY .. warzoneId .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        warzoneImageCache[warzoneId] = false
        return nil
    end

    local image = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    image:setFilter("linear", "linear")
    image:setMipmapFilter("linear")
    warzoneImageCache[warzoneId] = image
    return image
end

local function getNodePreviewIconImage(nodeDefinition)
    if not nodeDefinition then
        return nil
    end

    local candidates = {}

    if nodeDefinition.id then
        candidates[#candidates + 1] = nodeDefinition.id
        candidates[#candidates + 1] = tostring(nodeDefinition.id):lower()
    end

    if nodeDefinition.icon then
        candidates[#candidates + 1] = nodeDefinition.icon
    end

    for _, candidate in ipairs(candidates) do
        local cacheKey = tostring(candidate)

        if mapImageCache[cacheKey] ~= nil then
            return mapImageCache[cacheKey] or nil
        end

        local imagePath = MAP_IMAGE_DIRECTORY .. cacheKey .. ".png"

        if love.filesystem.getInfo(imagePath) then
            local image = love.graphics.newImage(imagePath, {
                mipmaps = true,
            })

            image:setFilter("linear", "linear")
            image:setMipmapFilter("linear")
            mapImageCache[cacheKey] = image
            return image
        end

        mapImageCache[cacheKey] = false
    end

    return nil
end

local function getEncounterPreviewImage(encounter)
    local definition = encounter and encounter.definition or nil

    if not definition or not definition.id then
        return nil
    end

    local directory = nil

    if encounter.sourceKind == "champion" then
        directory = CHAMP_IMAGE_DIRECTORY
    elseif encounter.sourceKind == "stdpkg" then
        directory = STDPKG_IMAGE_DIRECTORY
    elseif encounter.sourceKind == "modularpkg" then
        directory = MODULARPKG_IMAGE_DIRECTORY
    elseif encounter.sourceKind == "warzone" then
        directory = WARZONE_IMAGE_DIRECTORY
    end

    if not directory then
        return nil
    end

    local cacheKey = encounter.sourceKind .. ":" .. definition.id

    if encounterImageCache[cacheKey] ~= nil then
        return encounterImageCache[cacheKey] or nil
    end

    local imagePath = directory .. definition.id .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        encounterImageCache[cacheKey] = false
        return nil
    end

    local image = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    image:setFilter("linear", "linear")
    image:setMipmapFilter("linear")
    encounterImageCache[cacheKey] = image
    return image
end

local function getPlayerMapPosition(state)
    return state and state.playerMapPosition or {
        kind = "start",
    }
end

local function isPlayerMapNode(playerMapPosition, nodeKind, clusterIndex, nodeIndex)
    if not playerMapPosition or playerMapPosition.kind ~= nodeKind then
        return false
    end

    if nodeKind == "start" then
        return true
    end

    return playerMapPosition.clusterIndex == clusterIndex and playerMapPosition.nodeIndex == nodeIndex
end

local function getNextMapPosition(playerMapPosition)
    if not playerMapPosition or playerMapPosition.kind == "start" then
        return {
            kind = "path",
            clusterIndex = 1,
            nodeIndex = 1,
        }
    end

    if playerMapPosition.kind ~= "path" then
        return nil
    end

    local clusterIndex = playerMapPosition.clusterIndex or 1
    local nodeIndex = playerMapPosition.nodeIndex or 1

    if nodeIndex < MAP_CLUSTER_SIZE then
        return {
            kind = "path",
            clusterIndex = clusterIndex,
            nodeIndex = nodeIndex + 1,
        }
    end

    if clusterIndex < MAP_CLUSTER_COUNT then
        return {
            kind = "path",
            clusterIndex = clusterIndex + 1,
            nodeIndex = 1,
        }
    end

    return nil
end

local function isLoadingWorldMapNode(state, clusterIndex, nodeIndex)
    local loadingNode = state and state.pendingMissionSetup and state.loadingWorldMapNode or nil

    return loadingNode
        and loadingNode.clusterIndex == clusterIndex
        and loadingNode.nodeIndex == nodeIndex
end

local function printWrappedLine(text, x, y, width, font)
    love.graphics.printf(text, x, y, width, "left")
    local _, lines = font:getWrap(text, width)

    return y + (#lines * font:getHeight())
end

local function getWrappedLineCount(font, text, width)
    local _, lines = font:getWrap(text or "", width)

    return #lines
end

local function addWorldMapPreviewDeckTarget(state, x, y, width, height, source)
    if not state or not source or not source.definition then
        return
    end

    state.worldMapPreviewDeckTargets = state.worldMapPreviewDeckTargets or {}
    state.worldMapPreviewDeckTargets[#state.worldMapPreviewDeckTargets + 1] = {
        x = x,
        y = y,
        width = width,
        height = height,
        definition = source.definition,
        title = source.name or source.id,
    }
end

local function addWorldMapObjectivePreviewTarget(state, x, y, width, height, card)
    local definition = card and card.definition or nil

    if not state
        or not definition
        or (
            definition.type ~= "objective"
            and definition.type ~= "intel"
            and definition.type ~= "warzone"
            and definition.type ~= "poi"
        ) then
        return
    end

    state.worldMapObjectivePreviewTargets = state.worldMapObjectivePreviewTargets or {}
    state.worldMapObjectivePreviewTargets[#state.worldMapObjectivePreviewTargets + 1] = {
        x = x,
        y = y,
        width = width,
        height = height,
        definition = definition,
    }
end

local function drawEncounterThumbnail(image, x, y, size, accentColor)
    love.graphics.setColor(0.025, 0.028, 0.035, 1)
    love.graphics.rectangle("fill", x, y, size, size, 4, 4)

    if image then
        local scale = math.min(size / image:getWidth(), size / image:getHeight())
        local imageWidth = image:getWidth() * scale
        local imageHeight = image:getHeight() * scale
        local imageX = x + ((size - imageWidth) * 0.5)
        local imageY = y + ((size - imageHeight) * 0.5)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(image, imageX, imageY, 0, scale, scale)
    else
        love.graphics.setColor(0.15, 0.16, 0.19, 1)
        love.graphics.rectangle("fill", x + 4, y + 4, size - 8, size - 8, 3, 3)
    end

    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.86)
    love.graphics.rectangle("line", x, y, size, size, 4, 4)
end

local function drawEncounterPreviewRow(row, x, y, textX, textWidth, thumbnailSize, titleFont, metaFont, accentColor, state)
    drawEncounterThumbnail(row.image, x, y, thumbnailSize, accentColor)
    addWorldMapPreviewDeckTarget(state, x, y, thumbnailSize, thumbnailSize, row)

    love.graphics.setFont(metaFont)
    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 1)
    love.graphics.printf(row.sourceLabel or "Encounter", textX, y + 2, textWidth, "left")

    love.graphics.setFont(titleFont)
    love.graphics.setColor(0.94, 0.95, 0.96, 1)
    love.graphics.printf(row.name or row.id or "?", textX, y + metaFont:getHeight() + 5, textWidth, "left")
end

local function drawChampionHealthBar(championRow, x, y, width, height)
    local health = math.max(0, math.floor(tonumber(championRow and championRow.health) or 0))
    local maxHealth = math.max(1, math.floor(tonumber(championRow and championRow.max) or health or 1))
    local gap = 3
    local pipCount = math.min(maxHealth, 24)
    local columns = math.min(pipCount, 10)
    local rows = math.max(1, math.ceil(pipCount / columns))
    local maxPipWidth = math.floor((width - ((columns - 1) * gap)) / columns)
    local maxPipHeight = math.floor((height - ((rows - 1) * gap)) / rows)
    local pipSize = math.max(3, math.min(maxPipWidth, maxPipHeight))
    local startX = x + ((width - ((columns * pipSize) + ((columns - 1) * gap))) * 0.5)
    local startY = y + ((height - ((rows * pipSize) + ((rows - 1) * gap))) * 0.5)

    for pipIndex = 1, pipCount do
        local row = math.floor((pipIndex - 1) / columns)
        local column = (pipIndex - 1) % columns
        local pipX = startX + (column * (pipSize + gap))
        local pipY = startY + (row * (pipSize + gap))

        if pipIndex <= health then
            love.graphics.setColor(1, 0.855, 0.255, 1)
        else
            love.graphics.setColor(0.2, 0.18, 0.09, 0.95)
        end

        love.graphics.rectangle("fill", pipX, pipY, pipSize, pipSize)
    end
end

local function getChampionIntelPreviewCards(championDefinition)
    local cards = {}

    for _, intelEntry in ipairs(championDefinition and championDefinition.intelDeck or {}) do
        local objectiveDefinition = getObjectiveDefinitionById(intelEntry.cardId)

        if objectiveDefinition then
            cards[#cards + 1] = {
                id = objectiveDefinition.id,
                name = objectiveDefinition.name,
                quantity = math.max(1, math.floor(tonumber(intelEntry.quantity) or 1)),
                definition = objectiveDefinition,
                image = getObjectivePreviewImage(objectiveDefinition.id),
            }
        end
    end

    return cards
end

local function getChampionObjectivePreviewCards(championDefinition)
    local cards = {}
    local seenObjectiveIds = {}
    local objectiveId = championDefinition and (championDefinition.PrimaryObjective or championDefinition.primaryObjective) or nil

    while objectiveId and not seenObjectiveIds[objectiveId] do
        seenObjectiveIds[objectiveId] = true

        local objectiveDefinition = getObjectiveDefinitionById(objectiveId)

        if not objectiveDefinition then
            break
        end

        cards[#cards + 1] = {
            id = objectiveDefinition.id,
            name = objectiveDefinition.name,
            definition = objectiveDefinition,
            image = getObjectivePreviewImage(objectiveDefinition.id),
        }

        objectiveId = objectiveDefinition.escalate
    end

    return cards
end

local function getLinkedPoiForWarzone(warzoneDefinition)
    if not warzoneDefinition then
        return nil
    end

    local poiId = warzoneDefinition.poi
    local pairedVariant = nil

    if not poiId then
        pairedVariant = getPairedWarzoneVariant(warzoneDefinition)
        poiId = pairedVariant and pairedVariant.poi or nil
    end

    return getWarzoneDefinitionById(poiId)
end

local function buildWarzonePreviewCard(warzoneRow)
    local definition = warzoneRow and warzoneRow.definition or nil

    if not definition then
        return nil
    end

    return {
        id = definition.id,
        name = definition.name,
        definition = definition,
        image = getWarzonePreviewImage(definition.id),
    }
end

local function buildPoiPreviewCard(warzoneRow)
    local definition = getLinkedPoiForWarzone(warzoneRow and warzoneRow.definition or nil)

    if not definition then
        return nil
    end

    return {
        id = definition.id,
        name = definition.name,
        definition = definition,
        image = getWarzonePreviewImage(definition.id),
    }
end

local function drawObjectivePreviewCard(card, x, y, size, labelFont, accentColor, state)
    love.graphics.setColor(0.025, 0.028, 0.035, 1)
    love.graphics.rectangle("fill", x, y, size, size, 4, 4)

    if card and card.image then
        local image = card.image
        local scale = math.min(size / image:getWidth(), size / image:getHeight())
        local imageWidth = image:getWidth() * scale
        local imageHeight = image:getHeight() * scale

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            image,
            x + ((size - imageWidth) * 0.5),
            y + ((size - imageHeight) * 0.5),
            0,
            scale,
            scale
        )
    else
        love.graphics.setColor(0.15, 0.16, 0.19, 1)
        love.graphics.rectangle("fill", x + 4, y + 4, size - 8, size - 8, 3, 3)
    end

    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.86)
    love.graphics.rectangle("line", x, y, size, size, 4, 4)
    addWorldMapObjectivePreviewTarget(state, x, y, size, size, card)

    if card and card.quantity and card.quantity > 1 then
        local badgeSize = 18

        love.graphics.setColor(0.02, 0.02, 0.025, 0.94)
        love.graphics.rectangle("fill", x + size - badgeSize - 4, y + size - badgeSize - 4, badgeSize, badgeSize, 3, 3)
        love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.95)
        love.graphics.rectangle("line", x + size - badgeSize - 4, y + size - badgeSize - 4, badgeSize, badgeSize, 3, 3)
        love.graphics.setFont(labelFont)
        love.graphics.setColor(0.95, 0.96, 0.98, 1)
        love.graphics.printf("x" .. tostring(card.quantity), x + size - badgeSize - 4, y + size - badgeSize + 1, badgeSize, "center")
    end
end

local function drawObjectivePreviewRow(labelText, cards, x, y, width, cardSize, labelFont, accentColor, state)
    if not cards or #cards <= 0 then
        return
    end

    local _, labelLines = labelFont:getWrap(labelText or "", width)
    local labelHeight = math.max(1, #labelLines) * labelFont:getHeight()

    love.graphics.setFont(labelFont)
    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 1)
    love.graphics.printf(labelText, x, y, width, "left")

    local cardY = y + labelHeight + 5
    local gap = #cards > 1 and math.max(8, math.floor((width - (#cards * cardSize)) / (#cards - 1))) or 0

    gap = math.min(gap, 14)

    for cardIndex, card in ipairs(cards or {}) do
        local cardX = x + ((cardIndex - 1) * (cardSize + gap))

        drawObjectivePreviewCard(card, cardX, cardY, cardSize, labelFont, accentColor, state)
    end
end

local function getWrappedLabelHeight(labelFont, labelText, width)
    local _, labelLines = labelFont:getWrap(labelText or "", width)

    return math.max(1, #labelLines) * labelFont:getHeight()
end

local function getSplitPreviewRowMetrics(leftLabel, leftCards, rightLabel, rightCards, x, width, cardSize, labelFont)
    local gap = OBJECTIVE_ROW_GAP + 8
    local leftCount = #(leftCards or {})
    local rightCount = #(rightCards or {})
    local leftCardGap = leftCount > 1 and math.min(14, math.max(8, math.floor((width - (leftCount * cardSize)) / math.max(1, leftCount - 1)))) or 0
    local leftRequiredWidth = leftCount > 0 and ((leftCount * cardSize) + ((leftCount - 1) * leftCardGap)) or 0
    local rightRequiredWidth = rightCount > 0 and cardSize or 0
    local minRightX = x + leftRequiredWidth + gap
    local preferredRightX = x + ((width - gap) * 0.5) + gap
    local maxRightX = x + width - rightRequiredWidth
    local rightX = math.min(maxRightX, math.max(preferredRightX, minRightX))
    local leftWidth = math.max(cardSize, rightX - x - gap)
    local rightWidth = math.max(cardSize, x + width - rightX)
    local leftLabelHeight = leftCount > 0 and getWrappedLabelHeight(labelFont, leftLabel, leftWidth) or 0
    local rightLabelHeight = rightCount > 0 and getWrappedLabelHeight(labelFont, rightLabel, rightWidth) or 0

    return {
        rightX = rightX,
        leftWidth = leftWidth,
        rightWidth = rightWidth,
        height = math.max(leftLabelHeight, rightLabelHeight) + 5 + cardSize,
    }
end

local function drawSplitPreviewRow(leftLabel, leftCards, rightLabel, rightCards, x, y, width, cardSize, labelFont, accentColor, state)
    local metrics = getSplitPreviewRowMetrics(leftLabel, leftCards, rightLabel, rightCards, x, width, cardSize, labelFont)

    drawObjectivePreviewRow(leftLabel, leftCards, x, y, metrics.leftWidth, cardSize, labelFont, accentColor, state)
    drawObjectivePreviewRow(rightLabel, rightCards, metrics.rightX, y, metrics.rightWidth, cardSize, labelFont, accentColor, state)

    return metrics.height
end

local function shouldDrawNodePreviewPlayButton(state, hoveredNode)
    local nextMapPosition = getNextMapPosition(getPlayerMapPosition(state))

    return hoveredNode
        and isPlayerMapNode(nextMapPosition, "path", hoveredNode.clusterIndex, hoveredNode.nodeIndex)
end

local function drawNodePreviewPlayButton(state, hoveredNode, panelX, panelY, panelWidth)
    local buttonSize = PLAY_BUTTON_SIZE
    local buttonX = panelX + panelWidth - PLAY_BUTTON_MARGIN - buttonSize
    local buttonY = panelY + PLAY_BUTTON_MARGIN
    local triangleInsetX = buttonSize * 0.34
    local triangleInsetY = buttonSize * 0.28
    local isEnabled = worldfuelrules.isCurrentSegmentCleared(state)

    if isEnabled then
        love.graphics.setColor(PLAY_BUTTON_COLOR[1], PLAY_BUTTON_COLOR[2], PLAY_BUTTON_COLOR[3], PLAY_BUTTON_COLOR[4])
    else
        love.graphics.setColor(
            PLAY_BUTTON_DISABLED_COLOR[1],
            PLAY_BUTTON_DISABLED_COLOR[2],
            PLAY_BUTTON_DISABLED_COLOR[3],
            PLAY_BUTTON_DISABLED_COLOR[4]
        )
    end
    love.graphics.rectangle("fill", buttonX, buttonY, buttonSize, buttonSize, 3, 3)
    love.graphics.setColor(0.96, 0.96, 0.95, isEnabled and 1 or 0.34)
    love.graphics.polygon(
        "fill",
        buttonX + triangleInsetX,
        buttonY + triangleInsetY,
        buttonX + triangleInsetX,
        buttonY + buttonSize - triangleInsetY,
        buttonX + buttonSize - triangleInsetX + 2,
        buttonY + (buttonSize * 0.5)
    )

    if not isEnabled then
        local fuelImage = getMapImage("fuelcost.png")

        if fuelImage then
            local pulse = (math.sin(love.timer.getTime() * FUEL_COST_PULSE_SPEED) + 1) * 0.5
            local iconSize = math.floor(buttonSize * 0.78)
            local imageScale = math.min(iconSize / fuelImage:getWidth(), iconSize / fuelImage:getHeight())
            local imageWidth = math.floor((fuelImage:getWidth() * imageScale) + 0.5)
            local imageHeight = math.floor((fuelImage:getHeight() * imageScale) + 0.5)
            local drawX = math.floor(buttonX + ((buttonSize - imageWidth) * 0.5) + 0.5)
            local drawY = math.floor(buttonY + ((buttonSize - imageHeight) * 0.5) + 0.5)

            love.graphics.setColor(1, 1, 1, pulse)
            love.graphics.draw(
                fuelImage,
                drawX,
                drawY,
                0,
                imageWidth / fuelImage:getWidth(),
                imageHeight / fuelImage:getHeight()
            )
        end
    end

    if state then
        state.worldMapNodePlayButtonTargets = state.worldMapNodePlayButtonTargets or {}
        state.worldMapNodePlayButtonTargets[#state.worldMapNodePlayButtonTargets + 1] = {
            x = buttonX,
            y = buttonY,
            width = buttonSize,
            height = buttonSize,
            hoveredNode = hoveredNode,
            disabled = not isEnabled,
        }
        state.worldMapNodePlayButtonTarget = state.worldMapNodePlayButtonTargets[#state.worldMapNodePlayButtonTargets]
    end
end

local function drawNodePreviewCornerIcon(hoveredNode, panelX, panelY)
    local image = getNodePreviewIconImage(hoveredNode and hoveredNode.nodeDefinition or nil)

    if not image then
        return
    end

    local iconSize = CORNER_ICON_SIZE
    local iconX = panelX - math.floor(iconSize * 0.32)
    local iconY = panelY - math.floor(iconSize * 0.32)
    local imageScale = math.min(iconSize / image:getWidth(), iconSize / image:getHeight())
    local imageWidth = image:getWidth() * imageScale
    local imageHeight = image:getHeight() * imageScale

    love.graphics.setColor(0.015, 0.018, 0.023, 0.96)
    love.graphics.rectangle("fill", iconX, iconY, iconSize, iconSize, 5, 5)
    love.graphics.setColor(0.9, 0.92, 0.95, 0.78)
    love.graphics.rectangle("line", iconX, iconY, iconSize, iconSize, 5, 5)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        image,
        iconX + ((iconSize - imageWidth) * 0.5),
        iconY + ((iconSize - imageHeight) * 0.5),
        0,
        imageScale,
        imageScale
    )
end

local function drawImageCover(image, x, y, width, height, alpha)
    if not image then
        return
    end

    local scale = math.max(width / image:getWidth(), height / image:getHeight())
    local imageWidth = image:getWidth() * scale
    local imageHeight = image:getHeight() * scale
    local drawX = math.floor(x + ((width - imageWidth) * 0.5) + 0.5)
    local drawY = math.floor(y + ((height - imageHeight) * 0.5) + 0.5)
    local previousScissorX, previousScissorY, previousScissorWidth, previousScissorHeight = love.graphics.getScissor()

    love.graphics.setScissor(x, y, width, height)
    love.graphics.setColor(1, 1, 1, alpha or 1)
    love.graphics.draw(image, drawX, drawY, 0, scale, scale)

    if previousScissorX then
        love.graphics.setScissor(previousScissorX, previousScissorY, previousScissorWidth, previousScissorHeight)
    else
        love.graphics.setScissor()
    end
end

local function drawDomainAwarenessIcon(image, x, y, size, alpha)
    x = math.floor(x + 0.5)
    y = math.floor(y + 0.5)
    size = math.floor(size + 0.5)

    if image then
        love.graphics.setColor(1, 1, 1, alpha or 1)
        love.graphics.draw(image, x, y, 0, size / image:getWidth(), size / image:getHeight())
    else
        love.graphics.setColor(0.82, 0.85, 0.89, alpha or 1)
        love.graphics.rectangle("line", x, y, size, size, 3, 3)
    end
end

local function addDomainAwarenessTarget(state, button)
    if not state or not button then
        return
    end

    state.worldMapDomainAwarenessTargets = state.worldMapDomainAwarenessTargets or {}
    state.worldMapDomainAwarenessTargets[#state.worldMapDomainAwarenessTargets + 1] = {
        x = button.x,
        y = button.y,
        width = button.width,
        height = button.height,
        id = button.id,
    }
end

local function drawDomainAwarenessButton(state, button, font)
    local isDisabled = state and state.pendingDomainAwareness ~= nil
    local alpha = isDisabled and 0.38 or 1
    local iconSize = 24
    local iconGap = 5
    local textGap = 8
    local buttonCenterY = button.y + (button.height * 0.5)
    local iconY = math.floor(buttonCenterY - (iconSize * 0.5) + 0.5)
    local costWidth = (#button.costIcons * iconSize) + ((#button.costIcons - 1) * iconGap)
    local colonText = ":"
    local valueText = button.value or ""
    local groupWidth = costWidth
        + textGap
        + font:getWidth(colonText)
        + textGap
        + iconSize
        + textGap
        + font:getWidth(valueText)
    local x = math.floor(button.x + ((button.width - groupWidth) * 0.5) + 0.5)

    love.graphics.setColor(0.01, 0.012, 0.016, 0.94 * alpha)
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 4, 4)
    love.graphics.setColor(DOMAIN_ACCENT_COLOR[1], DOMAIN_ACCENT_COLOR[2], DOMAIN_ACCENT_COLOR[3], 0.86 * alpha)
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 4, 4)

    for _, iconFile in ipairs(button.costIcons) do
        drawDomainAwarenessIcon(getMapImage(iconFile), x, iconY, iconSize, alpha)
        x = x + iconSize + iconGap
    end

    love.graphics.setFont(font)
    love.graphics.setColor(0.94, 0.95, 0.96, alpha)
    love.graphics.print(colonText, x + (textGap - iconGap), math.floor(buttonCenterY - (font:getHeight() * 0.5) + 0.5))
    x = x + textGap + font:getWidth(colonText) + textGap - iconGap

    drawDomainAwarenessIcon(getIconImage(button.rewardIcon), x, iconY, iconSize, alpha)
    x = x + iconSize + textGap

    love.graphics.setFont(font)
    love.graphics.setColor(0.94, 0.95, 0.96, alpha)
    love.graphics.print(valueText, x, math.floor(buttonCenterY - (font:getHeight() * 0.5) + 0.5))

    addDomainAwarenessTarget(state, button)

    if isDisabled then
        love.graphics.setColor(0, 0, 0, 0.34)
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 4, 4)
        love.graphics.setColor(0.42, 0.44, 0.48, 0.78)
        love.graphics.line(button.x + 5, button.y + button.height - 5, button.x + button.width - 5, button.y + 5)
    end
end

local function drawDomainAwarenessPanel(state, previewPanel)
    if not state
        or not previewPanel
        or crewrules.isCrewRoleDead(state.deadCrewRoles, "Tactician") then
        return
    end

    local screenWidth, screenHeight = love.graphics.getDimensions()
    local buttonFont = getFont(13)
    local panelWidth = DOMAIN_PANEL_WIDTH
    local panelHeight = DOMAIN_PANEL_PADDING
        + DOMAIN_PORTRAIT_SIZE
        + 16
        + (DOMAIN_BUTTON_HEIGHT * 3)
        + (DOMAIN_BUTTON_GAP * 2)
        + DOMAIN_PANEL_PADDING
    local panelX = math.floor(previewPanel.x + previewPanel.width + DOMAIN_PANEL_GAP + 0.5)
    local panelY = math.floor(previewPanel.y + ((previewPanel.height - panelHeight) * 0.5) + 0.5)

    if panelX + panelWidth > screenWidth - MARGIN_X then
        panelX = math.floor(previewPanel.x - DOMAIN_PANEL_GAP - panelWidth + 0.5)
    end

    panelY = math.max(MARGIN_X, math.min(screenHeight - MARGIN_X - panelHeight, panelY))

    local portraitX = math.floor(panelX + ((panelWidth - DOMAIN_PORTRAIT_SIZE) * 0.5) + 0.5)
    local portraitY = panelY + DOMAIN_PANEL_PADDING
    local buttonX = panelX + DOMAIN_PANEL_PADDING
    local buttonWidth = panelWidth - (DOMAIN_PANEL_PADDING * 2)
    local buttonY = portraitY + DOMAIN_PORTRAIT_SIZE + 16
    local buttons = {
        {
            id = "domain-reroll",
            x = buttonX,
            y = buttonY,
            width = buttonWidth,
            height = DOMAIN_BUTTON_HEIGHT,
            costIcons = { "tithes.png", "tithes.png" },
            rewardIcon = "reroll.png",
            value = "+2 / TURN",
        },
        {
            id = "domain-method",
            x = buttonX,
            y = buttonY + DOMAIN_BUTTON_HEIGHT + DOMAIN_BUTTON_GAP,
            width = buttonWidth,
            height = DOMAIN_BUTTON_HEIGHT,
            costIcons = { "munitions.png", "munitions.png" },
            rewardIcon = "method.png",
            value = "+1",
        },
        {
            id = "domain-draw",
            x = buttonX,
            y = buttonY + ((DOMAIN_BUTTON_HEIGHT + DOMAIN_BUTTON_GAP) * 2),
            width = buttonWidth,
            height = DOMAIN_BUTTON_HEIGHT,
            costIcons = { "munitions.png" },
            rewardIcon = "draw.png",
            value = "+3",
        },
    }

    love.graphics.setColor(0.02, 0.025, 0.03, 0.58)
    love.graphics.rectangle("fill", panelX - 6, panelY - 6, panelWidth + 12, panelHeight + 12, 8, 8)
    love.graphics.setColor(0.06, 0.07, 0.09, 0.97)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 6, 6)
    love.graphics.setColor(DOMAIN_ACCENT_COLOR[1], DOMAIN_ACCENT_COLOR[2], DOMAIN_ACCENT_COLOR[3], 0.95)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 6, 6)

    love.graphics.setColor(0.075, 0.082, 0.095, 0.92)
    love.graphics.rectangle("fill", portraitX, portraitY, DOMAIN_PORTRAIT_SIZE, DOMAIN_PORTRAIT_SIZE, 5, 5)
    love.graphics.setColor(DOMAIN_ACCENT_COLOR[1], DOMAIN_ACCENT_COLOR[2], DOMAIN_ACCENT_COLOR[3], 0.9)
    love.graphics.rectangle("line", portraitX, portraitY, DOMAIN_PORTRAIT_SIZE, DOMAIN_PORTRAIT_SIZE, 5, 5)
    drawImageCover(getCrewImage("tactician.png"), portraitX + 5, portraitY + 5, DOMAIN_PORTRAIT_SIZE - 10, DOMAIN_PORTRAIT_SIZE - 10, 1)

    for _, button in ipairs(buttons) do
        drawDomainAwarenessButton(state, button, buttonFont)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

local function drawChampionPreviewPrize(prize, x, y, width, height, valueFont)
    local value = tonumber(prize)

    if not value then
        return
    end

    local iconSize = PRIZE_ICON_SIZE
    local iconGap = 8
    local valueText = tostring(math.floor(math.max(0, value)))
    local textWidth = valueFont:getWidth(valueText)
    local contentWidth = iconSize + iconGap + textWidth
    local startX = math.floor(x + math.max(0, (width - contentWidth) * 0.5) + 0.5)
    local iconY = math.floor(y + ((height - iconSize) * 0.5) + 0.5)
    local image = getMapImage("alms.png")

    if image then
        local imageScale = math.min(iconSize / image:getWidth(), iconSize / image:getHeight())
        local imageWidth = image:getWidth() * imageScale
        local imageHeight = image:getHeight() * imageScale

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            image,
            math.floor(startX + ((iconSize - imageWidth) * 0.5) + 0.5),
            math.floor(iconY + ((iconSize - imageHeight) * 0.5) + 0.5),
            0,
            imageScale,
            imageScale
        )
    end

    love.graphics.setFont(valueFont)
    love.graphics.setColor(ALMS_COLOR[1], ALMS_COLOR[2], ALMS_COLOR[3], 1)
    love.graphics.print(
        valueText,
        startX + iconSize + iconGap,
        math.floor(y + ((height - valueFont:getHeight()) * 0.5) + 0.5)
    )
end

local function drawChampionPreviewRail(championRow, prize, cardReward, x, y, width, imageHeight, healthHeight, labelHeight, prizeHeight, cardRewardHeight, titleFont, metaFont, prizeFont, accentColor, state)
    local nameText = championRow and (championRow.name or championRow.id) or "Unknown Champion"
    local frameX = x
    local frameY = y
    local frameWidth = width
    local frameHeight = imageHeight
    local labelY = nil

    if championRow and championRow.image then
        local image = championRow.image
        local scale = math.min(width / image:getWidth(), imageHeight / image:getHeight())
        local scaledImageWidth = image:getWidth() * scale
        local scaledImageHeight = image:getHeight() * scale
        local previousScissorX, previousScissorY, previousScissorWidth, previousScissorHeight = love.graphics.getScissor()

        frameX = x + ((width - scaledImageWidth) * 0.5)
        frameWidth = scaledImageWidth
        frameHeight = scaledImageHeight

        love.graphics.setColor(0.025, 0.028, 0.035, 1)
        love.graphics.rectangle("fill", frameX, frameY, frameWidth, frameHeight, 5, 5)
        love.graphics.setScissor(frameX, frameY, frameWidth, frameHeight)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(image, frameX, frameY, 0, scale, scale)

        if previousScissorX then
            love.graphics.setScissor(previousScissorX, previousScissorY, previousScissorWidth, previousScissorHeight)
        else
            love.graphics.setScissor()
        end
    else
        frameX = x + 6
        frameY = y + 6
        frameWidth = width - 12
        frameHeight = imageHeight - 12

        love.graphics.setColor(0.025, 0.028, 0.035, 1)
        love.graphics.rectangle("fill", frameX, frameY, frameWidth, frameHeight, 5, 5)
        love.graphics.setColor(0.15, 0.16, 0.19, 1)
        love.graphics.rectangle("fill", frameX + 6, frameY + 6, frameWidth - 12, frameHeight - 12, 3, 3)
    end

    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.9)
    love.graphics.rectangle("line", frameX, frameY, frameWidth, frameHeight, 5, 5)

    addWorldMapPreviewDeckTarget(state, frameX, frameY, frameWidth, frameHeight, championRow)

    labelY = frameY + frameHeight + healthHeight
    love.graphics.setColor(0.035, 0.035, 0.025, 0.98)
    love.graphics.rectangle("fill", frameX, frameY + frameHeight, frameWidth, healthHeight)
    drawChampionHealthBar(championRow, frameX + 10, frameY + frameHeight + 4, frameWidth - 20, healthHeight - 8)

    love.graphics.setColor(0.02, 0.02, 0.025, 0.96)
    love.graphics.rectangle("fill", frameX, labelY, frameWidth, labelHeight, 0, 0)

    love.graphics.setFont(metaFont)
    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 1)
    love.graphics.printf("Champion", frameX + 10, labelY + 8, frameWidth - 20, "left")

    love.graphics.setFont(titleFont)
    love.graphics.setColor(0.94, 0.95, 0.96, 1)
    love.graphics.printf(nameText, frameX + 10, labelY + metaFont:getHeight() + 12, frameWidth - 20, "left")

    drawChampionPreviewPrize(prize, frameX, labelY + labelHeight + PRIZE_ROW_GAP, frameWidth, prizeHeight, prizeFont)

    if tostring(cardReward or ""):lower() == "regular" then
        local cardRewardImage = getMapImage("cardreg.png")

        if cardRewardImage then
            local cardRewardIconSize = 32
            local cardRewardScale = math.min(cardRewardIconSize / cardRewardImage:getWidth(), cardRewardIconSize / cardRewardImage:getHeight())
            local cardRewardWidth = cardRewardImage:getWidth() * cardRewardScale
            local cardRewardImageHeight = cardRewardImage:getHeight() * cardRewardScale
            local cardRewardY = labelY + labelHeight + PRIZE_ROW_GAP + prizeHeight

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                cardRewardImage,
                math.floor(frameX + ((frameWidth - cardRewardWidth) * 0.5) + 0.5),
                math.floor(cardRewardY + ((cardRewardHeight - cardRewardImageHeight) * 0.5) + 0.5),
                0,
                cardRewardScale,
                cardRewardScale
            )
        end
    end
end

local function getNodePreviewEdge(hoveredNode)
    local pos = hoveredNode
        and hoveredNode.nodeDefinition
        and hoveredNode.nodeDefinition.pos
        or nil

    return tostring(pos):lower() == "bottom" and "bottom" or "top"
end

local function drawNodeEncounterPreview(state, hoveredNode, panelIndexOnEdge)
    local preview = hoveredNode and hoveredNode.preview or nil

    if not preview then
        return
    end

    local screenWidth, screenHeight = love.graphics.getDimensions()
    local titleFont = getFont(18)
    local bodyFont = getFont(13)
    local smallFont = getFont(11)
    local championLabelFont = getFont(15)
    local championNameFont = getFont(18)
    local panelWidth = math.min(WIDTH, screenWidth * 0.48)
    local contentWidth = panelWidth - (PADDING * 2)
    local championRailWidth = math.min(CHAMPION_RAIL_WIDTH, contentWidth * 0.42)
    local rightColumnXOffset = championRailWidth + COLUMN_GAP
    local rightContentWidth = contentWidth - rightColumnXOffset
    local titleText = preview.title or "Node"
    local summaryText = preview.summary or ""
    local detailLines = {}
    local championRow = nil
    local warzoneRow = nil
    local packageRows = {}
    local encounterTextWidth = rightContentWidth - THUMBNAIL_SIZE - ROW_GAP

    for _, detail in ipairs(preview.details or {}) do
        detailLines[#detailLines + 1] = detail
    end

    for _, encounter in ipairs(preview.encounters or {}) do
        local definition = encounter.definition or {}
        local row = {
            sourceLabel = encounter.sourceLabel,
            sourceKind = encounter.sourceKind,
            name = definition.name,
            id = definition.id,
            health = definition.health,
            max = definition.max,
            definition = definition,
            image = getEncounterPreviewImage(encounter),
        }

        if encounter.sourceKind == "champion" and not championRow then
            championRow = row
        elseif encounter.sourceKind == "warzone" and not warzoneRow then
            warzoneRow = row
        else
            packageRows[#packageRows + 1] = row
        end
    end

    if not championRow and not warzoneRow and #packageRows == 0 then
        packageRows[#packageRows + 1] = {
            sourceLabel = "Encounter",
            name = "No matching encounter entries.",
        }
    end

    local intelCards = getChampionIntelPreviewCards(championRow and championRow.definition or nil)
    local objectiveCards = getChampionObjectivePreviewCards(championRow and championRow.definition or nil)
    local warzoneCard = buildWarzonePreviewCard(warzoneRow)
    local poiCard = buildPoiPreviewCard(warzoneRow)
    local warzoneCards = warzoneCard and { warzoneCard } or {}
    local poiCards = poiCard and { poiCard } or {}
    local hasIntelRow = #intelCards > 0 or #warzoneCards > 0
    local hasObjectiveRow = #objectiveCards > 0 or #poiCards > 0
    local intelRowHeight = hasIntelRow
        and getSplitPreviewRowMetrics("Intel Deck", intelCards, "Warzone", warzoneCards, 0, rightContentWidth, OBJECTIVE_THUMBNAIL_SIZE, smallFont).height
        or 0
    local objectiveRowHeight = hasObjectiveRow
        and getSplitPreviewRowMetrics("Objectives", objectiveCards, "Person of Interest", poiCards, 0, rightContentWidth, OBJECTIVE_THUMBNAIL_SIZE, smallFont).height
        or 0

    local rightColumnHeight = PADDING
        + titleFont:getHeight()
        + LINE_GAP
        + (getWrappedLineCount(bodyFont, summaryText, rightContentWidth) * bodyFont:getHeight())
        + LINE_GAP

    for _, detail in ipairs(detailLines) do
        rightColumnHeight = rightColumnHeight + (getWrappedLineCount(bodyFont, detail, rightContentWidth) * bodyFont:getHeight()) + 4
    end

    rightColumnHeight = rightColumnHeight + LINE_GAP

    for _, encounterRow in ipairs(packageRows) do
        local nameHeight = getWrappedLineCount(bodyFont, encounterRow.name or encounterRow.id or "?", encounterTextWidth) * bodyFont:getHeight()
        local textHeight = smallFont:getHeight() + 5 + nameHeight

        rightColumnHeight = rightColumnHeight + math.max(THUMBNAIL_SIZE, textHeight) + ROW_GAP
    end

    if hasIntelRow then
        rightColumnHeight = rightColumnHeight + intelRowHeight + OBJECTIVE_ROW_GAP
    end

    if hasObjectiveRow then
        rightColumnHeight = rightColumnHeight + objectiveRowHeight + OBJECTIVE_ROW_GAP
    end

    rightColumnHeight = rightColumnHeight + PADDING

    local prize = preview.prize
    local prizeHeight = tonumber(prize) and PRIZE_ROW_HEIGHT or 0
    local cardReward = preview.cardrw
    local cardRewardHeight = tostring(cardReward or ""):lower() == "regular" and 38 or 0
    local rewardGap = (prizeHeight > 0 or cardRewardHeight > 0) and PRIZE_ROW_GAP or 0
    local championRailHeight = CHAMPION_IMAGE_HEIGHT + CHAMPION_HEALTH_HEIGHT + 70 + prizeHeight + cardRewardHeight + rewardGap
    local panelHeight = math.max(rightColumnHeight, championRailHeight + (PADDING * 2))
    local previewEdge = getNodePreviewEdge(hoveredNode)
    local panelX = (screenWidth - panelWidth) * 0.5
    local panelOffsetY = ((panelIndexOnEdge or 1) - 1) * (panelHeight + MARGIN_X)
    local panelY = previewEdge == "bottom"
        and math.max(MARGIN_X, screenHeight - MARGIN_X - panelHeight - panelOffsetY)
        or (MARGIN_X + panelOffsetY)
    local accentColor = hoveredNode.nodeDefinition and hoveredNode.nodeDefinition.accentColor or { 0.82, 0.85, 0.89, 1 }
    local railX = panelX + PADDING
    local railY = panelY + ((panelHeight - championRailHeight) * 0.5)
    local contentX = panelX + PADDING + rightColumnXOffset
    local showPlayButton = shouldDrawNodePreviewPlayButton(state, hoveredNode)
    local y = panelY + PADDING
    local isLoadingPreview = isLoadingWorldMapNode(state, hoveredNode.clusterIndex, hoveredNode.nodeIndex)

    love.graphics.setColor(0.02, 0.025, 0.03, 0.58)
    love.graphics.rectangle("fill", panelX - 6, panelY - 6, panelWidth + 12, panelHeight + 12, 8, 8)
    love.graphics.setColor(0.06, 0.07, 0.09, 0.97)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 6, 6)

    if isLoadingPreview then
        local pendingElapsed = state.pendingMissionSetup and state.pendingMissionSetup.elapsed or 0

        if math.floor(pendingElapsed / LOADING_FLASH_INTERVAL) % 2 == 0 then
            love.graphics.setColor(1, 0.73, 0.08, 1)
        else
            love.graphics.setColor(0, 0, 0, 1)
        end
    else
        love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.95)
    end

    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 6, 6)
    drawNodePreviewCornerIcon(hoveredNode, panelX, panelY)

    if showPlayButton then
        drawNodePreviewPlayButton(state, hoveredNode, panelX, panelY, panelWidth)
    end

    drawChampionPreviewRail(
        championRow,
        prize,
        cardReward,
        railX,
        railY,
        championRailWidth,
        CHAMPION_IMAGE_HEIGHT,
        CHAMPION_HEALTH_HEIGHT,
        70,
        prizeHeight,
        cardRewardHeight,
        championNameFont,
        championLabelFont,
        bodyFont,
        accentColor,
        state
    )

    love.graphics.setFont(titleFont)
    love.graphics.setColor(0.95, 0.96, 0.98, 1)
    love.graphics.printf(
        titleText,
        contentX,
        y,
        showPlayButton and math.max(1, rightContentWidth - PLAY_BUTTON_SIZE - PLAY_BUTTON_MARGIN) or rightContentWidth,
        "left"
    )
    y = y + titleFont:getHeight() + LINE_GAP

    love.graphics.setFont(bodyFont)
    love.graphics.setColor(0.78, 0.81, 0.84, 1)
    y = printWrappedLine(summaryText, contentX, y, rightContentWidth, bodyFont) + LINE_GAP

    love.graphics.setColor(0.9, 0.91, 0.92, 0.95)
    for _, detail in ipairs(detailLines) do
        y = printWrappedLine(detail, contentX, y, rightContentWidth, bodyFont) + 4
    end

    y = y + LINE_GAP

    love.graphics.setFont(smallFont)
    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 1)
    for _, encounterRow in ipairs(packageRows) do
        local rowTextX = contentX + THUMBNAIL_SIZE + ROW_GAP
        local nameHeight = getWrappedLineCount(bodyFont, encounterRow.name or encounterRow.id or "?", encounterTextWidth) * bodyFont:getHeight()
        local textHeight = smallFont:getHeight() + 5 + nameHeight
        local rowHeight = math.max(THUMBNAIL_SIZE, textHeight)

        drawEncounterPreviewRow(encounterRow, contentX, y, rowTextX, encounterTextWidth, THUMBNAIL_SIZE, bodyFont, smallFont, accentColor, state)
        y = y + rowHeight + ROW_GAP
    end

    if hasIntelRow then
        y = y + drawSplitPreviewRow(
            "Intel Deck",
            intelCards,
            "Warzone",
            warzoneCards,
            contentX,
            y,
            rightContentWidth,
            OBJECTIVE_THUMBNAIL_SIZE,
            smallFont,
            accentColor,
            state
        ) + OBJECTIVE_ROW_GAP
    end

    if hasObjectiveRow then
        drawSplitPreviewRow(
            "\nObjectives",
            objectiveCards,
            "Person of Interest",
            poiCards,
            contentX,
            y,
            rightContentWidth,
            OBJECTIVE_THUMBNAIL_SIZE,
            smallFont,
            accentColor,
            state
        )
    end

    drawDomainAwarenessPanel(state, {
        x = panelX,
        y = panelY,
        width = panelWidth,
        height = panelHeight,
    })
end

function worldencounterpreviewdraw.drawGroup(state, previewGroup)
    if state then
        state.worldMapDomainAwarenessTargets = {}
    end

    local previewNodes = previewGroup and previewGroup.previewNodes or nil

    if not previewNodes then
        if previewGroup then
            drawNodeEncounterPreview(state, previewGroup, 1)
        end

        return
    end

    local edgeCounts = {
        top = 0,
        bottom = 0,
    }

    for _, previewNode in ipairs(previewNodes) do
        local edge = getNodePreviewEdge(previewNode)

        edgeCounts[edge] = (edgeCounts[edge] or 0) + 1
        drawNodeEncounterPreview(state, previewNode, edgeCounts[edge])
    end
end

return worldencounterpreviewdraw
