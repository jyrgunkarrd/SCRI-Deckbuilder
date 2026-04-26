local carddraw = require("src.render.carddraw")
local cardregistry = require("src.system.cardregistry")
local keywordrules = require("src.system.keywordrules")
local sfxrules = require("src.audio.sfxrules")

local engagerules = {}
local COUNTER_STRIKE_KEYWORD_ID = "KWCNTR"
local RELOADING_KEYWORD_ID = "KWRLD"
local RELOADING_KEYWORD_VALUE = 2

function engagerules.isEngagePhase(ctx)
    return ctx.turnrules.getCurrentPhase() == "War" and ctx.turnrules.getCurrentWarSubphase() == "Engage"
end

local function clearSelectedAttacker(ctx)
    ctx.setSelectedAttackerCardIndex(nil)
end

local function drawCardsForRoll(ctx, rollState)
    if not rollState or rollState.drawCards ~= true or not ctx.drawCardFromPlayerDeck then
        return
    end

    local drawCount = math.max(0, math.floor(tonumber(rollState.damageValue) or 0))

    for _ = 1, drawCount do
        if not ctx.drawCardFromPlayerDeck() then
            break
        end
    end
end

local function generateResourceForRoll(ctx, rollState)
    if not rollState or not rollState.generatedResource or not ctx.addMethodResource then
        return
    end

    ctx.addMethodResource(rollState.generatedResource, rollState.damageValue or 0)
end

local function applyRollUtilitySideEffects(ctx, rollState)
    if rollState and rollState.gainSyntac == true then
        ctx.addSyntac(rollState.damageValue or 0)
    end

    drawCardsForRoll(ctx, rollState)
    generateResourceForRoll(ctx, rollState)
end

local function isUtilityRollState(rollState)
    return rollState
        and rollState.action == "utility"
        and (
            rollState.gainSyntac == true
            or rollState.drawCards == true
            or rollState.generatedResource ~= nil
        )
        or false
end

local function applyPain(ctx, cardIndex, rollState)
    if not rollState or rollState.pain ~= true then
        return
    end

    local sourceCard = cardIndex and ctx.cards[cardIndex] or nil

    if sourceCard then
        ctx.dealDamageToCard(sourceCard, rollState.damageValue or 0)
    end
end

local function applyReloading(ctx, cardIndex, rollState)
    if not rollState or rollState.autoReload ~= true then
        return
    end

    local sourceCard = cardIndex and ctx.cards[cardIndex] or nil

    if sourceCard then
        keywordrules.setTemporaryKeywordValue(sourceCard, RELOADING_KEYWORD_ID, RELOADING_KEYWORD_VALUE)
    end
end

local function applyAreaDamageToAdjacentCards(ctx, attackerCardIndex, rollState, targetCardIndex)
    if not rollState
        or rollState.area ~= true
        or not targetCardIndex then
        return
    end

    local adjacentCardIndices = ctx.warrules.getAdjacentSameRowCardIndices(ctx.cards, targetCardIndex)

    for _, adjacentCardIndex in ipairs(adjacentCardIndices) do
        local adjacentCard = ctx.cards[adjacentCardIndex]

        if adjacentCard and not ctx.isCardUnavailable(adjacentCard) then
            local damageResult = ctx.dealDamageToCard(adjacentCard, rollState.damageValue or 0)

            if damageResult and damageResult.killed and attackerCardIndex and ctx.resolveKilledEnemyByPlayerCard then
                ctx.resolveKilledEnemyByPlayerCard(attackerCardIndex, adjacentCardIndex)
            end
        end
    end
end

local function finishSelectedAttack(ctx, saviorTriggered)
    if not saviorTriggered then
        if ctx.selectedAttackerTopSlotId then
            ctx.warrules.consumeEntityAttack(ctx.selectedAttackerTopSlotId)
        else
            ctx.warrules.consumeCardAttack(ctx.selectedAttackerCardIndex)
        end
    end

    clearSelectedAttacker(ctx)
end

