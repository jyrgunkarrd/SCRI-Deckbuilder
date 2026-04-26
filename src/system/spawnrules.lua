local cardinstances = require("src.system.cardinstances")
local cardzones = require("src.system.cardzones")

local spawnrules = {}

local function getCards(ctx)
    return ctx and ctx.cards or nil
end

local function createGeneratedGridCard(ctx, cardDefinition, rowId, column)
    if not ctx then
        return nil
    end

    local generatedCard = cardinstances.createGeneratedGridCard(
        ctx.cards,
        ctx.cardExpansion,
        ctx.cardEntranceProgress,
        cardDefinition,
        rowId,
        column
    )

    if generatedCard
        and ctx.turnrules
        and ctx.warrules
        and ctx.turnrules.getCurrentPhase() == "War"
        and ctx.turnrules.getCurrentWarSubphase() == "Engage" then
        local generatedCardIndex = #ctx.cards

        ctx.warrules.rerollEntity(
            ctx.warrules.getCardEntityKey(generatedCardIndex),
            cardDefinition,
            rowId == "OppRow"
        )
    end

    return generatedCard
end

function spawnrules.createGeneratedSupportCard(ctx, cardDefinition, targetLocation)
    if not ctx then
        return nil
    end

    local generatedCard = cardinstances.createGeneratedSupportCard(
        ctx.cards,
        ctx.cardExpansion,
        ctx.cardEntranceProgress,
        ctx.playerDeck,
        cardDefinition,
        targetLocation
    )

    if generatedCard
        and targetLocation
        and (targetLocation.kind == "hand" or targetLocation.kind == "deck")
        and ctx.playHunterAddedSfxForCardDefinition then
        ctx.playHunterAddedSfxForCardDefinition(cardDefinition)
    end

    return generatedCard
end

function spawnrules.createGeneratedDeckCardShuffled(ctx, cardDefinition)
    local generatedCard = ctx and cardinstances.createGeneratedDeckCardShuffled(ctx.playerDeck, cardDefinition) or nil

    if generatedCard and ctx.playHunterAddedSfxForCardDefinition then
        ctx.playHunterAddedSfxForCardDefinition(cardDefinition)
    end

    return generatedCard
end

function spawnrules.createGeneratedGridCard(ctx, cardDefinition, rowId, column)
    return createGeneratedGridCard(ctx, cardDefinition, rowId, column)
end

