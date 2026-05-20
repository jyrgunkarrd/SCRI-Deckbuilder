local worldfuelrules = {}

local MAP_CLUSTER_COUNT = 3
local MAP_CLUSTER_SIZE = 5

local function getPlayerMapPosition(state)
    return state and state.playerMapPosition or {
        kind = "start",
    }
end

local function getNextMapPosition(playerMapPosition)
    if not playerMapPosition or playerMapPosition.kind == "start" then
        return {
            kind = "path",
            clusterIndex = 1,
            nodeIndex = 1,
        }
    end

    if playerMapPosition.kind ~= "path" then
        return nil
    end

    local clusterIndex = playerMapPosition.clusterIndex or 1
    local nodeIndex = playerMapPosition.nodeIndex or 1

    if nodeIndex < MAP_CLUSTER_SIZE then
        return {
            kind = "path",
            clusterIndex = clusterIndex,
            nodeIndex = nodeIndex + 1,
        }
    end

    if clusterIndex < MAP_CLUSTER_COUNT then
        return {
            kind = "path",
            clusterIndex = clusterIndex + 1,
            nodeIndex = 1,
        }
    end

    return nil
end

local function getPositionKey(position)
    if not position then
        return nil
    end

    if position.kind == "start" then
        return "start"
    end

    if position.kind == "path" then
        return "path:" .. tostring(position.clusterIndex or 1) .. ":" .. tostring(position.nodeIndex or 1)
    end

    return tostring(position.kind)
end

local function isStartOrBossPosition(position)
    return not position
        or position.kind == "start"
        or (position.kind == "path" and (position.nodeIndex or 1) == MAP_CLUSTER_SIZE)
end

function worldfuelrules.getSegmentKey(sourcePosition, destinationPosition)
    local sourceKey = getPositionKey(sourcePosition)
    local destinationKey = getPositionKey(destinationPosition)

    if not sourceKey or not destinationKey then
        return nil
    end

    return sourceKey .. "->" .. destinationKey
end

function worldfuelrules.getSegmentFuelCost(sourcePosition)
    return isStartOrBossPosition(sourcePosition) and 2 or 1
end

function worldfuelrules.getCurrentSegment(state)
    local sourcePosition = getPlayerMapPosition(state)
    local destinationPosition = getNextMapPosition(sourcePosition)

    if not destinationPosition then
        return nil
    end

    return {
        sourcePosition = sourcePosition,
        destinationPosition = destinationPosition,
        key = worldfuelrules.getSegmentKey(sourcePosition, destinationPosition),
        cost = worldfuelrules.getSegmentFuelCost(sourcePosition),
    }
end

function worldfuelrules.getPaidFuelCount(state, segmentKey)
    local payments = state and state.worldMapFuelPayments or nil

    return math.max(0, math.floor(tonumber(payments and payments[segmentKey]) or 0))
end

function worldfuelrules.getRemainingFuelCount(state, segmentKey, cost)
    return math.max(0, math.floor(tonumber(cost) or 0) - worldfuelrules.getPaidFuelCount(state, segmentKey))
end

function worldfuelrules.isNodeNextDestination(state, clusterIndex, nodeIndex)
    local currentSegment = worldfuelrules.getCurrentSegment(state)
    local destination = currentSegment and currentSegment.destinationPosition or nil

    return destination
        and destination.kind == "path"
        and destination.clusterIndex == clusterIndex
        and destination.nodeIndex == nodeIndex
        or false
end

function worldfuelrules.isCurrentSegmentCleared(state)
    local currentSegment = worldfuelrules.getCurrentSegment(state)

    if not currentSegment then
        return true
    end

    return worldfuelrules.getRemainingFuelCount(state, currentSegment.key, currentSegment.cost) <= 0
end

function worldfuelrules.payCurrentSegmentFuel(state)
    local currentSegment = worldfuelrules.getCurrentSegment(state)

    if not state or not currentSegment then
        return false, "no-segment"
    end

    if worldfuelrules.getRemainingFuelCount(state, currentSegment.key, currentSegment.cost) <= 0 then
        return false, "cleared"
    end

    local resources = state.worldResources or {}
    local availableFuel = math.max(0, math.floor(tonumber(resources.fuel) or 0))

    if availableFuel <= 0 then
        return false, "no-fuel"
    end

    state.worldResources = resources
    state.worldMapFuelPayments = state.worldMapFuelPayments or {}
    resources.fuel = availableFuel - 1
    state.worldMapFuelPayments[currentSegment.key] = worldfuelrules.getPaidFuelCount(state, currentSegment.key) + 1

    return true, currentSegment
end

return worldfuelrules
