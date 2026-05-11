local targetingrules = require("src.system.targetingrules")

local targetoverlays = {}

local TARGET_BRACKET_PULSE_SPEED = 4.8
local TARGET_BRACKET_ALPHA_MIN = 0.42
local TARGET_BRACKET_ALPHA_MAX = 0.95
local TARGET_BRACKET_COLOR = { 1, 0.298, 0.298, 1 }
local STRATEGY_TARGET_BRACKET_COLOR = { 0.953, 0.749, 0.208, 1 }

local function drawSegmentedLine(x1, y1, x2, y2, dashLength, gapLength)
    if x1 == x2 then
        local direction = y2 >= y1 and 1 or -1
        local position = y1

        while (direction > 0 and position < y2) or (direction < 0 and position > y2) do
            local segmentEnd = position + (direction * dashLength)

            if direction > 0 then
                segmentEnd = math.min(segmentEnd, y2)
            else
                segmentEnd = math.max(segmentEnd, y2)
            end

            love.graphics.line(x1, position, x2, segmentEnd)
            position = segmentEnd + (direction * gapLength)
        end
    else
        local direction = x2 >= x1 and 1 or -1
        local position = x1

        while (direction > 0 and position < x2) or (direction < 0 and position > x2) do
            local segmentEnd = position + (direction * dashLength)

            if direction > 0 then
                segmentEnd = math.min(segmentEnd, x2)
            else
                segmentEnd = math.max(segmentEnd, x2)
            end

            love.graphics.line(position, y1, segmentEnd, y2)
            position = segmentEnd + (direction * gapLength)
        end
    end
end

local function drawBracketLines(drawX, drawY, width, height, color, alpha, lineWidth, inset, options)
    local drawOptions = options or {}
    local bracketLength = math.max(16, math.min(width, height) * 0.16) * (drawOptions.bracketLengthScale or 1)
    local x1 = drawX - inset
    local y1 = drawY - inset
    local x2 = drawX + width + inset
    local y2 = drawY + height + inset
    local dotted = drawOptions.dotted == true
    local dashLength = drawOptions.dashLength or 6
    local gapLength = drawOptions.gapLength or 5

    love.graphics.setColor(color[1], color[2], color[3], alpha)
    love.graphics.setLineWidth(lineWidth)

    local function drawLine(ax, ay, bx, by)
        if dotted then
            drawSegmentedLine(ax, ay, bx, by, dashLength, gapLength)
        else
            love.graphics.line(ax, ay, bx, by)
        end
    end

    drawLine(x1, y1, x1 + bracketLength, y1)
    drawLine(x1, y1, x1, y1 + bracketLength)
    drawLine(x2, y1, x2 - bracketLength, y1)
    drawLine(x2, y1, x2, y1 + bracketLength)
    drawLine(x1, y2, x1 + bracketLength, y2)
    drawLine(x1, y2, x1, y2 - bracketLength)
    drawLine(x2, y2, x2 - bracketLength, y2)
    drawLine(x2, y2, x2, y2 - bracketLength)
end

function targetoverlays.drawBrackets(drawX, drawY, width, height, color, options)
    local pulseRange = TARGET_BRACKET_ALPHA_MAX - TARGET_BRACKET_ALPHA_MIN
    local pulseAlpha = TARGET_BRACKET_ALPHA_MIN + (((math.sin(love.timer.getTime() * TARGET_BRACKET_PULSE_SPEED) + 1) / 2) * pulseRange)
    local bracketColor = color or TARGET_BRACKET_COLOR
    local drawOptions = options or {}
    local inset = drawOptions.inset or 4
    local lineWidth = drawOptions.lineWidth or 3

    drawBracketLines(drawX, drawY, width, height, bracketColor, pulseAlpha, lineWidth, inset, drawOptions)
    love.graphics.setLineWidth(1)
end

function targetoverlays.getDefaultBracketColor()
    return TARGET_BRACKET_COLOR
end

function targetoverlays.getStrategyBracketColor()
    return STRATEGY_TARGET_BRACKET_COLOR
end

function targetoverlays.drawTopSlotBrackets(slots, context)
    if not context
        or (
            not context.hoveredCardIndex
            and not context.hoveredTopSlotId
            and not context.selectedAttackerCardIndex
            and not context.primedActivatedAbility
        ) then
        return
    end

    for _, slot in ipairs(slots or {}) do
        if slot.definition and targetingrules.shouldBracketTopSlot(slot.id, context) then
            local bracketLayers = targetingrules.getTopSlotBracketLayers(slot.id, context)

            for _, bracketColorName in ipairs(bracketLayers) do
                if bracketColorName == "strategy" or bracketColorName == "strategy_hover" then
                    targetoverlays.drawBrackets(
                        slot.x,
                        slot.y,
                        slot.width,
                        slot.labelHeight + slot.height,
                        bracketColorName == "strategy_hover"
                            and targetoverlays.getDefaultBracketColor()
                            or targetoverlays.getStrategyBracketColor(),
                        {
                            bracketLengthScale = 0.5,
                        }
                    )
                else
                    targetoverlays.drawBrackets(
                        slot.x,
                        slot.y,
                        slot.width,
                        slot.labelHeight + slot.height,
                        targetoverlays.getDefaultBracketColor(),
                        {
                            dotted = true,
                        }
                    )
                end
            end
        end
    end
end

return targetoverlays
