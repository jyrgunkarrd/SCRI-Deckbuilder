local carddraw = require("src.render.carddraw")
local cardregistry = require("src.system.cardregistry")

local huntermodal = {}

local FONT_PATH = "assets/fonts/Furore.otf"
local MODAL_MARGIN = 42
local MODAL_PADDING = 22
local HEADER_HEIGHT = 58
local FOOTER_HEIGHT = 62
local REMOVAL_PANEL_HEIGHT = 158
local REMOVAL_SLOT_SIZE = 88
local REMOVAL_SLOT_GAP = 34
local REMOVAL_ICON_SIZE = 46
local PANEL_GAP = 18
local PANEL_PADDING = 14
local CARD_GAP = 12
local EXISTING_HUNTER_CARD_MAX_WIDTH = 172
local DRAG_PREVIEW_SCALE = 0.68
local BUTTON_WIDTH = 238
local BUTTON_HEIGHT = 42
local HUNTER_RED = { 0.95, 0.12, 0.15, 1 }
local PANEL_OUTLINE = { 0.72, 0.08, 0.1, 0.92 }
local PANEL_FILL = { 0.035, 0.025, 0.03, 0.94 }
local SCANNER_ICON_PATH = "assets/images/icons/scanner.png"
local SHERIFF_PORTRAIT_PATH = "assets/images/crew/sheriff.png"
local CARD_IMAGE_DIRECTORY = "assets/images/cards/"

local fontCache = {}
local imageCache = {}
local drawCardId
local isHunterLocked

local function getFont(size)
    local key = tostring(size)

    if fontCache[key] then
        return fontCache[key]
    end

    fontCache[key] = love.graphics.newFont(FONT_PATH, size)
    return fontCache[key]
end

local function getImage(path)
    if not path then
        return nil
    end

    if imageCache[path] ~= nil then
        return imageCache[path] or nil
    end

    if not love.filesystem.getInfo(path) then
        imageCache[path] = false
        return nil
    end

    imageCache[path] = love.graphics.newImage(path, {
        mipmaps = true,
    })
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

local function getCardId(entry)
    if type(entry) == "string" then
        return entry
    end

    return type(entry) == "table" and (entry.cardId or entry.id) or nil
end

local function getRemovalSlotDefinitions(modal)
    local slots = {}

    if modal and modal.scannerPurchased then
        slots[#slots + 1] = {
            id = "scanner",
            icon = SCANNER_ICON_PATH,
        }
    end

    if modal and modal.sheriffAlive then
        slots[#slots + 1] = {
            id = "sheriff",
            icon = SHERIFF_PORTRAIT_PATH,
        }
    end

    return slots
end

