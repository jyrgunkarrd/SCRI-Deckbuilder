local targetingrules = require("src.system.targetingrules")

local targetoverlays = {}

local TARGET_BRACKET_PULSE_SPEED = 4.8
local TARGET_BRACKET_ALPHA_MIN = 0.42
local TARGET_BRACKET_ALPHA_MAX = 0.95
local TARGET_BRACKET_COLOR = { 1, 0.298, 0.298, 1 }
local STRATEGY_TARGET_BRACKET_COLOR = { 0.953, 0.749, 0.208, 1 }

function targetoverlays.drawBrackets(drawX, drawY, width, height, color)
    local pulseRange = TARGET_BRACKET_ALPHA_MAX - TARGET_BRACKET_ALPHA_MIN
    local pulseAlpha = TARGET_BRACKET_ALPHA_MIN + (((math.sin(love.timer.getTime() * TARGET_BRACKET_PULSE_SPEED) + 1) / 2) * pulseRange)
    local inset = 4
    local bracketLength = math.max(16, math.min(width, height) * 0.16)
    local x1 = drawX - inset
    local y1 = drawY - inset
    local x2 = drawX + width + inset
    local y2 = drawY + height + inset
    local bracketColor = color or TARGET_BRACKET_COLOR

    love.graphics.setColor(bracketColor[1], bracketColor[2], bracketColor[3], pulseAlpha)
    love.graphics.setLineWidth(3)
    love.graphics.line(x1, y1, x1 + bracketLength, y1)
    love.graphics.line(x1, y1, x1, y1 + bracketLength)
    love.graphics.line(x2, y1, x2 - bracketLength, y1)
    love.graphics.line(x2, y1, x2, y1 + bracketLength)
    love.graphics.line(x1, y2, x1 + bracketLength, y2)
    love.graphics.line(x1, y2, x1, y2 - bracketLength)
    love.graphics.line(x2, y2, x2 - bracketLength, y2)
    love.graphics.line(x2, y2, x2, y2 - bracketLength)
    love.graphics.setLineWidth(1)
end

function targetoverlays.getDefaultBracketColor()
    return TARGET_BRACKET_COLOR
end

function targetoverlays.getStrategyBracketColor()
    return STRATEGY_TARGET_BRACKET_COLOR
end

function targetoverlays.drawTopSlotBrackets(slots, context)
    if not context or (not context.hoveredCardIndex and not context.hoveredTopSlotId) then
        return
    end

    for _, slot in ipairs(slots or {}) do
        if slot.definition and targetingrules.shouldBracketTopSlot(slot.id, context) then
            targetoverlays.drawBrackets(slot.x, slot.y, slot.width, slot.labelHeight + slot.height)
        end
    end
end

return targetoverlays
