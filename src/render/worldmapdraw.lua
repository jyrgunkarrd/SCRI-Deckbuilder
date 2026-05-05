local worldmapdraw = {}

local carddraw = require("src.render.carddraw")
local jaclDefinitions = require("data.jacl")
local troopDefinitions = require("data.cards.troops")

local JACL_IMAGE_DIRECTORY = "assets/images/jacl/"
local CARD_FONT_PATH = "assets/fonts/Furore.otf"
local MAP_SHOP_IMAGE_PATH = "assets/images/map/shop.png"
local MAP_CACHE_IMAGE_PATH = "assets/images/map/cache.png"
local MAP_REGFOR_IMAGE_PATH = "assets/images/map/regfor.png"
local MAP_GLORYFOR_IMAGE_PATH = "assets/images/map/gloryfor.png"
local MAP_CITYEVT_IMAGE_PATH = "assets/images/map/cityevt.png"
local MAP_JNGLEVT_IMAGE_PATH = "assets/images/map/jnglevt.png"
local MAP_BOSS_IMAGE_PATH = "assets/images/map/boss.png"

local mapShopImage = nil
local mapCacheImage = nil
local mapRegforImage = nil
local mapGloryforImage = nil
local mapCityevtImage = nil
local mapJnglevtImage = nil
local mapBossImage = nil
local jaclImageCache = {}
local fontCache = {}
local PLAYER_POSITION_COLOR = { 0.1, 1, 0.94, 1 }
local PLAYER_POSITION_PULSE_SPEED = 4.5
local PLAYER_POSITION_PULSE_MIN_ALPHA = 0.45
local PLAYER_POSITION_PULSE_MAX_ALPHA = 1
local NEXT_DESTINATION_COLOR = { 1, 0.16, 0.1, 1 }
local MAP_CLUSTER_COUNT = 3
local MAP_CLUSTER_SIZE = 5

local function getFont(size)
    local key = tostring(size)

    if fontCache[key] then
        return fontCache[key]
    end

    fontCache[key] = love.graphics.newFont(CARD_FONT_PATH, size)
    return fontCache[key]
end

local function getJaclById(jaclId)
    if not jaclId then
        return nil
    end

    for _, jaclDefinition in ipairs(jaclDefinitions or {}) do
        if jaclDefinition.id == jaclId then
            return jaclDefinition
        end
    end

    return nil
end

local function getTroopById(troopId)
    if not troopId then
        return nil
    end

    for _, troopDefinition in ipairs(troopDefinitions or {}) do
        if troopDefinition.id == troopId then
            return troopDefinition
        end
    end

    return nil
end

local function getJaclImage(jaclDefinition)
    if not jaclDefinition or not jaclDefinition.name then
        return nil
    end

    if jaclImageCache[jaclDefinition.name] ~= nil then
        return jaclImageCache[jaclDefinition.name]
    end

    local imagePath = JACL_IMAGE_DIRECTORY .. jaclDefinition.name .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        jaclImageCache[jaclDefinition.name] = false
        return nil
    end

    jaclImageCache[jaclDefinition.name] = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    jaclImageCache[jaclDefinition.name]:setFilter("linear", "linear")
    return jaclImageCache[jaclDefinition.name]
end

local function getMapShopImage()
    if mapShopImage ~= nil then
        return mapShopImage
    end

    mapShopImage = love.graphics.newImage(MAP_SHOP_IMAGE_PATH, {
        mipmaps = true,
    })
    mapShopImage:setFilter("linear", "linear")
    mapShopImage:setMipmapFilter("linear")
    return mapShopImage
end

local function getMapCacheImage()
    if mapCacheImage ~= nil then
        return mapCacheImage
    end

    mapCacheImage = love.graphics.newImage(MAP_CACHE_IMAGE_PATH, {
        mipmaps = true,
    })
    mapCacheImage:setFilter("linear", "linear")
    mapCacheImage:setMipmapFilter("linear")
    return mapCacheImage
end

local function getMapRegforImage()
    if mapRegforImage ~= nil then
        return mapRegforImage
    end

    mapRegforImage = love.graphics.newImage(MAP_REGFOR_IMAGE_PATH, {
        mipmaps = true,
    })
    mapRegforImage:setFilter("linear", "linear")
    mapRegforImage:setMipmapFilter("linear")
    return mapRegforImage
