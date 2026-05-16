local script = {}

function script.activate(ctx)
    local enemyIndices = ctx.getLiveEnemyCardIndices and ctx.getLiveEnemyCardIndices() or {}

    if #enemyIndices == 0 then
        return false
    end

    local targetCardIndex = enemyIndices[love.math.random(1, #enemyIndices)]
    local targetCenter = ctx.getCardCenter and ctx.getCardCenter(targetCardIndex) or nil

    if not targetCenter or not ctx.sourceCenter then
        return false
    end

    return ctx.queueProjectile(ctx.sourceCenter, targetCenter, function()
        local targetCard = ctx.state.cards[targetCardIndex]

        if targetCard and ctx.dealDamageToCard then
            ctx.dealDamageToCard(targetCard, 1)
        end
    end)
end

return script
