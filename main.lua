local envdraw = require("src.render.envdraw")
local carddraw = require("src.render.carddraw")
local cardpresentation = require("src.render.cardpresentation")
local infiltrationdraw = require("src.render.infiltrationdraw")
local sfxrules = require("src.audio.sfxrules")
local cardregistry = require("src.system.cardregistry")
local cardinstances = require("src.system.cardinstances")
local cardzones = require("src.system.cardzones")
local championplayrules = require("src.system.championplayrules")
local championrules = require("src.system.championrules")
local engagerules = require("src.system.engagerules")
local envrules = require("src.system.envrules")
local notifications = require("src.system.notifications")
local objectiverules = require("src.system.objectiverules")
local objectiveprogressrules = require("src.system.objectiveprogressrules")
local phasecontroller = require("src.system.phasecontroller")
local turnrules = require("src.system.turnrules")
local warzonerules = require("src.system.warzonerules")
local warzonecontrolrules = require("src.system.warzonecontrolrules")
local topsloteffects = require("src.system.topsloteffects")
local deckrules = require("src.system.deckrules")
local damagerules = require("src.system.damagerules")
local jaclrules = require("src.system.jaclrules")
local keywordrules = require("src.system.keywordrules")
local resourcerules = require("src.system.resourcerules")
local specialrules = require("src.system.specialrules")
local infiltrationrules = require("src.system.infiltrationrules")
local strategyrules = require("src.system.strategyrules")
local tomerules = require("src.system.tomerules")
local targetoverlays = require("src.render.targetoverlays")
local gamestatedraw = require("src.render.gamestate_draw")
local inputcontroller = require("src.ui.inputcontroller")
local modals = require("src.ui.modals")
local warrules = require("src.system.warrules")

local CARD_HOVER_ANIMATION_SPEED = 10
local CARD_ENTRANCE_SPEED = 6
local CARD_ENTRANCE_STAGGER = 0.1
local CARD_ENTRANCE_MAX_DT = 1 / 60
local DAMAGE_JITTER_DURATION = 0.28
local DAMAGE_JITTER_MAGNITUDE = 7
local DESTRUCTION_DURATION = 0.6
local PLAYER_JACL_ID = "JACL001"
local ACTIVE_CHAMPION_ID = "CH0001"
local ACTIVE_WARZONE_ID = "WZ0001"
local RANDOM_WARZONE_SUFFIX = "B"
local ACTIVE_POI_ID = "POI0001"
local ACTIVE_PRIMARY_OBJECTIVE_ID = "PRIMOBJ0001"

local gameState = {
    playerJacl = nil,
    activeChampion = nil,
    activeWarzone = nil,
    activePoi = nil,
    activePrimaryObjective = nil,
    activeIntel = nil,
    playerDeck = nil,
    championDeck = nil,
    cards = {},

    hoveredCardIndex = nil,
    hoveredTopSlotId = nil,
    hoveredKeyword = nil,
    expandedGridCardIndex = nil,
    expandedTopSlotId = nil,
    selectedAttackerCardIndex = nil,
    draggedCardIndex = nil,
    draggedCardOrigin = nil,
    dragOffsetX = 0,
    dragOffsetY = 0,
    cardEntranceTimer = 0,
    cardExpansion = {},
    cardEntranceProgress = {},
    topSlotExpansion = {},
    damageJitters = {},
    waitingForStartGeneration = false,
    championPlayState = championplayrules.createState(),
    engageRerollCount = 2,
    syntacCount = 0,
    isResourceExchangeModalOpen = false,
    isJaclDeckModalOpen = false,
    jaclDeckModalScroll = {
        deck = 0,
        discard = 0,
    },
    jaclDeckPreviewCard = nil,
    activeDeckModalDeck = nil,
    primedJaclSpecial = nil,
    fullArtImage = nil,
    hoveredJaclSpecialDefinition = nil,
    hoveredJaclSpecialPreviewCard = nil,
    hoveredTomeSpawnPreviewCard = nil,
    hasRenderedFirstFrame = false,
    pendingPhaseEntry = false,
    pendingSetupCompletion = false,
}
local getCardDrawPosition
local isGridRowColumnOccupied
local isWarRollSourceActive
local getTargetingContext
local getTopSlotRollTargets
local initializeCardHealthState
local initializeCardsHealthState
local dealDamageToCard
local dealDamageToChampion
local addBlockingToCard
local clearAllBlocking
local beginInfiltrationEffect
local getNextOpenHandSlot
local preloadWarzoneFamily
local updateInfiltrationEffect
local playHunterAddedSfxForCard
local playHunterAddedSfxForCardDefinition
local playHunterAddedSfxForCards
local isPointInsideJaclPortrait
local function getDamageJitterKeyForCard(cardIndex)
    return "card:" .. tostring(cardIndex)
end

local function isCardDestroyed(card)
    return card and card.destroyed == true
end

local function isCardUnavailable(card)
    return card == nil or card.destroyed == true or card.destroying == true
end

local function startCardDestruction(cardIndex)
    local card = gameState.cards[cardIndex]

    if not card or card.destroying or card.destroyed then
        return
    end

    card.destroying = true
    card.destroyElapsed = 0
    card.destroySeed = love.math.random() * 1000
    warrules.clearCardRollState(cardIndex)
    sfxrules.playDestroy()

    if gameState.selectedAttackerCardIndex == cardIndex then
        gameState.selectedAttackerCardIndex = nil
    end
end

local function startChampionDestruction()
    topsloteffects.startChampionDestruction(gameState.activeChampion)
end

local function startIntelDestruction()
    topsloteffects.startIntelDestruction(gameState.activeIntel)
end

local function triggerDamageFeedback(entityKey)
    if not entityKey then
        return
    end

    gameState.damageJitters[entityKey] = {
        elapsed = 0,
        duration = DAMAGE_JITTER_DURATION,
        magnitude = DAMAGE_JITTER_MAGNITUDE,
    }
    sfxrules.playDamage()
end

local function getDamageJitterOffset(entityKey)
    local jitter = gameState.damageJitters[entityKey]

    if not jitter then
        return 0, 0
    end

    local remainingRatio = math.max(0, 1 - (jitter.elapsed / jitter.duration))
    local amplitude = jitter.magnitude * remainingRatio
    local offsetX = math.sin(jitter.elapsed * 90) * amplitude
    local offsetY = math.cos(jitter.elapsed * 72) * amplitude * 0.5

    return offsetX, offsetY
end

local function getObjectiveProgressJitterOffset()
    return topsloteffects.getObjectiveProgressJitterOffset()
end

local function getObjectiveProgressEffectSlotId()
    return topsloteffects.getObjectiveProgressEffectSlotId()
end

local function beginObjectiveEscalation(objectiveDefinition, escalationId)
    return topsloteffects.beginObjectiveEscalation(objectiveDefinition, escalationId, envdraw.preloadTopStripAssets)
end

