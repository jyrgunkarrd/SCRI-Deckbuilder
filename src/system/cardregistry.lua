local cardregistry = {}

local CARD_DIRECTORY = "data/cards"
local CARD_MODULE_PREFIX = "data.cards."

local cardsBySet = nil
local cardsById = nil

local function loadRegistry()
    if cardsBySet ~= nil and cardsById ~= nil then
        return
    end

    cardsBySet = {}
    cardsById = {}

    for _, fileName in ipairs(love.filesystem.getDirectoryItems(CARD_DIRECTORY)) do
        if fileName:sub(-4) == ".lua" then
            local setName = fileName:sub(1, -5)
            local ok, definitions = pcall(require, CARD_MODULE_PREFIX .. setName)

            if ok and type(definitions) == "table" then
                cardsBySet[setName] = definitions

                for _, definition in ipairs(definitions) do
                    if definition.id then
                        definition.setName = setName
                        cardsById[definition.id] = definition
                    end
                end
            end
        end
    end
end

function cardregistry.getSet(setName)
    loadRegistry()
    return cardsBySet[setName]
end

function cardregistry.getCard(setName, cardId)
    loadRegistry()

    if setName then
        local definitions = cardsBySet[setName]

        if not definitions then
            return nil
        end

        for _, definition in ipairs(definitions) do
            if definition.id == cardId then
                return definition
            end
        end

        return nil
    end

    return cardsById[cardId]
end

function cardregistry.getCardById(cardId)
    loadRegistry()
    return cardsById[cardId]
end

function cardregistry.getAllCards()
    loadRegistry()

    local cards = {}

    for _, definition in pairs(cardsById or {}) do
        cards[#cards + 1] = definition
    end

    table.sort(cards, function(left, right)
        return tostring(left and left.id or "") < tostring(right and right.id or "")
    end)

    return cards
end

function cardregistry.reload()
    cardsBySet = nil
    cardsById = nil
    loadRegistry()
end

return cardregistry
