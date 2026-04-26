local envdraw = {}
local envrules = require("src.system.envrules")
local carddraw = require("src.render.carddraw")
local buildTopStripLayout

local GRID_COLUMNS = 9
local CELL_WIDTH = 180
local CELL_HEIGHT = 180
local CELL_GAP = 20
local IMAGE_DIRECTORY = "assets/images/env/"
local JACL_IMAGE_DIRECTORY = "assets/images/jacl/"
local CHAMP_IMAGE_DIRECTORY = "assets/images/champ/"
local OBJECTIVE_IMAGE_DIRECTORY = "assets/images/objectives/"
local WARZONE_IMAGE_DIRECTORY = "assets/images/warzone/"
local METHOD_IMAGE_DIRECTORY = "assets/images/method/"
local JACL_LABEL_FONT_PATH = "assets/fonts/Furore.otf"
local CHAMP_LABEL_FONT_PATH = "assets/fonts/Furore.otf"
local PHASE_TRACKER_FONT_PATH = "assets/fonts/Furore.otf"
local RESOURCE_COUNTER_FONT_PATH = "assets/fonts/BITSUMIS.TTF"
local CARD_FLAVOR_FONT_PATH = "assets/fonts/DejaVuSans-Oblique.ttf"
local PHASE_TRACKER_X = 24
local PHASE_TRACKER_WIDTH = 180
local PHASE_TRACKER_STEP_HEIGHT = 54
local PHASE_TRACKER_MARKER_SIZE = 18
local PHASE_TRACKER_ACTIVE_MARKER_SIZE = 8
local PHASE_TRACKER_LINE_WIDTH = 3
local PHASE_TRACKER_PULSE_SPEED = 3.5
local PHASE_TRACKER_PULSE_MIN = 0.75
local PHASE_TRACKER_PULSE_MAX = 1
local PHASE_TRACKER_PHASES = {
    "Start",
    "House",
    "Prelude",
    "War",
    "End",
}
local HAND_SLOT_FONT_PATH = "assets/fonts/BITSUMIS.TTF"
local HAND_SLOT_WIDTH = 220
local HAND_SLOT_HEIGHT = 264
local HAND_SLOT_STEP = 150
local HAND_SLOT_VISUAL_WIDTH = HAND_SLOT_WIDTH * 0.5
local HAND_SLOT_VISUAL_OFFSET_X = 50
local HAND_MARGIN_X = 24
local HAND_MARGIN_Y = 24
local PANEL_MARGIN = 24
local PANEL_LABEL_HEIGHT = 44
local PANEL_LABEL_PADDING = 14
local REROLL_BUTTON_HEIGHT = 38
local REROLL_BUTTON_GAP = 12
local SYNTAC_BOX_LABEL_PADDING = 14
local SYNTAC_BOX_TRACKER_PADDING = 14
local SYNTAC_BOX_TRACKER_GAP = 16
local SYNTAC_BOX_MAX_PIPS = 10
local RESOURCE_TRACKER_MARGIN_X = 28
local RESOURCE_TRACKER_VERTICAL_PADDING = 16
local RESOURCE_TRACKER_COLUMN_WIDTH = 128
local RESOURCE_TRACKER_COLUMN_GAP = 22
local RESOURCE_TRACKER_ICON_SIZE = 68
local RESOURCE_TRACKER_COUNTER_GAP = 6
local RESOURCE_TRACKER_ROW_STEP = 108
local RESOURCE_TRACKER_COUNTER_WIDTH = 72
local RESOURCE_TRACKER_COUNTER_FONT_SIZE = 26
local RESOURCE_EXCHANGE_MODAL_MARGIN = 24
local RESOURCE_EXCHANGE_MODAL_PADDING = 28
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
local JACL_SCRATCH_RESOURCE_NAME = "The Scratch"
local JACL_SCRATCH_BADGE_SIZE = 42
local JACL_SCRATCH_FOOTER_HEIGHT = 22
local JACL_SCRATCH_MARGIN = 10
local JACL_METHOD_BADGE_SIZE = 42
local JACL_METHOD_BADGE_MARGIN = 10
local RESOURCE_TRANSFER_RADIUS = 7
local RESOURCE_TRANSFER_TRAIL_STEPS = 10
local RESOURCE_TRANSFER_TRAIL_SPACING = 0.055
local JACL_SPECIAL_CURSOR_ALPHA = 0.72
local JACL_DECK_MODAL_MARGIN = 24
local JACL_DECK_MODAL_PADDING = 22
local JACL_DECK_MODAL_SECTION_GAP = 18
local JACL_DECK_MODAL_HEADER_HEIGHT = 26
local JACL_DECK_MODAL_CARD_GAP = 14
local JACL_DECK_MODAL_CARD_WIDTH = 112
local JACL_DECK_MODAL_MAX_HEIGHT_RATIO = 0.82
local SPECIAL_TOOLTIP_WIDTH = 300
local SPECIAL_TOOLTIP_PADDING = 12
local SPECIAL_TOOLTIP_TITLE_SIZE = 16
local SPECIAL_TOOLTIP_BODY_SIZE = 12
local SPECIAL_TOOLTIP_OFFSET_X = 18
local SPECIAL_TOOLTIP_OFFSET_Y = 18
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
local SETUP_MODAL_MARGIN = 24
local SETUP_MODAL_PADDING = 18
local SETUP_MODAL_SLOT_GAP = 20
local SETUP_MODAL_MAX_HEIGHT_RATIO = 0.48
local CHAMP_DISPLAY_WIDTH = 505
local CHAMP_DISPLAY_HEIGHT = 265
local CHAMP_DISPLAY_TOP_MARGIN = 24
local CHAMP_LABEL_HEIGHT = 44
local CHAMP_LABEL_PADDING = 14
local CHAMP_ACCENT_COLOR = { 1, 0.255, 0.255 }
local CHAMP_HEALTH_COLOR = { 1, 0.855, 0.255 }
local TROOP_HEALTH_COLOR = { 0, 1, 0.839 }
local OBJECTIVE_ACCENT_COLOR = { 1, 0.486, 0.694 }
local OBJECTIVE_PLAN_COLOR = { 1, 0.486, 0.694 }
local PREVIEW_PIP_COLOR = { 1, 0.298, 0.298 }
local INTEL_ACCENT_COLOR = { 0, 1, 0.98 }
local INTEL_PLAN_COLOR = { 1, 0.486, 0.694 }
local WARZONE_ACCENT_COLOR = { 1, 0.608, 0.145 }
local POI_ACCENT_COLOR = { 0.525, 0.831, 0.973 }
local CHAMP_LABEL_FONT_SIZE = 18
local CHAMP_SLOT_GAP = 22
local CHAMP_HEALTH_PIP_COLUMNS = 20
local TOP_SLOT_PIP_MAX_SIZE_RATIO = 0.18
local TOP_SLOT_TEXTBOX_FONT_PATH = "assets/fonts/Furore.otf"
local TOP_SLOT_TEXTBOX_FONT_SIZE = 12
local TOP_SLOT_FLAVOR_FONT_SIZE = 12
local TOP_SLOT_TEXTBOX_PADDING = 14
local TOP_SLOT_EMPHASIS_BADGE_SIZE_RATIO = 0.1425

local imageCache = {}
local fontCache = {}
local getChampImage
local getObjectiveImage
local getWarzoneImage
local getFont
local getMethodImage

local function lerp(a, b, t)
    return a + ((b - a) * t)
end

local function snap(value)
    return math.floor(value + 0.5)
end

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function getResourceGridMetrics(maxWidth, maxHeight)
    local counterFont = getFont(RESOURCE_COUNTER_FONT_PATH, RESOURCE_TRACKER_COUNTER_FONT_SIZE)
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
    local scaledCounterFont = getFont(RESOURCE_COUNTER_FONT_PATH, math.max(10, math.floor(RESOURCE_TRACKER_COUNTER_FONT_SIZE * scale)))
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
        local columnX = startX + ((columnIndex - 1) * (metrics.columnWidth + metrics.columnGap))

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
        resourceCenters = resourceCenters,
        resourceHitBoxes = resourceHitBoxes,
    }
end

local function drawResourceGrid(layout, resourceCounts)
    local previousFont = love.graphics.getFont()
    local resourceValues = resourceCounts or {}

    for columnIndex, column in ipairs(RESOURCE_TRACKER_COLUMNS) do
        local columnX = layout.startX + ((columnIndex - 1) * (layout.columnWidth + layout.columnGap))

        for rowIndex, resourceName in ipairs(column.resources) do
            if resourceName then
                local itemY = layout.startY + ((rowIndex - 1) * layout.rowStep)
                local counterY = itemY + layout.iconSize + layout.counterGap
                local methodImage = getMethodImage(resourceName)

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

function getFont(path, size)
    local cacheKey = path .. ":" .. size

    if fontCache[cacheKey] ~= nil then
        return fontCache[cacheKey]
    end

    fontCache[cacheKey] = love.graphics.newFont(path, size)
    return fontCache[cacheKey]
end

local function getFittedFontForBox(path, text, targetSize, maxWidth, maxHeight, minSize)
    local fontSize = math.max(minSize or 10, targetSize)
    local fittedFont = getFont(path, fontSize)

    while fontSize > (minSize or 10) do
        local _, wrappedLines = fittedFont:getWrap(text, maxWidth)
        local wrappedHeight = #wrappedLines * fittedFont:getHeight()

        if wrappedHeight <= maxHeight then
            return fittedFont, wrappedLines
        end

        fontSize = fontSize - 1
        fittedFont = getFont(path, fontSize)
    end

    local _, wrappedLines = fittedFont:getWrap(text, maxWidth)
    return fittedFont, wrappedLines
end

local function getTopSlotImageRect(slotX, slotY, slotWidth, slotHeight, labelHeight, image)
    local imageX = slotX
    local imageY = slotY + labelHeight
    local imageWidth = slotWidth
    local imageHeight = slotHeight

    if image then
        local drawScale = math.min(slotWidth / image:getWidth(), slotHeight / image:getHeight())
        imageWidth = image:getWidth() * drawScale
        imageHeight = image:getHeight() * drawScale
        imageX = slotX + ((slotWidth - imageWidth) / 2)
        imageY = slotY + labelHeight + ((slotHeight - imageHeight) / 2)
    end

    return {
        x = imageX,
        y = imageY,
        width = imageWidth,
        height = imageHeight,
    }
end

local function getTopSlotPipLayout(slotX, slotY, slotWidth, labelHeight, labelPadding, rightPipCount, maxPipCount)
    if not ((rightPipCount and rightPipCount > 0) or (maxPipCount and maxPipCount > 0)) then
        return nil
    end

    local pipCount = math.max(0, tonumber(rightPipCount) or 0)
    local maxCount = math.max(pipCount, math.max(0, tonumber(maxPipCount) or 0))
    local columnCount = math.min(CHAMP_HEALTH_PIP_COLUMNS, math.max(1, maxCount))
    local rowCount = math.max(1, math.ceil(math.max(1, maxCount) / CHAMP_HEALTH_PIP_COLUMNS))
    local pipGap = math.max(1, snap(labelHeight * 0.06))
    local rightPipAreaWidth = math.min(slotWidth * 0.48, math.max(labelHeight * 2.4, slotWidth * 0.34))
    local availableWidth = math.max(1, rightPipAreaWidth)
    local availableHeight = math.max(1, labelHeight - 4)
    local pipSizeByWidth = (availableWidth - ((columnCount - 1) * pipGap)) / math.max(1, columnCount)
    local pipSizeByHeight = (availableHeight - ((rowCount - 1) * pipGap)) / rowCount
    local maxDefaultPipSize = math.max(1, snap(labelHeight * TOP_SLOT_PIP_MAX_SIZE_RATIO))
    local pipSize = math.max(1, snap(math.min(pipSizeByWidth, pipSizeByHeight, maxDefaultPipSize)))
    local totalGridWidth = (columnCount * pipSize) + ((columnCount - 1) * pipGap)
    local totalGridHeight = (rowCount * pipSize) + ((rowCount - 1) * pipGap)
    local startX = snap(slotX + slotWidth - labelPadding - rightPipAreaWidth + ((availableWidth - totalGridWidth) / 2))
    local startY = snap(slotY + ((labelHeight - totalGridHeight) / 2))

    return {
        pipCount = pipCount,
        maxCount = maxCount,
        pipSize = pipSize,
        pipGap = pipGap,
        startX = startX,
        startY = startY,
    }
end

