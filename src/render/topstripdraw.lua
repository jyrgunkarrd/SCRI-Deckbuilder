local topstripdraw = {}
local carddraw = require("src.render.carddraw")
local envassets = require("src.render.envassets")
local envgrid = require("src.render.envgrid")
local handdraw = require("src.render.handdraw")
local buildTopStripLayout

local JACL_LABEL_FONT_PATH = "assets/fonts/Furore.otf"
local CHAMP_LABEL_FONT_PATH = "assets/fonts/Furore.otf"
local CARD_FLAVOR_FONT_PATH = "assets/fonts/DejaVuSans-Oblique.ttf"
local JACL_METHOD_BADGE_SIZE = 42
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
local ENEMY_WARZONE_INFLUENCE_COLOR = { 1, 0.607843, 0.141176 }
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

local getJaclImage = envassets.getJaclImage
local getChampImage = envassets.getChampImage
local getObjectiveImage = envassets.getObjectiveImage
local getWarzoneImage = envassets.getWarzoneImage
local getFont = envassets.getFont
local getMethodImage = envassets.getMethodImage

local function lerp(a, b, t)
    return a + ((b - a) * t)
end

local function snap(value)
    return math.floor(value + 0.5)
end

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
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
    if not slots or not effect or not effect.generatedCardDefinition then
        return
    end

    local sourceSlot = nil
    local sourceSlotId = effect.sourceSlotId or "poi"
    local sourceRect = nil

    if sourceSlotId == "grid" and effect.sourceLocation then
        local sourceRow = envgrid.getGridRow(effect.sourceLocation.rowId)
        local sourceCell = sourceRow and sourceRow.cells and sourceRow.cells[effect.sourceLocation.column] or nil

        if sourceCell then
            sourceRect = {
                x = sourceCell.x,
                y = sourceCell.y,
                width = sourceCell.width,
                height = sourceCell.height,
            }
        end
    else
        for _, slot in ipairs(slots) do
            if slot.id == sourceSlotId then
                sourceSlot = slot
                break
            end
        end

        sourceRect = sourceSlot and sourceSlot.imageRect or nil
    end

    if not sourceRect then
        return
    end

    local progress = clamp(effect.progress or 0, 0, 1)
    local sourceImage = nil

    if sourceSlotId == "objective" and effect.sourceObjective then
        sourceImage = getObjectiveImage(effect.sourceObjective.id)
    elseif effect.sourcePoi then
        sourceImage = getWarzoneImage(effect.sourcePoi.id)
    end

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
        local handLayout = handdraw.getPlayerHandLayout()
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
    local sourceAlpha = targetLocation.kind == "hand"
        and (1 - morphProgress)
        or (1 - clamp((progress - 0.2) / 0.8, 0, 1))
    local hunterAlpha = targetLocation.kind == "hand" and morphProgress or 0
    local trailAlpha = 0.08 + (0.18 * (1 - progress))

    love.graphics.setColor(0.76, 0.9, 0.96, trailAlpha)
    love.graphics.setLineWidth(2)
    love.graphics.line(startX + (startWidth / 2), startY + (startHeight / 2), drawX + (drawWidth / 2), drawY + (drawHeight / 2))
    love.graphics.setLineWidth(1)

    if sourceImage and sourceAlpha > 0 then
        love.graphics.setColor(1, 1, 1, sourceAlpha)
        love.graphics.draw(
            sourceImage,
            drawX,
            drawY,
            0,
            drawWidth / sourceImage:getWidth(),
            drawHeight / sourceImage:getHeight()
        )
    elseif sourceSlotId == "grid" and sourceAlpha > 0 then
        carddraw.drawPortraitPreview(
            effect.generatedCardDefinition.setName,
            effect.generatedCardDefinition.id,
            drawX,
            drawY,
            drawWidth,
            drawHeight,
            sourceAlpha
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

function topstripdraw.drawPoiHunterTransformationOverlay(currentPhase, championDefinition, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition, effect, jitterOffsets)
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
    local badgeX = snap(imageRect.x + badgeInset)
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

function topstripdraw.preloadTopStripAssets(championDefinition, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition)
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

function topstripdraw.getJaclArtImage(jaclDefinition)
    return jaclDefinition and getJaclImage(jaclDefinition.name) or nil
end

function topstripdraw.getTopSlotArtImage(slotId, championDefinition, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition)
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
    local gridLayout = envgrid.getGridLayout()
    local gridTopY = gridLayout.rows[1] and gridLayout.rows[1].y or 0
    local availableHeight = math.max(1, gridTopY - (CHAMP_DISPLAY_TOP_MARGIN * 2))
    local windowWidth = love.graphics.getWidth()
    local championHealth = championDefinition and championDefinition.health and tostring(championDefinition.health) or nil
    local championHealthPips = championDefinition and championDefinition.health or nil
    local championMaxPips = championDefinition and championDefinition.max or nil
    local warzoneControl = warzoneDefinition and warzoneDefinition.control and tostring(warzoneDefinition.control) or nil
    local warzoneControlColor = warzoneDefinition and warzoneDefinition.allied ~= true
        and ENEMY_WARZONE_INFLUENCE_COLOR
        or (warzoneDefinition and (warzoneDefinition.control or 0) > 0) and TROOP_HEALTH_COLOR
        or CHAMP_ACCENT_COLOR
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

function topstripdraw.getTopSlotHit(mouseX, mouseY, currentPhase, championDefinition, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition)
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

function topstripdraw.getHoveredTopSlotDiceFace(mouseX, mouseY, currentPhase, championDefinition, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition, rollStates, expandedSlotId, expandedSlotProgress)
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

function topstripdraw.getTopSlotRollBadgeHit(mouseX, mouseY, currentPhase, championDefinition, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition, rollStates)
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

function topstripdraw.getTopSlotLayouts(currentPhase, championDefinition, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition, warzonePreviewState, objectivePreviewPips, intelPreviewPips)
    return buildTopStripLayout(championDefinition, currentPhase, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition, warzonePreviewState, objectivePreviewPips, intelPreviewPips) or {}
end

function topstripdraw.getTopSlotRollTargets(currentPhase, championDefinition, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition)
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

function topstripdraw.drawChampion(championDefinition, currentPhase, warzoneDefinition, poiDefinition, objectiveDefinition, intelDefinition, expandedSlotId, expandedSlotProgress, rollStates, jitterOffsets, destructionStates, warzonePreviewState, objectivePreviewPips, intelPreviewPips, objectiveProgressEffectProgress, objectiveProgressOverlayName, objectiveProgressEffectSlotId, objectiveEscalationEffect, warzoneTransformationEffect, poiEmergenceEffect, poiFlipEffect, poiHunterTransformationEffect)
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

return topstripdraw
