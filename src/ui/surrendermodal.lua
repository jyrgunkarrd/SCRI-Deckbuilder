local surrendermodal = {}

local RESOURCE_KEYS = { "fuel", "munitions", "tithes" }
local FONT_PATH = "assets/fonts/Furore.otf"
local MAP_IMAGE_DIRECTORY = "assets/images/map/"
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

    local path = MAP_IMAGE_DIRECTORY .. fileName

    if not love.filesystem.getInfo(path) then
        iconCache[fileName] = false
        return nil
    end

    local image = love.graphics.newImage(path, {
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

local function getSurrenderState(gameState)
    if not gameState then
        return nil
    end

    gameState.championSurrender = gameState.championSurrender or {
        offered = false,
        rejected = false,
        modal = nil,
    }

    return gameState.championSurrender
end

local function getResourceIconFile(resourceKey)
    if resourceKey == "fuel" then
        return "fuel.png"
    elseif resourceKey == "munitions" then
        return "munitions.png"
    elseif resourceKey == "tithes" then
        return "tithes.png"
    end

    return nil
end

local function getResourceDisplayName(resourceKey)
    if resourceKey == "fuel" then
        return "Fuel"
    elseif resourceKey == "munitions" then
        return "Munitions"
    elseif resourceKey == "tithes" then
        return "Tithes"
    end

    return tostring(resourceKey or "Resource")
end

local function buildOffer(basePrize, champion)
    local percent = love.math.random(50, 75) / 100
    local resourceKey = RESOURCE_KEYS[love.math.random(1, #RESOURCE_KEYS)]

    return {
        alms = math.max(0, math.floor(((tonumber(basePrize) or 0) * percent) + 0.5)),
        resourceKey = resourceKey,
        resourceAmount = love.math.random(1, 6),
        text = champion and champion.surrtext or nil,
    }
end

function surrendermodal.shouldOffer(gameState, damageResult)
    local surrenderState = getSurrenderState(gameState)
    local champion = gameState and gameState.activeChampion or nil

    if not damageResult
        or not damageResult.changed
        or damageResult.killed
        or not surrenderState
        or surrenderState.offered
        or surrenderState.rejected
        or surrenderState.modal
        or not champion then
        return false
    end

    local previousHealth = tonumber(damageResult.previousHealth) or 0
    local currentHealth = tonumber(damageResult.currentHealth) or 0
    local maxHealth = math.max(
        previousHealth,
        currentHealth,
        tonumber(champion.max) or 0,
        tonumber(champion.health) or 0
    )
    local threshold = math.ceil(maxHealth * 0.25)

    return threshold > 0
        and previousHealth > threshold
        and currentHealth > 0
        and currentHealth <= threshold
end

function surrendermodal.maybeOffer(gameState, damageResult, basePrize)
    if not surrendermodal.shouldOffer(gameState, damageResult) then
        return false
    end

    local surrenderState = getSurrenderState(gameState)

    surrenderState.offered = true
    surrenderState.modal = buildOffer(basePrize, gameState and gameState.activeChampion or nil)

    return true
end

function surrendermodal.hasOpenModal(gameState)
    return gameState
        and gameState.championSurrender
        and gameState.championSurrender.modal ~= nil
        or false
end

function surrendermodal.accept(gameState, deps)
    local surrenderState = getSurrenderState(gameState)
    local offer = surrenderState and surrenderState.modal or nil

    if not offer then
        return false
    end

    if deps and deps.setActiveMissionReward then
        deps.setActiveMissionReward({
            alms = offer.alms,
            resourceKey = offer.resourceKey,
            resourceAmount = offer.resourceAmount,
            source = "surrender",
        })
    end

    surrenderState.modal = nil

    if deps and deps.beginChampionVictoryDestruction then
        deps.beginChampionVictoryDestruction()
    end

    if deps and deps.sfxrules and deps.sfxrules.playClick then
        deps.sfxrules.playClick()
    end

    return true
end

function surrendermodal.reject(gameState, deps)
    local surrenderState = getSurrenderState(gameState)

    if not surrenderState or not surrenderState.modal then
        return false
    end

    surrenderState.modal = nil
    surrenderState.rejected = true

    if deps and deps.sfxrules and deps.sfxrules.playClick then
        deps.sfxrules.playClick()
    end

    return true
end

local function getWrappedTextHeight(font, text, width)
    local _, wrappedLines = font:getWrap(text or "", width)

    return math.max(1, #wrappedLines) * font:getHeight()
end

local function getLayout(bodyText, bodyFont)
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local modalWidth = math.min(430, screenWidth - 36)
    local modalPaddingX = 34
    local bodyY = 62
    local bodyWidth = modalWidth - (modalPaddingX * 2)
    local bodyHeight = getWrappedTextHeight(bodyFont, bodyText, bodyWidth)
    local rewardY = bodyY + bodyHeight + 24
    local resourceRewardY = rewardY + 43
    local resourceLabelY = resourceRewardY + 31
    local buttonY = resourceLabelY + 42
    local modalHeight = math.min(screenHeight - 36, buttonY + 62)
    local modalX = math.floor((screenWidth - modalWidth) * 0.5)
    local modalY = math.floor((screenHeight - modalHeight) * 0.5)
    local buttonWidth = math.floor((modalWidth - 70) * 0.5)
    local buttonHeight = 42

    return {
        x = modalX,
        y = modalY,
        width = modalWidth,
        height = modalHeight,
        bodyX = modalX + modalPaddingX,
        bodyY = modalY + bodyY,
        bodyWidth = bodyWidth,
        rewardY = modalY + rewardY,
        resourceRewardY = modalY + resourceRewardY,
        resourceLabelY = modalY + resourceLabelY,
        acceptButton = {
            x = modalX + 24,
            y = modalY + buttonY,
            width = buttonWidth,
            height = buttonHeight,
        },
        rejectButton = {
            x = modalX + modalWidth - 24 - buttonWidth,
            y = modalY + buttonY,
            width = buttonWidth,
            height = buttonHeight,
        },
    }
end

local function drawRewardRow(iconFile, valueText, x, y, width, iconSize, valueFont, color)
    local icon = getMapIcon(iconFile)
    local gap = 12
    local textWidth = valueFont:getWidth(valueText)
    local contentWidth = iconSize + gap + textWidth
    local drawX = math.floor(x + ((width - contentWidth) * 0.5) + 0.5)

    if icon then
        local scale = math.min(iconSize / icon:getWidth(), iconSize / icon:getHeight())
        local imageWidth = icon:getWidth() * scale
        local imageHeight = icon:getHeight() * scale

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            icon,
            math.floor(drawX + ((iconSize - imageWidth) * 0.5) + 0.5),
            math.floor(y + ((iconSize - imageHeight) * 0.5) + 0.5),
            0,
            scale,
            scale
        )
    end

    love.graphics.setFont(valueFont)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.print(valueText, drawX + iconSize + gap, math.floor(y + ((iconSize - valueFont:getHeight()) * 0.5) + 0.5))
end

local function drawButton(button, label, hovered, outlineColor, fillColor, textColor, font)
    love.graphics.setColor(fillColor[1], fillColor[2], fillColor[3], hovered and 1 or fillColor[4])
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 4, 4)
    love.graphics.setColor(outlineColor[1], outlineColor[2], outlineColor[3], hovered and 1 or outlineColor[4])
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 4, 4)
    love.graphics.setFont(font)
    love.graphics.setColor(textColor[1], textColor[2], textColor[3], textColor[4] or 1)
    love.graphics.printf(label, button.x, button.y + math.floor((button.height - font:getHeight()) * 0.5), button.width, "center")
end

function surrendermodal.draw(gameState)
    local modal = gameState and gameState.championSurrender and gameState.championSurrender.modal or nil

    if not modal then
        return
    end

    local titleFont = getFont(22)
    local bodyFont = getFont(12)
    local valueFont = getFont(27)
    local buttonFont = getFont(13)
    local bodyText = modal.text or "The Champion offers tribute to end the fight now."
    local layout = getLayout(bodyText, bodyFont)
    local mouseX, mouseY = love.mouse.getPosition()
    local gold = { 0.976, 0.761, 0.169, 1 }
    local red = { 0.906, 0.102, 0.176, 0.9 }
    local black = { 0.01, 0.012, 0.016, 0.94 }

    love.graphics.setColor(0, 0, 0, 0.58)
    love.graphics.rectangle("fill", layout.x - 8, layout.y - 8, layout.width + 16, layout.height + 16, 8, 8)
    love.graphics.setColor(0.055, 0.062, 0.078, 0.98)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height, 6, 6)
    love.graphics.setColor(red[1], red[2], red[3], 0.95)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height, 6, 6)

    love.graphics.setFont(titleFont)
    love.graphics.setColor(0.95, 0.96, 0.98, 1)
    love.graphics.printf("TERMS OF SURRENDER", layout.x + 24, layout.y + 24, layout.width - 48, "center")

    love.graphics.setFont(bodyFont)
    love.graphics.setColor(0.78, 0.81, 0.84, 1)
    love.graphics.printf(
        bodyText,
        layout.bodyX,
        layout.bodyY,
        layout.bodyWidth,
        "left"
    )

    drawRewardRow("alms.png", tostring(math.max(0, math.floor(tonumber(modal.alms) or 0))), layout.x, layout.rewardY, layout.width, 34, valueFont, gold)
    drawRewardRow(
        getResourceIconFile(modal.resourceKey),
        tostring(math.max(0, math.floor(tonumber(modal.resourceAmount) or 0))),
        layout.x,
        layout.resourceRewardY,
        layout.width,
        30,
        valueFont,
        { 0.95, 0.96, 0.98, 1 }
    )
    love.graphics.setFont(bodyFont)
    love.graphics.setColor(0.78, 0.81, 0.84, 1)
    love.graphics.printf(getResourceDisplayName(modal.resourceKey), layout.x + 34, layout.resourceLabelY, layout.width - 68, "center")

    drawButton(
        layout.acceptButton,
        "ACCEPT TERMS",
        isPointInsideRect(mouseX, mouseY, layout.acceptButton),
        gold,
        black,
        gold,
        buttonFont
    )
    drawButton(
        layout.rejectButton,
        "REJECT TERMS",
        isPointInsideRect(mouseX, mouseY, layout.rejectButton),
        red,
        black,
        { 0.95, 0.96, 0.98, 1 },
        buttonFont
    )

    gameState.championSurrender.acceptButtonTarget = layout.acceptButton
    gameState.championSurrender.rejectButtonTarget = layout.rejectButton
end

function surrendermodal.mousepressed(gameState, x, y, button, deps)
    local surrenderState = gameState and gameState.championSurrender or nil

    if button ~= 1 or not surrenderState or not surrenderState.modal then
        return false
    end

    if isPointInsideRect(x, y, surrenderState.acceptButtonTarget) then
        return surrendermodal.accept(gameState, deps)
    end

    if isPointInsideRect(x, y, surrenderState.rejectButtonTarget) then
        return surrendermodal.reject(gameState, deps)
    end

    return true
end

return surrendermodal
