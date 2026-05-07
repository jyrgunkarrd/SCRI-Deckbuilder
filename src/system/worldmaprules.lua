local worldmaprules = {}

local maps = require("data.maps")
local mapnodes = require("data.mapnodes")
local champions = require("data.champions")
local stdpkg = require("data.stdpkg")
local modularpkg = require("data.modularpkg")
local warzones = require("data.warzones")

local nodeDefinitionsById = nil

local function buildNodeDefinitionIndex()
    local definitionsById = {}

    for _, nodeDefinition in ipairs(mapnodes or {}) do
        if nodeDefinition.id then
            definitionsById[nodeDefinition.id] = nodeDefinition
        end
    end

    return definitionsById
end

local function getNodeDefinitionsById()
    if not nodeDefinitionsById then
        nodeDefinitionsById = buildNodeDefinitionIndex()
    end

    return nodeDefinitionsById
end

local function addEncounterEntries(entries, definitions, sourceLabel, sourceKind)
    for _, definition in ipairs(definitions or {}) do
        if definition.encounter then
            entries[#entries + 1] = {
                poolId = definition.encounter,
                sourceLabel = sourceLabel,
                sourceKind = sourceKind,
                definition = definition,
            }
        end
    end
end

local function addWarzoneEncounterEntries(entries)
    for _, definition in ipairs(warzones or {}) do
        if definition.encounter and definition.type == "warzone" then
            entries[#entries + 1] = {
                poolId = definition.encounter,
                sourceLabel = "Warzone",
                sourceKind = "warzone",
                definition = definition,
            }
        end
    end
end

local function collectEncounterEntries()
    local entries = {}

    addEncounterEntries(entries, champions, "Champion", "champion")
    addEncounterEntries(entries, stdpkg, "Standard Package", "stdpkg")
    addEncounterEntries(entries, modularpkg, "Modular Package", "modularpkg")
    addWarzoneEncounterEntries(entries)

    return entries
end

function worldmaprules.getActiveMap(state)
    local mapId = state and state.worldMapId or nil

    if mapId then
        for _, mapDefinition in ipairs(maps or {}) do
            if mapDefinition.id == mapId then
                return mapDefinition
            end
        end
    end

    return maps and maps[1] or nil
end

function worldmaprules.getNodeDefinition(nodeId)
    if not nodeId then
        return nil
    end

    return getNodeDefinitionsById()[nodeId]
end

function worldmaprules.getFirstClusterNode(state, nodeIndex)
    local mapDefinition = worldmaprules.getActiveMap(state)
    local firstCluster = mapDefinition and mapDefinition.clusters and mapDefinition.clusters[1] or nil

    return firstCluster and firstCluster.nodes and firstCluster.nodes[nodeIndex] or nil
end

function worldmaprules.getFirstClusterBranchNode(state, nodeIndex, branchIndex)
    local routeNode = worldmaprules.getFirstClusterNode(state, nodeIndex)
    local branchNodeId = routeNode and routeNode.branches and routeNode.branches[branchIndex] or nil

    return worldmaprules.getNodeDefinition(branchNodeId)
end

function worldmaprules.getEncounterPoolEntries(poolId)
    local poolEntries = {}

    if not poolId then
        return poolEntries
    end

    for _, entry in ipairs(collectEncounterEntries()) do
        if entry.poolId == poolId then
            poolEntries[#poolEntries + 1] = entry
        end
    end

    return poolEntries
end

function worldmaprules.getNodeEncounterPreview(nodeDefinition)
    if not nodeDefinition then
        return nil
    end

    return {
        title = nodeDefinition.preview and nodeDefinition.preview.title or nodeDefinition.name or nodeDefinition.id,
        summary = nodeDefinition.preview and nodeDefinition.preview.summary or nil,
        details = nodeDefinition.preview and nodeDefinition.preview.details or {},
        encounterPool = nodeDefinition.encounterPool,
        encounters = worldmaprules.getEncounterPoolEntries(nodeDefinition.encounterPool),
    }
end

return worldmaprules
