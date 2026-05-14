local script = {}

local function getHunterDeckCardIndices(ctx)
    local hunterCardIndices = {}
    local playerDeck = ctx and ctx.state and ctx.state.playerDeck or nil

    for cardIndex, card in ipairs(playerDeck and playerDeck.cards or {}) do
        local cardDefinition = card and ctx.cardregistry and ctx.cardregistry.getCard(card.setName, card.cardId) or nil

        if cardDefinition and cardDefinition.type == "hunter" then
            hunterCardIndices[#hunterCardIndices + 1] = cardIndex
        end
    end

    return hunterCardIndices
end

function script.button(cardIndex, state)
    local ctx = state and state.ctx or nil
    local playerDeck = ctx and ctx.state and ctx.state.playerDeck or nil

    if not ctx
        or not ctx.systemrules
        or not ctx.deckrules
        or not ctx.cardregistry
        or not playerDeck then
        return false
    end

    local hunterCardIndices = getHunterDeckCardIndices(ctx)

    if #hunterCardIndices <= 0 then
        return false
    end

    if ctx.systemrules.getFreshSystemCount(ctx.state.missionSystems) <= 0 then
        return false
    end

    local burnedSystemIndex = ctx.systemrules.burnFreshSystem(ctx.state.missionSystems)

    if not burnedSystemIndex then
        return false
    end

    local selectedDeckIndex = hunterCardIndices[love.math.random(1, #hunterCardIndices)]
    local hunterCard = table.remove(playerDeck.cards, selectedDeckIndex)
    local discardedCard = ctx.deckrules.discardCard(playerDeck, hunterCard)

    if ctx.beginHunterDeckDiscardAnimation then
        ctx.beginHunterDeckDiscardAnimation(discardedCard or hunterCard)
    end

    return true
end

return script
