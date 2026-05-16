local worldrewardmodal = {}

local FONT_PATH = "assets/fonts/Furore.otf"
local MAP_IMAGE_DIRECTORY = "assets/images/map/"
local MODAL_WIDTH = 360
local MODAL_HEIGHT = 250
local MODAL_PADDING = 24
local BUTTON_WIDTH = 190
local BUTTON_HEIGHT = 42
local ICON_SIZE = 42
local COLLECT_DURATION = 0.7
local ALMS_COLOR = { 0.976, 0.761, 0.169, 1 }

local fontCache = {}
local iconCache = {}

local function getFont(size)
    local key = tostring(size)

    if fontCache[key] then
        return fontCache[key]
    end

    fontCache[key] = love.graphics.newFont(FONT_PATH, size)
    return fontCache[key]
end

local function getMapIcon(fileName)
    if not fileName then
        return nil
    end

    if iconCache[fileName] ~= nil then
        return iconCache[fileName] or nil
    end

    local imagePath = MAP_IMAGE_DIRECTORY .. fileName

    if not love.filesystem.getInfo(imagePath) then
        iconCache[fileName] = false
        return nil
    end

    local image = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    image:setFilter("linear", "linear")
    image:setMipmapFilter("linear")
    iconCache[fileName] = image
    return image
end

local function isPointInsideRect(x, y, rect)
    return rect
        and x >= rect.x
        and x <= rect.x + rect.width
        and y >= rect.y
        and y <= rect.y + rect.height
end

local function getPrize(state)
    local modal = state and state.worldMapRewardModal or nil

    return math.max(0, math.floor(tonumber(modal and (modal.displayPrize or modal.prize)) or 0))
end

local function getResourceAmount(state)
    local modal = state and state.worldMapRewardModal or nil

    return math.max(0, math.floor(tonumber(modal and (modal.displayResourceAmount or modal.resourceAmount)) or 0))
end

local function getResourceIcon(resourceKey)
    if resourceKey == "fuel" then
        return getMapIcon("fuel.png")
    elseif resourceKey == "munitions" then
        return getMapIcon("munitions.png")
    elseif resourceKey == "tithes" then
        return getMapIcon("tithes.png")
    end

    return nil
end

local function getLayout()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local modalWidth = math.min(MODAL_WIDTH, screenWidth - 32)
    local modalHeight = math.min(MODAL_HEIGHT, screenHeight - 32)
    local modalX = math.floor((screenWidth - modalWidth) * 0.5)
    local modalY = math.floor((screenHeight - modalHeight) * 0.5)
    local buttonWidth = math.min(BUTTON_WIDTH, modalWidth - (MODAL_PADDING * 2))
    local buttonHeight = BUTTON_HEIGHT

    return {
        x = modalX,
        y = modalY,
        width = modalWidth,
        height = modalHeight,
        button = {
            x = math.floor(modalX + ((modalWidth - buttonWidth) * 0.5)),
            y = math.floor(modalY + modalHeight - MODAL_PADDING - buttonHeight),
            width = buttonWidth,
            height = buttonHeight,
        },
    }
end

local function collect(state, deps)
    if not state or not state.worldMapRewardModal then
        return false
    end

    if state.worldMapRewardModal.collecting then
        return true
    end

    local prize = math.max(0, math.floor(tonumber(state.worldMapRewardModal.prize) or 0))
    local currentAlms = math.max(0, math.floor(tonumber(state.worldResources and state.worldResources.alms) or 0))
    local resourceKey = state.worldMapRewardModal.resourceKey
    local resourceAmount = math.max(0, math.floor(tonumber(state.worldMapRewardModal.resourceAmount) or 0))
    local currentResource = resourceKey
        and math.max(0, math.floor(tonumber(state.worldResources and state.worldResources[resourceKey]) or 0))
        or 0

    state.worldResources = state.worldResources or {}
    state.worldMapRewardModal.collecting = true
    state.worldMapRewardModal.elapsed = 0
    state.worldMapRewardModal.duration = COLLECT_DURATION
    state.worldMapRewardModal.startPrize = prize
    state.worldMapRewardModal.displayPrize = prize
    state.worldMapRewardModal.startAlms = currentAlms
    state.worldMapRewardModal.targetAlms = currentAlms + prize
    state.worldMapRewardModal.startResourceAmount = resourceAmount
    state.worldMapRewardModal.displayResourceAmount = resourceAmount
    state.worldMapRewardModal.startResource = currentResource
    state.worldMapRewardModal.targetResource = currentResource + resourceAmount
    state.worldMapRewardCollectButtonTarget = nil

    if deps and deps.sfxrules and deps.sfxrules.playCollect then
        deps.sfxrules.playCollect()
    elseif deps and deps.sfxrules and deps.sfxrules.playClick then
        deps.sfxrules.playClick()
    end

    return true
