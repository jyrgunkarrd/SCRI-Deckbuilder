local envassets = require("src.render.envassets")
local handdraw = require("src.render.handdraw")
local jacldraw = require("src.render.jacldraw")

local syntacdraw = {}

local JACL_LABEL_FONT_PATH = "assets/fonts/Furore.otf"
local JACL_SCRATCH_RESOURCE_NAME = "The Scratch"
local MAP_IMAGE_DIRECTORY = "assets/images/map/"
local ICON_IMAGE_DIRECTORY = "assets/images/icons/"
local MUNITIONS_ICON_FILE = "munitions.png"
local TITHES_ICON_FILE = "tithes.png"
local SYNTAC_BOX_LABEL_PADDING = 14
local SYNTAC_BOX_TRACKER_PADDING = 14
local SYNTAC_BOX_TRACKER_GAP = 16
local SYNTAC_BOX_MAX_PIPS = 10
local SYNTAC_BOX_LABEL_TEXT = "SynTac"
local SYNTAC_BOX_PIP_COLOR = { 0.58, 0.9, 0.96 }
local SYNTAC_BOX_GOLD_COLOR = { 1, 0.855, 0.255 }
local SYNTAC_TOOLTIP_HEADER_TEXT = "LEXURGY :"
local SYNTAC_TOOLTIP_BODY_TEXT = "2 Damage or\n2 Block or\n2 Sabotage or\n2 Infuence"
local SYNTAC_TOOLTIP_PADDING = 12
local SYNTAC_TOOLTIP_GAP = 8
local SYNTAC_TOOLTIP_HEADER_BODY_GAP = 8
local SYNTAC_TOOLTIP_HEADER_ICON_GAP = 10
local SYNTAC_TOOLTIP_PIP_GAP = 4
local SYNTAC_TOOLTIP_PIP_SIZE = 12
local SYNTAC_TOOLTIP_TITLE_SIZE = 16
local SYNTAC_TOOLTIP_BODY_SIZE = 13
local SYNTAC_REWARD_TOOLTIP_PADDING = 10
local SYNTAC_REWARD_TOOLTIP_GAP = 8
local SYNTAC_REWARD_TOOLTIP_FONT_SIZE = 13
local SYNTAC_CURSOR_BOX_PADDING = 10
local SYNTAC_CURSOR_BOX_GAP = 8
local SYNTAC_CURSOR_PIP_SIZE = 14
local SYNTAC_CURSOR_PIP_GAP = 5
local SYNTAC_REWARD_BUTTON_GAP = 8
local SYNTAC_REWARD_BUTTON_PADDING = 12
local SYNTAC_REWARD_BUTTON_TEXT_ICON_GAP = 8
local SYNTAC_REWARD_BUTTON_ICON_GAP = 4
local SYNTAC_REWARD_BUTTON_ICON_SIZE_RATIO = 0.58
local SYNTAC_MUNITIONS_TEXT_COLOR = { 0.549, 1, 0.871, 1 }
local SYNTAC_REWARD_BUTTON_DEFINITIONS = {
    { id = "tithes", kind = "world_resource", resourceKey = "tithes", icon = TITHES_ICON_FILE },
    { id = "munitions", kind = "munitions" },
    { id = "method", icon = "method.png", value = "+1", tooltip = "NEXT TURN" },
    { id = "draw", icon = "draw.png", value = "+1", tooltip = "NEXT TURN" },
    { id = "rerolls", icon = "reroll.png", value = "+2", tooltip = "NEXT TURN" },
    { id = "scanner", icon = "scanner.png", tooltip = "MISSION REWARD" },
}
local mapImageCache = {}
local iconImageCache = {}

local function snap(value)
    return math.floor(value + 0.5)
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

local function getSyntacBoxContentMetrics(height)
    local labelFont = envassets.getFont(JACL_LABEL_FONT_PATH, 16)
    local labelWidth = labelFont:getWidth(SYNTAC_BOX_LABEL_TEXT)
    local pipGap = math.max(1, snap(height * 0.06))
    local pipSize = math.max(1, snap(math.max(1, height * 0.34)))
    local totalPipWidth = (SYNTAC_BOX_MAX_PIPS * pipSize) + ((SYNTAC_BOX_MAX_PIPS - 1) * pipGap)
    local contentWidth = SYNTAC_BOX_LABEL_PADDING
        + labelWidth
        + SYNTAC_BOX_TRACKER_GAP
        + totalPipWidth
        + SYNTAC_BOX_TRACKER_PADDING

    return {
        labelFont = labelFont,
        labelWidth = labelWidth,
        pipGap = pipGap,
        pipSize = pipSize,
        totalPipWidth = totalPipWidth,
        contentWidth = snap(contentWidth),
    }
