local enhancementrules = {}

local enhancementDefinitions = require("data.enhancements")

local enhancementsById = nil

local function loadEnhancements()
    if enhancementsById ~= nil then
        return
    end

    enhancementsById = {}

    for _, definition in ipairs(enhancementDefinitions or {}) do
        if definition.id then
            enhancementsById[definition.id] = definition
        end
    end
end

local function appendEnhancementId(ids, seenIds, enhancementId)
    if not enhancementId or seenIds[enhancementId] then
        return
    end

    ids[#ids + 1] = enhancementId
    seenIds[enhancementId] = true
end

local function appendEnhancementSource(ids, seenIds, source)
    if type(source) == "string" then
        appendEnhancementId(ids, seenIds, source)
        return
    end

    if type(source) ~= "table" then
        return
    end

    if source.id and enhancementsById and enhancementsById[source.id] then
        appendEnhancementId(ids, seenIds, source.id)
        return
    end

    for _, value in ipairs(source) do
        if type(value) == "string" then
            appendEnhancementId(ids, seenIds, value)
        elseif type(value) == "table" and value.id then
            appendEnhancementId(ids, seenIds, value.id)
        end
    end
end

function enhancementrules.getDefinition(enhancementId)
    loadEnhancements()
    return enhancementsById[enhancementId]
end

function enhancementrules.getCardEnhancementIds(cardDefinition, card)
    loadEnhancements()

    local ids = {}
    local seenIds = {}

    appendEnhancementSource(ids, seenIds, cardDefinition and cardDefinition.enhancement)
    appendEnhancementSource(ids, seenIds, cardDefinition and cardDefinition.enhancements)
    appendEnhancementSource(ids, seenIds, cardDefinition and cardDefinition.enhance)
    appendEnhancementSource(ids, seenIds, cardDefinition and cardDefinition.enh)
    appendEnhancementSource(ids, seenIds, card and card.enhancement)
    appendEnhancementSource(ids, seenIds, card and card.enhancements)
    appendEnhancementSource(ids, seenIds, card and card.enhance)
    appendEnhancementSource(ids, seenIds, card and card.enh)

    return ids
end

function enhancementrules.cardHasEnhancements(cardDefinition, card)
    return #enhancementrules.getCardEnhancementIds(cardDefinition, card) > 0
end

function enhancementrules.isEnhancementExhausted(card, enhancementId)
    return card
        and enhancementId
        and card.exhaustedEnhancements
        and card.exhaustedEnhancements[enhancementId] == true
        or false
end

function enhancementrules.exhaustEnhancement(card, enhancementId)
    if not card or not enhancementId or enhancementrules.isEnhancementExhausted(card, enhancementId) then
        return false
    end

    card.exhaustedEnhancements = card.exhaustedEnhancements or {}
    card.exhaustedEnhancements[enhancementId] = true
    return true
end

function enhancementrules.resolveCardPlayed(card, cardDefinition, ctx)
    if not card or not cardDefinition or not ctx then
        return false
    end

    local resolvedAny = false

    for _, enhancementId in ipairs(enhancementrules.getCardEnhancementIds(cardDefinition, card)) do
        local enhancementDefinition = enhancementrules.getDefinition(enhancementId)
        local drawCount = math.max(0, math.floor(tonumber(
            enhancementDefinition
                and enhancementDefinition.enh
                and enhancementDefinition.enh.CDRAW
        ) or 0))

        if drawCount > 0
            and not enhancementrules.isEnhancementExhausted(card, enhancementId)
            and enhancementrules.exhaustEnhancement(card, enhancementId) then
            for _ = 1, drawCount do
                if not ctx.drawCardFromPlayerDeck or not ctx.drawCardFromPlayerDeck() then
                    break
                end
            end

            resolvedAny = true
        end
    end

    return resolvedAny
end

function enhancementrules.reload()
    enhancementsById = nil
    loadEnhancements()
end

return enhancementrules
