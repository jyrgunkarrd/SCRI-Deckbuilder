local cardinstances = require("src.system.cardinstances")
local deckrules = require("src.system.deckrules")
local keywordrules = require("src.system.keywordrules")

local cardlifecycle = {}
local INCAP_SET_NAME = "troops"
local INCAP_CARD_ID = "INCAP"
local INCAP_RECOVERY_ANIMATION_DURATION = 0.58
local BOOM_KEYWORD_ID = "KWBOOM"

local function copyMethodEntries(methodEntries)
    local copiedEntries = {}

    for _, methodEntry in ipairs(methodEntries or {}) do
        copiedEntries[#copiedEntries + 1] = {
            resource = methodEntry.resource,
            amount = methodEntry.amount,
        }
    end

    return #copiedEntries > 0 and copiedEntries or nil
end

local function getEnemyReinforcementValue(ctx, card)
    if not ctx or not card or not card.location or card.location.kind ~= "grid" or card.location.rowId ~= "OppRow" then
        return 0
    end

    local cardDefinition = ctx.cardregistry.getCard(card.setName, card.cardId)
    return math.max(0, tonumber(cardDefinition and cardDefinition.rfc) or 0)
end

local function applyEnemyDefeatChampionDamage(ctx, card)
    if not ctx or not card or card.rfcChampionDamageApplied or card.replacedByReinforcement then
        return false
    end

    local reinforcementDamage = getEnemyReinforcementValue(ctx, card)

    if reinforcementDamage <= 0 or not ctx.dealDamageToChampion then
        return false
    end

    card.rfcChampionDamageApplied = true
    ctx.dealDamageToChampion(reinforcementDamage)
    return true
end

local function applyBoomKeywordDamage(ctx, cardIndex, card)
    local state = ctx and ctx.state or nil
    local cardDefinition = ctx and card and ctx.cardregistry.getCard(card.setName, card.cardId) or nil

    if not state
        or not card
        or card.boomKeywordDamageApplied
        or not card.location
        or card.location.kind ~= "grid"
        or not card.location.rowId
        or not ctx.dealDamageToCard
        or not keywordrules.cardHasKeyword(cardDefinition, BOOM_KEYWORD_ID, card) then
        return false
    end

    local boomDamage = math.max(0, tonumber(keywordrules.getCardKeywordValue(card, cardDefinition, BOOM_KEYWORD_ID)) or 0)

    if boomDamage <= 0 then
        return false
    end

    card.boomKeywordDamageApplied = true

    for targetCardIndex, targetCard in ipairs(state.cards or {}) do
        if targetCardIndex ~= cardIndex
            and targetCard
            and targetCard.location
            and targetCard.location.kind == "grid"
            and targetCard.location.rowId == card.location.rowId
            and not cardlifecycle.isCardUnavailable(targetCard) then
            ctx.dealDamageToCard(targetCard, boomDamage)
        end
    end

    return true
end

local function resolveDefeatedCard(ctx, cardIndex, card)
    local state = ctx and ctx.state or nil

    if not state or not card then
        return false
    end

    local attachedKitCards = card.attachedKitCards

    if ctx.haywirerules
        and ctx.addObjectiveProgress
        and state.activePrimaryObjective
        and not card.haywireDamageDefeatProgressApplied then
        local haywireProgress = ctx.haywirerules.getDamageDefeatProgress(ctx, card)

        if haywireProgress > 0 then
            ctx.addObjectiveProgress(state.activePrimaryObjective, haywireProgress)
        end
    end

    card.haywireDefeatedByDamage = nil
    card.haywireDamageDefeatProgressApplied = nil
    cardlifecycle.releaseAttachedKits(ctx, card)
    ctx.resolveDestroyedTroopCard(cardIndex, attachedKitCards)

    ctx.trooprules.notifyPlayerRowUnitDefeated(cardIndex, {
        cards = state.cards,
        cardregistry = ctx.cardregistry,
        isCardUnavailable = function(candidateCard)
            return cardlifecycle.isCardUnavailable(candidateCard)
        end,
        addCardKeywordValue = ctx.addCardKeywordValue,
    })
    return true
end

local function shouldTransformDefeatedAgent(ctx, card)
    local cardDefinition = ctx and card and ctx.cardregistry.getCard(card.setName, card.cardId) or nil

    return cardDefinition
        and cardDefinition.type == "agent"
        and card.location
        and card.location.kind == "grid"
        and card.location.rowId == "PlayerRow"
        or false
end