end

function syntacdraw.getSyntacBoxLayout(jaclDefinition)
    local handLayout = handdraw.getPlayerHandLayout()
    local firstHandSlot = handLayout.slots[1]
    local lastHandSlot = handLayout.slots[#handLayout.slots]
    local rerollLayout = jacldraw.getRerollButtonLayout(jaclDefinition)
    local metrics = getSyntacBoxContentMetrics(rerollLayout.height)

    if not firstHandSlot or not lastHandSlot then
        return {
            x = snap((rerollLayout.x + rerollLayout.width) - metrics.contentWidth),
            y = rerollLayout.y,
            width = metrics.contentWidth,
            height = rerollLayout.height,
        }
    end

    local firstVisualBounds = handdraw.getHandSlotVisualBounds(firstHandSlot)
    local lastVisualBounds = handdraw.getHandSlotVisualBounds(lastHandSlot)
    local rightEdge = lastVisualBounds.x + lastVisualBounds.width
    local availableWidth = rightEdge - firstVisualBounds.x
    local width = math.min(availableWidth, metrics.contentWidth)

    return {
        x = snap(rightEdge - width),
        y = rerollLayout.y,
        width = width,
        height = rerollLayout.height,
    }
end

function syntacdraw.isPointInsideSyntacBox(mouseX, mouseY, jaclDefinition)
    local layout = syntacdraw.getSyntacBoxLayout(jaclDefinition)

    return mouseX >= layout.x
        and mouseX <= layout.x + layout.width
        and mouseY >= layout.y
        and mouseY <= layout.y + layout.height
end

local function drawDiamondPip(mode, x, y, size)
    local centerX = x + (size / 2)
    local centerY = y + (size / 2)

    love.graphics.polygon(
        mode,
        centerX, y,
        x + size, centerY,
        centerX, y + size,
        x, centerY
    )
end

local function getSyntacRewardButtonLayouts(jaclDefinition, syntacLayout)
    local layout = syntacLayout or syntacdraw.getSyntacBoxLayout(jaclDefinition)
    local handLayout = handdraw.getPlayerHandLayout()
    local firstHandSlot = handLayout.slots[1]
    local leftEdge = layout.x

    if firstHandSlot then
        leftEdge = handdraw.getHandSlotVisualBounds(firstHandSlot).x
    else
        leftEdge = jacldraw.getRerollButtonLayout(jaclDefinition).x
    end

    local labelFont = envassets.getFont(JACL_LABEL_FONT_PATH, 16)
    local iconSize = math.max(1, snap(layout.height * SYNTAC_REWARD_BUTTON_ICON_SIZE_RATIO))
    local buttonLayouts = {}
    local totalWidth = 0

    for _, definition in ipairs(SYNTAC_REWARD_BUTTON_DEFINITIONS) do
        local buttonWidth

        if definition.kind == "munitions" or definition.kind == "world_resource" then
            buttonWidth = snap(
                (SYNTAC_REWARD_BUTTON_PADDING * 2)
                + iconSize
                + SYNTAC_REWARD_BUTTON_TEXT_ICON_GAP
                + math.max(labelFont:getWidth("00"), labelFont:getWidth("0"))
            )
        else
            buttonWidth = snap(
                (SYNTAC_REWARD_BUTTON_PADDING * 2)
                + (iconSize * 3)
                + (SYNTAC_REWARD_BUTTON_ICON_GAP * 2)
                + SYNTAC_REWARD_BUTTON_TEXT_ICON_GAP
                + labelFont:getWidth(":")
                + SYNTAC_REWARD_BUTTON_TEXT_ICON_GAP
                + (definition.value and (labelFont:getWidth(definition.value) + SYNTAC_REWARD_BUTTON_TEXT_ICON_GAP) or 0)
            )
        end

        buttonLayouts[#buttonLayouts + 1] = {
            id = definition.id,
            kind = definition.kind,
            icon = definition.icon,
            resourceKey = definition.resourceKey,
            value = definition.value,
            tooltip = definition.tooltip,
            width = buttonWidth,
        }
        totalWidth = totalWidth + buttonWidth
    end

    totalWidth = totalWidth + ((#buttonLayouts - 1) * SYNTAC_REWARD_BUTTON_GAP)

    local startX = snap(layout.x - SYNTAC_REWARD_BUTTON_GAP - totalWidth)
    if startX < leftEdge then
        startX = snap(leftEdge)
    end

    local x = startX
    for _, button in ipairs(buttonLayouts) do
        button.x = x
        button.y = layout.y
        button.height = layout.height
        button.iconSize = iconSize
        button.font = labelFont
        x = x + button.width + SYNTAC_REWARD_BUTTON_GAP
    end

    return buttonLayouts
end

function syntacdraw.getSyntacRewardButtonAt(mouseX, mouseY, jaclDefinition)
    for _, button in ipairs(getSyntacRewardButtonLayouts(jaclDefinition)) do
        if mouseX >= button.x
            and mouseX <= button.x + button.width
            and mouseY >= button.y
            and mouseY <= button.y + button.height then
            return button
        end
    end

    return nil
end

function syntacdraw.getSyntacRewardButtonLayout(buttonId, jaclDefinition)
    for _, button in ipairs(getSyntacRewardButtonLayouts(jaclDefinition)) do
        if button.id == buttonId then
            return button
        end
    end

    return nil
end

local function drawButtonImage(image, x, y, size, alpha)
    if image then
        love.graphics.draw(
            image,
            x,
            y,
            0,
            size / image:getWidth(),
            size / image:getHeight()
        )
    else
        love.graphics.rectangle("line", x, y, size, size)
    end
end

local function drawMunitionsButton(button, worldResources, alpha)
    local iconImage = getMapImage(MUNITIONS_ICON_FILE)
    local count = math.max(0, math.floor(tonumber(worldResources and worldResources.munitions) or 0))
    local countText = tostring(count)
    local iconX = snap(button.x + SYNTAC_REWARD_BUTTON_PADDING)
    local iconY = snap(button.y + ((button.height - button.iconSize) / 2))
    local textX = snap(iconX + button.iconSize + SYNTAC_REWARD_BUTTON_TEXT_ICON_GAP)
    local textY = snap(button.y + ((button.height - button.font:getHeight()) / 2))

    love.graphics.setColor(1, 1, 1, alpha)
    drawButtonImage(iconImage, iconX, iconY, button.iconSize, alpha)

    love.graphics.setFont(button.font)
    love.graphics.setColor(
        SYNTAC_MUNITIONS_TEXT_COLOR[1],
        SYNTAC_MUNITIONS_TEXT_COLOR[2],
        SYNTAC_MUNITIONS_TEXT_COLOR[3],
        alpha
    )
    love.graphics.print(countText, textX, textY)
end

local function drawWorldResourceButton(button, worldResources, alpha)
    local iconImage = getMapImage(button.icon)
    local count = math.max(0, math.floor(tonumber(worldResources and worldResources[button.resourceKey]) or 0))
    local countText = tostring(count)
    local iconX = snap(button.x + SYNTAC_REWARD_BUTTON_PADDING)
    local iconY = snap(button.y + ((button.height - button.iconSize) / 2))
    local textX = snap(iconX + button.iconSize + SYNTAC_REWARD_BUTTON_TEXT_ICON_GAP)
    local textY = snap(button.y + ((button.height - button.font:getHeight()) / 2))

    love.graphics.setColor(1, 1, 1, alpha)
    drawButtonImage(iconImage, iconX, iconY, button.iconSize, alpha)

    love.graphics.setFont(button.font)
    love.graphics.setColor(
        SYNTAC_MUNITIONS_TEXT_COLOR[1],
        SYNTAC_MUNITIONS_TEXT_COLOR[2],
        SYNTAC_MUNITIONS_TEXT_COLOR[3],
        alpha
    )
    love.graphics.print(countText, textX, textY)
end

local function drawRewardButtonContents(button, scratchImage, alpha)
    local rewardIcon = getIconImage(button.icon)
    local iconY = snap(button.y + ((button.height - button.iconSize) / 2))
    local scratchX = snap(button.x + SYNTAC_REWARD_BUTTON_PADDING)
    local secondScratchX = snap(scratchX + button.iconSize + SYNTAC_REWARD_BUTTON_ICON_GAP)
    local colonX = snap(secondScratchX + button.iconSize + SYNTAC_REWARD_BUTTON_TEXT_ICON_GAP)
    local colonY = snap(button.y + ((button.height - button.font:getHeight()) / 2))
    local rewardIconX = snap(colonX + button.font:getWidth(":") + SYNTAC_REWARD_BUTTON_TEXT_ICON_GAP)

    love.graphics.setColor(1, 1, 1, alpha)
    drawButtonImage(scratchImage, scratchX, iconY, button.iconSize, alpha)
    drawButtonImage(scratchImage, secondScratchX, iconY, button.iconSize, alpha)

    love.graphics.setFont(button.font)
    love.graphics.setColor(0.93, 0.93, 0.95, alpha)
    love.graphics.print(":", colonX, colonY)

    love.graphics.setColor(1, 1, 1, alpha)
    drawButtonImage(rewardIcon, rewardIconX, iconY, button.iconSize, alpha)

    if button.value then
        love.graphics.setFont(button.font)
        love.graphics.setColor(0.93, 0.93, 0.95, alpha)
        love.graphics.print(button.value, rewardIconX + button.iconSize + SYNTAC_REWARD_BUTTON_TEXT_ICON_GAP, colonY)
    end
end

local function drawSyntacRewardButtons(jaclDefinition, syntacLayout, rewardButtonState, worldResources)
    local buttonLayouts = getSyntacRewardButtonLayouts(jaclDefinition, syntacLayout)
    local scratchImage = envassets.getMethodImage(JACL_SCRATCH_RESOURCE_NAME)
    local buttonStates = rewardButtonState or {}

    for _, button in ipairs(buttonLayouts) do
        local isExhausted = buttonStates[button.id] == true
        local chosenMethodResource = button.id == "method" and buttonStates.methodResource or nil
        local alpha = isExhausted and 0.38 or 1

        love.graphics.setColor(0.12, 0.13, 0.16, 0.92 * alpha)
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
        love.graphics.setColor(0.82, 0.85, 0.89, 0.78 * alpha)
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height)

        if button.kind == "munitions" then
            drawMunitionsButton(button, worldResources, alpha)
        elseif button.kind == "world_resource" then
            drawWorldResourceButton(button, worldResources, alpha)
        else
            drawRewardButtonContents(button, scratchImage, alpha)

            if isExhausted and not chosenMethodResource then
                love.graphics.setColor(0, 0, 0, 0.34)
                love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
                love.graphics.setColor(0.42, 0.44, 0.48, 0.78)
                love.graphics.line(
                    button.x + 4,
                    button.y + button.height - 4,
                    button.x + button.width - 4,
                    button.y + 4
                )
            end
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function syntacdraw.drawSyntacBox(jaclDefinition, syntacCount, rewardButtonState, worldResources)
    local layout = syntacdraw.getSyntacBoxLayout(jaclDefinition)
    local metrics = getSyntacBoxContentMetrics(layout.height)
    local labelFont = metrics.labelFont
    local labelText = SYNTAC_BOX_LABEL_TEXT
    local pipCount = math.min(SYNTAC_BOX_MAX_PIPS, math.max(0, math.floor(tonumber(syntacCount) or 0)))
    local maxCount = SYNTAC_BOX_MAX_PIPS
    local textX = snap(layout.x + SYNTAC_BOX_LABEL_PADDING)
    local textY = snap(layout.y + ((layout.height - labelFont:getHeight()) / 2))

    drawSyntacRewardButtons(jaclDefinition, layout, rewardButtonState, worldResources)

    love.graphics.setColor(0.12, 0.13, 0.16, 0.92)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height)
    if pipCount >= 2 then
        love.graphics.setColor(SYNTAC_BOX_GOLD_COLOR[1], SYNTAC_BOX_GOLD_COLOR[2], SYNTAC_BOX_GOLD_COLOR[3], 0.88)
    else
        love.graphics.setColor(0.82, 0.85, 0.89, 0.78)
    end
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height)

    love.graphics.setFont(labelFont)
    love.graphics.setColor(0.93, 0.93, 0.95, 1)
    love.graphics.print(labelText, textX, textY)

    local trackerX = snap(textX + labelFont:getWidth(labelText) + SYNTAC_BOX_TRACKER_GAP)
    local trackerRight = snap(layout.x + layout.width - SYNTAC_BOX_TRACKER_PADDING)
    local trackerWidth = math.max(1, trackerRight - trackerX)
    local trackerHeight = math.max(1, layout.height - 8)
    local columnCount = maxCount
    local rowCount = math.max(1, math.ceil(maxCount / columnCount))
    local pipGap = metrics.pipGap
    local pipSizeByWidth = (trackerWidth - ((columnCount - 1) * pipGap)) / math.max(1, columnCount)
    local pipSizeByHeight = (trackerHeight - ((rowCount - 1) * pipGap)) / rowCount
    local pipSize = math.max(1, snap(math.min(pipSizeByWidth, pipSizeByHeight, math.max(1, layout.height * 0.34))))
    local totalGridWidth = (columnCount * pipSize) + ((columnCount - 1) * pipGap)
    local totalGridHeight = (rowCount * pipSize) + ((rowCount - 1) * pipGap)
    local startX = snap(trackerRight - totalGridWidth)
    local startY = snap(layout.y + ((layout.height - totalGridHeight) / 2))

    for pipIndex = 0, maxCount - 1 do
        local row = math.floor(pipIndex / columnCount)
        local column = pipIndex % columnCount
        local pipX = startX + (column * (pipSize + pipGap))
        local pipY = startY + (row * (pipSize + pipGap))

        if pipIndex < 2 then
            love.graphics.setColor(SYNTAC_BOX_GOLD_COLOR[1], SYNTAC_BOX_GOLD_COLOR[2], SYNTAC_BOX_GOLD_COLOR[3], 0.5)
        else
            love.graphics.setColor(SYNTAC_BOX_PIP_COLOR[1], SYNTAC_BOX_PIP_COLOR[2], SYNTAC_BOX_PIP_COLOR[3], 0.45)
        end
        drawDiamondPip("line", pipX, pipY, pipSize)
    end

    for pipIndex = 0, pipCount - 1 do
        local row = math.floor(pipIndex / columnCount)
        local column = pipIndex % columnCount
        local pipX = startX + (column * (pipSize + pipGap))
        local pipY = startY + (row * (pipSize + pipGap))

        if pipIndex < 2 then
            love.graphics.setColor(SYNTAC_BOX_GOLD_COLOR[1], SYNTAC_BOX_GOLD_COLOR[2], SYNTAC_BOX_GOLD_COLOR[3], 1)
        else
            love.graphics.setColor(SYNTAC_BOX_PIP_COLOR[1], SYNTAC_BOX_PIP_COLOR[2], SYNTAC_BOX_PIP_COLOR[3], 1)
        end
        drawDiamondPip("fill", pipX, pipY, pipSize)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function syntacdraw.drawSyntacTooltip(jaclDefinition)
    local layout = syntacdraw.getSyntacBoxLayout(jaclDefinition)
    local previousFont = love.graphics.getFont()
    local titleFont = envassets.getFont(JACL_LABEL_FONT_PATH, SYNTAC_TOOLTIP_TITLE_SIZE)
    local bodyFont = envassets.getFont(JACL_LABEL_FONT_PATH, SYNTAC_TOOLTIP_BODY_SIZE)
    local headerTextWidth = titleFont:getWidth(SYNTAC_TOOLTIP_HEADER_TEXT)
    local headerIconWidth = (SYNTAC_TOOLTIP_PIP_SIZE * 2) + SYNTAC_TOOLTIP_PIP_GAP
    local headerWidth = headerTextWidth + SYNTAC_TOOLTIP_HEADER_ICON_GAP + headerIconWidth
    local bodyLines = {}

    for line in SYNTAC_TOOLTIP_BODY_TEXT:gmatch("([^\n]+)") do
        bodyLines[#bodyLines + 1] = line
    end

    local bodyWidth = 0
    for _, line in ipairs(bodyLines) do
        bodyWidth = math.max(bodyWidth, bodyFont:getWidth(line))
    end

    local tooltipWidth = snap((SYNTAC_TOOLTIP_PADDING * 2) + math.max(headerWidth, bodyWidth))
    local tooltipHeight = snap(
        (SYNTAC_TOOLTIP_PADDING * 2)
        + titleFont:getHeight()
        + SYNTAC_TOOLTIP_HEADER_BODY_GAP
        + (#bodyLines * bodyFont:getHeight())
    )
    local windowWidth = love.graphics.getWidth()
    local tooltipX = snap(layout.x + ((layout.width - tooltipWidth) / 2))
    local tooltipY = snap(layout.y - SYNTAC_TOOLTIP_GAP - tooltipHeight)

    tooltipX = snap(math.max(8, math.min(tooltipX, windowWidth - tooltipWidth - 8)))
    tooltipY = snap(math.max(8, tooltipY))

    love.graphics.setColor(0.02, 0.025, 0.03, 0.42)
    love.graphics.rectangle("fill", tooltipX - 6, tooltipY - 6, tooltipWidth + 12, tooltipHeight + 12, 8, 8)
    love.graphics.setColor(0.05, 0.05, 0.06, 0.96)
    love.graphics.rectangle("fill", tooltipX, tooltipY, tooltipWidth, tooltipHeight, 6, 6)
    love.graphics.setColor(SYNTAC_BOX_GOLD_COLOR[1], SYNTAC_BOX_GOLD_COLOR[2], SYNTAC_BOX_GOLD_COLOR[3], 0.88)
    love.graphics.rectangle("line", tooltipX, tooltipY, tooltipWidth, tooltipHeight, 6, 6)

    local headerX = tooltipX + SYNTAC_TOOLTIP_PADDING
    local headerY = tooltipY + SYNTAC_TOOLTIP_PADDING
    love.graphics.setFont(titleFont)
    love.graphics.setColor(0.95, 0.96, 0.98, 1)
    love.graphics.print(SYNTAC_TOOLTIP_HEADER_TEXT, headerX, headerY)

    local pipX = snap(headerX + headerTextWidth + SYNTAC_TOOLTIP_HEADER_ICON_GAP)
    local pipY = snap(headerY + ((titleFont:getHeight() - SYNTAC_TOOLTIP_PIP_SIZE) / 2))
    love.graphics.setColor(SYNTAC_BOX_GOLD_COLOR[1], SYNTAC_BOX_GOLD_COLOR[2], SYNTAC_BOX_GOLD_COLOR[3], 1)
    drawDiamondPip("fill", pipX, pipY, SYNTAC_TOOLTIP_PIP_SIZE)
    drawDiamondPip("fill", pipX + SYNTAC_TOOLTIP_PIP_SIZE + SYNTAC_TOOLTIP_PIP_GAP, pipY, SYNTAC_TOOLTIP_PIP_SIZE)

    love.graphics.setFont(bodyFont)
    love.graphics.setColor(0.82, 0.85, 0.89, 0.98)
    for lineIndex, line in ipairs(bodyLines) do
        love.graphics.print(
            line,
            tooltipX + SYNTAC_TOOLTIP_PADDING,
            headerY + titleFont:getHeight() + SYNTAC_TOOLTIP_HEADER_BODY_GAP + ((lineIndex - 1) * bodyFont:getHeight())
        )
    end

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

local function drawSimpleTooltip(anchor, headerText, bodyText)
    if not anchor or not headerText then
        return false
    end

    local previousFont = love.graphics.getFont()
    local headerFont = envassets.getFont(JACL_LABEL_FONT_PATH, SYNTAC_REWARD_TOOLTIP_FONT_SIZE)
    local bodyFont = envassets.getFont(JACL_LABEL_FONT_PATH, SYNTAC_TOOLTIP_BODY_SIZE)
    local textWidth = math.max(headerFont:getWidth(headerText), bodyText and bodyFont:getWidth(bodyText) or 0)
    local tooltipWidth = snap((SYNTAC_REWARD_TOOLTIP_PADDING * 2) + textWidth)
    local tooltipHeight = snap(
        (SYNTAC_REWARD_TOOLTIP_PADDING * 2)
        + headerFont:getHeight()
        + (bodyText and (SYNTAC_TOOLTIP_HEADER_BODY_GAP + bodyFont:getHeight()) or 0)
    )
    local windowWidth = love.graphics.getWidth()
    local tooltipX = snap(anchor.x + ((anchor.width - tooltipWidth) / 2))
    local tooltipY = snap(anchor.y - SYNTAC_REWARD_TOOLTIP_GAP - tooltipHeight)

    tooltipX = snap(math.max(8, math.min(tooltipX, windowWidth - tooltipWidth - 8)))
    tooltipY = snap(math.max(8, tooltipY))

    love.graphics.setColor(0, 0, 0, 0.58)
    love.graphics.rectangle("fill", tooltipX - 5, tooltipY - 5, tooltipWidth + 10, tooltipHeight + 10, 7, 7)
    love.graphics.setColor(0.075, 0.082, 0.095, 0.96)
    love.graphics.rectangle("fill", tooltipX, tooltipY, tooltipWidth, tooltipHeight, 5, 5)
    love.graphics.setColor(0.82, 0.85, 0.89, 0.84)
    love.graphics.rectangle("line", tooltipX, tooltipY, tooltipWidth, tooltipHeight, 5, 5)

    love.graphics.setFont(headerFont)
    love.graphics.setColor(0.95, 0.96, 0.98, 1)
    love.graphics.print(headerText, tooltipX + SYNTAC_REWARD_TOOLTIP_PADDING, tooltipY + SYNTAC_REWARD_TOOLTIP_PADDING)

    if bodyText then
        love.graphics.setFont(bodyFont)
        love.graphics.setColor(0.82, 0.85, 0.89, 0.98)
        love.graphics.print(
            bodyText,
            tooltipX + SYNTAC_REWARD_TOOLTIP_PADDING,
            tooltipY + SYNTAC_REWARD_TOOLTIP_PADDING + headerFont:getHeight() + SYNTAC_TOOLTIP_HEADER_BODY_GAP
        )
    end

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
    return true
end

function syntacdraw.drawSyntacRewardButtonTooltip(jaclDefinition, mouseX, mouseY, munitionsSystem, titheSystem)
    local button = syntacdraw.getSyntacRewardButtonAt(mouseX, mouseY, jaclDefinition)

    if not button then
        return false
    end

    if button.kind == "munitions" then
        if not munitionsSystem then
            return false
        end

        return drawSimpleTooltip(button, munitionsSystem.name or munitionsSystem.id or "Munitions", munitionsSystem.text)
    end

    if button.id == "tithes" then
        if not titheSystem then
            return false
        end

        return drawSimpleTooltip(button, titheSystem.name or titheSystem.id or "Tithe", titheSystem.text)
    end

    if not button.tooltip then
        return false
    end

    return drawSimpleTooltip(button, button.tooltip)
end

function syntacdraw.drawSyntacCursorIndicator(mouseX, mouseY)
    local previousFont = love.graphics.getFont()
    local pipAreaWidth = (SYNTAC_CURSOR_PIP_SIZE * 2) + SYNTAC_CURSOR_PIP_GAP
    local boxWidth = (SYNTAC_CURSOR_BOX_PADDING * 2) + pipAreaWidth
    local boxHeight = (SYNTAC_CURSOR_BOX_PADDING * 2) + SYNTAC_CURSOR_PIP_SIZE
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local boxX = snap((mouseX or 0) + SYNTAC_CURSOR_BOX_GAP)
    local boxY = snap((mouseY or 0) + SYNTAC_CURSOR_BOX_GAP)

    boxX = snap(math.max(8, math.min(boxX, windowWidth - boxWidth - 8)))
    boxY = snap(math.max(8, math.min(boxY, windowHeight - boxHeight - 8)))

    love.graphics.setColor(0.02, 0.025, 0.03, 0.44)
    love.graphics.rectangle("fill", boxX - 5, boxY - 5, boxWidth + 10, boxHeight + 10, 8, 8)
    love.graphics.setColor(0.05, 0.05, 0.06, 0.94)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 6, 6)
    love.graphics.setColor(SYNTAC_BOX_GOLD_COLOR[1], SYNTAC_BOX_GOLD_COLOR[2], SYNTAC_BOX_GOLD_COLOR[3], 0.9)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 6, 6)

    local pipX = snap(boxX + SYNTAC_CURSOR_BOX_PADDING)
    local pipY = snap(boxY + SYNTAC_CURSOR_BOX_PADDING)
    love.graphics.setColor(SYNTAC_BOX_GOLD_COLOR[1], SYNTAC_BOX_GOLD_COLOR[2], SYNTAC_BOX_GOLD_COLOR[3], 1)
    drawDiamondPip("fill", pipX, pipY, SYNTAC_CURSOR_PIP_SIZE)
    drawDiamondPip("fill", pipX + SYNTAC_CURSOR_PIP_SIZE + SYNTAC_CURSOR_PIP_GAP, pipY, SYNTAC_CURSOR_PIP_SIZE)

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

return syntacdraw
