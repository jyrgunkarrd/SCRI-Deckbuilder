local worldloadoutdraw = {}

local carddraw = require("src.render.carddraw")
local jaclDefinitions = require("data.jacl")
local troopDefinitions = require("data.cards.troops")

local JACL_IMAGE_DIRECTORY = "assets/images/jacl/"
local FONT_PATH = "assets/fonts/Furore.otf"

local jaclImageCache = {}
local fontCache = {}

local function getFont(size)
    local key = tostring(size)

    if fontCache[key] then
        return fontCache[key]
    end

    fontCache[key] = love.graphics.newFont(FONT_PATH, size)
    return fontCache[key]
end

local function isPointInsideRect(x, y, rect)
    return rect
        and x >= rect.x
        and x <= rect.x + rect.width
        and y >= rect.y
        and y <= rect.y + rect.height
end

local function getJaclById(jaclId)
    if not jaclId then
        return nil
    end

    for _, jaclDefinition in ipairs(jaclDefinitions or {}) do
        if jaclDefinition.id == jaclId then
            return jaclDefinition
        end
    end

    return nil
end

local function getTroopById(troopId)
    if not troopId then
        return nil
    end

    for _, troopDefinition in ipairs(troopDefinitions or {}) do
        if troopDefinition.id == troopId then
            return troopDefinition
        end
    end

    return nil
end

local function getJaclImage(jaclDefinition)
    if not jaclDefinition or not jaclDefinition.name then
        return nil
    end

    if jaclImageCache[jaclDefinition.name] ~= nil then
        return jaclImageCache[jaclDefinition.name]
    end

    local imagePath = JACL_IMAGE_DIRECTORY .. jaclDefinition.name .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        jaclImageCache[jaclDefinition.name] = false
        return nil
    end

    jaclImageCache[jaclDefinition.name] = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    jaclImageCache[jaclDefinition.name]:setFilter("linear", "linear")
    return jaclImageCache[jaclDefinition.name]
end

local function addPreviewDeckTarget(state, x, y, width, height, source)
    if not state or not source or not source.definition then
        return
    end

    state.worldMapPreviewDeckTargets = state.worldMapPreviewDeckTargets or {}
    state.worldMapPreviewDeckTargets[#state.worldMapPreviewDeckTargets + 1] = {
        x = x,
        y = y,
        width = width,
        height = height,
        definition = source.definition,
        title = source.name or source.id,
        rewardOwnerKind = source.rewardOwnerKind,
        rewardOwnerId = source.rewardOwnerId,
    }
end

local function drawPanelFrame(x, y, width, height, cornerRadius)
    cornerRadius = cornerRadius or 8

    love.graphics.setColor(0.025, 0.028, 0.035, 0.9)
    love.graphics.rectangle("fill", x, y, width, height, cornerRadius, cornerRadius)
    love.graphics.setColor(0.88, 0.9, 0.92, 0.88)
    love.graphics.rectangle("line", x, y, width, height, cornerRadius, cornerRadius)
end

local function drawJaclLoadoutCard(jaclDefinition, x, y, width, height)
    local labelHeight = math.max(28, math.floor(height - width))
    local imageHeight = height - labelHeight
    local image = getJaclImage(jaclDefinition)
    local previousFont = love.graphics.getFont()

    drawPanelFrame(x, y, width, height, 0)

    if image then
        local scale = math.min(width / image:getWidth(), imageHeight / image:getHeight())
        local imageWidth = image:getWidth() * scale
        local scaledImageHeight = image:getHeight() * scale
        local previousScissorX, previousScissorY, previousScissorWidth, previousScissorHeight = love.graphics.getScissor()

        love.graphics.setScissor(x, y, width, imageHeight)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(image, x + ((width - imageWidth) * 0.5), y + ((imageHeight - scaledImageHeight) * 0.5), 0, scale, scale)

        if previousScissorX then
            love.graphics.setScissor(previousScissorX, previousScissorY, previousScissorWidth, previousScissorHeight)
        else
            love.graphics.setScissor()
        end
    else
        love.graphics.setColor(0.16, 0.17, 0.2, 1)
        love.graphics.rectangle("fill", x, y, width, imageHeight)
    end

    love.graphics.setColor(0.02, 0.02, 0.025, 0.98)
    love.graphics.rectangle("fill", x, y + imageHeight, width, labelHeight, 0, 0)
    love.graphics.setColor(0.93, 0.93, 0.95, 1)
    love.graphics.setFont(getFont(14))
    love.graphics.printf(
        jaclDefinition and jaclDefinition.name or "JACL",
        x + 8,
        y + imageHeight + ((labelHeight - love.graphics.getFont():getHeight()) * 0.5),
        width - 16,
        "center"
    )
    love.graphics.setFont(previousFont)
end

local function drawEmptyAgentLoadoutCard(x, y, width, height)
    drawPanelFrame(x, y, width, height)
    love.graphics.setColor(0.18, 0.19, 0.22, 0.9)
    love.graphics.rectangle("fill", x + 6, y + 6, width - 12, height - 12, 6, 6)
end