local function transformDefeatedAgentToIncap(ctx, card, cardIndex)
    local state = ctx and ctx.state or nil
    local incapDefinition = ctx and ctx.cardregistry.getCard(INCAP_SET_NAME, INCAP_CARD_ID) or nil
    local agentSetName = card and card.setName or nil
    local agentCardId = card and card.cardId or nil
    local agentDefinition = ctx and ctx.cardregistry.getCard(agentSetName, agentCardId) or nil

    if not state or not card or not incapDefinition then
        return false
    end

    card.associatedAgent = {
        setName = agentSetName,
        cardId = agentCardId,
        displayName = card.displayName,
        portraitPath = card.portraitPath,
    }
    card.associatedAgentCardId = agentCardId
    card.method = copyMethodEntries(agentDefinition and agentDefinition.method or nil)
    card.setName = INCAP_SET_NAME
    card.cardId = INCAP_CARD_ID
    card.displayName = nil
    card.portraitPath = nil
    card.currentHealth = nil
    card.maxHealth = nil
    card.blocking = nil
    card.keywordValues = nil
    card.passiveGrowthHealthBonus = nil
    card.boomKeywordDamageApplied = nil
    card.dieFaceOverrides = nil
    card.attachedKitCards = nil
    card.attachedPilotCard = nil
    card.destroying = false
    card.destroyed = false
    card.sentToDiscard = nil
    card.destroyElapsed = nil
    card.destroySeed = nil
    card.incapRecoveryAnimation = nil
    card.rfcChampionDamageApplied = nil

    cardinstances.initializeHealth(card)
    ctx.warrules.clearCardRollState(cardIndex)

    state.cardExpansion[cardIndex] = 0
    state.cardEntranceProgress[cardIndex] = 1

    if state.selectedAttackerCardIndex == cardIndex then
        state.selectedAttackerCardIndex = nil
    end

    return true
end

function cardlifecycle.restoreIncapAgentIfRecovered(ctx, card)
    local state = ctx and ctx.state or nil
    local associatedAgent = card and card.associatedAgent or nil
    local agentSetName = associatedAgent and associatedAgent.setName or nil
    local agentCardId = associatedAgent and associatedAgent.cardId or card and card.associatedAgentCardId or nil
    local agentDefinition = ctx and ctx.cardregistry and ctx.cardregistry.getCard(agentSetName or "troops", agentCardId) or nil

    if not state
        or not card
        or not agentDefinition
        or card.setName ~= INCAP_SET_NAME
        or card.cardId ~= INCAP_CARD_ID
        or (tonumber(card.currentHealth) or 0) < (tonumber(card.maxHealth) or 0) then
        return false
    end

    local cardIndex = nil

    for candidateIndex, candidateCard in ipairs(state.cards or {}) do
        if candidateCard == card then
            cardIndex = candidateIndex
            break
        end
    end

    card.setName = agentDefinition.setName or agentSetName or "troops"
    card.cardId = agentDefinition.id
    card.displayName = associatedAgent and associatedAgent.displayName or nil
    card.portraitPath = associatedAgent and associatedAgent.portraitPath or nil
    card.currentHealth = nil
    card.maxHealth = nil
    card.blocking = nil
    card.keywordValues = nil
    card.passiveGrowthHealthBonus = nil
    card.boomKeywordDamageApplied = nil
    card.dieFaceOverrides = nil
    card.method = nil
    card.associatedAgent = nil
    card.associatedAgentCardId = nil
    card.destroying = false
    card.destroyed = false
    card.sentToDiscard = nil
    card.incapRecoveryAnimation = {
        elapsed = 0,
        duration = INCAP_RECOVERY_ANIMATION_DURATION,
        seed = love.math.random() * 1000,
    }

    cardinstances.initializeHealth(card)

    if ctx.warrules and cardIndex then
        ctx.warrules.clearCardRollState(cardIndex)
    end

    if cardIndex then
        state.cardExpansion[cardIndex] = 0
        state.cardEntranceProgress[cardIndex] = 1
    end

    if ctx.sfxrules and ctx.sfxrules.playRestored then
        ctx.sfxrules.playRestored()
    end

    return true
end

function cardlifecycle.isCardDestroyed(card)
    return card and card.destroyed == true
end

function cardlifecycle.isCardUnavailable(card)
    return card == nil
        or card.destroyed == true
        or card.destroying == true
        or card.pilotVehicleAnimation == true
        or card.hunterAutoPlayAnimation == true
end

