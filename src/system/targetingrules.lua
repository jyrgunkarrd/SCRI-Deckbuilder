local targetingrules = {}

local function hasTargetType(rollState, targetType)
    if not rollState or not targetType then
        return false
    end

    if type(rollState.targetType) == "table" then
        for _, candidate in ipairs(rollState.targetType) do
            if candidate == targetType then
                return true
            end
        end

        return false
    end

    return rollState.targetType == targetType
end

local function canTargetEnemyCard(rollState, context)
    if context and context.canTargetEnemyCard then
        return context.canTargetEnemyCard(rollState)
    end

    if rollState and rollState.action == "attack" and rollState.targetClass == "enemy_card" then
        return true
    end

    return hasTargetType(rollState, "Atk")
        or hasTargetType(rollState, "AtkSab")
        or hasTargetType(rollState, "TAtk")
        or hasTargetType(rollState, "closeatk")
        or hasTargetType(rollState, "maulatk")
end

local function canTargetPlayerWarzone(rollState, context)
    if context and context.canTargetPlayerWarzone then
        return context.canTargetPlayerWarzone(rollState)
    end

    if rollState and rollState.action == "influence" and rollState.targetClass == "player_warzone" then
        return true
    end

    return hasTargetType(rollState, "WZPlayer") or hasTargetType(rollState, "InfTac")
end

local function isPlayerGridCard(card)
    return card
        and card.location
        and card.location.kind == "grid"
        and card.location.rowId == "PlayerRow"
end

local function isEnemyGridCard(card)
    return card
        and card.location
        and card.location.kind == "grid"
        and card.location.rowId == "OppRow"
end

local function isSelectedAttackerCardTarget(cardIndex, context)
    local selectedCardIndex = context and context.selectedAttackerCardIndex or nil
    local selectedCard = selectedCardIndex and context.cards and context.cards[selectedCardIndex] or nil
    local selectedTopSlotId = context and context.selectedAttackerTopSlotId or nil
    local displayStates = context and context.displayStates or {}
    local selectedRollState = context and context.getCardRollState and selectedCardIndex and context.getCardRollState(selectedCardIndex)
        or selectedTopSlotId and displayStates[selectedTopSlotId]
        or nil
    local candidateCard = cardIndex and context.cards and context.cards[cardIndex] or nil

    if not selectedRollState or not candidateCard then
        return false
    end

    if selectedRollState.action == "block" or hasTargetType(selectedRollState, "Blk") then
        local candidateDefinition = context.cardregistry
            and candidateCard
            and context.cardregistry.getCard(candidateCard.setName, candidateCard.cardId)
            or nil

        return isPlayerGridCard(candidateCard)
            and (
                not context.canTargetCardByHeavyRestriction
                or context.canTargetCardByHeavyRestriction(candidateDefinition, candidateCard, selectedRollState, context.cards)
            )
    end

    if selectedRollState.action == "divert" or hasTargetType(selectedRollState, "Div") then
        local candidateDefinition = context.cardregistry
            and candidateCard
            and context.cardregistry.getCard(candidateCard.setName, candidateCard.cardId)
            or nil

        return isPlayerGridCard(candidateCard)
            and (
                not context.canTargetCardByHeavyRestriction
                or context.canTargetCardByHeavyRestriction(candidateDefinition, candidateCard, selectedRollState, context.cards)
            )
    end

    if canTargetEnemyCard(selectedRollState, context) and isEnemyGridCard(candidateCard) then
        if not context.cardregistry or not context.canAttackTarget then
            return true
        end

        local selectedDefinition = selectedCard and context.cardregistry.getCard(selectedCard.setName, selectedCard.cardId)
            or selectedTopSlotId == "warzone" and context.activeWarzone
            or selectedTopSlotId == "poi" and context.activePoi
            or nil
        local candidateDefinition = context.cardregistry.getCard(candidateCard.setName, candidateCard.cardId)
        return context.canAttackTarget(selectedDefinition, candidateDefinition, selectedCard, candidateCard, selectedRollState, context.cards)
    end

    return false
