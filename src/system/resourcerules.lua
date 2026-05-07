local resourcerules = {}
local sfxrules = require("src.audio.sfxrules")

local RESOURCE_TRANSFER_DURATION = 0.42
local SCRATCH_RESOURCE = "The Scratch"
local SCRATCH_COLOR = { 0.24, 1, 0.39, 1 }
local METHOD_COLOR = { 0.953, 0.749, 0.208, 1 }

local resourceCounts = {}
local activeTransfers = {}
local pendingGenerations = {}
local queueTransfer
local startNextPendingGeneration

local function cloneColor(color)
    return { color[1], color[2], color[3], color[4] }
end

local function setResourceCount(resourceName, value)
    resourceCounts[resourceName] = value
end

local function incrementResource(resourceName, amount)
    resourceCounts[resourceName] = (resourceCounts[resourceName] or 0) + (amount or 1)
end

local function expandMethodEntries(methodEntries)
    local expandedResources = {}

    for _, methodEntry in ipairs(methodEntries or {}) do
        for _ = 1, (methodEntry.amount or 0) do
            expandedResources[#expandedResources + 1] = methodEntry.resource
        end
    end

    return expandedResources
end

function resourcerules.reset()
    resourceCounts = {}
    activeTransfers = {}
    pendingGenerations = {}
end

function resourcerules.getResourceCounts()
    return resourceCounts
end

function resourcerules.getResourceCount(resourceName)
    return resourceCounts[resourceName] or 0
end

function resourcerules.addResource(resourceName, amount)
    if not resourceName then
        return false
    end

    local resourceAmount = math.max(0, math.floor(tonumber(amount) or 0))

    if resourceAmount <= 0 then
        return false
    end

    incrementResource(resourceName, resourceAmount)
    return true
end

function resourcerules.addResourceFromSource(resourceName, amount, sourceCenter, panelLayout, resourceTrackerLayout)
    local resourceAmount = math.max(0, math.floor(tonumber(amount) or 0))

    if resourceAmount <= 0 then
        return false
    end

    if not sourceCenter or not panelLayout or not resourceTrackerLayout then
        return resourcerules.addResource(resourceName, resourceAmount)
    end

    for _ = 1, resourceAmount do
        queueTransfer(sourceCenter, resourceName, panelLayout.scratchBadgeCenter, resourceTrackerLayout)
    end

    startNextPendingGeneration()
    return true
end

function resourcerules.getActiveTransfers()
    return activeTransfers
end

function resourcerules.isGenerationComplete()
    return #activeTransfers == 0 and #pendingGenerations == 0
end

function resourcerules.canAffordCosts(costEntries)
    if not costEntries then
        return true
    end

    for _, costEntry in ipairs(costEntries) do
        local resourceName = costEntry.resource
        local amount = costEntry.amount or 0

        if (resourceCounts[resourceName] or 0) < amount then
            return false
        end
    end

    return true
end

function resourcerules.payCosts(costEntries)
    if not resourcerules.canAffordCosts(costEntries) then
        return false
    end

    for _, costEntry in ipairs(costEntries or {}) do
        local resourceName = costEntry.resource
        local amount = costEntry.amount or 0
        resourceCounts[resourceName] = (resourceCounts[resourceName] or 0) - amount
    end

    return true
end

function resourcerules.deductCosts(costEntries)
    for _, costEntry in ipairs(costEntries or {}) do
        local resourceName = costEntry.resource
        local amount = math.max(0, math.floor(tonumber(costEntry.amount) or 0))

        if resourceName and amount > 0 then
            resourceCounts[resourceName] = math.max(0, (resourceCounts[resourceName] or 0) - amount)
        end
    end

    return true
end

function resourcerules.exchangeScratchForResource(targetResource)
    if not targetResource or targetResource == SCRATCH_RESOURCE then
        return false
    end

    if (resourceCounts[SCRATCH_RESOURCE] or 0) <= 0 then
        return false
    end

    resourceCounts[SCRATCH_RESOURCE] = (resourceCounts[SCRATCH_RESOURCE] or 0) - 1
    incrementResource(targetResource, 1)
    sfxrules.playResourcePlay()
    return true
end

function resourcerules.exchangeResourceForScratch(sourceResource)
    if not sourceResource or sourceResource == SCRATCH_RESOURCE then
        return false
    end

    if (resourceCounts[sourceResource] or 0) <= 0 then
        return false
    end

    resourceCounts[sourceResource] = (resourceCounts[sourceResource] or 0) - 1
    incrementResource(SCRATCH_RESOURCE, 1)
    sfxrules.playResourcePlay()
    return true
end

queueTransfer = function(sourceCenter, targetResource, scratchTargetCenter, resourceTrackerLayout)
    if not sourceCenter or not targetResource or not scratchTargetCenter or not resourceTrackerLayout then
        return nil
    end

    local targetCenter = nil
    local transferColor = nil

    if targetResource == SCRATCH_RESOURCE then
        targetCenter = scratchTargetCenter
        transferColor = cloneColor(SCRATCH_COLOR)
    else
        targetCenter = resourceTrackerLayout.resourceCenters[targetResource]
        transferColor = cloneColor(METHOD_COLOR)
    end

    if not targetCenter then
        return dieRoll
    end

    if resourceCounts[targetResource] == nil then
        setResourceCount(targetResource, 0)
    end

    pendingGenerations[#pendingGenerations + 1] = {
        sourceX = sourceCenter.x,
        sourceY = sourceCenter.y,
        targetX = targetCenter.x,
        targetY = targetCenter.y,
        resourceName = targetResource,
        color = transferColor,
    }
end

startNextPendingGeneration = function()
    if #activeTransfers > 0 or #pendingGenerations == 0 then
        return
    end

    local generation = table.remove(pendingGenerations, 1)

    activeTransfers[1] = {
        sourceX = generation.sourceX,
        sourceY = generation.sourceY,
        targetX = generation.targetX,
        targetY = generation.targetY,
        elapsed = 0,
        duration = RESOURCE_TRANSFER_DURATION,
        resourceName = generation.resourceName,
        color = generation.color,
    }
end

function resourcerules.enterStartPhase(jaclDefinition, panelLayout, resourceTrackerLayout, cardGenerators)
    if not jaclDefinition or not panelLayout or not resourceTrackerLayout then
        return nil
    end

    pendingGenerations = {}
    activeTransfers = {}

    local function queueSourceGeneration(methodEntries, methodBadgeCenters)
        local expandedResources = expandMethodEntries(methodEntries)
        local firstSourceCenter = methodBadgeCenters and methodBadgeCenters[1]

        if not firstSourceCenter or #expandedResources == 0 then
            return
        end

        for resourceIndex, resourceName in ipairs(expandedResources) do
            local dieRoll = love.math.random(1, 6)
            local sourceCenter = methodBadgeCenters[resourceIndex] or firstSourceCenter

            if dieRoll <= 4 then
                queueTransfer(sourceCenter, SCRATCH_RESOURCE, panelLayout.scratchBadgeCenter, resourceTrackerLayout)
            else
                queueTransfer(sourceCenter, resourceName, panelLayout.scratchBadgeCenter, resourceTrackerLayout)
            end
        end
    end

    queueSourceGeneration(jaclDefinition.method, panelLayout.methodBadgeCenters)

    for _, cardGenerator in ipairs(cardGenerators or {}) do
        queueSourceGeneration(cardGenerator.methodEntries, cardGenerator.methodBadgeCenters)
    end

    startNextPendingGeneration()
end

function resourcerules.update(dt)
    for transferIndex = #activeTransfers, 1, -1 do
        local transfer = activeTransfers[transferIndex]
        transfer.elapsed = transfer.elapsed + dt

        if transfer.elapsed >= transfer.duration then
            incrementResource(transfer.resourceName, 1)

            if transfer.resourceName == SCRATCH_RESOURCE then
                sfxrules.playResourceMove()
            else
                sfxrules.playResourcePlay()
            end

            table.remove(activeTransfers, transferIndex)
        end
    end

    startNextPendingGeneration()
end

return resourcerules
