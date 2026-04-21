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

local function getTargetTypeSet(targetTypes)
    local set = {}

    if type(targetTypes) == "table" then
        for _, targetType in ipairs(targetTypes) do
            if type(targetType) == "string" then
                set[targetType:lower()] = true
            end
        end
    elseif type(targetTypes) == "string" then
        set[targetTypes:lower()] = true
    end

    return set
end

local function isSelectableSacrificeTarget(card, strategyDefinition, ctx)
    if not card
        or not card.location
        or card.location.kind ~= "grid"
        or card.location.rowId ~= "PlayerRow"
        or card.destroyed
        or card.destroying then
        return false
    end

    local cardDefinition = ctx.cardregistry.getCard(card.setName, card.cardId)
    local allowedTargetTypes = getTargetTypeSet(strategyDefinition and strategyDefinition.target or nil)

    return cardDefinition
        and cardDefinition.type
        and allowedTargetTypes[tostring(cardDefinition.type):lower()] == true
end

function strategyrules.isValidFunccostTarget(cardIndex, pendingSelection, ctx)
    local card = cardIndex and ctx.cards and ctx.cards[cardIndex] or nil

    if not pendingSelection or not card then
        return false
    end

    if tostring(pendingSelection.funccost or ""):lower() == "sactarg" then
        return isSelectableSacrificeTarget(card, pendingSelection.definition, ctx)
    end

    return false
end

local function beginPendingStrategySelection(strategyDefinition, state)
    if not state.ctx.beginPendingStrategySelection then
        return false
    end

    return state.ctx.beginPendingStrategySelection({
        strategyCardIndex = state.strategyCardIndex,
        targetCardIndex = state.targetCardIndex,
        strategyCard = state.strategyCard,
        targetCard = state.targetCard,
        definition = strategyDefinition,
        funccost = strategyDefinition.funccost,
    })
end

local function applyCounterstrikeDamage(selectedCardIndex, pendingSelection, ctx)
    local strategyDefinition = pendingSelection and pendingSelection.definition or nil
    local damageAmount = math.max(0, tonumber(strategyDefinition and strategyDefinition.value) or 0)
    local displayStates = ctx.warrules.getDisplayStates and ctx.warrules.getDisplayStates() or {}
    local pendingTargets = {}
    local damagedAny = false

    for entityKey, rollState in pairs(displayStates) do
        if rollState
            and ctx.warrules.canTargetEnemyCard(rollState)
            and rollState.targetCardIndex == selectedCardIndex then
            pendingTargets[#pendingTargets + 1] = {
                entityKey = entityKey,
                sourceCard = rollState.sourceCard,
            }
        end
    end

    for _, target in ipairs(pendingTargets) do
        if target.entityKey == "champion" then
            local damageResult = ctx.dealDamageToChampion and ctx.dealDamageToChampion(damageAmount) or nil
            damagedAny = damagedAny or (damageResult and damageResult.changed) or false
        elseif target.sourceCard then
            local damageResult = ctx.dealDamageToCard and ctx.dealDamageToCard(target.sourceCard, damageAmount) or nil
            damagedAny = damagedAny or (damageResult and damageResult.changed) or false
        end
    end

    return damagedAny
end

function strategyrules.resolvePendingSelection(selectedCardIndex, pendingSelection, ctx)
    if not selectedCardIndex or not pendingSelection or not ctx then
        return false
    end

    if not strategyrules.isValidFunccostTarget(selectedCardIndex, pendingSelection, ctx) then
        return false
    end

    if tostring(pendingSelection.funccost or ""):lower() == "sactarg" then
        if ctx.startCardDestruction then
            ctx.startCardDestruction(selectedCardIndex)
        elseif ctx.discardCard then
            ctx.discardCard(selectedCardIndex)
        end

        if tostring((pendingSelection.definition and pendingSelection.definition.func) or ""):lower() == "counterstrk" then
            applyCounterstrikeDamage(selectedCardIndex, pendingSelection, ctx)
        end

        if ctx.warrules.retargetIllegalEnemyAttacks then
            ctx.warrules.retargetIllegalEnemyAttacks(ctx.cards)
        end

        return true
    end

    return false
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

    local state = {
        cards = ctx.cards,
        strategyCardIndex = strategyCardIndex,
        targetCardIndex = targetCardIndex,
        strategyCard = strategyCard,
        targetCard = ctx.cards[targetCardIndex],
        definition = strategyDefinition,
        ctx = ctx,
    }

    local hasPendingFunccost = strategyDefinition.funccost ~= nil

    if not hasPendingFunccost and not executeStrategyEffect(strategyDefinition, {
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

    if ctx.warrules.retargetIllegalEnemyAttacks and not hasPendingFunccost then
        ctx.warrules.retargetIllegalEnemyAttacks(ctx.cards)
    end

    ctx.discardCard(strategyCardIndex)

    if hasPendingFunccost then
        beginPendingStrategySelection(strategyDefinition, state)
    end

    return true
end

return strategyrules
