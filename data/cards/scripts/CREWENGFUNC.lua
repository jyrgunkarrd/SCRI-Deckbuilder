local script = {}

local function cardHasHealthBar(ctx, card)
    if not card then
        return false
    end

    if card.currentHealth ~= nil or card.maxHealth ~= nil then
        return true
    end

    local cardDefinition = ctx.cardregistry and ctx.cardregistry.getCard(card.setName, card.cardId) or nil
    return cardDefinition and cardDefinition.health ~= nil or false
end

local function hasValidTarget(ctx)
    for _, card in ipairs(ctx.state.cards or {}) do
        if card
            and card.location
            and card.location.kind == "grid"
            and card.location.rowId == "PlayerRow"
            and not card.destroyed
            and not card.destroying
            and not (ctx.isCardUnavailable and ctx.isCardUnavailable(card))
            and cardHasHealthBar(ctx, card) then
            return true
        end
    end

    return false
end

function script.button(cardIndex, state)
    local ctx = state and state.ctx or nil

    if not ctx
        or not ctx.systemrules
        or not ctx.cardregistry
        or not ctx.state then
        return false
    end

    if not hasValidTarget(ctx) then
        return false
    end

    if ctx.systemrules.getFreshSystemCount(ctx.state.missionSystems) <= 0 then
        return false
    end

    local burnedSystemIndex = ctx.systemrules.burnFreshSystem(ctx.state.missionSystems)

    if not burnedSystemIndex then
        return false
    end

    ctx.state.pendingButtonSelection = {
        kind = "crew_button_block_2",
        sourceCardIndex = cardIndex,
        burnedSystemIndex = burnedSystemIndex,
        prompt = "Choose a player row card to block",
    }

    if ctx.notifications then
        ctx.notifications.push("Choose a player row card to block")
    end

    return true
end

return script