local function getLayout(modal)
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local removalSlotDefinitions = getRemovalSlotDefinitions(modal)
    local hasRemovalPanel = #removalSlotDefinitions > 0
    local modalWidth = math.min(screenWidth - (MODAL_MARGIN * 2), 980)
    local modalHeight = math.min(screenHeight - (MODAL_MARGIN * 2), hasRemovalPanel and 760 or 620)
    local modalX = math.floor((screenWidth - modalWidth) * 0.5)
    local modalY = math.floor((screenHeight - modalHeight) * 0.5)
    local contentX = modalX + MODAL_PADDING
    local contentY = modalY + HEADER_HEIGHT
    local contentWidth = modalWidth - (MODAL_PADDING * 2)
    local removalPanel = hasRemovalPanel and {
        x = contentX,
        y = contentY,
        width = contentWidth,
        height = REMOVAL_PANEL_HEIGHT,
    } or nil
    local huntersY = hasRemovalPanel and (contentY + REMOVAL_PANEL_HEIGHT + PANEL_GAP) or contentY
    local contentHeight = modalHeight - HEADER_HEIGHT - FOOTER_HEIGHT - MODAL_PADDING - (hasRemovalPanel and (REMOVAL_PANEL_HEIGHT + PANEL_GAP) or 0)
    local newPanelWidth = math.floor(contentWidth * 0.34)
    local existingPanelWidth = contentWidth - newPanelWidth - PANEL_GAP
    local panelHeight = contentHeight
    local buttonX = math.floor(modalX + ((modalWidth - BUTTON_WIDTH) * 0.5))
    local buttonY = modalY + modalHeight - FOOTER_HEIGHT + 10

    local layout = {
        x = modalX,
        y = modalY,
        width = modalWidth,
        height = modalHeight,
        removalPanel = removalPanel,
        newPanel = {
            x = contentX,
            y = huntersY,
            width = newPanelWidth,
            height = panelHeight,
        },
        existingPanel = {
            x = contentX + newPanelWidth + PANEL_GAP,
            y = huntersY,
            width = existingPanelWidth,
            height = panelHeight,
        },
        button = {
            x = buttonX,
            y = buttonY,
            width = BUTTON_WIDTH,
            height = BUTTON_HEIGHT,
        },
    }

    if removalPanel then
        local totalSlotWidth = (#removalSlotDefinitions * REMOVAL_SLOT_SIZE) + ((#removalSlotDefinitions - 1) * REMOVAL_SLOT_GAP)
        local slotStartX = math.floor(removalPanel.x + ((removalPanel.width - totalSlotWidth) * 0.5))
        local slotY = math.floor(removalPanel.y + REMOVAL_ICON_SIZE + 28)

        layout.removalSlots = {}

        for slotIndex, slotDefinition in ipairs(removalSlotDefinitions) do
            layout.removalSlots[#layout.removalSlots + 1] = {
                id = slotDefinition.id,
                icon = slotDefinition.icon,
                x = slotStartX + ((slotIndex - 1) * (REMOVAL_SLOT_SIZE + REMOVAL_SLOT_GAP)),
                y = slotY,
                width = REMOVAL_SLOT_SIZE,
                height = REMOVAL_SLOT_SIZE,
                iconX = slotStartX + ((slotIndex - 1) * (REMOVAL_SLOT_SIZE + REMOVAL_SLOT_GAP)) + math.floor((REMOVAL_SLOT_SIZE - REMOVAL_ICON_SIZE) * 0.5),
                iconY = removalPanel.y + 12,
                iconSize = REMOVAL_ICON_SIZE,
            }
        end
    else
        layout.removalSlots = {}
    end

    return layout
end

local function drawPanel(rect)
    love.graphics.setColor(PANEL_FILL[1], PANEL_FILL[2], PANEL_FILL[3], PANEL_FILL[4])
    love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height, 6, 6)
    love.graphics.setColor(PANEL_OUTLINE[1], PANEL_OUTLINE[2], PANEL_OUTLINE[3], PANEL_OUTLINE[4])
    love.graphics.rectangle("line", rect.x, rect.y, rect.width, rect.height, 6, 6)
end

local function drawImageInRect(image, x, y, width, height, alpha)
    if not image then
        return
    end

    local scale = math.min(width / image:getWidth(), height / image:getHeight())
    local drawWidth = image:getWidth() * scale
    local drawHeight = image:getHeight() * scale
    local drawX = math.floor(x + ((width - drawWidth) * 0.5) + 0.5)
    local drawY = math.floor(y + ((height - drawHeight) * 0.5) + 0.5)

    love.graphics.setColor(1, 1, 1, alpha or 1)
    love.graphics.draw(image, drawX, drawY, 0, scale, scale)
end

local function drawImageCoverInRect(image, x, y, width, height, alpha)
    if not image then
        return
    end

    local scale = math.max(width / image:getWidth(), height / image:getHeight())
    local drawWidth = image:getWidth() * scale
    local drawHeight = image:getHeight() * scale
    local drawX = math.floor(x + ((width - drawWidth) * 0.5) + 0.5)
    local drawY = math.floor(y + ((height - drawHeight) * 0.5) + 0.5)
    local scissorX, scissorY, scissorWidth, scissorHeight = love.graphics.getScissor()

    love.graphics.setScissor(math.floor(x), math.floor(y), math.floor(width), math.floor(height))
    love.graphics.setColor(1, 1, 1, alpha or 1)
    love.graphics.draw(image, drawX, drawY, 0, scale, scale)

    if scissorX then
        love.graphics.setScissor(scissorX, scissorY, scissorWidth, scissorHeight)
    else
        love.graphics.setScissor()
    end
end

