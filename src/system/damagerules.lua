local cardinstances = require("src.system.cardinstances")

local damagerules = {}

function damagerules.dealDamageToCard(card, amount)
    if not card or amount == nil then
        return nil
    end

    cardinstances.initializeHealth(card)

    if card.currentHealth == nil then
        return nil
    end

    local previousHealth = card.currentHealth
    local previousBlocking = math.max(0, tonumber(card.blocking) or 0)
    local appliedDamage = math.max(0, tonumber(amount) or 0)
    local blockedDamage = math.min(previousBlocking, appliedDamage)

    if blockedDamage > 0 then
        card.blocking = previousBlocking - blockedDamage
        appliedDamage = appliedDamage - blockedDamage
    end

    card.currentHealth = math.max(0, card.currentHealth - appliedDamage)

    return {
        previousHealth = previousHealth,
        currentHealth = card.currentHealth,
        previousBlocking = previousBlocking,
        currentBlocking = math.max(0, tonumber(card.blocking) or 0),
        blockedDamage = blockedDamage,
        healthDamage = previousHealth - card.currentHealth,
        killed = previousHealth > 0 and card.currentHealth <= 0,
        changed = card.currentHealth < previousHealth or blockedDamage > 0,
    }
end

function damagerules.addBlockingToCard(card, amount)
    if not card or amount == nil then
        return nil
    end

    cardinstances.initializeHealth(card)

    if card.currentHealth == nil then
        return nil
    end

    local previousBlocking = math.max(0, tonumber(card.blocking) or 0)
    local addedBlocking = math.max(0, tonumber(amount) or 0)

    card.blocking = previousBlocking + addedBlocking

    return {
        previousBlocking = previousBlocking,
        currentBlocking = card.blocking,
        addedBlocking = addedBlocking,
        changed = addedBlocking > 0,
    }
end

function damagerules.clearAllBlocking(cards)
    for _, card in ipairs(cards or {}) do
        if card then
            card.blocking = nil
        end
    end
end

function damagerules.dealDamageToChampion(champion, amount)
    if not champion or amount == nil then
        return nil
    end

    local previousHealth = champion.health or 0
    champion.health = math.max(0, previousHealth - math.max(0, tonumber(amount) or 0))

    return {
        previousHealth = previousHealth,
        currentHealth = champion.health,
        healthDamage = previousHealth - champion.health,
        killed = previousHealth > 0 and champion.health <= 0,
        changed = champion.health < previousHealth,
    }
end

return damagerules
