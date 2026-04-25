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

local function getJaclMethodBadgeAbilities(jaclDefinition)
    return jaclDefinition and jaclDefinition.jaclAbilities or {}
end

local function findMethodBadgeAbilityForResource(abilityDefinitions, resourceName)
    for _, abilityDefinition in ipairs(abilityDefinitions or {}) do
        if abilityDefinition
            and abilityDefinition.trigger == "method_badge_click"
            and abilityDefinition.badgeResource == resourceName then
            return abilityDefinition
        end
    end

    return nil
end

local function isMethodAbilityUsed(card, resourceName)
    return card
        and resourceName
        and card.usedMethodAbilities
        and card.usedMethodAbilities[resourceName] == true
        or false
end

local function markMethodAbilityUsed(card, resourceName)
    if not card or not resourceName then
        return false
    end

    card.usedMethodAbilities = card.usedMethodAbilities or {}
    card.usedMethodAbilities[resourceName] = true
    return true
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

local function areCostsAffordable(abilityDefinition, ctx)
    if ctx.resourcerules.canAffordCosts then
        return ctx.resourcerules.canAffordCosts(abilityDefinition.costs)
    end

    for _, cost in ipairs(abilityDefinition.costs or {}) do
        if ctx.resourcerules.getResourceCount(cost.resource) < (tonumber(cost.amount) or 0) then
            return false
        end
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

local function isTopSlotAllowed(slotId, allowedTopSlots)
    if not allowedTopSlots or #allowedTopSlots == 0 then
        return false
    end

    for _, allowedSlotId in ipairs(allowedTopSlots) do
        if allowedSlotId == slotId then
            return true
        end
    end

    return false
end

local function isEnemyCardOrChampionTargetValid(target, primedAbility, ctx)
    local targetRules = primedAbility and primedAbility.definition and primedAbility.definition.target or nil

    if not targetRules or targetRules.kind ~= "enemy_card_or_champion" then
        return false
    end

    if type(target) == "table" and target.kind == "top_slot" then
        return target.slotId == "champion"
            and ctx.activeChampion
            and ctx.activeChampion.hidden ~= true
            and isTopSlotAllowed(target.slotId, targetRules.topSlots)
            or false
    end

    local targetCard = target and ctx.cards and ctx.cards[target] or nil
    local targetDefinition = targetCard and ctx.cardregistry.getCard(targetCard.setName, targetCard.cardId) or nil

    return targetCard
        and targetDefinition
        and targetCard.location
        and targetCard.location.kind == "grid"
        and targetCard.location.rowId == (targetRules.rowId or "OppRow")
        and not ctx.isCardUnavailable(targetCard)
        and isTargetCardTypeAllowed(targetDefinition, targetRules.cardTypes)
        or false
end

local function isCellTargetValid(targetCell, primedAbility, ctx)
    local targetRules = primedAbility and primedAbility.definition and primedAbility.definition.target or nil

    if not targetRules
        or targetRules.kind ~= "player_row_cell"
        or type(targetCell) ~= "table" then
        return false
    end

    return targetCell.rowId == nil or targetRules.rowId == nil or targetCell.rowId == targetRules.rowId
end

function abilityrules.getCardMethodAbility(cardIndex, resourceName, ctx)
    local card, cardDefinition = getSourceCardAndDefinition(cardIndex, ctx)

    if not isSourceCardValid(card, cardDefinition, ctx) or not resourceName then
        return nil
    end

    if isMethodAbilityUsed(card, resourceName) then
        return nil
    end

    return findMethodBadgeAbilityForResource(getMethodBadgeAbilities(cardDefinition), resourceName)
end

function abilityrules.getJaclMethodAbility(jaclDefinition, resourceName, ctx)
    if not jaclDefinition or not resourceName then
        return nil
    end

    if isMethodAbilityUsed(jaclDefinition, resourceName) then
        return nil
    end

    return findMethodBadgeAbilityForResource(getJaclMethodBadgeAbilities(jaclDefinition), resourceName)
end

function abilityrules.primeCardMethodAbility(cardIndex, resourceName, state, ctx)
    local abilityDefinition = abilityrules.getCardMethodAbility(cardIndex, resourceName, ctx)

    if not abilityDefinition
        or not isTimingValid(abilityDefinition, ctx)
        or not areCostsAffordable(abilityDefinition, ctx) then
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

function abilityrules.primeJaclMethodAbility(resourceName, state, ctx)
    local abilityDefinition = abilityrules.getJaclMethodAbility(state and state.playerJacl or nil, resourceName, ctx)

    if not abilityDefinition
        or not isTimingValid(abilityDefinition, ctx)
        or not areCostsAffordable(abilityDefinition, ctx) then
        return false
    end

    state.primedActivatedAbility = {
        sourceKind = "jacl",
        resourceName = resourceName,
        definition = abilityDefinition,
    }

    return true
end