end

local function canSelectedAttackerTargetSlot(slotId, context)
    local selectedCardIndex = context and context.selectedAttackerCardIndex or nil
    local selectedTopSlotId = context and context.selectedAttackerTopSlotId or nil
    local displayStates = context and context.displayStates or {}
    local selectedRollState = context and context.getCardRollState and selectedCardIndex and context.getCardRollState(selectedCardIndex)
        or selectedTopSlotId and displayStates[selectedTopSlotId]
        or nil

    if not selectedRollState or not slotId then
        return false
    end

    if slotId == "champion" then
        return context.activeChampion and canTargetEnemyCard(selectedRollState, context) or false
    end

    if slotId == "objective" then
        return context.activePrimaryObjective
            and (
                hasTargetType(selectedRollState, "Obj")
                or (
                    selectedRollState.action == "sabotage"
                    and (
                        selectedRollState.targetClass == "objective"
                        or selectedRollState.targetClass == "objective_or_intel"
                    )
                )
            ) or false
    end

    if slotId == "intel" then
        return context.activeIntel
            and (
                hasTargetType(selectedRollState, "IntCD")
                or (
                    selectedRollState.action == "sabotage"
                    and (
                        selectedRollState.targetClass == "intel"
                        or selectedRollState.targetClass == "objective_or_intel"
                    )
                )
            ) or false
    end

    if slotId == "warzone" or slotId == "poi" then
        local targetExists = (slotId == "warzone" and context.activeWarzone) or (slotId == "poi" and context.activePoi)
        return targetExists
            and (
                canTargetPlayerWarzone(selectedRollState, context)
                or hasTargetType(selectedRollState, "WZOpp")
                or (selectedRollState.action == "influence" and selectedRollState.targetClass == "enemy_warzone")
            ) or false
    end

    return false
end

local function isPendingChoiceTarget(cardIndex, context)
    return context.pendingStrategySelection
        and context.isPendingStrategyTarget
        and context.isPendingStrategyTarget(cardIndex, context.pendingStrategySelection)
        or false
end

local function isPrimedAbilityTarget(cardIndex, context)
    return context.primedActivatedAbility
        and context.isPrimedAbilityTarget
        and context.isPrimedAbilityTarget(cardIndex, context.primedActivatedAbility)
        or false
end

local function isPrimedAbilityTopSlotTarget(slotId, context)
    return context.primedActivatedAbility
        and context.isPrimedAbilityTarget
        and context.isPrimedAbilityTarget({
            kind = "top_slot",
            slotId = slotId,
        }, context.primedActivatedAbility)
        or false
end

local function isThreatBracketCard(cardIndex, context)
    if context.currentPhase ~= "War" then
        return false
    end

    local displayStates = context.displayStates or {}

    if context.hoveredTopSlotId then
        local hoveredTopSlotRollState = displayStates[context.hoveredTopSlotId]

        if targetingrules.rollStateTargetsCard(hoveredTopSlotRollState, cardIndex, context) then
            return true
        end

        local cardRollState = context.getCardRollState and context.getCardRollState(cardIndex) or nil

        if targetingrules.rollStateTargetsTopSlot(cardRollState, context.hoveredTopSlotId, context) then
            return true
        end
    end

    if context.hoveredCardIndex then
        local hoveredCard = context.cards and context.cards[context.hoveredCardIndex] or nil

        if not hoveredCard or not hoveredCard.location or hoveredCard.location.kind ~= "grid" then
            return false
        end

        local hoveredRollState = context.getCardRollState and context.getCardRollState(context.hoveredCardIndex) or nil

        if hoveredCard.location.rowId ~= "PlayerRow"
            and targetingrules.rollStateTargetsCard(hoveredRollState, cardIndex, context) then
            return true
        end

        if hoveredCard.location.rowId == "PlayerRow" then
            local rollState = context.getCardRollState and context.getCardRollState(cardIndex) or nil
            local card = context.cards and context.cards[cardIndex] or nil

            return card
                and card.location
                and card.location.kind == "grid"
                and card.location.rowId == "OppRow"
                and targetingrules.rollStateTargetsCard(rollState, context.hoveredCardIndex, context)
        end
    end

    return false
