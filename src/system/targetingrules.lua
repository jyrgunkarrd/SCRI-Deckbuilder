local targetingrules = {}

function targetingrules.rollStateTargetsCard(rollState, cardIndex)
    return rollState
        and rollState.targetType == "Atk"
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
        return rollState.targetType == "Obj"
            and targetCard.kind == "objective"
            and context.activePrimaryObjective
            and targetCard.objectiveId == context.activePrimaryObjective.id
    elseif slotId == "intel" then
        return rollState.targetType == "IntCD"
            and targetCard.kind == "intel"
            and context.activeIntel
            and targetCard.objectiveId == context.activeIntel.id
    elseif slotId == "warzone" then
        return (rollState.targetType == "WZOpp" or rollState.targetType == "WZPlayer")
            and targetCard.kind == "warzone"
            and context.activeWarzone
            and targetCard.warzoneId == context.activeWarzone.id
    elseif slotId == "poi" then
        return (rollState.targetType == "WZOpp" or rollState.targetType == "WZPlayer")
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

        if targetingrules.rollStateTargetsCard(hoveredTopSlotRollState, cardIndex) then
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
            and targetingrules.rollStateTargetsCard(hoveredRollState, cardIndex) then
            return true
        end

        if hoveredCard.location.rowId == "PlayerRow" then
            local rollState = context.getCardRollState and context.getCardRollState(cardIndex) or nil
            local card = context.cards and context.cards[cardIndex] or nil

            return card
                and card.location
                and card.location.kind == "grid"
                and card.location.rowId == "OppRow"
                and targetingrules.rollStateTargetsCard(rollState, context.hoveredCardIndex)
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

    if context.hoveredCardIndex then
        local hoveredCard = context.cards and context.cards[context.hoveredCardIndex] or nil

        if not hoveredCard or not hoveredCard.location or hoveredCard.location.kind ~= "grid" then
            return false
        end

        if hoveredCard.location.rowId ~= "PlayerRow"
            and targetingrules.rollStateTargetsTopSlot(
                context.getCardRollState and context.getCardRollState(context.hoveredCardIndex) or nil,
                slotId,
                context
            ) then
            return true
        end

        if targetingrules.rollStateTargetsCard(displayStates[slotId], context.hoveredCardIndex) then
            return true
        end
    end

    return false
end

return targetingrules
