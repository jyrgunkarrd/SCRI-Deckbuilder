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

    return hasTargetType(rollState, "Atk") or hasTargetType(rollState, "AtkSab")
end

local function canTargetPlayerWarzone(rollState, context)
    if context and context.canTargetPlayerWarzone then
        return context.canTargetPlayerWarzone(rollState)
    end

    return hasTargetType(rollState, "WZPlayer") or hasTargetType(rollState, "InfTac")
end

local function isPlayerGridCard(card)
    return card
        and card.location
        and card.location.kind == "grid"
        and card.location.rowId == "PlayerRow"
end

function targetingrules.rollStateTargetsCard(rollState, cardIndex, context)
    return rollState
        and canTargetEnemyCard(rollState, context)
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
        return hasTargetType(rollState, "Obj")
            and targetCard.kind == "objective"
            and context.activePrimaryObjective
            and targetCard.objectiveId == context.activePrimaryObjective.id
    elseif slotId == "intel" then
        return hasTargetType(rollState, "IntCD")
            and targetCard.kind == "intel"
            and context.activeIntel
            and targetCard.objectiveId == context.activeIntel.id
    elseif slotId == "warzone" then
        return (hasTargetType(rollState, "WZOpp") or canTargetPlayerWarzone(rollState, context))
            and targetCard.kind == "warzone"
            and context.activeWarzone
            and targetCard.warzoneId == context.activeWarzone.id
    elseif slotId == "poi" then
        return (hasTargetType(rollState, "WZOpp") or canTargetPlayerWarzone(rollState, context))
            and targetCard.kind == "warzone"
            and context.activePoi
            and targetCard.warzoneId == context.activePoi.id
    end

    return false
end

function targetingrules.shouldBracketCard(cardIndex, context)
    context = context or {}

    if cardIndex == context.hoveredCardIndex or context.currentPhase ~= "War" then
        return false
    end

    local displayStates = context.displayStates or {}

    if context.hoveredTopSlotId then
        local hoveredTopSlotRollState = displayStates[context.hoveredTopSlotId]

        if targetingrules.rollStateTargetsCard(hoveredTopSlotRollState, cardIndex, context) then
            return true
        end

        local cardRollState = context.getCardRollState and context.getCardRollState(cardIndex) or nil
        local card = context.cards and context.cards[cardIndex] or nil

        if context.hoveredTopSlotId == "champion"
            and context.activeChampion
            and isPlayerGridCard(card)
            and canTargetEnemyCard(cardRollState, context) then
            return true
        end

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

function targetingrules.shouldBracketTopSlot(slotId, context)
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

        if slotId == "champion"
            and context.activeChampion
            and isPlayerGridCard(hoveredCard)
            and canTargetEnemyCard(hoveredRollState, context) then
            return true
        end

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

return targetingrules