end

function targetingrules.rollStateTargetsCard(rollState, cardIndex, context)
    return rollState
        and rollState.targetCard
        and rollState.targetCard.kind == "card"
        and rollState.targetCardIndex
        and rollState.targetCardIndex == cardIndex
end

function targetingrules.rollStateTargetsTopSlot(rollState, slotId, context)
    if not rollState or not rollState.targetCard or not slotId then
        return false
    end

    context = context or {}

    local targetCard = rollState.targetCard

    if slotId == "objective" then
        return (
            hasTargetType(rollState, "Obj")
            or (
                rollState.action == "sabotage"
                and (
                    rollState.targetClass == "objective"
                    or rollState.targetClass == "objective_or_intel"
                )
            )
        )
            and targetCard.kind == "objective"
            and context.activePrimaryObjective
            and targetCard.objectiveId == context.activePrimaryObjective.id
    elseif slotId == "intel" then
        return (
            hasTargetType(rollState, "IntCD")
            or (
                rollState.action == "sabotage"
                and (
                    rollState.targetClass == "intel"
                    or rollState.targetClass == "objective_or_intel"
                )
            )
        )
            and targetCard.kind == "intel"
            and context.activeIntel
            and targetCard.objectiveId == context.activeIntel.id
    elseif slotId == "warzone" then
        return (
            hasTargetType(rollState, "WZOpp")
            or canTargetPlayerWarzone(rollState, context)
            or (rollState.action == "influence" and rollState.targetClass == "enemy_warzone")
        )
            and targetCard.kind == "warzone"
            and context.activeWarzone
            and targetCard.warzoneId == context.activeWarzone.id
    elseif slotId == "poi" then
        return (
            hasTargetType(rollState, "WZOpp")
            or canTargetPlayerWarzone(rollState, context)
            or (rollState.action == "influence" and rollState.targetClass == "enemy_warzone")
        )
            and targetCard.kind == "warzone"
            and context.activePoi
            and targetCard.warzoneId == context.activePoi.id
    end

    return false
end

function targetingrules.shouldBracketCard(cardIndex, context)
    context = context or {}

    if cardIndex == context.hoveredCardIndex then
        return false
    end

    return isPendingChoiceTarget(cardIndex, context)
        or isPrimedAbilityTarget(cardIndex, context)
        or ((context.selectedAttackerCardIndex or context.selectedAttackerTopSlotId) and isSelectedAttackerCardTarget(cardIndex, context) or false)
        or isThreatBracketCard(cardIndex, context)
end

function targetingrules.shouldBracketTopSlot(slotId, context)
    context = context or {}

    if not slotId then
        return false
    end

    if isPrimedAbilityTopSlotTarget(slotId, context) then
        return true
    end

    if context.currentPhase ~= "War" then
        return false
    end

    if (context.selectedAttackerCardIndex or context.selectedAttackerTopSlotId) and canSelectedAttackerTargetSlot(slotId, context) then
        return true
    end

    if slotId == context.hoveredTopSlotId then
        return false
    end

    local displayStates = context.displayStates or {}

    if context.hoveredTopSlotId then
        if targetingrules.rollStateTargetsTopSlot(displayStates[context.hoveredTopSlotId], slotId, context) then
            return true
        end

        if targetingrules.rollStateTargetsTopSlot(displayStates[slotId], context.hoveredTopSlotId, context) then
            return true
        end
    end

    if slotId == "champion" and context.activeChampion then
        local selectedCard = context.cards
            and context.selectedAttackerCardIndex
            and context.cards[context.selectedAttackerCardIndex]
            or nil
        local selectedRollState = context.getCardRollState
            and context.selectedAttackerCardIndex
            and context.getCardRollState(context.selectedAttackerCardIndex)
            or nil

        if isPlayerGridCard(selectedCard) and canTargetEnemyCard(selectedRollState, context) then
            return true
        end
    end

    if context.hoveredCardIndex then
        local hoveredCard = context.cards and context.cards[context.hoveredCardIndex] or nil

        if not hoveredCard or not hoveredCard.location or hoveredCard.location.kind ~= "grid" then
            return false
        end

        local hoveredRollState = context.getCardRollState and context.getCardRollState(context.hoveredCardIndex) or nil

        if hoveredCard.location.rowId ~= "PlayerRow"
            and targetingrules.rollStateTargetsTopSlot(
                hoveredRollState,
                slotId,
                context
            ) then
            return true
        end

        if targetingrules.rollStateTargetsCard(displayStates[slotId], context.hoveredCardIndex, context) then
            return true
        end
    end

    return false
