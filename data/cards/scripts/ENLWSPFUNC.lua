local PANZERVORE_CARD_ID = "ENTNKVOR"

local function summonPanzervore(sourceCardIndex, state)
    if not sourceCardIndex
        or not state
        or not state.ctx
        or not state.ctx.cardregistry
        or not state.ctx.spawnTokensNearCard then
        return false
    end

    local panzervoreDefinition = state.ctx.cardregistry.getCardById(PANZERVORE_CARD_ID)

    if not panzervoreDefinition then
        return false
    end

    return (state.ctx.spawnTokensNearCard(sourceCardIndex, panzervoreDefinition, 1) or 0) > 0
end

local function onKill(sourceCardIndex, state)
    if state and state.targetCardIndex == sourceCardIndex then
        return false
    end

    return summonPanzervore(sourceCardIndex, state)
end

return {
    onDeath = summonPanzervore,
    onKill = onKill,
}
