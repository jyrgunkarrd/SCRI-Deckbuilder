local carddraw = require("src.render.carddraw")

local infiltrationdraw = {}

local function lerp(a, b, t)
    return a + ((b - a) * t)
end

function infiltrationdraw.drawEffect(effect)
    if not effect or not effect.generatedCardDefinition or not effect.sourceRect then
        return
    end

    local sourceRect = effect.sourceRect
    local targetX = sourceRect.x
    local targetY = love.graphics.getHeight() + sourceRect.height

    for _, copy in ipairs(effect.copies or {}) do
        local localElapsed = effect.elapsed - (copy.delay or 0)

        if localElapsed >= 0 and localElapsed < effect.duration then
            local progress = math.min(1, localElapsed / effect.duration)
            local drawX = lerp(sourceRect.x, targetX, progress)
            local drawY = lerp(sourceRect.y, targetY, progress)
            local drawAlpha = 1 - math.max(0, (progress - 0.72) / 0.28)

            love.graphics.setColor(0.76, 0.9, 0.96, 0.08 + (0.2 * (1 - progress)))
            love.graphics.setLineWidth(2)
            love.graphics.line(
                sourceRect.x + (sourceRect.width / 2),
                sourceRect.y + (sourceRect.height / 2),
                drawX + (sourceRect.width / 2),
                drawY + (sourceRect.height / 2)
            )
            love.graphics.setLineWidth(1)

            carddraw.drawPortraitPreview(
                effect.generatedCardDefinition.setName,
                effect.generatedCardDefinition.id,
                drawX,
                drawY,
                sourceRect.width,
                sourceRect.height,
                drawAlpha
            )
        end
    end
end

return infiltrationdraw