function cardlifecycle.startCardDestruction(ctx, cardIndex)
    local state = ctx and ctx.state or nil
    local card = state and state.cards[cardIndex] or nil

    if not card or card.destroying or card.destroyed then
        return
    end

    card.destroying = true
    card.destroyElapsed = 0
    card.destroySeed = love.math.random() * 1000
    ctx.warrules.clearCardRollState(cardIndex)
    applyEnemyDefeatChampionDamage(ctx, card)
    applyBoomKeywordDamage(ctx, cardIndex, card)
    ctx.sfxrules.playDestroy()

    if state.selectedAttackerCardIndex == cardIndex then
        state.selectedAttackerCardIndex = nil
    end
end

function cardlifecycle.releaseAttachedKits(ctx, card)
    local state = ctx and ctx.state or nil

    if not card
        or not state
        or not state.playerDeck
        or not card.attachedKitCards
        or #card.attachedKitCards <= 0 then
        return false
    end

    local releasedAny = false
    local remainingAttachedKits = {}

    for _, attachedKit in ipairs(card.attachedKitCards) do
        local returnsToPlayer = attachedKit.deckOwner == "player"
            or card.deckOwner == "player"
            or (
                card.location
                and card.location.kind == "grid"
                and card.location.rowId == "PlayerRow"
            )

        if returnsToPlayer then
            local nextSlotIndex = ctx.getNextOpenHandSlot()
            local kitCard = {
                instanceId = attachedKit.instanceId,
                setName = attachedKit.setName,
                cardId = attachedKit.cardId,
                displayName = attachedKit.displayName,
                portraitPath = attachedKit.portraitPath,
                deckOwner = "player",
            }

            if nextSlotIndex then
                kitCard.location = {
                    kind = "hand",
                    slotIndex = nextSlotIndex,
                }
                state.cards[#state.cards + 1] = kitCard
                state.cardExpansion[#state.cards] = 0
                state.cardEntranceProgress[#state.cards] = 1
                ctx.beginKitReturnAnimation(card, attachedKit, kitCard)
            else
                deckrules.discardCard(state.playerDeck, kitCard)
            end

            releasedAny = true
        else
            remainingAttachedKits[#remainingAttachedKits + 1] = attachedKit
        end
    end

    card.attachedKitCards = #remainingAttachedKits > 0 and remainingAttachedKits or nil
    return releasedAny
end

function cardlifecycle.restoreAttachedPilotToSlot(ctx, cardIndex, vehicleCard)
    local state = ctx and ctx.state or nil
    local attachedPilot = vehicleCard and vehicleCard.attachedPilotCard or nil
    local vehicleDefinition = vehicleCard and ctx.cardregistry.getCard(vehicleCard.setName, vehicleCard.cardId) or nil

    if not state
        or not cardIndex
        or not vehicleCard
        or not attachedPilot
        or not keywordrules.cardHasKeyword(vehicleDefinition, "KWPILOT", vehicleCard)
        or not vehicleCard.location
        or vehicleCard.location.kind ~= "grid" then
        return false
    end

    local pilotCard = {
        instanceId = attachedPilot.instanceId,
        setName = attachedPilot.setName,
        cardId = attachedPilot.cardId,
        deckOwner = attachedPilot.deckOwner or vehicleCard.deckOwner,
        displayName = attachedPilot.displayName,
        portraitPath = attachedPilot.portraitPath,
        currentHealth = attachedPilot.currentHealth,
        maxHealth = attachedPilot.maxHealth,
        keywordValues = attachedPilot.keywordValues,
        dieFaceOverrides = attachedPilot.dieFaceOverrides,
        attachedKitCards = attachedPilot.attachedKitCards,
        location = ctx.copyLocation(vehicleCard.location),
    }

    pilotCard.destroying = false
    pilotCard.destroyed = false
    pilotCard.sentToDiscard = nil
    cardinstances.initializeHealth(pilotCard)
    state.cards[cardIndex] = pilotCard
    state.cardExpansion[cardIndex] = 0
    state.cardEntranceProgress[cardIndex] = 1
    ctx.warrules.clearCardRollState(cardIndex)

    if ctx.turnrules.getCurrentPhase() == "War"
        and ctx.turnrules.getCurrentWarSubphase() == "Engage" then
        local pilotDefinition = ctx.cardregistry.getCard(pilotCard.setName, pilotCard.cardId)

        ctx.warrules.rerollEntity(
            ctx.warrules.getCardEntityKey(cardIndex),
            pilotDefinition,
            pilotCard.location.rowId == "OppRow",
            pilotCard
        )
    end

    return true
end

function cardlifecycle.discardDestroyedCard(ctx, card, cardIndex)
    local state = ctx and ctx.state or nil

    if not state or not card or card.sentToDiscard then
        return nil
    end

    local cardDefinition = ctx.cardregistry.getCard(card.setName, card.cardId)

    if cardDefinition and (cardDefinition.type == "token" or cardDefinition.type == "cache") then
        card.sentToDiscard = true
        cardlifecycle.restoreAttachedPilotToSlot(ctx, cardIndex, card)
        return nil
    end

    if card.deckOwner == "player" and state.playerDeck then
        cardlifecycle.releaseAttachedKits(ctx, card)
        card.sentToDiscard = true
        local discardedCard = deckrules.discardCard(state.playerDeck, card)
        cardlifecycle.restoreAttachedPilotToSlot(ctx, cardIndex, card)
        return discardedCard
    end

    if card.deckOwner == "champion" and state.championDeck then
        card.sentToDiscard = true
        local discardedCard = deckrules.discardCard(state.championDeck, card)
        cardlifecycle.restoreAttachedPilotToSlot(ctx, cardIndex, card)
        return discardedCard
    end

    cardlifecycle.restoreAttachedPilotToSlot(ctx, cardIndex, card)
    return nil
end

function cardlifecycle.removeCardFromPlay(ctx, cardIndex)
    local state = ctx and ctx.state or nil
    local card = state and state.cards[cardIndex] or nil

    if not card then
        return false
    end

    card.destroying = false
    card.destroyed = true
    card.sentToDiscard = true
    ctx.warrules.clearCardRollState(cardIndex)

    if state.selectedAttackerCardIndex == cardIndex then
        state.selectedAttackerCardIndex = nil
    end

    if state.hoveredCardIndex == cardIndex then
        state.hoveredCardIndex = nil
    end

    if state.expandedGridCardIndex == cardIndex then
        state.expandedGridCardIndex = nil
    end

    cardlifecycle.restoreAttachedPilotToSlot(ctx, cardIndex, card)
    return true
end

function cardlifecycle.expireCardFromPlay(ctx, cardIndex)
    local state = ctx and ctx.state or nil
    local card = state and state.cards[cardIndex] or nil

    if not card or card.destroyed or card.sentToDiscard then
        return false
    end

    card.destroying = true
    applyEnemyDefeatChampionDamage(ctx, card)
    applyBoomKeywordDamage(ctx, cardIndex, card)
    resolveDefeatedCard(ctx, cardIndex, card)
    return cardlifecycle.removeCardFromPlay(ctx, cardIndex)
end

function cardlifecycle.discardCardFromPlay(ctx, cardIndex)
    local state = ctx and ctx.state or nil
    local card = state and state.cards[cardIndex] or nil

    if not card then
        return false
    end

    if card.deckOwner == "player" and state.playerDeck then
        cardlifecycle.releaseAttachedKits(ctx, card)
        deckrules.discardCard(state.playerDeck, card)
    elseif card.deckOwner == "champion" and state.championDeck then
        deckrules.discardCard(state.championDeck, card)
    end

    cardlifecycle.removeCardFromPlay(ctx, cardIndex)
    return true
end

function cardlifecycle.updateDestroyedCards(ctx, dt)
    local state = ctx and ctx.state or nil

    if not state then
        return
    end

    for cardIndex, card in ipairs(state.cards) do
        if card.destroying then
            card.destroyElapsed = (card.destroyElapsed or 0) + dt

            if card.destroyElapsed >= ctx.destructionDuration then
                resolveDefeatedCard(ctx, cardIndex, card)

                local transformedToIncap = shouldTransformDefeatedAgent(ctx, card)
                    and transformDefeatedAgentToIncap(ctx, card, cardIndex)

                if not transformedToIncap then
                    card.destroying = false
                    card.destroyed = true
                    cardlifecycle.discardDestroyedCard(ctx, card, cardIndex)
                end
            end
        end
    end
end

function cardlifecycle.updateIncapRecoveryAnimations(ctx, dt)
    local state = ctx and ctx.state or nil

    if not state then
        return
    end

    for _, card in ipairs(state.cards or {}) do
        local animation = card and card.incapRecoveryAnimation or nil

        if animation then
            animation.elapsed = (animation.elapsed or 0) + (dt or 0)

            if animation.elapsed >= (animation.duration or INCAP_RECOVERY_ANIMATION_DURATION) then
                card.incapRecoveryAnimation = nil
            end
        end
    end
end

return cardlifecycle
