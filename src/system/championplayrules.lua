local cardregistry = require("src.system.cardregistry")
local deckrules = require("src.system.deckrules")
local keywordrules = require("src.system.keywordrules")
local sfxrules = require("src.audio.sfxrules")

local championplayrules = {}

local DEFAULT_PLAY_DELAY = 0.2

function championplayrules.createState()
    return {
        pendingPlays = 0,
        delayTimer = 0,
    }
end

function championplayrules.resetState(state)
    state.pendingPlays = 0
    state.delayTimer = 0
end

function championplayrules.getCenterBiasedOppRowColumn(ctx)
    local oppRow = ctx.getOppRow()

    if not oppRow then
        return nil
    end

    local center = (#oppRow.cells + 1) / 2
    local bestColumn = nil
    local bestDistance = nil

    for _, cell in ipairs(oppRow.cells) do
        if not ctx.isGridRowColumnOccupied("OppRow", cell.column) then
            local distance = math.abs(cell.column - center)

            if bestDistance == nil
                or distance < bestDistance
                or (distance == bestDistance and cell.column > bestColumn) then
                bestColumn = cell.column
                bestDistance = distance
            end
        end
    end

    return bestColumn
end

function championplayrules.playHouseCard(ctx)
    local championDeck = ctx.championDeck

    if not championDeck or not championDeck.cards then
        return nil
    end

    if #championDeck.cards == 0 then
        deckrules.reshuffleDiscardIntoDeck(championDeck)
    end

    if #championDeck.cards == 0 then
        return nil
    end

    local targetColumn = championplayrules.getCenterBiasedOppRowColumn(ctx)

    if not targetColumn then
        return nil
    end

    local randomIndex = love.math.random(1, #championDeck.cards)
    local card = table.remove(championDeck.cards, randomIndex)
    local playedCardIndex = #ctx.cards + 1

    ctx.cards[playedCardIndex] = {
        instanceId = card.instanceId,
        setName = card.setName,
        cardId = card.cardId,
        displayName = card.displayName,
        portraitPath = card.portraitPath,
        deckOwner = card.deckOwner,
        location = {
            kind = "grid",
            rowId = "OppRow",
            column = targetColumn,
        },
    }
    ctx.initializeCardHealthState(ctx.cards[playedCardIndex])
    ctx.cardExpansion[playedCardIndex] = 0
    ctx.cardEntranceProgress[playedCardIndex] = 1
    sfxrules.playUnitPlay()

    return cardregistry.getCard(card.setName, card.cardId)
end

function championplayrules.queueKeywordPlays(state, cardDefinition, playDelay)
    local effect = keywordrules.getEnemyChampionPlayEffect(cardDefinition)

    if effect and effect.playAnotherCard then
        state.pendingPlays = state.pendingPlays + 1
        state.delayTimer = playDelay or DEFAULT_PLAY_DELAY
    end
end

function championplayrules.playHouseCardAndQueueKeywords(state, ctx)
    local playedCardDefinition = championplayrules.playHouseCard(ctx)

    if playedCardDefinition then
        championplayrules.queueKeywordPlays(state, playedCardDefinition, ctx.playDelay)
    end

    return playedCardDefinition
end

function championplayrules.updateQueuedPlays(state, dt, ctx)
    if state.pendingPlays <= 0 then
        return false
    end

    state.delayTimer = state.delayTimer - dt

    if state.delayTimer > 0 then
        return false
    end

    state.pendingPlays = state.pendingPlays - 1
    championplayrules.playHouseCardAndQueueKeywords(state, ctx)

    if state.pendingPlays > 0 then
        state.delayTimer = state.delayTimer + (ctx.playDelay or DEFAULT_PLAY_DELAY)
    else
        state.delayTimer = 0
    end

    return true
end

function championplayrules.isSequenceComplete(state)
    return state.pendingPlays == 0 and state.delayTimer <= 0
end

return championplayrules