local function resolveSelectedAttack(ctx, action)
    local attackerCardIndex = ctx.selectedAttackerCardIndex
    local attackerRollState = attackerCardIndex
        and ctx.warrules.getCardRollState(attackerCardIndex)
        or ctx.selectedAttackerTopSlotId and ctx.warrules.getDisplayStates()[ctx.selectedAttackerTopSlotId]
        or nil
    local saviorCheck = attackerCardIndex and ctx.warrules.beginSaviorCheck(attackerCardIndex, ctx.cards, ctx.isWarRollSourceActive) or nil
    local resolved = action()

    if not resolved then
        return false
    end

    finishSelectedAttack(ctx, saviorCheck and ctx.warrules.didSaviorPreventDeath(saviorCheck, ctx.cards, ctx.isWarRollSourceActive) or false)

    if attackerCardIndex then
        applyReloading(ctx, attackerCardIndex, attackerRollState)
        applyPain(ctx, attackerCardIndex, attackerRollState)
    end
    return true
end

local function resolveImmediateCardAction(ctx, cardIndex, action)
    local rollState = ctx.warrules.getCardRollState(cardIndex)
    local saviorCheck = ctx.warrules.beginSaviorCheck(cardIndex, ctx.cards, ctx.isWarRollSourceActive)
    local resolved = action()

    if not resolved then
        return false
    end

    if not ctx.warrules.didSaviorPreventDeath(saviorCheck, ctx.cards, ctx.isWarRollSourceActive) then
        ctx.warrules.consumeCardAttack(cardIndex)
    end

    applyReloading(ctx, cardIndex, rollState)
    applyPain(ctx, cardIndex, rollState)
    return true
end

local function applyAttackSideEffects(ctx, rollState)
    if rollState and rollState.sabotageObjective == true and ctx.activePrimaryObjective then
        ctx.addObjectiveProgress(ctx.activePrimaryObjective, -(rollState.damageValue or 0), "objective")
    end

    applyRollUtilitySideEffects(ctx, rollState)

    if rollState and rollState.selfBlock == true and ctx.selectedAttackerCardIndex then
        local attackerCard = ctx.cards[ctx.selectedAttackerCardIndex]

        if attackerCard then
            ctx.addBlockingToCard(attackerCard, rollState.damageValue or 0)
        end
    end

    if rollState and rollState.selfHeal == true and ctx.selectedAttackerCardIndex and ctx.healCard then
        local attackerCard = ctx.cards[ctx.selectedAttackerCardIndex]

        if attackerCard then
            ctx.healCard(attackerCard, rollState.damageValue or 0)
        end
    end
end

local function getCounterStrikeDamage(targetCard, targetDefinition)
    if not targetCard or not targetDefinition then
        return 0
    end

    if not keywordrules.cardHasKeyword(targetDefinition, COUNTER_STRIKE_KEYWORD_ID, targetCard) then
        return 0
    end

    return math.max(
        0,
        tonumber(keywordrules.getCardKeywordValue(targetCard, targetDefinition, COUNTER_STRIKE_KEYWORD_ID)) or 0
    )
end

local function applyCounterStrikeToAttacker(ctx, attackerCard, targetCard, targetDefinition)
    if not attackerCard then
        return
    end

    local counterDamage = getCounterStrikeDamage(targetCard, targetDefinition)

    if counterDamage <= 0 then
        return
    end

    ctx.dealDamageToCard(attackerCard, counterDamage)
end

local function applyPlayerWarzoneSideEffects(ctx, rollState)
    applyRollUtilitySideEffects(ctx, rollState)
end

local function canTargetEnemyWarzone(ctx, rollState)
    return ctx.warrules.hasTargetType(rollState, "WZOpp")
        or (
            rollState
            and rollState.action == "influence"
            and rollState.targetClass == "enemy_warzone"
        )
end

local function canTargetSabotage(ctx, rollState)
    return (
        rollState
        and rollState.action == "sabotage"
        and (
            rollState.targetClass == "objective_or_intel"
            or rollState.targetClass == "objective"
            or rollState.targetClass == "intel"
        )
    ) or ctx.warrules.hasTargetType(rollState, "Sab")
        or ctx.warrules.hasTargetType(rollState, "TacSab")
end

local function applySabotageSideEffects(ctx, rollState)
    applyRollUtilitySideEffects(ctx, rollState)
end

local function canApplySabotageToProgressTrack(ctx, objectiveDefinition, rollState)
    if not ctx.canApplyObjectiveProgress then
        return true
    end

    return ctx.canApplyObjectiveProgress(objectiveDefinition, -(rollState.damageValue or 0))
