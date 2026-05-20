local fileselect = {}

local systemrules = require("src.system.systemrules")

local SAVE_DIRECTORY = "saves"
local FONT_PATH = "assets/fonts/Furore.otf"
local LOAD_DURATION = 0.55
local FLASH_INTERVAL = 0.06
local HOVER_EXPANSION = 28
local SLOT_IDS = {
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
}

local font = nil

local function getFont()
    if font ~= nil then
        return font
    end

    font = love.graphics.newFont(FONT_PATH, 18)
    return font
end

local function getTimestamp()
    return os.date("%Y-%m-%d %H:%M:%S")
end

local function getSlotPath(slotId)
    return string.format("%s/file_%s.txt", SAVE_DIRECTORY, slotId)
end

local function getButtonLayout()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local buttonWidth = math.min(420, screenWidth * 0.36)
    local buttonHeight = math.max(42, math.min(62, screenHeight * 0.052))
    local gap = math.max(8, screenHeight * 0.008)
    local totalHeight = (#SLOT_IDS * buttonHeight) + ((#SLOT_IDS - 1) * gap)
    local left = (screenWidth - buttonWidth) * 0.5
    local top = (screenHeight - totalHeight) * 0.54

    return left, top, buttonWidth, buttonHeight, gap
end

local function isPointInsideRect(x, y, rect)
    return x >= rect.x
        and x <= rect.x + rect.width
        and y >= rect.y
        and y <= rect.y + rect.height
end

function fileselect.getSaveSlots()
    local slots = {}

    for index, slotId in ipairs(SLOT_IDS) do
        local path = getSlotPath(slotId)
        local contents = love.filesystem.getInfo(path) and love.filesystem.read(path) or nil
        local selectedAt = contents and contents:match("selectedAt=([^\n]+)") or nil

        slots[index] = {
            id = slotId,
            path = path,
            selectedAt = selectedAt,
        }
    end

    return slots
end

local function writeSaveSlot(slotId)
    local timestamp = getTimestamp()

    love.filesystem.createDirectory(SAVE_DIRECTORY)
    love.filesystem.write(getSlotPath(slotId), string.format("slot=%s\nselectedAt=%s\n", slotId, timestamp))

    return timestamp
end

function fileselect.getSaveSlotAt(x, y)
    local left, top, buttonWidth, buttonHeight, gap = getButtonLayout()

    for index, slotId in ipairs(SLOT_IDS) do
        local rect = {
            x = left,
            y = top + ((index - 1) * (buttonHeight + gap)),
            width = buttonWidth,
            height = buttonHeight,
        }

        if isPointInsideRect(x, y, rect) then
            return slotId
        end
    end

    return nil
end

function fileselect.selectSaveSlot(state, slotId, deps)
    if not state or not slotId or state.pendingStartGame then
        return false
    end

    state.selectedSaveSlot = slotId
    state.selectedSaveTimestamp = writeSaveSlot(slotId)
    state.deadCrewRoles = {}
    state.missionDeadCrewRoles = {}
    state.worldMapFuelPayments = {}
    state.pendingDomainAwareness = nil
    state.worldMissionSystems = systemrules.createFreshSystems()
    state.worldMapSystemRepair = nil
    state.worldMapSystemRepairQueue = nil
    state.pendingWorldMapHunterModal = nil
    state.worldMapHunterModal = nil
    state.pendingWorldMapCrewReviveModal = nil
    state.worldMapCrewReviveModal = nil
    state.saveSlots = fileselect.getSaveSlots()

    if deps and deps.sfxrules and deps.sfxrules.playFileSelect then
        deps.sfxrules.playFileSelect()
    end

    state.pendingStartGame = {
        elapsed = 0,
        duration = LOAD_DURATION,
        slotId = slotId,
        timestamp = state.selectedSaveTimestamp,
    }

    return true
end

function fileselect.update(state, dt, deps)
    if not state then
        return
    end

    local mouseX, mouseY = love.mouse.getPosition()
    local previousHoveredSaveSlot = state.hoveredSaveSlot
    state.hoveredSaveSlot = fileselect.getSaveSlotAt(mouseX, mouseY)

    if state.hoveredSaveSlot
        and state.hoveredSaveSlot ~= previousHoveredSaveSlot
        and not state.pendingStartGame
        and deps
        and deps.sfxrules
        and deps.sfxrules.playClick then
        deps.sfxrules.playClick()
    end

    if not state.pendingStartGame then
        return
    end

    state.pendingStartGame.elapsed = state.pendingStartGame.elapsed + (dt or 0)

    if state.pendingStartGame.elapsed < state.pendingStartGame.duration then
        return
    end

    state.pendingStartGame = nil
    state.current = "WorldStage"
end

function fileselect.keypressed(_, key)
    if key == "escape" then
        love.event.quit()
        return true
    end

    return false
end

function fileselect.mousepressed(state, x, y, button, deps)
    if button ~= 1 then
        return false
    end

    return fileselect.selectSaveSlot(state, fileselect.getSaveSlotAt(x, y), deps)
end

function fileselect.draw(state)
    local screenWidth = love.graphics.getWidth()
    local left, top, buttonWidth, buttonHeight, gap = getButtonLayout()
    local titleY = math.max(44, top - 104)
    local previousFont = love.graphics.getFont()
    local fileSelectFont = getFont()
    local slotsById = {}

    love.graphics.setFont(fileSelectFont)
    for _, slot in ipairs(state and state.saveSlots or {}) do
        slotsById[slot.id] = slot
    end

    love.graphics.clear(0.045, 0.047, 0.055, 1)
    love.graphics.setColor(0.92, 0.94, 0.9, 1)
    love.graphics.printf("Select File", 0, titleY, screenWidth, "center")
    love.graphics.setColor(0.54, 0.58, 0.62, 1)
    love.graphics.printf("Choose a save slot to begin", 0, titleY + 34, screenWidth, "center")

    for index, slotId in ipairs(SLOT_IDS) do
        local y = top + ((index - 1) * (buttonHeight + gap))
        local isHovered = state and state.hoveredSaveSlot == slotId
        local slot = slotsById[slotId]
        local hoverExpansion = isHovered and not (state and state.pendingStartGame) and HOVER_EXPANSION or 0
        local buttonX = left - hoverExpansion
        local expandedButtonWidth = buttonWidth + hoverExpansion

        love.graphics.setColor(0, 0, 0, 1)

        love.graphics.rectangle("fill", buttonX, y, expandedButtonWidth, buttonHeight, 3, 3)
        if state
            and state.pendingStartGame
            and state.pendingStartGame.slotId == slotId
            and (math.floor(state.pendingStartGame.elapsed / FLASH_INTERVAL) % 2 == 0) then
            love.graphics.setColor(1, 0.73, 0.08, 1)
        elseif state and state.pendingStartGame and state.pendingStartGame.slotId == slotId then
            love.graphics.setColor(0, 0, 0, 1)
        else
            love.graphics.setColor(0.11, 0.49, 0.55, 1)
        end
        love.graphics.rectangle("line", buttonX, y, expandedButtonWidth, buttonHeight, 3, 3)
        love.graphics.setColor(0.95, 0.28, 0.15, 1)
        love.graphics.printf("FILE " .. slotId, buttonX + 20, y + 10, expandedButtonWidth - 40, "left")

        if slot and slot.selectedAt then
            love.graphics.setColor(0.56, 0.62, 0.64, 1)
            love.graphics.printf(slot.selectedAt, buttonX + 20, y + 32, expandedButtonWidth - 40, "left")
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(previousFont)
end

return fileselect