end

function targetingrules.getCardBracketColor(cardIndex, context)
    context = context or {}

    if isPendingChoiceTarget(cardIndex, context) then
        return "strategy"
    end

    if isPrimedAbilityTarget(cardIndex, context) then
        return "strategy"
    end

    if (context.selectedAttackerCardIndex or context.selectedAttackerTopSlotId) and isSelectedAttackerCardTarget(cardIndex, context) then
        return "strategy"
    end

    return "default"
end

function targetingrules.getCardBracketLayers(cardIndex, context)
    context = context or {}

    if cardIndex == context.hoveredCardIndex then
        return {}
    end

    local layers = {}

    if isThreatBracketCard(cardIndex, context) then
        layers[#layers + 1] = "default"
    end

    if isPendingChoiceTarget(cardIndex, context)
        or isPrimedAbilityTarget(cardIndex, context)
        or (
        (context.selectedAttackerCardIndex or context.selectedAttackerTopSlotId) and isSelectedAttackerCardTarget(cardIndex, context)
    ) then
        layers[#layers + 1] = "strategy"
    end

    return layers
end

local function isThreatBracketTopSlot(slotId, context)
    context = context or {}

    if not slotId or slotId == context.hoveredTopSlotId or context.currentPhase ~= "War" then
        return false
    end

    local displayStates = context.displayStates or {}

    if context.hoveredTopSlotId then
        if targetingrules.rollStateTargetsTopSlot(displayStates[context.hoveredTopSlotId], slotId, context) then
            return true
        end

        if targetingrules.rollStateTargetsTopSlot(displayStates[slotId], context.hoveredTopSlotId, context) then
            return true
        end
    end

    if context.hoveredCardIndex then
        local hoveredCard = context.cards and context.cards[context.hoveredCardIndex] or nil

        if not hoveredCard or not hoveredCard.location or hoveredCard.location.kind ~= "grid" then
            return false
        end

        local hoveredRollState = context.getCardRollState and context.getCardRollState(context.hoveredCardIndex) or nil

        if hoveredCard.location.rowId ~= "PlayerRow"
            and targetingrules.rollStateTargetsTopSlot(
                hoveredRollState,
                slotId,
                context
            ) then
            return true
        end

        if targetingrules.rollStateTargetsCard(displayStates[slotId], context.hoveredCardIndex, context) then
            return true
        end
    end

    return false
end

function targetingrules.getTopSlotBracketLayers(slotId, context)
    context = context or {}

    local layers = {}

    if isThreatBracketTopSlot(slotId, context) then
        layers[#layers + 1] = "default"
    end

    if isPrimedAbilityTopSlotTarget(slotId, context) then
        layers[#layers + 1] = "strategy"
    end

    if (context.selectedAttackerCardIndex or context.selectedAttackerTopSlotId) and canSelectedAttackerTargetSlot(slotId, context) then
        layers[#layers + 1] = "strategy"
    end

    return layers
end

return targetingrules