local function getCardPortraitImage(cardId)
    local cardDefinition = cardId and cardregistry.getCardById(cardId) or nil

    if not cardDefinition then
        return nil
    end

    local portraitId = cardDefinition.artId or cardDefinition.id
    local candidates = {
        cardDefinition.setName,
        cardDefinition.type,
        cardDefinition.type and (cardDefinition.type .. "s") or nil,
    }

    for _, directory in ipairs(candidates) do
        if directory then
            local image = getImage(CARD_IMAGE_DIRECTORY .. directory .. "/" .. portraitId .. ".png")

            if image then
                return image
            end
        end
    end

    return nil
end

local function drawCardPortraitOnly(cardId, x, y, width, height, alpha)
    drawImageCoverInRect(getCardPortraitImage(cardId), x, y, width, height, alpha)
end

local function drawRemovalPanel(layout, modal)
    if not layout.removalPanel then
        return
    end

    drawPanel(layout.removalPanel)

    for _, slot in ipairs(layout.removalSlots or {}) do
        drawImageInRect(getImage(slot.icon), slot.iconX, slot.iconY, slot.iconSize, slot.iconSize, 1)
        love.graphics.setColor(0.015, 0.014, 0.018, 1)
        love.graphics.rectangle("fill", slot.x, slot.y, slot.width, slot.height, 5, 5)
        love.graphics.setColor(HUNTER_RED[1], HUNTER_RED[2], HUNTER_RED[3], 0.78)
        love.graphics.rectangle("line", slot.x, slot.y, slot.width, slot.height, 5, 5)

        local lockedHunter = modal.lockedHunters and modal.lockedHunters[slot.id] or nil

        if lockedHunter then
            drawCardPortraitOnly(
                getCardId(lockedHunter.entry),
                slot.x + 4,
                slot.y + 4,
                slot.width - 8,
                slot.height - 8,
                0.52
            )
        end
    end
end

local function getHunterTargetAt(modal, x, y)
    for _, target in ipairs(modal and modal.cardTargets or {}) do
        if not isHunterLocked(modal, target.source, target.index) and isPointInsideRect(x, y, target) then
            return target
        end
    end

    return nil
end

local function getRemovalSlotAt(layout, x, y)
    for _, slot in ipairs(layout and layout.removalSlots or {}) do
        if isPointInsideRect(x, y, slot) then
            return slot
        end
    end

    return nil
end

drawCardId = function(cardId, x, y, width, alpha)
    local cardDefinition = cardId and cardregistry.getCardById(cardId) or nil

    if not cardDefinition then
        return
    end

    love.graphics.setColor(1, 1, 1, alpha or 1)
    carddraw.drawCardState(cardDefinition.setName, cardDefinition.id, x, y, 0, {
        width = width,
        showLabelWhenCollapsed = true,
        showHealthOnPortrait = true,
    })
end

isHunterLocked = function(modal, source, index)
    for _, lockedHunter in pairs(modal and modal.lockedHunters or {}) do
        if lockedHunter.source == source and lockedHunter.index == index then
            return true
        end
    end

    return false
end

local function drawLockedOverlay(x, y, width, height)
    love.graphics.setColor(0, 0, 0, 0.48)
    love.graphics.rectangle("fill", x, y, width, height, 6, 6)
    love.graphics.setColor(0.42, 0.44, 0.48, 0.86)
    love.graphics.line(x + 6, y + height - 6, x + width - 6, y + 6)
end

local function drawSingleNewHunter(panel, cardId, modal)
    local availableWidth = panel.width - (PANEL_PADDING * 2)
    local availableHeight = panel.height - (PANEL_PADDING * 2)
    local baseWidth, baseHeight = carddraw.getCardSize({
        width = availableWidth,
        showLabelWhenCollapsed = true,
        showHealthOnPortrait = true,
    })
    local scale = math.min(1, availableWidth / baseWidth, availableHeight / baseHeight)
    local cardWidth = math.floor(availableWidth * scale)
    local _, cardHeight = carddraw.getCardSize({
        width = cardWidth,
        showLabelWhenCollapsed = true,
        showHealthOnPortrait = true,
    })
    local cardX = math.floor(panel.x + ((panel.width - cardWidth) * 0.5))
    local cardY = math.floor(panel.y + ((panel.height - cardHeight) * 0.5))

    local locked = isHunterLocked(modal, "new", 1)

    drawCardId(cardId, cardX, cardY, cardWidth, locked and 0.42 or 1)

    if locked then
        drawLockedOverlay(cardX, cardY, cardWidth, cardHeight)
    end

    return {
        x = cardX,
        y = cardY,
        width = cardWidth,
        height = cardHeight,
        source = "new",
        index = 1,
        entry = {
            cardId = cardId,
        },
    }
