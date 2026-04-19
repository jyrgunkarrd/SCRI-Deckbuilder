local cardregistry = require("src.system.cardregistry")
local deckdefinitions = require("data.decks")
local namerules = require("src.system.namerules")

local deckrules = {}

local decksById = nil

local function copyLocation(location)
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

local function loadDecks()
    if decksById ~= nil then
        return
    end

    decksById = {}

    for _, definition in ipairs(deckdefinitions) do
        if definition.id then
            decksById[definition.id] = definition
        end
    end
end

local function createDeckCard(cardDefinition, instanceIndex, location)
    return namerules.applyRandomizedName({
        instanceId = cardDefinition.id .. ":" .. tostring(instanceIndex),
        setName = cardDefinition.setName,
        cardId = cardDefinition.id,
        location = copyLocation(location),
    }, cardDefinition)
end

local function createDetachedDeckCard(deck, cardDefinition, location)
    local instanceIndex = ((deck and deck.createdCardCount) or 0) + 1

    if deck then
        deck.createdCardCount = instanceIndex
    end

    local card = createDeckCard(cardDefinition, instanceIndex, location)
    card.deckOwner = deck and deck.owner or nil
    return card
end

local function copyCardInstance(card, location)
    return {
        instanceId = card.instanceId,
        setName = card.setName,
        cardId = card.cardId,
        displayName = card.displayName,
        portraitPath = card.portraitPath,
        deckOwner = card.deckOwner,
        location = copyLocation(location),
    }
end

function deckrules.getDeckDefinition(deckId)
    loadDecks()
    return decksById[deckId]
end

function deckrules.buildDeck(deckId)
    local deckDefinition = deckrules.getDeckDefinition(deckId)

    if not deckDefinition then
        return nil
    end

    local builtDeck = {
        id = deckDefinition.id,
        name = deckDefinition.name,
        cards = {},
        discard = {},
        missingCards = {},
        createdCardCount = 0,
    }

    for _, deckEntry in ipairs(deckDefinition.cards or {}) do
        local cardDefinition = cardregistry.getCardById(deckEntry.cardId)

        if cardDefinition then
            for quantityIndex = 1, deckEntry.quantity or 0 do
                builtDeck.createdCardCount = builtDeck.createdCardCount + 1
                builtDeck.cards[#builtDeck.cards + 1] = createDeckCard(cardDefinition, builtDeck.createdCardCount, {
                    kind = "deck",
                })
            end
        else
            builtDeck.missingCards[#builtDeck.missingCards + 1] = {
                cardId = deckEntry.cardId,
                quantity = deckEntry.quantity or 0,
            }
        end
    end

    return builtDeck
end

function deckrules.discardCard(deck, card)
    if not deck or not card then
        return nil
    end

    local discardedCard = copyCardInstance(card, {
        kind = "discard",
    })

    deck.discard[#deck.discard + 1] = discardedCard
    return discardedCard
end

function deckrules.reshuffleDiscardIntoDeck(deck)
    if not deck or not deck.discard or #deck.discard == 0 then
        return false
    end

    for _, discardedCard in ipairs(deck.discard) do
        discardedCard.location = {
            kind = "deck",
        }
        deck.cards[#deck.cards + 1] = discardedCard
    end

    deck.discard = {}
    return true
end

local function ensureDeckHasCards(deck)
    if not deck then
        return false
    end

    if #deck.cards > 0 then
        return true
    end

    return deckrules.reshuffleDiscardIntoDeck(deck)
end

function deckrules.drawSpecificCardToHand(deck, cardId, slotIndex)
    if not deck or not cardId or not slotIndex then
        return nil
    end

    for cardIndex, card in ipairs(deck.cards or {}) do
        if card.cardId == cardId then
            local drawnCard = table.remove(deck.cards, cardIndex)
            return copyCardInstance(drawnCard, {
                kind = "hand",
                slotIndex = slotIndex,
            })
        end
    end

    local cardDefinition = cardregistry.getCardById(cardId)

    if not cardDefinition then
        deck.missingCards = deck.missingCards or {}
        deck.missingCards[#deck.missingCards + 1] = {
            cardId = cardId,
            quantity = 1,
        }
        return nil
    end

    return createDetachedDeckCard(deck, cardDefinition, {
        kind = "hand",
        slotIndex = slotIndex,
    })
end

function deckrules.assignCardsToHand(deck, handSize, options)
    local handCards = {}

    if not deck then
        return handCards
    end

    local startingSlotIndex = 1
    local firstCardId = options and options.firstCardId or nil

    if firstCardId and handSize >= startingSlotIndex then
        local firstCard = deckrules.drawSpecificCardToHand(deck, firstCardId, startingSlotIndex)

        if firstCard then
            handCards[#handCards + 1] = firstCard
            startingSlotIndex = startingSlotIndex + 1
        end
    end

    for slotIndex = startingSlotIndex, handSize do
        if not ensureDeckHasCards(deck) then
            break
        end

        local randomIndex = love.math.random(1, #deck.cards)
        local card = table.remove(deck.cards, randomIndex)

        handCards[#handCards + 1] = copyCardInstance(card, {
            kind = "hand",
            slotIndex = slotIndex,
        })
    end

    return handCards
end

function deckrules.drawCardToHand(deck, slotIndex)
    if not deck or not slotIndex or not ensureDeckHasCards(deck) then
        return nil
    end

    local randomIndex = love.math.random(1, #deck.cards)
    local card = table.remove(deck.cards, randomIndex)

    return copyCardInstance(card, {
        kind = "hand",
        slotIndex = slotIndex,
    })
end

return deckrules
