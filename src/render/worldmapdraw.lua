local worldmapdraw = {}

local carddraw = require("src.render.carddraw")
local worldmaprules = require("src.system.worldmaprules")
local deckrules = require("src.system.deckrules")
local cardregistry = require("src.system.cardregistry")
local previewrules = require("src.system.previewrules")
local envdraw = require("src.render.envdraw")
local worldencounterpreviewdraw = require("src.render.worldencounterpreviewdraw")
local munitionsrules = require("src.system.munitionsrules")
local tithesrules = require("src.system.tithesrules")
local worldrewardmodal = require("src.ui.worldrewardmodal")
local jaclDefinitions = require("data.jacl")
local troopDefinitions = require("data.cards.troops")

local JACL_IMAGE_DIRECTORY = "assets/images/jacl/"
local CARD_FONT_PATH = "assets/fonts/Furore.otf"
local MAP_IMAGE_DIRECTORY = "assets/images/map/"
local WARZONE_IMAGE_DIRECTORY = "assets/images/warzone/"
local CREW_IMAGE_DIRECTORY = "assets/images/crew/"

local jaclImageCache = {}
local nodePreviewIconCache = {}
local objectivePreviewImageCache = {}
local warzonePreviewImageCache = {}
local crewImageCache = {}
local fontCache = {}
local PLAYER_POSITION_COLOR = { 0.1, 1, 0.94, 1 }
local PLAYER_POSITION_PULSE_SPEED = 4.5
local PLAYER_POSITION_PULSE_MIN_ALPHA = 0.45
local PLAYER_POSITION_PULSE_MAX_ALPHA = 1
local NEXT_DESTINATION_COLOR = { 1, 0.16, 0.1, 1 }
local MAP_CLUSTER_COUNT = 3
local MAP_CLUSTER_SIZE = 5
local WORLD_DECK_MODAL_CARD_WIDTH = 150
local WORLD_DECK_MODAL_CARD_GAP = 14
local WORLD_DECK_MODAL_HEADER_HEIGHT = 44
local WORLD_DECK_MODAL_MARGIN = 38
local WORLD_DECK_MODAL_PADDING = 18
local WORLD_DECK_MODAL_MAX_HEIGHT_RATIO = 0.78
local DICE_SUMMON_PREVIEW_GAP = 14
local DICE_SUMMON_PREVIEW_PADDING = 10
local OBJECTIVE_CARD_PREVIEW_WIDTH = 340
local OBJECTIVE_CARD_PREVIEW_PADDING = 16
local OBJECTIVE_CARD_PREVIEW_LABEL_HEIGHT = 46
local OBJECTIVE_CARD_PREVIEW_TEXTBOX_HEIGHT = 132
local OBJECTIVE_CARD_PREVIEW_DICE_GAP = 8
local OBJECTIVE_CARD_PREVIEW_PLAN_PIP_MAX_SIZE = 12
local OBJECTIVE_CARD_PREVIEW_PLAN_COLOR = { 1, 0.72, 0.18, 1 }
local OBJECTIVE_CARD_PREVIEW_INTEL_COLOR = { 0.3, 0.72, 1, 1 }
local OBJECTIVE_CARD_PREVIEW_WARZONE_COLOR = { 0.75, 0.86, 0.42, 1 }
local OBJECTIVE_CARD_PREVIEW_HOSTILE_INFLUENCE_COLOR = { 0.906, 0.102, 0.176, 1 }
local WORLD_RESOURCE_TRACKER_OUTLINE_COLOR = { 0.549, 1, 0.871, 1 }
local WORLD_RESOURCE_TRACKER_FILL_COLOR = { 0.025, 0.032, 0.04, 0.88 }
local WORLD_RESOURCE_TRACKER_TEXT_COLOR = { 0.9, 0.98, 0.96, 1 }
local WORLD_RESOURCE_TRACKER_LABEL_COLOR = { 0.58, 0.74, 0.72, 1 }
local WORLD_RESOURCE_TRACKER_DETAIL_COLOR = { 0.95, 0.96, 0.98, 1 }
local WORLD_ALMS_TRACKER_COLOR = { 0.976, 0.761, 0.169, 1 }
local WORLD_MUNITIONS_TOOLTIP_PADDING = 12
local WORLD_MUNITIONS_TOOLTIP_GAP = 8
local WORLD_MUNITIONS_TOOLTIP_HEADER_SIZE = 14
local WORLD_MUNITIONS_TOOLTIP_BODY_SIZE = 12
local WORLD_ROLE_PORTRAIT_LABEL_COLOR = { 1, 0.725, 0.337, 1 }
local WORLD_ROLE_PORTRAIT_OUTLINE_COLOR = { 1, 0.725, 0.337, 1 }
local WORLD_ROLE_PORTRAIT_FILL_COLOR = { 0.075, 0.082, 0.095, 0.92 }
local WORLD_SYSTEMS_LABEL_COLOR = { 0.549, 1, 0.871, 1 }
local WORLD_SYSTEMS_OUTLINE_COLOR = { 0.549, 1, 0.871, 1 }
local WORLD_SYSTEMS_BOX_FILL_COLOR = { 0.075, 0.082, 0.095, 0.92 }
local WORLD_ROLE_PORTRAITS = {
    {
        label = "Captain",
        image = "captain.png",
    },
    {
        label = "Surgeon",
        image = "surgeon.png",
    },
    {
        label = "Sheriff",
        image = "sheriff.png",
    },
    {
        label = "Tactician",
        image = "tactician.png",
    },
    {
        label = "Engineer",
        image = "engineer.png",
    },
}
local WORLD_RESOURCE_TRACKERS = {
    {
        key = "fuel",
        label = "FUEL",
        icon = "fuel.png",
    },
    {
        key = "munitions",
        label = "MUNITIONS",
        icon = "munitions.png",
    },
    {
        key = "tithes",
        label = "TITHES",
        icon = "tithes.png",
    },
}

local drawDiceSummonPreviewLeft
local getSelectedRunLoadoutLayout
local getWorldResourceTrackerLayout

local function getFont(size)
    local key = tostring(size)

    if fontCache[key] then
        return fontCache[key]
    end

    fontCache[key] = love.graphics.newFont(CARD_FONT_PATH, size)
    return fontCache[key]
end

local function getMapImage(fileName)
    if not fileName then
        return nil
    end

    if nodePreviewIconCache[fileName] ~= nil then
        return nodePreviewIconCache[fileName] or nil
    end

    local imagePath = MAP_IMAGE_DIRECTORY .. fileName

    if not love.filesystem.getInfo(imagePath) then
        nodePreviewIconCache[fileName] = false
        return nil
    end

    local image = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    image:setFilter("linear", "linear")
    image:setMipmapFilter("linear")
    nodePreviewIconCache[fileName] = image
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

    local image = carddraw.preloadPortraitPath and carddraw.preloadPortraitPath(imagePath) or nil

    if not image then
        image = love.graphics.newImage(imagePath, {
            mipmaps = true,
        })
        image:setFilter("linear", "linear")
    end

    image:setMipmapFilter("linear")
    crewImageCache[fileName] = image
    return image
end

local function isPointInsideRect(x, y, rect)
    return rect
        and x >= rect.x
        and x <= rect.x + rect.width
        and y >= rect.y
        and y <= rect.y + rect.height
end

local function getMapLayout()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local horizontalMargin = math.max(54, screenWidth * 0.045)
    local availableSpan = screenWidth - (horizontalMargin * 2)
    local clusterGap = availableSpan * 0.105
    local startGap = availableSpan * 0.145
    local clusterSize = MAP_CLUSTER_SIZE
    local clusterCount = MAP_CLUSTER_COUNT
    local intraClusterSpacing = (availableSpan - startGap - ((clusterCount - 1) * clusterGap))
        / ((clusterSize - 1) * clusterCount)
    local startX = horizontalMargin
    local firstDiamondX = startX + startGap
    local diamondSpan = availableSpan - startGap

    return {
        screenWidth = screenWidth,
        screenHeight = screenHeight,
        y = screenHeight * 0.5,
        circleRadius = 22,
        diamondRadius = 20,
        eventCircleRadius = 15,
        bossDiamondRadius = 30,
        bossInnerDiamondRadius = 18,
        nonBossNodeShift = 24,
        clusterSize = clusterSize,
        clusterCount = clusterCount,
        horizontalMargin = horizontalMargin,
        availableSpan = availableSpan,
        clusterGap = clusterGap,
        startGap = startGap,
        intraClusterSpacing = intraClusterSpacing,
        diamondSpan = diamondSpan,
        startX = startX,
        firstDiamondX = firstDiamondX,
        lastDiamondX = firstDiamondX + diamondSpan,
    }
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

local function getSelectedMunitionsSystem(state)
    if state and state.selectedRunMunitionsSystem then
        return state.selectedRunMunitionsSystem
    end

    if state and state.selectedRunPackage and state.selectedRunPackage.munitionsSystem then
        return state.selectedRunPackage.munitionsSystem
    end

    local jaclDefinition = state
        and state.selectedRunPackage
        and state.selectedRunPackage.jacl
        or getJaclById(state and state.selectedRunJaclId or nil)

    return munitionsrules.getJaclMunitions(jaclDefinition)
end

local function getSelectedTitheSystem(state)
    if state and state.selectedRunTitheSystem then
        return state.selectedRunTitheSystem
    end

    if state and state.selectedRunPackage and state.selectedRunPackage.titheSystem then
        return state.selectedRunPackage.titheSystem
    end

    local jaclDefinition = state
        and state.selectedRunPackage
        and state.selectedRunPackage.jacl
        or getJaclById(state and state.selectedRunJaclId or nil)

    return tithesrules.getJaclTithe(jaclDefinition)
end