local function drawObjectiveEscalationPipEffect(slot, effect)
    if not slot or not effect then
        return
    end

    local pipLayout = getTopSlotPipLayout(slot.x, slot.y, slot.width, slot.labelHeight, slot.labelPadding, slot.rightPipCount, slot.maxPipCount)

    if not pipLayout or pipLayout.maxCount <= 0 then
        return
    end

    local sequenceProgress = clamp((effect.progress or 0) / math.max(0.001, effect.swapProgress or 1), 0, 1)
    local flashPosition = sequenceProgress * pipLayout.maxCount
    local strongestFlash = 0

    for pipIndex = 0, pipLayout.maxCount - 1 do
        local phase = flashPosition - pipIndex

        if phase >= 0 and phase <= 1.15 then
            local flashAlpha = 1 - clamp(math.abs(phase - 0.2) / 0.95, 0, 1)
            local row = math.floor(pipIndex / CHAMP_HEALTH_PIP_COLUMNS)
            local column = pipIndex % CHAMP_HEALTH_PIP_COLUMNS
            local pipX = pipLayout.startX + (column * (pipLayout.pipSize + pipLayout.pipGap))
            local pipY = pipLayout.startY + (row * (pipLayout.pipSize + pipLayout.pipGap))
            strongestFlash = math.max(strongestFlash, flashAlpha)

            love.graphics.setColor(1, 0.95, 0.98, 0.18 * flashAlpha)
            love.graphics.rectangle("fill", pipX - 2, pipY - 2, pipLayout.pipSize + 4, pipLayout.pipSize + 4)
            love.graphics.setColor(1, 0.62, 0.82, 0.95 * flashAlpha)
            love.graphics.rectangle("fill", pipX, pipY, pipLayout.pipSize, pipLayout.pipSize)
            love.graphics.setColor(1, 0.93, 0.98, flashAlpha)
            love.graphics.rectangle("line", pipX - 1, pipY - 1, pipLayout.pipSize + 2, pipLayout.pipSize + 2)
        end
    end

    if strongestFlash > 0 then
        local bodyHeight = slot.labelHeight + slot.height
        love.graphics.setColor(1, 0.64, 0.84, 0.32 * strongestFlash)
        love.graphics.rectangle("line", slot.x - 1, slot.y - 1, slot.width + 2, bodyHeight + 2)
        love.graphics.setColor(1, 0.88, 0.96, 0.12 * strongestFlash)
        love.graphics.rectangle("fill", slot.x, slot.y + slot.labelHeight, slot.width, slot.height)
    end
end

local function drawObjectiveEscalationTransition(imageRect, effect)
    if not imageRect or not effect then
        return
    end

    local sourceImage = effect.sourceObjective and getObjectiveImage(effect.sourceObjective.id) or nil
    local targetImage = effect.targetObjective and getObjectiveImage(effect.targetObjective.id) or nil
    local progress = clamp(effect.progress or 0, 0, 1)
    local swapProgress = clamp(effect.swapProgress or 0.7, 0.05, 0.95)
    local revealProgress = clamp((progress - (swapProgress - 0.16)) / 0.36, 0, 1)
    local breakupProgress = clamp((progress - (swapProgress - 0.1)) / 0.28, 0, 1)
    local overlayProgress = clamp(progress / math.max(0.001, swapProgress), 0, 1)
    local slices = math.max(10, snap(imageRect.height / 12))
    local sliceHeight = imageRect.height / slices
    local sourceScaleX = sourceImage and (imageRect.width / sourceImage:getWidth()) or nil
    local sourceScaleY = sourceImage and (imageRect.height / sourceImage:getHeight()) or nil
    local targetScaleX = targetImage and (imageRect.width / targetImage:getWidth()) or nil
    local targetScaleY = targetImage and (imageRect.height / targetImage:getHeight()) or nil

    if targetImage and revealProgress > 0 then
        love.graphics.setColor(1, 1, 1, 0.22 + (0.78 * revealProgress))
        love.graphics.draw(targetImage, imageRect.x, imageRect.y, 0, targetScaleX, targetScaleY)
    end

    if sourceImage and breakupProgress < 1 then
        for sliceIndex = 0, slices - 1 do
            local sliceY = imageRect.y + (sliceIndex * sliceHeight)
            local direction = sliceIndex % 2 == 0 and -1 or 1
            local pseudo = (math.sin((effect.seed or 0) + (sliceIndex * 13.17)) + 1) / 2
            local offsetX = direction * imageRect.width * (0.05 + (0.18 * pseudo)) * breakupProgress
            local offsetY = math.cos((effect.seed or 0) + (sliceIndex * 5.21)) * 1.8 * breakupProgress
            local sliceAlpha = 1 - (0.88 * breakupProgress)

            love.graphics.setScissor(snap(imageRect.x), snap(sliceY), math.max(1, snap(imageRect.width)), math.max(1, snap(sliceHeight + 1)))
            love.graphics.setColor(1, 1, 1, sliceAlpha)
            love.graphics.draw(sourceImage, imageRect.x + offsetX, imageRect.y + offsetY, 0, sourceScaleX, sourceScaleY)
        end
    end

    love.graphics.setScissor()

    if overlayProgress < 1 then
        carddraw.drawOverlayPulse("progress", imageRect.x, imageRect.y, imageRect.width, imageRect.height, overlayProgress, 0.95)
    end

    love.graphics.setColor(1, 0.86, 0.94, 0.18 * revealProgress)
    for sliceIndex = 0, slices do
        local lineY = imageRect.y + (sliceIndex * sliceHeight)
        love.graphics.rectangle("fill", imageRect.x, snap(lineY), imageRect.width, 1)
    end

    if breakupProgress > 0 then
        love.graphics.setColor(1, 0.65, 0.83, 0.25 * breakupProgress)
        love.graphics.rectangle("line", imageRect.x, imageRect.y, imageRect.width, imageRect.height)
    end
end

local function drawWarzoneTransformationTransition(imageRect, effect)
    if not imageRect or not effect then
        return
    end

    local sourceImage = effect.sourceWarzone and getWarzoneImage(effect.sourceWarzone.id) or nil
    local targetImage = effect.targetWarzone and getWarzoneImage(effect.targetWarzone.id) or nil
    local progress = clamp(effect.progress or 0, 0, 1)
    local mode = effect.mode or "breach"
    local frontX = imageRect.x + imageRect.width - (imageRect.width * progress)
    local slices = math.max(10, snap(imageRect.height / 12))
    local sliceHeight = imageRect.height / slices
    local sourceScaleX = sourceImage and (imageRect.width / sourceImage:getWidth()) or nil
    local sourceScaleY = sourceImage and (imageRect.height / sourceImage:getHeight()) or nil
    local targetScaleX = targetImage and (imageRect.width / targetImage:getWidth()) or nil
    local targetScaleY = targetImage and (imageRect.height / targetImage:getHeight()) or nil
    local breachAlpha = mode == "breach" and (0.32 + (0.38 * progress)) or (0.16 + (0.12 * (1 - progress)))
    local restoreGlow = mode == "restore" and progress or 0

    if targetImage and mode == "restore" then
        love.graphics.setColor(1, 1, 1, 0.18 + (0.36 * restoreGlow))
        love.graphics.draw(targetImage, imageRect.x, imageRect.y, 0, targetScaleX, targetScaleY)
    end

    if sourceImage and progress < 1 then
        local visibleWidth = math.max(0, frontX - imageRect.x)

        if visibleWidth > 0 then
            love.graphics.setScissor(snap(imageRect.x), snap(imageRect.y), math.max(1, snap(visibleWidth)), math.max(1, snap(imageRect.height)))
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(sourceImage, imageRect.x, imageRect.y, 0, sourceScaleX, sourceScaleY)
            love.graphics.setScissor()
        end
    end

    love.graphics.setColor(0.03, 0.04, 0.05, breachAlpha)
    love.graphics.rectangle("fill", frontX, imageRect.y, imageRect.x + imageRect.width - frontX, imageRect.height)

    for sliceIndex = 0, slices - 1 do
        local sliceY = imageRect.y + (sliceIndex * sliceHeight)
        local pseudo = (math.sin((effect.seed or 0) + (sliceIndex * 11.73)) + 1) / 2
        local blockWidth = imageRect.width * (0.08 + (0.18 * pseudo))
        local wobble = math.sin((effect.seed or 0) + (sliceIndex * 5.17) + (progress * 18)) * imageRect.width * 0.018
        local blockX = clamp(frontX - (blockWidth * (0.22 + (0.62 * pseudo))) + wobble, imageRect.x, imageRect.x + imageRect.width)
        local alpha = mode == "breach"
            and (0.14 + (0.56 * progress * pseudo))
            or (0.08 + (0.22 * (1 - progress) * pseudo))

        love.graphics.setColor(0.02, 0.03, 0.04, alpha)
        love.graphics.rectangle("fill", snap(blockX), snap(sliceY), math.max(1, snap(blockWidth)), math.max(1, snap(sliceHeight + 1)))

        if mode == "restore" then
            love.graphics.setColor(0.86, 0.94, 0.96, 0.08 * restoreGlow * (0.5 + pseudo))
            love.graphics.rectangle("fill", snap(blockX), snap(sliceY), math.max(1, snap(blockWidth * 0.72)), 1)
        end
    end

    local seamAlpha = mode == "breach" and (0.25 + (0.45 * progress)) or (0.2 + (0.28 * restoreGlow))
    love.graphics.setColor(mode == "breach" and 0.08 or 0.82, mode == "breach" and 0.09 or 0.93, mode == "breach" and 0.1 or 0.97, seamAlpha)
    love.graphics.rectangle("fill", snap(frontX), imageRect.y, math.max(1, snap(imageRect.width * 0.012)), imageRect.height)

    if mode == "restore" then
        love.graphics.setColor(0.82, 0.93, 0.97, 0.16 * restoreGlow)
        for sliceIndex = 0, slices do
            local lineY = imageRect.y + (sliceIndex * sliceHeight)
            love.graphics.rectangle("fill", imageRect.x, snap(lineY), imageRect.width, 1)
        end
    else
        love.graphics.setColor(0, 0, 0, 0.12 + (0.22 * progress))
        for sliceIndex = 0, slices do
            local lineY = imageRect.y + (sliceIndex * sliceHeight)
            love.graphics.rectangle("fill", imageRect.x, snap(lineY), imageRect.width, 1)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

local function drawPoiEmergenceEffect(warzoneSlot, poiSlot, effect)
    if not warzoneSlot or not poiSlot or not effect or not warzoneSlot.imageRect or not poiSlot.imageRect then
        return
    end

    local progress = clamp(effect.progress or 0, 0, 1)
    local seed = effect.seed or 0
    local sourceRect = warzoneSlot.imageRect
    local targetRect = poiSlot.imageRect
    local sourceX = sourceRect.x + sourceRect.width
    local sourceY = sourceRect.y + (sourceRect.height * 0.52)
    local targetX = targetRect.x
    local targetY = targetRect.y + (targetRect.height * 0.52)
    local lineProgress = clamp(progress / 0.42, 0, 1)
    local revealProgress = clamp((progress - 0.18) / 0.82, 0, 1)
    local lineEndX = sourceX + ((targetX - sourceX) * lineProgress)
    local pulse = (math.sin((love.timer.getTime() + seed) * 18) + 1) / 2
    local slices = math.max(10, snap(targetRect.height / 12))
    local sliceHeight = targetRect.height / slices

    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.76, 0.92, 0.98, 0.2 + (0.45 * lineProgress))
    love.graphics.line(sourceX, sourceY, lineEndX, targetY)
    love.graphics.setColor(0.92, 0.98, 1, 0.12 + (0.24 * lineProgress))
    love.graphics.rectangle("fill", sourceX, sourceY - 2, math.max(1, lineEndX - sourceX), 4)

    local burstX = sourceX + ((targetX - sourceX) * math.min(1, lineProgress * 1.08))
    love.graphics.setColor(0.86, 0.96, 1, 0.2 + (0.35 * pulse * lineProgress))
    love.graphics.rectangle("fill", burstX - 3, targetY - 3, 6, 6)

    if poiSlot.image then
        love.graphics.setColor(1, 1, 1, 0.2 + (0.8 * revealProgress))
        love.graphics.draw(
            poiSlot.image,
            targetRect.x,
            targetRect.y,
            0,
            targetRect.width / poiSlot.image:getWidth(),
            targetRect.height / poiSlot.image:getHeight()
        )
    end

    local occlusionFront = targetRect.x + (targetRect.width * (1 - revealProgress))
    local occlusionWidth = math.max(0, (targetRect.x + targetRect.width) - occlusionFront)

    if occlusionWidth > 0 then
        love.graphics.setColor(0.03, 0.04, 0.06, 0.82 - (0.26 * revealProgress))
        love.graphics.rectangle("fill", occlusionFront, targetRect.y, occlusionWidth, targetRect.height)
    end

    for sliceIndex = 0, slices - 1 do
        local sliceY = targetRect.y + (sliceIndex * sliceHeight)
        local pseudo = (math.sin(seed + (sliceIndex * 13.11)) + 1) / 2
        local bandProgress = clamp(revealProgress - (sliceIndex / math.max(1, slices - 1)) * 0.12, 0, 1)
        local bandWidth = targetRect.width * (0.16 + (0.42 * pseudo)) * (1 - bandProgress)
        local bandX = clamp(targetRect.x + (targetRect.width * (1 - bandProgress)) - bandWidth + (math.sin(seed + (sliceIndex * 3.7) + (progress * 14)) * targetRect.width * 0.03), targetRect.x, targetRect.x + targetRect.width)
        local alpha = 0.16 + (0.55 * (1 - bandProgress))

        if bandWidth > 0.5 then
            love.graphics.setColor(0.04, 0.06, 0.08, alpha)
            love.graphics.rectangle("fill", snap(bandX), snap(sliceY), math.max(1, snap(bandWidth)), math.max(1, snap(sliceHeight + 1)))
        end
    end

    love.graphics.setColor(0.84, 0.95, 0.99, 0.1 + (0.18 * revealProgress))
    for sliceIndex = 0, slices do
        local lineY = targetRect.y + (sliceIndex * sliceHeight)
        love.graphics.rectangle("fill", targetRect.x, snap(lineY), targetRect.width, 1)
    end

    if revealProgress > 0 then
        love.graphics.setColor(0.82, 0.94, 0.99, 0.08 + (0.22 * revealProgress))
        love.graphics.rectangle("line", targetRect.x, targetRect.y, targetRect.width, targetRect.height)
    end

    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