function spawnrules.getClosestOpenGridColumns(ctx, rowId, anchorColumn, ignoredCardIndex, preferredColumn)
    local row = ctx and ctx.envdraw and rowId and ctx.envdraw.getGridRow(rowId) or nil
    local columns = {}
    local preferredIsOpen = false

    if not row or not anchorColumn then
        return columns
    end

    for _, cell in ipairs(row.cells or {}) do
        local column = cell.column

        if column and not cardzones.isGridRowColumnOccupied(getCards(ctx), rowId, column, ignoredCardIndex) then
            if preferredColumn and column == preferredColumn then
                preferredIsOpen = true
            else
                columns[#columns + 1] = column
            end
        end
    end

    table.sort(columns, function(a, b)
        local distanceA = math.abs(a - anchorColumn)
        local distanceB = math.abs(b - anchorColumn)

        if distanceA == distanceB then
            return a < b
        end

        return distanceA < distanceB
    end)

    if preferredIsOpen then
        table.insert(columns, 1, preferredColumn)
    end

    return columns
end

function spawnrules.spawnTokensNearCard(ctx, sourceCardIndex, tokenDefinition, count, options)
    local sourceCard = sourceCardIndex and getCards(ctx) and ctx.cards[sourceCardIndex] or nil

    if not sourceCard
        or not sourceCard.location
        or sourceCard.location.kind ~= "grid"
        or not tokenDefinition
        or (count or 0) <= 0 then
        return 0
    end

    local spawnedCount = 0
    local rowId = sourceCard.location.rowId
    local preferredColumn = options and options.preferredColumn or nil
    local ignoredCardIndex = options and options.ignoredCardIndex or nil
    local openColumns = spawnrules.getClosestOpenGridColumns(ctx, rowId, sourceCard.location.column, ignoredCardIndex, preferredColumn)

    for _, column in ipairs(openColumns) do
        if spawnedCount >= count then
            break
        end

        if createGeneratedGridCard(ctx, tokenDefinition, rowId, column) then
            spawnedCount = spawnedCount + 1
        end
    end

    return spawnedCount
end

function spawnrules.spawnRandomTokensNearCard(ctx, sourceCardIndex, tokenDefinitions, count, options)
    local sourceCard = sourceCardIndex and getCards(ctx) and ctx.cards[sourceCardIndex] or nil

    if not sourceCard
        or not sourceCard.location
        or sourceCard.location.kind ~= "grid"
        or not tokenDefinitions
        or #tokenDefinitions <= 0
        or (count or 0) <= 0 then
        return 0
    end

    local spawnedCount = 0
    local rowId = sourceCard.location.rowId
    local preferredColumn = options and options.preferredColumn or nil
    local ignoredCardIndex = options and options.ignoredCardIndex or nil
    local openColumns = spawnrules.getClosestOpenGridColumns(ctx, rowId, sourceCard.location.column, ignoredCardIndex, preferredColumn)

    for _, column in ipairs(openColumns) do
        if spawnedCount >= count then
            break
        end

        local tokenDefinition = tokenDefinitions[love.math.random(1, #tokenDefinitions)]

        if createGeneratedGridCard(ctx, tokenDefinition, rowId, column) then
            spawnedCount = spawnedCount + 1
        end
    end

    return spawnedCount
end

function spawnrules.spawnTokensNearPlayerCard(ctx, sourceCardIndex, tokenDefinition, count, options)
    local sourceCard = sourceCardIndex and getCards(ctx) and ctx.cards[sourceCardIndex] or nil

    if not sourceCard
        or not sourceCard.location
        or sourceCard.location.kind ~= "grid"
        or not tokenDefinition
        or (count or 0) <= 0 then
        return 0
    end

    local spawnedCount = 0
    local preferredColumn = options and options.preferredColumn or nil
    local ignoredCardIndex = options and options.ignoredCardIndex or nil
    local openColumns = spawnrules.getClosestOpenGridColumns(ctx, "PlayerRow", sourceCard.location.column, ignoredCardIndex, preferredColumn)

    for _, column in ipairs(openColumns) do
        if spawnedCount >= count then
            break
        end

        if createGeneratedGridCard(ctx, tokenDefinition, "PlayerRow", column) then
            spawnedCount = spawnedCount + 1
        end
    end

    return spawnedCount
end

function spawnrules.findPlayerCacheCard(ctx, cacheCardId)
    for cardIndex, card in ipairs(getCards(ctx) or {}) do
        if card
            and not ctx.isCardUnavailable(card)
            and card.location
            and card.location.kind == "grid"
            and card.location.rowId == "PlayerRow"
            and card.cardId == cacheCardId then
            return cardIndex, card
        end
    end

    return nil, nil
end

function spawnrules.createOrStackPlayerCacheNearCard(ctx, sourceCardIndex, cacheDefinition, count)
    local sourceCard = sourceCardIndex and getCards(ctx) and ctx.cards[sourceCardIndex] or nil
    local stackCount = math.max(0, math.floor(tonumber(count) or 0))

    if not sourceCard
        or not sourceCard.location
        or sourceCard.location.kind ~= "grid"
        or not cacheDefinition
        or stackCount <= 0 then
        return 0
    end

    local _, existingCache = spawnrules.findPlayerCacheCard(ctx, cacheDefinition.id)

    if existingCache then
        existingCache.currentHealth = math.max(0, tonumber(existingCache.currentHealth) or 0) + stackCount
        existingCache.maxHealth = math.max(existingCache.currentHealth, math.max(0, tonumber(existingCache.maxHealth) or 0))
        return stackCount
    end

    local spawnedCache = nil
    local openColumns = spawnrules.getClosestOpenGridColumns(ctx, "PlayerRow", sourceCard.location.column)

    for _, column in ipairs(openColumns) do
        spawnedCache = createGeneratedGridCard(ctx, cacheDefinition, "PlayerRow", column)

        if spawnedCache then
            spawnedCache.currentHealth = stackCount
            spawnedCache.maxHealth = stackCount
            break
        end
    end

    return spawnedCache and stackCount or 0
end

return spawnrules