end

local function getMapGloryforImage()
    if mapGloryforImage ~= nil then
        return mapGloryforImage
    end

    mapGloryforImage = love.graphics.newImage(MAP_GLORYFOR_IMAGE_PATH, {
        mipmaps = true,
    })
    mapGloryforImage:setFilter("linear", "linear")
    mapGloryforImage:setMipmapFilter("linear")
    return mapGloryforImage
end

local function getMapCityevtImage()
    if mapCityevtImage ~= nil then
        return mapCityevtImage
    end

    mapCityevtImage = love.graphics.newImage(MAP_CITYEVT_IMAGE_PATH, {
        mipmaps = true,
    })
    mapCityevtImage:setFilter("linear", "linear")
    mapCityevtImage:setMipmapFilter("linear")
    return mapCityevtImage
end

local function getMapJnglevtImage()
    if mapJnglevtImage ~= nil then
        return mapJnglevtImage
    end

    mapJnglevtImage = love.graphics.newImage(MAP_JNGLEVT_IMAGE_PATH, {
        mipmaps = true,
    })
    mapJnglevtImage:setFilter("linear", "linear")
    mapJnglevtImage:setMipmapFilter("linear")
    return mapJnglevtImage
end

local function getMapBossImage()
    if mapBossImage ~= nil then
        return mapBossImage
    end

    mapBossImage = love.graphics.newImage(MAP_BOSS_IMAGE_PATH, {
        mipmaps = true,
    })
    mapBossImage:setFilter("linear", "linear")
    mapBossImage:setMipmapFilter("linear")
    return mapBossImage
end

local function drawVerticalDottedLine(x, startY, endY, dotRadius, gapLength)
    local direction = startY <= endY and 1 or -1
    local cursorY = startY

    dotRadius = dotRadius or 4
    gapLength = gapLength or 8

    while (direction == 1 and cursorY <= endY) or (direction == -1 and cursorY >= endY) do
        love.graphics.circle("fill", x, cursorY, dotRadius)
        cursorY = cursorY + (((dotRadius * 2) + gapLength) * direction)
    end
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

local function getMapPulseAlpha()
    local pulse = (math.sin(love.timer.getTime() * PLAYER_POSITION_PULSE_SPEED) + 1) * 0.5
    return PLAYER_POSITION_PULSE_MIN_ALPHA
        + ((PLAYER_POSITION_PULSE_MAX_ALPHA - PLAYER_POSITION_PULSE_MIN_ALPHA) * pulse)
end

local function setPlayerMapPulseColor()
    love.graphics.setColor(PLAYER_POSITION_COLOR[1], PLAYER_POSITION_COLOR[2], PLAYER_POSITION_COLOR[3], getMapPulseAlpha())
end

local function setDestinationPulseColor()
    love.graphics.setColor(NEXT_DESTINATION_COLOR[1], NEXT_DESTINATION_COLOR[2], NEXT_DESTINATION_COLOR[3], getMapPulseAlpha())
end

local function setMapImageColor(isPulsing)
    if isPulsing then
        love.graphics.setColor(1, 1, 1, getMapPulseAlpha())
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
end

local function drawPanelFrame(x, y, width, height, cornerRadius)
    cornerRadius = cornerRadius or 8

    love.graphics.setColor(0.025, 0.028, 0.035, 0.9)
    love.graphics.rectangle("fill", x, y, width, height, cornerRadius, cornerRadius)
    love.graphics.setColor(0.88, 0.9, 0.92, 0.88)
    love.graphics.rectangle("line", x, y, width, height, cornerRadius, cornerRadius)
end