local function drawPoiFlipTransition(poiSlot, effect)
    if not poiSlot or not poiSlot.imageRect or not effect then
        return
    end

    local imageRect = poiSlot.imageRect
    local sourceImage = effect.sourcePoi and getWarzoneImage(effect.sourcePoi.id) or nil
    local targetImage = effect.targetPoi and getWarzoneImage(effect.targetPoi.id) or nil
    local progress = clamp(effect.progress or 0, 0, 1)
    local seed = effect.seed or 0
    local diagonalLead = imageRect.x + (imageRect.width * progress) + ((imageRect.y + imageRect.height - imageRect.y) * 0.16)
    local slices = math.max(10, snap(imageRect.height / 12))
    local sliceHeight = imageRect.height / slices
    local sourceScaleX = sourceImage and (imageRect.width / sourceImage:getWidth()) or nil
    local sourceScaleY = sourceImage and (imageRect.height / sourceImage:getHeight()) or nil
    local targetScaleX = targetImage and (imageRect.width / targetImage:getWidth()) or nil
    local targetScaleY = targetImage and (imageRect.height / targetImage:getHeight()) or nil

    if sourceImage then
        love.graphics.setColor(0.78, 0.78, 0.8, 1)
        love.graphics.draw(sourceImage, imageRect.x, imageRect.y, 0, sourceScaleX, sourceScaleY)
    end

    if targetImage then
        for sliceIndex = 0, slices - 1 do
            local sliceY = imageRect.y + (sliceIndex * sliceHeight)
            local sliceCenterY = sliceY + (sliceHeight * 0.5)
            local revealX = diagonalLead - ((sliceCenterY - imageRect.y) * 0.2)
            local visibleWidth = math.max(0, imageRect.x + imageRect.width - revealX)

            if visibleWidth > 0 then
                love.graphics.setScissor(snap(revealX), snap(sliceY), math.max(1, snap(visibleWidth + 1)), math.max(1, snap(sliceHeight + 1)))
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(targetImage, imageRect.x, imageRect.y, 0, targetScaleX, targetScaleY)
            end
        end
        love.graphics.setScissor()
    end

    local wipeX = clamp(diagonalLead - (imageRect.width * 0.1), imageRect.x, imageRect.x + imageRect.width)
    love.graphics.setColor(0.78, 0.14, 0.08, 0.12 + (0.22 * progress))
    love.graphics.rectangle("fill", imageRect.x, imageRect.y, imageRect.width, imageRect.height)

    for sliceIndex = 0, slices - 1 do
        local sliceY = imageRect.y + (sliceIndex * sliceHeight)
        local pseudo = (math.sin(seed + (sliceIndex * 12.37)) + 1) / 2
        local blockWidth = imageRect.width * (0.08 + (0.14 * pseudo))
        local blockX = clamp(wipeX - (blockWidth * (0.2 + pseudo)) + (math.sin(seed + (sliceIndex * 6.11) + (progress * 20)) * imageRect.width * 0.02), imageRect.x, imageRect.x + imageRect.width)

        love.graphics.setColor(0.76, 0.2 + (0.18 * pseudo), 0.06, 0.1 + (0.22 * progress))
        love.graphics.rectangle("fill", snap(blockX), snap(sliceY), math.max(1, snap(blockWidth)), math.max(1, snap(sliceHeight + 1)))
        love.graphics.setColor(0.98, 0.72, 0.14, 0.04 + (0.1 * progress * pseudo))
        love.graphics.rectangle("fill", snap(blockX), snap(sliceY), math.max(1, snap(blockWidth * 0.66)), 1)
    end

    love.graphics.setColor(0.98, 0.7, 0.16, 0.18 + (0.34 * progress))
    love.graphics.rectangle("fill", snap(wipeX), imageRect.y, math.max(1, snap(imageRect.width * 0.018)), imageRect.height)
    love.graphics.setColor(0.88, 0.22, 0.08, 0.12 + (0.24 * progress))
    love.graphics.rectangle("line", imageRect.x, imageRect.y, imageRect.width, imageRect.height)
    love.graphics.setColor(1, 1, 1, 1)
end

local function drawPoiHunterTransformation(slots, effect)
    if not slots or not effect or not effect.sourcePoi or not effect.generatedCardDefinition then
        return
    end

    local poiSlot = nil

    for _, slot in ipairs(slots) do
        if slot.id == "poi" then
            poiSlot = slot
            break
        end
    end

    if not poiSlot or not poiSlot.imageRect then
        return
    end

    local progress = clamp(effect.progress or 0, 0, 1)
    local sourceRect = poiSlot.imageRect
    local sourceImage = getWarzoneImage(effect.sourcePoi.id)
    local targetLocation = effect.targetLocation or {}
    local startX = sourceRect.x
    local startY = sourceRect.y
    local startWidth = sourceRect.width
    local startHeight = sourceRect.height
    local targetX = startX
    local targetY = love.graphics.getHeight() + startHeight
    local targetWidth = startWidth
    local targetHeight = startHeight

    if targetLocation.kind == "hand" and targetLocation.slotIndex then
        local handLayout = envdraw.getPlayerHandLayout()
        local handSlot = handLayout and handLayout.slots and handLayout.slots[targetLocation.slotIndex] or nil

        if handSlot then
            targetX = handSlot.x
            targetY = handSlot.y
            targetWidth = handSlot.width
            targetHeight = handSlot.height
        end
    end

    local moveProgress = targetLocation.kind == "hand"
        and clamp(progress / 0.82, 0, 1)
        or clamp(progress, 0, 1)
    local morphProgress = targetLocation.kind == "hand"
        and clamp((progress - 0.42) / 0.58, 0, 1)
        or clamp((progress - 0.22) / 0.78, 0, 1)
    local drawX = lerp(startX, targetX, moveProgress)
    local drawY = lerp(startY, targetY, moveProgress)
    local drawWidth = lerp(startWidth, targetWidth, moveProgress)
    local drawHeight = lerp(startHeight, targetHeight, moveProgress)
    local poiAlpha = targetLocation.kind == "hand"
        and (1 - morphProgress)
        or (1 - clamp((progress - 0.2) / 0.8, 0, 1))
    local hunterAlpha = targetLocation.kind == "hand" and morphProgress or 0
    local trailAlpha = 0.08 + (0.18 * (1 - progress))

    love.graphics.setColor(0.76, 0.9, 0.96, trailAlpha)
    love.graphics.setLineWidth(2)
    love.graphics.line(startX + (startWidth / 2), startY + (startHeight / 2), drawX + (drawWidth / 2), drawY + (drawHeight / 2))
    love.graphics.setLineWidth(1)

    if sourceImage and poiAlpha > 0 then
        love.graphics.setColor(1, 1, 1, poiAlpha)
        love.graphics.draw(
            sourceImage,
            drawX,
            drawY,
            0,
            drawWidth / sourceImage:getWidth(),
            drawHeight / sourceImage:getHeight()
        )
    end

    if targetLocation.kind == "hand" and hunterAlpha > 0 then
        carddraw.drawPortraitPreview(
            effect.generatedCardDefinition.setName,
            effect.generatedCardDefinition.id,
            drawX,
            drawY,
            drawWidth,
            drawHeight,
            hunterAlpha
        )
    end

    if targetLocation.kind == "deck" then
        local fadeAlpha = 0.12 + (0.24 * (1 - progress))
        love.graphics.setColor(0.03, 0.04, 0.05, fadeAlpha)
        love.graphics.rectangle("fill", drawX, drawY, drawWidth, drawHeight)
    end

    love.graphics.setColor(0.86, 0.92, 0.96, 0.12 + (0.24 * (1 - progress)))
    love.graphics.rectangle("line", drawX, drawY, drawWidth, drawHeight)
    love.graphics.setColor(1, 1, 1, 1)
end

function envdraw.drawPoiHunterTransformationOverlay(currentPhase, championDefinition, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition, effect, jitterOffsets)
    if not effect then
        return
    end

    local slots = buildTopStripLayout(championDefinition, currentPhase, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition)

    if not slots then
        return
    end

    for _, slot in ipairs(slots) do
        local jitterOffset = jitterOffsets and jitterOffsets[slot.id] or nil

        if jitterOffset then
            slot.x = slot.x + jitterOffset.x
            slot.y = slot.y + jitterOffset.y

            if slot.imageRect then
                slot.imageRect = {
                    x = slot.imageRect.x + jitterOffset.x,
                    y = slot.imageRect.y + jitterOffset.y,
                    width = slot.imageRect.width,
                    height = slot.imageRect.height,
                }
            end
        end
    end

    drawPoiHunterTransformation(slots, effect)
end

local function drawTopSlotEmphasisBadge(slot, imageRect)
    if not slot or not slot.definition or slot.definition.emphasis == nil or not imageRect then
        return
    end

    local badgeSize = math.max(20, snap(imageRect.width * TOP_SLOT_EMPHASIS_BADGE_SIZE_RATIO))
    local badgeInset = math.max(4, snap(imageRect.width * 0.04))
    local badgeX = snap(imageRect.x + imageRect.width - badgeInset - badgeSize)
    local badgeY = snap(imageRect.y + imageRect.height - badgeInset - badgeSize)
    local badgeFontSize = math.max(10, snap(badgeSize * 0.5))
    local badgeFont = getFont(CHAMP_LABEL_FONT_PATH, badgeFontSize)
    local valueText = tostring(slot.definition.emphasis)
    local textY = snap(badgeY + ((badgeSize - badgeFont:getHeight()) / 2))

    love.graphics.setColor(0.05, 0.05, 0.06, 0.95)
    love.graphics.rectangle("fill", badgeX, badgeY, badgeSize, badgeSize)
    love.graphics.setColor(slot.accentColor[1], slot.accentColor[2], slot.accentColor[3], 0.95)
    love.graphics.rectangle("line", badgeX, badgeY, badgeSize, badgeSize)
    love.graphics.setColor(slot.accentColor[1], slot.accentColor[2], slot.accentColor[3], 1)
    love.graphics.setFont(badgeFont)
    love.graphics.printf(
        valueText,
        badgeX,
        textY,
        badgeSize,
        "center"
    )
end

local function getRowImage(rowIdentifier)
    if imageCache[rowIdentifier] ~= nil then
        return imageCache[rowIdentifier]
    end

    local imagePath = IMAGE_DIRECTORY .. rowIdentifier .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        imageCache[rowIdentifier] = false
        return nil
    end

    imageCache[rowIdentifier] = love.graphics.newImage(imagePath)
    return imageCache[rowIdentifier]
end

local function getJaclImage(jaclName)
    if not jaclName then
        return nil
    end

    local cacheKey = "jacl:" .. jaclName

    if imageCache[cacheKey] ~= nil then
        return imageCache[cacheKey]
    end

    local imagePath = JACL_IMAGE_DIRECTORY .. jaclName .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        imageCache[cacheKey] = false
        return nil
    end

    imageCache[cacheKey] = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    imageCache[cacheKey]:setFilter("linear", "linear")
    return imageCache[cacheKey]
end

getChampImage = function(championId)
    if not championId then
        return nil
    end

    local cacheKey = "champ:" .. championId

    if imageCache[cacheKey] ~= nil then
        return imageCache[cacheKey]
    end

    local imagePath = CHAMP_IMAGE_DIRECTORY .. championId .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        imageCache[cacheKey] = false
        return nil
    end

    imageCache[cacheKey] = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    imageCache[cacheKey]:setFilter("linear", "linear")
    return imageCache[cacheKey]
end

getObjectiveImage = function(objectiveId)
    if not objectiveId then
        return nil
    end

    local cacheKey = "objective:" .. objectiveId

    if imageCache[cacheKey] ~= nil then
        return imageCache[cacheKey]
    end

    local imagePath = OBJECTIVE_IMAGE_DIRECTORY .. objectiveId .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        imageCache[cacheKey] = false
        return nil
    end

    imageCache[cacheKey] = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    imageCache[cacheKey]:setFilter("linear", "linear")
    return imageCache[cacheKey]
end

getWarzoneImage = function(warzoneId)
    if not warzoneId then
        return nil
    end

    local cacheKey = "warzone:" .. warzoneId

    if imageCache[cacheKey] ~= nil then
        return imageCache[cacheKey]
    end

    local imagePath = WARZONE_IMAGE_DIRECTORY .. warzoneId .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        imageCache[cacheKey] = false
        return nil
    end

    imageCache[cacheKey] = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    imageCache[cacheKey]:setFilter("linear", "linear")
    return imageCache[cacheKey]
