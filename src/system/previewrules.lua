local previewrules = {}

local cardregistry = require("src.system.cardregistry")

local DEFAULT_PREVIEW_LABEL = "PREVIEW"

local function addCardId(cardIds, cardId)
    if cardId and cardId ~= "" then
        cardIds[#cardIds + 1] = cardId
    end
end

local function addCardIds(cardIds, sourceCardIds)
    if type(sourceCardIds) == "table" then
        for _, cardId in ipairs(sourceCardIds) do
            addCardId(cardIds, cardId)
        end
    else
        addCardId(cardIds, sourceCardIds)
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
            if type(cardEntry) == "table" then
                addCardId(cardIds, cardEntry.cardId or cardEntry.id)
            else
                addCardId(cardIds, cardEntry)
            end
        end
    end

    return cardIds
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

function previewrules.getDefinitionPreview(definition, fallbackLabel)
    local previewCardDefinitions = previewrules.getPreviewCardDefinitions(definition)

    if #previewCardDefinitions == 0 then
        return nil
    end

    return {
        label = previewrules.getPreviewLabel(definition, fallbackLabel),
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
    tooltip.previewCardDefinitions = preview.cardDefinitions

    return tooltip
end

return previewrules