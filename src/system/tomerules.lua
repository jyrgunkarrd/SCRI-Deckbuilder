local tomerules = {}

local TOME_CARD_TYPE = "tome"

local funcHandlers = {}

local function getFirstTargetCardId(tomeDefinition)
    if type(tomeDefinition.target) == "table" then
        return tomeDefinition.target[1]
    end

    return tomeDefinition.target
end

function tomerules.getFirstTargetCardId(tomeDefinition)
    return getFirstTargetCardId(tomeDefinition)
end

local function isEngagePhase(ctx)
    return ctx.turnrules.getCurrentPhase() == "War"
        and ctx.turnrules.getCurrentWarSubphase() == "Engage"
end

funcHandlers.Spawn = function(tomeDefinition, state)
    local tokenCardId = getFirstTargetCardId(tomeDefinition)
    local tokenDefinition = tokenCardId and state.ctx.cardregistry.getCardById(tokenCardId) or nil
    local spawnCount = math.max(0, math.floor(tonumber(tomeDefinition.value) or 0))

    if not tokenDefinition or spawnCount <= 0 or not state.ctx.spawnTokensNearCard then
        return false
    end

    state.ctx.spawnTokensNearCard(state.tomeCardIndex, tokenDefinition, spawnCount)
    return true
end
funcHandlers.spawn = funcHandlers.Spawn

function tomerules.isTomeDefinition(cardDefinition)
    return cardDefinition and cardDefinition.type == TOME_CARD_TYPE or false
end

function tomerules.isTomeCard(card, ctx)
    local cardDefinition = card and ctx.cardregistry.getCard(card.setName, card.cardId) or nil
    return tomerules.isTomeDefinition(cardDefinition)
end

function tomerules.isSpawnTomeDefinition(tomeDefinition)
    local funcName = tomeDefinition and tomeDefinition.func
    return tomerules.isTomeDefinition(tomeDefinition)
        and funcName ~= nil
        and tostring(funcName):lower() == "spawn"
end

local function executeTomeEffect(tomeDefinition, state)
    for _, fieldName in ipairs({ "onUse", "use", "execute" }) do
        if type(tomeDefinition[fieldName]) == "function" then
            return tomeDefinition[fieldName](state) ~= false
        end
    end

    if tomeDefinition.func then
        local handler = funcHandlers[tomeDefinition.func] or funcHandlers[tostring(tomeDefinition.func):lower()]

        if handler then
            return handler(tomeDefinition, state) ~= false
        end
    end

    return true
end

function tomerules.canUseTome(tomeCard, ctx)
    local tomeDefinition = tomeCard and ctx.cardregistry.getCard(tomeCard.setName, tomeCard.cardId) or nil
    local syntacCost = math.max(0, tonumber(tomeDefinition and tomeDefinition.syncost) or 0)
    local syntacCount = math.max(0, tonumber(ctx.getSyntacCount and ctx.getSyntacCount()) or 0)

    return isEngagePhase(ctx)
        and tomerules.isTomeDefinition(tomeDefinition)
        and tomeCard.location
        and tomeCard.location.kind == "grid"
        and tomeCard.location.rowId == "PlayerRow"
        and syntacCount >= syntacCost
end

function tomerules.useTome(tomeCardIndex, ctx)
    local tomeCard = tomeCardIndex and ctx.cards[tomeCardIndex] or nil
    local tomeDefinition = tomeCard and ctx.cardregistry.getCard(tomeCard.setName, tomeCard.cardId) or nil

    if not tomerules.canUseTome(tomeCard, ctx) then
        return false
    end

    if not executeTomeEffect(tomeDefinition, {
        cards = ctx.cards,
        tomeCardIndex = tomeCardIndex,
        tomeCard = tomeCard,
        definition = tomeDefinition,
        ctx = ctx,
    }) then
        return false
    end

    if ctx.spendSyntac then
        ctx.spendSyntac(math.max(0, tonumber(tomeDefinition.syncost) or 0))
    end

    return true
end

return tomerules