end

function envdraw.preloadTopStripAssets(championDefinition, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition)
    if championDefinition then
        getChampImage(championDefinition.id)
    end

    if warzoneDefinition then
        getWarzoneImage(warzoneDefinition.id)
    end

    if poiDefinition then
        getWarzoneImage(poiDefinition.id)
    end

    if objectiveDefinition then
        getObjectiveImage(objectiveDefinition.id)
    end

    if intelDefinition then
        getObjectiveImage(intelDefinition.id)
    end
end

function envdraw.getJaclArtImage(jaclDefinition)
    return jaclDefinition and getJaclImage(jaclDefinition.name) or nil
end

function envdraw.getTopSlotArtImage(slotId, championDefinition, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition)
    if slotId == "champion" and championDefinition and not championDefinition.hidden then
        return getChampImage(championDefinition.id)
    elseif slotId == "warzone" and warzoneDefinition then
        return getWarzoneImage(warzoneDefinition.id)
    elseif slotId == "poi" and poiDefinition then
        return getWarzoneImage(poiDefinition.id)
    elseif slotId == "objective" and objectiveDefinition and not objectiveDefinition.hidden then
        return getObjectiveImage(objectiveDefinition.id)
    elseif slotId == "intel" and intelDefinition and not intelDefinition.hidden then
        return getObjectiveImage(intelDefinition.id)
    end

    return nil
end

function getMethodImage(resourceName)
    if not resourceName then
        return nil
    end

    local cacheKey = "method:" .. resourceName

    if imageCache[cacheKey] ~= nil then
        return imageCache[cacheKey]
    end

    local imagePath = METHOD_IMAGE_DIRECTORY .. resourceName .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        imageCache[cacheKey] = false
        return nil
    end

    imageCache[cacheKey] = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    imageCache[cacheKey]:setFilter("linear", "linear")
    return imageCache[cacheKey]
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