local function drawMunitionsSystemTooltip(systemDefinition, anchor)
    if not systemDefinition or not anchor then
        return
    end

    local previousFont = love.graphics.getFont()
    local headerFont = getFont(WORLD_MUNITIONS_TOOLTIP_HEADER_SIZE)
    local bodyFont = getFont(WORLD_MUNITIONS_TOOLTIP_BODY_SIZE)
    local headerText = systemDefinition.name or systemDefinition.id or "Munitions"
    local bodyText = systemDefinition.text or ""
    local textWidth = math.max(headerFont:getWidth(headerText), bodyText ~= "" and bodyFont:getWidth(bodyText) or 0)
    local tooltipWidth = math.max(180, math.floor((WORLD_MUNITIONS_TOOLTIP_PADDING * 2) + textWidth))
    local tooltipHeight = math.floor(
        (WORLD_MUNITIONS_TOOLTIP_PADDING * 2)
        + headerFont:getHeight()
        + (bodyText ~= "" and (6 + bodyFont:getHeight()) or 0)
    )
    local windowWidth = love.graphics.getWidth()
    local tooltipX = math.floor(anchor.x + ((anchor.width - tooltipWidth) * 0.5))
    local tooltipY = math.floor(anchor.y - WORLD_MUNITIONS_TOOLTIP_GAP - tooltipHeight)

    tooltipX = math.max(8, math.min(tooltipX, windowWidth - tooltipWidth - 8))
    tooltipY = math.max(8, tooltipY)

    love.graphics.setColor(0, 0, 0, 0.58)
    love.graphics.rectangle("fill", tooltipX - 5, tooltipY - 5, tooltipWidth + 10, tooltipHeight + 10, 7, 7)
    love.graphics.setColor(0.075, 0.082, 0.095, 0.96)
    love.graphics.rectangle("fill", tooltipX, tooltipY, tooltipWidth, tooltipHeight, 5, 5)
    love.graphics.setColor(0.82, 0.85, 0.89, 0.84)
    love.graphics.rectangle("line", tooltipX, tooltipY, tooltipWidth, tooltipHeight, 5, 5)

    love.graphics.setFont(headerFont)
    love.graphics.setColor(WORLD_RESOURCE_TRACKER_DETAIL_COLOR[1], WORLD_RESOURCE_TRACKER_DETAIL_COLOR[2], WORLD_RESOURCE_TRACKER_DETAIL_COLOR[3], 1)
    love.graphics.print(headerText, tooltipX + WORLD_MUNITIONS_TOOLTIP_PADDING, tooltipY + WORLD_MUNITIONS_TOOLTIP_PADDING)

    if bodyText ~= "" then
        love.graphics.setFont(bodyFont)
        love.graphics.setColor(0.82, 0.85, 0.89, 0.98)
        love.graphics.print(
            bodyText,
            tooltipX + WORLD_MUNITIONS_TOOLTIP_PADDING,
            tooltipY + WORLD_MUNITIONS_TOOLTIP_PADDING + headerFont:getHeight() + 6
        )
    end

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
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

local function getObjectivePreviewImage(objectiveId)
    if not objectiveId then
        return nil
    end

    if objectivePreviewImageCache[objectiveId] ~= nil then
        return objectivePreviewImageCache[objectiveId] or nil
    end

    local imagePath = "assets/images/objectives/" .. objectiveId .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        objectivePreviewImageCache[objectiveId] = false
        return nil
    end

    local image = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    image:setFilter("linear", "linear")
    image:setMipmapFilter("linear")
    objectivePreviewImageCache[objectiveId] = image
    return image
end

local function getWarzonePreviewImage(warzoneId)
    if not warzoneId then
        return nil
    end

    if warzonePreviewImageCache[warzoneId] ~= nil then
        return warzonePreviewImageCache[warzoneId] or nil
    end

    local imagePath = WARZONE_IMAGE_DIRECTORY .. warzoneId .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        warzonePreviewImageCache[warzoneId] = false
        return nil
    end

    local image = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    image:setFilter("linear", "linear")
    image:setMipmapFilter("linear")
    warzonePreviewImageCache[warzoneId] = image
    return image
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

local function getClusterNodeX(layout, clusterIndex, nodeIndex)
    local clusterStartX = layout.firstDiamondX
        + ((clusterIndex - 1) * ((layout.clusterSize - 1) * layout.intraClusterSpacing + layout.clusterGap))
    local x = clusterStartX + ((nodeIndex - 1) * layout.intraClusterSpacing)

    if nodeIndex ~= layout.clusterSize then
        x = x - layout.nonBossNodeShift
    end

    return x
end

