local keywordrules = {}
local keywordDefinitions = require("data.keywords")
local cardregistry = require("src.system.cardregistry")
local temporaryeffects = require("src.system.temporaryeffects")
local TIME_LIMIT_KEYWORD_ID = "KWTIME"
local RELOADING_KEYWORD_ID = "KWRLD"
local GROWTH_KEYWORD_ID = "KWGRO"
local TOUGH_KEYWORD_ID = "KWTOUGH"
local RAGE_KEYWORD_ID = "KWRAGE"
local WOUND_KEYWORD_ID = "KWWOUND"
local CARD_SCRIPT_MODULE_PREFIX = "data.cards.scripts."
local exhaustedKeywordInstances = {}
local cardScriptHandlers = {}

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

local function getCardScriptHandler(funcName)
    if not funcName then
        return nil
    end

    local scriptName = tostring(funcName)

    if cardScriptHandlers[scriptName] ~= nil then
        return cardScriptHandlers[scriptName]
    end

    local ok, handler = pcall(require, CARD_SCRIPT_MODULE_PREFIX .. scriptName)

    if ok and type(handler) == "table" then
        cardScriptHandlers[scriptName] = handler
        return handler
    end

    if not ok and not tostring(handler):find("module '" .. CARD_SCRIPT_MODULE_PREFIX .. scriptName .. "' not found", 1, true) then
        error(handler)
    end

    cardScriptHandlers[scriptName] = false
    return nil
end

