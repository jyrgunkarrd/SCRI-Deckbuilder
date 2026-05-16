local envrules = require("src.system.envrules")
local envassets = require("src.render.envassets")

local handdraw = {}

local JACL_LABEL_FONT_PATH = "assets/fonts/Furore.otf"
local HAND_SLOT_FONT_PATH = "assets/fonts/BITSUMIS.TTF"
local HAND_SLOT_WIDTH = 220
local HAND_SLOT_HEIGHT = 264
local HAND_SLOT_STEP = 150
local HAND_SLOT_VISUAL_WIDTH = HAND_SLOT_WIDTH * 0.5
local HAND_SLOT_VISUAL_OFFSET_X = 50
local HAND_MARGIN_X = 24
local HAND_MARGIN_Y = 24

handdraw.HAND_SLOT_HEIGHT = HAND_SLOT_HEIGHT

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

function handdraw.getPlayerHandLayout()
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

function handdraw.drawPlayerHand()
    local handLayout = handdraw.getPlayerHandLayout()
    local previousFont = love.graphics.getFont()
    local slotLabelFont = envassets.getFont(HAND_SLOT_FONT_PATH, 26)
    local safeSlotColor = { 0, 0.918, 0.765, 1 }
    local limitSlotColor = { 1, 0.188, 0.188, 1 }

    love.graphics.setColor(0.8, 0.84, 0.88, 0.35)

    for slotIndex, slot in ipairs(handLayout.slots) do
        local visualBounds = handdraw.getHandSlotVisualBounds(slot)
        local slotColor = slotIndex >= 10 and limitSlotColor or safeSlotColor

        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", visualBounds.x, slot.y, visualBounds.width, slot.height, 8, 8)
        love.graphics.setColor(slotColor[1], slotColor[2], slotColor[3], 0.75)
        love.graphics.rectangle("line", visualBounds.x, slot.y, visualBounds.width, slot.height, 8, 8)
        love.graphics.setColor(slotColor)
        love.graphics.setFont(slotLabelFont)
        love.graphics.printf(
            tostring(slotIndex),
            visualBounds.x,
            slot.y + ((slot.height - slotLabelFont:getHeight()) / 2),
            visualBounds.width,
            "center"
        )
        love.graphics.setColor(0.8, 0.84, 0.88, 0.35)
    end

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

function handdraw.getMulliganPromptLayout()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local handLayout = handdraw.getPlayerHandLayout()
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

function handdraw.drawMulliganPrompt(alpha)
    alpha = clamp(alpha or 1, 0, 1)

    local layout = handdraw.getMulliganPromptLayout()
    local previousFont = love.graphics.getFont()
    local titleFont = envassets.getFont(JACL_LABEL_FONT_PATH, 24)
    local buttonFont = envassets.getFont(JACL_LABEL_FONT_PATH, 14)
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

function handdraw.getHandSlotVisualBounds(slot)
    local visualX = slot.x + ((slot.width - HAND_SLOT_VISUAL_WIDTH) / 2) + HAND_SLOT_VISUAL_OFFSET_X

    return {
        x = visualX,
        y = slot.y,
        width = HAND_SLOT_VISUAL_WIDTH,
        height = slot.height,
    }
end

return handdraw
