local keywordrules = require("src.system.keywordrules")

local strategyrules = {}

local STRATEGIST_KEYWORD_ID = "KWSTRAT"
local ELITE_KEYWORD_ID = "KWELITE"
local CARD_SCRIPT_MODULE_PREFIX = "data.cards.scripts."

local effectHandlers = {}
local funcHandlers = {}
local cardScriptHandlers = {}

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

local function triggerStrategistExhaust(targetCardIndex, state)
    local targetCard = targetCardIndex and state.ctx.cards[targetCardIndex] or nil
    local targetDefinition = targetCard and state.ctx.cardregistry.getCard(targetCard.setName, targetCard.cardId) or nil
    local handler = targetDefinition and getCardScriptHandler(targetDefinition.func) or nil

    if handler and type(handler.onStrategistExhaust) == "function" then
        handler.onStrategistExhaust(targetCardIndex, state)
    end
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

local function refreshEliteCards(ctx)
    for cardIndex, card in ipairs(ctx.cards or {}) do
        if card
            and card.location
            and card.location.kind == "grid"
            and card.location.rowId == "PlayerRow"
            and not card.destroyed
            and not card.destroying then
            local definition = ctx.cardregistry.getCard(card.setName, card.cardId)

            if keywordrules.cardHasKeyword(definition, ELITE_KEYWORD_ID, card) then
                ctx.warrules.rerollEntity(ctx.warrules.getCardEntityKey(cardIndex), definition, false, card)
            end
        end
    end
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

    triggerStrategistExhaust(targetCardIndex, {
        cards = ctx.cards,
        strategyCardIndex = strategyCardIndex,
        targetCardIndex = targetCardIndex,
        strategyCard = strategyCard,
        targetCard = ctx.cards[targetCardIndex],
        definition = strategyDefinition,
        ctx = ctx,
    })

    refreshEliteCards(ctx)

    if ctx.warrules.retargetIllegalEnemyAttacks then
        ctx.warrules.retargetIllegalEnemyAttacks(ctx.cards)
    end

    ctx.discardCard(strategyCardIndex)
    return true
end

return strategyrules
