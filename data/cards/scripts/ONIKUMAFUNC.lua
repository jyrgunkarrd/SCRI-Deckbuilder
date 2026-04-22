local GROWTH_KEYWORD_ID = "KWGRO"

local function growCard(sourceCardIndex, state)
    local sourceCard = sourceCardIndex and state.ctx.cards[sourceCardIndex] or nil

    if not sourceCard or state.ctx.isCardUnavailable(sourceCard) then
        return false
    end

    return state.ctx.addCardKeywordValue(sourceCardIndex, GROWTH_KEYWORD_ID, 1) ~= nil
end

local function beginEndPhaseSelection(sourceCardIndex, state)
    local sourceCard = sourceCardIndex and state.ctx.cards[sourceCardIndex] or nil

    if not sourceCard or state.ctx.isCardUnavailable(sourceCard) then
        return nil
    end

    return {
        kind = "troop_script_sacrifice",
        sourceCardIndex = sourceCardIndex,
        prompt = "Choose a troop or token to sacrifice",
    }
end

local function onPlayerRowUnitDefeated(sourceCardIndex, defeatedCardIndex, state)
    if sourceCardIndex == defeatedCardIndex then
        return false
    end

    return growCard(sourceCardIndex, state)
end

local function onMeatCacheDecayed(sourceCardIndex, cacheCardIndex, state)
    return growCard(sourceCardIndex, state)
end

return {
    beginEndPhaseSelection = beginEndPhaseSelection,
    onPlayerRowUnitDefeated = onPlayerRowUnitDefeated,
    onMeatCacheDecayed = onMeatCacheDecayed,
}
