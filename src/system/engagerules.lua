local carddraw = require("src.render.carddraw")
local cardregistry = require("src.system.cardregistry")
local sfxrules = require("src.audio.sfxrules")

local engagerules = {}

function engagerules.isEngagePhase(ctx)
    return ctx.turnrules.getCurrentPhase() == "War" and ctx.turnrules.getCurrentWarSubphase() == "Engage"
end

local function clearSelectedAttacker(ctx)
    ctx.setSelectedAttackerCardIndex(nil)
end

local function finishSelectedAttack(ctx, saviorTriggered)
    if not saviorTriggered then
        ctx.warrules.consumeCardAttack(ctx.selectedAttackerCardIndex)
    end

    clearSelectedAttacker(ctx)
end

local function resolveSelectedAttack(ctx, action)
    local attackerCardIndex = ctx.selectedAttackerCardIndex
    local saviorCheck = ctx.warrules.beginSaviorCheck(attackerCardIndex, ctx.cards, ctx.isWarRollSourceActive)
    local resolved = action()

    if not resolved then
        return false
    end

    finishSelectedAttack(ctx, ctx.warrules.didSaviorPreventDeath(saviorCheck, ctx.cards, ctx.isWarRollSourceActive))
    return true
end

local function resolveImmediateCardAction(ctx, cardIndex, action)
    local saviorCheck = ctx.warrules.beginSaviorCheck(cardIndex, ctx.cards, ctx.isWarRollSourceActive)
    local resolved = action()

    if not resolved then
        return false
    end

    if not ctx.warrules.didSaviorPreventDeath(saviorCheck, ctx.cards, ctx.isWarRollSourceActive) then
        ctx.warrules.consumeCardAttack(cardIndex)
    end

    return true
end

function engagerules.tryResolveClick(hoveredTopSlotId, ctx)
    if not engagerules.isEngagePhase(ctx) then
        return false
    end

    if ctx.selectedAttackerCardIndex then
        local attackerCard = ctx.cards[ctx.selectedAttackerCardIndex]
        local attackerRollState = ctx.warrules.getCardRollState(ctx.selectedAttackerCardIndex)

        if not attackerCard or not ctx.warrules.canCardAttack(ctx.selectedAttackerCardIndex) then
            clearSelectedAttacker(ctx)
            return false
        end

        if ctx.warrules.hasTargetType(attackerRollState, "Blk") then
            if ctx.hoveredCardIndex then
                local targetCard = ctx.cards[ctx.hoveredCardIndex]

                if targetCard
                    and targetCard.location.kind == "grid"
                    and targetCard.location.rowId == "PlayerRow" then
                    resolveSelectedAttack(ctx, function()
                        ctx.addBlockingToCard(targetCard, attackerRollState.damageValue or 0)
                        return true
                    end)

                    return true
                end
            end
        end

        if ctx.warrules.hasTargetType(attackerRollState, "Div") then
            if ctx.hoveredCardIndex then
                local targetCard = ctx.cards[ctx.hoveredCardIndex]

                if targetCard
                    and targetCard.location.kind == "grid"
                    and targetCard.location.rowId == "PlayerRow" then
                    resolveSelectedAttack(ctx, function()
                        ctx.warrules.redirectIncomingAttacks(ctx.cards, ctx.hoveredCardIndex, ctx.selectedAttackerCardIndex)
                        ctx.addBlockingToCard(attackerCard, attackerRollState.damageValue or 0)
                        return true
                    end)

                    return true
                end
            end
        end

        if ctx.hoveredCardIndex == ctx.selectedAttackerCardIndex then
            clearSelectedAttacker(ctx)
            return true
        end

        if ctx.warrules.hasTargetType(attackerRollState, "Sab") then
            if hoveredTopSlotId == "objective" and ctx.activePrimaryObjective then
                resolveSelectedAttack(ctx, function()
                    ctx.addObjectiveProgress(ctx.activePrimaryObjective, -(attackerRollState.damageValue or 0), "objective")
                    return true
                end)
                return true
            elseif hoveredTopSlotId == "intel" and ctx.activeIntel then
                resolveSelectedAttack(ctx, function()
                    ctx.addObjectiveProgress(ctx.activeIntel, -(attackerRollState.damageValue or 0), "intel")
                    return true
                end)
                return true
            end
        end

        if ctx.warrules.hasTargetType(attackerRollState, "WZPlayer") then
            if hoveredTopSlotId == "warzone" and ctx.activeWarzone then
                resolveSelectedAttack(ctx, function()
                    ctx.addWarzoneControl(ctx.activeWarzone, attackerRollState.damageValue or 0, "warzone")
                    return true
                end)
            elseif hoveredTopSlotId == "poi" and ctx.activePoi then
                resolveSelectedAttack(ctx, function()
                    ctx.addWarzoneControl(ctx.activePoi, attackerRollState.damageValue or 0, "poi")
                    return true
                end)
            end
        end

        if hoveredTopSlotId == "champion" and ctx.warrules.hasTargetType(attackerRollState, "Atk") then
            resolveSelectedAttack(ctx, function()
                ctx.dealDamageToChampion(attackerRollState.damageValue or 0)
                return true
            end)
            return true
        end

        if ctx.hoveredCardIndex then
            local targetCard = ctx.cards[ctx.hoveredCardIndex]

            if targetCard
                and targetCard.location.kind == "grid"
                and targetCard.location.rowId == "OppRow"
                and (ctx.warrules.hasTargetType(attackerRollState, "Atk") or ctx.warrules.hasTargetType(attackerRollState, "AtkSab")) then
                local attackerDefinition = cardregistry.getCard(attackerCard.setName, attackerCard.cardId)
                local targetDefinition = cardregistry.getCard(targetCard.setName, targetCard.cardId)

                if ctx.warrules.canAttackTarget(attackerDefinition, targetDefinition) then
                    resolveSelectedAttack(ctx, function()
                        ctx.dealDamageToCard(targetCard, attackerRollState.damageValue or 0)

                        if ctx.warrules.hasTargetType(attackerRollState, "AtkSab") and ctx.activePrimaryObjective then
                            ctx.addObjectiveProgress(ctx.activePrimaryObjective, -(attackerRollState.damageValue or 0), "objective")
                        end

                        return true
                    end)
                end

                return true
            end
        end

        return true
    end

    if ctx.hoveredCardIndex then
        local hoveredCard = ctx.cards[ctx.hoveredCardIndex]

        if hoveredCard
            and hoveredCard.location.kind == "grid"
            and hoveredCard.location.rowId == "PlayerRow"
            and ctx.warrules.canCardAttack(ctx.hoveredCardIndex) then
            local hoveredRollState = ctx.warrules.getCardRollState(ctx.hoveredCardIndex)

            if hoveredRollState and ctx.warrules.hasTargetType(hoveredRollState, "Inf") then
                local generatedCardDefinition = cardregistry.getCardById(hoveredRollState.cardgen)

                if generatedCardDefinition then
                    resolveImmediateCardAction(ctx, ctx.hoveredCardIndex, function()
                        return ctx.beginInfiltrationEffect(ctx.warrules.getCardEntityKey(ctx.hoveredCardIndex), generatedCardDefinition, hoveredRollState.damageValue or 0)
                    end)
                end

                return true
            end

            ctx.setSelectedAttackerCardIndex(ctx.hoveredCardIndex)
            ctx.setExpandedGridCardIndex(nil)
            ctx.setExpandedTopSlotId(nil)
            return true
        end
    end

    return false