local function getTopSlotMethodBadgeLayout(slotX, slotY, slotWidth, labelHeight, labelPadding, methodEntries)
    local expandedResources = expandMethodEntries(methodEntries)
    local badgeSize = math.max(12, snap(math.min(JACL_METHOD_BADGE_SIZE, labelHeight - 6)))
    local badgeGap = math.max(2, snap(badgeSize * 0.12))
    local totalWidth = (#expandedResources * badgeSize) + (math.max(0, #expandedResources - 1) * badgeGap)
    local startX = snap(slotX + slotWidth - labelPadding - totalWidth)
    local startY = snap(slotY + ((labelHeight - badgeSize) / 2))
    local centers = {}
    local badges = {}

    for badgeIndex, resourceName in ipairs(expandedResources) do
        local badgeX = startX + ((badgeIndex - 1) * (badgeSize + badgeGap))

        centers[#centers + 1] = {
            resource = resourceName,
            x = badgeX + (badgeSize / 2),
            y = startY + (badgeSize / 2),
        }
        badges[#badges + 1] = {
            resource = resourceName,
            x = badgeX,
            y = startY,
            width = badgeSize,
            height = badgeSize,
        }
    end

    return centers, badges
end

local function drawMethodBadges(methodBadges)
    for _, badge in ipairs(methodBadges or {}) do
        local methodImage = getMethodImage(badge.resource)

        love.graphics.setColor(0.12, 0.13, 0.16, 0.95)
        love.graphics.rectangle("fill", badge.x, badge.y, badge.width, badge.height)
        love.graphics.setColor(0.87, 0.87, 0.9, 0.9)
        love.graphics.rectangle("line", badge.x, badge.y, badge.width, badge.height)

        if methodImage then
            local imageScale = math.min(badge.width / methodImage:getWidth(), badge.height / methodImage:getHeight())
            local imageWidth = methodImage:getWidth() * imageScale
            local imageHeight = methodImage:getHeight() * imageScale
            local imageX = badge.x + ((badge.width - imageWidth) / 2)
            local imageY = badge.y + ((badge.height - imageHeight) / 2)

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(methodImage, imageX, imageY, 0, imageScale, imageScale)
        end
    end
end

function envdraw.getGridLayout()
    local rows = envrules.getRows()
    local gridRows = #rows
    local totalWidth = (GRID_COLUMNS * CELL_WIDTH) + ((GRID_COLUMNS - 1) * CELL_GAP)
    local totalHeight = (gridRows * CELL_HEIGHT) + ((gridRows - 1) * CELL_GAP)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local startX = (windowWidth - totalWidth) / 2
    local startY = (windowHeight - totalHeight) / 2
    local layout = {
        rows = {},
    }

    for row = 0, gridRows - 1 do
        local rowDefinition = rows[row + 1]
        local rowY = startY + (row * (CELL_HEIGHT + CELL_GAP))
        local cells = {}

        for column = 0, GRID_COLUMNS - 1 do
            local x = startX + (column * (CELL_WIDTH + CELL_GAP))
            cells[column + 1] = {
                column = column + 1,
                x = x,
                y = rowY,
                width = CELL_WIDTH,
                height = CELL_HEIGHT,
            }
        end

        layout.rows[row + 1] = {
            id = rowDefinition.id,
            y = rowY,
            cells = cells,
        }
    end

    return layout
end

function envdraw.getGridRow(rowId)
    local gridLayout = envdraw.getGridLayout()

    for _, row in ipairs(gridLayout.rows) do
        if row.id == rowId then
            return row
        end
    end

    return nil
end

function envdraw.getSetupModalLayout(agentCount)
    if not agentCount or agentCount <= 0 then
        return nil
    end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    local playerRow = envdraw.getGridRow("PlayerRow")
    local cardsWidth = (agentCount * CELL_WIDTH) + ((agentCount - 1) * SETUP_MODAL_SLOT_GAP)
    local modalWidth = cardsWidth + (SETUP_MODAL_PADDING * 2)
    local modalHeight = CELL_HEIGHT + (SETUP_MODAL_PADDING * 2)
    local maxBottom = math.min(windowHeight * SETUP_MODAL_MAX_HEIGHT_RATIO, playerRow and (playerRow.y - SETUP_MODAL_MARGIN) or (windowHeight * SETUP_MODAL_MAX_HEIGHT_RATIO))
    local modalX = (windowWidth - modalWidth) / 2
    local modalY = math.max(SETUP_MODAL_MARGIN, maxBottom - modalHeight)
    local slots = {}

    for slotIndex = 1, agentCount do
        slots[slotIndex] = {
            x = modalX + SETUP_MODAL_PADDING + ((slotIndex - 1) * (CELL_WIDTH + SETUP_MODAL_SLOT_GAP)),
            y = modalY + SETUP_MODAL_PADDING,
            width = CELL_WIDTH,
            height = CELL_HEIGHT,
        }
    end

    return {
        x = modalX,
        y = modalY,
        width = modalWidth,
        height = modalHeight,
        slots = slots,
    }
end

function envdraw.drawGrid(currentPhase)
    local gridLayout = envdraw.getGridLayout()

    love.graphics.setColor(0.75, 0.78, 0.82, 1)

    for _, row in ipairs(gridLayout.rows) do
        if currentPhase ~= "Setup" or row.id ~= "OppRow" then
        local rowImage = getRowImage(row.id)

            for _, cell in ipairs(row.cells) do
                local x = cell.x
                local y = cell.y

                if rowImage then
                    local imageWidth = rowImage:getWidth()
                    local imageHeight = rowImage:getHeight()
                    local scaleX = CELL_WIDTH / imageWidth
                    local scaleY = CELL_HEIGHT / imageHeight
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(rowImage, x, y, 0, scaleX, scaleY)
                    love.graphics.setColor(0.75, 0.78, 0.82, 1)
                end

                love.graphics.rectangle("line", x, y, CELL_WIDTH, CELL_HEIGHT)
            end
        end
    end

    love.graphics.setColor(1, 1, 1)
end

function envdraw.drawChampion(championDefinition, currentPhase, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition)
    envdraw.drawChampion(championDefinition, currentPhase, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition, nil, nil)
end

buildTopStripLayout = function(championDefinition, currentPhase, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition, warzonePreviewState, objectivePreviewPips, intelPreviewPips)
    if currentPhase == "Setup" then
        return nil
    end

    local championSlotVisible = championDefinition and currentPhase ~= "Setup"
    local championImage = championSlotVisible and championDefinition and getChampImage(championDefinition.id) or nil
    local championPortraitVisible = championDefinition and not championDefinition.hidden and currentPhase ~= "Setup"
    local warzoneImage = warzoneDefinition and getWarzoneImage(warzoneDefinition.id) or nil
    local poiImage = poiDefinition and getWarzoneImage(poiDefinition.id) or nil
    local objectiveImage = objectiveDefinition and not objectiveDefinition.hidden and getObjectiveImage(objectiveDefinition.id) or nil
    local intelVisible = intelDefinition and not intelDefinition.hidden
    local intelImage = intelVisible and getObjectiveImage(intelDefinition.id) or nil
    local gridLayout = envdraw.getGridLayout()
    local gridTopY = gridLayout.rows[1] and gridLayout.rows[1].y or 0
    local availableHeight = math.max(1, gridTopY - (CHAMP_DISPLAY_TOP_MARGIN * 2))
    local windowWidth = love.graphics.getWidth()
    local championHealth = championDefinition and championDefinition.health and tostring(championDefinition.health) or nil
    local championHealthPips = championDefinition and championDefinition.health or nil
    local championMaxPips = championDefinition and championDefinition.max or nil
    local warzoneControl = warzoneDefinition and warzoneDefinition.control and tostring(warzoneDefinition.control) or nil
    local warzoneControlColor = (warzoneDefinition and (warzoneDefinition.control or 0) > 0) and TROOP_HEALTH_COLOR or CHAMP_ACCENT_COLOR
    local warzoneControlPips = warzoneDefinition and math.max(0, math.abs(warzoneDefinition.control or 0)) or nil
    local warzoneMaxPips = warzoneDefinition and warzoneDefinition.max or nil
    local poiControl = poiDefinition and poiDefinition.control and tostring(poiDefinition.control) or nil
    local poiControlColor = (poiDefinition and (poiDefinition.control or 0) > 0) and TROOP_HEALTH_COLOR or CHAMP_ACCENT_COLOR
    local poiControlPips = poiDefinition and math.max(0, math.abs(poiDefinition.control or 0)) or nil
    local poiMaxPips = poiDefinition and poiDefinition.max or nil
    local objectivePlan = objectiveDefinition and objectiveDefinition.plan and tostring(objectiveDefinition.plan) or nil
    local objectivePlanPips = objectiveDefinition and objectiveDefinition.plan or nil
    local objectiveMaxPips = objectiveDefinition and objectiveDefinition.max or nil
    local intelPlan = intelDefinition and intelDefinition.plan and tostring(intelDefinition.plan) or nil
    local intelPlanPips = intelDefinition and intelDefinition.plan or nil
    local intelMaxPips = intelDefinition and intelDefinition.max or nil
    local slots = {}

    local function addSlot(slotId, slotX, slotY, slotWidth, slotHeight, labelHeight, labelPadding, labelFont, accentColor, nameColor, rightTextColor, nameText, rightText, rightPipCount, maxPipCount, previewPipCount, previewOverlaysExisting, previewExtendPipCount, slotLabel, image, textbox, definition, hideHeader)
        local imageRect = getTopSlotImageRect(slotX, slotY, slotWidth, slotHeight, labelHeight, image)
        local slotTextbox = textbox or definition and definition.flavor or nil
        local isFlavorTextbox = textbox == nil and definition and definition.flavor ~= nil
        local methodBadgeCenters, methodBadges = getTopSlotMethodBadgeLayout(slotX, slotY, slotWidth, labelHeight, labelPadding, definition and definition.method or nil)

        slots[#slots + 1] = {
            id = slotId,
            x = slotX,
            y = slotY,
            width = slotWidth,
            height = slotHeight,
            labelHeight = labelHeight,
            labelPadding = labelPadding,
            labelFont = labelFont,
            accentColor = accentColor,
            nameColor = nameColor,
            rightTextColor = rightTextColor,
            nameText = nameText,
            rightText = rightText,
            rightPipCount = rightPipCount,
            maxPipCount = maxPipCount,
            previewPipCount = previewPipCount,
            previewOverlaysExisting = previewOverlaysExisting,
            previewExtendPipCount = previewExtendPipCount,
            slotLabel = slotLabel,
            image = image,
            imageRect = imageRect,
            textbox = slotTextbox,
            isFlavorTextbox = isFlavorTextbox,
            methodBadgeCenters = methodBadgeCenters,
            methodBadges = methodBadges,
            definition = definition,
            hideHeader = hideHeader == true,
            hideBodyOutline = false,
        }
    end

    local function finalizeLayout(boxWidth, boxHeight, labelHeight, labelPadding, labelFont, drawX, drawY)
        addSlot("champion", drawX, drawY, boxWidth, boxHeight, labelHeight, labelPadding, labelFont, CHAMP_ACCENT_COLOR, CHAMP_ACCENT_COLOR, CHAMP_HEALTH_COLOR, championSlotVisible and (championDefinition.name or championDefinition.id) or nil, championHealth, championHealthPips, championMaxPips, nil, false, nil, nil, championPortraitVisible and championImage or nil, championDefinition and championDefinition.textbox or nil, championDefinition, false)

        for slotIndex = 1, 2 do
            local leftSlotX = drawX - (slotIndex * (boxWidth + CHAMP_SLOT_GAP))
            local rightSlotX = drawX + boxWidth + ((slotIndex - 1) * (boxWidth + CHAMP_SLOT_GAP)) + CHAMP_SLOT_GAP

            if slotIndex == 2 and warzoneDefinition then
                addSlot("warzone", leftSlotX, drawY, boxWidth, boxHeight, labelHeight, labelPadding, labelFont, WARZONE_ACCENT_COLOR, WARZONE_ACCENT_COLOR, warzoneControlColor, warzoneDefinition.name or warzoneDefinition.id, warzoneControl, warzoneControlPips, warzoneMaxPips, warzonePreviewState and warzonePreviewState.overlayPips or nil, true, warzonePreviewState and warzonePreviewState.extendPips or nil, nil, warzoneImage, warzoneDefinition.textbox, warzoneDefinition, false)
            elseif slotIndex == 1 and poiDefinition then
                addSlot("poi", leftSlotX, drawY, boxWidth, boxHeight, labelHeight, labelPadding, labelFont, POI_ACCENT_COLOR, POI_ACCENT_COLOR, poiControlColor, poiDefinition and (poiDefinition.name or poiDefinition.id) or nil, poiControl, poiControlPips, poiMaxPips, nil, false, nil, nil, poiImage, poiDefinition and poiDefinition.textbox or nil, poiDefinition, poiDefinition == nil)
            elseif slotIndex ~= 1 then
                addSlot("placeholder_" .. tostring(3 - slotIndex), leftSlotX, drawY, boxWidth, boxHeight, labelHeight, labelPadding, labelFont, CHAMP_ACCENT_COLOR, CHAMP_ACCENT_COLOR, CHAMP_HEALTH_COLOR, nil, nil, nil, nil, nil, false, nil, tostring(3 - slotIndex), nil, nil, nil, false)
            end

            if slotIndex == 1 and objectiveDefinition and not objectiveDefinition.hidden then
                addSlot("objective", rightSlotX, drawY, boxWidth, boxHeight, labelHeight, labelPadding, labelFont, OBJECTIVE_ACCENT_COLOR, OBJECTIVE_ACCENT_COLOR, OBJECTIVE_PLAN_COLOR, objectiveDefinition.name or objectiveDefinition.id, objectivePlan, objectivePlanPips, objectiveMaxPips, objectivePreviewPips, false, nil, nil, objectiveImage, objectiveDefinition.textbox, objectiveDefinition, false)
            elseif slotIndex == 2 and intelVisible then
                addSlot("intel", rightSlotX, drawY, boxWidth, boxHeight, labelHeight, labelPadding, labelFont, INTEL_ACCENT_COLOR, INTEL_ACCENT_COLOR, INTEL_PLAN_COLOR, intelDefinition.name or intelDefinition.id, intelPlan, intelPlanPips, intelMaxPips, intelPreviewPips, true, nil, nil, intelImage, intelDefinition.textbox, intelDefinition, false)
            else
                addSlot("placeholder_" .. tostring(slotIndex + 2), rightSlotX, drawY, boxWidth, boxHeight, labelHeight, labelPadding, labelFont, CHAMP_ACCENT_COLOR, CHAMP_ACCENT_COLOR, CHAMP_HEALTH_COLOR, nil, nil, nil, nil, nil, false, nil, tostring(slotIndex + 2), nil, nil, nil, false)
            end
        end

        return slots
    end

    local function drawTopSlot(slotX, slotY, slotWidth, slotHeight, labelHeight, labelPadding, labelFont, accentColor, nameColor, rightTextColor, nameText, rightText, rightPipCount, maxPipCount, previewPipCount, previewOverlaysExisting, previewExtendPipCount, slotLabel, image, definition, imageRect, rollState, destructionState, hideHeader, hideBodyOutline)
        if not hideHeader then
            love.graphics.setColor(0, 0, 0, 0.94)
            love.graphics.rectangle("fill", slotX, slotY, slotWidth, labelHeight)
            love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.94)
            love.graphics.rectangle("line", slotX, slotY, slotWidth, labelHeight)
        end

        local rightTextWidth = rightText and labelFont:getWidth(rightText) or 0
        local rightTextPadding = (rightText or rightPipCount) and labelPadding or 0
        local rightPipAreaWidth = 0
        local _, methodBadges = getTopSlotMethodBadgeLayout(slotX, slotY, slotWidth, labelHeight, labelPadding, definition and definition.method or nil)
        local methodBadgeAreaWidth = 0

        if methodBadges and #methodBadges > 0 then
            local firstBadge = methodBadges[1]
            local lastBadge = methodBadges[#methodBadges]
            methodBadgeAreaWidth = (lastBadge.x + lastBadge.width) - firstBadge.x
        end

        if rightPipCount and rightPipCount > 0 or maxPipCount and maxPipCount > 0 then
            local basePipAreaWidth = math.max(labelHeight * 2.4, slotWidth * 0.34)

            if methodBadgeAreaWidth > 0 then
                basePipAreaWidth = basePipAreaWidth + methodBadgeAreaWidth + math.max(2, snap(labelHeight * 0.08))
            end

            rightPipAreaWidth = math.min(slotWidth * 0.62, basePipAreaWidth)
            rightTextWidth = rightPipAreaWidth
        end

        local leftText = nameText or slotLabel
        local leftTextWidth = slotWidth - (labelPadding * 2) - rightTextWidth - rightTextPadding

        if leftText then
            local baseFontSize = labelFont:getHeight()
            local nameFont, wrappedLines = getFittedFontForBox(
                CHAMP_LABEL_FONT_PATH,
                leftText,
                baseFontSize,
                leftTextWidth,
                math.max(1, labelHeight - 4),
                10
            )
            local wrappedHeight = #wrappedLines * nameFont:getHeight()

            love.graphics.setColor(nameColor[1], nameColor[2], nameColor[3], 1)
            love.graphics.setFont(nameFont)
            love.graphics.printf(
                leftText,
                slotX + labelPadding,
                slotY + ((labelHeight - wrappedHeight) / 2),
                leftTextWidth,
                "left"
            )
        end

        if (rightPipCount and rightPipCount > 0) or (maxPipCount and maxPipCount > 0) then
            local pipCount = math.max(0, tonumber(rightPipCount) or 0)
            local maxCount = math.max(pipCount, math.max(0, tonumber(maxPipCount) or 0))
            local columnCount = math.min(CHAMP_HEALTH_PIP_COLUMNS, math.max(1, maxCount))
            local rowCount = math.max(1, math.ceil(math.max(1, maxCount) / CHAMP_HEALTH_PIP_COLUMNS))
            local pipGap = math.max(1, snap(labelHeight * 0.06))
            local methodBadgeGap = methodBadgeAreaWidth > 0 and math.max(2, snap(labelHeight * 0.08)) or 0
            local availableWidth = math.max(1, rightPipAreaWidth - methodBadgeAreaWidth - methodBadgeGap)
            local availableHeight = math.max(1, labelHeight - 4)
            local pipSizeByWidth = (availableWidth - ((columnCount - 1) * pipGap)) / math.max(1, columnCount)
            local pipSizeByHeight = (availableHeight - ((rowCount - 1) * pipGap)) / rowCount
            local maxDefaultPipSize = math.max(1, snap(labelHeight * TOP_SLOT_PIP_MAX_SIZE_RATIO))
            local pipSize = math.max(1, snap(math.min(pipSizeByWidth, pipSizeByHeight, maxDefaultPipSize)))
            local totalGridWidth = (columnCount * pipSize) + ((columnCount - 1) * pipGap)
            local totalGridHeight = (rowCount * pipSize) + ((rowCount - 1) * pipGap)
            local pipAreaX = slotX + slotWidth - labelPadding - rightPipAreaWidth
            local startX = snap(pipAreaX + ((availableWidth - totalGridWidth) / 2))
            local startY = snap(slotY + ((labelHeight - totalGridHeight) / 2))

            if maxPipCount and maxPipCount > 0 then
                love.graphics.setColor(rightTextColor[1], rightTextColor[2], rightTextColor[3], 0.65)

                for pipIndex = 0, maxCount - 1 do
                    local row = math.floor(pipIndex / CHAMP_HEALTH_PIP_COLUMNS)
                    local column = pipIndex % CHAMP_HEALTH_PIP_COLUMNS
                    local pipX = startX + (column * (pipSize + pipGap))
                    local pipY = startY + (row * (pipSize + pipGap))

                    love.graphics.rectangle("line", pipX, pipY, pipSize, pipSize)
                end
            end

            love.graphics.setColor(rightTextColor[1], rightTextColor[2], rightTextColor[3], 1)

            for pipIndex = 0, pipCount - 1 do
                local row = math.floor(pipIndex / CHAMP_HEALTH_PIP_COLUMNS)
                local column = pipIndex % CHAMP_HEALTH_PIP_COLUMNS
                local pipX = startX + (column * (pipSize + pipGap))
                local pipY = startY + (row * (pipSize + pipGap))

                love.graphics.rectangle("fill", pipX, pipY, pipSize, pipSize)
            end

            if previewPipCount and previewPipCount > 0 then
                love.graphics.setColor(PREVIEW_PIP_COLOR[1], PREVIEW_PIP_COLOR[2], PREVIEW_PIP_COLOR[3], 1)

                local previewStartIndex = previewOverlaysExisting and math.max(0, pipCount - previewPipCount) or pipCount
                local previewEndIndex = previewOverlaysExisting
                    and math.max(0, pipCount - 1)
                    or math.min(maxCount, pipCount + previewPipCount) - 1

                for pipIndex = previewStartIndex, previewEndIndex do
                    local row = math.floor(pipIndex / CHAMP_HEALTH_PIP_COLUMNS)
                    local column = pipIndex % CHAMP_HEALTH_PIP_COLUMNS
                    local pipX = startX + (column * (pipSize + pipGap))
                    local pipY = startY + (row * (pipSize + pipGap))

                    love.graphics.rectangle("fill", pipX, pipY, pipSize, pipSize)
                end
            end

            if previewExtendPipCount and previewExtendPipCount > 0 then
                love.graphics.setColor(PREVIEW_PIP_COLOR[1], PREVIEW_PIP_COLOR[2], PREVIEW_PIP_COLOR[3], 1)

                local previewStartIndex = pipCount
                local previewEndIndex = math.min(maxCount, pipCount + previewExtendPipCount) - 1

                for pipIndex = previewStartIndex, previewEndIndex do
                    local row = math.floor(pipIndex / CHAMP_HEALTH_PIP_COLUMNS)
                    local column = pipIndex % CHAMP_HEALTH_PIP_COLUMNS
                    local pipX = startX + (column * (pipSize + pipGap))
                    local pipY = startY + (row * (pipSize + pipGap))

                    love.graphics.rectangle("fill", pipX, pipY, pipSize, pipSize)
                end
            end

            drawMethodBadges(methodBadges)
        elseif rightText then
            love.graphics.setColor(rightTextColor[1], rightTextColor[2], rightTextColor[3], 1)
            love.graphics.print(
                rightText,
                slotX + slotWidth - labelPadding - rightTextWidth,
                slotY + ((labelHeight - labelFont:getHeight()) / 2)
            )
        end

        local bodyX = slotX
        local bodyY = slotY + (hideHeader and 0 or labelHeight)
        local bodyWidth = slotWidth
        local bodyHeight = slotHeight + (hideHeader and labelHeight or 0)

        if hideHeader and imageRect then
            bodyX = imageRect.x
            bodyY = imageRect.y
            bodyWidth = imageRect.width
            bodyHeight = imageRect.height
        end

        love.graphics.setColor(0.12, 0.13, 0.16, 0.9)
        love.graphics.rectangle("fill", bodyX, bodyY, bodyWidth, bodyHeight)

        if not hideBodyOutline then
            love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.9)
            love.graphics.rectangle("line", bodyX, bodyY, bodyWidth, bodyHeight)
        end

        if not hideHeader then
            love.graphics.line(slotX, slotY + labelHeight, slotX + slotWidth, slotY + labelHeight)
        end

        if image then
            if destructionState and destructionState.progress and destructionState.progress > 0 then
                carddraw.drawSignalLossImage(image, imageRect.x, imageRect.y, imageRect.width, imageRect.height, destructionState.progress, destructionState.seed, 1, { 0.12, 0.13, 0.16, 1 })
            else
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(image, imageRect.x, imageRect.y, 0, imageRect.width / image:getWidth(), imageRect.height / image:getHeight())
            end
            if not hideBodyOutline then
                love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.9)
                love.graphics.rectangle("line", bodyX, bodyY, bodyWidth, bodyHeight)
            end
            if not hideHeader then
                love.graphics.line(slotX, slotY + labelHeight, slotX + slotWidth, slotY + labelHeight)
            end
        end

        if definition and rollState and rollState.faceIndex then
            local badgeInset = math.max(4, snap(imageRect.width * 0.035))
            local badgeWidth = math.max(20, snap(imageRect.width * 0.115 * 1.12))
            local badgeHeaderHeight = snap(badgeWidth * 0.44)
            local badgeBodyHeight = badgeWidth
            local badgeHeight = badgeHeaderHeight + badgeBodyHeight
            local badgeX = snap(imageRect.x + imageRect.width - badgeInset - badgeWidth)
            local badgeY = snap(imageRect.y + badgeInset)

            carddraw.drawDefinitionRollBadge(definition, badgeX, badgeY, badgeWidth, badgeHeight, rollState.faceIndex, rollState.pulseScale)

            if rollState.locked then
                love.graphics.setColor(1, 0.847, 0.219, 0.95)
                love.graphics.setLineWidth(3)
                love.graphics.rectangle("line", badgeX - 1, badgeY - 1, badgeWidth + 2, badgeHeight + 2)
                love.graphics.setLineWidth(1)
            end
        end

        if rollState and rollState.targetCard then
            local targetBadgeInset = math.max(4, snap(imageRect.width * 0.04))
            local targetBadgeSize = math.max(20, snap(imageRect.width * 0.19))
            local targetBadgeX = snap(imageRect.x + imageRect.width - targetBadgeInset - targetBadgeSize)
            local targetBadgeY = snap(imageRect.y + imageRect.height - targetBadgeInset - targetBadgeSize)

            carddraw.drawTargetPreviewBadge(rollState.targetCard, targetBadgeX, targetBadgeY, targetBadgeSize)
        end

        drawTopSlotEmphasisBadge({
            definition = definition,
            accentColor = accentColor,
        }, imageRect)
    end

    if championImage then
        local imageScale = math.min(CHAMP_DISPLAY_WIDTH / championImage:getWidth(), CHAMP_DISPLAY_HEIGHT / championImage:getHeight())
        local baseImageWidth = championImage:getWidth() * imageScale
        local baseImageHeight = championImage:getHeight() * imageScale
        local totalBaseHeight = CHAMP_LABEL_HEIGHT + baseImageHeight
        local layoutScale = math.min(1, availableHeight / totalBaseHeight)
        local boxWidth = baseImageWidth * layoutScale
        local boxHeight = baseImageHeight * layoutScale
        local labelHeight = CHAMP_LABEL_HEIGHT * layoutScale
        local labelPadding = CHAMP_LABEL_PADDING * layoutScale
        local labelFont = getFont(CHAMP_LABEL_FONT_PATH, math.max(10, math.floor(CHAMP_LABEL_FONT_SIZE * layoutScale)))
        local drawX = (windowWidth - boxWidth) / 2
        local totalHeight = labelHeight + boxHeight
        local drawY = math.max(0, (gridTopY - totalHeight) / 2)

        return finalizeLayout(boxWidth, boxHeight, labelHeight, labelPadding, labelFont, drawX, drawY), drawTopSlot
    else
        local layoutScale = math.min(1, availableHeight / (CHAMP_LABEL_HEIGHT + CHAMP_DISPLAY_HEIGHT))
        local labelHeight = CHAMP_LABEL_HEIGHT * layoutScale
        local labelPadding = CHAMP_LABEL_PADDING * layoutScale
        local labelFont = getFont(CHAMP_LABEL_FONT_PATH, math.max(10, math.floor(CHAMP_LABEL_FONT_SIZE * layoutScale)))
        local boxWidth = CHAMP_DISPLAY_WIDTH * layoutScale
        local boxHeight = CHAMP_DISPLAY_HEIGHT * layoutScale
        local drawX = (windowWidth - boxWidth) / 2
        local totalHeight = labelHeight + boxHeight
        local drawY = math.max(0, (gridTopY - totalHeight) / 2)

        return finalizeLayout(boxWidth, boxHeight, labelHeight, labelPadding, labelFont, drawX, drawY), drawTopSlot
    end
