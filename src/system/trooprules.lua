local trooprules = {}

local TROOP_CARD_TYPE = "troop"

local funcHandlers = {}

local function getFirstTargetCardId(troopDefinition)
    if type(troopDefinition.target) == "table" then
        return troopDefinition.target[1]
    end

    return troopDefinition.target
end

function trooprules.getFirstTargetCardId(troopDefinition)
    return getFirstTargetCardId(troopDefinition)
end

funcHandlers.Spawn = function(troopDefinition, state)
    local tokenCardId = getFirstTargetCardId(troopDefinition)
    local tokenDefinition = tokenCardId and state.ctx.cardregistry.getCardById(tokenCardId) or nil
    local spawnCount = math.max(0, math.floor(tonumber(troopDefinition.value) or 0))

    if not tokenDefinition or spawnCount <= 0 or not state.ctx.spawnTokensNearPlayerCard then
        return false
    end

    state.ctx.spawnTokensNearPlayerCard(state.troopCardIndex, tokenDefinition, spawnCount)
    return true
end
funcHandlers.spawn = funcHandlers.Spawn

function trooprules.isTroopDefinition(cardDefinition)
    return cardDefinition and cardDefinition.type == TROOP_CARD_TYPE or false
end

function trooprules.isSpawnTroopDefinition(troopDefinition)
    local funcName = troopDefinition and troopDefinition.func
    return trooprules.isTroopDefinition(troopDefinition)
        and funcName ~= nil
        and tostring(funcName):lower() == "spawn"
end

local function executeTroopPlayEffect(troopDefinition, state)
    if troopDefinition.func then
        local handler = funcHandlers[troopDefinition.func] or funcHandlers[tostring(troopDefinition.func):lower()]

        if handler then
            return handler(troopDefinition, state) ~= false
        end
    end

    return true
end

function trooprules.resolvePlay(troopCardIndex, ctx)
    local troopCard = troopCardIndex and ctx.cards[troopCardIndex] or nil
    local troopDefinition = troopCard and ctx.cardregistry.getCard(troopCard.setName, troopCard.cardId) or nil

    if not trooprules.isTroopDefinition(troopDefinition) then
        return false
    end

    return executeTroopPlayEffect(troopDefinition, {
        cards = ctx.cards,
        troopCardIndex = troopCardIndex,
        troopCard = troopCard,
        definition = troopDefinition,
        ctx = ctx,
    })
end

return trooprules
