local previewrules = {}

local cardregistry = require("src.system.cardregistry")

local DEFAULT_PREVIEW_LABEL = "PREVIEW"

local function normalizePreviewCount(count)
    return math.max(1, math.floor(tonumber(count) or 1))
end

local function addCardId(cardIds, cardId)
    if cardId and cardId ~= "" then
        cardIds[#cardIds + 1] = cardId
    end
end

local function addCardEntry(cardEntries, cardId, count)
    if cardId and cardId ~= "" then
        cardEntries[#cardEntries + 1] = {
            cardId = cardId,
            count = normalizePreviewCount(count),
        }
    end
end

local function getCardEntryId(cardEntry)
    if type(cardEntry) ~= "table" then
        return cardEntry
    end

    return cardEntry.cardId or cardEntry.id or cardEntry[1]
end

local function addCardIds(cardIds, sourceCardIds)
    if type(sourceCardIds) == "table" then
        for _, cardEntry in ipairs(sourceCardIds) do
            addCardId(cardIds, getCardEntryId(cardEntry))
        end
    else
        addCardId(cardIds, sourceCardIds)
    end
end

local function addCardEntries(cardEntries, sourceCardIds)
    if type(sourceCardIds) == "table" then
        for _, cardEntry in ipairs(sourceCardIds) do
            if type(cardEntry) == "table" then
                addCardEntry(cardEntries, getCardEntryId(cardEntry), cardEntry.quantity or cardEntry.count)
            else
                addCardEntry(cardEntries, cardEntry, 1)
            end
        end
    else
        addCardEntry(cardEntries, sourceCardIds, 1)
    end
end

local function getPreviewSpec(definition)
    if not definition then
        return nil
    end

    local preview = definition.preview

    if type(preview) == "string" then
        return {
            cardId = preview,
        }
    end

    if type(preview) ~= "table" then
        return nil
    end

    return preview
end

function previewrules.getPreviewCardIds(definition)
    local preview = getPreviewSpec(definition)
    local cardIds = {}

    if not preview then
        return cardIds
    end

    addCardId(cardIds, preview.cardId)
    addCardIds(cardIds, preview.cardIds)

    -- Optional future-friendly shape:
    -- preview = { label = "KIT", cards = { { cardId = "X" }, { cardId = "Y" } } }
    if type(preview.cards) == "table" then
        for _, cardEntry in ipairs(preview.cards) do
            addCardId(cardIds, getCardEntryId(cardEntry))
        end
    end

    return cardIds
end

function previewrules.getPreviewCardEntries(definition)
    local preview = getPreviewSpec(definition)
    local cardEntries = {}

    if not preview then
        return cardEntries
    end

    addCardEntry(cardEntries, preview.cardId, preview.quantity or preview.count)
    addCardEntries(cardEntries, preview.cardIds)

    if type(preview.cards) == "table" then
        for _, cardEntry in ipairs(preview.cards) do
            if type(cardEntry) == "table" then
                addCardEntry(cardEntries, getCardEntryId(cardEntry), cardEntry.quantity or cardEntry.count)
            else
                addCardEntry(cardEntries, cardEntry, 1)
            end
        end
    end

    return cardEntries
end

function previewrules.getPreviewLabel(definition, fallbackLabel)
    local preview = getPreviewSpec(definition)

    if preview and preview.label then
        return preview.label
    end

    return fallbackLabel or DEFAULT_PREVIEW_LABEL
end

function previewrules.getPreviewCardDefinitions(definition)
    local previewCardDefinitions = {}

    for _, cardId in ipairs(previewrules.getPreviewCardIds(definition)) do
        local previewCardDefinition = cardregistry.getCardById(cardId)

        if previewCardDefinition then
            previewCardDefinitions[#previewCardDefinitions + 1] = previewCardDefinition
        end
    end

    return previewCardDefinitions
end

function previewrules.getPreviewCardDefinitionEntries(definition)
    local previewCardDefinitionEntries = {}

    for _, cardEntry in ipairs(previewrules.getPreviewCardEntries(definition)) do
        local previewCardDefinition = cardregistry.getCardById(cardEntry.cardId)

        if previewCardDefinition then
            previewCardDefinitionEntries[#previewCardDefinitionEntries + 1] = {
                definition = previewCardDefinition,
                count = cardEntry.count,
            }
        end
    end

    return previewCardDefinitionEntries
end

function previewrules.getDefinitionPreview(definition, fallbackLabel)
    local previewCardDefinitionEntries = previewrules.getPreviewCardDefinitionEntries(definition)
    local previewCardDefinitions = {}

    if #previewCardDefinitionEntries == 0 then
        return nil
    end

    for _, previewEntry in ipairs(previewCardDefinitionEntries) do
        previewCardDefinitions[#previewCardDefinitions + 1] = previewEntry.definition
    end

    return {
        label = previewrules.getPreviewLabel(definition, fallbackLabel),
        cardDefinitionEntries = previewCardDefinitionEntries,
        cardDefinitions = previewCardDefinitions,
        cardDefinition = previewCardDefinitions[1],
    }
end

function previewrules.applyDefinitionPreviewToTooltip(definition, tooltip, fallbackLabel)
    if not tooltip then
        return nil
    end

    local preview = previewrules.getDefinitionPreview(definition or tooltip, fallbackLabel)

    if not preview then
        return tooltip
    end

    tooltip.previewLabel = preview.label
    tooltip.previewCardDefinition = preview.cardDefinition
    tooltip.previewCardDefinitionEntries = preview.cardDefinitionEntries
    tooltip.previewCardDefinitions = preview.cardDefinitions

    return tooltip
end

return previewrules
