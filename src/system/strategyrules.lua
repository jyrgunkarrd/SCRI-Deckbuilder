local keywordrules = require("src.system.keywordrules")

local strategyrules = {}

local STRATEGIST_KEYWORD_ID = "KWSTRAT"

local effectHandlers = {}
local funcHandlers = {}

local function getFirstTargetCardId(strategyDefinition)
    if type(strategyDefinition.target) == "table" then
        return strategyDefinition.target[1]
    end

    return strategyDefinition.target
end

function strategyrules.getFirstTargetCardId(strategyDefinition)
    return getFirstTargetCardId(strategyDefinition)
end

funcHandlers.Spawn = function(strategyDefinition, state)
    local tokenCardId = getFirstTargetCardId(strategyDefinition)
    local tokenDefinition = tokenCardId and state.ctx.cardregistry.getCardById(tokenCardId) or nil
    local spawnCount = math.max(0, math.floor(tonumber(strategyDefinition.value) or 0))

    if not tokenDefinition or spawnCount <= 0 or not state.ctx.spawnTokensNearCard then
        return false
    end

    state.ctx.spawnTokensNearCard(state.targetCardIndex, tokenDefinition, spawnCount)
    return true
end
funcHandlers.spawn = funcHandlers.Spawn

local function isEngagePhase(ctx)
    return ctx.turnrules.getCurrentPhase() == "War"
        and ctx.turnrules.getCurrentWarSubphase() == "Engage"
end

function strategyrules.isStrategyDefinition(cardDefinition)
    return cardDefinition and cardDefinition.type == "strategy" or false
end

function strategyrules.isSpawnStrategyDefinition(strategyDefinition)
    local funcName = strategyDefinition and strategyDefinition.func
    return strategyrules.isStrategyDefinition(strategyDefinition)
        and funcName ~= nil
        and tostring(funcName):lower() == "spawn"
end

function strategyrules.isStrategyCard(card, ctx)
    local cardDefinition = card and ctx.cardregistry.getCard(card.setName, card.cardId) or nil
    return strategyrules.isStrategyDefinition(cardDefinition)
end

function strategyrules.isStrategistDefinition(cardDefinition)
    return keywordrules.cardHasKeyword(cardDefinition, STRATEGIST_KEYWORD_ID)
end

local function executeStrategyEffect(strategyDefinition, state)
    for _, fieldName in ipairs({ "onPlay", "play", "execute" }) do
        if type(strategyDefinition[fieldName]) == "function" then
            return strategyDefinition[fieldName](state) ~= false
        end
    end

    if strategyDefinition.effect then
        local handler = effectHandlers[strategyDefinition.effect]

        if handler then
            return handler(strategyDefinition, state) ~= false
        end
    end

    if strategyDefinition.func then
        local handler = funcHandlers[strategyDefinition.func] or funcHandlers[tostring(strategyDefinition.func):lower()]

        if handler then
            return handler(strategyDefinition, state) ~= false
        end
    end

    return true
end

function strategyrules.registerEffectHandler(effectName, handler)
    if effectName and type(handler) == "function" then
        effectHandlers[effectName] = handler
    end
end

function strategyrules.registerFuncHandler(funcName, handler)
    if funcName and type(handler) == "function" then
        funcHandlers[funcName] = handler
    end
end

function strategyrules.canPlayStrategy(strategyCard, targetCardIndex, ctx)
    local targetCard = targetCardIndex and ctx.cards[targetCardIndex] or nil
    local strategyDefinition = strategyCard and ctx.cardregistry.getCard(strategyCard.setName, strategyCard.cardId) or nil
    local targetDefinition = targetCard and ctx.cardregistry.getCard(targetCard.setName, targetCard.cardId) or nil
    local targetRollState = targetCardIndex and ctx.warrules.getCardRollState(targetCardIndex) or nil

    return isEngagePhase(ctx)
        and strategyrules.isStrategyDefinition(strategyDefinition)
        and strategyCard.location
        and strategyCard.location.kind == "hand"
        and targetCard
        and targetCard.location
        and targetCard.location.kind == "grid"
        and targetCard.location.rowId == "PlayerRow"
        and strategyrules.isStrategistDefinition(targetDefinition)
        and targetRollState
        and targetRollState.exhausted ~= true
end

function strategyrules.playStrategy(strategyCardIndex, targetCardIndex, ctx)
    local strategyCard = strategyCardIndex and ctx.cards[strategyCardIndex] or nil
    local strategyDefinition = strategyCard and ctx.cardregistry.getCard(strategyCard.setName, strategyCard.cardId) or nil

    if not strategyrules.canPlayStrategy(strategyCard, targetCardIndex, ctx) then
        return false
    end

    if not executeStrategyEffect(strategyDefinition, {
        cards = ctx.cards,
        strategyCardIndex = strategyCardIndex,
        targetCardIndex = targetCardIndex,
        strategyCard = strategyCard,
        targetCard = ctx.cards[targetCardIndex],
        definition = strategyDefinition,
        ctx = ctx,
    }) then
        return false
    end

    if not ctx.warrules.consumeCardAttack(targetCardIndex) then
        return false
    end

    ctx.discardCard(strategyCardIndex)
    return true
end

return strategyrules