end

function engagerules.tryResolveClick(hoveredTopSlotId, ctx)
    if not engagerules.isEngagePhase(ctx) then
        return false
    end

    if ctx.selectedAttackerCardIndex or ctx.selectedAttackerTopSlotId then
        local selectedTopSlotDefinition = ctx.selectedAttackerTopSlotId == "warzone" and ctx.activeWarzone
            or ctx.selectedAttackerTopSlotId == "poi" and ctx.activePoi
            or nil
        local attackerCard = ctx.selectedAttackerCardIndex and ctx.cards[ctx.selectedAttackerCardIndex] or nil
        local attackerDefinition = attackerCard and cardregistry.getCard(attackerCard.setName, attackerCard.cardId) or selectedTopSlotDefinition
        local attackerRollState = ctx.selectedAttackerCardIndex
            and ctx.warrules.getCardRollState(ctx.selectedAttackerCardIndex)
            or ctx.selectedAttackerTopSlotId and ctx.warrules.getDisplayStates()[ctx.selectedAttackerTopSlotId]
            or nil

        if ctx.selectedAttackerCardIndex and (not attackerCard or not ctx.warrules.canCardAttack(ctx.selectedAttackerCardIndex)) then
            clearSelectedAttacker(ctx)
            return false
        end

        if ctx.selectedAttackerTopSlotId and (not selectedTopSlotDefinition or selectedTopSlotDefinition.allied ~= true or not ctx.warrules.canEntityAttack(ctx.selectedAttackerTopSlotId)) then
            clearSelectedAttacker(ctx)
            return false
        end

        if ctx.selectedAttackerCardIndex and ctx.warrules.refreshCardRollValue then
            ctx.warrules.refreshCardRollValue(ctx.selectedAttackerCardIndex, ctx.cards)
            attackerRollState = ctx.warrules.getCardRollState(ctx.selectedAttackerCardIndex)
        end

        if ctx.warrules.hasTargetType(attackerRollState, "Blk") then
            if ctx.hoveredCardIndex then
                local targetCard = ctx.cards[ctx.hoveredCardIndex]

                if targetCard
                    and targetCard.location.kind == "grid"
                    and targetCard.location.rowId == "PlayerRow" then
                    local targetDefinition = cardregistry.getCard(targetCard.setName, targetCard.cardId)

                    if not ctx.warrules.canTargetCardByHeavyRestriction(targetDefinition, targetCard, attackerRollState, ctx.cards) then
                        return true
                    end

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
                    local targetDefinition = cardregistry.getCard(targetCard.setName, targetCard.cardId)

                    if not ctx.warrules.canTargetCardByHeavyRestriction(targetDefinition, targetCard, attackerRollState, ctx.cards) then
                        return true
                    end

                    resolveSelectedAttack(ctx, function()
                        ctx.warrules.redirectIncomingAttacks(ctx.cards, ctx.hoveredCardIndex, ctx.selectedAttackerCardIndex)
                        ctx.addBlockingToCard(attackerCard, attackerRollState.damageValue or 0)
                        return true
                    end)

                    return true
                end
            end
        end

        if ctx.selectedAttackerCardIndex and ctx.hoveredCardIndex == ctx.selectedAttackerCardIndex then
            clearSelectedAttacker(ctx)
            return true
        end

        if ctx.selectedAttackerTopSlotId and hoveredTopSlotId == ctx.selectedAttackerTopSlotId then
            clearSelectedAttacker(ctx)
            return true
        end

        if isUtilityRollState(attackerRollState) then
            resolveSelectedAttack(ctx, function()
                applyRollUtilitySideEffects(ctx, attackerRollState)
                return true
            end)
            return true
        end

        if canTargetSabotage(ctx, attackerRollState) then
            if hoveredTopSlotId == "objective" and ctx.activePrimaryObjective then
                if not canApplySabotageToProgressTrack(ctx, ctx.activePrimaryObjective, attackerRollState) then
                    return true
                end

                resolveSelectedAttack(ctx, function()
                    ctx.addObjectiveProgress(ctx.activePrimaryObjective, -(attackerRollState.damageValue or 0), "objective")
                    applySabotageSideEffects(ctx, attackerRollState)
                    return true
                end)
                return true
            elseif hoveredTopSlotId == "intel" and ctx.activeIntel then
                if not canApplySabotageToProgressTrack(ctx, ctx.activeIntel, attackerRollState) then
                    return true
                end

                resolveSelectedAttack(ctx, function()
                    ctx.addObjectiveProgress(ctx.activeIntel, -(attackerRollState.damageValue or 0), "intel")
                    applySabotageSideEffects(ctx, attackerRollState)
                    return true
                end)
                return true
            end
        end

        if ctx.warrules.canTargetPlayerWarzone(attackerRollState) then
            if hoveredTopSlotId == "warzone" and ctx.activeWarzone then
                resolveSelectedAttack(ctx, function()
                    ctx.addWarzoneControl(ctx.activeWarzone, attackerRollState.damageValue or 0, "warzone")
                    applyPlayerWarzoneSideEffects(ctx, attackerRollState)
                    return true
                end)
                return true
            elseif hoveredTopSlotId == "poi" and ctx.activePoi then
                resolveSelectedAttack(ctx, function()
                    ctx.addWarzoneControl(ctx.activePoi, attackerRollState.damageValue or 0, "poi")
                    applyPlayerWarzoneSideEffects(ctx, attackerRollState)
                    return true
                end)
                return true
            end
        end

        if canTargetEnemyWarzone(ctx, attackerRollState) then
            if hoveredTopSlotId == "warzone" and ctx.activeWarzone then
                resolveSelectedAttack(ctx, function()
                    ctx.addWarzoneControl(ctx.activeWarzone, -(attackerRollState.damageValue or 0), "warzone")
                    applyPlayerWarzoneSideEffects(ctx, attackerRollState)
                    return true
                end)
                return true
            elseif hoveredTopSlotId == "poi" and ctx.activePoi then
                resolveSelectedAttack(ctx, function()
                    ctx.addWarzoneControl(ctx.activePoi, -(attackerRollState.damageValue or 0), "poi")
                    applyPlayerWarzoneSideEffects(ctx, attackerRollState)
                    return true
                end)
                return true
            end
        end

        if hoveredTopSlotId == "champion" and ctx.warrules.canTargetEnemyCard(attackerRollState) then
            resolveSelectedAttack(ctx, function()
                applyCounterStrikeToAttacker(ctx, attackerCard, ctx.activeChampion, ctx.activeChampion)

                if attackerCard and ctx.isCardUnavailable(attackerCard) then
                    return true
                end

                ctx.dealDamageToChampion(attackerRollState.damageValue or 0)
                applyAttackSideEffects(ctx, attackerRollState)
                return true
            end)
            return true
        end

        if ctx.hoveredCardIndex then
            local targetCard = ctx.cards[ctx.hoveredCardIndex]

            if targetCard
                and targetCard.location.kind == "grid"
                and targetCard.location.rowId == "OppRow"
                and ctx.warrules.canTargetEnemyCard(attackerRollState) then
                local targetDefinition = cardregistry.getCard(targetCard.setName, targetCard.cardId)

                if ctx.warrules.canAttackTarget(attackerDefinition, targetDefinition, attackerCard, targetCard, attackerRollState, ctx.cards) then
                    resolveSelectedAttack(ctx, function()
                        applyCounterStrikeToAttacker(ctx, attackerCard, targetCard, targetDefinition)

                        if attackerCard and ctx.isCardUnavailable(attackerCard) then
                            return true
                        end

                        local damageResult = ctx.dealDamageToCard(targetCard, attackerRollState.damageValue or 0)

                        if damageResult and damageResult.killed and ctx.resolveKilledEnemyByPlayerCard and ctx.selectedAttackerCardIndex then
                            ctx.resolveKilledEnemyByPlayerCard(ctx.selectedAttackerCardIndex, ctx.hoveredCardIndex)
                        end

                        if ctx.selectedAttackerCardIndex then
                            applyAreaDamageToAdjacentCards(ctx, ctx.selectedAttackerCardIndex, attackerRollState, ctx.hoveredCardIndex)
                        else
                            applyAreaDamageToAdjacentCards(ctx, nil, attackerRollState, ctx.hoveredCardIndex)
                        end

                        applyAttackSideEffects(ctx, attackerRollState)
                        return true
                    end)
                end

                return true
            end
        end

        return true
    end

    if hoveredTopSlotId == "warzone"
        and ctx.activeWarzone
        and ctx.activeWarzone.allied == true
        and ctx.warrules.canEntityAttack("warzone") then
        local hoveredRollState = ctx.warrules.getDisplayStates()["warzone"]

        ctx.setSelectedAttackerTopSlotId("warzone")
        ctx.selectedAttackerTopSlotId = "warzone"
        ctx.setExpandedGridCardIndex(nil)
        ctx.setExpandedTopSlotId(nil)

        if isUtilityRollState(hoveredRollState) then
            resolveSelectedAttack(ctx, function()
                applyRollUtilitySideEffects(ctx, hoveredRollState)
                return true
            end)
        end

        return true
    end

    if ctx.hoveredCardIndex then
        local hoveredCard = ctx.cards[ctx.hoveredCardIndex]

        if hoveredCard
            and hoveredCard.location.kind == "grid"
            and hoveredCard.location.rowId == "PlayerRow"
            and ctx.warrules.canCardAttack(ctx.hoveredCardIndex) then
            if ctx.warrules.refreshCardRollValue then
                ctx.warrules.refreshCardRollValue(ctx.hoveredCardIndex, ctx.cards)
            end

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

            if hoveredRollState and ctx.warrules.hasTargetType(hoveredRollState, "smn") then
                local generatedCardDefinition = cardregistry.getCardById(hoveredRollState.cardgen)
                local spawnCount = math.max(0, math.floor(tonumber(hoveredRollState.damageValue) or 0))

                if generatedCardDefinition and spawnCount > 0 and ctx.spawnTokensNearCard then
                    resolveImmediateCardAction(ctx, ctx.hoveredCardIndex, function()
                        ctx.spawnTokensNearCard(ctx.hoveredCardIndex, generatedCardDefinition, spawnCount)
                        return true
                    end)
                end

                return true
            end

            if hoveredRollState and ctx.warrules.hasTargetType(hoveredRollState, "rsmn") then
                local generatedCardDefinitions = {}
                local spawnCount = math.max(0, math.floor(tonumber(hoveredRollState.damageValue) or 0))

                for _, cardId in ipairs(hoveredRollState.cardgenPool or {}) do
                    local generatedCardDefinition = cardregistry.getCardById(cardId)

                    if generatedCardDefinition then
                        generatedCardDefinitions[#generatedCardDefinitions + 1] = generatedCardDefinition
                    end
                end

                if #generatedCardDefinitions > 0 and spawnCount > 0 and ctx.spawnRandomTokensNearCard then
                    resolveImmediateCardAction(ctx, ctx.hoveredCardIndex, function()
                        ctx.spawnRandomTokensNearCard(ctx.hoveredCardIndex, generatedCardDefinitions, spawnCount)
                        return true
                    end)
                end

                return true
            end

            if hoveredRollState
                and (
                    isUtilityRollState(hoveredRollState)
                    or ctx.warrules.hasTargetType(hoveredRollState, "Tac")
                ) then
                resolveImmediateCardAction(ctx, ctx.hoveredCardIndex, function()
                    applyRollUtilitySideEffects(ctx, hoveredRollState)
                    return true
                end)

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

function engagerules.tryCancelSelectedAttacker(ctx)
    if not engagerules.isEngagePhase(ctx) or (not ctx.selectedAttackerCardIndex and not ctx.selectedAttackerTopSlotId) then
        return false
    end

    clearSelectedAttacker(ctx)
    return true
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

    local alliedTopSlots = {}

    if ctx.activeWarzone and ctx.activeWarzone.allied == true then
        alliedTopSlots[#alliedTopSlots + 1] = {
            id = "warzone",
            definition = ctx.activeWarzone,
        }
    end

    local rerolledAny = ctx.warrules.rerollUnlockedPlayerCards(ctx.cards, alliedTopSlots)
    ctx.setEngageRerollCount(math.max(0, ctx.engageRerollCount - 1))
    clearSelectedAttacker(ctx)

    if rerolledAny then
        sfxrules.playDice()
    end

    return true
end

return engagerules
