local carddraw = require("src.render.carddraw")
local cardregistry = require("src.system.cardregistry")

local crewrevivemodal = {}

local FONT_PATH = "assets/fonts/Furore.otf"
local SURGEON_IMAGE_PATH = "assets/images/crew/surgeon.png"
local MODAL_MARGIN = 42
local MODAL_PADDING = 22
local HEADER_HEIGHT = 58
local FOOTER_HEIGHT = 62
local PANEL_GAP = 18
local PANEL_PADDING = 14
local SLOT_GAP = 14
local SURGEON_SLOT_SIZE = 104
local SURGEON_ICON_SIZE = 52
local BUTTON_WIDTH = 250
local BUTTON_HEIGHT = 42
local REVIVE_COLOR = { 0.788, 0.925, 0.522, 1 }
local PANEL_FILL = { 0.035, 0.04, 0.03, 0.94 }

local fontCache = {}
local imageCache = {}

local function getFont(size)
    local key = tostring(size)

    if fontCache[key] then
        return fontCache[key]
    end

    fontCache[key] = love.graphics.newFont(FONT_PATH, size)
    return fontCache[key]
end

local function getImage(path)
    if imageCache[path] ~= nil then
        return imageCache[path] or nil
    end

    if not love.filesystem.getInfo(path) then
        imageCache[path] = false
        return nil
    end

    imageCache[path] = love.graphics.newImage(path, { mipmaps = true })
    imageCache[path]:setFilter("linear", "linear")
    return imageCache[path]
end

local function isPointInsideRect(x, y, rect)
    return rect
        and x >= rect.x
        and x <= rect.x + rect.width
        and y >= rect.y
        and y <= rect.y + rect.height
end

local function drawImageInRect(image, x, y, width, height, alpha)
    if not image then
        return
    end

    local scale = math.min(width / image:getWidth(), height / image:getHeight())
    local drawWidth = image:getWidth() * scale
    local drawHeight = image:getHeight() * scale

    love.graphics.setColor(1, 1, 1, alpha or 1)
    love.graphics.draw(
        image,
        math.floor(x + ((width - drawWidth) * 0.5) + 0.5),
        math.floor(y + ((height - drawHeight) * 0.5) + 0.5),
        0,
        scale,
        scale
    )
end

local function getCrewDefinition(roleName)
    for _, crewDefinition in ipairs(cardregistry.getSet("crew") or {}) do
        if crewDefinition.name == roleName then
            return crewDefinition
        end
    end

    return nil
end

local function getCrewPortraitPath(roleName)
    if not roleName then
        return nil
    end

    return "assets/images/crew/" .. string.lower(roleName) .. ".png"
end

local function getLayout(modal)
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local modalWidth = math.min(screenWidth - (MODAL_MARGIN * 2), 900)
    local modalHeight = math.min(screenHeight - (MODAL_MARGIN * 2), 560)
    local modalX = math.floor((screenWidth - modalWidth) * 0.5)
    local modalY = math.floor((screenHeight - modalHeight) * 0.5)
    local contentX = modalX + MODAL_PADDING
    local contentY = modalY + HEADER_HEIGHT
    local contentWidth = modalWidth - (MODAL_PADDING * 2)
    local contentHeight = modalHeight - HEADER_HEIGHT - FOOTER_HEIGHT - MODAL_PADDING
    local crewPanelWidth = math.floor(contentWidth * 0.68)
    local surgeonPanelWidth = contentWidth - crewPanelWidth - PANEL_GAP
    local buttonX = math.floor(modalX + ((modalWidth - BUTTON_WIDTH) * 0.5))
    local buttonY = modalY + modalHeight - FOOTER_HEIGHT + 10
    local surgeonPanel = {
        x = contentX + crewPanelWidth + PANEL_GAP,
        y = contentY,
        width = surgeonPanelWidth,
        height = contentHeight,
    }
    local surgeonSlotX = math.floor(surgeonPanel.x + ((surgeonPanel.width - SURGEON_SLOT_SIZE) * 0.5))
    local surgeonSlotY = math.floor(surgeonPanel.y + ((surgeonPanel.height - SURGEON_SLOT_SIZE) * 0.5) + 24)

    return {
        x = modalX,
        y = modalY,
        width = modalWidth,
        height = modalHeight,
        crewPanel = {
            x = contentX,
            y = contentY,
            width = crewPanelWidth,
            height = contentHeight,
        },
        surgeonPanel = surgeonPanel,
        surgeonSlot = {
            x = surgeonSlotX,
            y = surgeonSlotY,
            width = SURGEON_SLOT_SIZE,
            height = SURGEON_SLOT_SIZE,
        },
        button = {
            x = buttonX,
            y = buttonY,
            width = BUTTON_WIDTH,
            height = BUTTON_HEIGHT,
        },
    }
