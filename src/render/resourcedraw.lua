local envassets = require("src.render.envassets")
local envgrid = require("src.render.envgrid")

local resourcedraw = {}

local RESOURCE_COUNTER_FONT_PATH = "assets/fonts/BITSUMIS.TTF"
local ICON_IMAGE_DIRECTORY = "assets/images/icons/"
local METHOD_PURCHASE_ICON_FILE = "method.png"
local RESOURCE_TRACKER_MARGIN_X = 28
local RESOURCE_TRACKER_VERTICAL_PADDING = 16
local RESOURCE_TRACKER_COLUMN_WIDTH = 128
local RESOURCE_TRACKER_COLUMN_GAP = 22
local RESOURCE_TRACKER_ICON_SIZE = 68
local RESOURCE_TRACKER_COUNTER_GAP = 6
local RESOURCE_TRACKER_ROW_STEP = 108
local RESOURCE_TRACKER_COUNTER_WIDTH = 72
local RESOURCE_TRACKER_COUNTER_FONT_SIZE = 26
local SYSTEM_BADGE_COUNT = 5
local SYSTEM_BADGE_OUTLINE_COLOR = { 0.549, 1, 0.871, 1 }
local SYSTEM_BADGE_INNER_FILL_COLOR = { 0.075, 0.082, 0.095, 0.92 }
local METHOD_ASSOCIATION_ROW_INDEX = 1
local METHOD_ASSOCIATION_MIN_ICON_SIZE = 28
local METHOD_ASSOCIATION_ICON_SCALE = 1.25
local RESOURCE_EXCHANGE_MODAL_MARGIN = 24
local RESOURCE_EXCHANGE_MODAL_PADDING = 28
local RESOURCE_TRANSFER_RADIUS = 7
local RESOURCE_TRANSFER_TRAIL_STEPS = 10
local RESOURCE_TRANSFER_TRAIL_SPACING = 0.055
local RESOURCE_TRACKER_COLUMNS = {
    {
        resources = {
            "The Beast",
            "The Blade",
            "The Crusade",
            "The Gate",
            "The Inferno",
        },
    },
    {
        resources = {
            "The Nightmare",
            "The Rampage",
            "The Shadow",
            "The Stitch",
            "The Trigger",
        },
    },
}
local iconImageCache = {}

local function lerp(a, b, t)
    return a + ((b - a) * t)
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

