local GROWTH_KEYWORD_ID = "KWGRO"

local function getBlockValue(card)
    return math.max(0, tonumber(card and card.blocking) or 0)
end

local function getPassiveKeywordIds(card)
    if getBlockValue(card) <= 0 then
        return {}
    end

    return { GROWTH_KEYWORD_ID }
end

local function getPassiveKeywordValue(card, definition, keywordId)
    if keywordId ~= GROWTH_KEYWORD_ID then
        return nil
    end

    local blockValue = getBlockValue(card)

    return blockValue > 0 and blockValue or nil
end

return {
    getPassiveKeywordIds = getPassiveKeywordIds,
    getPassiveKeywordValue = getPassiveKeywordValue,
}
