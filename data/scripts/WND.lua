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

function script.activate(ctx)
    if not ctx or not ctx.state or not ctx.cardregistry then
        return false
    end

    if not hasValidTarget(ctx) then
        return false
    end

    ctx.state.pendingButtonSelection = {
        kind = "tithe_block_1",
        blockAmount = 1,
        refundWorldResource = {
            key = "tithes",
            amount = 1,
        },
        exhaustedRewardButtonId = "tithes",
        prompt = "Choose a player row card to block",
    }

    if ctx.notifications then
        ctx.notifications.push("Choose a player row card to block")
    end

    return true
end

return script