end

local function drawPanel(rect)
    love.graphics.setColor(PANEL_FILL[1], PANEL_FILL[2], PANEL_FILL[3], PANEL_FILL[4])
    love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height, 6, 6)
    love.graphics.setColor(REVIVE_COLOR[1], REVIVE_COLOR[2], REVIVE_COLOR[3], 0.78)
    love.graphics.rectangle("line", rect.x, rect.y, rect.width, rect.height, 6, 6)
end

local function drawCrewCard(roleName, x, y, width, alpha)
    local crewDefinition = getCrewDefinition(roleName)

    if not crewDefinition then
        return nil
    end

    love.graphics.setColor(1, 1, 1, alpha or 1)
    carddraw.drawCardState(crewDefinition.setName, crewDefinition.id, x, y, 0, {
        width = width,
        showLabelWhenCollapsed = true,
        showHealthOnPortrait = true,
        portraitPath = crewDefinition.portraitPath or getCrewPortraitPath(crewDefinition.name),
    })
end

local function isRoleLocked(modal, roleName)
    return modal and modal.lockedCrew and modal.lockedCrew.roleName == roleName or false
end

local function drawCrewSlots(panel, modal)
    local roles = modal.deadCrewRoles or {}
    local availableWidth = panel.width - (PANEL_PADDING * 2)
    local availableHeight = panel.height - (PANEL_PADDING * 2)
    local columns = 2
    local rows = 2
    local slotWidth = math.floor((availableWidth - SLOT_GAP) / columns)
    local slotHeight = math.floor((availableHeight - SLOT_GAP) / rows)
    local targets = {}

    for slotIndex = 1, 4 do
        local column = (slotIndex - 1) % columns
        local row = math.floor((slotIndex - 1) / columns)
        local slotX = panel.x + PANEL_PADDING + (column * (slotWidth + SLOT_GAP))
        local slotY = panel.y + PANEL_PADDING + (row * (slotHeight + SLOT_GAP))
        local roleName = roles[slotIndex]

        love.graphics.setColor(0.015, 0.018, 0.014, 1)
        love.graphics.rectangle("fill", slotX, slotY, slotWidth, slotHeight, 5, 5)
        love.graphics.setColor(REVIVE_COLOR[1], REVIVE_COLOR[2], REVIVE_COLOR[3], 0.45)
        love.graphics.rectangle("line", slotX, slotY, slotWidth, slotHeight, 5, 5)

        if roleName then
            local cardWidth = math.min(156, slotWidth - 12)
            local _, cardHeight = carddraw.getCardSize({
                width = cardWidth,
                showLabelWhenCollapsed = true,
                showHealthOnPortrait = true,
            })
            local cardX = math.floor(slotX + ((slotWidth - cardWidth) * 0.5))
            local cardY = math.floor(slotY + ((slotHeight - cardHeight) * 0.5))
            local locked = isRoleLocked(modal, roleName)

            drawCrewCard(roleName, cardX, cardY, cardWidth, locked and 0.36 or 1)

            if locked then
                love.graphics.setColor(0, 0, 0, 0.46)
                love.graphics.rectangle("fill", cardX, cardY, cardWidth, cardHeight, 6, 6)
                love.graphics.setColor(0.42, 0.44, 0.48, 0.86)
                love.graphics.line(cardX + 6, cardY + cardHeight - 6, cardX + cardWidth - 6, cardY + 6)
            end

            targets[#targets + 1] = {
                x = cardX,
                y = cardY,
                width = cardWidth,
                height = cardHeight,
                roleName = roleName,
            }
        end
    end

    return targets
end

local function drawSurgeonSlot(panel, modal)
    local slotX = math.floor(panel.x + ((panel.width - SURGEON_SLOT_SIZE) * 0.5))
    local slotY = math.floor(panel.y + ((panel.height - SURGEON_SLOT_SIZE) * 0.5) + 24)
    local iconX = math.floor(panel.x + ((panel.width - SURGEON_ICON_SIZE) * 0.5))
    local iconY = math.floor(slotY - SURGEON_ICON_SIZE - 14)

    drawImageInRect(getImage(SURGEON_IMAGE_PATH), iconX, iconY, SURGEON_ICON_SIZE, SURGEON_ICON_SIZE, 1)
    love.graphics.setColor(0.015, 0.018, 0.014, 1)
    love.graphics.rectangle("fill", slotX, slotY, SURGEON_SLOT_SIZE, SURGEON_SLOT_SIZE, 5, 5)
    love.graphics.setColor(REVIVE_COLOR[1], REVIVE_COLOR[2], REVIVE_COLOR[3], 0.82)
    love.graphics.rectangle("line", slotX, slotY, SURGEON_SLOT_SIZE, SURGEON_SLOT_SIZE, 5, 5)

    if modal.lockedCrew then
        drawCrewCard(modal.lockedCrew.roleName, slotX + 6, slotY + 6, SURGEON_SLOT_SIZE - 12, 0.52)
    end

    return nil
