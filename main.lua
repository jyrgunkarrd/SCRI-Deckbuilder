local envdraw = require("src.render.envdraw")
local carddraw = require("src.render.carddraw")
local cardpresentation = require("src.render.cardpresentation")
local infiltrationdraw = require("src.render.infiltrationdraw")
local sfxrules = require("src.audio.sfxrules")
local cardregistry = require("src.system.cardregistry")
local cardinstances = require("src.system.cardinstances")
local cardzones = require("src.system.cardzones")
local championrules = require("src.system.championrules")
local envrules = require("src.system.envrules")
local notifications = require("src.system.notifications")
local objectiverules = require("src.system.objectiverules")
local objectiveprogressrules = require("src.system.objectiveprogressrules")
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
local targetoverlays = require("src.render.targetoverlays")
local gamestatedraw = require("src.render.gamestate_draw")
local modals = require("src.ui.modals")
local warrules = require("src.system.warrules")

local CARD_HOVER_ANIMATION_SPEED = 10
local CARD_ENTRANCE_SPEED = 6
local CARD_ENTRANCE_STAGGER = 0.1
local CARD_ENTRANCE_MAX_DT = 1 / 60
local CHAMPION_PLAY_DELAY = 0.2
local DAMAGE_JITTER_DURATION = 0.28
local DAMAGE_JITTER_MAGNITUDE = 7
local DESTRUCTION_DURATION = 0.6
local PLAYER_JACL_ID = "JACL001"
local ACTIVE_CHAMPION_ID = "CH0001"
local ACTIVE_WARZONE_ID = "WZ0001"
local RANDOM_WARZONE_SUFFIX = "B"
local ACTIVE_POI_ID = "POI0001"
local ACTIVE_PRIMARY_OBJECTIVE_ID = "PRIMOBJ0001"

local playerJacl = nil
local activeChampion = nil
local activeWarzone = nil
local activePoi = nil
local activePrimaryObjective = nil
local activeIntel = nil
local playerDeck = nil
local championDeck = nil
local cards = {}

local hoveredCardIndex = nil
local hoveredTopSlotId = nil
local hoveredKeyword = nil
local expandedGridCardIndex = nil
local expandedTopSlotId = nil
local selectedAttackerCardIndex = nil
local draggedCardIndex = nil
local draggedCardOrigin = nil
local dragOffsetX = 0
local dragOffsetY = 0
local cardEntranceTimer = 0
local cardExpansion = {}
local cardEntranceProgress = {}
local topSlotExpansion = {}
local damageJitters = {}
local waitingForStartGeneration = false
local pendingChampionPlays = 0
local championPlayDelayTimer = 0
local engageRerollCount = 2
local isResourceExchangeModalOpen = false
local isJaclDeckModalOpen = false
local jaclDeckModalScroll = {
    deck = 0,
    discard = 0,
}
local jaclDeckPreviewCard = nil
local activeDeckModalDeck = nil
local primedJaclSpecial = nil
local hoveredJaclSpecialDefinition = nil
local hoveredJaclSpecialPreviewCard = nil
local hasRenderedFirstFrame = false
local pendingPhaseEntry = false
local pendingSetupCompletion = false
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
    local card = cards[cardIndex]

    if not card or card.destroying or card.destroyed then
        return
    end

    card.destroying = true
    card.destroyElapsed = 0
    card.destroySeed = love.math.random() * 1000
    warrules.clearCardRollState(cardIndex)
    sfxrules.playDestroy()

    if selectedAttackerCardIndex == cardIndex then
        selectedAttackerCardIndex = nil
    end
end

local function startChampionDestruction()
    topsloteffects.startChampionDestruction(activeChampion)
end

local function startIntelDestruction()
    topsloteffects.startIntelDestruction(activeIntel)
end

local function triggerDamageFeedback(entityKey)
    if not entityKey then
        return
    end

    damageJitters[entityKey] = {
        elapsed = 0,
        duration = DAMAGE_JITTER_DURATION,
        magnitude = DAMAGE_JITTER_MAGNITUDE,
    }
    sfxrules.playDamage()
end

local function getDamageJitterOffset(entityKey)
    local jitter = damageJitters[entityKey]

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
        activeChampion,
        activeWarzone,
        activePoi,
        activePrimaryObjective,
        activeIntel
    )
end

local function getSetupCardCount()
    return cardzones.getSetupCardCount(cards, isCardDestroyed)
end

