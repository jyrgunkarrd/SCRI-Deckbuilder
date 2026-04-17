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

local function consumeSelectedAttack(ctx)
    ctx.warrules.consumeCardAttack(ctx.selectedAttackerCardIndex)
    clearSelectedAttacker(ctx)
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

        if attackerRollState.targetType == "Blk" then
            if ctx.hoveredCardIndex then
                local targetCard = ctx.cards[ctx.hoveredCardIndex]

                if targetCard
                    and targetCard.location.kind == "grid"
                    and targetCard.location.rowId == "PlayerRow" then
                    ctx.addBlockingToCard(targetCard, attackerRollState.damageValue or 0)
                    consumeSelectedAttack(ctx)
                end
            end

            return true
        end

        if ctx.hoveredCardIndex == ctx.selectedAttackerCardIndex then
            clearSelectedAttacker(ctx)
            return true
        end

        if attackerRollState.targetType == "Sab" then
            if hoveredTopSlotId == "objective" and ctx.activePrimaryObjective then
                ctx.addObjectiveProgress(ctx.activePrimaryObjective, -(attackerRollState.damageValue or 0), "objective")
                consumeSelectedAttack(ctx)
                return true
            elseif hoveredTopSlotId == "intel" and ctx.activeIntel then
                ctx.addObjectiveProgress(ctx.activeIntel, -(attackerRollState.damageValue or 0), "intel")
                consumeSelectedAttack(ctx)
                return true
            end

            return true
        end

        if attackerRollState.targetType == "WZPlayer" then
            if hoveredTopSlotId == "warzone" and ctx.activeWarzone then
                ctx.addWarzoneControl(ctx.activeWarzone, attackerRollState.damageValue or 0, "warzone")
                consumeSelectedAttack(ctx)
            elseif hoveredTopSlotId == "poi" and ctx.activePoi then
                ctx.addWarzoneControl(ctx.activePoi, attackerRollState.damageValue or 0, "poi")
                consumeSelectedAttack(ctx)
            end

            return true
        end

        if hoveredTopSlotId == "champion" then
            ctx.dealDamageToChampion(attackerRollState.damageValue or 0)
            consumeSelectedAttack(ctx)
            return true
        end

        if ctx.hoveredCardIndex then
            local targetCard = ctx.cards[ctx.hoveredCardIndex]

            if targetCard and targetCard.location.kind == "grid" and targetCard.location.rowId == "OppRow" then
                local attackerDefinition = cardregistry.getCard(attackerCard.setName, attackerCard.cardId)
                local targetDefinition = cardregistry.getCard(targetCard.setName, targetCard.cardId)

                if ctx.warrules.canAttackTarget(attackerDefinition, targetDefinition) then
                    ctx.dealDamageToCard(targetCard, attackerRollState.damageValue or 0)
                    consumeSelectedAttack(ctx)
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

            if hoveredRollState and hoveredRollState.targetType == "Inf" then
                local generatedCardDefinition = cardregistry.getCardById(hoveredRollState.cardgen)

                if generatedCardDefinition
                    and ctx.beginInfiltrationEffect(ctx.warrules.getCardEntityKey(ctx.hoveredCardIndex), generatedCardDefinition, hoveredRollState.damageValue or 0) then
                    ctx.warrules.consumeCardAttack(ctx.hoveredCardIndex)
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
