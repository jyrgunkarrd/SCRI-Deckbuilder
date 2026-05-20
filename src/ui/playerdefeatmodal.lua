local playerdefeatmodal = {}

local FONT_PATH = "assets/fonts/Furore.otf"
local OBJECTIVE_IMAGE_DIRECTORY = "assets/images/objectives/"
local DISSOLVE_DURATION = 1.15
local MODAL_FADE_DURATION = 0.35
local MODAL_WIDTH = 620
local MODAL_PADDING = 28
local OBJECTIVE_WIDTH = 260
local BUTTON_WIDTH = 230
local BUTTON_HEIGHT = 46
local RED = { 0.95, 0.12, 0.12, 1 }

local fontCache = {}
local imageCache = {}

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function lerp(a, b, t)
    return a + ((b - a) * t)
end

local function getFont(size)
    local key = tostring(size)

    if fontCache[key] then
        return fontCache[key]
    end

    fontCache[key] = love.graphics.newFont(FONT_PATH, size)
    return fontCache[key]
end

local function getObjectiveImage(objectiveId)
    if not objectiveId then
        return nil
    end

    if imageCache[objectiveId] ~= nil then
        return imageCache[objectiveId] or nil
    end

    local imagePath = OBJECTIVE_IMAGE_DIRECTORY .. objectiveId .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        imageCache[objectiveId] = false
        return nil
    end

    local image = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    image:setFilter("linear", "linear")
    image:setMipmapFilter("linear")
    imageCache[objectiveId] = image
    return image
end

local function isPointInsideRect(x, y, rect)
    return rect
        and x >= rect.x
        and x <= rect.x + rect.width
        and y >= rect.y
        and y <= rect.y + rect.height
end

function playerdefeatmodal.open(state, objectiveDefinition, sourceRect)
    if not state or state.playerDefeat then
        return false
    end

    state.playerDefeat = {
        objective = objectiveDefinition,
        sourceRect = sourceRect,
        elapsed = 0,
        duration = DISSOLVE_DURATION,
        modalElapsed = 0,
        modalOpen = false,
        buttonTarget = nil,
    }

    return true
end

function playerdefeatmodal.hasOpen(state)
    return state and state.playerDefeat ~= nil or false
end

function playerdefeatmodal.update(state, dt)
    local defeat = state and state.playerDefeat or nil

    if not defeat then
        return false
    end

    defeat.elapsed = math.min(defeat.duration or DISSOLVE_DURATION, (defeat.elapsed or 0) + (dt or 0))

    if defeat.elapsed >= (defeat.duration or DISSOLVE_DURATION) then
        defeat.modalOpen = true
        defeat.modalElapsed = math.min(MODAL_FADE_DURATION, (defeat.modalElapsed or 0) + (dt or 0))
    end

    return true
end

