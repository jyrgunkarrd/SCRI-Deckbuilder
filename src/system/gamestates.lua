local gamestates = {}

local fileselect = require("src.states.fileselect")
local worldmapdraw = require("src.render.worldmapdraw")
local runsetupmodal = require("src.ui.runsetupmodal")

function gamestates.create()
    return {
        current = "FileSelect",
        hoveredSaveSlot = nil,
        previousHoveredSaveSlot = nil,
        saveSlots = fileselect.getSaveSlots(),
        selectedSaveSlot = nil,
        selectedSaveTimestamp = nil,
        pendingStartGame = nil,
        runSetupModal = nil,
        selectedRunPackageIndex = nil,
        selectedRunJaclId = nil,
        selectedRunAgentIds = {},
        selectedRunPackage = nil,
        worldResources = {
            alms = 0,
            fuel = 0,
            munitions = 0,
            tithes = 0,
        },
    }
end

function gamestates.isFileSelect(state)
    return state and state.current == "FileSelect"
end

function gamestates.isMissionStage(state)
    return state and state.current == "MissionStage"
end

function gamestates.isWorldStage(state)
    return state and state.current == "WorldStage"
end

function gamestates.advancePlayerMapPosition(state)
    if not state then
        return nil
    end

    local nextMapPosition = gamestates.getNextPlayerMapPosition(state)

    if nextMapPosition then
        state.playerMapPosition = nextMapPosition
    end

    return nextMapPosition
end

function gamestates.getNextPlayerMapPosition(state)
    if not state then
        return nil
    end

    return worldmapdraw.getNextMapPosition(state.playerMapPosition)
end

function gamestates.updateFileSelect(state, dt, deps)
    fileselect.update(state, dt, deps)

    if gamestates.isWorldStage(state) then
        runsetupmodal.ensure(state)
    end
end

function gamestates.getSaveSlotAt(x, y)
    return fileselect.getSaveSlotAt(x, y)
end

function gamestates.selectSaveSlot(state, slotId, deps)
    return fileselect.selectSaveSlot(state, slotId, deps)
end

function gamestates.updateWorldStage(state, dt, deps)
    runsetupmodal.ensure(state)
    runsetupmodal.update(state, dt, deps)

    if state.runSetupModal and state.runSetupModal.isOpen then
        state.hoveredWorldMapNode = nil
        state.pinnedWorldMapNode = nil
        state.worldMapDeckModal = nil
        state.worldMapObjectivePreviewModal = nil
        state.worldMapNodePlayButtonTarget = nil
        state.worldMapNodePlayButtonTargets = nil
        return
    end

    worldmapdraw.updateHover(state, deps)
end

function gamestates.keypressedFileSelect(_, key)
    return fileselect.keypressed(_, key)
end

function gamestates.keypressedWorldStage(state, key)
    if not state or key ~= "escape" then
        return false
    end

    state.current = "FileSelect"
    state.pendingStartGame = nil
    state.selectedSaveSlot = nil
    state.selectedSaveTimestamp = nil
    state.hoveredSaveSlot = nil
    state.runSetupModal = nil
    state.selectedRunPackageIndex = nil
    state.selectedRunJaclId = nil
    state.selectedRunAgentIds = {}
    state.selectedRunPackage = nil
    state.hoveredWorldMapNode = nil
    state.pinnedWorldMapNode = nil
    state.worldMapDeckModal = nil
    state.worldMapObjectivePreviewModal = nil
    state.worldMapNodePlayButtonTarget = nil
    state.worldMapNodePlayButtonTargets = nil
    state.saveSlots = fileselect.getSaveSlots()

    return true
end

function gamestates.mousepressedFileSelect(state, x, y, button, deps)
    return fileselect.mousepressed(state, x, y, button, deps)
end

function gamestates.mousepressedWorldStage(state, x, y, button, deps)
    if runsetupmodal.mousepressed(state, x, y, button, deps) then
        return true
    end

    return worldmapdraw.mousepressed(state, x, y, button, deps)
end

function gamestates.wheelmovedWorldStage(state, x, y)
    if worldmapdraw.wheelmoved(state, x, y) then
        return true
    end

    return runsetupmodal.wheelmoved(state, x, y)
end

function gamestates.drawFileSelect(state)
    fileselect.draw(state)
end

function gamestates.drawWorldStage(state)
    worldmapdraw.draw(state)
    runsetupmodal.draw(state)
end

return gamestates