end

function worldrewardmodal.update(state, dt)
    local modal = state and state.worldMapRewardModal or nil

    if not modal or not modal.collecting then
        return false
    end

    local duration = math.max(0.01, modal.duration or COLLECT_DURATION)
    local elapsed = math.min(duration, (modal.elapsed or 0) + (dt or 0))
    local progress = math.max(0, math.min(1, elapsed / duration))
    local easedProgress = progress * progress * (3 - (2 * progress))
    local startPrize = math.max(0, math.floor(tonumber(modal.startPrize or modal.prize) or 0))
    local startAlms = math.max(0, math.floor(tonumber(modal.startAlms) or 0))
    local targetAlms = math.max(startAlms, math.floor(tonumber(modal.targetAlms) or (startAlms + startPrize)))
    local resourceKey = modal.resourceKey
    local startResourceAmount = math.max(0, math.floor(tonumber(modal.startResourceAmount or modal.resourceAmount) or 0))
    local startResource = math.max(0, math.floor(tonumber(modal.startResource) or 0))
    local targetResource = math.max(startResource, math.floor(tonumber(modal.targetResource) or (startResource + startResourceAmount)))

    modal.elapsed = elapsed
    modal.displayPrize = math.max(0, math.ceil(startPrize * (1 - easedProgress)))
    modal.displayResourceAmount = math.max(0, math.ceil(startResourceAmount * (1 - easedProgress)))
    state.worldResources = state.worldResources or {}
    state.worldResources.alms = math.floor(startAlms + ((targetAlms - startAlms) * easedProgress) + 0.5)

    if resourceKey and startResourceAmount > 0 then
        state.worldResources[resourceKey] = math.floor(startResource + ((targetResource - startResource) * easedProgress) + 0.5)
    end

    if progress >= 1 then
        state.worldResources.alms = targetAlms

        if resourceKey and startResourceAmount > 0 then
            state.worldResources[resourceKey] = targetResource
        end

        state.worldMapRewardModal = nil
        state.worldMapRewardCollectButtonTarget = nil
    end

    return true
end

function worldrewardmodal.mousepressed(state, x, y, button, deps)
    if not state or not state.worldMapRewardModal then
        return false
    end

    if button == 1 and state.worldMapRewardCollectButtonTarget and isPointInsideRect(x, y, state.worldMapRewardCollectButtonTarget) then
        return collect(state, deps)
    end

    return true
end

function worldrewardmodal.wheelmoved(state)
    return state and state.worldMapRewardModal ~= nil or false
end