end

function engagerules.getHoveredPlayerRollBadgeCardIndex(mouseX, mouseY, ctx)
    if not engagerules.isEngagePhase(ctx) then
        return nil
    end

    for cardIndex = #ctx.cards, 1, -1 do
        local card = ctx.cards[cardIndex]
        local rollState = ctx.warrules.getCardRollState(cardIndex)

        if card
            and not ctx.isCardUnavailable(card)
            and card.location.kind == "grid"
            and card.location.rowId == "PlayerRow"
            and rollState
            and rollState.faceIndex then
            local drawX, drawY, _, renderOptions = ctx.getCardDrawPosition(card, cardIndex)
            local badgeX, badgeY, badgeWidth, badgeHeight = carddraw.getCardRollBadgeRect(drawX, drawY, renderOptions)

            if mouseX >= badgeX
                and mouseX <= badgeX + badgeWidth
                and mouseY >= badgeY
                and mouseY <= badgeY + badgeHeight then
                return cardIndex
            end
        end
    end

    return nil
end

function engagerules.isPointInsideRerollButton(mouseX, mouseY, ctx)
    if not engagerules.isEngagePhase(ctx) then
        return false
    end

    local layout = ctx.envdraw.getRerollButtonLayout(ctx.playerJacl)

    return mouseX >= layout.x
        and mouseX <= layout.x + layout.width
        and mouseY >= layout.y
        and mouseY <= layout.y + layout.height
end

function engagerules.tryUseReroll(mouseX, mouseY, ctx)
    if not engagerules.isPointInsideRerollButton(mouseX, mouseY, ctx) or ctx.engageRerollCount <= 0 then
        return false
    end

    local rerolledAny = ctx.warrules.rerollUnlockedPlayerCards(ctx.cards)
    ctx.setEngageRerollCount(math.max(0, ctx.engageRerollCount - 1))
    clearSelectedAttacker(ctx)

    if rerolledAny then
        sfxrules.playDice()
    end

    return true
end

return engagerules