local function getRouteNodeDefinitionIds(state, clusterIndex, nodeIndex)
    local mapDefinition = worldmaprules.getActiveMap(state)
    local cluster = mapDefinition and mapDefinition.clusters and mapDefinition.clusters[clusterIndex] or nil
    local routeNode = cluster and cluster.nodes and cluster.nodes[nodeIndex] or nil
    local nodeDefinitionIds = {}

    for _, nodeDefinitionId in ipairs(routeNode and routeNode.branches or {}) do
        nodeDefinitionIds[#nodeDefinitionIds + 1] = nodeDefinitionId
    end

    if #nodeDefinitionIds <= 0 and routeNode and routeNode.nodeId then
        nodeDefinitionIds[#nodeDefinitionIds + 1] = routeNode.nodeId
    end

    return nodeDefinitionIds
end

local function getCachedNodeEncounterPreview(state, nodeDefinition)
    if not nodeDefinition then
        return nil
    end

    if not state then
        return worldmaprules.getNodeEncounterPreview(nodeDefinition)
    end

    state.worldMapEncounterPreviewCache = state.worldMapEncounterPreviewCache or {}

    local cacheKey = nodeDefinition.id or tostring(nodeDefinition)

    if state.worldMapEncounterPreviewCache[cacheKey] == nil then
        state.worldMapEncounterPreviewCache[cacheKey] = worldmaprules.getNodeEncounterPreview(nodeDefinition) or false
    end

    return state.worldMapEncounterPreviewCache[cacheKey] or nil
end

local function getRouteNodePreviewGroup(state, clusterIndex, nodeIndex)
    local layout = getMapLayout()
    local x = getClusterNodeX(layout, clusterIndex, nodeIndex)
    local isBossNode = nodeIndex == layout.clusterSize
    local isEventNode = nodeIndex == 3
    local nodeRadius = isBossNode and layout.bossDiamondRadius
        or (isEventNode and layout.eventCircleRadius or layout.diamondRadius)
    local previewNodes = {}

    for branchIndex, nodeDefinitionId in ipairs(getRouteNodeDefinitionIds(state, clusterIndex, nodeIndex)) do
        local nodeDefinition = worldmaprules.getNodeDefinition(nodeDefinitionId)

        if nodeDefinition then
            previewNodes[#previewNodes + 1] = {
                clusterIndex = clusterIndex,
                nodeIndex = nodeIndex,
                branchIndex = branchIndex,
                nodeDefinition = nodeDefinition,
                sourceRect = {
                    x = x - nodeRadius,
                    y = layout.y - nodeRadius,
                    width = nodeRadius * 2,
                    height = nodeRadius * 2,
                },
                preview = getCachedNodeEncounterPreview(state, nodeDefinition),
            }
        end
    end

    if #previewNodes <= 0 then
        return nil
    end

    return {
        clusterIndex = clusterIndex,
        nodeIndex = nodeIndex,
        sourceRect = {
            x = x - nodeRadius,
            y = layout.y - nodeRadius,
            width = nodeRadius * 2,
            height = nodeRadius * 2,
        },
        previewNodes = previewNodes,
    }
end

local function getHoveredFunctionalNode(state, mouseX, mouseY)
    local layout = getMapLayout()

    for clusterIndex = 1, layout.clusterCount do
        for nodeIndex = 1, layout.clusterSize do
            local previewGroup = getRouteNodePreviewGroup(state, clusterIndex, nodeIndex)

            if previewGroup and isPointInsideRect(mouseX, mouseY, previewGroup.sourceRect) then
                return previewGroup
            end
        end
    end

    return nil
end

local function getDefaultFunctionalNode(state)
    local nextMapPosition = getNextMapPosition(getPlayerMapPosition(state))

    if not nextMapPosition or nextMapPosition.kind ~= "path" then
        return nil
    end

    return getRouteNodePreviewGroup(state, nextMapPosition.clusterIndex, nextMapPosition.nodeIndex)
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

getWorldResourceTrackerLayout = function(state)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local margin = math.max(18, math.floor(math.min(screenWidth, screenHeight) * 0.025))
    local baseIconSize = math.max(28, math.floor(math.min(screenWidth, screenHeight) * 0.038))
    local baseTrackerWidth = math.max(170, math.floor(screenWidth * 0.15))
    local baseTrackerHeight = math.max(42, math.floor(baseIconSize * 1.15))
    local baseGap = math.max(8, math.floor(baseTrackerHeight * 0.24))
    local baseIconGap = math.max(10, math.floor(baseIconSize * 0.32))
    local scale = 1
    local iconSize = baseIconSize
    local trackerWidth = baseTrackerWidth
    local trackerHeight = baseTrackerHeight
    local gap = baseGap
    local iconGap = baseIconGap
    local totalHeight = (#WORLD_RESOURCE_TRACKERS * trackerHeight) + ((#WORLD_RESOURCE_TRACKERS - 1) * gap)
    local y = math.max(margin, math.floor((screenHeight - totalHeight) * 0.5))
    local loadoutLayout = getSelectedRunLoadoutLayout(state)
    local x = margin

    if loadoutLayout then
        local agentTopY = loadoutLayout.y + loadoutLayout.jaclHeight - loadoutLayout.agentHeight
        local agentGap = math.max(6, math.floor(loadoutLayout.gap * 0.5))
        local availableHeight = math.max(1, agentTopY - agentGap - loadoutLayout.y)

        scale = math.min(1, availableHeight / totalHeight)
        iconSize = math.max(18, math.floor(baseIconSize * scale))
        trackerWidth = math.max(110, math.floor(baseTrackerWidth * scale))
        trackerHeight = math.max(28, math.floor(baseTrackerHeight * scale))
        gap = math.max(5, math.floor(baseGap * scale))
        iconGap = math.max(6, math.floor(baseIconGap * scale))
        totalHeight = (#WORLD_RESOURCE_TRACKERS * trackerHeight) + ((#WORLD_RESOURCE_TRACKERS - 1) * gap)
        x = loadoutLayout.x + loadoutLayout.jaclWidth + loadoutLayout.gap
        trackerWidth = math.max(
            90,
            math.floor(
                loadoutLayout.x
                    + loadoutLayout.jaclWidth
                    + loadoutLayout.gap
                    + (loadoutLayout.agentWidth * 2)
                    + loadoutLayout.gap
                    - (x + iconSize + iconGap)
            )
        )
        y = math.floor(loadoutLayout.y)
    end

    return {
        x = x,
        y = y,
        iconSize = iconSize,
        iconGap = iconGap,
        trackerWidth = trackerWidth,
        trackerHeight = trackerHeight,
        gap = gap,
        labelFontSize = math.max(7, math.floor(10 * scale)),
        valueFontSize = math.max(11, math.floor(18 * scale)),
        paddingX = math.max(7, math.floor(12 * scale)),
        labelOffsetY = math.max(4, math.floor(7 * scale)),
        valueOffsetY = math.max(12, math.floor(17 * scale)),
        cornerRadius = math.max(2, math.floor(4 * scale)),
        lineWidth = math.max(1, math.floor(2 * scale)),
    }
end

local function drawWorldResourceTrackers(state)
    if state and state.runSetupModal and state.runSetupModal.isOpen then
        return
    end

    local layout = getWorldResourceTrackerLayout(state)
    local labelFont = getFont(layout.labelFontSize)
    local valueFont = getFont(layout.valueFontSize)
    local resources = state and state.worldResources or {}
    local munitionsSystem = getSelectedMunitionsSystem(state)
    local titheSystem = getSelectedTitheSystem(state)
    local hoveredSystemTooltip = nil

    for trackerIndex, tracker in ipairs(WORLD_RESOURCE_TRACKERS) do
        local rowY = layout.y + ((trackerIndex - 1) * (layout.trackerHeight + layout.gap))
        local iconX = layout.x
        local iconY = rowY + math.floor((layout.trackerHeight - layout.iconSize) * 0.5)
        local trackerX = iconX + layout.iconSize + layout.iconGap
        local value = math.max(0, math.floor(tonumber(resources[tracker.key]) or 0))
        local image = getMapImage(tracker.icon)
        local mouseX, mouseY = love.mouse.getPosition()
        local iconAnchor = {
            x = iconX,
            y = iconY,
            width = layout.iconSize,
            height = layout.iconSize,
        }

        if image then
            local imageScale = math.min(layout.iconSize / image:getWidth(), layout.iconSize / image:getHeight())
            local imageWidth = image:getWidth() * imageScale
            local imageHeight = image:getHeight() * imageScale

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                image,
                iconX + ((layout.iconSize - imageWidth) * 0.5),
                iconY + ((layout.iconSize - imageHeight) * 0.5),
                0,
                imageScale,
                imageScale
            )
        end

        if tracker.key == "munitions" and isPointInsideRect(mouseX, mouseY, iconAnchor) then
            hoveredSystemTooltip = {
                systemDefinition = munitionsSystem,
                anchor = iconAnchor,
            }
        elseif tracker.key == "tithes" and isPointInsideRect(mouseX, mouseY, iconAnchor) then
            hoveredSystemTooltip = {
                systemDefinition = titheSystem,
                anchor = iconAnchor,
            }
        end

        love.graphics.setColor(
            WORLD_RESOURCE_TRACKER_FILL_COLOR[1],
            WORLD_RESOURCE_TRACKER_FILL_COLOR[2],
            WORLD_RESOURCE_TRACKER_FILL_COLOR[3],
            WORLD_RESOURCE_TRACKER_FILL_COLOR[4]
        )
        love.graphics.rectangle(
            "fill",
            trackerX,
            rowY,
            layout.trackerWidth,
            layout.trackerHeight,
            layout.cornerRadius,
            layout.cornerRadius
        )
        love.graphics.setColor(
            WORLD_RESOURCE_TRACKER_OUTLINE_COLOR[1],
            WORLD_RESOURCE_TRACKER_OUTLINE_COLOR[2],
            WORLD_RESOURCE_TRACKER_OUTLINE_COLOR[3],
            WORLD_RESOURCE_TRACKER_OUTLINE_COLOR[4]
        )
        love.graphics.setLineWidth(layout.lineWidth)
        love.graphics.rectangle(
            "line",
            trackerX,
            rowY,
            layout.trackerWidth,
            layout.trackerHeight,
            layout.cornerRadius,
            layout.cornerRadius
        )
        love.graphics.setLineWidth(1)

        love.graphics.setFont(labelFont)
        love.graphics.setColor(
            WORLD_RESOURCE_TRACKER_LABEL_COLOR[1],
            WORLD_RESOURCE_TRACKER_LABEL_COLOR[2],
            WORLD_RESOURCE_TRACKER_LABEL_COLOR[3],
            WORLD_RESOURCE_TRACKER_LABEL_COLOR[4]
        )
        local labelText = tracker.label
        local labelX = trackerX + layout.paddingX
        local labelY = rowY + layout.labelOffsetY
        love.graphics.print(labelText, labelX, labelY)

        local trackerSystem = tracker.key == "munitions" and munitionsSystem
            or tracker.key == "tithes" and titheSystem
            or nil

        if trackerSystem and trackerSystem.name then
            love.graphics.setFont(valueFont)
            love.graphics.setColor(
                WORLD_RESOURCE_TRACKER_DETAIL_COLOR[1],
                WORLD_RESOURCE_TRACKER_DETAIL_COLOR[2],
                WORLD_RESOURCE_TRACKER_DETAIL_COLOR[3],
                WORLD_RESOURCE_TRACKER_DETAIL_COLOR[4]
            )
            love.graphics.print(
                trackerSystem.name,
                trackerX + layout.paddingX,
                rowY + layout.valueOffsetY
            )
        end

        love.graphics.setFont(valueFont)
        love.graphics.setColor(
            WORLD_RESOURCE_TRACKER_TEXT_COLOR[1],
            WORLD_RESOURCE_TRACKER_TEXT_COLOR[2],
            WORLD_RESOURCE_TRACKER_TEXT_COLOR[3],
            WORLD_RESOURCE_TRACKER_TEXT_COLOR[4]
        )
        love.graphics.printf(
            tostring(value),
            trackerX + layout.paddingX,
            rowY + layout.valueOffsetY,
            layout.trackerWidth - (layout.paddingX * 2),
            "right"
        )
    end

    love.graphics.setColor(1, 1, 1, 1)
    return hoveredSystemTooltip and hoveredSystemTooltip.systemDefinition and hoveredSystemTooltip or nil
end

local function getDeckSourceAt(state, x, y)
    for _, target in ipairs(state and state.worldMapPreviewDeckTargets or {}) do
        if isPointInsideRect(x, y, target) then
            return target
        end
    end

    return nil
end

local function getObjectivePreviewSourceAt(state, x, y)
    for _, target in ipairs(state and state.worldMapObjectivePreviewTargets or {}) do
        if isPointInsideRect(x, y, target) then
            return target
        end
    end

    return nil
end

getSelectedRunLoadoutLayout = function(state)
    if not state or not state.selectedRunJaclId then
        return nil
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

    return {
        x = x,
        y = y,
        gap = gap,
        jaclWidth = jaclWidth,
        jaclHeight = jaclHeight,
        jaclLabelHeight = jaclLabelHeight,
        agentWidth = agentWidth,
        agentHeight = agentHeight,
    }
end

local function getSelectedRunLoadoutDeckSourceAt(state, x, y)
    local layout = getSelectedRunLoadoutLayout(state)

    if not layout then
        return nil
    end

    local jaclDefinition = getJaclById(state.selectedRunJaclId)

    if isPointInsideRect(x, y, {
        x = layout.x,
        y = layout.y,
        width = layout.jaclWidth,
        height = layout.jaclHeight - layout.jaclLabelHeight,
    }) then
        return {
            definition = jaclDefinition,
            title = jaclDefinition and jaclDefinition.name or "JACL",
        }
    end

    local agentIds = state.selectedRunAgentIds or {}

    for agentIndex = 1, 2 do
        local agentX = layout.x + layout.jaclWidth + layout.gap + ((agentIndex - 1) * (layout.agentWidth + layout.gap))
        local agentY = layout.y + layout.jaclHeight - layout.agentHeight
        local agentDefinition = getTroopById(agentIds[agentIndex])

        if agentDefinition
            and carddraw.isPointInsideCard(x, y, agentX, agentY, 0, {
                width = layout.agentWidth,
                showLabelWhenCollapsed = false,
            }) then
            return {
                definition = agentDefinition,
                title = agentDefinition.name or agentDefinition.id,
            }
        end
    end

    return nil
end

local function buildPreviewDeck(deckSource)
    local definition = deckSource and deckSource.definition or nil
    local candidateDeckIds = {}

    if definition and definition.deckId then
        candidateDeckIds[#candidateDeckIds + 1] = definition.deckId
    end

    if definition and definition.deck then
        candidateDeckIds[#candidateDeckIds + 1] = definition.deck
    end

    if definition and definition.id then
        candidateDeckIds[#candidateDeckIds + 1] = definition.id
    end

    for _, deckId in ipairs(candidateDeckIds) do
        local deck = deckrules.buildDeck(deckId)

        if deck then
            deck.owner = "worldstage"
            deck.displayTitle = deckSource.title or definition.name or deck.name
            return deck
        end
    end

    return nil
end

local function openWorldMapDeckModal(state, deckSource, deps)
    local deck = buildPreviewDeck(deckSource)

    if not state or not deck then
        return false
    end

    state.worldMapDeckModal = {
        deck = deck,
        scrollY = 0,
    }

    if deps and deps.sfxrules and deps.sfxrules.playClick then
        deps.sfxrules.playClick()
    end

    return true
end

local function openWorldMapObjectivePreviewModal(state, objectiveSource, deps)
    if not state or not objectiveSource or not objectiveSource.definition then
        return false
    end

    state.worldMapObjectivePreviewModal = {
        definition = objectiveSource.definition,
    }

    if deps and deps.sfxrules and deps.sfxrules.playClick then
        deps.sfxrules.playClick()
    end

    return true
end

local function getDefinitionDeckId(definition)
    return definition and (definition.deckId or definition.deck or definition.id) or nil
end

local function buildMissionLaunchPayload(state, hoveredNode)
    local preview = hoveredNode and hoveredNode.preview or nil

    if not state or not preview then
        return nil
    end

    local payload = {
        jaclId = state.selectedRunJaclId,
        agentIds = {},
        championAdditionalDeckIds = {},
        prize = preview.prize,
    }

    for _, agentId in ipairs(state.selectedRunAgentIds or {}) do
        payload.agentIds[#payload.agentIds + 1] = agentId
    end

    for _, encounter in ipairs(preview.encounters or {}) do
        local definition = encounter.definition or nil

        if encounter.sourceKind == "champion" and definition and not payload.championId then
            payload.championId = definition.id
        elseif encounter.sourceKind == "warzone" and definition and not payload.warzoneId then
            payload.warzoneId = definition.id
        elseif encounter.sourceKind == "stdpkg" or encounter.sourceKind == "modularpkg" then
            local deckId = getDefinitionDeckId(definition)

            if deckId then
                payload.championAdditionalDeckIds[#payload.championAdditionalDeckIds + 1] = deckId
            end
        end
    end

    if not payload.jaclId or #payload.agentIds <= 0 or not payload.championId or not payload.warzoneId then
        return nil
    end

    return payload
end

local function tryLaunchMissionFromNodePreview(state, x, y, deps)
    local target = nil

    for _, candidateTarget in ipairs(state and state.worldMapNodePlayButtonTargets or {}) do
        if isPointInsideRect(x, y, candidateTarget) then
            target = candidateTarget
            break
        end
    end

    target = target or state and state.worldMapNodePlayButtonTarget or nil

    if not target or not isPointInsideRect(x, y, target) then
        return false
    end

    local payload = buildMissionLaunchPayload(state, target.hoveredNode)

    if not payload or not deps or not deps.startMissionFromWorldNode then
        return false
    end

    if deps.startMissionFromWorldNode(payload) then
        state.loadingWorldMapNode = target.hoveredNode

        if deps.sfxrules and deps.sfxrules.playMissionStart then
            deps.sfxrules.playMissionStart()
        elseif deps.sfxrules and deps.sfxrules.playGo then
            deps.sfxrules.playGo()
        elseif deps.sfxrules and deps.sfxrules.playClick then
            deps.sfxrules.playClick()
        end

        return true
    end

    return false
end

local function getWorldMapDeckModalLayout(deckModal)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local deck = deckModal and deckModal.deck or nil
    local cards = deck and deck.cards or {}
    local cardWidth, cardHeight = carddraw.getCardSize({
        width = WORLD_DECK_MODAL_CARD_WIDTH,
        showLabelWhenCollapsed = true,
    })
    local sectionWidth = math.max(
        cardWidth,
        windowWidth - ((WORLD_DECK_MODAL_MARGIN + WORLD_DECK_MODAL_PADDING) * 2)
    )
    local cardsPerRow = math.max(1, math.floor((sectionWidth + WORLD_DECK_MODAL_CARD_GAP) / (cardWidth + WORLD_DECK_MODAL_CARD_GAP)))
    local usedSectionWidth = (cardsPerRow * cardWidth) + ((cardsPerRow - 1) * WORLD_DECK_MODAL_CARD_GAP)
    local contentWidth = math.min(sectionWidth, usedSectionWidth)
    local modalWidth = contentWidth + (WORLD_DECK_MODAL_PADDING * 2)
    local viewportHeight = math.max(
        cardHeight,
        math.min(
            windowHeight - (WORLD_DECK_MODAL_MARGIN * 2) - (WORLD_DECK_MODAL_PADDING * 2) - WORLD_DECK_MODAL_HEADER_HEIGHT,
            (windowHeight * WORLD_DECK_MODAL_MAX_HEIGHT_RATIO) - (WORLD_DECK_MODAL_PADDING * 2) - WORLD_DECK_MODAL_HEADER_HEIGHT
        )
    )
    local rows = math.max(1, math.ceil(math.max(1, #cards) / cardsPerRow))
    local bodyContentHeight = (rows * cardHeight) + ((rows - 1) * WORLD_DECK_MODAL_CARD_GAP)
    local maxScroll = math.max(0, bodyContentHeight - viewportHeight)
    local scrollY = math.max(0, math.min(maxScroll, deckModal and deckModal.scrollY or 0))
    local modalHeight = WORLD_DECK_MODAL_HEADER_HEIGHT + viewportHeight + (WORLD_DECK_MODAL_PADDING * 2)
    local modalX = (windowWidth - modalWidth) * 0.5
    local modalY = (windowHeight - modalHeight) * 0.5
    local bodyX = modalX + WORLD_DECK_MODAL_PADDING
    local bodyY = modalY + WORLD_DECK_MODAL_PADDING + WORLD_DECK_MODAL_HEADER_HEIGHT
    local cardLayouts = {}

    for cardIndex, card in ipairs(cards) do
        local rowIndex = math.floor((cardIndex - 1) / cardsPerRow)
        local columnIndex = (cardIndex - 1) % cardsPerRow

        cardLayouts[#cardLayouts + 1] = {
            card = card,
            x = bodyX + (columnIndex * (cardWidth + WORLD_DECK_MODAL_CARD_GAP)),
            y = bodyY + (rowIndex * (cardHeight + WORLD_DECK_MODAL_CARD_GAP)) - scrollY,
            width = cardWidth,
        }
    end

    return {
        x = modalX,
        y = modalY,
        width = modalWidth,
        height = modalHeight,
        bodyX = bodyX,
        bodyY = bodyY,
        bodyWidth = contentWidth,
        bodyHeight = viewportHeight,
        bodyContentHeight = bodyContentHeight,
        cardHeight = cardHeight,
        cardLayouts = cardLayouts,
        maxScroll = maxScroll,
        scrollY = scrollY,
    }
end

local function getWorldMapDeckModalCardAt(deckModal, x, y)
    local layout = getWorldMapDeckModalLayout(deckModal)

    if not isPointInsideRect(x, y, {
        x = layout.bodyX,
        y = layout.bodyY,
        width = layout.bodyWidth,
        height = layout.bodyHeight,
    }) then
        return nil
    end

    for _, cardLayout in ipairs(layout.cardLayouts or {}) do
        if carddraw.isPointInsideCard(x, y, cardLayout.x, cardLayout.y, 0, {
            width = cardLayout.width,
            showLabelWhenCollapsed = true,
            showHealthOnPortrait = false,
            showBadgesInTextbox = true,
        }) then
            return cardLayout.card
        end
    end

    return nil
end

local function getObjectiveCardPreviewLayout()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local width = math.min(OBJECTIVE_CARD_PREVIEW_WIDTH, windowWidth - 48)
    local imageHeight = width
    local diceBadgeWidth = math.max(34, math.floor(width * 0.16))
    local diceBadgeHeight = math.floor(diceBadgeWidth * 1.44)
    local planHeight = math.max(36, math.floor(width * 0.12))
    local height = OBJECTIVE_CARD_PREVIEW_LABEL_HEIGHT + imageHeight + planHeight + OBJECTIVE_CARD_PREVIEW_TEXTBOX_HEIGHT
    local x = (windowWidth - width) * 0.5
    local y = math.max(24, (windowHeight - height) * 0.5)

    return {
        x = x,
        y = y,
        width = width,
        height = height,
        labelHeight = OBJECTIVE_CARD_PREVIEW_LABEL_HEIGHT,
        imageX = x,
        imageY = y + OBJECTIVE_CARD_PREVIEW_LABEL_HEIGHT,
        imageWidth = width,
        imageHeight = imageHeight,
        planY = y + OBJECTIVE_CARD_PREVIEW_LABEL_HEIGHT + imageHeight,
        planHeight = planHeight,
        textboxY = y + OBJECTIVE_CARD_PREVIEW_LABEL_HEIGHT + imageHeight + planHeight,
        textboxHeight = OBJECTIVE_CARD_PREVIEW_TEXTBOX_HEIGHT,
        diceBadgeWidth = diceBadgeWidth,
        diceBadgeHeight = diceBadgeHeight,
    }
end

local function getObjectiveCardTrackValues(definition, accentColor)
    if definition and (definition.type == "warzone" or definition.type == "poi") then
        local control = tonumber(definition.control) or 0
        local maxControl = math.max(math.abs(control), math.floor(tonumber(definition.max) or 0))
        local trackColor = control < 0 and OBJECTIVE_CARD_PREVIEW_HOSTILE_INFLUENCE_COLOR or OBJECTIVE_CARD_PREVIEW_WARZONE_COLOR

        return math.abs(math.floor(control)), maxControl, trackColor
    end

    local plan = math.max(0, math.floor(tonumber(definition and definition.plan) or 0))
    local maxPlan = math.max(plan, math.floor(tonumber(definition and definition.max) or 0))

    return plan, maxPlan, accentColor
end

local function drawObjectiveCardPlanTrack(definition, layout, accentColor)
    local plan, maxPlan, trackColor = getObjectiveCardTrackValues(definition, accentColor)
    local trackX = layout.x + OBJECTIVE_CARD_PREVIEW_PADDING
    local trackWidth = layout.width - (OBJECTIVE_CARD_PREVIEW_PADDING * 2)
    local pipGap = 4
    local columns = math.min(10, math.max(1, maxPlan))
    local rows = math.max(1, math.ceil(math.max(1, maxPlan) / columns))
    local pipSize = math.max(4, math.min(
        math.floor((trackWidth - ((columns - 1) * pipGap)) / columns),
        math.floor((layout.planHeight - 12 - ((rows - 1) * pipGap)) / rows),
        OBJECTIVE_CARD_PREVIEW_PLAN_PIP_MAX_SIZE
    ))
    local totalWidth = (columns * pipSize) + ((columns - 1) * pipGap)
    local totalHeight = (rows * pipSize) + ((rows - 1) * pipGap)
    local startX = trackX + ((trackWidth - totalWidth) * 0.5)
    local startY = layout.planY + ((layout.planHeight - totalHeight) * 0.5)

    for pipIndex = 1, maxPlan do
        local row = math.floor((pipIndex - 1) / columns)
        local column = (pipIndex - 1) % columns
        local pipX = startX + (column * (pipSize + pipGap))
        local pipY = startY + (row * (pipSize + pipGap))

        if pipIndex <= plan then
            love.graphics.setColor(trackColor[1], trackColor[2], trackColor[3], 1)
            love.graphics.rectangle("fill", pipX, pipY, pipSize, pipSize)
        else
            love.graphics.setColor(trackColor[1], trackColor[2], trackColor[3], 0.62)
            love.graphics.rectangle("line", pipX, pipY, pipSize, pipSize)
        end
    end
end

local function drawObjectiveCardEmphasisBadge(definition, layout, accentColor)
    if not definition or definition.emphasis == nil then
        return
    end

    local badgeSize = math.max(26, math.floor(layout.width * 0.18))
    local badgeInset = math.max(8, math.floor(layout.width * 0.04))
    local badgeX = layout.imageX + layout.imageWidth - badgeInset - badgeSize
    local badgeY = layout.imageY + badgeInset
    local badgeFont = getFont(math.max(14, math.floor(badgeSize * 0.48)))

    love.graphics.setColor(0.05, 0.05, 0.06, 0.96)
    love.graphics.rectangle("fill", badgeX, badgeY, badgeSize, badgeSize)
    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.95)
    love.graphics.rectangle("line", badgeX, badgeY, badgeSize, badgeSize)
    love.graphics.setFont(badgeFont)
    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 1)
    love.graphics.printf(
        tostring(definition.emphasis),
        badgeX,
        badgeY + ((badgeSize - badgeFont:getHeight()) * 0.5),
        badgeSize,
        "center"
    )
end

local function getObjectiveCardDiceBadgeLayouts(layout)
    local badgeInset = math.max(8, math.floor(layout.width * 0.035))
    local availableWidth = layout.imageWidth - (badgeInset * 2)
    local badgeGap = math.min(
        OBJECTIVE_CARD_PREVIEW_DICE_GAP,
        math.max(2, (availableWidth - (layout.diceBadgeWidth * 6)) / 5)
    )
    local totalWidth = (layout.diceBadgeWidth * 6) + (badgeGap * 5)
    local startX = layout.imageX + ((layout.imageWidth - totalWidth) * 0.5)
    local badgeY = layout.imageY + layout.imageHeight - badgeInset - layout.diceBadgeHeight
    local badgeLayouts = {}

    for faceIndex = 1, 6 do
        badgeLayouts[#badgeLayouts + 1] = {
            faceIndex = faceIndex,
            x = startX + ((faceIndex - 1) * (layout.diceBadgeWidth + badgeGap)),
            y = badgeY,
            width = layout.diceBadgeWidth,
            height = layout.diceBadgeHeight,
        }
    end

    return badgeLayouts
end

local function drawObjectiveCardDiceBadges(definition, layout)
    for _, badgeLayout in ipairs(getObjectiveCardDiceBadgeLayouts(layout)) do

        carddraw.drawDefinitionRollBadge(
            definition,
            badgeLayout.x,
            badgeLayout.y,
            badgeLayout.width,
            badgeLayout.height,
            badgeLayout.faceIndex
        )
    end
end

local function getObjectiveCardDiceTooltip(definition, layout, mouseX, mouseY)
    if not definition or not layout then
        return nil
    end

    for _, badgeLayout in ipairs(getObjectiveCardDiceBadgeLayouts(layout)) do
        if isPointInsideRect(mouseX, mouseY, badgeLayout) then
            local faceDefinition = carddraw.getCardFaceBadge(definition, badgeLayout.faceIndex, nil)
            local tooltip = carddraw.buildDiceFaceTooltip(
                faceDefinition,
                layout.imageX,
                layout.imageY,
                layout.imageWidth,
                layout.imageHeight
            )

            if tooltip then
                tooltip.badgeX = badgeLayout.x
                tooltip.badgeY = badgeLayout.y
                tooltip.badgeWidth = badgeLayout.width
                tooltip.badgeHeight = badgeLayout.height
            end

            return tooltip
        end
    end

    return nil
end

local function drawObjectiveCardPreviewModal(modal)
    local definition = modal and modal.definition or nil

    if not definition then
        return
    end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    local layout = getObjectiveCardPreviewLayout()
    local accentColor = OBJECTIVE_CARD_PREVIEW_PLAN_COLOR

    if definition.type == "intel" then
        accentColor = OBJECTIVE_CARD_PREVIEW_INTEL_COLOR
    elseif definition.type == "warzone" or definition.type == "poi" then
        accentColor = OBJECTIVE_CARD_PREVIEW_WARZONE_COLOR
    end

    local titleFont = getFont(18)
    local bodyFont = getFont(13)
    local image = (definition.type == "warzone" or definition.type == "poi")
        and getWarzonePreviewImage(definition.id)
        or getObjectivePreviewImage(definition.id)
    local textboxText = definition.textbox or definition.flavor or ""
    local previousFont = love.graphics.getFont()
    local mouseX, mouseY = love.mouse.getPosition()

    love.graphics.setColor(0.01, 0.01, 0.02, 0.72)
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    love.graphics.setColor(0.045, 0.05, 0.06, 0.98)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height, 8, 8)
    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.95)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height, 8, 8)

    love.graphics.setColor(0.01, 0.01, 0.015, 0.98)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.labelHeight, 8, 8)
    love.graphics.setFont(titleFont)
    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 1)
    love.graphics.printf(
        definition.name or definition.id or "Objective",
        layout.x + OBJECTIVE_CARD_PREVIEW_PADDING,
        layout.y + ((layout.labelHeight - titleFont:getHeight()) * 0.5),
        layout.width - (OBJECTIVE_CARD_PREVIEW_PADDING * 2),
        "left"
    )

    love.graphics.setColor(0.12, 0.13, 0.16, 1)
    love.graphics.rectangle("fill", layout.imageX, layout.imageY, layout.imageWidth, layout.imageHeight)

    if image then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(image, layout.imageX, layout.imageY, 0, layout.imageWidth / image:getWidth(), layout.imageHeight / image:getHeight())
    end

    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.9)
    love.graphics.rectangle("line", layout.imageX, layout.imageY, layout.imageWidth, layout.imageHeight)
    drawObjectiveCardDiceBadges(definition, layout)
    drawObjectiveCardEmphasisBadge(definition, layout, accentColor)

    love.graphics.setColor(0.02, 0.02, 0.025, 0.96)
    love.graphics.rectangle("fill", layout.x, layout.planY, layout.width, layout.planHeight)
    drawObjectiveCardPlanTrack(definition, layout, accentColor)
    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.8)
    love.graphics.rectangle("line", layout.x, layout.planY, layout.width, layout.planHeight)

    love.graphics.setColor(0.055, 0.06, 0.07, 0.98)
    love.graphics.rectangle("fill", layout.x, layout.textboxY, layout.width, layout.textboxHeight)
    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.8)
    love.graphics.rectangle("line", layout.x, layout.textboxY, layout.width, layout.textboxHeight)
    love.graphics.setFont(bodyFont)
    love.graphics.setColor(0.9, 0.91, 0.94, 1)
    love.graphics.printf(
        textboxText,
        layout.x + OBJECTIVE_CARD_PREVIEW_PADDING,
        layout.textboxY + OBJECTIVE_CARD_PREVIEW_PADDING,
        layout.width - (OBJECTIVE_CARD_PREVIEW_PADDING * 2),
        "left"
    )

    local diceTooltip = getObjectiveCardDiceTooltip(definition, layout, mouseX, mouseY)

    if diceTooltip then
        previewrules.applyDefinitionPreviewToTooltip(diceTooltip.definition or diceTooltip, diceTooltip, diceTooltip.previewLabel or "PREVIEW")

        local dicePreviewCards = diceTooltip.previewCardDefinitionEntries or diceTooltip.previewCardDefinitions
        local summonAnchorLayout = {
            cardX = layout.x,
            cardY = layout.y,
            cardWidth = layout.width,
            cardHeight = layout.height,
        }

        if drawDiceSummonPreviewLeft then
            if dicePreviewCards and #dicePreviewCards > 0 then
                drawDiceSummonPreviewLeft(dicePreviewCards, diceTooltip.previewLabel, summonAnchorLayout)
            elseif diceTooltip.previewCardDefinition then
                drawDiceSummonPreviewLeft({ diceTooltip.previewCardDefinition }, diceTooltip.previewLabel, summonAnchorLayout)
            end
        end

        carddraw.drawDiceFaceTooltip(diceTooltip)
    end

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

local function normalizeDiceSummonPreviewEntries(previewCards)
    local entries = {}

    for _, previewCard in ipairs(previewCards or {}) do
        if previewCard.definition then
            entries[#entries + 1] = {
                definition = previewCard.definition,
                count = math.max(1, math.floor(tonumber(previewCard.count or previewCard.quantity) or 1)),
            }
        elseif previewCard.cardDefinition then
            entries[#entries + 1] = {
                definition = previewCard.cardDefinition,
                count = math.max(1, math.floor(tonumber(previewCard.count or previewCard.quantity) or 1)),
            }
        else
            entries[#entries + 1] = {
                definition = previewCard,
                count = math.max(1, math.floor(tonumber(previewCard.count or previewCard.quantity) or 1)),
            }
        end
    end

    return entries
end

local function getDiceSummonPreviewEntryWidth(previewWidth, previewEntry)
    local count = math.max(1, tonumber(previewEntry and previewEntry.count) or 1)
    local visibleStackCount = math.min(count, 5)

    return previewWidth + ((visibleStackCount - 1) * previewWidth * 0.24)
end

local function getDiceSummonPreviewWidth(previewEntries, previewWidth)
    local width = 0

    for entryIndex, previewEntry in ipairs(previewEntries or {}) do
        if entryIndex > 1 then
            width = width + DICE_SUMMON_PREVIEW_GAP
        end

        width = width + getDiceSummonPreviewEntryWidth(previewWidth, previewEntry)
    end

    return width
end

local function drawDiceSummonPreviewStack(previewEntry, x, y, previewWidth, previewHeight, labelFont)
    local definition = previewEntry and previewEntry.definition or nil

    if not definition then
        return
    end

    local count = math.max(1, math.floor(tonumber(previewEntry.count) or 1))
    local visibleStackCount = math.min(count, 5)
    local stackOffset = previewWidth * 0.24

    for stackIndex = visibleStackCount, 1, -1 do
        local cardX = x + ((stackIndex - 1) * stackOffset)

        if stackIndex > 1 then
            love.graphics.setColor(0.02, 0.025, 0.03, 0.72)
            love.graphics.rectangle("fill", cardX - 4, y + 4, previewWidth, previewHeight, 8, 8)
            love.graphics.setColor(0.86, 0.88, 0.93, 0.64)
            love.graphics.rectangle("line", cardX, y, previewWidth, previewHeight, 8, 8)
        end

        carddraw.drawCardState(definition.setName, definition.id, cardX, y, 1, {
            width = previewWidth,
            showBadgesInTextbox = true,
        })
    end

    if count > 1 then
        local badgeText = "x" .. tostring(count)
        local badgePaddingX = DICE_SUMMON_PREVIEW_PADDING * 0.7
        local badgeHeight = labelFont:getHeight() + 8
        local badgeWidth = math.max(labelFont:getWidth(badgeText) + (badgePaddingX * 2), badgeHeight)
        local badgeX = x + getDiceSummonPreviewEntryWidth(previewWidth, previewEntry) - badgeWidth - 8
        local badgeY = y + previewHeight - badgeHeight - 8

        love.graphics.setColor(0.04, 0.045, 0.055, 0.94)
        love.graphics.rectangle("fill", badgeX, badgeY, badgeWidth, badgeHeight, 5, 5)
        love.graphics.setColor(0.92, 0.94, 0.98, 0.92)
        love.graphics.rectangle("line", badgeX, badgeY, badgeWidth, badgeHeight, 5, 5)
        love.graphics.setFont(labelFont)
        love.graphics.setColor(0.96, 0.97, 1, 1)
        love.graphics.printf(badgeText, badgeX, badgeY + ((badgeHeight - labelFont:getHeight()) / 2), badgeWidth, "center")
    end
end

drawDiceSummonPreviewLeft = function(previewCards, labelText, cardLayout)
    local previewEntries = normalizeDiceSummonPreviewEntries(previewCards)

    if #previewEntries <= 0 or not cardLayout then
        return
    end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    local labelFont = getFont(14)
    local previewWidth, previewHeight = carddraw.getExpandedCardSize({
        width = math.min(190, math.max(150, windowWidth * 0.1)),
    })
    local totalWidth = getDiceSummonPreviewWidth(previewEntries, previewWidth)
    local bubbleHeight = (DICE_SUMMON_PREVIEW_PADDING * 2) + labelFont:getHeight()
    local totalHeight = previewHeight + DICE_SUMMON_PREVIEW_GAP + bubbleHeight
    local boxX = math.max(8, cardLayout.cardX - DICE_SUMMON_PREVIEW_GAP - totalWidth)
    local boxY = math.max(8, math.min(cardLayout.cardY, windowHeight - totalHeight - 8))
    local bubbleY = boxY + previewHeight + DICE_SUMMON_PREVIEW_GAP
    local previewX = boxX

    love.graphics.setColor(0.02, 0.025, 0.03, 0.42)
    love.graphics.rectangle(
        "fill",
        boxX - DICE_SUMMON_PREVIEW_PADDING,
        boxY - DICE_SUMMON_PREVIEW_PADDING,
        totalWidth + (DICE_SUMMON_PREVIEW_PADDING * 2),
        totalHeight + (DICE_SUMMON_PREVIEW_PADDING * 2),
        8,
        8
    )

    for _, previewEntry in ipairs(previewEntries) do
        drawDiceSummonPreviewStack(previewEntry, previewX, boxY, previewWidth, previewHeight, labelFont)
        previewX = previewX + getDiceSummonPreviewEntryWidth(previewWidth, previewEntry) + DICE_SUMMON_PREVIEW_GAP
    end

    love.graphics.setColor(0.05, 0.05, 0.06, 0.96)
    love.graphics.rectangle("fill", boxX, bubbleY, totalWidth, bubbleHeight, 6, 6)
    love.graphics.setColor(0.82, 0.85, 0.89, 0.82)
    love.graphics.rectangle("line", boxX, bubbleY, totalWidth, bubbleHeight, 6, 6)

    love.graphics.setFont(labelFont)
    love.graphics.setColor(0.95, 0.96, 0.98, 1)
    love.graphics.printf(
        labelText or "SUMMON",
        boxX + DICE_SUMMON_PREVIEW_PADDING,
        bubbleY + ((bubbleHeight - labelFont:getHeight()) / 2),
        totalWidth - (DICE_SUMMON_PREVIEW_PADDING * 2),
        "center"
    )
end

local function drawWorldMapDeckCardPreview(card)
    if not card then
        return
    end

    local cardDefinition = cardregistry.getCard(card.setName, card.cardId)
    local preview = previewrules.getDefinitionPreview(cardDefinition, nil, card)
    local previewCards = preview and (preview.cardDefinitionEntries or preview.cardDefinitions) or nil
    local layout = envdraw.getJaclDeckPreviewModalLayout(previewCards)
    local mouseX, mouseY = love.mouse.getPosition()
    local diceTooltip = nil

    envdraw.drawJaclDeckPreviewModal(card, preview)

    diceTooltip = carddraw.getHoveredDiceFace(
        card.setName,
        card.cardId,
        layout.cardX,
        layout.cardY,
        1,
        {
            displayName = card.displayName,
            portraitPath = card.portraitPath,
            showBadgesInTextbox = true,
        },
        mouseX,
        mouseY,
        nil
    )

    if diceTooltip then
        previewrules.applyDefinitionPreviewToTooltip(diceTooltip.definition or diceTooltip, diceTooltip, diceTooltip.previewLabel or "SUMMON")

        local dicePreviewCards = diceTooltip.previewCardDefinitionEntries or diceTooltip.previewCardDefinitions

        if dicePreviewCards and #dicePreviewCards > 0 then
            drawDiceSummonPreviewLeft(dicePreviewCards, diceTooltip.previewLabel, layout)
        elseif diceTooltip.previewCardDefinition then
            drawDiceSummonPreviewLeft({ diceTooltip.previewCardDefinition }, diceTooltip.previewLabel, layout)
        end

        carddraw.drawDiceFaceTooltip(diceTooltip)
    end
end

local function drawWorldMapDeckModal(deckModal)
    if not deckModal or not deckModal.deck then
        return
    end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    local layout = getWorldMapDeckModalLayout(deckModal)
    local previousFont = love.graphics.getFont()
    local headerFont = getFont(18)
    local deck = deckModal.deck
    local cards = deck.cards or {}
    local title = deck.displayTitle or deck.name or "Deck"

    love.graphics.setColor(0.01, 0.01, 0.02, 0.72)
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    love.graphics.setColor(0.06, 0.07, 0.09, 0.96)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height, 10, 10)
    love.graphics.setColor(0.82, 0.85, 0.89, 0.78)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height, 10, 10)

    love.graphics.setFont(headerFont)
    love.graphics.setColor(0.93, 0.93, 0.95, 1)
    love.graphics.print(
        title .. " Deck (" .. tostring(#cards) .. ")",
        layout.x + WORLD_DECK_MODAL_PADDING,
        layout.y + WORLD_DECK_MODAL_PADDING + ((WORLD_DECK_MODAL_HEADER_HEIGHT - headerFont:getHeight()) * 0.5)
    )

    love.graphics.setScissor(
        math.floor(layout.bodyX),
        math.floor(layout.bodyY),
        math.max(1, math.floor(layout.bodyWidth)),
        math.max(1, math.floor(layout.bodyHeight))
    )

    for _, cardLayout in ipairs(layout.cardLayouts) do
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

    if layout.maxScroll > 0 then
        local trackHeight = math.max(24, layout.bodyHeight)
        local thumbHeight = math.max(20, trackHeight * (layout.bodyHeight / layout.bodyContentHeight))
        local thumbTravel = math.max(0, trackHeight - thumbHeight)
        local thumbY = layout.bodyY + (thumbTravel * (layout.scrollY / layout.maxScroll))

        love.graphics.setColor(0.22, 0.24, 0.29, 0.9)
        love.graphics.rectangle("fill", layout.bodyX + layout.bodyWidth - 6, layout.bodyY + 4, 3, trackHeight - 8, 2, 2)
        love.graphics.setColor(0.88, 0.9, 0.94, 0.8)
        love.graphics.rectangle("fill", layout.bodyX + layout.bodyWidth - 7, thumbY + 4, 5, math.max(12, thumbHeight - 8), 2, 2)
    end

    drawWorldMapDeckCardPreview(deckModal.cardPreview)

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

function worldmapdraw.updateHover(state, deps)
    if not state then
        return
    end

    if state.worldMapRewardModal then
        state.hoveredWorldMapNode = nil
        state.pinnedWorldMapNode = nil
        state.worldMapDeckModal = nil
        state.worldMapObjectivePreviewModal = nil
        state.worldMapNodePlayButtonTarget = nil
        state.worldMapNodePlayButtonTargets = nil
        return
    end

    if state.pinnedWorldMapNode then
        state.hoveredWorldMapNode = nil
        return
    end

    local mouseX, mouseY = love.mouse.getPosition()
    local previousHoveredNode = state.hoveredWorldMapNode

    state.hoveredWorldMapNode = getHoveredFunctionalNode(state, mouseX, mouseY)

    if state.hoveredWorldMapNode
        and (
            not previousHoveredNode
            or previousHoveredNode.clusterIndex ~= state.hoveredWorldMapNode.clusterIndex
            or previousHoveredNode.nodeIndex ~= state.hoveredWorldMapNode.nodeIndex
        )
        and deps
        and deps.sfxrules
        and deps.sfxrules.playHover then
        deps.sfxrules.playHover()
    end
end

function worldmapdraw.updateRewardModal(state, dt)
    return worldrewardmodal.update(state, dt)
end

function worldmapdraw.mousepressed(state, x, y, button, deps)
    if not state then
        return false
    end

    if state.worldMapRewardModal then
        return worldrewardmodal.mousepressed(state, x, y, button, deps)
    end

    if state.worldMapObjectivePreviewModal then
        state.worldMapObjectivePreviewModal = nil
        return true
    end

    if state.worldMapDeckModal then
        if state.worldMapDeckModal.cardPreview then
            state.worldMapDeckModal.cardPreview = nil
            return true
        end

        if button == 2 then
            state.worldMapDeckModal.cardPreview = getWorldMapDeckModalCardAt(state.worldMapDeckModal, x, y)
            return true
        end

        state.worldMapDeckModal = nil
        return true
    end

    if button == 3 then
        local objectiveSource = getObjectivePreviewSourceAt(state, x, y)

        if objectiveSource then
            return openWorldMapObjectivePreviewModal(state, objectiveSource, deps)
        end

        local deckSource = getDeckSourceAt(state, x, y) or getSelectedRunLoadoutDeckSourceAt(state, x, y)

        return openWorldMapDeckModal(state, deckSource, deps)
    end

    if button == 2 then
        if state.pinnedWorldMapNode then
            state.pinnedWorldMapNode = nil

            if deps and deps.sfxrules and deps.sfxrules.playClick then
                deps.sfxrules.playClick()
            end

            return true
        end

        return false
    end

    if button ~= 1 then
        return false
    end

    if tryLaunchMissionFromNodePreview(state, x, y, deps) then
        return true
    end

    local hoveredNode = state.hoveredWorldMapNode or getHoveredFunctionalNode(state, x, y)

    if not hoveredNode then
        return false
    end

    state.pinnedWorldMapNode = hoveredNode
    state.hoveredWorldMapNode = nil

    if deps and deps.sfxrules and deps.sfxrules.playClick then
        deps.sfxrules.playClick()
    end

    return true
end

function worldmapdraw.wheelmoved(state, _, y)
    if worldrewardmodal.wheelmoved(state) then
        return true
    end

    local deckModal = state and state.worldMapDeckModal or nil

    if not deckModal or not deckModal.deck then
        return false
    end

    local mouseX, mouseY = love.mouse.getPosition()
    local layout = getWorldMapDeckModalLayout(deckModal)

    if not isPointInsideRect(mouseX, mouseY, {
        x = layout.bodyX,
        y = layout.bodyY,
        width = layout.bodyWidth,
        height = layout.bodyHeight,
    }) then
        return true
    end

    local scrollDelta = -(y or 0) * 42
    deckModal.scrollY = math.max(0, math.min(layout.maxScroll, (deckModal.scrollY or 0) + scrollDelta))

    return true
end

function worldmapdraw.getNextMapPosition(playerMapPosition)
    return getNextMapPosition(playerMapPosition)
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

local function drawAgentLoadoutNameLabel(agentDefinition, x, y, width, height)
    local nameText = agentDefinition and (agentDefinition.name or agentDefinition.id) or nil

    if not nameText then
        return
    end

    local previousFont = love.graphics.getFont()
    local labelHeight = math.max(16, math.floor(height * 0.18))
    local labelY = y + height - labelHeight
    local labelFont = getFont(math.max(8, math.floor(width * 0.105)))

    love.graphics.setColor(0.02, 0.02, 0.025, 0.88)
    love.graphics.rectangle("fill", x, labelY, width, labelHeight, 0, 0)
    love.graphics.setFont(labelFont)
    love.graphics.setColor(0.93, 0.93, 0.95, 1)
    love.graphics.printf(
        nameText,
        x + 4,
        labelY + ((labelHeight - labelFont:getHeight()) * 0.5),
        width - 8,
        "center"
    )
    love.graphics.setFont(previousFont)
end

local function drawWorldRolePortraits(state)
    if state and state.runSetupModal and state.runSetupModal.isOpen then
        return
    end

    local layout = getSelectedRunLoadoutLayout(state)

    if not layout then
        return
    end

    local roleCount = #WORLD_ROLE_PORTRAITS
    local gap = math.max(6, math.floor(layout.gap * 0.65))
    local resourceLayout = getWorldResourceTrackerLayout(state)
    local resourceTrackerRight = resourceLayout.x
        + resourceLayout.iconSize
        + resourceLayout.iconGap
        + resourceLayout.trackerWidth
    local totalWidth = math.max(1, resourceTrackerRight - layout.x)
    local boxWidth = (totalWidth - (gap * (roleCount - 1))) / roleCount
    local boxHeight = math.max(56, boxWidth * 1.12)
    local y = math.floor(layout.y - gap - boxHeight)
    local labelHeight = math.max(18, boxHeight * 0.24)
    local portraitHeight = boxHeight - labelHeight
    local previousFont = love.graphics.getFont()
    local labelFont = getFont(math.max(8, math.floor(boxWidth * 0.12)))

    for roleIndex, rolePortrait in ipairs(WORLD_ROLE_PORTRAITS) do
        local roleLabel = rolePortrait.label
        local x = layout.x + ((roleIndex - 1) * (boxWidth + gap))
        local image = getCrewImage(rolePortrait.image)

        love.graphics.setColor(0.025, 0.028, 0.035, 0.9)
        love.graphics.rectangle("fill", x, y, boxWidth, boxHeight, 5, 5)
        love.graphics.setColor(
            WORLD_ROLE_PORTRAIT_OUTLINE_COLOR[1],
            WORLD_ROLE_PORTRAIT_OUTLINE_COLOR[2],
            WORLD_ROLE_PORTRAIT_OUTLINE_COLOR[3],
            WORLD_ROLE_PORTRAIT_OUTLINE_COLOR[4]
        )
        love.graphics.rectangle("line", x, y, boxWidth, boxHeight, 5, 5)

        love.graphics.setColor(
            WORLD_ROLE_PORTRAIT_FILL_COLOR[1],
            WORLD_ROLE_PORTRAIT_FILL_COLOR[2],
            WORLD_ROLE_PORTRAIT_FILL_COLOR[3],
            WORLD_ROLE_PORTRAIT_FILL_COLOR[4]
        )
        love.graphics.rectangle("fill", x + 5, y + 5, boxWidth - 10, portraitHeight - 8, 4, 4)

        if image then
            local imagePadding = 5
            local imageX = x + imagePadding
            local imageY = y + imagePadding
            local imageWidth = boxWidth - (imagePadding * 2)
            local imageHeight = portraitHeight - (imagePadding + 3)
            local imageScale = math.max(imageWidth / image:getWidth(), imageHeight / image:getHeight())
            local scaledWidth = image:getWidth() * imageScale
            local scaledHeight = image:getHeight() * imageScale
            local previousScissorX, previousScissorY, previousScissorWidth, previousScissorHeight = love.graphics.getScissor()

            love.graphics.setScissor(imageX, imageY, imageWidth, imageHeight)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                image,
                imageX + ((imageWidth - scaledWidth) * 0.5),
                imageY + ((imageHeight - scaledHeight) * 0.5),
                0,
                imageScale,
                imageScale
            )

            if previousScissorX then
                love.graphics.setScissor(previousScissorX, previousScissorY, previousScissorWidth, previousScissorHeight)
            else
                love.graphics.setScissor()
            end
        end

        love.graphics.setFont(labelFont)
        love.graphics.setColor(
            WORLD_ROLE_PORTRAIT_LABEL_COLOR[1],
            WORLD_ROLE_PORTRAIT_LABEL_COLOR[2],
            WORLD_ROLE_PORTRAIT_LABEL_COLOR[3],
            WORLD_ROLE_PORTRAIT_LABEL_COLOR[4]
        )
        love.graphics.printf(
            roleLabel,
            x + 4,
            y + portraitHeight + ((labelHeight - labelFont:getHeight()) * 0.5),
            boxWidth - 8,
            "center"
        )
    end

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