function worldrewardmodal.draw(state)
    if not state or not state.worldMapRewardModal then
        return
    end

    local layout = getLayout()
    local titleFont = getFont(22)
    local valueFont = getFont(34)
    local buttonFont = getFont(15)
    local prize = getPrize(state)
    local prizeText = tostring(prize)
    local resourceKey = state.worldMapRewardModal.resourceKey
    local resourceAmount = getResourceAmount(state)
    local iconSize = ICON_SIZE
    local iconGap = 12
    local valueWidth = valueFont:getWidth(prizeText)
    local rewardWidth = iconSize + iconGap + valueWidth
    local rewardX = math.floor(layout.x + ((layout.width - rewardWidth) * 0.5) + 0.5)
    local rewardY = math.floor(layout.y + ((resourceKey and resourceAmount > 0 and 0.39 or 0.44) * layout.height) - (iconSize * 0.5) + 0.5)
    local almsImage = getMapIcon("alms.png")
    local resourceImage = getResourceIcon(resourceKey)
    local button = layout.button
    local mouseX, mouseY = love.mouse.getPosition()
    local buttonHovered = isPointInsideRect(mouseX, mouseY, button)

    love.graphics.setColor(0, 0, 0, 0.62)
    love.graphics.rectangle("fill", layout.x - 7, layout.y - 7, layout.width + 14, layout.height + 14, 8, 8)
    love.graphics.setColor(0.06, 0.07, 0.09, 0.98)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height, 6, 6)
    love.graphics.setColor(ALMS_COLOR[1], ALMS_COLOR[2], ALMS_COLOR[3], 0.95)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height, 6, 6)

    love.graphics.setFont(titleFont)
    love.graphics.setColor(0.95, 0.96, 0.98, 1)
    love.graphics.printf("MISSION ACCOMPLISHED", layout.x + MODAL_PADDING, layout.y + 28, layout.width - (MODAL_PADDING * 2), "center")

    if almsImage then
        local scale = math.min(iconSize / almsImage:getWidth(), iconSize / almsImage:getHeight())
        local imageWidth = almsImage:getWidth() * scale
        local imageHeight = almsImage:getHeight() * scale

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            almsImage,
            math.floor(rewardX + ((iconSize - imageWidth) * 0.5) + 0.5),
            math.floor(rewardY + ((iconSize - imageHeight) * 0.5) + 0.5),
            0,
            scale,
            scale
        )
    end

    love.graphics.setFont(valueFont)
    love.graphics.setColor(ALMS_COLOR[1], ALMS_COLOR[2], ALMS_COLOR[3], 1)
    love.graphics.print(
        prizeText,
        rewardX + iconSize + iconGap,
        math.floor(rewardY + ((iconSize - valueFont:getHeight()) * 0.5) + 0.5)
    )

    if resourceKey and resourceAmount > 0 then
        local resourceText = tostring(resourceAmount)
        local resourceWidth = iconSize + iconGap + valueFont:getWidth(resourceText)
        local resourceX = math.floor(layout.x + ((layout.width - resourceWidth) * 0.5) + 0.5)
        local resourceY = rewardY + iconSize + 14

        if resourceImage then
            local scale = math.min(iconSize / resourceImage:getWidth(), iconSize / resourceImage:getHeight())
            local imageWidth = resourceImage:getWidth() * scale
            local imageHeight = resourceImage:getHeight() * scale

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                resourceImage,
                math.floor(resourceX + ((iconSize - imageWidth) * 0.5) + 0.5),
                math.floor(resourceY + ((iconSize - imageHeight) * 0.5) + 0.5),
                0,
                scale,
                scale
            )
        end

        love.graphics.setFont(valueFont)
        love.graphics.setColor(0.95, 0.96, 0.98, 1)
        love.graphics.print(
            resourceText,
            resourceX + iconSize + iconGap,
            math.floor(resourceY + ((iconSize - valueFont:getHeight()) * 0.5) + 0.5)
        )
    end

    love.graphics.setColor(0.01, 0.012, 0.016, buttonHovered and 1 or 0.94)
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 4, 4)
    love.graphics.setColor(ALMS_COLOR[1], ALMS_COLOR[2], ALMS_COLOR[3], buttonHovered and 1 or 0.9)
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 4, 4)
    love.graphics.setFont(buttonFont)
    love.graphics.setColor(ALMS_COLOR[1], ALMS_COLOR[2], ALMS_COLOR[3], 1)
    love.graphics.printf(
        "COLLECT ALMS",
        button.x,
        button.y + math.floor((button.height - buttonFont:getHeight()) * 0.5),
        button.width,
        "center"
    )

    state.worldMapRewardCollectButtonTarget = button
end

return worldrewardmodal