local function beginWarzoneTransformation(sourceWarzone, targetWarzone)
    return topsloteffects.beginWarzoneTransformation(sourceWarzone, targetWarzone, envdraw.preloadTopStripAssets)
end

local function beginPoiEmergenceEffect()
    topsloteffects.beginPoiEmergence()
end

local function beginPoiFlipEffect(sourcePoi, targetPoi)
    return topsloteffects.beginPoiFlip(sourcePoi, targetPoi, envdraw.preloadTopStripAssets)
end

local function beginPoiGeneratedCardTransformation(poiDefinition, generatedCardId)
    return topsloteffects.beginPoiGeneratedCardTransformation(poiDefinition, generatedCardId, getNextOpenHandSlot)
end

local function copyLocation(location)
    return cardinstances.copyLocation(location)
end

local function getPlayerHandLayout()
    return envdraw.getPlayerHandLayout()
end

local function getPlayerRow()
    return envdraw.getGridRow("PlayerRow")
end

local function getOppRow()
    return envdraw.getGridRow("OppRow")
end

local function isSetupCard(card)
    return cardzones.isSetupCard(card)
end

local function isGridCard(card)
    return cardzones.isGridCard(card)
end

local function canExpandCard(card)
    return cardzones.canExpandCard(card)
end

local function getHoveredTopSlotId(mouseX, mouseY)
    return envdraw.getTopSlotHit(
        mouseX,
        mouseY,
        turnrules.getCurrentPhase(),
        gameState.activeChampion,
        gameState.activeWarzone,
        gameState.activePoi,
        gameState.activePrimaryObjective,
        gameState.activeIntel
    )
end

local function getSetupCardCount()
    return cardzones.getSetupCardCount(gameState.cards, isCardDestroyed)
end

