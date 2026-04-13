local cardregistry = require("src.system.cardregistry")
local keywordrules = require("src.system.keywordrules")
local namerules = require("src.system.namerules")

local cardinstances = {}

local generatedCardInstanceCounter = 0

function cardinstances.reset()
    generatedCardInstanceCounter = 0
end

function cardinstances.copyLocation(location)
    if not location then
        return nil
    end

    return {
        kind = location.kind,
        slotIndex = location.slotIndex,
        rowId = location.rowId,
        column = location.column,
    }
end

function cardinstances.initializeHealth(card)
    if not card then
        return
    end

    local cardDefinition = cardregistry.getCard(card.setName, card.cardId)
    keywordrules.initializeCardKeywordState(card, cardDefinition)

    if not cardDefinition or cardDefinition.health == nil then
        return
    end

    card.maxHealth = card.maxHealth or cardDefinition.max or cardDefinition.health
    card.currentHealth = card.currentHealth or cardDefinition.health
end

function cardinstances.initializeAllHealth(cardList)
    for _, card in ipairs(cardList or {}) do
        cardinstances.initializeHealth(card)
    end
end

function cardinstances.create(cardDefinition, instanceId, location, deckOwner)
    if not cardDefinition or not instanceId or not location then
        return nil
    end

    return namerules.applyRandomizedName({
        instanceId = instanceId,
        setName = cardDefinition.setName,
        cardId = cardDefinition.id,
        deckOwner = deckOwner,
        location = cardinstances.copyLocation(location),
    }, cardDefinition)
end

function cardinstances.createGenerated(cardDefinition, location)
    if not cardDefinition or not location then
        return nil
    end

    generatedCardInstanceCounter = generatedCardInstanceCounter + 1

    return cardinstances.create(
        cardDefinition,
        cardDefinition.id .. ":generated:" .. tostring(generatedCardInstanceCounter),
        location,
        location.deckOwner
    )
end

function cardinstances.addToActiveCards(cards, cardExpansion, cardEntranceProgress, card, entranceProgress)
    if not cards or not card then
        return nil
    end

    cards[#cards + 1] = card

    if cardExpansion then
        cardExpansion[#cards] = 0
    end

    if cardEntranceProgress then
        cardEntranceProgress[#cards] = entranceProgress or 1
    end

    return card
end

function cardinstances.createGeneratedSupportCard(cards, cardExpansion, cardEntranceProgress, playerDeck, cardDefinition, targetLocation)
    if not cardDefinition or not targetLocation then
        return nil
    end

    if targetLocation.kind == "hand" then
        local generatedCard = cardinstances.createGenerated(cardDefinition, {
            kind = "hand",
            slotIndex = targetLocation.slotIndex,
        })

        if not generatedCard then
            return nil
        end

        cardinstances.initializeHealth(generatedCard)
        return cardinstances.addToActiveCards(cards, cardExpansion, cardEntranceProgress, generatedCard, 1)
    end

    if targetLocation.kind ~= "deck" or not playerDeck then
        return nil
    end

    local generatedDeckCard = cardinstances.createGenerated(cardDefinition, {
        kind = "deck",
        deckOwner = "player",
    })

    if not generatedDeckCard then
        return nil
    end

    generatedDeckCard.deckOwner = "player"
    playerDeck.cards[#playerDeck.cards + 1] = generatedDeckCard
    return generatedDeckCard
end

function cardinstances.createGeneratedDeckCardShuffled(playerDeck, cardDefinition)
    if not cardDefinition or not playerDeck then
        return nil
    end

    local generatedDeckCard = cardinstances.createGenerated(cardDefinition, {
        kind = "deck",
        deckOwner = "player",
    })

    if not generatedDeckCard then
        return nil
    end

    generatedDeckCard.deckOwner = "player"
    local insertIndex = love.math.random(1, #playerDeck.cards + 1)
    table.insert(playerDeck.cards, insertIndex, generatedDeckCard)
    return generatedDeckCard
end

function cardinstances.createGeneratedGridCard(cards, cardExpansion, cardEntranceProgress, cardDefinition, rowId, column)
    if not cardDefinition or not rowId or not column then
        return nil
    end

    local generatedCard = cardinstances.createGenerated(cardDefinition, {
        kind = "grid",
        rowId = rowId,
        column = column,
    })

    if not generatedCard then
        return nil
    end

    cardinstances.initializeHealth(generatedCard)
    return cardinstances.addToActiveCards(cards, cardExpansion, cardEntranceProgress, generatedCard, 1)
end

return cardinstances