end

local function drawExistingHunters(panel, entries, modal)
    local count = #(entries or {})
    local targets = {}

    if count <= 0 then
        return targets
    end

    local availableWidth = panel.width - (PANEL_PADDING * 2)
    local availableHeight = panel.height - (PANEL_PADDING * 2)
    local best = nil

    for columns = 1, count do
        local rows = math.ceil(count / columns)
        local candidateWidth = math.min(
            EXISTING_HUNTER_CARD_MAX_WIDTH,
            math.floor((availableWidth - ((columns - 1) * CARD_GAP)) / columns)
        )
        local _, candidateHeight = carddraw.getCardSize({
            width = candidateWidth,
            showLabelWhenCollapsed = true,
            showHealthOnPortrait = true,
        })

        if candidateWidth > 0
            and candidateHeight > 0
            and (rows * candidateHeight) + ((rows - 1) * CARD_GAP) <= availableHeight
            and (not best or candidateWidth > best.cardWidth) then
            best = {
                columns = columns,
                rows = rows,
                cardWidth = candidateWidth,
                cardHeight = candidateHeight,
            }
        end
    end

    if not best then
        local columns = count
        local rows = 1
        local candidateWidth = math.min(
            EXISTING_HUNTER_CARD_MAX_WIDTH,
            math.floor((availableWidth - ((columns - 1) * CARD_GAP)) / columns)
        )
        local _, candidateHeight = carddraw.getCardSize({
            width = candidateWidth,
            showLabelWhenCollapsed = true,
            showHealthOnPortrait = true,
        })

        best = {
            columns = columns,
            rows = rows,
            cardWidth = candidateWidth,
            cardHeight = candidateHeight,
        }
    end

    local totalWidth = (best.columns * best.cardWidth) + ((best.columns - 1) * CARD_GAP)
    local totalHeight = (best.rows * best.cardHeight) + ((best.rows - 1) * CARD_GAP)
    local startX = math.floor(panel.x + ((panel.width - totalWidth) * 0.5))
    local startY = math.floor(panel.y + ((panel.height - totalHeight) * 0.5))

    for entryIndex, entry in ipairs(entries) do
        local column = (entryIndex - 1) % best.columns
        local row = math.floor((entryIndex - 1) / best.columns)
        local cardX = startX + (column * (best.cardWidth + CARD_GAP))
        local cardY = startY + (row * (best.cardHeight + CARD_GAP))

        local locked = isHunterLocked(modal, "existing", entryIndex)

        drawCardId(getCardId(entry), cardX, cardY, best.cardWidth, locked and 0.42 or 1)

        if locked then
            drawLockedOverlay(cardX, cardY, best.cardWidth, best.cardHeight)
        end

        targets[#targets + 1] = {
            x = cardX,
            y = cardY,
            width = best.cardWidth,
            height = best.cardHeight,
            source = "existing",
            index = entryIndex,
            entry = entry,
        }
    end

    return targets
end

function huntermodal.open(state, options)
    if not state then
        return false
    end

    state.worldMapHunterModal = {
        newHunterId = options and options.newHunterId or "HNTINFFM",
        existingHunters = options and options.existingHunters or {},
        scannerPurchased = options and options.scannerPurchased == true,
        sheriffAlive = options and options.sheriffAlive == true,
        lockedHunters = {},
        draggingHunter = nil,
        cardTargets = {},
    }
    state.pendingWorldMapHunterModal = nil
    return true
end

function huntermodal.hasOpen(state)
    return state and state.worldMapHunterModal ~= nil or false
end

function huntermodal.update()
    return false
end

