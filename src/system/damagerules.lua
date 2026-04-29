local cardinstances = require("src.system.cardinstances")
local cardregistry = require("src.system.cardregistry")
local keywordrules = require("src.system.keywordrules")

local damagerules = {}
local TOUGH_KEYWORD_ID = "KWTOUGH"
local BULLETPROOF_KEYWORD_ID = "KWBULLETPROOF"

local function applyDamageLimitKeywords(card, damageAmount)
    local limitedDamage = math.max(0, tonumber(damageAmount) or 0)

    if limitedDamage <= 0 then
        return limitedDamage, nil
    end

    local cardDefinition = card and cardregistry.getCard(card.setName, card.cardId) or nil

    if keywordrules.cardHasKeyword(cardDefinition, BULLETPROOF_KEYWORD_ID, card) then
        return math.min(1, limitedDamage), BULLETPROOF_KEYWORD_ID
    end

    if keywordrules.cardHasKeyword(cardDefinition, TOUGH_KEYWORD_ID, card)
        and not keywordrules.isKeywordExhausted(card, TOUGH_KEYWORD_ID) then
        keywordrules.exhaustKeyword(card, TOUGH_KEYWORD_ID)
        return math.min(1, limitedDamage), TOUGH_KEYWORD_ID
    end

    return limitedDamage, nil
end

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
        if card.enemyGuardCarryBlock then
            card.enemyGuardCarryBlock = math.max(0, (tonumber(card.enemyGuardCarryBlock) or 0) - blockedDamage)

            if card.enemyGuardCarryBlock <= 0 then
                card.enemyGuardCarryBlock = nil
            end
        end
        appliedDamage = appliedDamage - blockedDamage
    end

    local preKeywordDamage = appliedDamage
    local damageLimitKeywordId = nil
    appliedDamage, damageLimitKeywordId = applyDamageLimitKeywords(card, appliedDamage)

    card.currentHealth = math.max(0, card.currentHealth - appliedDamage)

    return {
        previousHealth = previousHealth,
        currentHealth = card.currentHealth,
        previousBlocking = previousBlocking,
        currentBlocking = math.max(0, tonumber(card.blocking) or 0),
        blockedDamage = blockedDamage,
        preventedByKeywordDamage = preKeywordDamage - appliedDamage,
        damageLimitKeywordId = damageLimitKeywordId,
        healthDamage = previousHealth - card.currentHealth,
        killed = previousHealth > 0 and card.currentHealth <= 0,
        changed = card.currentHealth < previousHealth or blockedDamage > 0,
    }
end

function damagerules.dealDirectDamageToCard(card, amount)
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

    card.currentHealth = math.max(0, card.currentHealth - appliedDamage)

    return {
        previousHealth = previousHealth,
        currentHealth = card.currentHealth,
        previousBlocking = previousBlocking,
        currentBlocking = previousBlocking,
        blockedDamage = 0,
        preventedByKeywordDamage = 0,
        healthDamage = previousHealth - card.currentHealth,
        killed = previousHealth > 0 and card.currentHealth <= 0,
        changed = card.currentHealth < previousHealth,
    }
end

function damagerules.addBlockingToCard(card, amount, options)
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

    if options and options.carryEnemyGuard == true and addedBlocking > 0 then
        card.enemyGuardCarryBlock = math.max(0, tonumber(card.enemyGuardCarryBlock) or 0) + addedBlocking
    end

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
            local carriedBlock = math.max(0, tonumber(card.enemyGuardCarryBlock) or 0)

            if carriedBlock > 0
                and card.location
                and card.location.kind == "grid"
                and card.location.rowId == "OppRow" then
                card.blocking = math.min(math.max(0, tonumber(card.blocking) or 0), carriedBlock)
                card.enemyGuardCarryBlock = card.blocking > 0 and card.blocking or nil
            else
                card.blocking = nil
                card.enemyGuardCarryBlock = nil
            end
        end
    end
end

function damagerules.clearEnemyGuardCarryBlocking(cards)
    for _, card in ipairs(cards or {}) do
        local carriedBlock = math.max(0, tonumber(card and card.enemyGuardCarryBlock) or 0)

        if carriedBlock > 0 then
            card.blocking = math.max(0, (tonumber(card.blocking) or 0) - carriedBlock)
            card.enemyGuardCarryBlock = nil

            if card.blocking <= 0 then
                card.blocking = nil
            end
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
