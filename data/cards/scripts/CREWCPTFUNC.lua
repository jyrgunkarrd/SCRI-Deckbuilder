local script = {}

function script.button(cardIndex, state)
    local ctx = state and state.ctx or nil

    if not ctx or not ctx.systemrules or not ctx.drawCardFromPlayerDeck then
        return false
    end

    if ctx.systemrules.getFreshSystemCount(ctx.state and ctx.state.missionSystems or nil) <= 0 then
        return false
    end

    if not ctx.systemrules.burnFreshSystem(ctx.state.missionSystems) then
        return false
    end

    ctx.drawCardFromPlayerDeck()
    return true
end

return script
