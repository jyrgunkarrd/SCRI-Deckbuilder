local temporaryeffects = require("src.system.temporaryeffects")

local function onStrategistExhaust(cardIndex, context)
    local cards = context and context.cards or {}
    local sourceCard = cards[cardIndex]
    if not sourceCard or not sourceCard.location or sourceCard.location.kind ~= "grid" then return end

    local column = sourceCard.location.column

    -- Apply to self
    temporaryeffects.addCardKeyword(sourceCard, "KWFLY")

    -- Apply to adjacent in the PlayerRow
    for _, card in ipairs(cards) do
        if card.location and card.location.kind == "grid" and card.location.rowId == "PlayerRow" then
            if card.location.column == column - 1 or card.location.column == column + 1 then
                temporaryeffects.addCardKeyword(card, "KWFLY")
            end
        end
    end
end

return {
    onStrategistExhaust = onStrategistExhaust
}
