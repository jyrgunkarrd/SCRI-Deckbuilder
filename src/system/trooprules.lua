local trooprules = {}

local TROOP_CARD_TYPE = "troop"
local TOKEN_CARD_TYPE = "token"
local AGENT_CARD_TYPE = "agent"

local funcHandlers = {}

local function getFirstTargetCardId(troopDefinition)
    if type(troopDefinition.target) == "table" then
        return troopDefinition.target[1]
    end

    return troopDefinition.target
end

local function getFuncNameForTrigger(troopDefinition, triggerName)
    if not troopDefinition or not troopDefinition.func or not triggerName then
        return nil
    end

    local funcName = tostring(troopDefinition.func):lower()
    local funcTrigger = troopDefinition.functrig and tostring(troopDefinition.functrig):lower() or nil
    local normalizedTrigger = tostring(triggerName):lower()

    if funcName == "deathspawn" then
        return normalizedTrigger == "death" and "spawn" or nil
    end

    if funcName == "deathdraw" then
        return normalizedTrigger == "death" and "draw" or nil
    end

    if funcTrigger ~= nil then
        return funcTrigger == normalizedTrigger and funcName or nil
    end

    return normalizedTrigger == "play" and funcName or nil
end

function trooprules.getFirstTargetCardId(troopDefinition)
    return getFirstTargetCardId(troopDefinition)
end

funcHandlers.Draw = function(effectDefinition, state)
    local drawCount = math.max(0, math.floor(tonumber(effectDefinition.value) or 0))

    if drawCount <= 0 or not state.ctx.drawCardFromPlayerDeck then
        return false
    end

    for _ = 1, drawCount do
        if not state.ctx.drawCardFromPlayerDeck() then
            break
        end
    end

    return true
end
funcHandlers.draw = funcHandlers.Draw

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

local function isUnitDefinition(cardDefinition)
    return cardDefinition
        and (
            cardDefinition.type == TROOP_CARD_TYPE
            or cardDefinition.type == TOKEN_CARD_TYPE
            or cardDefinition.type == AGENT_CARD_TYPE
        )
        or false
end

function trooprules.isSpawnTroopDefinition(troopDefinition)
    local funcName = getFuncNameForTrigger(troopDefinition, "play")
    return trooprules.isTroopDefinition(troopDefinition)
        and funcName ~= nil
        and funcName == "spawn"
end

function trooprules.isSpawnPreviewTroopDefinition(troopDefinition)
    local playFuncName = getFuncNameForTrigger(troopDefinition, "play")
    local deathFuncName = getFuncNameForTrigger(troopDefinition, "death")

    return trooprules.isTroopDefinition(troopDefinition)
        and (playFuncName == "spawn" or deathFuncName == "spawn")
end

local function executeTroopEffect(troopDefinition, triggerName, state)
    local funcName = getFuncNameForTrigger(troopDefinition, triggerName)

    if funcName then
        local handler = funcHandlers[funcName] or funcHandlers[tostring(funcName):lower()]

        if handler then
            return handler(troopDefinition, state) ~= false
        end
    end

    return true
end

local function executeAttachedKitEffects(hostCard, triggerName, state)
    for _, attachedKit in ipairs(hostCard and hostCard.attachedKitCards or {}) do
        local attachedDefinition = attachedKit and state.ctx.cardregistry.getCard(attachedKit.setName, attachedKit.cardId) or nil

        if attachedDefinition and attachedDefinition.func then
            executeTroopEffect(attachedDefinition, triggerName, state)
        end
    end
end

function trooprules.resolvePlay(troopCardIndex, ctx)
    local troopCard = troopCardIndex and ctx.cards[troopCardIndex] or nil
    local troopDefinition = troopCard and ctx.cardregistry.getCard(troopCard.setName, troopCard.cardId) or nil

    if not trooprules.isTroopDefinition(troopDefinition) then
        return false
    end

    return executeTroopEffect(troopDefinition, "play", {
        cards = ctx.cards,
        troopCardIndex = troopCardIndex,
        troopCard = troopCard,
        definition = troopDefinition,
        ctx = ctx,
    })
end

function trooprules.resolveDeath(troopCardIndex, ctx)
    local troopCard = troopCardIndex and ctx.cards[troopCardIndex] or nil
    local troopDefinition = troopCard and ctx.cardregistry.getCard(troopCard.setName, troopCard.cardId) or nil

    if not isUnitDefinition(troopDefinition) then
        return false
    end

    local state = {
        cards = ctx.cards,
        troopCardIndex = troopCardIndex,
        troopCard = troopCard,
        definition = troopDefinition,
        ctx = ctx,
    }

    local resolvedOwnEffect = executeTroopEffect(troopDefinition, "death", state)
    executeAttachedKitEffects(troopCard, "death", state)
    return resolvedOwnEffect
end

return trooprules