local function addSetupAgents()
    local setupAgentIds = {
        "AGT0001",
        "AGT0002",
    }

    for slotIndex, cardId in ipairs(setupAgentIds) do
        local cardDefinition = cardregistry.getCard("troops", cardId)

        cards[#cards + 1] = cardinstances.create(
            cardDefinition,
            "setup:" .. cardId .. ":" .. tostring(slotIndex),
            {
                kind = "setup",
                slotIndex = slotIndex,
            },
            "player"
        )

        initializeCardHealthState(cards[#cards])

        if cardId == "AGT0001" then
            dealDamageToCard(cards[#cards], 2, true)
        end
    end
end

local function normalizeSetupCardSlots()
    cardzones.normalizeSetupCardSlots(cards, isCardDestroyed)
end

local function normalizeHandCardSlots()
    cardzones.normalizeHandCardSlots(cards, isCardDestroyed)
end

getNextOpenHandSlot = function()
    return cardzones.getNextOpenHandSlot(cards, envrules.getPlayerHand().slots, isCardDestroyed)
end

local function createGeneratedSupportCard(cardDefinition, targetLocation)
    return cardinstances.createGeneratedSupportCard(cards, cardExpansion, cardEntranceProgress, playerDeck, cardDefinition, targetLocation)
end

local function createGeneratedDeckCardShuffled(cardDefinition)
    return cardinstances.createGeneratedDeckCardShuffled(playerDeck, cardDefinition)
end

local function createGeneratedGridCard(cardDefinition, rowId, column)
    return cardinstances.createGeneratedGridCard(cards, cardExpansion, cardEntranceProgress, cardDefinition, rowId, column)
end

local function drawCardFromPlayerDeck()
    local nextSlotIndex = getNextOpenHandSlot()

    if not nextSlotIndex then
        return nil
    end

    local drawnCard = deckrules.drawCardToHand(playerDeck, nextSlotIndex)

    if not drawnCard then
        return nil
    end

    initializeCardHealthState(drawnCard)
    cards[#cards + 1] = drawnCard
    cardExpansion[#cards] = 0
    cardEntranceProgress[#cards] = 1

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

    if card.deckOwner == "player" and playerDeck then
        card.sentToDiscard = true
        return deckrules.discardCard(playerDeck, card)
    end

    if card.deckOwner == "champion" and championDeck then
        card.sentToDiscard = true
        return deckrules.discardCard(championDeck, card)
    end

    return nil
end

local function removeCardFromPlay(cardIndex)
    local card = cards[cardIndex]

    if not card then
        return false
    end

    card.destroying = false
    card.destroyed = true
    card.sentToDiscard = true
    warrules.clearCardRollState(cardIndex)

    if selectedAttackerCardIndex == cardIndex then
        selectedAttackerCardIndex = nil
    end

    if hoveredCardIndex == cardIndex then
        hoveredCardIndex = nil
    end

    if expandedGridCardIndex == cardIndex then
        expandedGridCardIndex = nil
    end

    return true
end

local function addObjectiveProgress(objectiveDefinition, amount, slotId)
    local result = objectiveprogressrules.addProgress(objectiveDefinition, amount, {
        slotId = slotId,
        activePrimaryObjective = activePrimaryObjective,
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
        activeWarzone = activeWarzone,
        activePoi = activePoi,
        poiHunterTransformationActive = topsloteffects.isPoiHunterTransformationActive(),
        preloadTopStripAssets = envdraw.preloadTopStripAssets,
        beginWarzoneTransformation = beginWarzoneTransformation,
        beginPoiEmergenceEffect = beginPoiEmergenceEffect,
        beginPoiFlipEffect = beginPoiFlipEffect,
        beginPoiGeneratedCardTransformation = beginPoiGeneratedCardTransformation,
        setActiveWarzone = function(warzoneDefinition)
            activeWarzone = warzoneDefinition
        end,
        setActivePoi = function(poiDefinition)
            activePoi = poiDefinition
        end,
        onControlChanged = function(changedSlotId)
            damageJitters[changedSlotId or "warzone"] = {
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
        return getRandomChampionIntel(activeChampion)
    end

    return objectiverules.getObjective("INT0000")
end

local function getHunterEmphasisInHand()
    local totalEmphasis = 0

    for _, card in ipairs(cards or {}) do
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
    return (activePrimaryObjective and activePrimaryObjective.emphasis or 0) + getHunterEmphasisInHand()
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

        for cardIndex, candidateCard in ipairs(cards) do
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
    return damagerules.clearAllBlocking(cards)
end

dealDamageToChampion = function(amount, suppressFeedback)
    local damageResult = damagerules.dealDamageToChampion(activeChampion, amount)

    if damageResult and damageResult.changed and not suppressFeedback then
        triggerDamageFeedback("champion")

        if damageResult.killed then
            startChampionDestruction()
        end
    end

    return damageResult
end

local function getCenterBiasedOppRowColumn()
    local oppRow = getOppRow()

    if not oppRow then
        return nil
    end

    local center = (#oppRow.cells + 1) / 2
    local bestColumn = nil
    local bestDistance = nil

    for _, cell in ipairs(oppRow.cells) do
        if not isGridRowColumnOccupied("OppRow", cell.column) then
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

local function playChampionHouseCard()
    if not championDeck or not championDeck.cards then
        return nil
    end

    if #championDeck.cards == 0 then
        deckrules.reshuffleDiscardIntoDeck(championDeck)
    end

    if #championDeck.cards == 0 then
        return nil
    end

    local targetColumn = getCenterBiasedOppRowColumn()

    if not targetColumn then
        return nil
    end

    local randomIndex = love.math.random(1, #championDeck.cards)
    local card = table.remove(championDeck.cards, randomIndex)
    local playedCardIndex = #cards + 1

    cards[playedCardIndex] = {
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
    initializeCardHealthState(cards[playedCardIndex])
    cardExpansion[playedCardIndex] = 0
    cardEntranceProgress[playedCardIndex] = 1
    sfxrules.playUnitPlay()

    return cardregistry.getCard(card.setName, card.cardId)
end

local function isChampionPlaySequenceComplete()
    return pendingChampionPlays == 0 and championPlayDelayTimer <= 0
end

local function resolveChampionPlayKeywords(cardDefinition)
    local effect = keywordrules.getEnemyChampionPlayEffect(cardDefinition)

    if effect and effect.playAnotherCard then
        pendingChampionPlays = pendingChampionPlays + 1
        championPlayDelayTimer = CHAMPION_PLAY_DELAY
    end
end

local function enterCurrentPhase()
    local currentPhase = turnrules.getCurrentPhase()

    if currentPhase == turnrules.getSetupPhase() then
        cards = deckrules.assignCardsToHand(playerDeck, envrules.getPlayerHand().slots)
        initializeCardsHealthState(cards)
        addSetupAgents()
        normalizeSetupCardSlots()
    elseif currentPhase == "Start" then
        local gridCardGenerators = {}

        for cardIndex, card in ipairs(cards) do
            if isGridCard(card) and not isCardUnavailable(card) then
                local drawX, drawY, expansionProgress, renderOptions = getCardDrawPosition(card, cardIndex)
                local cardDefinition = cardregistry.getCard(card.setName, card.cardId)
                local methodBadgeCenters = carddraw.getMethodBadgeCenters(card.setName, card.cardId, drawX, drawY, expansionProgress, renderOptions)

                if methodBadgeCenters and #methodBadgeCenters > 0 and cardDefinition and cardDefinition.method then
                    gridCardGenerators[#gridCardGenerators + 1] = {
                        column = card.location.column,
                        methodBadgeCenters = methodBadgeCenters,
                        methodEntries = cardDefinition.method,
                    }
                end
            end
        end

        table.sort(gridCardGenerators, function(a, b)
            return a.column < b.column
        end)

        resourcerules.enterStartPhase(playerJacl, envdraw.getBottomLeftPanelLayout(playerJacl), envdraw.getResourceTrackerLayout(), gridCardGenerators)
        waitingForStartGeneration = true
    elseif currentPhase == "House" then
        local playedCardDefinition = playChampionHouseCard()

        if playedCardDefinition then
            resolveChampionPlayKeywords(playedCardDefinition)
        end
    elseif currentPhase == "Prelude" then
        sfxrules.playPrelude()
        notifications.push("Mobilize!")
    elseif currentPhase == "War" then
        sfxrules.playPhaseEnd()
        warrules.beginPhase(getTopSlotRollTargets(), cards, activePrimaryObjective, activeIntel, activeWarzone)
    elseif currentPhase == "End" then
        warrules.clearBlankResults()
        warrules.clearAllRollResults()
        clearAllBlocking()
        for _, expiredCardIndex in ipairs(keywordrules.decrementEndPhaseKeywords(cards)) do
            removeCardFromPlay(expiredCardIndex)
        end
        drawCardFromPlayerDeck()
        if activePoi
            and activePoi.id
            and activePoi.id:sub(-1) == "B"
            and beginPoiGeneratedCardTransformation(activePoi, activePoi.huntID) then
            return
        end
        addObjectiveProgress(activePrimaryObjective, getEndPhaseObjectiveProgress())
        warrules.resetPlayerCardStates(cards)
        engageRerollCount = 2
        turnrules.advancePhase()
        enterCurrentPhase()
    end
end

getTopSlotRollTargets = function()
    return envdraw.getTopSlotRollTargets(
        turnrules.getCurrentPhase(),
        activeChampion,
        activeWarzone,
        activePoi,
        activePrimaryObjective,
        activeIntel
    )
end

local function completeSetupPhaseIfReady()
    if turnrules.getCurrentPhase() ~= turnrules.getSetupPhase() then
        return
    end

    if getSetupCardCount() > 0 then
        return
    end

    turnrules.beginStartPhase()
    pendingSetupCompletion = true
end

local function canPlayCard(card)
    local cardDefinition = cardregistry.getCard(card.setName, card.cardId)

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

local function payCardCosts(card)
    local cardDefinition = cardregistry.getCard(card.setName, card.cardId)

    if not cardDefinition or not cardDefinition.mcost then
        return true
    end

    return resourcerules.payCosts(cardDefinition.mcost)
end

local function getCardPresentationContext()
    return {
        envdraw = envdraw,
        turnrules = turnrules,
        warrules = warrules,
        cards = cards,
        cardExpansion = cardExpansion,
        cardEntranceProgress = cardEntranceProgress,
        draggedCardIndex = draggedCardIndex,
        dragOffsetX = dragOffsetX,
        dragOffsetY = dragOffsetY,
        selectedAttackerCardIndex = selectedAttackerCardIndex,
        activeChampion = activeChampion,
        activeWarzone = activeWarzone,
        activePoi = activePoi,
        activePrimaryObjective = activePrimaryObjective,
        activeIntel = activeIntel,
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
    return cardzones.isGridRowColumnOccupied(cards, rowId, column, ignoredCardIndex)
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
    return cardzones.getValidDropColumn(mouseX, mouseY, cards, ignoredCardIndex, draggedCard, {
        getPlayerRow = getPlayerRow,
        getOppRow = getOppRow,
        isHunterCard = isHunterCard,
    })
end

local function getDropCell(mouseX, mouseY)
    return cardzones.getDropCell(mouseX, mouseY, cards, draggedCardIndex, {
        getPlayerRow = getPlayerRow,
        getOppRow = getOppRow,
        isHunterCard = isHunterCard,
    })
end

local function getPlayerRowCellAt(mouseX, mouseY)
    return cardzones.getCellAt(getPlayerRow(), mouseX, mouseY)
end

local function getValidJaclSpecialTargetCell(mouseX, mouseY)
    return cardzones.getValidJaclSpecialTargetCell(mouseX, mouseY, cards, {
        getPlayerRow = getPlayerRow,
    })
end

isWarRollSourceActive = function(entityKey)
    if entityKey == "champion" then
        return activeChampion and not activeChampion.hidden and not topsloteffects.isChampionDestructionActive()
    end

    local cardIndex = entityKey and entityKey:match("^card:(%d+)$")

    if cardIndex then
        local sourceCard = cards[tonumber(cardIndex)]
        return sourceCard and not sourceCard.destroying and not sourceCard.destroyed
    end

    return true
end

local function tryResolveEngageClick(hoveredTopSlotId)
    if turnrules.getCurrentPhase() ~= "War" or turnrules.getCurrentWarSubphase() ~= "Engage" then
        return false
    end

    if selectedAttackerCardIndex then
        local attackerCard = cards[selectedAttackerCardIndex]
        local attackerRollState = warrules.getCardRollState(selectedAttackerCardIndex)

        if not attackerCard or not warrules.canCardAttack(selectedAttackerCardIndex) then
            selectedAttackerCardIndex = nil
            return false
        end

        if attackerRollState.targetType == "Blk" then
            if hoveredCardIndex then
                local targetCard = cards[hoveredCardIndex]

                if targetCard
                    and targetCard.location.kind == "grid"
                    and targetCard.location.rowId == "PlayerRow" then
                    addBlockingToCard(targetCard, attackerRollState.damageValue or 0)
                    warrules.consumeCardAttack(selectedAttackerCardIndex)
                    selectedAttackerCardIndex = nil
                end
            end

            return true
        end

        if hoveredCardIndex == selectedAttackerCardIndex then
            selectedAttackerCardIndex = nil
            return true
        end

        if attackerRollState.targetType == "Sab" then
            if hoveredTopSlotId == "objective" and activePrimaryObjective then
                addObjectiveProgress(activePrimaryObjective, -(attackerRollState.damageValue or 0), "objective")
                warrules.consumeCardAttack(selectedAttackerCardIndex)
                selectedAttackerCardIndex = nil
                return true
            elseif hoveredTopSlotId == "intel" and activeIntel then
                addObjectiveProgress(activeIntel, -(attackerRollState.damageValue or 0), "intel")
                warrules.consumeCardAttack(selectedAttackerCardIndex)
                selectedAttackerCardIndex = nil
                return true
            end

            return true
        end

        if attackerRollState.targetType == "WZPlayer" then
            if hoveredTopSlotId == "warzone" and activeWarzone then
                addWarzoneControl(activeWarzone, attackerRollState.damageValue or 0, "warzone")
                warrules.consumeCardAttack(selectedAttackerCardIndex)
                selectedAttackerCardIndex = nil
            elseif hoveredTopSlotId == "poi" and activePoi then
                addWarzoneControl(activePoi, attackerRollState.damageValue or 0, "poi")
                warrules.consumeCardAttack(selectedAttackerCardIndex)
                selectedAttackerCardIndex = nil
            end

            return true
        end

        if hoveredTopSlotId == "champion" then
            dealDamageToChampion(attackerRollState.damageValue or 0)
            warrules.consumeCardAttack(selectedAttackerCardIndex)
            selectedAttackerCardIndex = nil
            return true
        end

        if hoveredCardIndex then
            local targetCard = cards[hoveredCardIndex]

            if targetCard and targetCard.location.kind == "grid" and targetCard.location.rowId == "OppRow" then
                local attackerDefinition = cardregistry.getCard(attackerCard.setName, attackerCard.cardId)
                local targetDefinition = cardregistry.getCard(targetCard.setName, targetCard.cardId)

                if warrules.canAttackTarget(attackerDefinition, targetDefinition) then
                    dealDamageToCard(targetCard, attackerRollState.damageValue or 0)
                    warrules.consumeCardAttack(selectedAttackerCardIndex)
                    selectedAttackerCardIndex = nil
                end

                return true
            end
        end

        return true
    end

    if hoveredCardIndex then
        local hoveredCard = cards[hoveredCardIndex]

        if hoveredCard
            and hoveredCard.location.kind == "grid"
            and hoveredCard.location.rowId == "PlayerRow"
            and warrules.canCardAttack(hoveredCardIndex) then
            local hoveredRollState = warrules.getCardRollState(hoveredCardIndex)

            if hoveredRollState and hoveredRollState.targetType == "Inf" then
                local generatedCardDefinition = cardregistry.getCardById(hoveredRollState.cardgen)

                if generatedCardDefinition
                    and beginInfiltrationEffect(warrules.getCardEntityKey(hoveredCardIndex), generatedCardDefinition, hoveredRollState.damageValue or 0) then
                    warrules.consumeCardAttack(hoveredCardIndex)
                end

                return true
            end

            selectedAttackerCardIndex = hoveredCardIndex
            expandedGridCardIndex = nil
            expandedTopSlotId = nil
            return true
        end
    end

    return false
end

local function isEngagePhase()
    return turnrules.getCurrentPhase() == "War" and turnrules.getCurrentWarSubphase() == "Engage"
end

local function getHoveredPlayerRollBadgeCardIndex(mouseX, mouseY)
    if not isEngagePhase() then
        return nil
    end

    for cardIndex = #cards, 1, -1 do
        local card = cards[cardIndex]
        local rollState = warrules.getCardRollState(cardIndex)

        if card
            and not isCardUnavailable(card)
            and card.location.kind == "grid"
            and card.location.rowId == "PlayerRow"
            and rollState
            and rollState.faceIndex then
            local drawX, drawY, expansionProgress, renderOptions = getCardDrawPosition(card, cardIndex)
            local badgeX, badgeY, badgeWidth, badgeHeight = carddraw.getCardRollBadgeRect(drawX, drawY, renderOptions)

            if mouseX >= badgeX
                and mouseX <= badgeX + badgeWidth
                and mouseY >= badgeY
                and mouseY <= badgeY + badgeHeight then
                return cardIndex
            end
        end
    end

    return nil
end

local function isPointInsideRerollButton(mouseX, mouseY)
    if not isEngagePhase() then
        return false
    end

    local layout = envdraw.getRerollButtonLayout(playerJacl)

    return mouseX >= layout.x
        and mouseX <= layout.x + layout.width
        and mouseY >= layout.y
        and mouseY <= layout.y + layout.height
end

local function buildModalState()
    return {
        playerJacl = playerJacl,
        activePrimaryObjective = activePrimaryObjective,
        isResourceExchangeModalOpen = isResourceExchangeModalOpen,
        isJaclDeckModalOpen = isJaclDeckModalOpen,
        jaclDeckModalScroll = jaclDeckModalScroll,
        jaclDeckPreviewCard = jaclDeckPreviewCard,
        activeDeckModalDeck = activeDeckModalDeck,
        primedJaclSpecial = primedJaclSpecial,
    }
end

local function applyModalState(modalState)
    isResourceExchangeModalOpen = modalState.isResourceExchangeModalOpen
    isJaclDeckModalOpen = modalState.isJaclDeckModalOpen
    jaclDeckPreviewCard = modalState.jaclDeckPreviewCard
    activeDeckModalDeck = modalState.activeDeckModalDeck
    primedJaclSpecial = modalState.primedJaclSpecial
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
    return modals.isPointInsideJaclScratchBadge(mouseX, mouseY, envdraw, playerJacl)
end

local function isPointInsideJaclPortrait(mouseX, mouseY)
    return modals.isPointInsideJaclPortrait(mouseX, mouseY, envdraw, playerJacl)
end

local function primeJaclSpecial(resourceName)
    local modalState = buildModalState()
    local primed = modals.primeJaclSpecial(resourceName, modalState, getModalDeps())
    applyModalState(modalState)
    return primed
end

local function tryUseEngageReroll(mouseX, mouseY)
    if not isPointInsideRerollButton(mouseX, mouseY) or engageRerollCount <= 0 then
        return false
    end

    local rerolledAny = warrules.rerollUnlockedPlayerCards(cards)
    engageRerollCount = math.max(0, engageRerollCount - 1)
    selectedAttackerCardIndex = nil

    if rerolledAny then
        sfxrules.playDice()
    end

    return true
end

getTargetingContext = function()
    return {
        cards = cards,
        hoveredCardIndex = hoveredCardIndex,
        hoveredTopSlotId = hoveredTopSlotId,
        currentPhase = turnrules.getCurrentPhase(),
        displayStates = warrules.getDisplayStates(),
        activePrimaryObjective = activePrimaryObjective,
        activeIntel = activeIntel,
        activeWarzone = activeWarzone,
        activePoi = activePoi,
        getCardRollState = warrules.getCardRollState,
    }
end

local function drawTopSlotHoverTargetBrackets(currentPhase, warzonePreviewState, objectivePreviewPips, intelPreviewPips)
    local slots = envdraw.getTopSlotLayouts(
        currentPhase,
        activeChampion,
        activeWarzone,
        activePoi,
        activePrimaryObjective,
        activeIntel,
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

local function updateHoveredCard()
    local previousHoveredCardIndex = hoveredCardIndex
    hoveredKeyword = nil

    if draggedCardIndex or isResourceExchangeModalOpen or isJaclDeckModalOpen then
        hoveredCardIndex = nil
        hoveredTopSlotId = nil
        hoveredJaclSpecialDefinition = nil
        hoveredJaclSpecialPreviewCard = nil
        return
    end

    local mouseX, mouseY = love.mouse.getPosition()
    hoveredTopSlotId = getHoveredTopSlotId(mouseX, mouseY)
    hoveredJaclSpecialDefinition = nil
    hoveredJaclSpecialPreviewCard = nil

    if hoveredCardIndex then
        local activeCard = cards[hoveredCardIndex]

        if activeCard and not isCardUnavailable(activeCard) then
            local drawX, drawY, expansionProgress, renderOptions = getCardDrawPosition(activeCard, hoveredCardIndex)

            if carddraw.isPointInsideDrawnCard(mouseX, mouseY, drawX, drawY, expansionProgress, nil, renderOptions) then
                hoveredKeyword = carddraw.getHoveredKeyword(activeCard.setName, activeCard.cardId, drawX, drawY, renderOptions, mouseX, mouseY)
                return
            end
        end
    end

    hoveredCardIndex = nil

    for cardIndex = #cards, 1, -1 do
        if not isCardUnavailable(cards[cardIndex]) then
            local drawX, drawY, expansionProgress, renderOptions = getCardDrawPosition(cards[cardIndex], cardIndex)

            if carddraw.isPointInsideDrawnCard(mouseX, mouseY, drawX, drawY, expansionProgress, nil, renderOptions) then
                hoveredCardIndex = cardIndex
                hoveredKeyword = carddraw.getHoveredKeyword(cards[cardIndex].setName, cards[cardIndex].cardId, drawX, drawY, renderOptions, mouseX, mouseY)
                break
            end
        end
    end

    if hoveredCardIndex ~= nil
        and hoveredCardIndex ~= previousHoveredCardIndex
        and cards[hoveredCardIndex]
        and cards[hoveredCardIndex].location.kind == "hand" then
        sfxrules.playHover()
    end

    if not hoveredKeyword and playerJacl and playerJacl.special then
        local hoveredMethodBadge = envdraw.getJaclMethodBadgeAt(mouseX, mouseY, playerJacl)

        if hoveredMethodBadge then
            hoveredJaclSpecialDefinition = specialrules.getSpecial(playerJacl.special)

            if hoveredJaclSpecialDefinition and hoveredJaclSpecialDefinition.spawn then
                hoveredJaclSpecialPreviewCard = cardregistry.getCardById(hoveredJaclSpecialDefinition.spawn)
            end
        end
    end
end

function love.load()
    love.math.setRandomSeed(os.time())
    love.graphics.setBackgroundColor(0.08, 0.08, 0.1)
    love.graphics.setColor(1, 1, 1)
    turnrules.reset()
    resourcerules.reset()
    warrules.reset()
    notifications.reset()
    engageRerollCount = 2
    isResourceExchangeModalOpen = false
    isJaclDeckModalOpen = false
    jaclDeckModalScroll.deck = 0
    jaclDeckModalScroll.discard = 0
    jaclDeckPreviewCard = nil
    activeDeckModalDeck = nil
    primedJaclSpecial = nil
    hoveredJaclSpecialDefinition = nil
    hoveredJaclSpecialPreviewCard = nil
    cardinstances.reset()
    warzonecontrolrules.reset()
    topsloteffects.reset()
    infiltrationrules.reset()
    playerJacl = jaclrules.getJacl(PLAYER_JACL_ID)
    activeChampion = championrules.getChampion(ACTIVE_CHAMPION_ID)
    if activeChampion then
        activeChampion.hidden = false
    end
    activeWarzone = warzonerules.getRandomWarzoneByIdSuffix(RANDOM_WARZONE_SUFFIX) or warzonerules.getWarzone(ACTIVE_WARZONE_ID)
    activePoi = nil
    activePrimaryObjective = getChampionPrimaryObjective(activeChampion)
    activeIntel = getRandomChampionIntel(activeChampion)
    if activeIntel then
        activeIntel.hidden = false
    end
    envdraw.preloadTopStripAssets(activeChampion, activeWarzone, activePoi, activePrimaryObjective, activeIntel)
    preloadWarzoneFamily(activeWarzone)
    playerDeck = playerJacl and deckrules.buildDeck(playerJacl.deckId) or nil
    championDeck = activeChampion and activeChampion.deckId and deckrules.buildDeck(activeChampion.deckId) or nil

    if playerDeck then
        playerDeck.owner = "player"

        for _, deckCard in ipairs(playerDeck.cards) do
            deckCard.deckOwner = "player"
        end
    end

    if championDeck then
        championDeck.owner = "champion"

        for _, deckCard in ipairs(championDeck.cards) do
            deckCard.deckOwner = "champion"
        end
    end

    enterCurrentPhase()
    pendingPhaseEntry = false

    for cardIndex = 1, #cards do
        cardExpansion[cardIndex] = 0
        cardEntranceProgress[cardIndex] = 0
    end
end

local function updateInfiltrationEffect(dt)
    infiltrationrules.update(dt, function(generatedCardDefinition)
        if createGeneratedDeckCardShuffled(generatedCardDefinition) then
            sfxrules.playInfluence()
        end
    end)
end

function love.update(dt)
    local entranceDt = math.min(dt, CARD_ENTRANCE_MAX_DT)

    if hasRenderedFirstFrame and pendingPhaseEntry then
        enterCurrentPhase()
        pendingPhaseEntry = false
    end

    if pendingSetupCompletion then
        enterCurrentPhase()
        pendingSetupCompletion = false
    end

    cardEntranceTimer = cardEntranceTimer + entranceDt
    resourcerules.update(dt)

    if pendingChampionPlays > 0 then
        championPlayDelayTimer = championPlayDelayTimer - dt

        if championPlayDelayTimer <= 0 then
            pendingChampionPlays = pendingChampionPlays - 1

            local playedCardDefinition = playChampionHouseCard()

            if playedCardDefinition then
                resolveChampionPlayKeywords(playedCardDefinition)
            end

            if pendingChampionPlays > 0 then
                championPlayDelayTimer = championPlayDelayTimer + CHAMPION_PLAY_DELAY
            else
                championPlayDelayTimer = 0
            end
        end
    end

    if turnrules.getCurrentPhase() == "House" and isChampionPlaySequenceComplete() then
        turnrules.advancePhase()
        enterCurrentPhase()
    end

    if waitingForStartGeneration and turnrules.getCurrentPhase() == "Start" and resourcerules.isGenerationComplete() then
        waitingForStartGeneration = false
        turnrules.advancePhase()
        enterCurrentPhase()
    end

    for _, card in ipairs(cards) do
        if card.destroying then
            card.destroyElapsed = (card.destroyElapsed or 0) + dt

            if card.destroyElapsed >= DESTRUCTION_DURATION then
                card.destroying = false
                card.destroyed = true
                discardDestroyedCard(card)
            end
        end
    end

    for entityKey, jitter in pairs(damageJitters) do
        jitter.elapsed = jitter.elapsed + dt

        if jitter.elapsed >= jitter.duration then
            damageJitters[entityKey] = nil
        end
    end

    local topSlotEffectEvents = topsloteffects.update(dt)

    if topSlotEffectEvents.championDestroyed and activeChampion then
        activeChampion.hidden = true
    end

    if topSlotEffectEvents.intelDestroyed then
        local defeatedIntel = activeIntel

        if activeIntel then
            activeIntel.hidden = true
        end

        activeIntel = getReplacementIntel(defeatedIntel)

        if activeIntel then
            activeIntel.hidden = false
        end
    end

    if topSlotEffectEvents.objectiveEscalationSwap then
        activePrimaryObjective = topSlotEffectEvents.objectiveEscalationSwap or activePrimaryObjective
    end

    if topSlotEffectEvents.poiHunterTransformationComplete then
        local effect = topSlotEffectEvents.poiHunterTransformationComplete
        local generatedCard = createGeneratedSupportCard(
            effect.generatedCardDefinition,
            effect.targetLocation
        )

        if generatedCard then
            activePoi = nil
        end

        if turnrules.getCurrentPhase() == "End" then
            clearAllBlocking()
            addObjectiveProgress(activePrimaryObjective, getEndPhaseObjectiveProgress())
            warrules.resetPlayerCardStates(cards)
            engageRerollCount = 2
            turnrules.advancePhase()
            enterCurrentPhase()
        end
    end

    updateInfiltrationEffect(dt)

    warrules.update(dt, turnrules.getCurrentPhase())

    local retaliation = warrules.updateRetaliate(dt, turnrules.getCurrentPhase(), turnrules.getCurrentWarSubphase())

    if retaliation then
        if retaliation.targetType == "Obj"
            and retaliation.targetCard
            and retaliation.targetCard.kind == "objective"
            and activePrimaryObjective
            and activePrimaryObjective.id == retaliation.targetCard.objectiveId then
            addObjectiveProgress(activePrimaryObjective, retaliation.damageValue or 0)
        elseif retaliation.targetType == "WZOpp"
            and activeWarzone then
            addWarzoneControl(activeWarzone, -(retaliation.damageValue or 0), "warzone")
        elseif retaliation.targetType == "IntCD"
            and retaliation.targetCard
            and retaliation.targetCard.kind == "intel"
            and activeIntel
            and activeIntel.id == retaliation.targetCard.objectiveId then
            addObjectiveProgress(activeIntel, -(retaliation.damageValue or 0), "intel")
        elseif retaliation.targetType == "Inf"
            and retaliation.targetCard
            and retaliation.targetCard.kind == "deck" then
            local generatedCardDefinition = cardregistry.getCardById(retaliation.cardgen)

            if generatedCardDefinition then
                beginInfiltrationEffect(retaliation.entityKey, generatedCardDefinition, retaliation.damageValue or 0)
            end
        else
            local targetCard = cards[retaliation.targetCardIndex]

            if targetCard and not isCardUnavailable(targetCard) then
                dealDamageToCard(targetCard, retaliation.damageValue or 0)
            end
        end

        warrules.clearEntityRollState(retaliation.entityKey)
    end

    if turnrules.getCurrentPhase() == "War"
        and turnrules.getCurrentWarSubphase() == "Retaliate"
        and warrules.isRetaliationComplete() then
        turnrules.advancePhase()
        enterCurrentPhase()
    end

    if turnrules.isWarRollPhase() and warrules.isRollSequenceComplete() then
        local nextWarSubphase = turnrules.advanceWarSubphase()

        if nextWarSubphase == "Engage" then
            engageRerollCount = 2
            sfxrules.playEngage()
            notifications.push("Engage!")
        end
    end

    notifications.update(dt)
    updateHoveredCard()

    for cardIndex, card in ipairs(cards) do
        local startTime = (cardIndex - 1) * CARD_ENTRANCE_STAGGER
        local entranceTarget = 1
        local expansionTarget = 0
        local entranceProgress = cardEntranceProgress[cardIndex] or 0
        local expansionProgress = cardExpansion[cardIndex] or 0

        if card.location.kind == "hand" and cardEntranceTimer < startTime then
            entranceTarget = 0
        end

        if draggedCardIndex ~= cardIndex then
            if canExpandCard(card) then
                expansionTarget = expandedGridCardIndex == cardIndex and 1 or 0
            else
                expansionTarget = hoveredCardIndex == cardIndex and 1 or 0
            end
        end

        if entranceProgress < entranceTarget then
            cardEntranceProgress[cardIndex] = math.min(entranceTarget, entranceProgress + (entranceDt * CARD_ENTRANCE_SPEED))
        elseif entranceProgress > entranceTarget then
            cardEntranceProgress[cardIndex] = math.max(entranceTarget, entranceProgress - (entranceDt * CARD_ENTRANCE_SPEED))
        end

        if expansionProgress < expansionTarget then
            cardExpansion[cardIndex] = math.min(expansionTarget, expansionProgress + (dt * CARD_HOVER_ANIMATION_SPEED))
        elseif expansionProgress > expansionTarget then
            cardExpansion[cardIndex] = math.max(expansionTarget, expansionProgress - (dt * CARD_HOVER_ANIMATION_SPEED))
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
        local expansionProgress = topSlotExpansion[slotId] or 0
        local expansionTarget = expandedTopSlotId == slotId and 1 or 0

        if expansionProgress < expansionTarget then
            topSlotExpansion[slotId] = math.min(expansionTarget, expansionProgress + (dt * CARD_HOVER_ANIMATION_SPEED))
        elseif expansionProgress > expansionTarget then
            topSlotExpansion[slotId] = math.max(expansionTarget, expansionProgress - (dt * CARD_HOVER_ANIMATION_SPEED))
        end
    end
end

function love.mousepressed(x, y, button)
    if button ~= 1 and button ~= 2 and button ~= 3 then
        return
    end

    local modalState = buildModalState()
    local modalDeps = getModalDeps()

    if modals.handleDeckModalMousePressed(x, y, button, modalState, modalDeps)
        or modals.handleResourceExchangeMousePressed(x, y, button, modalState, modalDeps)
        or modals.handlePrimedSpecialMousePressed(x, y, button, modalState, modalDeps) then
        applyModalState(modalState)
        return
    end

    applyModalState(modalState)

    updateHoveredCard()
    hoveredTopSlotId = getHoveredTopSlotId(x, y)
    local hoveredPlayerRollBadgeCardIndex = getHoveredPlayerRollBadgeCardIndex(x, y)
    local clickedScratchBadge = isPointInsideJaclScratchBadge(x, y)
    local clickedJaclPortrait = isPointInsideJaclPortrait(x, y)
    local clickedJaclMethodBadge = envdraw.getJaclMethodBadgeAt(x, y, playerJacl)

    if button == 1 and tryUseEngageReroll(x, y) then
        return
    end

    if button == 1 and clickedJaclMethodBadge then
        if primeJaclSpecial(clickedJaclMethodBadge.resource) then
            expandedGridCardIndex = nil
            expandedTopSlotId = nil
            hoveredCardIndex = nil
            hoveredKeyword = nil
            return
        end

        sfxrules.playPlayReject()
    end

    if button == 2 and clickedScratchBadge and turnrules.getCurrentPhase() == "Prelude" then
        isResourceExchangeModalOpen = true
        expandedGridCardIndex = nil
        expandedTopSlotId = nil
        hoveredCardIndex = nil
        hoveredKeyword = nil
        return
    end

    if button == 3 and clickedJaclPortrait and turnrules.getCurrentPhase() == "Prelude" then
        local openModalState = buildModalState()
        modals.resetAndOpenJaclDeck(openModalState, playerDeck)
        applyModalState(openModalState)
        expandedGridCardIndex = nil
        expandedTopSlotId = nil
        hoveredCardIndex = nil
        hoveredKeyword = nil
        return
    end

    if button == 3 and hoveredTopSlotId == "champion" and championDeck then
        local openModalState = buildModalState()
        modals.resetAndOpenJaclDeck(openModalState, championDeck)
        applyModalState(openModalState)
        expandedGridCardIndex = nil
        expandedTopSlotId = nil
        hoveredCardIndex = nil
        hoveredKeyword = nil
        return
    end

    if button == 2 and hoveredPlayerRollBadgeCardIndex then
        warrules.toggleCardLock(hoveredPlayerRollBadgeCardIndex)
        return
    end

    if button == 1 and tryResolveEngageClick(hoveredTopSlotId) then
        return
    end

    if expandedGridCardIndex then
        if button == 2 and (hoveredTopSlotId or (hoveredCardIndex and canExpandCard(cards[hoveredCardIndex]))) then
            if hoveredTopSlotId then
                expandedGridCardIndex = nil
                expandedTopSlotId = hoveredTopSlotId
                sfxrules.playCharSelect()
            elseif hoveredPlayerRollBadgeCardIndex then
                return
            elseif hoveredCardIndex == expandedGridCardIndex then
                expandedGridCardIndex = nil
                hoveredCardIndex = nil
            else
                expandedGridCardIndex = hoveredCardIndex
                sfxrules.playCharSelect()
            end

            return
        end

        expandedGridCardIndex = nil
        hoveredCardIndex = nil
        return
    end

    if expandedTopSlotId then
        if button == 2 and (hoveredTopSlotId or (hoveredCardIndex and canExpandCard(cards[hoveredCardIndex]))) then
            if hoveredTopSlotId then
                if hoveredTopSlotId == expandedTopSlotId then
                    expandedTopSlotId = nil
                else
                    expandedTopSlotId = hoveredTopSlotId
                    sfxrules.playCharSelect()
                end
            else
                expandedTopSlotId = nil
                expandedGridCardIndex = hoveredCardIndex
                sfxrules.playCharSelect()
            end

            return
        end

        expandedTopSlotId = nil
        hoveredCardIndex = nil
        return
    end

    if button == 2 then
        if hoveredTopSlotId then
            expandedTopSlotId = hoveredTopSlotId
            sfxrules.playCharSelect()
        elseif hoveredPlayerRollBadgeCardIndex then
            return
        elseif hoveredCardIndex and canExpandCard(cards[hoveredCardIndex]) then
            expandedGridCardIndex = hoveredCardIndex
            sfxrules.playCharSelect()
        end

        return
    end

    if not hoveredCardIndex then
        return
    end

    if cards[hoveredCardIndex].location.kind == "hand" and turnrules.getCurrentPhase() ~= "Prelude" then
        return
    end

    if isGridCard(cards[hoveredCardIndex]) then
        return
    end

    if turnrules.getCurrentPhase() == turnrules.getSetupPhase() and not isSetupCard(cards[hoveredCardIndex]) then
        return
    end

    draggedCardIndex = hoveredCardIndex
    draggedCardOrigin = copyLocation(cards[draggedCardIndex].location)
    expandedGridCardIndex = nil
    expandedTopSlotId = nil

    local drawX, drawY = getCardDrawPosition(cards[draggedCardIndex], draggedCardIndex)
    dragOffsetX = x - drawX
    dragOffsetY = y - drawY
    cardExpansion[draggedCardIndex] = 0
    hoveredCardIndex = nil
end

function love.wheelmoved(_, y)
    local modalState = buildModalState()

    if modals.handleWheelMoved(y, modalState, {
        envdraw = envdraw,
    }) then
        applyModalState(modalState)
    end
end

function love.mousereleased(x, y, button)
    if button ~= 1 or not draggedCardIndex then
        return
    end

    local draggedCard = cards[draggedCardIndex]
    local dropColumn = getValidDropColumn(x, y, draggedCardIndex, draggedCard)

    local canPlayDrop = dropColumn and canPlayCard(draggedCard)

    if canPlayDrop and payCardCosts(draggedCard) then
        local targetRowId = isHunterCard(draggedCard) and "OppRow" or "PlayerRow"
        cards[draggedCardIndex].location = {
            kind = "grid",
            rowId = targetRowId,
            column = dropColumn,
        }
        if draggedCardOrigin.kind == "hand" then
            normalizeHandCardSlots()
        end
        sfxrules.playUnitPlay()
    elseif dropColumn and not canPlayDrop then
        sfxrules.playPlayReject()
        notifications.push("Not Enough Resources")
    else
        cards[draggedCardIndex].location = copyLocation(draggedCardOrigin)
    end

    if draggedCardOrigin.kind == "setup" then
        normalizeSetupCardSlots()
    end

    draggedCardIndex = nil
    draggedCardOrigin = nil
    expandedGridCardIndex = nil
    hoveredCardIndex = nil
    completeSetupPhaseIfReady()
    updateHoveredCard()
end

function love.keypressed(key)
    if key == "escape" then
        local modalState = buildModalState()

        if modals.handleEscapeKey(modalState) then
            applyModalState(modalState)
        else
            love.event.quit()
        end
    elseif key == "space" and turnrules.getCurrentPhase() == "Prelude" then
        turnrules.advancePhase()
        enterCurrentPhase()
    elseif key == "space" and isEngagePhase() then
        selectedAttackerCardIndex = nil
        turnrules.advanceWarSubphase()
        warrules.beginRetaliatePhase(getTopSlotRollTargets(), cards)
    end
end

function love.draw()
    hasRenderedFirstFrame = true
    gamestatedraw.draw({
        turnrules = turnrules,
        warrules = warrules,
        resourcerules = resourcerules,
        envdraw = envdraw,
        carddraw = carddraw,
        topsloteffects = topsloteffects,
        notifications = notifications,
        activeChampion = activeChampion,
        activeWarzone = activeWarzone,
        activePoi = activePoi,
        activePrimaryObjective = activePrimaryObjective,
        activeIntel = activeIntel,
        expandedTopSlotId = expandedTopSlotId,
        topSlotExpansion = topSlotExpansion,
        playerJacl = playerJacl,
        engageRerollCount = engageRerollCount,
        cards = cards,
        hoveredCardIndex = hoveredCardIndex,
        draggedCardIndex = draggedCardIndex,
        expandedGridCardIndex = expandedGridCardIndex,
        isJaclDeckModalOpen = isJaclDeckModalOpen,
        activeDeckModalDeck = activeDeckModalDeck,
        jaclDeckModalScroll = jaclDeckModalScroll,
        jaclDeckPreviewCard = jaclDeckPreviewCard,
        isResourceExchangeModalOpen = isResourceExchangeModalOpen,
        hoveredKeyword = hoveredKeyword,
        hoveredJaclSpecialDefinition = hoveredJaclSpecialDefinition,
        hoveredJaclSpecialPreviewCard = hoveredJaclSpecialPreviewCard,
        primedJaclSpecial = primedJaclSpecial,
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