local function getModalLayout(objectiveDefinition)
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local modalWidth = math.min(MODAL_WIDTH, screenWidth - 48)
    local textFont = getFont(15)
    local textWidth = modalWidth - (MODAL_PADDING * 2)
    local losstext = objectiveDefinition and objectiveDefinition.losstext or "The operation has failed."
    local _, wrappedLines = textFont:getWrap(losstext, textWidth)
    local baseTextHeight = math.min(240, math.max(140, (#wrappedLines + 2) * textFont:getHeight()))
    local objectiveHeight = OBJECTIVE_WIDTH
    local modalHeight = math.min(screenHeight - 48, MODAL_PADDING + objectiveHeight + 24 + baseTextHeight + 26 + BUTTON_HEIGHT + MODAL_PADDING)
    local modalX = math.floor((screenWidth - modalWidth) * 0.5)
    local desiredObjectiveY = math.floor((screenHeight - objectiveHeight) * 0.5)
    local modalY = math.floor(desiredObjectiveY - MODAL_PADDING)

    modalY = math.max(24, math.min(screenHeight - modalHeight - 24, modalY))

    return {
        x = modalX,
        y = modalY,
        width = modalWidth,
        height = modalHeight,
        objective = {
            x = math.floor(modalX + ((modalWidth - OBJECTIVE_WIDTH) * 0.5)),
            y = modalY + MODAL_PADDING,
            width = OBJECTIVE_WIDTH,
            height = objectiveHeight,
        },
        textX = modalX + MODAL_PADDING,
        textY = modalY + MODAL_PADDING + objectiveHeight + 24,
        textWidth = textWidth,
        button = {
            x = math.floor(modalX + ((modalWidth - BUTTON_WIDTH) * 0.5)),
            y = math.floor(modalY + modalHeight - MODAL_PADDING - BUTTON_HEIGHT),
            width = BUTTON_WIDTH,
            height = BUTTON_HEIGHT,
        },
    }
end

local function drawObjective(definition, rect, alpha)
    local image = getObjectiveImage(definition and definition.id or nil)

    love.graphics.setColor(0.08, 0.09, 0.11, alpha)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height)

    if image then
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.draw(image, rect.x, rect.y, 0, rect.width / image:getWidth(), rect.height / image:getHeight())
    else
        love.graphics.setColor(0.18, 0.19, 0.22, alpha)
        love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height)
    end

    love.graphics.setColor(RED[1], RED[2], RED[3], 0.96 * alpha)
    love.graphics.rectangle("line", rect.x, rect.y, rect.width, rect.height)
end

function playerdefeatmodal.draw(state)
    local defeat = state and state.playerDefeat or nil

    if not defeat then
        return
    end

    local objective = defeat.objective
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local progress = clamp((defeat.elapsed or 0) / math.max(0.01, defeat.duration or DISSOLVE_DURATION), 0, 1)
    local easedProgress = progress * progress * (3 - (2 * progress))
    local layout = getModalLayout(objective)
    local targetRect = layout.objective
    local sourceRect = defeat.sourceRect or targetRect
    local drawRect = {
        x = lerp(sourceRect.x, targetRect.x, easedProgress),
        y = lerp(sourceRect.y, targetRect.y, easedProgress),
        width = lerp(sourceRect.width, targetRect.width, easedProgress),
        height = lerp(sourceRect.height, targetRect.height, easedProgress),
    }

    love.graphics.setColor(0, 0, 0, 0.96 * easedProgress)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    if defeat.modalOpen then
        local modalAlpha = clamp((defeat.modalElapsed or 0) / MODAL_FADE_DURATION, 0, 1)
        local textFont = getFont(15)
        local buttonFont = getFont(16)
        local text = objective and objective.losstext or "The operation has failed."
        local button = layout.button

        love.graphics.setColor(0.015, 0.012, 0.014, 0.96 * modalAlpha)
        love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height, 6, 6)
        love.graphics.setColor(RED[1], RED[2], RED[3], 0.88 * modalAlpha)
        love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height, 6, 6)

        drawObjective(objective, targetRect, modalAlpha)

        love.graphics.setFont(textFont)
        love.graphics.setColor(0.9, 0.9, 0.92, modalAlpha)
        love.graphics.printf(text, layout.textX, layout.textY, layout.textWidth, "left")

        love.graphics.setColor(0, 0, 0, 0.95 * modalAlpha)
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 4, 4)
        love.graphics.setColor(RED[1], RED[2], RED[3], modalAlpha)
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 4, 4)
        love.graphics.setFont(buttonFont)
        love.graphics.printf("GAME OVER", button.x, button.y + math.floor((button.height - buttonFont:getHeight()) * 0.5), button.width, "center")

        defeat.buttonTarget = button
    else
        drawObjective(objective, drawRect, 1)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function playerdefeatmodal.mousepressed(state, x, y, button)
    local defeat = state and state.playerDefeat or nil

    if not defeat then
        return false
    end

    if button == 1 and defeat.modalOpen and isPointInsideRect(x, y, defeat.buttonTarget) then
        return "game_over"
    end

    return true
end

return playerdefeatmodal
