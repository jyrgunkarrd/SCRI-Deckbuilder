local buttonrules = {}

local CARD_SCRIPT_MODULE_PREFIX = "data.cards.scripts."
local cardScriptHandlers = {}

local function getCardScriptHandler(funcName)
    if not funcName then
        return nil
    end

    local scriptName = tostring(funcName)

    if cardScriptHandlers[scriptName] ~= nil then
        return cardScriptHandlers[scriptName] or nil
    end

    local ok, handler = pcall(require, CARD_SCRIPT_MODULE_PREFIX .. scriptName)

    if ok then
        cardScriptHandlers[scriptName] = handler
        return handler
    end

    if not tostring(handler):find("module '" .. CARD_SCRIPT_MODULE_PREFIX .. scriptName .. "' not found", 1, true) then
        error(handler)
    end

    cardScriptHandlers[scriptName] = false
    return nil
end

local function getButtonHandler(cardDefinition)
    local scriptHandler = getCardScriptHandler(cardDefinition and cardDefinition.func or nil)

    if type(scriptHandler) == "table" then
        return scriptHandler.button or scriptHandler.onButton or scriptHandler.click
    end

    if type(scriptHandler) == "function" then
        return scriptHandler
    end

    return nil
end

local function isButtonPhaseAllowed(ctx)
    local currentPhase = ctx and ctx.turnrules and ctx.turnrules.getCurrentPhase and ctx.turnrules.getCurrentPhase() or nil
    local currentWarSubphase = ctx
        and ctx.turnrules
        and ctx.turnrules.getCurrentWarSubphase
        and ctx.turnrules.getCurrentWarSubphase()
        or nil

    return currentPhase == "Prelude"
        or (currentPhase == "War" and currentWarSubphase == "Engage")
end

function buttonrules.canUseButton(cardIndex, ctx)
    local card = cardIndex and ctx and ctx.cards and ctx.cards[cardIndex] or nil
    local cardDefinition = card and ctx.cardregistry.getCard(card.setName, card.cardId) or nil

    return card ~= nil
        and cardDefinition ~= nil
        and cardDefinition.btn == true
        and isButtonPhaseAllowed(ctx)
        and card.buttonBadgeExhausted ~= true
        and getButtonHandler(cardDefinition) ~= nil
        and card.location
        and card.location.kind == "grid"
        and card.location.rowId == "PlayerRow"
        and not ctx.isCardUnavailable(card)
        or false
end

function buttonrules.useButton(cardIndex, ctx)
    if not buttonrules.canUseButton(cardIndex, ctx) then
        return false
    end

    local card = ctx.cards[cardIndex]
    local cardDefinition = ctx.cardregistry.getCard(card.setName, card.cardId)
    local handler = getButtonHandler(cardDefinition)
    local handled = handler(cardIndex, {
        cards = ctx.cards,
        cardIndex = cardIndex,
        card = card,
        definition = cardDefinition,
        ctx = ctx,
    }) ~= false

    if not handled then
        return false
    end

    card.buttonBadgeExhausted = true
    return true
end

function buttonrules.refreshButtons(cards)
    for _, card in ipairs(cards or {}) do
        if card then
            card.buttonBadgeExhausted = nil
        end
    end
end

return buttonrules