end

function envdraw.getTopSlotHit(mouseX, mouseY, currentPhase, championDefinition, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition)
    local slots = buildTopStripLayout(championDefinition, currentPhase, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition)

    if not slots then
        return nil
    end

    for _, slot in ipairs(slots) do
        if slot.definition
            and mouseX >= slot.x
            and mouseX <= slot.x + slot.width
            and mouseY >= slot.y
            and mouseY <= slot.y + slot.labelHeight + slot.height then
            return slot.id
        end
    end

    return nil
end

function envdraw.getHoveredTopSlotDiceFace(mouseX, mouseY, currentPhase, championDefinition, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition, rollStates, expandedSlotId, expandedSlotProgress)
    local slots = buildTopStripLayout(championDefinition, currentPhase, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition)

    if not slots then
        return nil
    end

    if expandedSlotId and expandedSlotProgress and expandedSlotProgress > 0 then
        for _, slot in ipairs(slots) do
            if slot.id == expandedSlotId and slot.textbox and slot.definition then
                local textboxHeight = snap(slot.height * expandedSlotProgress)

                if textboxHeight > slot.labelHeight and carddraw.definitionHasDice(slot.definition) then
                    local textboxX = snap(slot.x)
                    local textboxY = snap(slot.y + slot.labelHeight + slot.height)
                    local textboxWidth = snap(slot.width)
                    local textboxPadding = snap(TOP_SLOT_TEXTBOX_PADDING * (slot.width / CHAMP_DISPLAY_WIDTH))
                    local anchorHeight = slot.labelHeight + slot.height + textboxHeight
                    local tooltip = carddraw.getHoveredDefinitionTextboxDiceFace(
                        slot.definition,
                        textboxX,
                        textboxY,
                        textboxWidth,
                        textboxHeight,
                        textboxPadding,
                        0,
                        false,
                        true,
                        0.9,
                        mouseX,
                        mouseY,
                        slot.x,
                        slot.y,
                        slot.width,
                        anchorHeight
                    )

                    if tooltip then
                        return tooltip
                    end
                end
            end
        end
    end

    for _, slot in ipairs(slots) do
        local rollState = rollStates and rollStates[slot.id] or nil
        local imageRect = slot.imageRect

        if slot.definition and imageRect and rollState and rollState.faceIndex then
            local badgeInset = math.max(4, snap(imageRect.width * 0.035))
            local badgeWidth = math.max(20, snap(imageRect.width * 0.115 * 1.12))
            local badgeHeaderHeight = snap(badgeWidth * 0.44)
            local badgeBodyHeight = badgeWidth
            local badgeHeight = badgeHeaderHeight + badgeBodyHeight
            local badgeX = snap(imageRect.x + imageRect.width - badgeInset - badgeWidth)
            local badgeY = snap(imageRect.y + badgeInset)

            if mouseX >= badgeX
                and mouseX <= badgeX + badgeWidth
                and mouseY >= badgeY
                and mouseY <= badgeY + badgeHeight then
                return carddraw.buildDiceFaceTooltip(
                    carddraw.getDefinitionFaceBadge(slot.definition, rollState.faceIndex),
                    imageRect.x,
                    imageRect.y,
                    imageRect.width,
                    imageRect.height
                )
            end
        end
    end

    return nil
end

function envdraw.getTopSlotRollBadgeHit(mouseX, mouseY, currentPhase, championDefinition, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition, rollStates)
    local slots = buildTopStripLayout(championDefinition, currentPhase, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition)

    if not slots then
        return nil
    end

    for _, slot in ipairs(slots) do
        local rollState = rollStates and rollStates[slot.id] or nil

        if slot.imageRect and rollState and rollState.faceIndex then
            local badgeInset = math.max(4, snap(slot.imageRect.width * 0.035))
            local badgeWidth = math.max(20, snap(slot.imageRect.width * 0.115 * 1.12))
            local badgeHeaderHeight = snap(badgeWidth * 0.44)
            local badgeBodyHeight = badgeWidth
            local badgeHeight = badgeHeaderHeight + badgeBodyHeight
            local badgeX = snap(slot.imageRect.x + slot.imageRect.width - badgeInset - badgeWidth)
            local badgeY = snap(slot.imageRect.y + badgeInset)

            if mouseX >= badgeX
                and mouseX <= badgeX + badgeWidth
                and mouseY >= badgeY
                and mouseY <= badgeY + badgeHeight then
                return slot.id
            end
        end
    end

    return nil
end

function envdraw.getTopSlotLayouts(currentPhase, championDefinition, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition, warzonePreviewState, objectivePreviewPips, intelPreviewPips)
    return buildTopStripLayout(championDefinition, currentPhase, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition, warzonePreviewState, objectivePreviewPips, intelPreviewPips) or {}
end

function envdraw.getTopSlotRollTargets(currentPhase, championDefinition, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition)
    local slots = buildTopStripLayout(championDefinition, currentPhase, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition)
    local rollTargets = {}

    if not slots then
        return rollTargets
    end

    table.sort(slots, function(a, b)
        return a.x < b.x
    end)

    for _, slot in ipairs(slots) do
        if slot.definition and carddraw.definitionHasDice(slot.definition) then
            rollTargets[#rollTargets + 1] = {
                id = slot.id,
                definition = slot.definition,
                isEnemy = slot.definition.allied ~= true,
            }
        end
    end

    return rollTargets
end

function envdraw.drawChampion(championDefinition, currentPhase, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition, expandedSlotId, expandedSlotProgress, rollStates, jitterOffsets, destructionStates, warzonePreviewState, objectivePreviewPips, intelPreviewPips, objectiveProgressEffectProgress, objectiveProgressOverlayName, objectiveProgressEffectSlotId, objectiveEscalationEffect, warzoneTransformationEffect, poiEmergenceEffect, poiFlipEffect, poiHunterTransformationEffect)
    local slots, drawTopSlot = buildTopStripLayout(championDefinition, currentPhase, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition, warzonePreviewState, objectivePreviewPips, intelPreviewPips)

    if not slots then
        return
    end

    for _, slot in ipairs(slots) do
        local jitterOffset = jitterOffsets and jitterOffsets[slot.id] or nil
        local slotX = slot.x + (jitterOffset and jitterOffset.x or 0)
        local slotY = slot.y + (jitterOffset and jitterOffset.y or 0)
        local imageRect = slot.imageRect

        if jitterOffset and imageRect then
            imageRect = {
                x = imageRect.x + jitterOffset.x,
                y = imageRect.y + jitterOffset.y,
                width = imageRect.width,
                height = imageRect.height,
            }
        end

        drawTopSlot(slotX, slotY, slot.width, slot.height, slot.labelHeight, slot.labelPadding, slot.labelFont, slot.accentColor, slot.nameColor, slot.rightTextColor, slot.nameText, slot.rightText, slot.rightPipCount, slot.maxPipCount, slot.previewPipCount, slot.previewOverlaysExisting, slot.previewExtendPipCount, slot.slotLabel, slot.image, slot.definition, imageRect, rollStates and rollStates[slot.id] or nil, destructionStates and destructionStates[slot.id] or nil, slot.hideHeader, slot.hideBodyOutline)

        if slot.id == objectiveProgressEffectSlotId and imageRect and objectiveProgressEffectProgress ~= nil and objectiveProgressOverlayName then
            carddraw.drawOverlayPulse(objectiveProgressOverlayName, imageRect.x, imageRect.y, imageRect.width, imageRect.height, objectiveProgressEffectProgress, 1)
        end

        if slot.id == "warzone" and imageRect and warzoneTransformationEffect then
            drawWarzoneTransformationTransition(imageRect, warzoneTransformationEffect)
        end

        if slot.id == "objective" and objectiveEscalationEffect then
            local effectSlot = {
                x = slotX,
                y = slotY,
                width = slot.width,
                height = slot.height,
                labelHeight = slot.labelHeight,
                labelPadding = slot.labelPadding,
                rightPipCount = slot.rightPipCount,
                maxPipCount = slot.maxPipCount,
            }

            drawObjectiveEscalationPipEffect(effectSlot, objectiveEscalationEffect)

            if imageRect then
                drawObjectiveEscalationTransition(imageRect, objectiveEscalationEffect)
            end
        end
    end

    if poiEmergenceEffect then
        local warzoneSlot = nil
        local poiSlot = nil

        for _, slot in ipairs(slots) do
            if slot.id == "warzone" then
                warzoneSlot = slot
            elseif slot.id == "poi" then
                poiSlot = slot
            end
        end

        drawPoiEmergenceEffect(warzoneSlot, poiSlot, poiEmergenceEffect)
    end

    if poiFlipEffect then
        local poiSlot = nil

        for _, slot in ipairs(slots) do
            if slot.id == "poi" then
                poiSlot = slot
                break
            end
        end

        drawPoiFlipTransition(poiSlot, poiFlipEffect)
    end

    if poiHunterTransformationEffect and poiHunterTransformationEffect.targetLocation and poiHunterTransformationEffect.targetLocation.kind ~= "hand" then
        drawPoiHunterTransformation(slots, poiHunterTransformationEffect)
    end

    if not expandedSlotId or not expandedSlotProgress or expandedSlotProgress <= 0 then
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    for _, slot in ipairs(slots) do
        if slot.id == expandedSlotId and slot.textbox then
            local textboxHeight = snap(slot.height * expandedSlotProgress)
            local textboxX = snap(slot.x)
            local textboxY = snap(slot.y + slot.labelHeight + slot.height)
            local textboxWidth = snap(slot.width)
            local textboxFontPath = slot.isFlavorTextbox and CARD_FLAVOR_FONT_PATH or TOP_SLOT_TEXTBOX_FONT_PATH
            local textboxFontSize = slot.isFlavorTextbox and TOP_SLOT_FLAVOR_FONT_SIZE or TOP_SLOT_TEXTBOX_FONT_SIZE
            local textboxFont = getFont(textboxFontPath, textboxFontSize)
            local textboxPadding = snap(TOP_SLOT_TEXTBOX_PADDING * (slot.width / CHAMP_DISPLAY_WIDTH))

            love.graphics.setColor(0.18, 0.18, 0.22, 1)
            love.graphics.rectangle("fill", textboxX, textboxY, textboxWidth, textboxHeight)
            love.graphics.setColor(slot.accentColor[1], slot.accentColor[2], slot.accentColor[3], 0.9)
            love.graphics.rectangle("line", textboxX, textboxY, textboxWidth, textboxHeight)

            if textboxHeight > (textboxPadding * 2) then
                local textAlpha = math.max(0, math.min(1, (expandedSlotProgress - 0.2) / 0.8))
                local textBottomY = textboxY + textboxHeight

                if textboxHeight > slot.labelHeight and slot.definition and (slot.definition.D1 or slot.definition.D2 or slot.definition.D3 or slot.definition.D4 or slot.definition.D5 or slot.definition.D6) then
                    local badgeTopY = carddraw.drawDefinitionTextboxBadges(slot.definition, textboxX, textboxY, textboxWidth, textboxHeight, textboxPadding, 0, false, true, 0.9)

                    if badgeTopY then
                        textBottomY = badgeTopY - snap(textboxPadding * 0.75)
                    end
                end

                love.graphics.setColor(0.93, 0.93, 0.95, textAlpha)
                love.graphics.setFont(textboxFont)
                love.graphics.setScissor(textboxX, textboxY, textboxWidth, math.max(0, textBottomY - textboxY))
                love.graphics.printf(
                    slot.textbox,
                    textboxX + textboxPadding,
                    textboxY + textboxPadding,
                    textboxWidth - (textboxPadding * 2),
                    "left"
                )
                love.graphics.setScissor()
            end

            break
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function envdraw.drawSetupModal(agentCount)
    local layout = envdraw.getSetupModalLayout(agentCount)

    if not layout then
        return
    end

    love.graphics.setColor(0.06, 0.07, 0.09, 0.94)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height, 10, 10)
    love.graphics.setColor(0.82, 0.85, 0.89, 0.78)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height, 10, 10)
    love.graphics.setColor(1, 1, 1, 1)