local function getWorldRolePortraitBounds(state, layout)
    local roleCount = #WORLD_ROLE_PORTRAITS
    local gap = math.max(6, math.floor(layout.gap * 0.65))
    local resourceLayout = getWorldResourceTrackerLayout(state)
    local resourceTrackerRight = resourceLayout.x
        + resourceLayout.iconSize
        + resourceLayout.iconGap
        + resourceLayout.trackerWidth
    local totalWidth = math.max(1, resourceTrackerRight - layout.x)
    local boxWidth = (totalWidth - (gap * (roleCount - 1))) / roleCount
    local boxHeight = math.max(56, boxWidth * 1.12)

    return {
        x = layout.x,
        y = math.floor(layout.y - gap - boxHeight),
        right = resourceTrackerRight,
        bottom = layout.y + layout.jaclHeight,
        gap = gap,
    }
end

local function drawWorldAlmsTracker(state)
    if state and state.runSetupModal and state.runSetupModal.isOpen then
        return
    end

    local layout = getSelectedRunLoadoutLayout(state)

    if not layout then
        return
    end

    local bounds = getWorldRolePortraitBounds(state, layout)
    local resourceLayout = getWorldResourceTrackerLayout(state)
    local iconSize = resourceLayout.iconSize
    local iconGap = resourceLayout.iconGap
    local trackerHeight = resourceLayout.trackerHeight
    local gap = bounds.gap
    local iconX = bounds.x
    local rowY = bounds.y - gap - trackerHeight
    local iconY = rowY + math.floor((trackerHeight - iconSize) * 0.5)
    local trackerX = iconX + iconSize + iconGap
    local trackerWidth = math.max(80, bounds.right - trackerX)
    local labelFont = getFont(resourceLayout.labelFontSize)
    local valueFont = getFont(resourceLayout.valueFontSize)
    local resources = state and state.worldResources or {}
    local value = math.max(0, math.floor(tonumber(resources.alms) or 0))
    local image = getMapImage("alms.png")

    if image then
        local imageScale = math.min(iconSize / image:getWidth(), iconSize / image:getHeight())
        local imageWidth = image:getWidth() * imageScale
        local imageHeight = image:getHeight() * imageScale

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

    love.graphics.setColor(
        WORLD_RESOURCE_TRACKER_FILL_COLOR[1],
        WORLD_RESOURCE_TRACKER_FILL_COLOR[2],
        WORLD_RESOURCE_TRACKER_FILL_COLOR[3],
        WORLD_RESOURCE_TRACKER_FILL_COLOR[4]
    )
    love.graphics.rectangle(
        "fill",
        trackerX,
        rowY,
        trackerWidth,
        trackerHeight,
        resourceLayout.cornerRadius,
        resourceLayout.cornerRadius
    )
    love.graphics.setColor(
        WORLD_ALMS_TRACKER_COLOR[1],
        WORLD_ALMS_TRACKER_COLOR[2],
        WORLD_ALMS_TRACKER_COLOR[3],
        WORLD_ALMS_TRACKER_COLOR[4]
    )
    love.graphics.setLineWidth(resourceLayout.lineWidth)
    love.graphics.rectangle(
        "line",
        trackerX,
        rowY,
        trackerWidth,
        trackerHeight,
        resourceLayout.cornerRadius,
        resourceLayout.cornerRadius
    )
    love.graphics.setLineWidth(1)

    love.graphics.setFont(labelFont)
    love.graphics.setColor(
        WORLD_ALMS_TRACKER_COLOR[1],
        WORLD_ALMS_TRACKER_COLOR[2],
        WORLD_ALMS_TRACKER_COLOR[3],
        WORLD_ALMS_TRACKER_COLOR[4]
    )
    love.graphics.print("Alms", trackerX + resourceLayout.paddingX, rowY + resourceLayout.labelOffsetY)

    love.graphics.setFont(valueFont)
    love.graphics.setColor(
        WORLD_ALMS_TRACKER_COLOR[1],
        WORLD_ALMS_TRACKER_COLOR[2],
        WORLD_ALMS_TRACKER_COLOR[3],
        WORLD_ALMS_TRACKER_COLOR[4]
    )
    love.graphics.printf(
        tostring(value),
        trackerX + resourceLayout.paddingX,
        rowY + resourceLayout.valueOffsetY,
        trackerWidth - (resourceLayout.paddingX * 2),
        "right"
    )

    love.graphics.setColor(1, 1, 1, 1)