local function drawJaclLoadoutCard(jaclDefinition, x, y, width, height)
    local labelHeight = math.max(28, math.floor(height - width))
    local imageHeight = height - labelHeight
    local image = getJaclImage(jaclDefinition)
    local previousFont = love.graphics.getFont()

    drawPanelFrame(x, y, width, height, 0)

    if image then
        local scale = math.min(width / image:getWidth(), imageHeight / image:getHeight())
        local imageWidth = image:getWidth() * scale
        local scaledImageHeight = image:getHeight() * scale
        local previousScissorX, previousScissorY, previousScissorWidth, previousScissorHeight = love.graphics.getScissor()

        love.graphics.setScissor(x, y, width, imageHeight)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(image, x + ((width - imageWidth) * 0.5), y + ((imageHeight - scaledImageHeight) * 0.5), 0, scale, scale)

        if previousScissorX then
            love.graphics.setScissor(previousScissorX, previousScissorY, previousScissorWidth, previousScissorHeight)
        else
            love.graphics.setScissor()
        end
    else
        love.graphics.setColor(0.16, 0.17, 0.2, 1)
        love.graphics.rectangle("fill", x, y, width, imageHeight)
    end

    love.graphics.setColor(0.02, 0.02, 0.025, 0.98)
    love.graphics.rectangle("fill", x, y + imageHeight, width, labelHeight, 0, 0)
    love.graphics.setColor(0.93, 0.93, 0.95, 1)
    love.graphics.setFont(getFont(14))
    love.graphics.printf(
        jaclDefinition and jaclDefinition.name or "JACL",
        x + 8,
        y + imageHeight + ((labelHeight - love.graphics.getFont():getHeight()) * 0.5),
        width - 16,
        "center"
    )
    love.graphics.setFont(previousFont)
end

local function drawEmptyAgentLoadoutCard(x, y, width, height)
    drawPanelFrame(x, y, width, height)
    love.graphics.setColor(0.18, 0.19, 0.22, 0.9)
    love.graphics.rectangle("fill", x + 6, y + 6, width - 12, height - 12, 6, 6)
end

local function drawSelectedRunLoadout(state)
    if not state or not state.selectedRunJaclId then
        return
    end

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local margin = math.max(18, math.floor(math.min(screenWidth, screenHeight) * 0.025))
    local gap = 12
    local jaclWidth = math.min(220, math.max(170, math.floor(screenWidth * 0.12)))
    local jaclLabelHeight = 32
    local jaclHeight = jaclWidth + jaclLabelHeight
    local agentWidth = math.floor(jaclWidth * 0.46)
    local agentHeight = agentWidth
    local totalWidth = jaclWidth + gap + (agentWidth * 2) + gap
    local x = margin
    local y = screenHeight - margin - jaclHeight

    if totalWidth + (margin * 2) > screenWidth then
        local scale = (screenWidth - (margin * 2)) / totalWidth

        jaclWidth = math.floor(jaclWidth * scale)
        jaclLabelHeight = math.floor(jaclLabelHeight * scale)
        jaclHeight = math.floor(jaclHeight * scale)
        agentWidth = math.floor(agentWidth * scale)
        agentHeight = agentWidth
        gap = math.max(8, math.floor(gap * scale))
        y = screenHeight - margin - jaclHeight
    end

    local jaclDefinition = getJaclById(state.selectedRunJaclId)
    local agentIds = state.selectedRunAgentIds or {}

    drawJaclLoadoutCard(jaclDefinition, x, y, jaclWidth, jaclHeight)

    for agentIndex = 1, 2 do
        local agentX = x + jaclWidth + gap + ((agentIndex - 1) * (agentWidth + gap))
        local agentY = y + jaclHeight - agentHeight
        local agentId = agentIds[agentIndex]
        local agentDefinition = getTroopById(agentId)

        if agentDefinition then
            carddraw.drawCard("troops", agentId, agentX, agentY, {
                width = agentWidth,
                showLabelWhenCollapsed = false,
            })
        else
            drawEmptyAgentLoadoutCard(agentX, agentY, agentWidth, agentHeight)
        end
    end
end