local function addSetupAgents()
    local setupAgentIds = {
        "AGT0001",
        "AGT0002",
    }

    for slotIndex, cardId in ipairs(setupAgentIds) do
        local cardDefinition = cardregistry.getCard("troops", cardId)

        gameState.cards[#gameState.cards + 1] = cardinstances.create(
            cardDefinition,
            "setup:" .. cardId .. ":" .. tostring(slotIndex),
            {
                kind = "setup",
                slotIndex = slotIndex,
            },
            "player"
        )

        initializeCardHealthState(gameState.cards[#gameState.cards])

        if cardId == "AGT0001" then
            dealDamageToCard(gameState.cards[#gameState.cards], 2, true)
        end
    end
end

local function normalizeSetupCardSlots()
    cardzones.normalizeSetupCardSlots(gameState.cards, isCardDestroyed)
end

local function normalizeHandCardSlots()
    cardzones.normalizeHandCardSlots(gameState.cards, isCardDestroyed)
end

getNextOpenHandSlot = function()
    return cardzones.getNextOpenHandSlot(gameState.cards, envrules.getPlayerHand().slots, isCardDestroyed)
end

local function createGeneratedSupportCard(cardDefinition, targetLocation)
    local generatedCard = cardinstances.createGeneratedSupportCard(gameState.cards, gameState.cardExpansion, gameState.cardEntranceProgress, gameState.playerDeck, cardDefinition, targetLocation)

    if generatedCard and (targetLocation.kind == "hand" or targetLocation.kind == "deck") then
        playHunterAddedSfxForCardDefinition(cardDefinition)
    end

    return generatedCard
end

local function createGeneratedDeckCardShuffled(cardDefinition)
    local generatedCard = cardinstances.createGeneratedDeckCardShuffled(gameState.playerDeck, cardDefinition)

    if generatedCard then
        playHunterAddedSfxForCardDefinition(cardDefinition)
    end

    return generatedCard
end

local function createGeneratedGridCard(cardDefinition, rowId, column)
    local generatedCard = cardinstances.createGeneratedGridCard(gameState.cards, gameState.cardExpansion, gameState.cardEntranceProgress, cardDefinition, rowId, column)

    if generatedCard
        and turnrules.getCurrentPhase() == "War"
        and turnrules.getCurrentWarSubphase() == "Engage" then
        local generatedCardIndex = #gameState.cards

        warrules.rerollEntity(
            warrules.getCardEntityKey(generatedCardIndex),
            cardDefinition,
            rowId == "OppRow"
        )
    end

    return generatedCard
end

local function getClosestOpenGridColumns(rowId, anchorColumn)
    local row = rowId and envdraw.getGridRow(rowId) or nil
    local columns = {}

    if not row or not anchorColumn then
        return columns
    end

    for _, cell in ipairs(row.cells or {}) do
        local column = cell.column

        if column and not cardzones.isGridRowColumnOccupied(gameState.cards, rowId, column) then
            columns[#columns + 1] = column
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

    return columns
end

local function spawnTokensNearCard(sourceCardIndex, tokenDefinition, count)
    local sourceCard = sourceCardIndex and gameState.cards[sourceCardIndex] or nil

    if not sourceCard
        or not sourceCard.location
        or sourceCard.location.kind ~= "grid"
        or not tokenDefinition
        or (count or 0) <= 0 then
        return 0
    end

    local spawnedCount = 0
    local rowId = sourceCard.location.rowId
    local openColumns = getClosestOpenGridColumns(rowId, sourceCard.location.column)

    for _, column in ipairs(openColumns) do
        if spawnedCount >= count then
            break
        end

        if createGeneratedGridCard(tokenDefinition, rowId, column) then
            spawnedCount = spawnedCount + 1
        end
    end

    return spawnedCount
end

local function spawnTokensNearPlayerCard(sourceCardIndex, tokenDefinition, count)
    local sourceCard = sourceCardIndex and gameState.cards[sourceCardIndex] or nil

    if not sourceCard
        or not sourceCard.location
        or sourceCard.location.kind ~= "grid"
        or not tokenDefinition
        or (count or 0) <= 0 then
        return 0
    end

    local spawnedCount = 0
    local openColumns = getClosestOpenGridColumns("PlayerRow", sourceCard.location.column)

    for _, column in ipairs(openColumns) do
        if spawnedCount >= count then
            break
        end

        if createGeneratedGridCard(tokenDefinition, "PlayerRow", column) then
            spawnedCount = spawnedCount + 1
        end
    end

    return spawnedCount
end

local function drawCardFromPlayerDeck()
    local nextSlotIndex = getNextOpenHandSlot()

    if not nextSlotIndex then
        return nil
    end

    local drawnCard = deckrules.drawCardToHand(gameState.playerDeck, nextSlotIndex)

    if not drawnCard then
        return nil
    end

    initializeCardHealthState(drawnCard)
    gameState.cards[#gameState.cards + 1] = drawnCard
    gameState.cardExpansion[#gameState.cards] = 0
    gameState.cardEntranceProgress[#gameState.cards] = 1
    playHunterAddedSfxForCard(drawnCard)

    local drawnCardDefinition = cardregistry.getCard(drawnCard.setName, drawnCard.cardId)

    if drawnCardDefinition
        and drawnCardDefinition.type == "ally"
        and getNextOpenHandSlot() then
        drawCardFromPlayerDeck()
    end

    return drawnCard
end

local function discardDestroyedCard(card)
    if not card or card.sentToDiscard then
        return nil
    end

    local cardDefinition = cardregistry.getCard(card.setName, card.cardId)

    if cardDefinition and cardDefinition.type == "token" then
        card.sentToDiscard = true
        return nil
    end

    if card.deckOwner == "player" and gameState.playerDeck then
        card.sentToDiscard = true
        return deckrules.discardCard(gameState.playerDeck, card)
    end

    if card.deckOwner == "champion" and gameState.championDeck then
        card.sentToDiscard = true
        return deckrules.discardCard(gameState.championDeck, card)
    end

    return nil
end

local function removeCardFromPlay(cardIndex)
    local card = gameState.cards[cardIndex]

    if not card then
        return false
    end

    card.destroying = false
    card.destroyed = true
    card.sentToDiscard = true
    warrules.clearCardRollState(cardIndex)

    if gameState.selectedAttackerCardIndex == cardIndex then
        gameState.selectedAttackerCardIndex = nil
    end

    if gameState.hoveredCardIndex == cardIndex then
        gameState.hoveredCardIndex = nil
    end

    if gameState.expandedGridCardIndex == cardIndex then
        gameState.expandedGridCardIndex = nil
    end

    return true
end

local function discardCardFromPlay(cardIndex)
    local card = gameState.cards[cardIndex]

    if not card then
        return false
    end

    if card.deckOwner == "player" and gameState.playerDeck then
        deckrules.discardCard(gameState.playerDeck, card)
    elseif card.deckOwner == "champion" and gameState.championDeck then
        deckrules.discardCard(gameState.championDeck, card)
    end

    removeCardFromPlay(cardIndex)
    return true
end

local function addObjectiveProgress(objectiveDefinition, amount, slotId)
    local result = objectiveprogressrules.addProgress(objectiveDefinition, amount, {
        slotId = slotId,
        activePrimaryObjective = gameState.activePrimaryObjective,
        objectiveEscalationActive = topsloteffects.isObjectiveEscalationActive(),
    })

    if result.progressEffect and result.progressEffect.overlayName == "progress" then
        topsloteffects.beginObjectiveProgress(result.progressEffect.overlayName, result.progressEffect.slotId)
        sfxrules.playProgress()
    elseif result.progressEffect and result.progressEffect.overlayName == "sabotage" then
        topsloteffects.beginObjectiveProgress(result.progressEffect.overlayName, result.progressEffect.slotId)
        sfxrules.playSabotage()
    end

    if result.shouldDestroyIntel then
        startIntelDestruction()
    end

    if result.escalationId then
        beginObjectiveEscalation(objectiveDefinition, result.escalationId)
    end

    return result.appliedChange
end

local function buildWarzoneControlContext(slotId)
    return {
        slotId = slotId,
        activeWarzone = gameState.activeWarzone,
        activePoi = gameState.activePoi,
        poiHunterTransformationActive = topsloteffects.isPoiHunterTransformationActive(),
        preloadTopStripAssets = envdraw.preloadTopStripAssets,
        beginWarzoneTransformation = beginWarzoneTransformation,
        beginPoiEmergenceEffect = beginPoiEmergenceEffect,
        beginPoiFlipEffect = beginPoiFlipEffect,
        beginPoiGeneratedCardTransformation = beginPoiGeneratedCardTransformation,
        setActiveWarzone = function(warzoneDefinition)
            gameState.activeWarzone = warzoneDefinition
        end,
        setActivePoi = function(poiDefinition)
            gameState.activePoi = poiDefinition
        end,
        onControlChanged = function(changedSlotId)
            gameState.damageJitters[changedSlotId or "warzone"] = {
                elapsed = 0,
                duration = DAMAGE_JITTER_DURATION,
                magnitude = DAMAGE_JITTER_MAGNITUDE,
            }
            sfxrules.playInfluence()
        end,
    }
end

local function addWarzoneControl(warzoneDefinition, amount, slotId)
    return warzonecontrolrules.addControl(warzoneDefinition, amount, buildWarzoneControlContext(slotId))
end

local function getChampionPrimaryObjective(championDefinition)
    local objectiveId = championDefinition and championDefinition.PrimaryObjective or ACTIVE_PRIMARY_OBJECTIVE_ID
    return objectiverules.getObjective(objectiveId)
end

preloadWarzoneFamily = function(warzoneDefinition)
    warzonecontrolrules.preloadWarzoneFamily(warzoneDefinition, envdraw.preloadTopStripAssets)
end

local function getRandomChampionIntel(championDefinition)
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

local function getReplacementIntel(defeatedIntel)
    if not defeatedIntel then
        return nil
    end

    if defeatedIntel.id == "INT0000" then
        return getRandomChampionIntel(gameState.activeChampion)
    end

    return objectiverules.getObjective("INT0000")
end

local function getHunterEmphasisInHand()
    local totalEmphasis = 0

    for _, card in ipairs(gameState.cards or {}) do
        if card
            and card.location
            and card.location.kind == "hand"
            and not isCardDestroyed(card) then
            local cardDefinition = cardregistry.getCard(card.setName, card.cardId)

            if cardDefinition and cardDefinition.type == "hunter" then
                totalEmphasis = totalEmphasis + math.max(0, tonumber(cardDefinition.emphasis) or 0)
            end
        end
    end

    return totalEmphasis
end

local function getEndPhaseObjectiveProgress()
    return (gameState.activePrimaryObjective and gameState.activePrimaryObjective.emphasis or 0) + getHunterEmphasisInHand()
end

initializeCardHealthState = function(card)
    return cardinstances.initializeHealth(card)
end

initializeCardsHealthState = function(cardList)
    return cardinstances.initializeAllHealth(cardList)
end

dealDamageToCard = function(card, amount, suppressFeedback)
    local damageResult = damagerules.dealDamageToCard(card, amount)

    if damageResult and damageResult.changed and not suppressFeedback then
        local damagedCardIndex = nil

        for cardIndex, candidateCard in ipairs(gameState.cards) do
            if candidateCard == card then
                damagedCardIndex = cardIndex
                break
            end
        end

        if damagedCardIndex then
            triggerDamageFeedback(getDamageJitterKeyForCard(damagedCardIndex))

            if damageResult.killed then
                startCardDestruction(damagedCardIndex)
            end
        end
    end

    return damageResult
end

addBlockingToCard = function(card, amount)
    return damagerules.addBlockingToCard(card, amount)
end

clearAllBlocking = function()
    return damagerules.clearAllBlocking(gameState.cards)
end

dealDamageToChampion = function(amount, suppressFeedback)
    local damageResult = damagerules.dealDamageToChampion(gameState.activeChampion, amount)

    if damageResult and damageResult.changed and not suppressFeedback then
        triggerDamageFeedback("champion")

        if damageResult.killed then
            startChampionDestruction()
        end
    end

    return damageResult
end

local function getChampionPlayContext()
    return {
        championDeck = gameState.championDeck,
        cards = gameState.cards,
        cardExpansion = gameState.cardExpansion,
        cardEntranceProgress = gameState.cardEntranceProgress,
        getOppRow = getOppRow,
        isGridRowColumnOccupied = isGridRowColumnOccupied,
        initializeCardHealthState = initializeCardHealthState,
    }
end

getTopSlotRollTargets = function()
    return envdraw.getTopSlotRollTargets(
        turnrules.getCurrentPhase(),
        gameState.activeChampion,
        gameState.activeWarzone,
        gameState.activePoi,
        gameState.activePrimaryObjective,
        gameState.activeIntel
    )
end

local function getPhaseControllerDeps()
    return {
        carddraw = carddraw,
        cardregistry = cardregistry,
        championplayrules = championplayrules,
        deckrules = deckrules,
        envdraw = envdraw,
        envrules = envrules,
        keywordrules = keywordrules,
        notifications = notifications,
        resourcerules = resourcerules,
        sfxrules = sfxrules,
        topsloteffects = topsloteffects,
        turnrules = turnrules,
        warrules = warrules,
        addObjectiveProgress = addObjectiveProgress,
        addSetupAgents = addSetupAgents,
        addWarzoneControl = addWarzoneControl,
        beginInfiltrationEffect = beginInfiltrationEffect,
        beginPoiGeneratedCardTransformation = beginPoiGeneratedCardTransformation,
        clearAllBlocking = clearAllBlocking,
        createGeneratedSupportCard = createGeneratedSupportCard,
        dealDamageToCard = dealDamageToCard,
        drawCardFromPlayerDeck = drawCardFromPlayerDeck,
        getCardDrawPosition = getCardDrawPosition,
        getChampionPlayContext = getChampionPlayContext,
        getEndPhaseObjectiveProgress = getEndPhaseObjectiveProgress,
        getReplacementIntel = getReplacementIntel,
        getSetupCardCount = getSetupCardCount,
        getTopSlotRollTargets = getTopSlotRollTargets,
        initializeCardsHealthState = initializeCardsHealthState,
        isCardUnavailable = isCardUnavailable,
        isGridCard = isGridCard,
        normalizeSetupCardSlots = normalizeSetupCardSlots,
        playHunterAddedSfxForCards = playHunterAddedSfxForCards,
        removeCardFromPlay = removeCardFromPlay,
        updateInfiltrationEffect = updateInfiltrationEffect,
    }
end

local function enterCurrentPhase()
    phasecontroller.enterCurrentPhase(gameState, getPhaseControllerDeps())
end

local function completeSetupPhaseIfReady()
    phasecontroller.completeSetupPhaseIfReady(gameState, getPhaseControllerDeps())
end

local function canPlayCard(card)
    local cardDefinition = cardregistry.getCard(card.setName, card.cardId)

    if strategyrules.isStrategyDefinition(cardDefinition) then
        return false
    end

    if not cardDefinition or not cardDefinition.mcost then
        return true
    end

    return resourcerules.canAffordCosts(cardDefinition.mcost)
end

local function isHunterCard(card)
    if not card then
        return false
    end

    local cardDefinition = cardregistry.getCard(card.setName, card.cardId)
    return cardDefinition and cardDefinition.type == "hunter" or false
end

local function isHunterCardDefinition(cardDefinition)
    return cardDefinition and cardDefinition.type == "hunter" or false
end

playHunterAddedSfxForCard = function(card)
    if isHunterCard(card) then
        sfxrules.playHunt()
    end
end

playHunterAddedSfxForCardDefinition = function(cardDefinition)
    if isHunterCardDefinition(cardDefinition) then
        sfxrules.playHunt()
    end
end

playHunterAddedSfxForCards = function(cards)
    for _, card in ipairs(cards or {}) do
        playHunterAddedSfxForCard(card)
    end
end

local function payCardCosts(card)
    local cardDefinition = cardregistry.getCard(card.setName, card.cardId)

    if not cardDefinition or not cardDefinition.mcost then
        return true
    end

    return resourcerules.payCosts(cardDefinition.mcost)
end

local function getGridCardAt(mouseX, mouseY, ignoredCardIndex)
    for cardIndex = #gameState.cards, 1, -1 do
        local card = gameState.cards[cardIndex]

        if cardIndex ~= ignoredCardIndex
            and not isCardUnavailable(card)
            and card.location
            and card.location.kind == "grid" then
            local drawX, drawY, expansionProgress, renderOptions = getCardDrawPosition(card, cardIndex)

            if carddraw.isPointInsideDrawnCard(mouseX, mouseY, drawX, drawY, expansionProgress, nil, renderOptions) then
                return cardIndex
            end
        end
    end

    return nil
end

local function getCardAt(mouseX, mouseY, ignoredCardIndex)
    for cardIndex = #gameState.cards, 1, -1 do
        local card = gameState.cards[cardIndex]

        if cardIndex ~= ignoredCardIndex and not isCardUnavailable(card) then
            local drawX, drawY, expansionProgress, renderOptions = getCardDrawPosition(card, cardIndex)

            if carddraw.isPointInsideDrawnCard(mouseX, mouseY, drawX, drawY, expansionProgress, nil, renderOptions) then
                return cardIndex
            end
        end
    end

    return nil
end

local function getFullArtAt(mouseX, mouseY)
    local cardIndex = getCardAt(mouseX, mouseY)

    if cardIndex then
        local card = gameState.cards[cardIndex]

        return carddraw.getPortraitImage(card.setName, card.cardId, {
            portraitPath = card.portraitPath,
        })
    end

    if isPointInsideJaclPortrait(mouseX, mouseY) then
        return envdraw.getJaclArtImage(gameState.playerJacl)
    end

    local topSlotId = getHoveredTopSlotId(mouseX, mouseY)

    if topSlotId then
        return envdraw.getTopSlotArtImage(
            topSlotId,
            gameState.activeChampion,
            gameState.activeWarzone,
            gameState.activePoi,
            gameState.activePrimaryObjective,
            gameState.activeIntel
        )
    end

    return nil
end

local function tryOpenFullArt(mouseX, mouseY)
    local image = getFullArtAt(mouseX, mouseY)

    if not image then
        return false
    end

    gameState.fullArtImage = image
    gameState.draggedCardIndex = nil
    gameState.draggedCardOrigin = nil
    gameState.expandedGridCardIndex = nil
    gameState.expandedTopSlotId = nil
    return true
end

local function isStrategyCard(card)
    return strategyrules.isStrategyCard(card, {
        cardregistry = cardregistry,
    })
end

local function tryUseTomeCard(cardIndex)
    return tomerules.useTome(cardIndex, {
        cards = gameState.cards,
        turnrules = turnrules,
        cardregistry = cardregistry,
        spawnTokensNearCard = spawnTokensNearPlayerCard,
        getSyntacCount = function()
            return gameState.syntacCount or 0
        end,
        spendSyntac = function(amount)
            gameState.syntacCount = math.max(0, (gameState.syntacCount or 0) - math.max(0, tonumber(amount) or 0))
        end,
    })
end

local function tryPlayStrategyCard(strategyCardIndex, targetCardIndex)
    return strategyrules.playStrategy(strategyCardIndex, targetCardIndex, {
        cards = gameState.cards,
        turnrules = turnrules,
        warrules = warrules,
        cardregistry = cardregistry,
        discardCard = discardCardFromPlay,
        spawnTokensNearCard = spawnTokensNearCard,
    })
end

local function getCardPresentationContext()
    return {
        envdraw = envdraw,
        turnrules = turnrules,
        warrules = warrules,
        cards = gameState.cards,
        cardExpansion = gameState.cardExpansion,
        cardEntranceProgress = gameState.cardEntranceProgress,
        draggedCardIndex = gameState.draggedCardIndex,
        dragOffsetX = gameState.dragOffsetX,
        dragOffsetY = gameState.dragOffsetY,
        selectedAttackerCardIndex = gameState.selectedAttackerCardIndex,
        activeChampion = gameState.activeChampion,
        activeWarzone = gameState.activeWarzone,
        activePoi = gameState.activePoi,
        activePrimaryObjective = gameState.activePrimaryObjective,
        activeIntel = gameState.activeIntel,
        destructionDuration = DESTRUCTION_DURATION,
        isWarRollSourceActive = isWarRollSourceActive,
        isCardUnavailable = isCardUnavailable,
        getSetupCardCount = getSetupCardCount,
        getPlayerHandLayout = getPlayerHandLayout,
        getDamageJitterOffset = getDamageJitterOffset,
        getDamageJitterKeyForCard = getDamageJitterKeyForCard,
        getTargetingContext = getTargetingContext,
    }
end

local function getCardRenderOptions(card, cardIndex)
    return cardpresentation.getRenderOptions(card, cardIndex, getCardPresentationContext())
end

isGridRowColumnOccupied = function(rowId, column, ignoredCardIndex)
    return cardzones.isGridRowColumnOccupied(gameState.cards, rowId, column, ignoredCardIndex)
end

function getCardDrawPosition(card, cardIndex)
    return cardpresentation.getDrawPosition(card, cardIndex, getCardPresentationContext())
end

local function getEntitySourceRect(entityKey)
    return cardpresentation.getEntitySourceRect(entityKey, getCardPresentationContext())
end

beginInfiltrationEffect = function(entityKey, generatedCardDefinition, count)
    if not generatedCardDefinition then
        return false
    end

    local sourceRect = getEntitySourceRect(entityKey)

    if not sourceRect then
        return false
    end

    carddraw.preloadPortrait(generatedCardDefinition.setName, generatedCardDefinition.id)
    return infiltrationrules.begin(sourceRect, generatedCardDefinition, count)
end

local function getValidDropColumn(mouseX, mouseY, ignoredCardIndex, draggedCard)
    return cardzones.getValidDropColumn(mouseX, mouseY, gameState.cards, ignoredCardIndex, draggedCard, {
        getPlayerRow = getPlayerRow,
        getOppRow = getOppRow,
        isHunterCard = isHunterCard,
    })
end

local function getDropCell(mouseX, mouseY)
    return cardzones.getDropCell(mouseX, mouseY, gameState.cards, gameState.draggedCardIndex, {
        getPlayerRow = getPlayerRow,
        getOppRow = getOppRow,
        isHunterCard = isHunterCard,
    })
end

local function getPlayerRowCellAt(mouseX, mouseY)
    return cardzones.getCellAt(getPlayerRow(), mouseX, mouseY)
end

local function getValidJaclSpecialTargetCell(mouseX, mouseY)
    return cardzones.getValidJaclSpecialTargetCell(mouseX, mouseY, gameState.cards, {
        getPlayerRow = getPlayerRow,
    })
end

isWarRollSourceActive = function(entityKey)
    if entityKey == "champion" then
        return gameState.activeChampion and not gameState.activeChampion.hidden and not topsloteffects.isChampionDestructionActive()
    end

    local cardIndex = entityKey and entityKey:match("^card:(%d+)$")

    if cardIndex then
        local sourceCard = gameState.cards[tonumber(cardIndex)]
        return sourceCard and not sourceCard.destroying and not sourceCard.destroyed
    end

    return true
end

local function getEngageContext()
    return {
        turnrules = turnrules,
        warrules = warrules,
        envdraw = envdraw,
        cards = gameState.cards,
        hoveredCardIndex = gameState.hoveredCardIndex,
        selectedAttackerCardIndex = gameState.selectedAttackerCardIndex,
        engageRerollCount = gameState.engageRerollCount,
        playerJacl = gameState.playerJacl,
        activePrimaryObjective = gameState.activePrimaryObjective,
        activeIntel = gameState.activeIntel,
        activeWarzone = gameState.activeWarzone,
        activePoi = gameState.activePoi,
        isCardUnavailable = isCardUnavailable,
        isWarRollSourceActive = isWarRollSourceActive,
        getCardDrawPosition = getCardDrawPosition,
        addBlockingToCard = addBlockingToCard,
        addObjectiveProgress = addObjectiveProgress,
        addWarzoneControl = addWarzoneControl,
        dealDamageToChampion = dealDamageToChampion,
        dealDamageToCard = dealDamageToCard,
        beginInfiltrationEffect = beginInfiltrationEffect,
        addSyntac = function(amount)
            gameState.syntacCount = math.min(10, math.max(0, (gameState.syntacCount or 0) + math.max(0, tonumber(amount) or 0)))
        end,
        setSelectedAttackerCardIndex = function(cardIndex)
            gameState.selectedAttackerCardIndex = cardIndex
        end,
        setExpandedGridCardIndex = function(cardIndex)
            gameState.expandedGridCardIndex = cardIndex
        end,
        setExpandedTopSlotId = function(slotId)
            gameState.expandedTopSlotId = slotId
        end,
        setEngageRerollCount = function(count)
            gameState.engageRerollCount = count
        end,
    }
end

local function tryResolveEngageClick(hoveredTopSlotId)
    return engagerules.tryResolveClick(hoveredTopSlotId, getEngageContext())
end

local function isEngagePhase()
    return engagerules.isEngagePhase(getEngageContext())
end

local function canOpenPlayerDeckModal()
    return turnrules.getCurrentPhase() == "Prelude" or isEngagePhase()
end

local function getHoveredPlayerRollBadgeCardIndex(mouseX, mouseY)
    return engagerules.getHoveredPlayerRollBadgeCardIndex(mouseX, mouseY, getEngageContext())
end

local function buildModalState()
    return {
        playerJacl = gameState.playerJacl,
        activePrimaryObjective = gameState.activePrimaryObjective,
        isResourceExchangeModalOpen = gameState.isResourceExchangeModalOpen,
        isJaclDeckModalOpen = gameState.isJaclDeckModalOpen,
        jaclDeckModalScroll = gameState.jaclDeckModalScroll,
        jaclDeckPreviewCard = gameState.jaclDeckPreviewCard,
        activeDeckModalDeck = gameState.activeDeckModalDeck,
        primedJaclSpecial = gameState.primedJaclSpecial,
    }
end

local function applyModalState(modalState)
    gameState.isResourceExchangeModalOpen = modalState.isResourceExchangeModalOpen
    gameState.isJaclDeckModalOpen = modalState.isJaclDeckModalOpen
    gameState.jaclDeckPreviewCard = modalState.jaclDeckPreviewCard
    gameState.activeDeckModalDeck = modalState.activeDeckModalDeck
    gameState.primedJaclSpecial = modalState.primedJaclSpecial
end

local function getModalDeps()
    return {
        turnrules = turnrules,
        resourcerules = resourcerules,
        specialrules = specialrules,
        cardregistry = cardregistry,
        sfxrules = sfxrules,
        envdraw = envdraw,
        createGeneratedGridCard = createGeneratedGridCard,
        getValidJaclSpecialTargetCell = getValidJaclSpecialTargetCell,
        getPlayerRowCellAt = getPlayerRowCellAt,
        addObjectiveProgress = addObjectiveProgress,
    }
end

local function isPointInsideJaclScratchBadge(mouseX, mouseY)
    return modals.isPointInsideJaclScratchBadge(mouseX, mouseY, envdraw, gameState.playerJacl)
end

isPointInsideJaclPortrait = function(mouseX, mouseY)
    return modals.isPointInsideJaclPortrait(mouseX, mouseY, envdraw, gameState.playerJacl)
end

local function primeJaclSpecial(resourceName)
    local modalState = buildModalState()
    local primed = modals.primeJaclSpecial(resourceName, modalState, getModalDeps())
    applyModalState(modalState)
    return primed
end

local function tryUseEngageReroll(mouseX, mouseY)
    return engagerules.tryUseReroll(mouseX, mouseY, getEngageContext())
end

local function tryCancelSelectedEngageAttacker()
    return engagerules.tryCancelSelectedAttacker(getEngageContext())
end

getTargetingContext = function()
    return {
        cards = gameState.cards,
        hoveredCardIndex = gameState.hoveredCardIndex,
        hoveredTopSlotId = gameState.hoveredTopSlotId,
        selectedAttackerCardIndex = gameState.selectedAttackerCardIndex,
        currentPhase = turnrules.getCurrentPhase(),
        displayStates = warrules.getDisplayStates(),
        activePrimaryObjective = gameState.activePrimaryObjective,
        activeIntel = gameState.activeIntel,
        activeWarzone = gameState.activeWarzone,
        activePoi = gameState.activePoi,
        getCardRollState = warrules.getCardRollState,
        canTargetEnemyCard = warrules.canTargetEnemyCard,
        canTargetPlayerWarzone = warrules.canTargetPlayerWarzone,
    }
end

local function drawTopSlotHoverTargetBrackets(currentPhase, warzonePreviewState, objectivePreviewPips, intelPreviewPips)
    local slots = envdraw.getTopSlotLayouts(
        currentPhase,
        gameState.activeChampion,
        gameState.activeWarzone,
        gameState.activePoi,
        gameState.activePrimaryObjective,
        gameState.activeIntel,
        warzonePreviewState,
        objectivePreviewPips,
        intelPreviewPips
    )

    targetoverlays.drawTopSlotBrackets(slots, getTargetingContext())
end

local function drawInfiltrationEffect()
    infiltrationdraw.drawEffect(infiltrationrules.getActiveEffect())
end

local function drawCardStateOverlays(card, cardIndex, drawX, drawY, expansionProgress, renderOptions)
    cardpresentation.drawStateOverlays(card, cardIndex, drawX, drawY, expansionProgress, renderOptions, getCardPresentationContext())
end

local function updateHoveredSpawnPreview(card)
    gameState.hoveredTomeSpawnPreviewCard = nil

    local cardDefinition = card and cardregistry.getCard(card.setName, card.cardId) or nil

    if tomerules.isSpawnTomeDefinition(cardDefinition) then
        local targetCardId = tomerules.getFirstTargetCardId(cardDefinition)
        gameState.hoveredTomeSpawnPreviewCard = targetCardId and cardregistry.getCardById(targetCardId) or nil
    elseif strategyrules.isSpawnStrategyDefinition(cardDefinition) then
        local targetCardId = strategyrules.getFirstTargetCardId(cardDefinition)
        gameState.hoveredTomeSpawnPreviewCard = targetCardId and cardregistry.getCardById(targetCardId) or nil
    end
end

local function updateHoveredCard()
    local previousHoveredCardIndex = gameState.hoveredCardIndex
    gameState.hoveredKeyword = nil

    if gameState.draggedCardIndex or gameState.isResourceExchangeModalOpen or gameState.isJaclDeckModalOpen then
        gameState.hoveredCardIndex = nil
        gameState.hoveredTopSlotId = nil
        gameState.hoveredJaclSpecialDefinition = nil
        gameState.hoveredJaclSpecialPreviewCard = nil
        gameState.hoveredTomeSpawnPreviewCard = nil
        return
    end

    local mouseX, mouseY = love.mouse.getPosition()
    gameState.hoveredTopSlotId = getHoveredTopSlotId(mouseX, mouseY)
    gameState.hoveredJaclSpecialDefinition = nil
    gameState.hoveredJaclSpecialPreviewCard = nil
    gameState.hoveredTomeSpawnPreviewCard = nil

    if gameState.hoveredCardIndex then
        local activeCard = gameState.cards[gameState.hoveredCardIndex]

        if activeCard and not isCardUnavailable(activeCard) then
            local drawX, drawY, expansionProgress, renderOptions = getCardDrawPosition(activeCard, gameState.hoveredCardIndex)

            if carddraw.isPointInsideDrawnCard(mouseX, mouseY, drawX, drawY, expansionProgress, nil, renderOptions) then
                gameState.hoveredKeyword = carddraw.getHoveredKeyword(activeCard.setName, activeCard.cardId, drawX, drawY, renderOptions, mouseX, mouseY)
                updateHoveredSpawnPreview(activeCard)
                return
            end
        end
    end

    gameState.hoveredCardIndex = nil

    for cardIndex = #gameState.cards, 1, -1 do
        if not isCardUnavailable(gameState.cards[cardIndex]) then
            local drawX, drawY, expansionProgress, renderOptions = getCardDrawPosition(gameState.cards[cardIndex], cardIndex)

            if carddraw.isPointInsideDrawnCard(mouseX, mouseY, drawX, drawY, expansionProgress, nil, renderOptions) then
                gameState.hoveredCardIndex = cardIndex
                gameState.hoveredKeyword = carddraw.getHoveredKeyword(gameState.cards[cardIndex].setName, gameState.cards[cardIndex].cardId, drawX, drawY, renderOptions, mouseX, mouseY)
                updateHoveredSpawnPreview(gameState.cards[cardIndex])
                break
            end
        end
    end

    if gameState.hoveredCardIndex ~= nil
        and gameState.hoveredCardIndex ~= previousHoveredCardIndex
        and gameState.cards[gameState.hoveredCardIndex]
        and gameState.cards[gameState.hoveredCardIndex].location.kind == "hand" then
        sfxrules.playHover()
    end

    if not gameState.hoveredKeyword and gameState.playerJacl and gameState.playerJacl.special then
        local hoveredMethodBadge = envdraw.getJaclMethodBadgeAt(mouseX, mouseY, gameState.playerJacl)

        if hoveredMethodBadge then
            gameState.hoveredJaclSpecialDefinition = specialrules.getSpecial(gameState.playerJacl.special)

            if gameState.hoveredJaclSpecialDefinition and gameState.hoveredJaclSpecialDefinition.spawn then
                gameState.hoveredJaclSpecialPreviewCard = cardregistry.getCardById(gameState.hoveredJaclSpecialDefinition.spawn)
            end
        end
    end
end

local function getInputControllerDeps()
    return {
        envdraw = envdraw,
        modals = modals,
        notifications = notifications,
        phasecontroller = phasecontroller,
        sfxrules = sfxrules,
        turnrules = turnrules,
        warrules = warrules,
        applyModalState = applyModalState,
        buildModalState = buildModalState,
        canExpandCard = canExpandCard,
        canOpenPlayerDeckModal = canOpenPlayerDeckModal,
        canPlayCard = canPlayCard,
        completeSetupPhaseIfReady = completeSetupPhaseIfReady,
        copyLocation = copyLocation,
        getCardDrawPosition = getCardDrawPosition,
        getHoveredPlayerRollBadgeCardIndex = getHoveredPlayerRollBadgeCardIndex,
        getHoveredTopSlotId = getHoveredTopSlotId,
        getGridCardAt = getGridCardAt,
        getModalDeps = getModalDeps,
        getPhaseControllerDeps = getPhaseControllerDeps,
        getValidDropColumn = getValidDropColumn,
        isEngagePhase = isEngagePhase,
        isGridCard = isGridCard,
        isHunterCard = isHunterCard,
        isPointInsideJaclPortrait = isPointInsideJaclPortrait,
        isPointInsideJaclScratchBadge = isPointInsideJaclScratchBadge,
        isSetupCard = isSetupCard,
        isStrategyCard = isStrategyCard,
        normalizeHandCardSlots = normalizeHandCardSlots,
        normalizeSetupCardSlots = normalizeSetupCardSlots,
        payCardCosts = payCardCosts,
        primeJaclSpecial = primeJaclSpecial,
        tryPlayStrategyCard = tryPlayStrategyCard,
        tryUseTomeCard = tryUseTomeCard,
        tryOpenFullArt = tryOpenFullArt,
        tryCancelSelectedEngageAttacker = tryCancelSelectedEngageAttacker,
        tryResolveEngageClick = tryResolveEngageClick,
        tryUseEngageReroll = tryUseEngageReroll,
        updateHoveredCard = updateHoveredCard,
    }
end

function love.load()
    love.math.setRandomSeed(os.time())
    love.graphics.setBackgroundColor(0.08, 0.08, 0.1)
    love.graphics.setColor(1, 1, 1)
    gameState.cards = {}
    gameState.hoveredCardIndex = nil
    gameState.hoveredTopSlotId = nil
    gameState.hoveredKeyword = nil
    gameState.expandedGridCardIndex = nil
    gameState.expandedTopSlotId = nil
    gameState.selectedAttackerCardIndex = nil
    gameState.draggedCardIndex = nil
    gameState.draggedCardOrigin = nil
    gameState.dragOffsetX = 0
    gameState.dragOffsetY = 0
    gameState.cardEntranceTimer = 0
    gameState.cardExpansion = {}
    gameState.cardEntranceProgress = {}
    gameState.topSlotExpansion = {}
    gameState.damageJitters = {}
    gameState.waitingForStartGeneration = false
    gameState.hasRenderedFirstFrame = false
    gameState.pendingPhaseEntry = false
    gameState.pendingSetupCompletion = false
    turnrules.reset()
    resourcerules.reset()
    warrules.reset()
    notifications.reset()
    championplayrules.resetState(gameState.championPlayState)
    gameState.engageRerollCount = 2
    gameState.syntacCount = 0
    gameState.isResourceExchangeModalOpen = false
    gameState.isJaclDeckModalOpen = false
    gameState.jaclDeckModalScroll.deck = 0
    gameState.jaclDeckModalScroll.discard = 0
    gameState.jaclDeckPreviewCard = nil
    gameState.activeDeckModalDeck = nil
    gameState.primedJaclSpecial = nil
    gameState.fullArtImage = nil
    gameState.hoveredJaclSpecialDefinition = nil
    gameState.hoveredJaclSpecialPreviewCard = nil
    gameState.hoveredTomeSpawnPreviewCard = nil
    cardinstances.reset()
    warzonecontrolrules.reset()
    topsloteffects.reset()
    infiltrationrules.reset()
    gameState.playerJacl = jaclrules.getJacl(PLAYER_JACL_ID)
    gameState.activeChampion = championrules.getChampion(ACTIVE_CHAMPION_ID)
    if gameState.activeChampion then
        gameState.activeChampion.hidden = false
    end
    gameState.activeWarzone = warzonerules.getRandomWarzoneByIdSuffix(RANDOM_WARZONE_SUFFIX) or warzonerules.getWarzone(ACTIVE_WARZONE_ID)
    gameState.activePoi = nil
    gameState.activePrimaryObjective = getChampionPrimaryObjective(gameState.activeChampion)
    gameState.activeIntel = getRandomChampionIntel(gameState.activeChampion)
    if gameState.activeIntel then
        gameState.activeIntel.hidden = false
    end
    envdraw.preloadTopStripAssets(gameState.activeChampion, gameState.activeWarzone, gameState.activePoi, gameState.activePrimaryObjective, gameState.activeIntel)
    preloadWarzoneFamily(gameState.activeWarzone)
    gameState.playerDeck = gameState.playerJacl and deckrules.buildDeck(gameState.playerJacl.deckId) or nil
    gameState.championDeck = gameState.activeChampion and gameState.activeChampion.deckId and deckrules.buildDeck(gameState.activeChampion.deckId) or nil

    if gameState.playerDeck then
        gameState.playerDeck.owner = "player"

        for _, deckCard in ipairs(gameState.playerDeck.cards) do
            deckCard.deckOwner = "player"
        end
    end

    if gameState.championDeck then
        gameState.championDeck.owner = "champion"

        for _, deckCard in ipairs(gameState.championDeck.cards) do
            deckCard.deckOwner = "champion"
        end
    end

    enterCurrentPhase()
    gameState.pendingPhaseEntry = false

    for cardIndex = 1, #gameState.cards do
        gameState.cardExpansion[cardIndex] = 0
        gameState.cardEntranceProgress[cardIndex] = 0
    end
end

updateInfiltrationEffect = function(dt)
    infiltrationrules.update(dt, function(generatedCardDefinition)
        if createGeneratedDeckCardShuffled(generatedCardDefinition) then
            sfxrules.playInfluence()
        end
    end)
end

function love.update(dt)
    local entranceDt = math.min(dt, CARD_ENTRANCE_MAX_DT)

    gameState.cardEntranceTimer = gameState.cardEntranceTimer + entranceDt
    resourcerules.update(dt)

    for _, card in ipairs(gameState.cards) do
        if card.destroying then
            card.destroyElapsed = (card.destroyElapsed or 0) + dt

            if card.destroyElapsed >= DESTRUCTION_DURATION then
                card.destroying = false
                card.destroyed = true
                discardDestroyedCard(card)
            end
        end
    end

    for entityKey, jitter in pairs(gameState.damageJitters) do
        jitter.elapsed = jitter.elapsed + dt

        if jitter.elapsed >= jitter.duration then
            gameState.damageJitters[entityKey] = nil
        end
    end

    phasecontroller.update(gameState, getPhaseControllerDeps(), dt)

    notifications.update(dt)
    updateHoveredCard()

    for cardIndex, card in ipairs(gameState.cards) do
        local startTime = (cardIndex - 1) * CARD_ENTRANCE_STAGGER
        local entranceTarget = 1
        local expansionTarget = 0
        local entranceProgress = gameState.cardEntranceProgress[cardIndex] or 0
        local expansionProgress = gameState.cardExpansion[cardIndex] or 0

        if card.location.kind == "hand" and gameState.cardEntranceTimer < startTime then
            entranceTarget = 0
        end

        if gameState.draggedCardIndex ~= cardIndex then
            if canExpandCard(card) then
                expansionTarget = gameState.expandedGridCardIndex == cardIndex and 1 or 0
            else
                expansionTarget = gameState.hoveredCardIndex == cardIndex and 1 or 0
            end
        end

        if entranceProgress < entranceTarget then
            gameState.cardEntranceProgress[cardIndex] = math.min(entranceTarget, entranceProgress + (entranceDt * CARD_ENTRANCE_SPEED))
        elseif entranceProgress > entranceTarget then
            gameState.cardEntranceProgress[cardIndex] = math.max(entranceTarget, entranceProgress - (entranceDt * CARD_ENTRANCE_SPEED))
        end

        if expansionProgress < expansionTarget then
            gameState.cardExpansion[cardIndex] = math.min(expansionTarget, expansionProgress + (dt * CARD_HOVER_ANIMATION_SPEED))
        elseif expansionProgress > expansionTarget then
            gameState.cardExpansion[cardIndex] = math.max(expansionTarget, expansionProgress - (dt * CARD_HOVER_ANIMATION_SPEED))
        end
    end

    local topSlotIds = {
        "champion",
        "warzone",
        "poi",
        "objective",
        "intel",
    }

    for _, slotId in ipairs(topSlotIds) do
        local expansionProgress = gameState.topSlotExpansion[slotId] or 0
        local expansionTarget = gameState.expandedTopSlotId == slotId and 1 or 0

        if expansionProgress < expansionTarget then
            gameState.topSlotExpansion[slotId] = math.min(expansionTarget, expansionProgress + (dt * CARD_HOVER_ANIMATION_SPEED))
        elseif expansionProgress > expansionTarget then
            gameState.topSlotExpansion[slotId] = math.max(expansionTarget, expansionProgress - (dt * CARD_HOVER_ANIMATION_SPEED))
        end
    end
end

function love.mousepressed(x, y, button)
    inputcontroller.mousepressed(gameState, getInputControllerDeps(), x, y, button)
end

function love.wheelmoved(_, y)
    inputcontroller.wheelmoved(gameState, getInputControllerDeps(), _, y)
end

function love.mousereleased(x, y, button)
    inputcontroller.mousereleased(gameState, getInputControllerDeps(), x, y, button)
end

function love.keypressed(key)
    inputcontroller.keypressed(gameState, getInputControllerDeps(), key)
end

function love.draw()
    gameState.hasRenderedFirstFrame = true
    gamestatedraw.draw({
        turnrules = turnrules,
        warrules = warrules,
        resourcerules = resourcerules,
        envdraw = envdraw,
        carddraw = carddraw,
        topsloteffects = topsloteffects,
        notifications = notifications,
        activeChampion = gameState.activeChampion,
        activeWarzone = gameState.activeWarzone,
        activePoi = gameState.activePoi,
        activePrimaryObjective = gameState.activePrimaryObjective,
        activeIntel = gameState.activeIntel,
        expandedTopSlotId = gameState.expandedTopSlotId,
        topSlotExpansion = gameState.topSlotExpansion,
        playerJacl = gameState.playerJacl,
        engageRerollCount = gameState.engageRerollCount,
        syntacCount = gameState.syntacCount,
        cards = gameState.cards,
        hoveredCardIndex = gameState.hoveredCardIndex,
        draggedCardIndex = gameState.draggedCardIndex,
        expandedGridCardIndex = gameState.expandedGridCardIndex,
        isJaclDeckModalOpen = gameState.isJaclDeckModalOpen,
        activeDeckModalDeck = gameState.activeDeckModalDeck,
        fullArtImage = gameState.fullArtImage,
        jaclDeckModalScroll = gameState.jaclDeckModalScroll,
        jaclDeckPreviewCard = gameState.jaclDeckPreviewCard,
        isResourceExchangeModalOpen = gameState.isResourceExchangeModalOpen,
        hoveredKeyword = gameState.hoveredKeyword,
        hoveredJaclSpecialDefinition = gameState.hoveredJaclSpecialDefinition,
        hoveredJaclSpecialPreviewCard = gameState.hoveredJaclSpecialPreviewCard,
        hoveredTomeSpawnPreviewCard = gameState.hoveredTomeSpawnPreviewCard,
        primedJaclSpecial = gameState.primedJaclSpecial,
        isWarRollSourceActive = isWarRollSourceActive,
        getDamageJitterOffset = getDamageJitterOffset,
        getObjectiveProgressJitterOffset = getObjectiveProgressJitterOffset,
        getObjectiveProgressEffectSlotId = getObjectiveProgressEffectSlotId,
        getSetupCardCount = getSetupCardCount,
        isCardDestroyed = isCardDestroyed,
        getCardDrawPosition = getCardDrawPosition,
        drawCardStateOverlays = drawCardStateOverlays,
        getDropCell = getDropCell,
        getCardRenderOptions = getCardRenderOptions,
        drawTopSlotHoverTargetBrackets = drawTopSlotHoverTargetBrackets,
        drawInfiltrationEffect = drawInfiltrationEffect,
    })
end