function abilityrules.isPrimedAbilityTarget(target, primedAbility, ctx)
    if not primedAbility then
        return false
    end

    local targetRules = primedAbility.definition and primedAbility.definition.target or nil

    if targetRules and targetRules.kind == "player_row_cell" then
        return isCellTargetValid(target, primedAbility, ctx)
    end

    if targetRules and targetRules.kind == "enemy_card_or_champion" then
        return isEnemyCardOrChampionTargetValid(target, primedAbility, ctx)
    end

    return primedAbility.sourceKind == "card" and isTargetValid(target, primedAbility, ctx) or false
end

local function resolveSingleEffect(effectName, effectArgs, target, abilityDefinition, primedAbility, ctx)
    if effectName == "transform_card" then
        local targetDefinition = effectArgs and effectArgs.targetCardId and ctx.cardregistry.getCardById(effectArgs.targetCardId) or nil

        return targetDefinition and ctx.transformCardAtIndex(target, targetDefinition) or false
    end

    if effectName == "pilot_vehicle_card" then
        local vehicleDefinition = effectArgs and effectArgs.vehicleCardId and ctx.cardregistry.getCardById(effectArgs.vehicleCardId) or nil

        return vehicleDefinition and ctx.pilotCardWithVehicleAtIndex(target, vehicleDefinition) or false
    end

    if effectName == "create_grid_card" then
        local cardDefinition = effectArgs and effectArgs.cardId and ctx.cardregistry.getCardById(effectArgs.cardId) or nil
        local rowId = effectArgs and effectArgs.rowId or (abilityDefinition.target and abilityDefinition.target.rowId) or "PlayerRow"
        local targetCell = target

        return cardDefinition
            and targetCell
            and targetCell.column
            and ctx.createGeneratedGridCard(cardDefinition, rowId, targetCell.column)
            or false
    end

    if effectName == "deal_damage" then
        local damageAmount = math.max(0, tonumber(effectArgs and effectArgs.amount) or 0)

        if damageAmount <= 0 then
            return false
        end

        if type(target) == "table" and target.kind == "top_slot" and target.slotId == "champion" then
            return ctx.dealDamageToChampion and ctx.dealDamageToChampion(damageAmount) ~= nil or false
        end

        local targetCard = target and ctx.cards and ctx.cards[target] or nil
        local damageResult = targetCard and ctx.dealDamageToCard and ctx.dealDamageToCard(targetCard, damageAmount) or nil

        if damageResult
            and damageResult.killed
            and primedAbility
            and primedAbility.sourceKind == "card"
            and primedAbility.sourceCardIndex
            and ctx.resolveKilledEnemyByPlayerCard then
            ctx.resolveKilledEnemyByPlayerCard(primedAbility.sourceCardIndex, target)
        end

        return damageResult ~= nil
    end

    if effectName == "add_syntac" then
        local syntacAmount = math.max(0, tonumber(effectArgs and effectArgs.amount) or 0)

        if syntacAmount <= 0 or not ctx.addSyntac then
            return false
        end

        ctx.addSyntac(syntacAmount)
        return true
    end

    return false
end

local function resolveAbilityEffect(abilityDefinition, target, primedAbility, ctx)
    local effectArgs = abilityDefinition and abilityDefinition.effectArgs or nil

    if abilityDefinition.effect == "compound" then
        for _, childEffect in ipairs(effectArgs and effectArgs.effects or {}) do
            if not resolveSingleEffect(childEffect.effect, childEffect, target, abilityDefinition, primedAbility, ctx) then
                return false
            end
        end

        return true
    end

    return resolveSingleEffect(abilityDefinition.effect, effectArgs, target, abilityDefinition, primedAbility, ctx)
end

function abilityrules.resolvePrimedAbility(target, state, ctx)
    local primedAbility = state and state.primedActivatedAbility or nil
    local abilityDefinition = primedAbility and primedAbility.definition or nil

    if not primedAbility
        or not abilityDefinition
        or not isTimingValid(abilityDefinition, ctx)
        or not areCostsAffordable(abilityDefinition, ctx)
        or not abilityrules.isPrimedAbilityTarget(target, primedAbility, ctx) then
        return false
    end

    if not resolveAbilityEffect(abilityDefinition, target, primedAbility, ctx) then
        return false
    end

    if not ctx.resourcerules.payCosts(abilityDefinition.costs) then
        return false
    end

    local sourceCard = primedAbility.sourceCardIndex and ctx.cards and ctx.cards[primedAbility.sourceCardIndex] or nil
    markMethodAbilityUsed(sourceCard, primedAbility.resourceName)

    if primedAbility.sourceKind == "jacl" then
        markMethodAbilityUsed(state.playerJacl, primedAbility.resourceName)
    end

    state.primedActivatedAbility = nil

    if abilityDefinition.effect == "pilot_vehicle_card" and ctx.sfxrules and ctx.sfxrules.playPilot then
        ctx.sfxrules.playPilot()
    elseif ctx.sfxrules and ctx.sfxrules.playUnitPlay then
        ctx.sfxrules.playUnitPlay()
    end

    return true
end

return abilityrules
