local abilityrules = {}

local VALID_ABILITY_SOURCE_TYPES = {
    agent = true,
}

local function getSourceCardAndDefinition(cardIndex, ctx)
    local card = cardIndex and ctx.cards and ctx.cards[cardIndex] or nil
    local definition = card and ctx.cardregistry.getCard(card.setName, card.cardId) or nil
    return card, definition
end

local function getMethodBadgeAbilities(cardDefinition)
    return cardDefinition and cardDefinition.agentAbilities or {}
end

local function findAbilityForResource(cardDefinition, resourceName)
    for _, abilityDefinition in ipairs(getMethodBadgeAbilities(cardDefinition)) do
        if abilityDefinition
            and abilityDefinition.trigger == "method_badge_click"
            and abilityDefinition.badgeResource == resourceName then
            return abilityDefinition
        end
    end

    return nil
end

local function isSourceCardValid(card, cardDefinition, ctx)
    return card
        and cardDefinition
        and VALID_ABILITY_SOURCE_TYPES[cardDefinition.type] == true
        and card.location
        and card.location.kind == "grid"
        and card.location.rowId == "PlayerRow"
        and not ctx.isCardUnavailable(card)
        or false
end

local function isTimingValid(abilityDefinition, ctx)
    local requiredPhase = abilityDefinition and abilityDefinition.timing and abilityDefinition.timing.phase or nil

    if requiredPhase and ctx.turnrules.getCurrentPhase() ~= requiredPhase then
        return false
    end

    return true
end

local function isTargetCardTypeAllowed(cardDefinition, allowedTypes)
    if not allowedTypes or #allowedTypes == 0 then
        return true
    end

    for _, allowedType in ipairs(allowedTypes) do
        if allowedType == cardDefinition.type then
            return true
        end
    end

    return false
end

local function isTargetValid(cardIndex, primedAbility, ctx)
    local targetRules = primedAbility and primedAbility.definition and primedAbility.definition.target or nil
    local sourceCardIndex = primedAbility and primedAbility.sourceCardIndex or nil
    local sourceCard = sourceCardIndex and ctx.cards and ctx.cards[sourceCardIndex] or nil
    local targetCard = cardIndex and ctx.cards and ctx.cards[cardIndex] or nil
    local targetDefinition = targetCard and ctx.cardregistry.getCard(targetCard.setName, targetCard.cardId) or nil

    if not targetRules
        or targetRules.kind ~= "grid_card"
        or not sourceCard
        or not targetCard
        or not targetDefinition
        or ctx.isCardUnavailable(targetCard) then
        return false
    end

    if cardIndex == sourceCardIndex and targetRules.allowSelf ~= true then
        return false
    end

    if not targetCard.location or targetCard.location.kind ~= "grid" then
        return false
    end

    if targetRules.controller == "player" and targetCard.location.rowId ~= "PlayerRow" then
        return false
    end

    if targetRules.rowId and targetCard.location.rowId ~= targetRules.rowId then
        return false
    end

    if not isTargetCardTypeAllowed(targetDefinition, targetRules.cardTypes) then
        return false
    end

    return true
end

function abilityrules.getCardMethodAbility(cardIndex, resourceName, ctx)
    local card, cardDefinition = getSourceCardAndDefinition(cardIndex, ctx)

    if not isSourceCardValid(card, cardDefinition, ctx) or not resourceName then
        return nil
    end

    return findAbilityForResource(cardDefinition, resourceName)
end

function abilityrules.primeCardMethodAbility(cardIndex, resourceName, state, ctx)
    local abilityDefinition = abilityrules.getCardMethodAbility(cardIndex, resourceName, ctx)

    if not abilityDefinition
        or not isTimingValid(abilityDefinition, ctx)
        or not ctx.resourcerules.canAffordCosts(abilityDefinition.costs) then
        return false
    end

    state.primedActivatedAbility = {
        sourceKind = "card",
        sourceCardIndex = cardIndex,
        resourceName = resourceName,
        definition = abilityDefinition,
    }

    return true
end

function abilityrules.isPrimedAbilityTarget(cardIndex, primedAbility, ctx)
    if not primedAbility or primedAbility.sourceKind ~= "card" then
        return false
    end

    return isTargetValid(cardIndex, primedAbility, ctx)
end

function abilityrules.resolvePrimedAbility(cardIndex, state, ctx)
    local primedAbility = state and state.primedActivatedAbility or nil
    local abilityDefinition = primedAbility and primedAbility.definition or nil
    local effectArgs = abilityDefinition and abilityDefinition.effectArgs or nil

    if not primedAbility
        or primedAbility.sourceKind ~= "card"
        or not abilityDefinition
        or not isTimingValid(abilityDefinition, ctx)
        or not ctx.resourcerules.canAffordCosts(abilityDefinition.costs)
        or not abilityrules.isPrimedAbilityTarget(cardIndex, primedAbility, ctx) then
        return false
    end

    if abilityDefinition.effect == "transform_card" then
        local targetDefinition = effectArgs and effectArgs.targetCardId and ctx.cardregistry.getCardById(effectArgs.targetCardId) or nil

        if not targetDefinition or not ctx.transformCardAtIndex(cardIndex, targetDefinition) then
            return false
        end
    else
        return false
    end

    if not ctx.resourcerules.payCosts(abilityDefinition.costs) then
        return false
    end

    state.primedActivatedAbility = nil

    if ctx.sfxrules and ctx.sfxrules.playUnitPlay then
        ctx.sfxrules.playUnitPlay()
    end

    return true
end

return abilityrules
