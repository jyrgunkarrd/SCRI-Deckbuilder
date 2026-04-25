local trooprules = {}

local TROOP_CARD_TYPE = "troop"
local TOKEN_CARD_TYPE = "token"
local AGENT_CARD_TYPE = "agent"
local CACHE_CARD_ID = "MEATTOK"
local CARD_SCRIPT_MODULE_PREFIX = "data.cards.scripts."

local funcHandlers = {}
local cardScriptHandlers = {}

local function getFirstTargetCardId(troopDefinition)
    if type(troopDefinition.target) == "table" then
        return troopDefinition.target[1]
    end

    return troopDefinition.target
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

    if funcName == "killmeattok" then
        return normalizedTrigger == "kill" and "killmeattok" or nil
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

funcHandlers.killmeattok = function(effectDefinition, state)
    local cacheDefinition = state.ctx.cardregistry.getCardById(CACHE_CARD_ID)
    local cacheCount = math.max(0, math.floor(tonumber(effectDefinition.value) or 0))

    if not cacheDefinition or cacheCount <= 0 or not state.ctx.createOrStackPlayerCacheNearCard then
        return false
    end

    state.ctx.createOrStackPlayerCacheNearCard(state.troopCardIndex, cacheDefinition, cacheCount)
    return true
end

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

    return isUnitDefinition(troopDefinition)
        and (playFuncName == "spawn" or deathFuncName == "spawn")
end

function trooprules.getPreviewCardIds(troopDefinition)
    if not isUnitDefinition(troopDefinition) then
        return nil, nil
    end

    local playFuncName = getFuncNameForTrigger(troopDefinition, "play")
    local deathFuncName = getFuncNameForTrigger(troopDefinition, "death")
    local killFuncName = getFuncNameForTrigger(troopDefinition, "kill")

    if playFuncName == "spawn" or deathFuncName == "spawn" then
        local targetCardId = getFirstTargetCardId(troopDefinition)
        return targetCardId and { targetCardId } or nil, "SUMMON"
    end

    if killFuncName == "killmeattok" then
        return { CACHE_CARD_ID }, "CACHE"
    end

    return nil, nil
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

function trooprules.resolveKill(troopCardIndex, targetCardIndex, ctx)
    local troopCard = troopCardIndex and ctx.cards[troopCardIndex] or nil
    local troopDefinition = troopCard and ctx.cardregistry.getCard(troopCard.setName, troopCard.cardId) or nil

    if not isUnitDefinition(troopDefinition) then
        return false
    end

    local state = {
        cards = ctx.cards,
        troopCardIndex = troopCardIndex,
        troopCard = troopCard,
        targetCardIndex = targetCardIndex,
        targetCard = targetCardIndex and ctx.cards[targetCardIndex] or nil,
        definition = troopDefinition,
        ctx = ctx,
    }

    local resolvedOwnEffect = executeTroopEffect(troopDefinition, "kill", state)
    executeAttachedKitEffects(troopCard, "kill", state)
    return resolvedOwnEffect
end

function trooprules.beginEndPhaseSelection(ctx)
    for cardIndex, card in ipairs(ctx.cards or {}) do
        if card
            and not ctx.isCardUnavailable(card)
            and card.location
            and card.location.kind == "grid"
            and card.location.rowId == "PlayerRow" then
            local troopDefinition = ctx.cardregistry.getCard(card.setName, card.cardId)
            local handler = troopDefinition and getCardScriptHandler(troopDefinition.func) or nil

            if handler and type(handler.beginEndPhaseSelection) == "function" then
                local selection = handler.beginEndPhaseSelection(cardIndex, {
                    card = card,
                    definition = troopDefinition,
                    ctx = ctx,
                })

                if selection then
                    return selection
                end
            end
        end
    end

    return nil
end

function trooprules.isValidPendingSacrificeTarget(cardIndex, pendingSelection, ctx)
    local card = cardIndex and ctx.cards and ctx.cards[cardIndex] or nil

    if not pendingSelection or pendingSelection.kind ~= "troop_script_sacrifice" or not card then
        return false
    end

    if not card.location
        or card.location.kind ~= "grid"
        or card.location.rowId ~= "PlayerRow"
        or card.destroyed
        or card.destroying then
        return false
    end

    local cardDefinition = ctx.cardregistry.getCard(card.setName, card.cardId)

    return cardDefinition
        and (
            cardDefinition.type == TROOP_CARD_TYPE
            or cardDefinition.type == TOKEN_CARD_TYPE
        )
        or false
end

function trooprules.notifyPlayerRowUnitDefeated(defeatedCardIndex, ctx)
    local defeatedCard = defeatedCardIndex and ctx.cards[defeatedCardIndex] or nil
    local defeatedDefinition = defeatedCard and ctx.cardregistry.getCard(defeatedCard.setName, defeatedCard.cardId) or nil

    if not defeatedCard
        or not defeatedDefinition
        or not defeatedCard.location
        or defeatedCard.location.kind ~= "grid"
        or defeatedCard.location.rowId ~= "PlayerRow"
        or not isUnitDefinition(defeatedDefinition) then
        return false
    end

    for cardIndex, card in ipairs(ctx.cards or {}) do
        if card
            and not ctx.isCardUnavailable(card)
            and card.location
            and card.location.kind == "grid"
            and card.location.rowId == "PlayerRow" then
            local troopDefinition = ctx.cardregistry.getCard(card.setName, card.cardId)
            local handler = troopDefinition and getCardScriptHandler(troopDefinition.func) or nil

            if handler and type(handler.onPlayerRowUnitDefeated) == "function" then
                handler.onPlayerRowUnitDefeated(cardIndex, defeatedCardIndex, {
                    card = card,
                    definition = troopDefinition,
                    defeatedCard = defeatedCard,
                    defeatedDefinition = defeatedDefinition,
                    ctx = ctx,
                })
            end
        end
    end

    return true
end

function trooprules.notifyMeatCacheDecayed(cacheCardIndex, ctx)
    for cardIndex, card in ipairs(ctx.cards or {}) do
        if card
            and not ctx.isCardUnavailable(card)
            and card.location
            and card.location.kind == "grid"
            and card.location.rowId == "PlayerRow" then
            local troopDefinition = ctx.cardregistry.getCard(card.setName, card.cardId)
            local handler = troopDefinition and getCardScriptHandler(troopDefinition.func) or nil

            if handler and type(handler.onMeatCacheDecayed) == "function" then
                handler.onMeatCacheDecayed(cardIndex, cacheCardIndex, {
                    card = card,
                    definition = troopDefinition,
                    ctx = ctx,
                })
            end
        end
    end

    return true
end

return trooprules