end

local function drawWorldSystemsColumn(state)
    if state and state.runSetupModal and state.runSetupModal.isOpen then
        return
    end

    local layout = getSelectedRunLoadoutLayout(state)

    if not layout then
        return
    end

    local bounds = getWorldRolePortraitBounds(state, layout)
    local gap = bounds.gap
    local labelFont = getFont(12)
    local labelHeight = math.max(18, labelFont:getHeight())
    local boxGap = math.max(5, math.floor(gap * 0.75))
    local availableHeight = math.max(1, bounds.bottom - bounds.y - labelHeight - boxGap)
    local boxSize = math.max(30, math.floor((availableHeight - (boxGap * 4)) / 5))
    local x = bounds.right + layout.gap
    local y = bounds.y
    local boxX = x
    local boxY = y + labelHeight + boxGap
    local image = getMapImage("systems.png") or getMapImage("system.png")
    local previousFont = love.graphics.getFont()

    love.graphics.setFont(labelFont)
    love.graphics.setColor(
        WORLD_SYSTEMS_LABEL_COLOR[1],
        WORLD_SYSTEMS_LABEL_COLOR[2],
        WORLD_SYSTEMS_LABEL_COLOR[3],
        WORLD_SYSTEMS_LABEL_COLOR[4]
    )
    love.graphics.printf("Systems", x, y, boxSize, "center")

    for systemIndex = 1, 5 do
        local rowY = boxY + ((systemIndex - 1) * (boxSize + boxGap))

        love.graphics.setColor(0.025, 0.028, 0.035, 0.9)
        love.graphics.rectangle("fill", boxX, rowY, boxSize, boxSize, 5, 5)
        love.graphics.setColor(
            WORLD_SYSTEMS_OUTLINE_COLOR[1],
            WORLD_SYSTEMS_OUTLINE_COLOR[2],
            WORLD_SYSTEMS_OUTLINE_COLOR[3],
            WORLD_SYSTEMS_OUTLINE_COLOR[4]
        )
        love.graphics.rectangle("line", boxX, rowY, boxSize, boxSize, 5, 5)
        love.graphics.setColor(
            WORLD_SYSTEMS_BOX_FILL_COLOR[1],
            WORLD_SYSTEMS_BOX_FILL_COLOR[2],
            WORLD_SYSTEMS_BOX_FILL_COLOR[3],
            WORLD_SYSTEMS_BOX_FILL_COLOR[4]
        )
        love.graphics.rectangle("fill", boxX + 5, rowY + 5, boxSize - 10, boxSize - 10, 4, 4)

        if image then
            local imagePadding = math.max(6, math.floor(boxSize * 0.14))
            local imageSize = boxSize - (imagePadding * 2)
            local imageScale = math.min(imageSize / image:getWidth(), imageSize / image:getHeight())
            local imageWidth = image:getWidth() * imageScale
            local imageHeight = image:getHeight() * imageScale

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                image,
                boxX + ((boxSize - imageWidth) * 0.5),
                rowY + ((boxSize - imageHeight) * 0.5),
                0,
                imageScale,
                imageScale
            )
        end
    end

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
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
    addWorldMapPreviewDeckTarget(state, x, y, jaclWidth, jaclHeight - jaclLabelHeight, {
        definition = jaclDefinition,
        name = jaclDefinition and jaclDefinition.name or "JACL",
    })

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
            drawAgentLoadoutNameLabel(agentDefinition, agentX, agentY, agentWidth, agentHeight)
            addWorldMapPreviewDeckTarget(state, agentX, agentY, agentWidth, agentHeight, {
                definition = agentDefinition,
                name = agentDefinition.name or agentDefinition.id,
            })
        else
            drawEmptyAgentLoadoutCard(agentX, agentY, agentWidth, agentHeight)
        end
    end
