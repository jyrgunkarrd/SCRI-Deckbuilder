local cardregistry = require("src.system.cardregistry")
local deckrules = require("src.system.deckrules")
local keywordrules = require("src.system.keywordrules")
local sfxrules = require("src.audio.sfxrules")

local championplayrules = {}

local DEFAULT_PLAY_DELAY = 0.2
local DEFAULT_ENCOUNTER_SPAWN_DELAY = 0.16
local DEFAULT_REINFORCEMENT_HUNTER_ID = "HNTINFFM"
local HUNTER_CARD_TYPE = "hunter"

function championplayrules.createState()
    return {
        pendingPlays = 0,
        delayTimer = 0,
        pendingEncounterSpawns = {},
        encounterSpawnDelayTimer = 0,
    }
end

function championplayrules.resetState(state)
    state.pendingPlays = 0
    state.delayTimer = 0
    state.pendingEncounterSpawns = {}
    state.encounterSpawnDelayTimer = 0
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

local function getEnemyRfc(cardDefinition)
    return math.max(0, tonumber(cardDefinition and cardDefinition.rfc) or 0)
end

local function getCardCurrentHealth(card)
    return math.max(0, tonumber(card and card.currentHealth) or 0)
end

local function getReplacementHunterId(cardDefinition)
    return cardDefinition
        and (cardDefinition.hunterID or cardDefinition.hunterId or cardDefinition.hunterid)
        or DEFAULT_REINFORCEMENT_HUNTER_ID
end

local function discardReplacedCard(ctx, replacedCard, replacedDefinition)
    if not ctx or not replacedCard then
        return nil
    end

    replacedCard.replacedByReinforcement = true
    replacedCard.rfcChampionDamageApplied = true

    if replacedDefinition and replacedDefinition.type == HUNTER_CARD_TYPE and ctx.playerDeck then
        return deckrules.discardCard(ctx.playerDeck, replacedCard)
    end

    if ctx.championDeck then
        return deckrules.discardCard(ctx.championDeck, replacedCard)
    end

    return nil
end

local function beginReinforcementHunterDeckTransformation(ctx, replacedCard, replacedDefinition, hunterId)
    if not ctx or not hunterId then
        return false
    end

    if ctx.beginReinforcementHunterDeckTransformation and replacedCard and replacedCard.location then
        return ctx.beginReinforcementHunterDeckTransformation(
            replacedCard.location,
            replacedDefinition,
            hunterId
        )
    end

    if ctx.beginObjectiveHunterDeckTransformation and ctx.activePrimaryObjective then
        return ctx.beginObjectiveHunterDeckTransformation(ctx.activePrimaryObjective, hunterId)
    end

    return false
end

local function applyReplacementConsequences(ctx, replacedCard, replacedDefinition)
    local replacementRfc = getEnemyRfc(replacedDefinition)

    if replacementRfc <= 0 then
        discardReplacedCard(ctx, replacedCard, replacedDefinition)
        return
    end

    if ctx.addObjectiveProgress and ctx.activePrimaryObjective then
        ctx.addObjectiveProgress(ctx.activePrimaryObjective, replacementRfc, "objective")
    end

    local hunterId = getReplacementHunterId(replacedDefinition)

    for _ = 1, replacementRfc do
        beginReinforcementHunterDeckTransformation(ctx, replacedCard, replacedDefinition, hunterId)
    end

    discardReplacedCard(ctx, replacedCard, replacedDefinition)
end

local function findLowestRfcOppRowEnemy(ctx)
    local lowestCardIndex = nil
    local lowestCard = nil
    local lowestDefinition = nil
    local lowestRfc = nil

    for cardIndex, card in ipairs(ctx.cards or {}) do
        if card
            and card.location
            and card.location.kind == "grid"
            and card.location.rowId == "OppRow"
            and not card.destroyed
            and not card.destroying then
            local cardDefinition = cardregistry.getCard(card.setName, card.cardId)
            local rfc = getEnemyRfc(cardDefinition)

            if lowestRfc == nil
                or rfc < lowestRfc
                or (rfc == lowestRfc and getCardCurrentHealth(card) < getCardCurrentHealth(lowestCard)) then
                lowestCardIndex = cardIndex
                lowestCard = card
                lowestDefinition = cardDefinition
                lowestRfc = rfc
            end
        end
    end

    return lowestCardIndex, lowestCard, lowestDefinition
end

