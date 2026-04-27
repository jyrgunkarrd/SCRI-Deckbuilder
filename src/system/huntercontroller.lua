local huntercontroller = {}

local HUNTER_TYPE = "hunter"
local DEFAULT_INTEL_ID = "INT0000"

function huntercontroller.getRandomChampionIntel(championDefinition, objectiverules)
    if not championDefinition or not championDefinition.intelDeck then
        return nil
    end

    local availableIntelIds = {}

    for _, intelEntry in ipairs(championDefinition.intelDeck) do
        for _ = 1, (intelEntry.quantity or 0) do
            availableIntelIds[#availableIntelIds + 1] = intelEntry.cardId
        end
    end

    if #availableIntelIds == 0 then
        return nil
    end

    local intelId = availableIntelIds[love.math.random(1, #availableIntelIds)]
    return objectiverules.getObjective(intelId)
end

function huntercontroller.getReplacementIntel(ctx, defeatedIntel)
    if not defeatedIntel then
        return nil
    end

    if defeatedIntel.id == DEFAULT_INTEL_ID then
        return huntercontroller.getRandomChampionIntel(ctx.state.activeChampion, ctx.objectiverules)
    end

    return ctx.objectiverules.getObjective(DEFAULT_INTEL_ID)
end

function huntercontroller.isHunterCardDefinition(cardDefinition)
    return cardDefinition and cardDefinition.type == HUNTER_TYPE or false
end

function huntercontroller.isHunterCard(ctx, card)
    if not card then
        return false
    end

    local cardDefinition = ctx.cardregistry.getCard(card.setName, card.cardId)
    return huntercontroller.isHunterCardDefinition(cardDefinition)
end

function huntercontroller.getHunterEmphasisInHand(ctx)
    local totalEmphasis = 0

    for _, card in ipairs(ctx.state.cards or {}) do
        if card
            and card.location
            and card.location.kind == "hand"
            and not ctx.isCardDestroyed(card) then
            local cardDefinition = ctx.cardregistry.getCard(card.setName, card.cardId)

            if huntercontroller.isHunterCardDefinition(cardDefinition) then
                totalEmphasis = totalEmphasis + math.max(0, tonumber(cardDefinition.emphasis) or 0)
            end
        end
    end

    return totalEmphasis
end

function huntercontroller.getEndPhaseObjectiveProgress(state)
    return state.activePrimaryObjective and state.activePrimaryObjective.emphasis or 0
end

function huntercontroller.getRetaliationPhaseObjectiveProgress(ctx)
    return huntercontroller.getHunterEmphasisInHand(ctx)
end

function huntercontroller.playHunterAddedSfxForCard(ctx, card)
    if huntercontroller.isHunterCard(ctx, card) then
        ctx.sfxrules.playHunt()
    end
end

function huntercontroller.playHunterAddedSfxForCardDefinition(ctx, cardDefinition)
    if huntercontroller.isHunterCardDefinition(cardDefinition) then
        ctx.sfxrules.playHunt()
    end
end

function huntercontroller.playHunterAddedSfxForCards(ctx, cards)
    for _, card in ipairs(cards or {}) do
        huntercontroller.playHunterAddedSfxForCard(ctx, card)
    end
end

return huntercontroller