local function drawAgentLoadoutNameLabel(agentDefinition, x, y, width, height)
    local nameText = agentDefinition and (agentDefinition.name or agentDefinition.id) or nil

    if not nameText then
        return
    end

    local previousFont = love.graphics.getFont()
    local labelHeight = math.max(16, math.floor(height * 0.18))
    local labelY = y + height - labelHeight
    local labelFont = getFont(math.max(8, math.floor(width * 0.105)))

    love.graphics.setColor(0.02, 0.02, 0.025, 0.88)
    love.graphics.rectangle("fill", x, labelY, width, labelHeight, 0, 0)
    love.graphics.setFont(labelFont)
    love.graphics.setColor(0.93, 0.93, 0.95, 1)
    love.graphics.printf(
        nameText,
        x + 4,
        labelY + ((labelHeight - labelFont:getHeight()) * 0.5),
        width - 8,
        "center"
    )
    love.graphics.setFont(previousFont)
end

function worldloadoutdraw.getLayout(state)
    if not state or not state.selectedRunJaclId then
        return nil
    end

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local margin = math.max(18, math.floor(math.min(screenWidth, screenHeight) * 0.025))
    local gap = 12
    local jaclWidth = math.min(220, math.max(170, math.floor(screenWidth * 0.12)))
    local jaclLabelHeight = 32
    local jaclHeight = jaclWidth + jaclLabelHeight
    local agentWidth = math.floor(jaclWidth * 0.46)
    local agentHeight = agentWidth
    local totalWidth = jaclWidth + gap + (agentWidth * 2) + gap
    local x = margin
    local y = screenHeight - margin - jaclHeight

    if totalWidth + (margin * 2) > screenWidth then
        local scale = (screenWidth - (margin * 2)) / totalWidth

        jaclWidth = math.floor(jaclWidth * scale)
        jaclLabelHeight = math.floor(jaclLabelHeight * scale)
        jaclHeight = math.floor(jaclHeight * scale)
        agentWidth = math.floor(agentWidth * scale)
        agentHeight = agentWidth
        gap = math.max(8, math.floor(gap * scale))
        y = screenHeight - margin - jaclHeight
    end

    return {
        x = x,
        y = y,
        gap = gap,
        jaclWidth = jaclWidth,
        jaclHeight = jaclHeight,
        jaclLabelHeight = jaclLabelHeight,
        agentWidth = agentWidth,
        agentHeight = agentHeight,
    }
end

function worldloadoutdraw.getDeckSourceAt(state, x, y)
    local layout = worldloadoutdraw.getLayout(state)

    if not layout then
        return nil
    end

    local jaclDefinition = getJaclById(state.selectedRunJaclId)

    if isPointInsideRect(x, y, {
        x = layout.x,
        y = layout.y,
        width = layout.jaclWidth,
        height = layout.jaclHeight - layout.jaclLabelHeight,
    }) then
        return {
            definition = jaclDefinition,
            title = jaclDefinition and jaclDefinition.name or "JACL",
            rewardOwnerKind = "jacl",
            rewardOwnerId = state.selectedRunJaclId,
        }
    end

    local agentIds = state.selectedRunAgentIds or {}

    for agentIndex = 1, 2 do
        local agentX = layout.x + layout.jaclWidth + layout.gap + ((agentIndex - 1) * (layout.agentWidth + layout.gap))
        local agentY = layout.y + layout.jaclHeight - layout.agentHeight
        local agentId = agentIds[agentIndex]
        local agentDefinition = getTroopById(agentId)

        if agentDefinition
            and carddraw.isPointInsideCard(x, y, agentX, agentY, 0, {
                width = layout.agentWidth,
                showLabelWhenCollapsed = false,
            }) then
            return {
                definition = agentDefinition,
                title = agentDefinition.name or agentDefinition.id,
                rewardOwnerKind = "agent",
                rewardOwnerId = agentId,
            }
        end
    end

    return nil
end

function worldloadoutdraw.draw(state)
    local layout = worldloadoutdraw.getLayout(state)

    if not layout then
        return
    end

    local jaclDefinition = getJaclById(state.selectedRunJaclId)
    local agentIds = state.selectedRunAgentIds or {}

    drawJaclLoadoutCard(jaclDefinition, layout.x, layout.y, layout.jaclWidth, layout.jaclHeight)
    addPreviewDeckTarget(state, layout.x, layout.y, layout.jaclWidth, layout.jaclHeight - layout.jaclLabelHeight, {
        definition = jaclDefinition,
        name = jaclDefinition and jaclDefinition.name or "JACL",
        rewardOwnerKind = "jacl",
        rewardOwnerId = state.selectedRunJaclId,
    })

    for agentIndex = 1, 2 do
        local agentX = layout.x + layout.jaclWidth + layout.gap + ((agentIndex - 1) * (layout.agentWidth + layout.gap))
        local agentY = layout.y + layout.jaclHeight - layout.agentHeight
        local agentId = agentIds[agentIndex]
        local agentDefinition = getTroopById(agentId)

        if agentDefinition then
            carddraw.drawCard("troops", agentId, agentX, agentY, {
                width = layout.agentWidth,
                showLabelWhenCollapsed = false,
            })
            drawAgentLoadoutNameLabel(agentDefinition, agentX, agentY, layout.agentWidth, layout.agentHeight)
            addPreviewDeckTarget(state, agentX, agentY, layout.agentWidth, layout.agentHeight, {
                definition = agentDefinition,
                name = agentDefinition.name or agentDefinition.id,
                rewardOwnerKind = "agent",
                rewardOwnerId = agentId,
            })
        else
            drawEmptyAgentLoadoutCard(agentX, agentY, layout.agentWidth, layout.agentHeight)
        end
    end
end

return worldloadoutdraw
