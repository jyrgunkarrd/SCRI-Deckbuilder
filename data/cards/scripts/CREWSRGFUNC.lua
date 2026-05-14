local script = {}

function script.button(cardIndex, state)
    local ctx = state and state.ctx or nil

    if not ctx or not ctx.systemrules or not ctx.state then
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
        kind = "crew_button_heal",
        sourceCardIndex = cardIndex,
        burnedSystemIndex = burnedSystemIndex,
        prompt = "Choose a player row card to heal",
    }

    if ctx.notifications then
        ctx.notifications.push("Choose a player row card to heal")
    end

    return true
end

return script
