local worldmaprules = {}

local maps = require("data.maps")
local mapnodes = require("data.mapnodes")
local nodeencounters = require("data.nodeencounters")
local champions = require("data.champions")
local stdpkg = require("data.stdpkg")
local modularpkg = require("data.modularpkg")
local decks = require("data.decks")
local warzones = require("data.warzones")

local nodeDefinitionsById = nil
local encounterPoolsById = nil
local definitionIndexes = {}

local ENCOUNTER_CATEGORY_ORDER = {
    {
        field = "champions",
        sourceLabel = "Champion",
        sourceKind = "champion",
        definitions = champions,
    },
    {
        field = "warzones",
        sourceLabel = "Warzone",
        sourceKind = "warzone",
        definitions = warzones,
        definitionType = "warzone",
    },
    {
        field = "standardPackages",
        sourceLabel = "Standard Package",
        sourceKind = "stdpkg",
        definitions = stdpkg,
        fallbackDefinitions = decks,
    },
    {
        field = "modularPackages",
        sourceLabel = "Modular Package",
        sourceKind = "modularpkg",
        definitions = modularpkg,
        fallbackDefinitions = decks,
    },
}

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

local function buildEncounterPoolIndex()
    local poolsById = {}

    for _, poolDefinition in ipairs(nodeencounters or {}) do
        if poolDefinition.id then
            poolsById[poolDefinition.id] = poolDefinition
        end
    end

    return poolsById
end

local function getEncounterPoolsById()
    if not encounterPoolsById then
        encounterPoolsById = buildEncounterPoolIndex()
    end

    return encounterPoolsById
end

local function getDefinitionIndex(category)
    local key = category.field

    if definitionIndexes[key] then
        return definitionIndexes[key]
    end

    local definitionsById = {}

    for _, definition in ipairs(category.definitions or {}) do
        if definition.id and (not category.definitionType or definition.type == category.definitionType) then
            definitionsById[definition.id] = definition
        end
    end

    for _, definition in ipairs(category.fallbackDefinitions or {}) do
        if definition.id
            and definitionsById[definition.id] == nil
            and (not category.definitionType or definition.type == category.definitionType) then
            definitionsById[definition.id] = definition
        end
    end

    definitionIndexes[key] = definitionsById
    return definitionsById
end

local function getRandomIndex(count)
    if count <= 0 then
        return nil
    end

    if love and love.math and love.math.random then
        return love.math.random(count)
    end

    return math.random(count)
end

local function addRandomPoolCategoryEntry(entries, poolDefinition, category)
    local definitionsById = getDefinitionIndex(category)
    local choices = {}

    for _, definitionId in ipairs(poolDefinition[category.field] or {}) do
        local definition = definitionsById[definitionId]

        if definition then
            choices[#choices + 1] = {
                poolId = poolDefinition.id,
                sourceLabel = category.sourceLabel,
                sourceKind = category.sourceKind,
                definition = definition,
            }
        end
    end

    local choiceIndex = getRandomIndex(#choices)

    if choiceIndex then
        entries[#entries + 1] = choices[choiceIndex]
    end
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
    local poolDefinition = poolId and getEncounterPoolsById()[poolId] or nil

    if not poolDefinition then
        return poolEntries
    end

    for _, category in ipairs(ENCOUNTER_CATEGORY_ORDER) do
        addRandomPoolCategoryEntry(poolEntries, poolDefinition, category)
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