function worldmapdraw.draw(state)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local y = screenHeight * 0.5
    local circleRadius = 22
    local diamondRadius = 20
    local eventCircleRadius = 15
    local bossDiamondRadius = 30
    local bossInnerDiamondRadius = 18
    local shopIconSize = 208
    local bossIconSize = 208
    local nonBossNodeShift = 24
    local dottedConnectorInset = 12
    local dottedConnectorOffsetY = 8
    local clusterSize = MAP_CLUSTER_SIZE
    local clusterCount = MAP_CLUSTER_COUNT
    local horizontalMargin = math.max(54, screenWidth * 0.045)
    local availableSpan = screenWidth - (horizontalMargin * 2)
    local clusterGap = availableSpan * 0.105
    local startGap = availableSpan * 0.145
    local intraClusterSpacing = (availableSpan - startGap - ((clusterCount - 1) * clusterGap))
        / ((clusterSize - 1) * clusterCount)
    local diamondSpan = availableSpan - startGap
    local startX = horizontalMargin
    local firstDiamondX = startX + startGap
    local lastDiamondX = firstDiamondX + diamondSpan
    local playerMapPosition = getPlayerMapPosition(state)
    local nextMapPosition = getNextMapPosition(playerMapPosition)

    love.graphics.clear(0.045, 0.047, 0.055, 1)
    love.graphics.setLineWidth(5)
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.line(startX, y, lastDiamondX, y)

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.circle("fill", startX, y, circleRadius)
    love.graphics.setColor(0.95, 0.28, 0.15, 1)
    love.graphics.circle("line", startX, y, circleRadius)
    if isPlayerMapNode(playerMapPosition, "start") then
        setPlayerMapPulseColor()
    elseif isPlayerMapNode(nextMapPosition, "start") then
        setDestinationPulseColor()
    end
    love.graphics.circle("fill", startX, y, circleRadius * 0.42)

    for clusterIndex = 1, clusterCount do
        local clusterStartX = firstDiamondX
            + ((clusterIndex - 1) * ((clusterSize - 1) * intraClusterSpacing + clusterGap))

        for nodeIndex = 1, clusterSize do
            local x = clusterStartX + ((nodeIndex - 1) * intraClusterSpacing)
            local isBossNode = nodeIndex == clusterSize
            local isEventNode = nodeIndex == 3
            local isNextDestinationNode = isPlayerMapNode(nextMapPosition, "path", clusterIndex, nodeIndex)
            local nodeColor = { 0.5, 0.5, 0.5, 1 }
            local nodeRadius = isBossNode and bossDiamondRadius or diamondRadius

            if not isBossNode then
                x = x - nonBossNodeShift
            end

            love.graphics.setColor(0, 0, 0, 1)
            if isEventNode then
                love.graphics.circle("fill", x, y, eventCircleRadius)
            else
                love.graphics.polygon(
                    "fill",
                    x,
                    y - nodeRadius,
                    x + nodeRadius,
                    y,
                    x,
                    y + nodeRadius,
                    x - nodeRadius,
                    y
                )
            end

            if clusterIndex == 2 and nodeIndex == 3 then
                nodeColor = { 0.27, 0.86, 0.39, 1 }
            elseif isEventNode then
                nodeColor = { 1, 0.08, 0.62, 1 }
            elseif isBossNode then
                nodeColor = { 1, 0.73, 0.08, 1 }
            end

            love.graphics.setColor(nodeColor[1], nodeColor[2], nodeColor[3], nodeColor[4])

            if isEventNode then
                love.graphics.circle("line", x, y, eventCircleRadius)
            else
                love.graphics.polygon(
                    "line",
                    x,
                    y - nodeRadius,
                    x + nodeRadius,
                    y,
                    x,
                    y + nodeRadius,
                    x - nodeRadius,
                    y
                )
            end

            if isBossNode then
                love.graphics.polygon(
                    "line",
                    x,
                    y - bossInnerDiamondRadius,
                    x + bossInnerDiamondRadius,
                    y,
                    x,
                    y + bossInnerDiamondRadius,
                    x - bossInnerDiamondRadius,
                    y
                )
            end

            if isPlayerMapNode(playerMapPosition, "path", clusterIndex, nodeIndex) then
                setPlayerMapPulseColor()
            elseif isNextDestinationNode then
                setDestinationPulseColor()
            end

            if isEventNode then
                love.graphics.circle("fill", x, y, eventCircleRadius * 0.45)
            else
                local nestedDiamondRadius = nodeRadius * 0.42

                love.graphics.polygon(
                    "fill",
                    x,
                    y - nestedDiamondRadius,
                    x + nestedDiamondRadius,
                    y,
                    x,
                    y + nestedDiamondRadius,
                    x - nestedDiamondRadius,
                    y
                )
            end

            if nodeIndex == 1 then
                local regforImage = getMapRegforImage()
                local scale = shopIconSize / math.max(regforImage:getWidth(), regforImage:getHeight())
                local imageWidth = regforImage:getWidth() * scale
                local imageHeight = regforImage:getHeight() * scale
                local imageX = x - (imageWidth * 0.5)
                local imageY = y - nodeRadius - imageHeight - 20
                local connectorTopY = imageY + imageHeight
                local connectorBottomY = y - nodeRadius

                love.graphics.setColor(0.5, 0.5, 0.5, 1)
                love.graphics.line(x, connectorTopY, x, connectorBottomY)
                setMapImageColor(isNextDestinationNode)
                love.graphics.draw(regforImage, imageX, imageY, 0, scale, scale)
            end

            if nodeIndex == 1 then
                local gloryforImage = getMapGloryforImage()
                local scale = shopIconSize / math.max(gloryforImage:getWidth(), gloryforImage:getHeight())
                local imageWidth = gloryforImage:getWidth() * scale
                local imageHeight = gloryforImage:getHeight() * scale
                local imageX = x - (imageWidth * 0.5)
                local imageY = y + nodeRadius + 20
                local connectorTopY = y + nodeRadius
                local connectorBottomY = imageY

                love.graphics.setColor(0.5, 0.5, 0.5, 1)
                love.graphics.line(x, connectorTopY, x, connectorBottomY)
                setMapImageColor(isNextDestinationNode)
                love.graphics.draw(gloryforImage, imageX, imageY, 0, scale, scale)
            end

            if nodeIndex == 2 then
                local regforImage = getMapRegforImage()
                local scale = shopIconSize / math.max(regforImage:getWidth(), regforImage:getHeight())
                local imageWidth = regforImage:getWidth() * scale
                local imageHeight = regforImage:getHeight() * scale
                local imageX = x - (imageWidth * 0.5)
                local imageY = y - nodeRadius - imageHeight - 164
                local connectorTopY = imageY + imageHeight
                local connectorBottomY = y - nodeRadius

                love.graphics.setColor(0.5, 0.5, 0.5, 1)
                love.graphics.line(x, connectorTopY, x, connectorBottomY)
                setMapImageColor(isNextDestinationNode)
                love.graphics.draw(regforImage, imageX, imageY, 0, scale, scale)
            end

            if nodeIndex == 2 then
                local gloryforImage = getMapGloryforImage()
                local scale = shopIconSize / math.max(gloryforImage:getWidth(), gloryforImage:getHeight())
                local imageWidth = gloryforImage:getWidth() * scale
                local imageHeight = gloryforImage:getHeight() * scale
                local imageX = x - (imageWidth * 0.5)
                local imageY = y + nodeRadius + 164
                local connectorTopY = y + nodeRadius
                local connectorBottomY = imageY

                love.graphics.setColor(0.5, 0.5, 0.5, 1)
                love.graphics.line(x, connectorTopY, x, connectorBottomY)
                setMapImageColor(isNextDestinationNode)
                love.graphics.draw(gloryforImage, imageX, imageY, 0, scale, scale)
            end

            if (clusterIndex == 1 or clusterIndex == 3) and nodeIndex == 3 then
                local cityevtImage = getMapCityevtImage()
                local scale = shopIconSize / math.max(cityevtImage:getWidth(), cityevtImage:getHeight())
                local imageWidth = cityevtImage:getWidth() * scale
                local imageHeight = cityevtImage:getHeight() * scale
                local imageX = x - (imageWidth * 0.5)
                local imageY = y - eventCircleRadius - imageHeight - 20
                local connectorTopY = imageY + imageHeight
                local connectorBottomY = y - eventCircleRadius

                love.graphics.setColor(1, 0.08, 0.62, 1)
                love.graphics.line(x, connectorTopY, x, connectorBottomY)
                setMapImageColor(isNextDestinationNode)
                love.graphics.draw(cityevtImage, imageX, imageY, 0, scale, scale)
            end

            if (clusterIndex == 1 or clusterIndex == 3) and nodeIndex == 3 then
                local jnglevtImage = getMapJnglevtImage()
                local scale = shopIconSize / math.max(jnglevtImage:getWidth(), jnglevtImage:getHeight())
                local imageWidth = jnglevtImage:getWidth() * scale
                local imageHeight = jnglevtImage:getHeight() * scale
                local imageX = x - (imageWidth * 0.5)
                local imageY = y + eventCircleRadius + 20
                local connectorTopY = y + eventCircleRadius
                local connectorBottomY = imageY

                love.graphics.setColor(1, 0.08, 0.62, 1)
                love.graphics.line(x, connectorTopY, x, connectorBottomY)
                setMapImageColor(isNextDestinationNode)
                love.graphics.draw(jnglevtImage, imageX, imageY, 0, scale, scale)
            end

            if nodeIndex == 4 then
                local gloryforImage = getMapGloryforImage()
                local scale = shopIconSize / math.max(gloryforImage:getWidth(), gloryforImage:getHeight())
                local imageWidth = gloryforImage:getWidth() * scale
                local imageHeight = gloryforImage:getHeight() * scale
                local imageX = x - (imageWidth * 0.5)
                local imageY = y - nodeRadius - imageHeight - 164
                local connectorTopY = imageY + imageHeight
                local connectorBottomY = y - nodeRadius

                love.graphics.setColor(0.5, 0.5, 0.5, 1)
                love.graphics.line(x, connectorTopY, x, connectorBottomY)
                setMapImageColor(isNextDestinationNode)
                love.graphics.draw(gloryforImage, imageX, imageY, 0, scale, scale)
            end

            if nodeIndex == 4 then
                local jnglevtImage = getMapJnglevtImage()
                local scale = shopIconSize / math.max(jnglevtImage:getWidth(), jnglevtImage:getHeight())
                local imageWidth = jnglevtImage:getWidth() * scale
                local imageHeight = jnglevtImage:getHeight() * scale
                local imageX = x - (imageWidth * 0.5)
                local imageY = y + nodeRadius + 164
                local connectorTopY = y + nodeRadius + dottedConnectorInset + dottedConnectorOffsetY
                local connectorBottomY = imageY - dottedConnectorInset + dottedConnectorOffsetY

                love.graphics.setColor(1, 0.08, 0.62, 1)
                drawVerticalDottedLine(x, connectorTopY, connectorBottomY, 4, 8)
                setMapImageColor(isNextDestinationNode)
                love.graphics.draw(jnglevtImage, imageX, imageY, 0, scale, scale)
            end

            if nodeIndex == 5 then
                local bossImage = getMapBossImage()
                local scale = bossIconSize / math.max(bossImage:getWidth(), bossImage:getHeight())
                local imageWidth = bossImage:getWidth() * scale
                local imageHeight = bossImage:getHeight() * scale
                local imageX = x - (imageWidth * 0.5)
                local imageY = y - (imageHeight * 0.5)

                setMapImageColor(isNextDestinationNode)
                love.graphics.draw(bossImage, imageX, imageY, 0, scale, scale)
            end

            if clusterIndex == 2 and nodeIndex == 3 then
                local shopImage = getMapShopImage()
                local scale = shopIconSize / math.max(shopImage:getWidth(), shopImage:getHeight())
                local imageWidth = shopImage:getWidth() * scale
                local imageHeight = shopImage:getHeight() * scale
                local imageX = x - (imageWidth * 0.5)
                local imageY = y - nodeRadius - imageHeight - 20
                local connectorTopY = imageY + imageHeight
                local connectorBottomY = y - eventCircleRadius

                love.graphics.setColor(0.27, 0.86, 0.39, 1)
                love.graphics.line(x, connectorTopY, x, connectorBottomY)
                setMapImageColor(isNextDestinationNode)
                love.graphics.draw(shopImage, imageX, imageY, 0, scale, scale)
            end

            if clusterIndex == 2 and nodeIndex == 3 then
                local cacheImage = getMapCacheImage()
                local scale = shopIconSize / math.max(cacheImage:getWidth(), cacheImage:getHeight())
                local imageWidth = cacheImage:getWidth() * scale
                local imageHeight = cacheImage:getHeight() * scale
                local imageX = x - (imageWidth * 0.5)
                local imageY = y + eventCircleRadius + 20
                local connectorTopY = y + eventCircleRadius
                local connectorBottomY = imageY

                love.graphics.setColor(0.27, 0.86, 0.39, 1)
                love.graphics.line(x, connectorTopY, x, connectorBottomY)
                setMapImageColor(isNextDestinationNode)
                love.graphics.draw(cacheImage, imageX, imageY, 0, scale, scale)
            end
        end
    end

    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
    drawSelectedRunLoadout(state)
end

return worldmapdraw
