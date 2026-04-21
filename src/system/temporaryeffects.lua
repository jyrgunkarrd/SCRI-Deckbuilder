local temporaryeffects = {}

local effects = {}

function temporaryeffects.reset()
    effects = {}
end

function temporaryeffects.addEndPhaseEffect(effect)
    if type(effect) ~= "table" then
        return nil
    end

    effects[#effects + 1] = effect
    return effect
end

function temporaryeffects.addCardKeyword(card, keywordId)
    if not card then return end
    card.tempKeywords = card.tempKeywords or {}
    card.tempKeywords[keywordId] = true

    return temporaryeffects.addEndPhaseEffect({
        kind = "card_keyword",
        card = card,
        keywordId = keywordId
    })
end

function temporaryeffects.clearAllEndPhaseEffects()
    for _, effect in ipairs(effects) do
        if effect.kind == "card_keyword" then
            if effect.card and effect.card.tempKeywords then
                effect.card.tempKeywords[effect.keywordId] = nil
            end
        elseif type(effect.cleanup) == "function" then
            effect.cleanup(effect)
        end
    end
    effects = {}
end

function temporaryeffects.hasTemporaryKeyword(card, keywordId)
    return card and card.tempKeywords and card.tempKeywords[keywordId] == true
end

return temporaryeffects