end

function envdraw.drawPhaseTracker(currentPhase)
    local previousFont = love.graphics.getFont()
    local phaseTrackerFont = getFont(PHASE_TRACKER_FONT_PATH, 20)
    local gridLayout = envdraw.getGridLayout()
    local gridTopY = gridLayout.rows[1] and gridLayout.rows[1].y or 0
    local trackerHeight = PHASE_TRACKER_MARKER_SIZE + ((#PHASE_TRACKER_PHASES - 1) * PHASE_TRACKER_STEP_HEIGHT)
    local phaseTrackerY = math.max(0, (gridTopY - trackerHeight) / 2)
    local markerCenterX = PHASE_TRACKER_X + (PHASE_TRACKER_MARKER_SIZE / 2)
    local labelX = PHASE_TRACKER_X + PHASE_TRACKER_MARKER_SIZE + 16
    local pulseRange = PHASE_TRACKER_PULSE_MAX - PHASE_TRACKER_PULSE_MIN
    local pulse = PHASE_TRACKER_PULSE_MIN + (((math.sin(love.timer.getTime() * PHASE_TRACKER_PULSE_SPEED) + 1) / 2) * pulseRange)

    love.graphics.setFont(phaseTrackerFont)

    if #PHASE_TRACKER_PHASES > 1 then
        local lineTop = phaseTrackerY + (PHASE_TRACKER_MARKER_SIZE / 2)
        local lineHeight = (#PHASE_TRACKER_PHASES - 1) * PHASE_TRACKER_STEP_HEIGHT

        love.graphics.setLineWidth(PHASE_TRACKER_LINE_WIDTH)
        love.graphics.setColor(0.72, 0.75, 0.8, 0.4)
        love.graphics.line(markerCenterX, lineTop, markerCenterX, lineTop + lineHeight)
    end

    for phaseIndex, phaseName in ipairs(PHASE_TRACKER_PHASES) do
        local markerY = phaseTrackerY + ((phaseIndex - 1) * PHASE_TRACKER_STEP_HEIGHT)
        local markerCenterY = markerY + (PHASE_TRACKER_MARKER_SIZE / 2)
        local markerHalfSize = PHASE_TRACKER_MARKER_SIZE / 2
        local labelY = markerY + ((PHASE_TRACKER_MARKER_SIZE - phaseTrackerFont:getHeight()) / 2)
        local isCurrentPhase = phaseName == currentPhase
        local diamondPoints = {
            markerCenterX, markerCenterY - markerHalfSize,
            markerCenterX + markerHalfSize, markerCenterY,
            markerCenterX, markerCenterY + markerHalfSize,
            markerCenterX - markerHalfSize, markerCenterY,
        }

        love.graphics.setColor(0.09, 0.1, 0.12, 0.95)
        love.graphics.polygon("fill", diamondPoints)
        love.graphics.setColor(0.9, 0.92, 0.95, 0.85)
        love.graphics.polygon("line", diamondPoints)

        if isCurrentPhase then
            local activeHalfSize = PHASE_TRACKER_ACTIVE_MARKER_SIZE / 2
            local activeDiamondPoints = {
                markerCenterX, markerCenterY - activeHalfSize,
                markerCenterX + activeHalfSize, markerCenterY,
                markerCenterX, markerCenterY + activeHalfSize,
                markerCenterX - activeHalfSize, markerCenterY,
            }

            love.graphics.setColor(0.953, 0.749, 0.208, 1)
            love.graphics.polygon("fill", activeDiamondPoints)
            love.graphics.setColor(0.953, 0.749, 0.208, pulse)
        else
            love.graphics.setColor(0.95, 0.96, 0.98, 1)
        end

        love.graphics.printf(phaseName, labelX, labelY, PHASE_TRACKER_WIDTH, "left")
    end

    love.graphics.setLineWidth(1)
    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

local function buildResourceTrackerLayout()
    local windowWidth = love.graphics.getWidth()
    local gridLayout = envdraw.getGridLayout()
    local gridTopY = gridLayout.rows[1] and gridLayout.rows[1].y or 0
    local availableHeight = math.max(1, gridTopY - (RESOURCE_TRACKER_VERTICAL_PADDING * 2))
    local metrics = getResourceGridMetrics(nil, availableHeight)
    local startX = windowWidth - RESOURCE_TRACKER_MARGIN_X - metrics.width
    local startY = math.max(0, (gridTopY - metrics.height) / 2)

    return buildResourceGridLayout(startX, startY, metrics)
end

function envdraw.getResourceTrackerLayout()
    return buildResourceTrackerLayout()
end

function envdraw.drawResourceTracker(resourceCounts)
    local layout = buildResourceTrackerLayout()
    drawResourceGrid(layout, resourceCounts)
end

function envdraw.getResourceExchangeModalLayout()
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

function envdraw.drawResourceExchangeModal(resourceCounts)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local layout = envdraw.getResourceExchangeModalLayout()

    love.graphics.setColor(0.01, 0.01, 0.02, 0.72)
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    love.graphics.setColor(0.06, 0.07, 0.09, 0.96)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height, 10, 10)
    love.graphics.setColor(0.82, 0.85, 0.89, 0.78)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height, 10, 10)
    drawResourceGrid(layout.grid, resourceCounts)
    love.graphics.setColor(1, 1, 1, 1)
end

function envdraw.getResourceExchangeModalResourceAt(mouseX, mouseY)
    local layout = envdraw.getResourceExchangeModalLayout()

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

function envdraw.getJaclDeckModalLayout(playerDeck, scrollState)
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

function envdraw.drawJaclDeckModal(playerDeck, scrollState)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local layout = envdraw.getJaclDeckModalLayout(playerDeck, scrollState)
    local previousFont = love.graphics.getFont()
    local headerFont = getFont(JACL_LABEL_FONT_PATH, 18)

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

function envdraw.getJaclDeckModalSectionAt(mouseX, mouseY, playerDeck, scrollState)
    local layout = envdraw.getJaclDeckModalLayout(playerDeck, scrollState)

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

function envdraw.getJaclDeckModalCardAt(mouseX, mouseY, playerDeck, scrollState)
    local layout = envdraw.getJaclDeckModalLayout(playerDeck, scrollState)

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

function envdraw.getJaclDeckPreviewModalLayout()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local cardWidth, cardHeight = carddraw.getExpandedCardSize()
    local x = (windowWidth - cardWidth) / 2
    local y = (windowHeight - cardHeight) / 2

    return {
        x = x,
        y = y,
        width = cardWidth,
        height = cardHeight,
    }
end

function envdraw.drawJaclDeckPreviewModal(card)
    if not card then
        return
    end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    local layout = envdraw.getJaclDeckPreviewModalLayout()

    love.graphics.setColor(0.01, 0.01, 0.02, 0.36)
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    carddraw.drawCardState(card.setName, card.cardId, layout.x, layout.y, 1, {
        displayName = card.displayName,
        portraitPath = card.portraitPath,
    })
    love.graphics.setColor(1, 1, 1, 1)
end

function envdraw.drawFullArtOverlay(image)
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
    local labelFont = getFont(JACL_LABEL_FONT_PATH, 16)
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

    love.graphics.setFont(labelFont)
    love.graphics.setColor(0.95, 0.96, 0.98, 1)
    love.graphics.printf(
        preview.label or preview.slotId or "Preview",
        layout.x + 12,
        layout.y + ((HOVER_PREVIEW_LABEL_HEIGHT - labelFont:getHeight()) / 2),
        layout.width - 24,
        "center"
    )

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

    love.graphics.setColor(1, 1, 1, 1)
end

function envdraw.drawHoverPreview(preview, drawCardStateOverlays)
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

        return
    end

    drawHoverPreviewArtPanel(preview)
end

function envdraw.getPlayerHandLayout()
    local handDefinition = envrules.getPlayerHand()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local slots = {}
    local totalWidth = HAND_SLOT_WIDTH + ((handDefinition.slots - 1) * HAND_SLOT_STEP)
    local startX = windowWidth - HAND_MARGIN_X - totalWidth
    local y = windowHeight - HAND_MARGIN_Y - HAND_SLOT_HEIGHT

    for slotIndex = 1, handDefinition.slots do
        local x = startX + ((slotIndex - 1) * HAND_SLOT_STEP)
        slots[slotIndex] = {
            x = x,
            y = y,
            width = HAND_SLOT_WIDTH,
            height = HAND_SLOT_HEIGHT,
        }
    end

    return {
        id = handDefinition.id,
        slots = slots,
    }
end

function envdraw.drawPlayerHand()
    local handLayout = envdraw.getPlayerHandLayout()
    local previousFont = love.graphics.getFont()
    local slotLabelFont = getFont(HAND_SLOT_FONT_PATH, 26)

    love.graphics.setColor(0.8, 0.84, 0.88, 0.35)

    for slotIndex, slot in ipairs(handLayout.slots) do
        local visualX = slot.x + ((slot.width - HAND_SLOT_VISUAL_WIDTH) / 2) + HAND_SLOT_VISUAL_OFFSET_X

        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", visualX, slot.y, HAND_SLOT_VISUAL_WIDTH, slot.height, 8, 8)
        love.graphics.setColor(0.8, 0.84, 0.88, 0.35)
        love.graphics.rectangle("line", visualX, slot.y, HAND_SLOT_VISUAL_WIDTH, slot.height, 8, 8)
        love.graphics.setColor(1, 0.192, 0.192, 1)
        love.graphics.setFont(slotLabelFont)
        love.graphics.printf(tostring(slotIndex), visualX, slot.y + ((slot.height - slotLabelFont:getHeight()) / 2), HAND_SLOT_VISUAL_WIDTH, "center")
        love.graphics.setColor(0.8, 0.84, 0.88, 0.35)
    end

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

function envdraw.getMulliganPromptLayout()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local handLayout = envdraw.getPlayerHandLayout()
    local firstSlot = handLayout.slots[1]
    local promptWidth = 260
    local promptHeight = 112
    local buttonWidth = 132
    local buttonHeight = 34
    local promptX = (windowWidth - promptWidth) / 2
    local promptY = firstSlot and (firstSlot.y - promptHeight - 22) or (windowHeight * 0.62)

    promptY = math.max(16, promptY)

    return {
        x = promptX,
        y = promptY,
        width = promptWidth,
        height = promptHeight,
        button = {
            x = promptX + ((promptWidth - buttonWidth) / 2),
            y = promptY + promptHeight - buttonHeight - 16,
            width = buttonWidth,
            height = buttonHeight,
        },
    }
end

function envdraw.drawMulliganPrompt(alpha)
    alpha = clamp(alpha or 1, 0, 1)

    local layout = envdraw.getMulliganPromptLayout()
    local previousFont = love.graphics.getFont()
    local titleFont = getFont(JACL_LABEL_FONT_PATH, 24)
    local buttonFont = getFont(JACL_LABEL_FONT_PATH, 14)
    local button = layout.button

    love.graphics.setColor(0.04, 0.045, 0.055, 0.96 * alpha)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height, 6, 6)
    love.graphics.setColor(0.78, 0.82, 0.88, 0.8 * alpha)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height, 6, 6)

    love.graphics.setFont(titleFont)
    love.graphics.setColor(0.95, 0.96, 0.98, alpha)
    love.graphics.printf("MULLIGAN", layout.x, layout.y + 18, layout.width, "center")

    love.graphics.setColor(0.16, 0.18, 0.22, alpha)
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 4, 4)
    love.graphics.setColor(0.86, 0.88, 0.92, 0.9 * alpha)
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 4, 4)

    love.graphics.setFont(buttonFont)
    love.graphics.setColor(0.96, 0.97, 0.99, alpha)
    love.graphics.printf("DONE", button.x, button.y + ((button.height - buttonFont:getHeight()) / 2), button.width, "center")

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