local function getResourceGridMetrics(maxWidth, maxHeight)
    local counterFont = envassets.getFont(RESOURCE_COUNTER_FONT_PATH, RESOURCE_TRACKER_COUNTER_FONT_SIZE)
    local baseTrackerHeight = RESOURCE_TRACKER_ICON_SIZE + RESOURCE_TRACKER_COUNTER_GAP + counterFont:getHeight() + ((#RESOURCE_TRACKER_COLUMNS[1].resources - 1) * RESOURCE_TRACKER_ROW_STEP)
    local baseTrackerWidth = (#RESOURCE_TRACKER_COLUMNS * RESOURCE_TRACKER_COLUMN_WIDTH) + ((#RESOURCE_TRACKER_COLUMNS - 1) * RESOURCE_TRACKER_COLUMN_GAP)
    local widthLimit = maxWidth or baseTrackerWidth
    local heightLimit = maxHeight or baseTrackerHeight
    local scale = math.min(1, widthLimit / baseTrackerWidth, heightLimit / baseTrackerHeight)
    local columnWidth = RESOURCE_TRACKER_COLUMN_WIDTH * scale
    local columnGap = RESOURCE_TRACKER_COLUMN_GAP * scale
    local iconSize = RESOURCE_TRACKER_ICON_SIZE * scale
    local counterGap = RESOURCE_TRACKER_COUNTER_GAP * scale
    local rowStep = RESOURCE_TRACKER_ROW_STEP * scale
    local counterWidth = RESOURCE_TRACKER_COUNTER_WIDTH * scale
    local scaledCounterFont = envassets.getFont(RESOURCE_COUNTER_FONT_PATH, math.max(10, math.floor(RESOURCE_TRACKER_COUNTER_FONT_SIZE * scale)))
    local trackerHeight = iconSize + counterGap + scaledCounterFont:getHeight() + ((#RESOURCE_TRACKER_COLUMNS[1].resources - 1) * rowStep)
    local trackerWidth = (#RESOURCE_TRACKER_COLUMNS * columnWidth) + ((#RESOURCE_TRACKER_COLUMNS - 1) * columnGap)

    return {
        counterFont = scaledCounterFont,
        width = trackerWidth,
        height = trackerHeight,
        columnWidth = columnWidth,
        columnGap = columnGap,
        iconSize = iconSize,
        counterGap = counterGap,
        rowStep = rowStep,
        counterWidth = counterWidth,
    }
end

local function buildResourceGridLayout(startX, startY, metrics)
    local resourceCenters = {}
    local resourceHitBoxes = {}

    for columnIndex, column in ipairs(RESOURCE_TRACKER_COLUMNS) do
        local columnOffset = metrics.columnOffsets and metrics.columnOffsets[columnIndex] or 0
        local columnX = startX + ((columnIndex - 1) * (metrics.columnWidth + metrics.columnGap)) + columnOffset

        for rowIndex, resourceName in ipairs(column.resources) do
            if resourceName then
                local itemY = startY + ((rowIndex - 1) * metrics.rowStep)
                local itemHeight = math.max(metrics.rowStep, metrics.iconSize + metrics.counterGap + metrics.counterFont:getHeight())

                resourceCenters[resourceName] = {
                    x = columnX + (metrics.columnWidth / 2),
                    y = itemY + (metrics.iconSize / 2),
                }
                resourceHitBoxes[resourceName] = {
                    x = columnX,
                    y = itemY,
                    width = metrics.columnWidth,
                    height = itemHeight,
                }
            end
        end
    end

    return {
        counterFont = metrics.counterFont,
        startX = startX,
        startY = startY,
        width = metrics.width,
        height = metrics.height,
        columnWidth = metrics.columnWidth,
        columnGap = metrics.columnGap,
        iconSize = metrics.iconSize,
        counterGap = metrics.counterGap,
        rowStep = metrics.rowStep,
        counterWidth = metrics.counterWidth,
        columnOffsets = metrics.columnOffsets,
        resourceCenters = resourceCenters,
        resourceHitBoxes = resourceHitBoxes,
    }
end

local function drawResourceGrid(layout, resourceCounts)
    local previousFont = love.graphics.getFont()
    local resourceValues = resourceCounts or {}

    for columnIndex, column in ipairs(RESOURCE_TRACKER_COLUMNS) do
        local columnOffset = layout.columnOffsets and layout.columnOffsets[columnIndex] or 0
        local columnX = layout.startX + ((columnIndex - 1) * (layout.columnWidth + layout.columnGap)) + columnOffset

        for rowIndex, resourceName in ipairs(column.resources) do
            if resourceName then
                local itemY = layout.startY + ((rowIndex - 1) * layout.rowStep)
                local counterY = itemY + layout.iconSize + layout.counterGap
                local methodImage = envassets.getMethodImage(resourceName)

                if methodImage then
                    local imageScale = math.min(layout.iconSize / methodImage:getWidth(), layout.iconSize / methodImage:getHeight())
                    local imageWidth = methodImage:getWidth() * imageScale
                    local imageHeight = methodImage:getHeight() * imageScale
                    local imageX = columnX + ((layout.columnWidth - imageWidth) / 2)
                    local imageY = itemY + ((layout.iconSize - imageHeight) / 2)

                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(methodImage, imageX, imageY, 0, imageScale, imageScale)
                end

                love.graphics.setColor(0.95, 0.96, 0.98, 1)
                love.graphics.setFont(layout.counterFont)
                love.graphics.printf(
                    tostring(resourceValues[resourceName] or 0),
                    columnX + ((layout.columnWidth - layout.counterWidth) / 2),
                    counterY,
                    layout.counterWidth,
                    "center"
                )
            end
        end
    end

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

local function drawMethodAssociationIcon(layout)
    local methodIcon = getIconImage(METHOD_PURCHASE_ICON_FILE)

    if not layout then
        return
    end

    local previousFont = love.graphics.getFont()
    local previousLineWidth = love.graphics.getLineWidth()
    local windowWidth = love.graphics.getWidth()
    local secondColumnOffset = layout.columnOffsets and layout.columnOffsets[2] or 0
    local secondColumnX = layout.startX + layout.columnWidth + layout.columnGap + secondColumnOffset
    local visibleColumnWidth = math.max(layout.iconSize, layout.counterWidth)
    local secondColumnRight = secondColumnX + ((layout.columnWidth + visibleColumnWidth) / 2)
    local availableWidth = math.max(
        METHOD_ASSOCIATION_MIN_ICON_SIZE,
        windowWidth - RESOURCE_TRACKER_MARGIN_X - secondColumnRight - layout.columnGap
    )
    local itemY = layout.startY + ((METHOD_ASSOCIATION_ROW_INDEX - 1) * layout.rowStep)
    local boxSize = math.min(layout.iconSize * METHOD_ASSOCIATION_ICON_SCALE, availableWidth)
    local boxX = secondColumnRight + layout.columnGap
    local boxY = itemY

    if methodIcon then
        local imagePadding = math.max(5, math.floor(boxSize * 0.12))
        local imageSize = boxSize - (imagePadding * 2)
        local imageScale = math.min(imageSize / methodIcon:getWidth(), imageSize / methodIcon:getHeight())
        local imageWidth = methodIcon:getWidth() * imageScale
        local imageHeight = methodIcon:getHeight() * imageScale

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            methodIcon,
            boxX + ((boxSize - imageWidth) * 0.5),
            boxY + ((boxSize - imageHeight) * 0.5),
            0,
            imageScale,
            imageScale
        )
    end

    love.graphics.setLineWidth(previousLineWidth)
    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

local function isSystemBadgeBurned(systemStates, systemIndex)
    local systemState = systemStates and systemStates[systemIndex] or nil

    return systemState == true or (type(systemState) == "table" and systemState.burned == true)
end

local function drawSystemBadgeColumn(layout, systemStates)
    if not layout then
        return
    end

    local boxSize = layout.iconSize
    local boxX = layout.startX - layout.columnGap - boxSize
    local freshImage = envassets.getMapImage("systems.png") or envassets.getMapImage("system.png")
    local burnedImage = envassets.getMapImage("systemsburn.png") or freshImage

    for systemIndex = 1, SYSTEM_BADGE_COUNT do
        local rowY = layout.startY + ((systemIndex - 1) * layout.rowStep)
        local cornerRadius = math.max(3, math.floor(boxSize * 0.075))
        local inset = math.max(3, math.floor(boxSize * 0.075))
        local isBurned = isSystemBadgeBurned(systemStates, systemIndex)
        local badgeAlpha = isBurned and 0.46 or 1
        local image = isBurned and burnedImage or freshImage

        love.graphics.setColor(0.025, 0.028, 0.035, 0.9 * badgeAlpha)
        love.graphics.rectangle("fill", boxX, rowY, boxSize, boxSize, cornerRadius, cornerRadius)
        love.graphics.setColor(
            SYSTEM_BADGE_OUTLINE_COLOR[1],
            SYSTEM_BADGE_OUTLINE_COLOR[2],
            SYSTEM_BADGE_OUTLINE_COLOR[3],
            SYSTEM_BADGE_OUTLINE_COLOR[4] * badgeAlpha
        )
        love.graphics.rectangle("line", boxX, rowY, boxSize, boxSize, cornerRadius, cornerRadius)
        love.graphics.setColor(
            SYSTEM_BADGE_INNER_FILL_COLOR[1],
            SYSTEM_BADGE_INNER_FILL_COLOR[2],
            SYSTEM_BADGE_INNER_FILL_COLOR[3],
            SYSTEM_BADGE_INNER_FILL_COLOR[4] * badgeAlpha
        )
        love.graphics.rectangle(
            "fill",
            boxX + inset,
            rowY + inset,
            boxSize - (inset * 2),
            boxSize - (inset * 2),
            math.max(2, cornerRadius - 1),
            math.max(2, cornerRadius - 1)
        )

        if image then
            local imagePadding = math.max(6, math.floor(boxSize * 0.14))
            local imageSize = boxSize - (imagePadding * 2)
            local imageScale = math.min(imageSize / image:getWidth(), imageSize / image:getHeight())
            local imageWidth = image:getWidth() * imageScale
            local imageHeight = image:getHeight() * imageScale

            love.graphics.setColor(1, 1, 1, isBurned and 0.48 or 1)
            love.graphics.draw(
                image,
                boxX + ((boxSize - imageWidth) * 0.5),
                rowY + ((boxSize - imageHeight) * 0.5),
                0,
                imageScale,
                imageScale
            )
        end

        if isBurned then
            local lineInset = math.max(4, math.floor(boxSize * 0.11))

            love.graphics.setColor(0, 0, 0, 0.42)
            love.graphics.rectangle("fill", boxX, rowY, boxSize, boxSize, cornerRadius, cornerRadius)
            love.graphics.setColor(0.42, 0.44, 0.48, 0.86)
            love.graphics.line(
                boxX + lineInset,
                rowY + boxSize - lineInset,
                boxX + boxSize - lineInset,
                rowY + lineInset
            )
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

local function buildResourceTrackerLayout()
    local windowWidth = love.graphics.getWidth()
    local gridLayout = envgrid.getGridLayout()
    local gridTopY = gridLayout.rows[1] and gridLayout.rows[1].y or 0
    local availableHeight = math.max(1, gridTopY - (RESOURCE_TRACKER_VERTICAL_PADDING * 2))
    local metrics = getResourceGridMetrics(nil, availableHeight)
    local startX = windowWidth - RESOURCE_TRACKER_MARGIN_X - metrics.width
    local startY = math.max(0, (gridTopY - metrics.height) / 2)
    local topRow = gridLayout.rows[1]
    local rightmostCell = topRow and topRow.cells and topRow.cells[#topRow.cells] or nil

    if rightmostCell then
        local secondColumnX = startX + metrics.columnWidth + metrics.columnGap
        local visibleColumnWidth = math.max(metrics.iconSize, metrics.counterWidth)
        local currentRightEdge = secondColumnX + ((metrics.columnWidth + visibleColumnWidth) / 2)
        local targetRightEdge = rightmostCell.x + rightmostCell.width
        local rightColumnOffset = math.min(0, targetRightEdge - currentRightEdge)

        if rightColumnOffset < 0 then
            metrics.columnOffsets = {
                [2] = rightColumnOffset,
            }
        end
    end

    return buildResourceGridLayout(startX, startY, metrics)
end

function resourcedraw.getResourceTrackerLayout()
    return buildResourceTrackerLayout()
end

function resourcedraw.getSystemBadgeColumnRect()
    local layout = buildResourceTrackerLayout()
    local boxSize = layout.iconSize
    local boxX = layout.startX - layout.columnGap - boxSize
    local columnHeight = boxSize + ((SYSTEM_BADGE_COUNT - 1) * layout.rowStep)

    return {
        x = boxX,
        y = layout.startY,
        width = boxSize,
        height = columnHeight,
    }
end

function resourcedraw.drawResourceTracker(resourceCounts, systemStates)
    local layout = buildResourceTrackerLayout()
    drawSystemBadgeColumn(layout, systemStates)
    drawResourceGrid(layout, resourceCounts)
    drawMethodAssociationIcon(layout)
end

function resourcedraw.getResourceExchangeModalLayout()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local maxGridWidth = math.max(1, windowWidth - ((RESOURCE_EXCHANGE_MODAL_MARGIN + RESOURCE_EXCHANGE_MODAL_PADDING) * 2))
    local maxGridHeight = math.max(1, windowHeight - ((RESOURCE_EXCHANGE_MODAL_MARGIN + RESOURCE_EXCHANGE_MODAL_PADDING) * 2))
    local metrics = getResourceGridMetrics(maxGridWidth, maxGridHeight)
    local modalWidth = metrics.width + (RESOURCE_EXCHANGE_MODAL_PADDING * 2)
    local modalHeight = metrics.height + (RESOURCE_EXCHANGE_MODAL_PADDING * 2)
    local modalX = (windowWidth - modalWidth) / 2
    local modalY = (windowHeight - modalHeight) / 2
    local gridLayout = buildResourceGridLayout(
        modalX + RESOURCE_EXCHANGE_MODAL_PADDING,
        modalY + RESOURCE_EXCHANGE_MODAL_PADDING,
        metrics
    )

    return {
        x = modalX,
        y = modalY,
        width = modalWidth,
        height = modalHeight,
        grid = gridLayout,
    }
end

function resourcedraw.drawResourceExchangeModal(resourceCounts)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local layout = resourcedraw.getResourceExchangeModalLayout()

    love.graphics.setColor(0.01, 0.01, 0.02, 0.72)
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    love.graphics.setColor(0.06, 0.07, 0.09, 0.96)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height, 10, 10)
    love.graphics.setColor(0.82, 0.85, 0.89, 0.78)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height, 10, 10)
    drawResourceGrid(layout.grid, resourceCounts)
    love.graphics.setColor(1, 1, 1, 1)
end

function resourcedraw.getSyntacMethodModalLayout()
    return resourcedraw.getResourceExchangeModalLayout()
end

function resourcedraw.drawSyntacMethodModal()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local layout = resourcedraw.getSyntacMethodModalLayout()

    love.graphics.setColor(0.01, 0.01, 0.02, 0.72)
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    love.graphics.setColor(0.06, 0.07, 0.09, 0.96)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height, 10, 10)
    love.graphics.setColor(0.82, 0.85, 0.89, 0.78)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height, 10, 10)
    drawResourceGrid(layout.grid, {})
    love.graphics.setColor(1, 1, 1, 1)
end

function resourcedraw.getSyntacMethodModalResourceAt(mouseX, mouseY)
    local layout = resourcedraw.getSyntacMethodModalLayout()

    for resourceName, hitBox in pairs(layout.grid.resourceHitBoxes or {}) do
        if mouseX >= hitBox.x
            and mouseX <= hitBox.x + hitBox.width
            and mouseY >= hitBox.y
            and mouseY <= hitBox.y + hitBox.height then
            return resourceName
        end
    end

    return nil
end

function resourcedraw.getResourceExchangeModalResourceAt(mouseX, mouseY)
    local layout = resourcedraw.getResourceExchangeModalLayout()

    for resourceName, hitBox in pairs(layout.grid.resourceHitBoxes or {}) do
        if mouseX >= hitBox.x
            and mouseX <= hitBox.x + hitBox.width
            and mouseY >= hitBox.y
            and mouseY <= hitBox.y + hitBox.height then
            return resourceName
        end
    end

    return nil
end

function resourcedraw.drawResourceTransfers(transfers)
    for _, transfer in ipairs(transfers or {}) do
        local progress = math.min(1, transfer.elapsed / transfer.duration)
        local baseRed = transfer.color[1]
        local baseGreen = transfer.color[2]
        local baseBlue = transfer.color[3]
        local baseAlpha = transfer.color[4]

        for trailIndex = RESOURCE_TRANSFER_TRAIL_STEPS, 1, -1 do
            local trailProgress = math.max(0, progress - (trailIndex * RESOURCE_TRANSFER_TRAIL_SPACING))
            local trailX = lerp(transfer.sourceX, transfer.targetX, trailProgress)
            local trailY = lerp(transfer.sourceY, transfer.targetY, trailProgress)
            local alphaScale = 0.1 + (((RESOURCE_TRANSFER_TRAIL_STEPS - trailIndex) / RESOURCE_TRANSFER_TRAIL_STEPS) * 0.36)
            local radiusScale = 0.28 + (((RESOURCE_TRANSFER_TRAIL_STEPS - trailIndex) / RESOURCE_TRANSFER_TRAIL_STEPS) * 0.58)

            love.graphics.setColor(baseRed, baseGreen, baseBlue, baseAlpha * alphaScale)
            love.graphics.circle("fill", trailX, trailY, RESOURCE_TRANSFER_RADIUS * radiusScale)
        end

        local x = lerp(transfer.sourceX, transfer.targetX, progress)
        local y = lerp(transfer.sourceY, transfer.targetY, progress)

        love.graphics.setColor(baseRed, baseGreen, baseBlue, baseAlpha)
        love.graphics.circle("fill", x, y, RESOURCE_TRANSFER_RADIUS)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return resourcedraw