function championplayrules.playHouseCard(ctx)
    local championDeck = ctx.championDeck

    if not championDeck or not championDeck.cards then
        return nil
    end

    if #championDeck.cards == 0 then
        deckrules.resetDeckToInitialState(championDeck)
    end

    if #championDeck.cards == 0 then
        return nil
    end

    local targetColumn = championplayrules.getCenterBiasedOppRowColumn(ctx)
    local replacedCardIndex = nil
    local replacedCard = nil
    local replacedDefinition = nil

    if not targetColumn then
        replacedCardIndex, replacedCard, replacedDefinition = findLowestRfcOppRowEnemy(ctx)

        if not replacedCard or not replacedCard.location then
            return nil
        end

        targetColumn = replacedCard.location.column
    end

    local randomIndex = love.math.random(1, #championDeck.cards)
    local card = table.remove(championDeck.cards, randomIndex)
    local playedCardIndex = replacedCardIndex or (#ctx.cards + 1)

    if replacedCard then
        applyReplacementConsequences(ctx, replacedCard, replacedDefinition)
    end

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

    local playedCardDefinition = cardregistry.getCard(card.setName, card.cardId)

    ctx.cardExpansion[playedCardIndex] = 0
    ctx.cardEntranceProgress[playedCardIndex] = 1

    if replacedCardIndex and ctx.warrules and ctx.warrules.clearCardRollState then
        ctx.warrules.clearCardRollState(replacedCardIndex)
    end

    sfxrules.playUnitPlay()

    return playedCardDefinition, playedCardIndex
end

function championplayrules.queueEnemyEncounterSpawns(state, ctx, sourceCardIndex, enemyDefinition)
    if not state
        or not sourceCardIndex
        or not enemyDefinition
        or not enemyDefinition.encounter
        or not enemyDefinition.encounter.spawns then
        return 0
    end

    state.pendingEncounterSpawns = state.pendingEncounterSpawns or {}
    local queuedCount = 0

    for _, spawnEntry in ipairs(enemyDefinition.encounter.spawns or {}) do
        local enemyId = spawnEntry.enemyId or spawnEntry.cardId or spawnEntry.id
        local count = math.max(0, math.floor(tonumber(spawnEntry.count) or 0))
        local spawnDefinition = enemyId and ctx.cardregistry and ctx.cardregistry.getCardById(enemyId) or nil

        for _ = 1, count do
            if spawnDefinition then
                state.pendingEncounterSpawns[#state.pendingEncounterSpawns + 1] = {
                    sourceCardIndex = sourceCardIndex,
                    cardDefinition = spawnDefinition,
                }
                queuedCount = queuedCount + 1
            end
        end
    end

    if queuedCount > 0 and state.encounterSpawnDelayTimer <= 0 then
        state.encounterSpawnDelayTimer = ctx.encounterSpawnDelay or DEFAULT_ENCOUNTER_SPAWN_DELAY
    end

    return queuedCount
end

function championplayrules.queueKeywordPlays(state, cardDefinition, playDelay)
    local effect = keywordrules.getEnemyChampionPlayEffect(cardDefinition)

    if effect and effect.playAnotherCard then
        state.pendingPlays = state.pendingPlays + 1
        state.delayTimer = playDelay or DEFAULT_PLAY_DELAY
    end
end

function championplayrules.playHouseCardAndQueueKeywords(state, ctx)
    local playedCardDefinition, playedCardIndex = championplayrules.playHouseCard(ctx)

    if playedCardDefinition then
        championplayrules.queueEnemyEncounterSpawns(state, ctx, playedCardIndex, playedCardDefinition)
        championplayrules.queueKeywordPlays(state, playedCardDefinition, ctx.playDelay)
    end

    return playedCardDefinition
end

function championplayrules.updateQueuedEncounterSpawns(state, dt, ctx)
    local pendingEncounterSpawns = state.pendingEncounterSpawns or {}

    if #pendingEncounterSpawns <= 0 then
        state.encounterSpawnDelayTimer = 0
        return false
    end

    state.encounterSpawnDelayTimer = state.encounterSpawnDelayTimer - dt

    if state.encounterSpawnDelayTimer > 0 then
        return false
    end

    local spawn = table.remove(pendingEncounterSpawns, 1)

    if spawn and ctx.spawnTokensNearCard then
        local spawnedCount = ctx.spawnTokensNearCard(spawn.sourceCardIndex, spawn.cardDefinition, 1)

        if spawnedCount > 0 and ctx.sfxrules and ctx.sfxrules.playUnitPlay then
            ctx.sfxrules.playUnitPlay()
        end
    end

    if #pendingEncounterSpawns > 0 then
        state.encounterSpawnDelayTimer = state.encounterSpawnDelayTimer + (ctx.encounterSpawnDelay or DEFAULT_ENCOUNTER_SPAWN_DELAY)
    else
        state.encounterSpawnDelayTimer = 0
    end

    return true
end

function championplayrules.updateQueuedPlays(state, dt, ctx)
    if championplayrules.updateQueuedEncounterSpawns(state, dt, ctx) then
        return true
    end

    if state.pendingEncounterSpawns and #state.pendingEncounterSpawns > 0 then
        return false
    end

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
    return state.pendingPlays == 0
        and state.delayTimer <= 0
        and (not state.pendingEncounterSpawns or #state.pendingEncounterSpawns == 0)
        and state.encounterSpawnDelayTimer <= 0
end

return championplayrules
