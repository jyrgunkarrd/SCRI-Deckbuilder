local syntacrules = {}

local SCRATCH_RESOURCE_NAME = "The Scratch"
local REWARD_COST = 2
local LEXURGY_COST = 2
local LEXURGY_VALUE = 2

function syntacrules.resolveRewardButtons(ctx)
    local state = ctx.state
    local rewardButtons = state.syntacRewardButtons or {}
    local nextRewardButtons = {}

    if rewardButtons.draw then
        ctx.drawCardFromPlayerDeck()
    end

    if rewardButtons.rerolls then
        state.engageRerollBonus = math.max(0, tonumber(state.engageRerollBonus) or 0) + 2
    end

    if rewardButtons.method and rewardButtons.methodResource then
        local methodButton = ctx.envdraw.getSyntacRewardButtonLayout("method", state.playerJacl)
        local sourceCenter = methodButton and {
            x = methodButton.x + (methodButton.width / 2),
            y = methodButton.y + (methodButton.height / 2),
        } or nil

        ctx.resourcerules.addResourceFromSource(
            rewardButtons.methodResource,
            1,
            sourceCenter,
            ctx.envdraw.getBottomLeftPanelLayout(state.playerJacl),
            ctx.envdraw.getResourceTrackerLayout()
        )

        nextRewardButtons.method = true
        nextRewardButtons.methodResource = rewardButtons.methodResource
        state.syntacMethodRewardAnimating = true
    end

    state.syntacRewardButtons = nextRewardButtons
end

function syntacrules.clearResolvedMethodReward(state)
    if state.syntacMethodRewardAnimating then
        state.syntacMethodRewardAnimating = false
        state.syntacRewardButtons = {}
    end
end

function syntacrules.refundPendingMethodChoice(ctx)
    local state = ctx.state

    if state.syntacPendingMethodChoicePaid then
        ctx.resourcerules.addResource(SCRATCH_RESOURCE_NAME, REWARD_COST)
        ctx.sfxrules.playResourcePlay()
        state.syntacPendingMethodChoicePaid = false
    end

    state.isSyntacMethodModalOpen = false
end

function syntacrules.chooseMethodResource(resourceName, ctx)
    local state = ctx.state

    if not state.syntacPendingMethodChoicePaid or not resourceName then
        return false
    end

    state.syntacRewardButtons = state.syntacRewardButtons or {}
    state.syntacRewardButtons.method = true
    state.syntacRewardButtons.methodResource = resourceName
    state.syntacPendingMethodChoicePaid = false
    state.isSyntacMethodModalOpen = false
    ctx.sfxrules.playResourcePlay()
    return true
end

function syntacrules.canUseRewardButtons(ctx)
    return ctx.getCurrentPhase() == "Prelude" or ctx.isEngagePhase()
end

function syntacrules.tryUseRewardButton(mouseX, mouseY, ctx)
    local state = ctx.state
    local button = ctx.envdraw.getSyntacRewardButtonAt(mouseX, mouseY, state.playerJacl)

    if not button or (button.id ~= "method" and button.id ~= "draw" and button.id ~= "rerolls" and button.id ~= "munitions" and button.id ~= "tithes") then
        return false
    end

    if button.id == "tithes" then
        if ctx.tithesrules and ctx.tithesrules.tryUseButton then
            return ctx.tithesrules.tryUseButton(ctx)
        end

        ctx.sfxrules.playPlayReject()
        return true
    end

    if button.id == "munitions" then
        if ctx.munitionsrules and ctx.munitionsrules.tryUseButton then
            return ctx.munitionsrules.tryUseButton(ctx)
        end

        ctx.sfxrules.playPlayReject()
        return true
    end

    if not syntacrules.canUseRewardButtons(ctx) then
        ctx.sfxrules.playPlayReject()
        return true
    end

    state.syntacRewardButtons = state.syntacRewardButtons or {}

    if state.syntacRewardButtons[button.id] then
        ctx.sfxrules.playPlayReject()
        return true
    end

    if button.id == "method" and state.syntacPendingMethodChoicePaid then
        ctx.sfxrules.playPlayReject()
        return true
    end

    if not ctx.resourcerules.payCosts({
        { resource = SCRATCH_RESOURCE_NAME, amount = REWARD_COST },
    }) then
        ctx.sfxrules.playPlayReject()
        return true
    end

    if button.id == "method" then
        state.syntacPendingMethodChoicePaid = true
        state.isSyntacMethodModalOpen = true
        state.isResourceExchangeModalOpen = false
        state.isJaclDeckModalOpen = false
        ctx.sfxrules.playResourcePlay()
        return true
    end

    state.syntacRewardButtons[button.id] = true
    ctx.sfxrules.playResourcePlay()
    return true
