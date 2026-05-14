local cardinstances = require("src.system.cardinstances")

local haywirerules = {}

local BASIC_HAYWIRE_ID = "HWBSC"

local function isHaywireDefinition(cardDefinition)
    return cardDefinition and tostring(cardDefinition.type or ""):lower() == "haywire" or false
end

local function getCardDefinition(ctx, card)
    return card and ctx and ctx.cardregistry and ctx.cardregistry.getCard(card.setName, card.cardId) or nil
end

local function getEmphasis(cardDefinition)
    return math.max(0, tonumber(cardDefinition and cardDefinition.emphasis) or 0)
end

function haywirerules.isHaywireCard(ctx, card)
    return isHaywireDefinition(getCardDefinition(ctx, card))
end

function haywirerules.getHandEmphasis(ctx)
    local totalEmphasis = 0

    for _, card in ipairs(ctx and ctx.state and ctx.state.cards or {}) do
        if card
            and card.location
            and card.location.kind == "hand"
            and not card.destroyed
            and not card.destroying then
            totalEmphasis = totalEmphasis + getEmphasis(getCardDefinition(ctx, card))
        end
    end

    return totalEmphasis
end

function haywirerules.getObjectiveProgressBonus(ctx, baseProgressAmount)
    if math.max(0, tonumber(baseProgressAmount) or 0) <= 0 then
        return 0
    end

    return haywirerules.getHandEmphasis(ctx)
end

function haywirerules.getDamageDefeatProgress(ctx, card)
    if not card or card.haywireDefeatedByDamage ~= true then
        return 0
    end

    return getEmphasis(getCardDefinition(ctx, card))
end

function haywirerules.shouldCreateEndPhaseHaywire(ctx)
    local systems = ctx and ctx.state and ctx.state.missionSystems or nil

    return ctx
        and ctx.systemrules
        and systems
        and ctx.systemrules.getFreshSystemCount(systems) <= 0
        or false
end

function haywirerules.createBasicHaywireInPlayerDeck(ctx)
    if not ctx or not ctx.state or not ctx.state.playerDeck or not ctx.cardregistry then
        return nil
    end

    local cardDefinition = ctx.cardregistry.getCardById(BASIC_HAYWIRE_ID)
    local generatedCard = cardinstances.createGeneratedDeckCardShuffled(ctx.state.playerDeck, cardDefinition)

    if generatedCard and ctx.beginHaywireDeckAddAnimation then
        ctx.beginHaywireDeckAddAnimation(generatedCard)
    end

    return generatedCard
end

function haywirerules.resolveEndPhaseSystemBurn(ctx)
    if not haywirerules.shouldCreateEndPhaseHaywire(ctx) then
        return false
    end

    return haywirerules.createBasicHaywireInPlayerDeck(ctx) ~= nil
end

return haywirerules
