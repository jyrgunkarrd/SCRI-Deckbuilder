local keywordrules = {}
local keywordDefinitions = require("data.keywords")
local cardregistry = require("src.system.cardregistry")
local temporaryeffects = require("src.system.temporaryeffects")
local TIME_LIMIT_KEYWORD_ID = "KWTIME"

local enemyChampionHandlers = {
    enemy_champion_play_another_card = function()
        return {
            playAnotherCard = true,
        }
    end,
}

local keywordsById = nil

local function appendKeywordIds(keywordIds, seenKeywordIds, sourceDefinition)
    if not sourceDefinition then
        return
    end

    if type(sourceDefinition.keyword) == "table" then
        for _, keywordId in ipairs(sourceDefinition.keyword) do
            if keywordId and not seenKeywordIds[keywordId] then
                keywordIds[#keywordIds + 1] = keywordId
                seenKeywordIds[keywordId] = true
            end
        end
    elseif sourceDefinition.keyword ~= nil and not seenKeywordIds[sourceDefinition.keyword] then
        keywordIds[#keywordIds + 1] = sourceDefinition.keyword
        seenKeywordIds[sourceDefinition.keyword] = true
    end
end

local function getAttachedKitDefinitions(card)
    local attachedDefinitions = {}

    for _, attachedKit in ipairs(card and card.attachedKitCards or {}) do
        local attachedDefinition = attachedKit and cardregistry.getCard(attachedKit.setName, attachedKit.cardId) or nil

        if attachedDefinition then
            attachedDefinitions[#attachedDefinitions + 1] = attachedDefinition
        end
    end

    return attachedDefinitions
end

local function loadKeywords()
    if keywordsById ~= nil then
        return
    end

    keywordsById = {}

    for _, definition in ipairs(keywordDefinitions or {}) do
        if definition.id then
            keywordsById[definition.id] = definition
        end
    end
end

function keywordrules.getCardKeywordIds(cardDefinition, card)
    local keywordIds = {}
    local seenKeywordIds = {}

    appendKeywordIds(keywordIds, seenKeywordIds, cardDefinition)

    for keywordId in pairs(card and card.tempKeywords or {}) do
        if not seenKeywordIds[keywordId] and temporaryeffects.hasTemporaryKeyword(card, keywordId) then
            keywordIds[#keywordIds + 1] = keywordId
            seenKeywordIds[keywordId] = true
        end
    end

    for _, attachedDefinition in ipairs(getAttachedKitDefinitions(card)) do
        appendKeywordIds(keywordIds, seenKeywordIds, attachedDefinition)
    end

    return keywordIds
end

function keywordrules.cardHasKeyword(cardDefinition, keywordId, card)
    if not cardDefinition or not keywordId then
        return false
    end

    for _, cardKeywordId in ipairs(keywordrules.getCardKeywordIds(cardDefinition, card)) do
        if cardKeywordId == keywordId then
            return true
        end
    end

    return false
end

local function getDefinitionKeywordValue(cardDefinition, keywordId)
    if not cardDefinition or keywordId == nil then
        return nil
    end

    if type(cardDefinition.kwval) == "table" then
        return tonumber(cardDefinition.kwval[keywordId]) or 0
    end

    return tonumber(cardDefinition.kwval) or 0
end

local function getKeywordValueFromSource(card, sourceDefinition, keywordId)
    if not sourceDefinition or not keywordrules.cardHasKeyword(sourceDefinition, keywordId) then
        return nil
    end

    if card and card.keywordValues and card.keywordValues[keywordId] ~= nil then
        return tonumber(card.keywordValues[keywordId]) or 0
    end

    return tonumber(getDefinitionKeywordValue(sourceDefinition, keywordId)) or 0
end

function keywordrules.getEnemyChampionPlayEffect(cardDefinition)
    if not cardDefinition then
        return nil
    end

    loadKeywords()

    for _, keywordId in ipairs(keywordrules.getCardKeywordIds(cardDefinition)) do
        local keywordDefinition = keywordsById[keywordId]

        if keywordDefinition and keywordDefinition.effect then
            local handler = enemyChampionHandlers[keywordDefinition.effect]

            if handler then
                return handler(cardDefinition, keywordDefinition)
            end
        end
    end

    return nil
end

function keywordrules.getKeywordDefinition(keywordId)
    if not keywordId then
        return nil
    end

    loadKeywords()
    return keywordsById[keywordId]
end

function keywordrules.initializeCardKeywordState(card, cardDefinition)
    if not card or not cardDefinition then
        return
    end

    local keywordIds = keywordrules.getCardKeywordIds(cardDefinition)

    if #keywordIds == 0 then
        return
    end

    for _, keywordId in ipairs(keywordIds) do
        local keywordDefinition = keywordrules.getKeywordDefinition(keywordId)

        if keywordDefinition and keywordDefinition.hasvalue == 1 then
            card.keywordValues = card.keywordValues or {}

            if card.keywordValues[keywordId] == nil then
                card.keywordValues[keywordId] = getDefinitionKeywordValue(cardDefinition, keywordId)
            end
        end
    end
end

function keywordrules.getCardKeywordValue(card, cardDefinition, keywordId)
    if not keywordId then
        return nil
    end

    local keywordDefinition = keywordrules.getKeywordDefinition(keywordId)

    if not keywordDefinition or keywordDefinition.hasvalue ~= 1 then
        return nil
    end

    local keywordValue = 0
    local hasKeywordValue = false

    local baseKeywordValue = getKeywordValueFromSource(card, cardDefinition, keywordId)

    if baseKeywordValue ~= nil then
        keywordValue = keywordValue + baseKeywordValue
        hasKeywordValue = true
    end

    local temporaryKeywordValue = temporaryeffects.getTemporaryKeywordValue(card, keywordId)

    if temporaryKeywordValue ~= nil then
        keywordValue = keywordValue + temporaryKeywordValue
        hasKeywordValue = true
    end

    for _, attachedDefinition in ipairs(getAttachedKitDefinitions(card)) do
        local attachedKeywordValue = getKeywordValueFromSource(nil, attachedDefinition, keywordId)

        if attachedKeywordValue ~= nil then
            keywordValue = keywordValue + attachedKeywordValue
            hasKeywordValue = true
        end
    end

    if not hasKeywordValue then
        return nil
    end

    return keywordValue
end

function keywordrules.getCardKeywordValues(card, cardDefinition)
    local keywordValues = {}

    for _, keywordId in ipairs(keywordrules.getCardKeywordIds(cardDefinition, card)) do
        local keywordValue = keywordrules.getCardKeywordValue(card, cardDefinition, keywordId)

        if keywordValue ~= nil then
            keywordValues[keywordId] = keywordValue
        end
    end

    if next(keywordValues) == nil then
        return nil
    end

    return keywordValues
end

function keywordrules.decrementEndPhaseKeywords(cards)
    local expiredCardIndices = {}

    for cardIndex, card in ipairs(cards or {}) do
        if card
            and card.location
            and card.location.kind == "grid"
            and not card.destroyed
            and not card.destroying then
            local cardDefinition = cardregistry.getCard(card.setName, card.cardId)

            if keywordrules.cardHasKeyword(cardDefinition, TIME_LIMIT_KEYWORD_ID) then
                keywordrules.initializeCardKeywordState(card, cardDefinition)
                card.keywordValues = card.keywordValues or {}
                card.keywordValues[TIME_LIMIT_KEYWORD_ID] = (tonumber(card.keywordValues[TIME_LIMIT_KEYWORD_ID]) or 0) - 1

                if card.keywordValues[TIME_LIMIT_KEYWORD_ID] <= 0 then
                    expiredCardIndices[#expiredCardIndices + 1] = cardIndex
                end
            end
        end
    end

    return expiredCardIndices
end

return keywordrules