end

local function drawHybridEncounterEventNode(mode, x, y, radius)
    if mode == "line" then
        love.graphics.line(x - radius, y, x, y - radius, x + radius, y)
        love.graphics.arc("line", "open", x, y, radius, 0, math.pi, 24)
        return
    end

    love.graphics.polygon(
        "fill",
        x - radius,
        y + 1,
        x,
        y - radius,
        x + radius,
        y + 1
    )
    love.graphics.arc("fill", "pie", x, y, radius, 0, math.pi, 24)
    love.graphics.rectangle("fill", x - radius, y - 1, radius * 2, 2)
end

local function drawCenteredSquare(mode, x, y, radius)
    local size = radius * 2

    love.graphics.rectangle(mode, x - radius, y - radius, size, size)
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
    local nonBossNodeShift = 24
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

    local suppressMapElements = state and state.worldMapRewardModal

    love.graphics.clear(0.045, 0.047, 0.055, 1)

    if not suppressMapElements then
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
            local isHybridNode = nodeIndex == 4
            local isSquareNode = clusterIndex == 2 and nodeIndex == 3
            local isNextDestinationNode = isPlayerMapNode(nextMapPosition, "path", clusterIndex, nodeIndex)
            local nodeColor = { 0.5, 0.5, 0.5, 1 }
            local nodeRadius = isBossNode and bossDiamondRadius or diamondRadius

            if not isBossNode then
                x = x - nonBossNodeShift
            end

            love.graphics.setColor(0, 0, 0, 1)
            if isSquareNode then
                drawCenteredSquare("fill", x, y, eventCircleRadius)
            elseif isHybridNode then
                drawHybridEncounterEventNode("fill", x, y, nodeRadius)
            elseif isEventNode then
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

            if isSquareNode then
                drawCenteredSquare("line", x, y, eventCircleRadius)
            elseif isHybridNode then
                drawHybridEncounterEventNode("line", x, y, nodeRadius)
            elseif isEventNode then
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

            if isSquareNode then
                drawCenteredSquare("fill", x, y, eventCircleRadius * 0.45)
            elseif isHybridNode then
                drawHybridEncounterEventNode("fill", x, y, nodeRadius * 0.42)
            elseif isEventNode then
                love.graphics.circle("fill", x, y, eventCircleRadius * 0.45)
            else
                local nestedDiamondRadius = nodeRadius * (isBossNode and 0.34 or 0.42)

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
        end
    end

    end

    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)

    if state then
        state.worldMapPreviewDeckTargets = {}
        state.worldMapObjectivePreviewTargets = {}
        state.worldMapNodePlayButtonTarget = nil
        state.worldMapNodePlayButtonTargets = {}
    end

    drawWorldAlmsTracker(state)
    drawWorldRolePortraits(state)
    local munitionsTooltip = drawWorldResourceTrackers(state)
    drawWorldSystemsColumn(state)
    drawSelectedRunLoadout(state)
    if not suppressMapElements then
        worldencounterpreviewdraw.drawGroup(
            state,
            state and (state.pinnedWorldMapNode or state.hoveredWorldMapNode or getDefaultFunctionalNode(state)) or nil
        )
        drawWorldMapDeckModal(state and state.worldMapDeckModal or nil)
        drawObjectiveCardPreviewModal(state and state.worldMapObjectivePreviewModal or nil)
    end

    if munitionsTooltip then
        drawMunitionsSystemTooltip(munitionsTooltip.systemDefinition, munitionsTooltip.anchor)
    end

    worldrewardmodal.draw(state)
end

return worldmapdraw
