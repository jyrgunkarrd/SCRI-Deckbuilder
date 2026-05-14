local script = {}

local TARGET_HEALTH = 2

local function getCardCurrentHealth(ctx, card)
    if not card then
        return nil
    end

    if card.currentHealth == nil then
        local cardDefinition = ctx.cardregistry and ctx.cardregistry.getCard(card.setName, card.cardId) or nil
        card.currentHealth = tonumber(cardDefinition and cardDefinition.health)
        card.maxHealth = tonumber(cardDefinition and (cardDefinition.max or cardDefinition.health))
    end

    return tonumber(card.currentHealth)
end

local function hasValidTarget(ctx)
    local championHealth = tonumber(ctx.state.activeChampion and ctx.state.activeChampion.health)

    if ctx.state.activeChampion
        and ctx.state.activeChampion.hidden ~= true
        and championHealth == TARGET_HEALTH then
        return true
    end

    for _, card in ipairs(ctx.state.cards or {}) do
        if card
            and card.location
            and card.location.kind == "grid"
            and card.location.rowId == "OppRow"
            and not card.destroyed
            and not card.destroying
            and not (ctx.isCardUnavailable and ctx.isCardUnavailable(card))
            and getCardCurrentHealth(ctx, card) == TARGET_HEALTH then
            return true
        end
    end

    return false
end

function script.button(cardIndex, state)
    local ctx = state and state.ctx or nil

    if not ctx or not ctx.systemrules or not ctx.state then
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
        kind = "crew_button_defeat_2",
        sourceCardIndex = cardIndex,
        burnedSystemIndex = burnedSystemIndex,
        prompt = "Choose an enemy with exactly 2 health",
    }

    if ctx.notifications then
        ctx.notifications.push("Choose an enemy with exactly 2 health")
    end

    return true
end

return script