end

function syntacrules.refundPrimedAbility(state)
    local primedSyntacAbility = state.primedSyntacAbility

    if not primedSyntacAbility then
        return false
    end

    state.syntacCount = math.min(
        10,
        math.max(0, (state.syntacCount or 0) + math.max(0, tonumber(primedSyntacAbility.cost) or 0))
    )
    state.primedSyntacAbility = nil
    return true
end

function syntacrules.tryPrimeAbility(mouseX, mouseY, ctx)
    local state = ctx.state

    if not ctx.envdraw.isPointInsideSyntacBox(mouseX, mouseY, state.playerJacl) then
        return false
    end

    if state.primedSyntacAbility then
        ctx.sfxrules.playPlayReject()
        return true
    end

    if (state.syntacCount or 0) < LEXURGY_COST then
        ctx.sfxrules.playPlayReject()
        return true
    end

    state.syntacCount = math.max(0, (state.syntacCount or 0) - LEXURGY_COST)
    state.primedSyntacAbility = {
        cost = LEXURGY_COST,
    }
    ctx.sfxrules.playResourcePlay()
    return true
end

function syntacrules.isBlockTarget(card, ctx)
    if not card or not card.location or card.location.kind ~= "grid" or card.location.rowId ~= "PlayerRow" then
        return false
    end

    local cardDefinition = ctx.cardregistry.getCard(card.setName, card.cardId)
    local cardType = cardDefinition and cardDefinition.type or nil

    return cardType == "troop" or cardType == "agent" or cardType == "token" or cardType == "crew"
end

function syntacrules.tryResolvePrimedAbility(cardIndex, topSlotId, ctx)
    local state = ctx.state

    if not state.primedSyntacAbility then
        return false
    end

    if cardIndex then
        local targetCard = state.cards[cardIndex]

        if syntacrules.isBlockTarget(targetCard, ctx) then
            local blockResult = ctx.addBlockingToCard(targetCard, LEXURGY_VALUE)

            if blockResult and blockResult.changed then
                state.primedSyntacAbility = nil
                ctx.sfxrules.playResourcePlay()
                return true
            end

            return false
        end

        if targetCard
            and targetCard.location
            and targetCard.location.kind == "grid"
            and targetCard.location.rowId == "OppRow" then
            local damageResult = ctx.dealDamageToCard(targetCard, LEXURGY_VALUE)

            if damageResult and damageResult.changed then
                state.primedSyntacAbility = nil
                return true
            end

            return false
        end
    end

    if topSlotId == "champion" then
        local damageResult = ctx.dealDamageToChampion(LEXURGY_VALUE)

        if damageResult and damageResult.changed then
            state.primedSyntacAbility = nil
            return true
        end

        return false
    elseif topSlotId == "warzone" then
        if ctx.addWarzoneControl(state.activeWarzone, LEXURGY_VALUE, "warzone") ~= 0 then
            state.primedSyntacAbility = nil
            return true
        end

        return false
    elseif topSlotId == "poi" then
        if ctx.addWarzoneControl(state.activePoi, LEXURGY_VALUE, "poi") ~= 0 then
            state.primedSyntacAbility = nil
            return true
        end

        return false
    elseif topSlotId == "objective" then
        if ctx.addObjectiveProgress(state.activePrimaryObjective, -LEXURGY_VALUE, "objective") ~= 0 then
            state.primedSyntacAbility = nil
            return true
        end

        return false
    elseif topSlotId == "intel" then
        if ctx.addObjectiveProgress(state.activeIntel, -LEXURGY_VALUE, "intel") ~= 0 then
            state.primedSyntacAbility = nil
            return true
        end

        return false
    end

    return false
end

return syntacrules