local function appendPassiveScriptKeywordIds(keywordIds, seenKeywordIds, cardDefinition, card)
    local handler = cardDefinition and getCardScriptHandler(cardDefinition.func) or nil

    if not handler or type(handler.getPassiveKeywordIds) ~= "function" then
        return
    end

    for _, keywordId in ipairs(handler.getPassiveKeywordIds(card, cardDefinition) or {}) do
        if keywordId and not seenKeywordIds[keywordId] then
            keywordIds[#keywordIds + 1] = keywordId
            seenKeywordIds[keywordId] = true
        end
    end
end

local function getPassiveScriptKeywordValue(card, cardDefinition, keywordId)
    local handler = cardDefinition and getCardScriptHandler(cardDefinition.func) or nil

    if not handler or type(handler.getPassiveKeywordValue) ~= "function" then
        return nil
    end

    local keywordValue = handler.getPassiveKeywordValue(card, cardDefinition, keywordId)

    if keywordValue == nil then
        return nil
    end

    keywordValue = math.max(0, tonumber(keywordValue) or 0)

    if keywordValue <= 0 then
        return nil
    end

    return keywordValue
end

function keywordrules.getCardKeywordIds(cardDefinition, card)
    local keywordIds = {}
    local seenKeywordIds = {}

    appendKeywordIds(keywordIds, seenKeywordIds, cardDefinition)

    for keywordId, keywordValue in pairs(card and card.keywordValues or {}) do
        if (tonumber(keywordValue) or 0) > 0 and not seenKeywordIds[keywordId] then
            keywordIds[#keywordIds + 1] = keywordId
            seenKeywordIds[keywordId] = true
        end
    end

    for keywordId in pairs(card and card.tempKeywords or {}) do
        if not seenKeywordIds[keywordId] and temporaryeffects.hasTemporaryKeyword(card, keywordId) then
            keywordIds[#keywordIds + 1] = keywordId
            seenKeywordIds[keywordId] = true
        end
    end

    for _, attachedDefinition in ipairs(getAttachedKitDefinitions(card)) do
        appendKeywordIds(keywordIds, seenKeywordIds, attachedDefinition)
    end

    appendPassiveScriptKeywordIds(keywordIds, seenKeywordIds, cardDefinition, card)

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

function keywordrules.isKeywordExhausted(card, keywordId)
    if not card or not keywordId then
        return false
    end

    if card.instanceId
        and exhaustedKeywordInstances[card.instanceId]
        and exhaustedKeywordInstances[card.instanceId][keywordId] == true then
        return true
    end

    return card
        and keywordId
        and card.exhaustedKeywords
        and card.exhaustedKeywords[keywordId] == true
        or false
end

function keywordrules.exhaustKeyword(card, keywordId)
    if not card or not keywordId then
        return false
    end

    card.exhaustedKeywords = card.exhaustedKeywords or {}
    card.exhaustedKeywords[keywordId] = true

    if card.instanceId then
        exhaustedKeywordInstances[card.instanceId] = exhaustedKeywordInstances[card.instanceId] or {}
        exhaustedKeywordInstances[card.instanceId][keywordId] = true
    end

    return true
end

function keywordrules.resetKeywordExhaustion()
    exhaustedKeywordInstances = {}
end

function keywordrules.refreshEndPhaseKeywords(cards)
    for _, card in ipairs(cards or {}) do
        if card and card.instanceId and exhaustedKeywordInstances[card.instanceId] then
            exhaustedKeywordInstances[card.instanceId][TOUGH_KEYWORD_ID] = nil

            if next(exhaustedKeywordInstances[card.instanceId]) == nil then
                exhaustedKeywordInstances[card.instanceId] = nil
            end
        end

        if card and card.exhaustedKeywords then
            card.exhaustedKeywords[TOUGH_KEYWORD_ID] = nil

            if next(card.exhaustedKeywords) == nil then
                card.exhaustedKeywords = nil
            end
        end
    end
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
    if card and card.keywordValues and card.keywordValues[keywordId] ~= nil then
        return tonumber(card.keywordValues[keywordId]) or 0
    end

    if not sourceDefinition or not keywordrules.cardHasKeyword(sourceDefinition, keywordId) then
        return nil
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

function keywordrules.setTemporaryKeywordValue(card, keywordId, keywordValue)
    if not card or not keywordId then
        return false
    end

    card.tempKeywords = card.tempKeywords or {}
    card.tempKeywordValues = card.tempKeywordValues or {}
    card.tempKeywords[keywordId] = 1
    card.tempKeywordValues[keywordId] = math.max(0, tonumber(keywordValue) or 0)
    return true
end

function keywordrules.removeTemporaryKeyword(card, keywordId)
    if not card or not keywordId then
        return false
    end

    if card.tempKeywords then
        card.tempKeywords[keywordId] = nil
    end

    if card.tempKeywordValues then
        card.tempKeywordValues[keywordId] = nil
    end

    return true
end

function keywordrules.addCardKeywordValue(card, cardDefinition, keywordId, amount)
    if not card or not keywordId then
        return nil
    end

    local keywordDefinition = keywordrules.getKeywordDefinition(keywordId)
    local incrementAmount = math.max(0, tonumber(amount) or 0)

    if not keywordDefinition or keywordDefinition.hasvalue ~= 1 or incrementAmount <= 0 then
        return nil
    end

    keywordrules.initializeCardKeywordState(card, cardDefinition)
    card.keywordValues = card.keywordValues or {}

    local currentValue = card.keywordValues[keywordId]

    if currentValue == nil then
        currentValue = keywordrules.cardHasKeyword(cardDefinition, keywordId, card)
            and (tonumber(getDefinitionKeywordValue(cardDefinition, keywordId)) or 0)
            or 0
    end

    card.keywordValues[keywordId] = math.max(0, tonumber(currentValue) or 0) + incrementAmount

    if card.keywordValues[keywordId] <= 0 then
        card.keywordValues[keywordId] = nil
        return nil
    end

    if keywordId == GROWTH_KEYWORD_ID and card.currentHealth ~= nil then
        card.maxHealth = math.max(0, tonumber(card.maxHealth) or 0) + incrementAmount
        card.currentHealth = math.max(0, tonumber(card.currentHealth) or 0) + incrementAmount
    end

    return card.keywordValues[keywordId]
end

function keywordrules.removeKeywordValueIfEmpty(entity, keywordId)
    if not entity or not keywordId or not entity.keywordValues then
        return false
    end

    if (tonumber(entity.keywordValues[keywordId]) or 0) <= 0 then
        entity.keywordValues[keywordId] = nil
        return true
    end

    return false
end

function keywordrules.getWoundValue(entity, definition)
    local woundValue = keywordrules.getCardKeywordValue(entity, definition, WOUND_KEYWORD_ID)
    keywordrules.removeKeywordValueIfEmpty(entity, WOUND_KEYWORD_ID)
    return math.max(0, tonumber(woundValue) or 0)
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

    local passiveKeywordValue = getPassiveScriptKeywordValue(card, cardDefinition, keywordId)

    if passiveKeywordValue ~= nil then
        keywordValue = keywordValue + passiveKeywordValue
        hasKeywordValue = true
    end

    if not hasKeywordValue then
        return nil
    end

    return keywordValue
end

function keywordrules.syncPassiveGrowthHealth(card, cardDefinition)
    if not card or not cardDefinition or card.currentHealth == nil or card.maxHealth == nil then
        return nil
    end

    local passiveGrowthValue = getPassiveScriptKeywordValue(card, cardDefinition, GROWTH_KEYWORD_ID) or 0
    local previousPassiveGrowthValue = math.max(0, tonumber(card.passiveGrowthHealthBonus) or 0)
    local delta = passiveGrowthValue - previousPassiveGrowthValue

    if delta == 0 then
        return passiveGrowthValue
    end

    local currentMaxHealth = math.max(0, tonumber(card.maxHealth) or 0)
    local updatedMaxHealth = math.max(0, currentMaxHealth + delta)
    local updatedCurrentHealth = math.max(0, tonumber(card.currentHealth) or 0) + delta

    card.maxHealth = updatedMaxHealth
    card.currentHealth = math.max(0, math.min(updatedCurrentHealth, updatedMaxHealth))
    card.passiveGrowthHealthBonus = passiveGrowthValue > 0 and passiveGrowthValue or nil

    return passiveGrowthValue
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

function keywordrules.isRageActive(card, cardDefinition)
    if not keywordrules.cardHasKeyword(cardDefinition, RAGE_KEYWORD_ID, card) then
        return false
    end

    local currentHealth = tonumber(card and card.currentHealth) or tonumber(cardDefinition and cardDefinition.health)
    local maxHealth = tonumber(card and card.maxHealth)
        or tonumber(cardDefinition and (cardDefinition.max or cardDefinition.health))

    if currentHealth == nil or maxHealth == nil or maxHealth <= 0 then
        return false
    end

    return currentHealth <= math.ceil(maxHealth / 2)
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

            if temporaryeffects.hasTemporaryKeyword(card, RELOADING_KEYWORD_ID) then
                card.tempKeywordValues = card.tempKeywordValues or {}
                card.tempKeywordValues[RELOADING_KEYWORD_ID] = (tonumber(card.tempKeywordValues[RELOADING_KEYWORD_ID]) or 0) - 1

                if card.tempKeywordValues[RELOADING_KEYWORD_ID] <= 0 then
                    keywordrules.removeTemporaryKeyword(card, RELOADING_KEYWORD_ID)
                end
            end
        end
    end

    return expiredCardIndices
end

return keywordrules