end

function crewrevivemodal.open(state, options)
    if not state then
        return false
    end

    state.worldMapCrewReviveModal = {
        deadCrewRoles = options and options.deadCrewRoles or {},
        lockedCrew = nil,
        draggingCrew = nil,
        crewTargets = {},
    }
    state.pendingWorldMapCrewReviveModal = nil
    return true
end

function crewrevivemodal.update()
    return false
end

function crewrevivemodal.mousepressed(state, x, y, button, deps)
    local modal = state and state.worldMapCrewReviveModal or nil

    if not modal or button ~= 1 then
        return modal ~= nil
    end

    for _, target in ipairs(modal.crewTargets or {}) do
        if not isRoleLocked(modal, target.roleName) and isPointInsideRect(x, y, target) then
            modal.draggingCrew = {
                roleName = target.roleName,
                width = target.width,
                offsetX = x - target.x,
                offsetY = y - target.y,
            }
            return true
        end
    end

    local layout = getLayout(modal)

    if isPointInsideRect(x, y, layout.button) then
        if deps and deps.finalizeWorldCrewReviveModal then
            deps.finalizeWorldCrewReviveModal(state, modal)
        end

        state.worldMapCrewReviveModal = nil
        return true
    end

    return true
end

function crewrevivemodal.mousereleased(state, x, y, button, deps)
    local modal = state and state.worldMapCrewReviveModal or nil

    if not modal or button ~= 1 then
        return modal ~= nil
    end

    if modal.draggingCrew then
        local layout = getLayout(modal)

        if isPointInsideRect(x, y, layout.surgeonSlot) then
            modal.lockedCrew = {
                roleName = modal.draggingCrew.roleName,
            }

            if deps and deps.sfxrules and deps.sfxrules.playClick then
                deps.sfxrules.playClick()
            end
        end

        modal.draggingCrew = nil
    end

    return true
end

function crewrevivemodal.wheelmoved(state)
    return state and state.worldMapCrewReviveModal ~= nil or false
end

function crewrevivemodal.draw(state)
    local modal = state and state.worldMapCrewReviveModal or nil

    if not modal then
        return
    end

    local layout = getLayout(modal)
    local titleFont = getFont(24)
    local buttonFont = getFont(14)

    love.graphics.setColor(0, 0, 0, 0.72)
    love.graphics.rectangle("fill", layout.x - 8, layout.y - 8, layout.width + 16, layout.height + 16, 8, 8)
    love.graphics.setColor(0.034, 0.04, 0.032, 0.99)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height, 6, 6)
    love.graphics.setColor(REVIVE_COLOR[1], REVIVE_COLOR[2], REVIVE_COLOR[3], 0.95)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height, 6, 6)

    love.graphics.setFont(titleFont)
    love.graphics.setColor(REVIVE_COLOR[1], REVIVE_COLOR[2], REVIVE_COLOR[3], 1)
    love.graphics.printf("THEY MIGHT LIVE", layout.x + MODAL_PADDING, layout.y + 20, layout.width - (MODAL_PADDING * 2), "center")

    drawPanel(layout.crewPanel)
    drawPanel(layout.surgeonPanel)
    modal.crewTargets = drawCrewSlots(layout.crewPanel, modal)
    drawSurgeonSlot(layout.surgeonPanel, modal)

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", layout.button.x, layout.button.y, layout.button.width, layout.button.height, 4, 4)
    love.graphics.setColor(REVIVE_COLOR[1], REVIVE_COLOR[2], REVIVE_COLOR[3], 1)
    love.graphics.rectangle("line", layout.button.x, layout.button.y, layout.button.width, layout.button.height, 4, 4)
    love.graphics.setFont(buttonFont)
    love.graphics.printf("GET ON YOUR FEET", layout.button.x, layout.button.y + math.floor((layout.button.height - buttonFont:getHeight()) * 0.5), layout.button.width, "center")

    if modal.draggingCrew then
        local mouseX, mouseY = love.mouse.getPosition()
        drawCrewCard(
            modal.draggingCrew.roleName,
            mouseX - modal.draggingCrew.offsetX,
            mouseY - modal.draggingCrew.offsetY,
            modal.draggingCrew.width,
            0.82
        )
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return crewrevivemodal