local function getHandSlotVisualBounds(slot)
    local visualX = slot.x + ((slot.width - HAND_SLOT_VISUAL_WIDTH) / 2) + HAND_SLOT_VISUAL_OFFSET_X

    return {
        x = visualX,
        y = slot.y,
        width = HAND_SLOT_VISUAL_WIDTH,
        height = slot.height,
    }
end

local function buildBottomLeftPanelLayout()
    local handLayout = envdraw.getPlayerHandLayout()
    local firstHandSlot = handLayout.slots[1]
    local panelSize = firstHandSlot and firstHandSlot.height or HAND_SLOT_HEIGHT
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

function envdraw.getBottomLeftPanelLayout(jaclDefinition)
    local layout = buildBottomLeftPanelLayout()
    local _, _, _, methodBadgeCenters, methodBadges = getJaclMethodBadgeLayout(layout, jaclDefinition and jaclDefinition.method or nil)
    layout.methodBadgeCenters = methodBadgeCenters
    layout.methodBadges = methodBadges
    return layout
end

function envdraw.getRerollButtonLayout(jaclDefinition)
    local panelLayout = envdraw.getBottomLeftPanelLayout(jaclDefinition)

    return {
        x = panelLayout.panelX,
        y = panelLayout.panelY - REROLL_BUTTON_GAP - REROLL_BUTTON_HEIGHT,
        width = panelLayout.panelSize,
        height = REROLL_BUTTON_HEIGHT,
    }
end

function envdraw.getSyntacBoxLayout(jaclDefinition)
    local handLayout = envdraw.getPlayerHandLayout()
    local firstHandSlot = handLayout.slots[1]
    local lastHandSlot = handLayout.slots[#handLayout.slots]
    local rerollLayout = envdraw.getRerollButtonLayout(jaclDefinition)

    if not firstHandSlot or not lastHandSlot then
        return {
            x = rerollLayout.x,
            y = rerollLayout.y,
            width = rerollLayout.width,
            height = rerollLayout.height,
        }
    end

    local firstVisualBounds = getHandSlotVisualBounds(firstHandSlot)
    local lastVisualBounds = getHandSlotVisualBounds(lastHandSlot)
    local rightEdge = lastVisualBounds.x + lastVisualBounds.width

    return {
        x = firstVisualBounds.x,
        y = rerollLayout.y,
        width = rightEdge - firstVisualBounds.x,
        height = rerollLayout.height,
    }
end

function envdraw.drawRerollButton(jaclDefinition, rerollCount, enabled)
    local layout = envdraw.getRerollButtonLayout(jaclDefinition)
    local labelFont = getFont(JACL_LABEL_FONT_PATH, 16)
    local valueText = tostring(rerollCount or 0)
    local labelText = "Re-Roll:"
    local gap = 8
    local labelWidth = labelFont:getWidth(labelText)
    local valueWidth = labelFont:getWidth(valueText)
    local groupWidth = labelWidth + gap + valueWidth
    local startX = snap(layout.x + ((layout.width - groupWidth) / 2))
    local textY = snap(layout.y + ((layout.height - labelFont:getHeight()) / 2))

    local drawAlpha = enabled == false and 0.46 or 0.92
    local lineAlpha = enabled == false and 0.38 or 0.78
    local textAlpha = enabled == false and 0.5 or 1

    love.graphics.setColor(0.12, 0.13, 0.16, drawAlpha)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height)
    love.graphics.setColor(0.82, 0.85, 0.89, lineAlpha)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height)

    love.graphics.setFont(labelFont)
    love.graphics.setColor(0.93, 0.93, 0.95, textAlpha)
    love.graphics.print(labelText, startX, textY)
    love.graphics.print(valueText, startX + labelWidth + gap, textY)
    love.graphics.setColor(1, 1, 1, 1)
end

function envdraw.drawSyntacBox(jaclDefinition, syntacCount)
    local layout = envdraw.getSyntacBoxLayout(jaclDefinition)
    local labelFont = getFont(JACL_LABEL_FONT_PATH, 16)
    local labelText = "SynTac"
    local pipCount = math.min(SYNTAC_BOX_MAX_PIPS, math.max(0, math.floor(tonumber(syntacCount) or 0)))
    local maxCount = SYNTAC_BOX_MAX_PIPS
    local textX = snap(layout.x + SYNTAC_BOX_LABEL_PADDING)
    local textY = snap(layout.y + ((layout.height - labelFont:getHeight()) / 2))

    love.graphics.setColor(0.12, 0.13, 0.16, 0.92)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height)
    love.graphics.setColor(0.82, 0.85, 0.89, 0.78)
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
    local pipGap = math.max(1, snap(layout.height * 0.06))
    local pipSizeByWidth = (trackerWidth - ((columnCount - 1) * pipGap)) / math.max(1, columnCount)
    local pipSizeByHeight = (trackerHeight - ((rowCount - 1) * pipGap)) / rowCount
    local pipSize = math.max(1, snap(math.min(pipSizeByWidth, pipSizeByHeight, math.max(1, layout.height * 0.34))))
    local totalGridWidth = (columnCount * pipSize) + ((columnCount - 1) * pipGap)
    local totalGridHeight = (rowCount * pipSize) + ((rowCount - 1) * pipGap)
    local startX = snap(trackerRight - totalGridWidth)
    local startY = snap(layout.y + ((layout.height - totalGridHeight) / 2))

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

    love.graphics.setColor(0.58, 0.9, 0.96, 0.45)

    for pipIndex = 0, maxCount - 1 do
        local row = math.floor(pipIndex / columnCount)
        local column = pipIndex % columnCount
        local pipX = startX + (column * (pipSize + pipGap))
        local pipY = startY + (row * (pipSize + pipGap))

        drawDiamondPip("line", pipX, pipY, pipSize)
    end

    love.graphics.setColor(0.58, 0.9, 0.96, 1)

    for pipIndex = 0, pipCount - 1 do
        local row = math.floor(pipIndex / columnCount)
        local column = pipIndex % columnCount
        local pipX = startX + (column * (pipSize + pipGap))
        local pipY = startY + (row * (pipSize + pipGap))

        drawDiamondPip("fill", pipX, pipY, pipSize)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function envdraw.drawBottomLeftPanel(jaclDefinition, resourceCounts)
    local layout = envdraw.getBottomLeftPanelLayout(jaclDefinition)
    local labelFont = getFont(JACL_LABEL_FONT_PATH, 16)
    local counterFont = getFont(RESOURCE_COUNTER_FONT_PATH, 22)
    local scratchImage = getMethodImage(JACL_SCRATCH_RESOURCE_NAME)
    local methodBadgeX, methodBadgeY, methodBadgeGap, methodBadgeCenters = getJaclMethodBadgeLayout(layout, jaclDefinition and jaclDefinition.method or nil)
    local resourceValues = resourceCounts or {}
    local jaclImage = jaclDefinition and getJaclImage(jaclDefinition.name) or nil

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
        local methodImage = getMethodImage(badgeCenter.resource)
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

function envdraw.getJaclMethodBadgeAt(mouseX, mouseY, jaclDefinition)
    local layout = envdraw.getBottomLeftPanelLayout(jaclDefinition)

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

function envdraw.drawFloatingMethodBadge(resourceName, centerX, centerY)
    local methodImage = getMethodImage(resourceName)
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

function envdraw.drawJaclSpecialTooltip(specialDefinition, previewCardDefinition, anchorX, anchorY, anchorWidth, anchorHeight)
    if not specialDefinition then
        return
    end

    local previousFont = love.graphics.getFont()
    local titleFont = getFont(JACL_LABEL_FONT_PATH, SPECIAL_TOOLTIP_TITLE_SIZE)
    local bodyFont = getFont(JACL_LABEL_FONT_PATH, SPECIAL_TOOLTIP_BODY_SIZE)
    local previewWidth, previewHeight = 0, 0

    if previewCardDefinition then
        previewWidth, previewHeight = carddraw.getExpandedCardSize()
    end

    local tooltipWidth = previewWidth > 0 and previewWidth or SPECIAL_TOOLTIP_WIDTH
    local textWidth = tooltipWidth - (SPECIAL_TOOLTIP_PADDING * 2)
    local _, wrappedBodyLines = bodyFont:getWrap(specialDefinition.text or "", textWidth)
    local titleHeight = titleFont:getHeight()
    local bodyHeight = math.max(bodyFont:getHeight(), #wrappedBodyLines * bodyFont:getHeight())
    local tooltipHeight = (SPECIAL_TOOLTIP_PADDING * 2) + titleHeight + 6 + bodyHeight
    local totalWidth = tooltipWidth
    local totalHeight = tooltipHeight + (previewCardDefinition and (SPECIAL_TOOLTIP_PREVIEW_GAP + previewHeight) or 0)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local gap = SPECIAL_TOOLTIP_OFFSET_X
    local rightX = (anchorX or 0) + (anchorWidth or 0) + gap
    local leftX = (anchorX or 0) - gap - totalWidth
    local boxX = rightX + totalWidth <= windowWidth - 8 and rightX or leftX
    local boxY = anchorY or 0
    local tooltipY = boxY + (previewCardDefinition and (previewHeight + SPECIAL_TOOLTIP_PREVIEW_GAP) or 0)

    boxX = snap(math.max(8, math.min(boxX, windowWidth - totalWidth - 8)))
    boxY = snap(math.max(8, math.min(boxY, windowHeight - totalHeight - 8)))
    tooltipY = boxY + (previewCardDefinition and (previewHeight + SPECIAL_TOOLTIP_PREVIEW_GAP) or 0)

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

    if previewCardDefinition then
        local previewX = boxX
        local previewY = boxY
        carddraw.drawCardState(previewCardDefinition.setName, previewCardDefinition.id, previewX, previewY, 1, {
            showBadgesInTextbox = true,
        })
    end

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

function envdraw.drawSummonPreviewTooltip(previewCardDefinitions, anchorX, anchorY, anchorWidth, anchorHeight, labelText)
    if not previewCardDefinitions or #previewCardDefinitions <= 0 then
        return
    end

    local previousFont = love.graphics.getFont()
    local labelFont = getFont(JACL_LABEL_FONT_PATH, SPECIAL_TOOLTIP_TITLE_SIZE)
    local previewWidth, previewHeight = carddraw.getExpandedCardSize()
    local bubbleHeight = (SPECIAL_TOOLTIP_PADDING * 2) + labelFont:getHeight()
    local previewGap = SPECIAL_TOOLTIP_PREVIEW_GAP
    local totalWidth = (#previewCardDefinitions * previewWidth) + ((#previewCardDefinitions - 1) * previewGap)
    local totalHeight = previewHeight + SPECIAL_TOOLTIP_PREVIEW_GAP + bubbleHeight
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local gap = SPECIAL_TOOLTIP_OFFSET_X
    local rightX = (anchorX or 0) + (anchorWidth or 0) + gap
    local leftX = (anchorX or 0) - gap - totalWidth
    local boxX = rightX + totalWidth <= windowWidth - 8 and rightX or leftX
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

    for previewIndex, previewCardDefinition in ipairs(previewCardDefinitions) do
        local previewX = boxX + ((previewIndex - 1) * (previewWidth + previewGap))

        carddraw.drawCardState(previewCardDefinition.setName, previewCardDefinition.id, previewX, boxY, 1, {
            showBadgesInTextbox = true,
        })
    end

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

function envdraw.drawTomeSpawnTooltip(previewCardDefinition, anchorX, anchorY, anchorWidth, anchorHeight)
    if not previewCardDefinition then
        return
    end

    envdraw.drawSummonPreviewTooltip({ previewCardDefinition }, anchorX, anchorY, anchorWidth, anchorHeight)
end

function envdraw.drawResourceTransfers(transfers)
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

return envdraw
