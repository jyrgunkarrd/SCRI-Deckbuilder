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

function temporaryeffects.addCardKeyword(card, keywordId, keywordValue)
    if not card then return end
    card.tempKeywords = card.tempKeywords or {}
    card.tempKeywords[keywordId] = (tonumber(card.tempKeywords[keywordId]) or 0) + 1

    if keywordValue ~= nil then
        card.tempKeywordValues = card.tempKeywordValues or {}
        card.tempKeywordValues[keywordId] = (tonumber(card.tempKeywordValues[keywordId]) or 0) + (tonumber(keywordValue) or 0)
    end

    return temporaryeffects.addEndPhaseEffect({
        kind = "card_keyword",
        card = card,
        keywordId = keywordId,
        keywordValue = keywordValue,
    })
end

function temporaryeffects.clearAllEndPhaseEffects()
    for _, effect in ipairs(effects) do
        if effect.kind == "card_keyword" then
            if effect.card and effect.card.tempKeywords then
                local currentKeywordCount = math.max(0, tonumber(effect.card.tempKeywords[effect.keywordId]) or 0) - 1

                if currentKeywordCount > 0 then
                    effect.card.tempKeywords[effect.keywordId] = currentKeywordCount
                else
                    effect.card.tempKeywords[effect.keywordId] = nil
                end
            end

            if effect.keywordValue ~= nil and effect.card and effect.card.tempKeywordValues then
                local currentKeywordValue = (tonumber(effect.card.tempKeywordValues[effect.keywordId]) or 0) - (tonumber(effect.keywordValue) or 0)

                if currentKeywordValue > 0 then
                    effect.card.tempKeywordValues[effect.keywordId] = currentKeywordValue
                else
                    effect.card.tempKeywordValues[effect.keywordId] = nil
                end
            end
        elseif type(effect.cleanup) == "function" then
            effect.cleanup(effect)
        end
    end
    effects = {}
end

function temporaryeffects.hasTemporaryKeyword(card, keywordId)
    return card and card.tempKeywords and (tonumber(card.tempKeywords[keywordId]) or 0) > 0
end

function temporaryeffects.getTemporaryKeywordValue(card, keywordId)
    if not card or not keywordId or not temporaryeffects.hasTemporaryKeyword(card, keywordId) then
        return nil
    end

    return tonumber(card.tempKeywordValues and card.tempKeywordValues[keywordId]) or 0
end

return temporaryeffects