function huntermodal.mousepressed(state, x, y, button, deps)
    local modal = state and state.worldMapHunterModal or nil

    if not modal or button ~= 1 then
        return modal ~= nil
    end

    local layout = getLayout(modal)

    local hunterTarget = getHunterTargetAt(modal, x, y)

    if hunterTarget then
        modal.draggingHunter = {
            source = hunterTarget.source,
            index = hunterTarget.index,
            entry = hunterTarget.entry,
            cardId = getCardId(hunterTarget.entry),
            width = hunterTarget.width,
            offsetX = x - hunterTarget.x,
            offsetY = y - hunterTarget.y,
        }
        return true
    end

    if not isPointInsideRect(x, y, layout.button) then
        return true
    end

    if deps and deps.finalizeWorldHunterModal then
        deps.finalizeWorldHunterModal(state, modal)
    end

    state.worldMapHunterModal = nil

    if deps and deps.sfxrules and deps.sfxrules.playClick then
        deps.sfxrules.playClick()
    end

    return true
end

function huntermodal.mousereleased(state, x, y, button, deps)
    local modal = state and state.worldMapHunterModal or nil

    if not modal or button ~= 1 then
        return modal ~= nil
    end

    local draggingHunter = modal.draggingHunter

    if not draggingHunter then
        return true
    end

    local layout = getLayout(modal)
    local slot = getRemovalSlotAt(layout, x, y)

    if slot then
        modal.lockedHunters = modal.lockedHunters or {}
        modal.lockedHunters[slot.id] = {
            source = draggingHunter.source,
            index = draggingHunter.index,
            entry = draggingHunter.entry,
        }

        if deps and deps.sfxrules and deps.sfxrules.playClick then
            deps.sfxrules.playClick()
        end
    end

    modal.draggingHunter = nil
    return true
end

function huntermodal.wheelmoved(state)
    return huntermodal.hasOpen(state)
end

function huntermodal.draw(state)
    local modal = state and state.worldMapHunterModal or nil

    if not modal then
        return
    end

    local layout = getLayout(modal)
    local titleFont = getFont(24)
    local buttonFont = getFont(14)

    love.graphics.setColor(0, 0, 0, 0.72)
    love.graphics.rectangle("fill", layout.x - 8, layout.y - 8, layout.width + 16, layout.height + 16, 8, 8)
    love.graphics.setColor(0.035, 0.032, 0.038, 0.99)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height, 6, 6)
    love.graphics.setColor(HUNTER_RED[1], HUNTER_RED[2], HUNTER_RED[3], 0.95)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height, 6, 6)

    love.graphics.setFont(titleFont)
    love.graphics.setColor(HUNTER_RED[1], HUNTER_RED[2], HUNTER_RED[3], 1)
    love.graphics.printf("THEY HUNT YOU", layout.x + MODAL_PADDING, layout.y + 20, layout.width - (MODAL_PADDING * 2), "center")

    drawRemovalPanel(layout, modal)
    drawPanel(layout.newPanel)
    drawPanel(layout.existingPanel)
    modal.cardTargets = {}
    local newTarget = drawSingleNewHunter(layout.newPanel, modal.newHunterId, modal)

    if newTarget then
        modal.cardTargets[#modal.cardTargets + 1] = newTarget
    end

    for _, target in ipairs(drawExistingHunters(layout.existingPanel, modal.existingHunters, modal)) do
        modal.cardTargets[#modal.cardTargets + 1] = target
    end

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", layout.button.x, layout.button.y, layout.button.width, layout.button.height, 4, 4)
    love.graphics.setColor(HUNTER_RED[1], HUNTER_RED[2], HUNTER_RED[3], 1)
    love.graphics.rectangle("line", layout.button.x, layout.button.y, layout.button.width, layout.button.height, 4, 4)
    love.graphics.setFont(buttonFont)
    love.graphics.printf(
        "KEEPING RUNNING",
        layout.button.x,
        layout.button.y + math.floor((layout.button.height - buttonFont:getHeight()) * 0.5),
        layout.button.width,
        "center"
    )

    if modal.draggingHunter then
        local mouseX, mouseY = love.mouse.getPosition()
        local sourceWidth = modal.draggingHunter.width or 120
        local previewWidth = math.max(48, math.floor(sourceWidth * DRAG_PREVIEW_SCALE))
        local offsetScale = previewWidth / sourceWidth
        local drawX = mouseX - ((modal.draggingHunter.offsetX or 0) * offsetScale)
        local drawY = mouseY - ((modal.draggingHunter.offsetY or 0) * offsetScale)

        drawCardId(modal.draggingHunter.cardId, drawX, drawY, previewWidth, 0.82)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return huntermodal
