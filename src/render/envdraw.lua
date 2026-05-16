local envdraw = {}
local envassets = require("src.render.envassets")
local envgrid = require("src.render.envgrid")
local handdraw = require("src.render.handdraw")
local jacldraw = require("src.render.jacldraw")
local previewdraw = require("src.render.previewdraw")
local resourcedraw = require("src.render.resourcedraw")
local syntacdraw = require("src.render.syntacdraw")
local topstripdraw = require("src.render.topstripdraw")

envdraw.getGridLayout = envgrid.getGridLayout
envdraw.getGridRow = envgrid.getGridRow
envdraw.getSetupModalLayout = envgrid.getSetupModalLayout
envdraw.drawGrid = envgrid.drawGrid
envdraw.drawSetupModal = envgrid.drawSetupModal
envdraw.getPlayerHandLayout = handdraw.getPlayerHandLayout
envdraw.drawPlayerHand = handdraw.drawPlayerHand
envdraw.getMulliganPromptLayout = handdraw.getMulliganPromptLayout
envdraw.drawMulliganPrompt = handdraw.drawMulliganPrompt
envdraw.getBottomLeftPanelLayout = jacldraw.getBottomLeftPanelLayout
envdraw.getRerollButtonLayout = jacldraw.getRerollButtonLayout
envdraw.drawRerollButton = jacldraw.drawRerollButton
envdraw.drawBottomLeftPanel = jacldraw.drawBottomLeftPanel
envdraw.getJaclMethodBadgeAt = jacldraw.getJaclMethodBadgeAt
envdraw.drawFloatingMethodBadge = jacldraw.drawFloatingMethodBadge
envdraw.getJaclDeckModalLayout = jacldraw.getJaclDeckModalLayout
envdraw.drawJaclDeckModal = jacldraw.drawJaclDeckModal
envdraw.getJaclDeckModalSectionAt = jacldraw.getJaclDeckModalSectionAt
envdraw.getJaclDeckModalCardAt = jacldraw.getJaclDeckModalCardAt
envdraw.getResourceTrackerLayout = resourcedraw.getResourceTrackerLayout
envdraw.getSystemBadgeColumnRect = resourcedraw.getSystemBadgeColumnRect
envdraw.drawResourceTracker = resourcedraw.drawResourceTracker
envdraw.getResourceExchangeModalLayout = resourcedraw.getResourceExchangeModalLayout
envdraw.drawResourceExchangeModal = resourcedraw.drawResourceExchangeModal
envdraw.getSyntacMethodModalLayout = resourcedraw.getSyntacMethodModalLayout
envdraw.drawSyntacMethodModal = resourcedraw.drawSyntacMethodModal
envdraw.getSyntacMethodModalResourceAt = resourcedraw.getSyntacMethodModalResourceAt
envdraw.getResourceExchangeModalResourceAt = resourcedraw.getResourceExchangeModalResourceAt
envdraw.drawResourceTransfers = resourcedraw.drawResourceTransfers
envdraw.getSyntacBoxLayout = syntacdraw.getSyntacBoxLayout
envdraw.isPointInsideSyntacBox = syntacdraw.isPointInsideSyntacBox
envdraw.getSyntacRewardButtonAt = syntacdraw.getSyntacRewardButtonAt
envdraw.getSyntacRewardButtonLayout = syntacdraw.getSyntacRewardButtonLayout
envdraw.drawSyntacBox = syntacdraw.drawSyntacBox
envdraw.drawSyntacTooltip = syntacdraw.drawSyntacTooltip
envdraw.drawSyntacRewardButtonTooltip = syntacdraw.drawSyntacRewardButtonTooltip
envdraw.drawSyntacCursorIndicator = syntacdraw.drawSyntacCursorIndicator
envdraw.getJaclDeckPreviewModalLayout = previewdraw.getJaclDeckPreviewModalLayout
envdraw.drawJaclDeckPreviewModal = previewdraw.drawJaclDeckPreviewModal
envdraw.drawFullArtOverlay = previewdraw.drawFullArtOverlay
envdraw.drawHoverPreview = previewdraw.drawHoverPreview
envdraw.drawJaclSpecialTooltip = previewdraw.drawJaclSpecialTooltip
envdraw.drawSummonPreviewTooltip = previewdraw.drawSummonPreviewTooltip
envdraw.drawTomeSpawnTooltip = previewdraw.drawTomeSpawnTooltip
envdraw.drawPoiHunterTransformationOverlay = topstripdraw.drawPoiHunterTransformationOverlay
envdraw.preloadTopStripAssets = topstripdraw.preloadTopStripAssets
envdraw.getJaclArtImage = topstripdraw.getJaclArtImage
envdraw.getTopSlotArtImage = topstripdraw.getTopSlotArtImage
envdraw.getTopSlotHit = topstripdraw.getTopSlotHit
envdraw.getHoveredTopSlotDiceFace = topstripdraw.getHoveredTopSlotDiceFace
envdraw.getTopSlotRollBadgeHit = topstripdraw.getTopSlotRollBadgeHit
envdraw.getTopSlotLayouts = topstripdraw.getTopSlotLayouts
envdraw.getTopSlotRollTargets = topstripdraw.getTopSlotRollTargets
envdraw.drawChampion = topstripdraw.drawChampion


local PHASE_TRACKER_FONT_PATH = "assets/fonts/Furore.otf"
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

local getFont = envassets.getFont

function envdraw.drawPhaseTracker(currentPhase)
    local previousFont = love.graphics.getFont()
    local phaseTrackerFont = getFont(PHASE_TRACKER_FONT_PATH, 20)
    local gridLayout = envgrid.getGridLayout()
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

return envdraw
