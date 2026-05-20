local fileselect = require("src.states.fileselect")
local playerdefeatmodal = require("src.ui.playerdefeatmodal")
local systemrules = require("src.system.systemrules")

local playerdefeatcontroller = {}

local function getObjectiveDefeatSourceRect(ctx, objectiveDefinition)
    local layouts = ctx.envdraw.getTopSlotLayouts(
        ctx.turnrules.getCurrentPhase(),
        ctx.gameState.activeChampion,
        ctx.gameState.activeWarzone,
        ctx.gameState.activePoi,
        objectiveDefinition or ctx.gameState.activePrimaryObjective,
        ctx.gameState.activeIntel
    )

    for _, slot in ipairs(layouts or {}) do
        if slot.id == "objective" then
            return slot.imageRect or {
                x = slot.x,
                y = slot.y + (slot.labelHeight or 0),
                width = slot.width,
                height = slot.height,
            }
        end
    end

    return nil
end

function playerdefeatcontroller.hasOpen(ctx)
    return playerdefeatmodal.hasOpen(ctx and ctx.appState or nil)
end

function playerdefeatcontroller.begin(ctx, objectiveDefinition)
    if not ctx or not ctx.appState or not ctx.gameState or playerdefeatcontroller.hasOpen(ctx) then
        return false
    end

    local gameState = ctx.gameState

    ctx.appState.current = "MissionStage"
    gameState.draggedCardIndex = nil
    gameState.draggedCardOrigin = nil
    gameState.pendingSelection = nil
    gameState.pendingButtonSelection = nil
    gameState.pendingSacrificeSelection = nil
    gameState.pendingHandLimitDiscardSelection = nil
    gameState.primedActivatedAbility = nil
    gameState.primedSyntacAbility = nil

    return playerdefeatmodal.open(
        ctx.appState,
        objectiveDefinition or gameState.activePrimaryObjective,
        getObjectiveDefeatSourceRect(ctx, objectiveDefinition)
    )
end

function playerdefeatcontroller.resetRun(ctx)
    if not ctx or not ctx.appState or not ctx.gameState then
        return false
    end

    local appState = ctx.appState

    appState.playerDefeat = nil
    appState.current = "FileSelect"
    appState.pendingStartGame = nil
    appState.selectedSaveSlot = nil
    appState.selectedSaveTimestamp = nil
    appState.hoveredSaveSlot = nil
    appState.previousHoveredSaveSlot = nil
    appState.runSetupModal = nil
    appState.selectedRunPackageIndex = nil
    appState.selectedRunJaclId = nil
    appState.selectedRunAgentIds = {}
    appState.selectedRunPackage = nil
    appState.selectedRunMunitionsSystem = nil
    appState.selectedRunTitheSystem = nil
    appState.selectedRunCardRewards = {
        jacl = {},
        agents = {},
    }
    appState.worldResources = {
        alms = 0,
        fuel = 0,
        munitions = 0,
        tithes = 0,
    }
    appState.deadCrewRoles = {}
    appState.missionDeadCrewRoles = {}
    appState.worldMapFuelPayments = {}
    appState.pendingDomainAwareness = nil
    appState.worldMissionSystems = systemrules.createFreshSystems()
    appState.activeMissionPrize = nil
    appState.activeMissionReward = nil
    appState.worldMapRewardModal = nil
    appState.worldMapRewardCollectButtonTarget = nil
    appState.worldMapSystemRepair = nil
    appState.worldMapSystemRepairQueue = nil
    appState.pendingWorldMapCardReward = nil
    appState.worldMapCardRewardModal = nil
    appState.pendingWorldMapHunterModal = nil
    appState.worldMapHunterModal = nil
    appState.pendingWorldMapCrewReviveModal = nil
    appState.worldMapCrewReviveModal = nil
    appState.worldMapDeckModal = nil
    appState.worldMapObjectivePreviewModal = nil
    appState.worldMapNodePlayButtonTarget = nil
    appState.worldMapNodePlayButtonTargets = nil
    appState.victoryTransition = nil
    appState.championVictoryDestruction = nil
    appState.worldToMissionTransition = nil
    appState.pendingMissionSetup = nil
    appState.saveSlots = fileselect.getSaveSlots()

    if ctx.setSetupScenario then
        ctx.setSetupScenario(ctx.gamestate.getDefaultScenario())
    end

    ctx.gamestate.resetForNewRun(ctx.gameState)
    ctx.turnrules.reset()
    ctx.resourcerules.reset()
    ctx.warrules.reset()
    ctx.notifications.reset()
    ctx.cardinstances.reset()
    ctx.warzonecontrolrules.reset()
    ctx.topsloteffects.reset()
    ctx.infiltrationrules.reset()
    ctx.munitionsrules.reset()

    return true
end

function playerdefeatcontroller.update(ctx, dt)
    return playerdefeatmodal.update(ctx and ctx.appState or nil, dt)
end

function playerdefeatcontroller.draw(ctx)
    return playerdefeatmodal.draw(ctx and ctx.appState or nil)
end

function playerdefeatcontroller.mousepressed(ctx, x, y, button)
    local result = playerdefeatmodal.mousepressed(ctx and ctx.appState or nil, x, y, button)

    if result == "game_over" then
        return playerdefeatcontroller.resetRun(ctx)
    end

    return result
end

return playerdefeatcontroller
