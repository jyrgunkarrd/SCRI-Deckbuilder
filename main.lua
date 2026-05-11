local appmodules = require("src.system.appmodules")

envdraw = appmodules.envdraw
carddraw = appmodules.carddraw
cardpresentation = appmodules.cardpresentation
infiltrationdraw = appmodules.infiltrationdraw
targetoverlays = appmodules.targetoverlays
gamestatedraw = appmodules.gamestatedraw
sfxrules = appmodules.sfxrules
abilityrules = appmodules.abilityrules
animationbridge = appmodules.animationbridge
appconfig = appmodules.appconfig
boardquery = appmodules.boardquery
cardinstances = appmodules.cardinstances
cardlifecycle = appmodules.cardlifecycle
cardplaycontroller = appmodules.cardplaycontroller
cardregistry = appmodules.cardregistry
cardzones = appmodules.cardzones
championplayrules = appmodules.championplayrules
championrules = appmodules.championrules
contextassembly = appmodules.contextassembly
contextbuilders = appmodules.contextbuilders
deckrules = appmodules.deckrules
engagerules = appmodules.engagerules
envrules = appmodules.envrules
gameactions = appmodules.gameactions
gamestate = appmodules.gamestate
gamestates = appmodules.gamestates
huntercontroller = appmodules.huntercontroller
infiltrationrules = appmodules.infiltrationrules
jaclrules = appmodules.jaclrules
keywordrules = appmodules.keywordrules
kitrules = appmodules.kitrules
lifecyclebridge = appmodules.lifecyclebridge
notifications = appmodules.notifications
objectiverules = appmodules.objectiverules
phasecontroller = appmodules.phasecontroller
previewrules = appmodules.previewrules
resourcerules = appmodules.resourcerules
spawnbridge = appmodules.spawnbridge
strategyrules = appmodules.strategyrules
syntacrules = appmodules.syntacrules
temporaryeffects = appmodules.temporaryeffects
tomerules = appmodules.tomerules
topsloteffects = appmodules.topsloteffects
trooprules = appmodules.trooprules
turnrules = appmodules.turnrules
uibridge = appmodules.uibridge
warrules = appmodules.warrules
warzonecontrolrules = appmodules.warzonecontrolrules
warzonerules = appmodules.warzonerules
hoverpreview = appmodules.hoverpreview
inputcontroller = appmodules.inputcontroller
modals = appmodules.modals

local setupScenario = gamestate.getDefaultScenario()
local gameState = gamestate.createInitialState()
local appState = gamestates.create()
local getCardDrawPosition
local isGridRowColumnOccupied
local isWarRollSourceActive
local getTargetingContext
local getTopSlotRollTargets
local beginInfiltrationEffect
local addCardKeywordValue
local beginEndPhaseSacrificeSelection
local getNextOpenHandSlot
local preloadWarzoneFamily
local updateInfiltrationEffect
local playHunterAddedSfxForCard
local playHunterAddedSfxForCardDefinition
local playHunterAddedSfxForCards
local isPointInsideJaclPortrait
local isHunterCard
local getCardPresentationContext
local startNewRun
getDamageJitterKeyForCard = lifecyclebridge.getDamageJitterKeyForCard

local function isCardDestroyed(card)
    return cardlifecycle.isCardDestroyed(card)
end

local function isCardUnavailable(card)
    return cardlifecycle.isCardUnavailable(card)
end

startCardDestruction = function(cardIndex)
    return lifecyclebridge.startCardDestruction(lifecyclebridgeState, cardIndex)
end

startChampionDestruction = function()
    lifecyclebridge.startChampionDestruction(lifecyclebridgeState)
end

startIntelDestruction = function()
    lifecyclebridge.startIntelDestruction(lifecyclebridgeState)
end

triggerDamageFeedback = function(entityKey)
    lifecyclebridge.triggerDamageFeedback(lifecyclebridgeState, entityKey)
end

getDamageJitterOffset = function(entityKey)
    return lifecyclebridge.getDamageJitterOffset(lifecyclebridgeState, entityKey)
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

local function beginObjectiveHunterDeckTransformation(objectiveDefinition, generatedCardId)
    return topsloteffects.beginObjectiveHunterDeckTransformation(objectiveDefinition, generatedCardId)
end

local function beginReinforcementHunterDeckTransformation(sourceLocation, sourceCardDefinition, generatedCardId)
    return topsloteffects.beginReinforcementHunterDeckTransformation(sourceLocation, sourceCardDefinition, generatedCardId)
end

local function copyLocation(location)
    return cardinstances.copyLocation(location)
end

local function transformCardAtIndex(cardIndex, cardDefinition)
    local card = cardIndex and gameState.cards[cardIndex] or nil

    if not card or not cardDefinition then
        return false
    end

    releaseAttachedKits(card)

    local replacementCard = cardinstances.create(
        cardDefinition,
        card.instanceId,
        copyLocation(card.location),
        card.deckOwner
    )

    if not replacementCard then
        return false
    end

    replacementCard.deckOwner = card.deckOwner
    cardinstances.initializeHealth(replacementCard)
    gameState.cards[cardIndex] = replacementCard
    warrules.clearCardRollState(cardIndex)
    return true
end

pilotCardWithVehicleAtIndex = function(cardIndex, vehicleDefinition)
    return animationbridge.pilotCardWithVehicleAtIndex(animationbridgeState, cardIndex, vehicleDefinition)
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

getBoardQueryContext = function()
    return {
        state = gameState,
        carddraw = carddraw,
        cardpresentation = cardpresentation,
        cardzones = cardzones,
        envdraw = envdraw,
        turnrules = turnrules,
        warrules = warrules,
        getCardDrawPosition = getCardDrawPosition,
        getCardPresentationContext = getCardPresentationContext,
        getPlayerRow = getPlayerRow,
        getOppRow = getOppRow,
        isCardUnavailable = isCardUnavailable,
        isHunterCard = isHunterCard,
        isPointInsideJaclPortrait = isPointInsideJaclPortrait,
    }
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
    return boardquery.getHoveredTopSlotId(getBoardQueryContext(), mouseX, mouseY)
end

local function getSetupCardCount()
    return cardzones.getSetupCardCount(gameState.cards, isCardDestroyed)
end

local function addSetupAgents()
    for slotIndex, cardId in ipairs(setupScenario.setupAgentIds) do
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
    end
end

function getSetupAgentDeckIds()
    local deckIds = {}

    for _, cardId in ipairs(setupScenario.setupAgentIds) do
        local cardDefinition = cardregistry.getCard("troops", cardId)
        local deckId = cardDefinition and (cardDefinition.deck or cardDefinition.deckId) or nil

        if deckId then
            deckIds[#deckIds + 1] = deckId
        end
    end

    return deckIds
end

local function normalizeSetupCardSlots()
    cardzones.normalizeSetupCardSlots(gameState.cards, isCardDestroyed)
end

local function normalizeHandCardSlots()
    cardzones.normalizeHandCardSlots(gameState.cards, isCardDestroyed)
end

animationbridgeState = {
    gameState = gameState,
    cardregistry = cardregistry,
    envdraw = envdraw,
    warrules = warrules,
    getCardDrawPosition = function(card, cardIndex)
        return getCardDrawPosition(card, cardIndex)
    end,
    getPlayerHandLayout = getPlayerHandLayout,
    copyLocation = copyLocation,
    normalizeHandCardSlots = normalizeHandCardSlots,
    kitReturnFlashDuration = appconfig.KIT_RETURN_FLASH_DURATION,
    kitReturnExpandDuration = appconfig.KIT_RETURN_EXPAND_DURATION,
    kitReturnFlyDuration = appconfig.KIT_RETURN_FLY_DURATION,
    kitReturnTotalDuration = appconfig.KIT_RETURN_TOTAL_DURATION,
    pilotVehicleAnimationDuration = appconfig.PILOT_VEHICLE_ANIMATION_DURATION,
    hunterAutoPlayAnimationDuration = appconfig.HUNTER_AUTO_PLAY_ANIMATION_DURATION,
    mulliganPromptFadeDuration = appconfig.MULLIGAN_PROMPT_FADE_DURATION,
}

spawnbridgeState = {
    gameState = gameState,
    cardzones = cardzones,
    envrules = envrules,
    envdraw = envdraw,
    turnrules = turnrules,
    warrules = warrules,
    deckrules = deckrules,
    resourcerules = resourcerules,
    cardregistry = cardregistry,
    initializeCardHealthState = function(card)
        return initializeCardHealthState(card)
    end,
    isCardDestroyed = isCardDestroyed,
    isCardUnavailable = isCardUnavailable,
    addObjectiveProgress = function(objectiveDefinition, amount, slotId)
        return addObjectiveProgress(objectiveDefinition, amount, slotId)
    end,
    beginObjectiveHunterDeckTransformation = beginObjectiveHunterDeckTransformation,
    beginReinforcementHunterDeckTransformation = beginReinforcementHunterDeckTransformation,
    beginHunterAutoPlayAnimation = function(card, sourceSlotIndex, rowId, column)
        return beginHunterAutoPlayAnimation(card, sourceSlotIndex, rowId, column)
    end,
    playHunterAddedSfxForCard = function(card)
        return playHunterAddedSfxForCard(card)
    end,
    playHunterAddedSfxForCardDefinition = function(cardDefinition)
        return playHunterAddedSfxForCardDefinition(cardDefinition)
    end,
}

lifecyclebridgeState = {
    gameState = gameState,
    appconfig = appconfig,
    cardlifecycle = cardlifecycle,
    contextbuilders = contextbuilders,
    gameactions = gameactions,
    sfxrules = sfxrules,
    topsloteffects = topsloteffects,
    getContextBuildersContext = function()
        return getContextBuildersContext()
    end,
}

function resolveOpeningMulligan()
    if not gameState.mulliganActive or gameState.mulliganResolving then
        return false
    end

    local selectedEntries = {}

    for cardIndex, selected in pairs(gameState.mulliganSelection or {}) do
        local card = selected and gameState.cards[cardIndex] or nil
        local cardDefinition = card and cardregistry.getCard(card.setName, card.cardId) or nil

        if card
            and card.location
            and card.location.kind == "hand"
            and not tomerules.isTomeDefinition(cardDefinition) then
            selectedEntries[#selectedEntries + 1] = {
                cardIndex = cardIndex,
                slotIndex = card.location.slotIndex,
                card = card,
            }
        end
    end

    if #selectedEntries == 0 then
        gameState.mulliganSelection = {}
        gameState.mulliganResolving = true
        gameState.mulliganReturnedCards = {}
        gameState.hoveredCardIndex = nil
        gameState.hoveredKeyword = nil
        gameState.hoveredDiceFace = nil
        gameState.draggedCardIndex = nil
        gameState.draggedCardOrigin = nil
        return true
    end

    table.sort(selectedEntries, function(a, b)
        return a.cardIndex > b.cardIndex
    end)

    local returnedCards = {}
    local replacementSlots = {}

    for _, entry in ipairs(selectedEntries) do
        returnedCards[#returnedCards + 1] = entry.card
        replacementSlots[#replacementSlots + 1] = entry.slotIndex
        entry.card.mulliganOutAnimation = {
            elapsed = 0,
            duration = appconfig.MULLIGAN_REPLACEMENT_ANIMATION_DURATION,
            offset = appconfig.MULLIGAN_REPLACEMENT_SLIDE_OFFSET,
        }
    end

    table.sort(replacementSlots)

    for _, slotIndex in ipairs(replacementSlots) do
        local replacementCard = spawnbridge.drawCardFromPlayerDeck(spawnbridgeState, slotIndex, {
            animate = false,
        })

        if replacementCard then
            replacementCard.mulliganInAnimation = {
                elapsed = 0,
                duration = appconfig.MULLIGAN_REPLACEMENT_ANIMATION_DURATION,
                offset = appconfig.MULLIGAN_REPLACEMENT_SLIDE_OFFSET,
            }
        end
    end

    gameState.mulliganReturnedCards = returnedCards
    gameState.mulliganSelection = {}
    gameState.mulliganResolving = true
    gameState.hoveredCardIndex = nil
    gameState.hoveredKeyword = nil
    gameState.hoveredDiceFace = nil
    gameState.draggedCardIndex = nil
    gameState.draggedCardOrigin = nil
    return true
end

getNextOpenHandSlot = function()
    return spawnbridge.getNextOpenHandSlot(spawnbridgeState)
end

createGeneratedSupportCard = function(cardDefinition, targetLocation)
    return spawnbridge.createGeneratedSupportCard(spawnbridgeState, cardDefinition, targetLocation)
end

createGeneratedDeckCardShuffled = function(cardDefinition)
    return spawnbridge.createGeneratedDeckCardShuffled(spawnbridgeState, cardDefinition)
end

createGeneratedGridCard = function(cardDefinition, rowId, column)
    return spawnbridge.createGeneratedGridCard(spawnbridgeState, cardDefinition, rowId, column)
end

spawnTokensNearCard = function(sourceCardIndex, tokenDefinition, count, options)
    return spawnbridge.spawnTokensNearCard(spawnbridgeState, sourceCardIndex, tokenDefinition, count, options)
end

spawnRandomTokensNearCard = function(sourceCardIndex, tokenDefinitions, count, options)
    return spawnbridge.spawnRandomTokensNearCard(spawnbridgeState, sourceCardIndex, tokenDefinitions, count, options)
end

spawnTokensNearPlayerCard = function(sourceCardIndex, tokenDefinition, count, options)
    return spawnbridge.spawnTokensNearPlayerCard(spawnbridgeState, sourceCardIndex, tokenDefinition, count, options)
end

createOrStackPlayerCacheNearCard = function(sourceCardIndex, cacheDefinition, count)
    return spawnbridge.createOrStackPlayerCacheNearCard(spawnbridgeState, sourceCardIndex, cacheDefinition, count)
end

resolveEnemyEncounter = function(sourceCardIndex, enemyDefinition)
    return spawnbridge.resolveEnemyEncounter(spawnbridgeState, sourceCardIndex, enemyDefinition)
end

drawCardFromPlayerDeck = function(preferredSlotIndex, options)
    return spawnbridge.drawCardFromPlayerDeck(spawnbridgeState, preferredSlotIndex, options)
end

resolveHuntersInHand = function()
    return spawnbridge.resolveHuntersInHand(spawnbridgeState)
end

getSyntacRewardContext = function()
    return {
        state = gameState,
        envdraw = envdraw,
        sfxrules = sfxrules,
        resourcerules = resourcerules,
        drawCardFromPlayerDeck = drawCardFromPlayerDeck,
    }
end

local function resolveSyntacRewardButtons()
    syntacrules.resolveRewardButtons(getSyntacRewardContext())
end

local function clearResolvedSyntacMethodReward()
    syntacrules.clearResolvedMethodReward(gameState)
end

local function clearTemporaryRerollBonus()
    gameState.engageRerollBonus = 0

    if gameState.engageRerollCount > 2 then
        gameState.engageRerollCount = 2
    end
end

local function refundPendingSyntacMethodChoice()
    syntacrules.refundPendingMethodChoice(getSyntacRewardContext())
end

local function chooseSyntacMethodResource(resourceName)
    return syntacrules.chooseMethodResource(resourceName, getSyntacRewardContext())
end

beginKitReturnAnimation = function(hostCard, attachedKit, returningCard)
    return animationbridge.beginKitReturnAnimation(animationbridgeState, hostCard, attachedKit, returningCard)
end

beginHunterAutoPlayAnimation = function(card, sourceSlotIndex, rowId, column)
    return animationbridge.beginHunterAutoPlayAnimation(animationbridgeState, card, sourceSlotIndex, rowId, column)
end

updateKitReturnAnimations = function(dt)
    animationbridge.updateKitReturnAnimations(animationbridgeState, dt)
end

drawKitReturnAnimations = function()
    animationbridge.drawKitReturnAnimations(animationbridgeState)
end

updatePilotVehicleAnimations = function(dt)
    animationbridge.updatePilotVehicleAnimations(animationbridgeState, dt)
end

updateHunterAutoPlayAnimations = function(dt)
    animationbridge.updateHunterAutoPlayAnimations(animationbridgeState, dt)
end

updateMulliganAnimations = function(dt)
    animationbridge.updateMulliganAnimations(animationbridgeState, dt)
end

drawPilotVehicleAnimations = function()
    animationbridge.drawPilotVehicleAnimations(animationbridgeState)
end

drawHunterAutoPlayAnimations = function()
    animationbridge.drawHunterAutoPlayAnimations(animationbridgeState)
end

releaseAttachedKits = function(card)
    return lifecyclebridge.releaseAttachedKits(lifecyclebridgeState, card)
end

removeCardFromPlay = function(cardIndex)
    return lifecyclebridge.removeCardFromPlay(lifecyclebridgeState, cardIndex)
end

expireCardFromPlay = function(cardIndex)
    return lifecyclebridge.expireCardFromPlay(lifecyclebridgeState, cardIndex)
end

discardCardFromPlay = function(cardIndex)
    return lifecyclebridge.discardCardFromPlay(lifecyclebridgeState, cardIndex)
end

getGameActionsContext = function()
    return lifecyclebridge.getGameActionsContext(lifecyclebridgeState)
end

addObjectiveProgress = function(objectiveDefinition, amount, slotId)
    return lifecyclebridge.addObjectiveProgress(lifecyclebridgeState, objectiveDefinition, amount, slotId)
end

canApplyObjectiveProgress = function(objectiveDefinition, amount)
    return lifecyclebridge.canApplyObjectiveProgress(lifecyclebridgeState, objectiveDefinition, amount)
end

addWarzoneControl = function(warzoneDefinition, amount, slotId)
    return lifecyclebridge.addWarzoneControl(lifecyclebridgeState, warzoneDefinition, amount, slotId)
end

local function getChampionPrimaryObjective(championDefinition)
    local objectiveId = championDefinition and championDefinition.PrimaryObjective or setupScenario.activePrimaryObjectiveId
    return objectiverules.getObjective(objectiveId)
end

preloadWarzoneFamily = function(warzoneDefinition)
    warzonecontrolrules.preloadWarzoneFamily(warzoneDefinition, envdraw.preloadTopStripAssets)
end

getHunterControllerContext = function()
    return contextbuilders.getHunterControllerContext(getContextBuildersContext())
end

local function getRandomChampionIntel(championDefinition)
    return huntercontroller.getRandomChampionIntel(championDefinition, objectiverules)
end

local function getReplacementIntel(defeatedIntel)
    return huntercontroller.getReplacementIntel(getHunterControllerContext(), defeatedIntel)
end

local function getEndPhaseObjectiveProgress()
    return huntercontroller.getEndPhaseObjectiveProgress(gameState)
end

local function getRetaliationPhaseObjectiveProgress()
    return huntercontroller.getRetaliationPhaseObjectiveProgress(getHunterControllerContext())
end

initializeCardHealthState = function(card)
    return lifecyclebridge.initializeCardHealthState(lifecyclebridgeState, card)
end

initializeCardsHealthState = function(cardList)
    return lifecyclebridge.initializeCardsHealthState(lifecyclebridgeState, cardList)
end

dealDamageToCard = function(card, amount, suppressFeedback)
    return lifecyclebridge.dealDamageToCard(lifecyclebridgeState, card, amount, suppressFeedback)
end

dealDirectDamageToCard = function(card, amount, suppressFeedback)
    return lifecyclebridge.dealDirectDamageToCard(lifecyclebridgeState, card, amount, suppressFeedback)
end

addBlockingToCard = function(card, amount, options)
    return lifecyclebridge.addBlockingToCard(lifecyclebridgeState, card, amount, options)
end

healCard = function(card, amount)
    return lifecyclebridge.healCard(lifecyclebridgeState, card, amount)
end

clearAllBlocking = function()
    return lifecyclebridge.clearAllBlocking(lifecyclebridgeState)
end

clearEnemyGuardCarryBlocking = function()
    return lifecyclebridge.clearEnemyGuardCarryBlocking(lifecyclebridgeState)
end

dealDamageToChampion = function(amount, suppressFeedback)
    return lifecyclebridge.dealDamageToChampion(lifecyclebridgeState, amount, suppressFeedback)
end

local function getChampionPlayContext()
    return contextbuilders.getChampionPlayContext(getContextBuildersContext())
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
    return contextbuilders.getPhaseControllerDeps(getContextBuildersContext())
end

local function enterCurrentPhase()
    phasecontroller.enterCurrentPhase(gameState, getPhaseControllerDeps())
end

local function completeSetupPhaseIfReady()
    phasecontroller.completeSetupPhaseIfReady(gameState, getPhaseControllerDeps())
end

getCardPlayControllerContext = function()
    return contextbuilders.getCardPlayControllerContext(getContextBuildersContext())
end

local function canPlayCard(card)
    return cardplaycontroller.canPlayCard(card, getCardPlayControllerContext())
end

isHunterCard = function(card)
    return huntercontroller.isHunterCard(getHunterControllerContext(), card)
end

playHunterAddedSfxForCard = function(card)
    huntercontroller.playHunterAddedSfxForCard(getHunterControllerContext(), card)
end

playHunterAddedSfxForCardDefinition = function(cardDefinition)
    huntercontroller.playHunterAddedSfxForCardDefinition(getHunterControllerContext(), cardDefinition)
end

playHunterAddedSfxForCards = function(cards)
    huntercontroller.playHunterAddedSfxForCards(getHunterControllerContext(), cards)
end

local function payCardCosts(card)
    return cardplaycontroller.payCardCosts(card, getCardPlayControllerContext())
end

local function getGridCardAt(mouseX, mouseY, ignoredCardIndex)
    return boardquery.getGridCardAt(getBoardQueryContext(), mouseX, mouseY, ignoredCardIndex)
end

local function getCardAt(mouseX, mouseY, ignoredCardIndex)
    return boardquery.getCardAt(getBoardQueryContext(), mouseX, mouseY, ignoredCardIndex)
end

local function getFullArtAt(mouseX, mouseY)
    return boardquery.getFullArtAt(getBoardQueryContext(), mouseX, mouseY)
end

local function tryOpenFullArt(mouseX, mouseY)
    return uibridge.tryOpenFullArt(uibridgeState, mouseX, mouseY)
end

local function isStrategyCard(card)
    return strategyrules.isStrategyCard(card, {
        cardregistry = cardregistry,
    })
end

local function isStrategyPhase()
    return strategyrules.isStrategyPhase({
        turnrules = turnrules,
    })
end

local function tryUseTomeCard(cardIndex, mouseX, mouseY)
    return cardplaycontroller.tryUseTomeCard(cardIndex, mouseX, mouseY, getCardPlayControllerContext())
end

local function tryPlayStrategyCard(strategyCardIndex, targetCardIndex)
    return cardplaycontroller.tryPlayStrategyCard(strategyCardIndex, targetCardIndex, getCardPlayControllerContext())
end

local function tryPlayKitCard(kitCardIndex, targetCardIndex)
    return cardplaycontroller.tryPlayKitCard(kitCardIndex, targetCardIndex, getCardPlayControllerContext())
end

local function getPendingSelection()
    return cardplaycontroller.getPendingSelection(gameState)
end

local function hasPendingStrategySelection()
    return cardplaycontroller.hasPendingStrategySelection(gameState)
end

local function tryResolvePendingStrategySelection(cardIndex)
    return cardplaycontroller.tryResolvePendingStrategySelection(cardIndex, getCardPlayControllerContext())
end

local function cancelPendingStrategySelection()
    return cardplaycontroller.cancelPendingStrategySelection(getCardPlayControllerContext())
end

local function resolvePlayedTroopCard(troopCardIndex)
    return cardplaycontroller.resolvePlayedTroopCard(troopCardIndex, getCardPlayControllerContext())
end

local function resolveDestroyedTroopCard(troopCardIndex, attachedKitCards)
    return cardplaycontroller.resolveDestroyedTroopCard(troopCardIndex, attachedKitCards, getCardPlayControllerContext())
end

local function resolveKilledEnemyByPlayerCard(attackerCardIndex, targetCardIndex)
    return cardplaycontroller.resolveKilledEnemyByPlayerCard(attackerCardIndex, targetCardIndex, getCardPlayControllerContext())
end

addCardKeywordValue = function(cardIndex, keywordId, amount)
    return cardplaycontroller.addCardKeywordValue(cardIndex, keywordId, amount, getCardPlayControllerContext())
end

getCardLifecycleContext = function()
    return lifecyclebridge.getCardLifecycleContext(lifecyclebridgeState)
end

beginEndPhaseSacrificeSelection = function()
    if gameState.endPhaseSacrificeHandled then
        return gameState.pendingSacrificeSelection ~= nil
    end

    gameState.endPhaseSacrificeHandled = true

    local pendingSelection = trooprules.beginEndPhaseSelection({
        cards = gameState.cards,
        cardregistry = cardregistry,
        isCardUnavailable = isCardUnavailable,
    })

    if not pendingSelection then
        return false
    end

    gameState.pendingSacrificeSelection = pendingSelection
    notifications.push(pendingSelection.prompt or "Choose a troop or token to sacrifice")
    return true
end

getCardPresentationContext = function()
    return contextbuilders.getCardPresentationContext(getContextBuildersContext())
end

local function getCardRenderOptions(card, cardIndex)
    return cardpresentation.getRenderOptions(card, cardIndex, getCardPresentationContext())
end

isGridRowColumnOccupied = function(rowId, column, ignoredCardIndex)
    return boardquery.isGridRowColumnOccupied(getBoardQueryContext(), rowId, column, ignoredCardIndex)
end

function getCardDrawPosition(card, cardIndex)
    return cardpresentation.getDrawPosition(card, cardIndex, getCardPresentationContext())
end

local function getEntitySourceRect(entityKey)
    return boardquery.getEntitySourceRect(getBoardQueryContext(), entityKey)
end

local function getHoverPreviewState()
    return uibridge.getHoverPreviewState(uibridgeState)
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
    return boardquery.getValidDropColumn(getBoardQueryContext(), mouseX, mouseY, ignoredCardIndex, draggedCard)
end

local function getDropCell(mouseX, mouseY)
    return boardquery.getDropCell(getBoardQueryContext(), mouseX, mouseY)
end

local function getPlayerRowCellAt(mouseX, mouseY)
    return boardquery.getPlayerRowCellAt(getBoardQueryContext(), mouseX, mouseY)
end

local function getValidJaclSpecialTargetCell(mouseX, mouseY)
    return boardquery.getValidJaclSpecialTargetCell(getBoardQueryContext(), mouseX, mouseY)
end

local function getCardMethodBadgeTarget(mouseX, mouseY)
    return boardquery.getCardMethodBadgeTarget(getBoardQueryContext(), mouseX, mouseY)
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
    return contextbuilders.getEngageContext(getContextBuildersContext())
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

getSyntacAbilityContext = function()
    return contextbuilders.getSyntacAbilityContext(getContextBuildersContext())
end

local function tryUseSyntacRewardButton(mouseX, mouseY)
    return syntacrules.tryUseRewardButton(mouseX, mouseY, getSyntacAbilityContext())
end

refundPrimedSyntacAbility = function()
    return syntacrules.refundPrimedAbility(gameState)
end

tryPrimeSyntacAbility = function(mouseX, mouseY)
    return syntacrules.tryPrimeAbility(mouseX, mouseY, getSyntacAbilityContext())
end

tryResolvePrimedSyntacAbility = function(cardIndex, topSlotId)
    return syntacrules.tryResolvePrimedAbility(cardIndex, topSlotId, getSyntacAbilityContext())
end

local function getHoveredPlayerRollBadgeCardIndex(mouseX, mouseY)
    return boardquery.getHoveredPlayerRollBadgeCardIndex(mouseX, mouseY, getEngageContext())
end

uibridgeState = {
    gameState = gameState,
    abilityrules = abilityrules,
    boardquery = boardquery,
    contextbuilders = contextbuilders,
    engagerules = engagerules,
    envdraw = envdraw,
    hoverpreview = hoverpreview,
    modals = modals,
    getBoardQueryContext = getBoardQueryContext,
    getContextBuildersContext = function()
        return getContextBuildersContext()
    end,
    getEngageContext = getEngageContext,
    getFullArtAt = getFullArtAt,
}

buildModalState = function()
    return uibridge.buildModalState(uibridgeState)
end

applyModalState = function(modalState)
    uibridge.applyModalState(uibridgeState, modalState)
end

getModalDeps = function()
    return uibridge.getModalDeps(uibridgeState)
end

getHoverPreviewDeps = function()
    return uibridge.getHoverPreviewDeps(uibridgeState)
end

isPointInsideJaclScratchBadge = function(mouseX, mouseY)
    return uibridge.isPointInsideJaclScratchBadge(uibridgeState, mouseX, mouseY)
end

isPointInsideJaclPortrait = function(mouseX, mouseY)
    return uibridge.isPointInsideJaclPortrait(uibridgeState, mouseX, mouseY)
end

primeJaclSpecial = function(resourceName)
    return uibridge.primeJaclSpecial(uibridgeState, resourceName)
end

primeCardMethodAbility = function(cardIndex, resourceName)
    return uibridge.primeCardMethodAbility(uibridgeState, cardIndex, resourceName)
end

tryUseEngageReroll = function(mouseX, mouseY)
    return uibridge.tryUseEngageReroll(uibridgeState, mouseX, mouseY)
end

getHoveredTopSlotRollBadgeId = function(mouseX, mouseY)
    return uibridge.getHoveredTopSlotRollBadgeId(uibridgeState, mouseX, mouseY)
end

local function isAlliedTopSlot(slotId)
    return slotId == "warzone" and gameState.activeWarzone and gameState.activeWarzone.allied == true or false
end

tryCancelSelectedEngageAttacker = function()
    return uibridge.tryCancelSelectedEngageAttacker(uibridgeState)
end

getTargetingContext = function()
    return contextbuilders.getTargetingContext(getContextBuildersContext())
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

function clearHoveredSpawnPreview()
    uibridge.clearHoveredSpawnPreview(uibridgeState)
end

updateHoveredCard = function()
    uibridge.updateHoveredCard(uibridgeState)
end

getInputControllerDeps = function()
    return uibridge.getInputControllerDeps(uibridgeState)
end

contextassemblyState = {
        gameState = gameState,
        abilityrules = abilityrules,
        carddraw = carddraw,
        cardlifecycle = cardlifecycle,
        cardinstances = cardinstances,
        cardregistry = cardregistry,
        cardpresentation = cardpresentation,
        championplayrules = championplayrules,
        deckrules = deckrules,
        envdraw = envdraw,
        envrules = envrules,
        keywordrules = keywordrules,
        previewrules = previewrules,
        kitrules = kitrules,
        modals = modals,
        notifications = notifications,
        objectiverules = objectiverules,
        phasecontroller = phasecontroller,
        resourcerules = resourcerules,
        sfxrules = sfxrules,
        strategyrules = strategyrules,
        temporaryeffects = temporaryeffects,
        tomerules = tomerules,
        topsloteffects = topsloteffects,
        trooprules = trooprules,
        turnrules = turnrules,
        warrules = warrules,
        damageJitterDuration = appconfig.DAMAGE_JITTER_DURATION,
        damageJitterMagnitude = appconfig.DAMAGE_JITTER_MAGNITUDE,
        destructionDuration = appconfig.DESTRUCTION_DURATION,
        addBlockingToCard = addBlockingToCard,
        addCardKeywordValue = addCardKeywordValue,
        addObjectiveProgress = addObjectiveProgress,
        addSetupAgents = addSetupAgents,
        addWarzoneControl = addWarzoneControl,
        applyModalState = applyModalState,
        beginEndPhaseSacrificeSelection = beginEndPhaseSacrificeSelection,
        beginInfiltrationEffect = beginInfiltrationEffect,
        beginKitReturnAnimation = beginKitReturnAnimation,
        beginObjectiveEscalation = beginObjectiveEscalation,
        beginObjectiveHunterDeckTransformation = beginObjectiveHunterDeckTransformation,
        beginReinforcementHunterDeckTransformation = beginReinforcementHunterDeckTransformation,
        beginPoiEmergenceEffect = beginPoiEmergenceEffect,
        beginPoiFlipEffect = beginPoiFlipEffect,
        beginPoiGeneratedCardTransformation = beginPoiGeneratedCardTransformation,
        beginWarzoneTransformation = beginWarzoneTransformation,
        buildModalState = buildModalState,
        canApplyObjectiveProgress = canApplyObjectiveProgress,
        canExpandCard = canExpandCard,
        canOpenPlayerDeckModal = canOpenPlayerDeckModal,
        canPlayCard = canPlayCard,
        cancelPendingStrategySelection = cancelPendingStrategySelection,
        chooseSyntacMethodResource = chooseSyntacMethodResource,
        clearAllBlocking = clearAllBlocking,
        clearEnemyGuardCarryBlocking = clearEnemyGuardCarryBlocking,
        clearResolvedSyntacMethodReward = clearResolvedSyntacMethodReward,
        clearTemporaryRerollBonus = clearTemporaryRerollBonus,
        completeSetupPhaseIfReady = completeSetupPhaseIfReady,
        copyLocation = copyLocation,
        createGeneratedGridCard = createGeneratedGridCard,
        createGeneratedSupportCard = createGeneratedSupportCard,
        createOrStackPlayerCacheNearCard = createOrStackPlayerCacheNearCard,
        dealDamageToCard = dealDamageToCard,
        dealDirectDamageToCard = dealDirectDamageToCard,
        dealDamageToChampion = dealDamageToChampion,
        discardCardFromPlay = discardCardFromPlay,
        drawCardFromPlayerDeck = drawCardFromPlayerDeck,
        drawKitReturnAnimations = drawKitReturnAnimations,
        drawHunterAutoPlayAnimations = drawHunterAutoPlayAnimations,
        enterCurrentPhase = enterCurrentPhase,
        expireCardFromPlay = expireCardFromPlay,
        healCard = healCard,
        initializeCardHealthState = initializeCardHealthState,
        initializeCardsHealthState = initializeCardsHealthState,
        removeCardFromPlay = removeCardFromPlay,
        resolveEnemyEncounter = resolveEnemyEncounter,
        resolveKilledEnemyByPlayerCard = resolveKilledEnemyByPlayerCard,
        resolveHuntersInHand = resolveHuntersInHand,
        resolveOpeningMulligan = resolveOpeningMulligan,
        resolvePlayedTroopCard = resolvePlayedTroopCard,
        resolveDestroyedTroopCard = resolveDestroyedTroopCard,
        resolveSyntacRewardButtons = resolveSyntacRewardButtons,
        spawnRandomTokensNearCard = spawnRandomTokensNearCard,
        spawnTokensNearCard = spawnTokensNearCard,
        spawnTokensNearPlayerCard = spawnTokensNearPlayerCard,
        startCardDestruction = startCardDestruction,
        startChampionDestruction = startChampionDestruction,
        startIntelDestruction = startIntelDestruction,
        triggerDamageFeedback = triggerDamageFeedback,
        transformCardAtIndex = transformCardAtIndex,
        updateInfiltrationEffect = updateInfiltrationEffect,
        getCardDrawPosition = getCardDrawPosition,
        getCardMethodBadgeTarget = getCardMethodBadgeTarget,
        getChampionPlayContext = getChampionPlayContext,
        getCardPresentationContext = getCardPresentationContext,
        getDamageJitterKeyForCard = getDamageJitterKeyForCard,
        getDamageJitterOffset = getDamageJitterOffset,
        getEndPhaseObjectiveProgress = getEndPhaseObjectiveProgress,
        getEntitySourceRect = getEntitySourceRect,
        getGridCardAt = getGridCardAt,
        getHoveredPlayerRollBadgeCardIndex = getHoveredPlayerRollBadgeCardIndex,
        getHoveredTopSlotId = getHoveredTopSlotId,
        getHoveredTopSlotRollBadgeId = getHoveredTopSlotRollBadgeId,
        getInputControllerDeps = getInputControllerDeps,
        getModalDeps = getModalDeps,
        getNextOpenHandSlot = getNextOpenHandSlot,
        getOppRow = getOppRow,
        getPendingSelection = getPendingSelection,
        getPhaseControllerDeps = getPhaseControllerDeps,
        getPlayerHandLayout = getPlayerHandLayout,
        getReplacementIntel = getReplacementIntel,
        getRetaliationPhaseObjectiveProgress = getRetaliationPhaseObjectiveProgress,
        getSetupCardCount = getSetupCardCount,
        getTargetingContext = getTargetingContext,
        getTopSlotRollTargets = getTopSlotRollTargets,
        getValidDropColumn = getValidDropColumn,
        getValidJaclSpecialTargetCell = getValidJaclSpecialTargetCell,
        getPlayerRowCellAt = getPlayerRowCellAt,
        hasPendingStrategySelection = hasPendingStrategySelection,
        isAlliedTopSlot = isAlliedTopSlot,
        isCardDestroyed = isCardDestroyed,
        isCardUnavailable = isCardUnavailable,
        isEngagePhase = isEngagePhase,
        isGridCard = isGridCard,
        isGridRowColumnOccupied = isGridRowColumnOccupied,
        isHunterCard = isHunterCard,
        isPointInsideJaclPortrait = isPointInsideJaclPortrait,
        isPointInsideJaclScratchBadge = isPointInsideJaclScratchBadge,
        isSetupCard = isSetupCard,
        isStrategyCard = isStrategyCard,
        isStrategyPhase = isStrategyPhase,
        isWarRollSourceActive = isWarRollSourceActive,
        normalizeHandCardSlots = normalizeHandCardSlots,
        normalizeSetupCardSlots = normalizeSetupCardSlots,
        payCardCosts = payCardCosts,
        pilotCardWithVehicleAtIndex = pilotCardWithVehicleAtIndex,
        playHunterAddedSfxForCards = playHunterAddedSfxForCards,
        primeCardMethodAbility = primeCardMethodAbility,
        primeJaclSpecial = primeJaclSpecial,
        refundPendingSyntacMethodChoice = refundPendingSyntacMethodChoice,
        refundPrimedSyntacAbility = refundPrimedSyntacAbility,
        tryCancelSelectedEngageAttacker = tryCancelSelectedEngageAttacker,
        tryOpenFullArt = tryOpenFullArt,
        tryPlayKitCard = tryPlayKitCard,
        tryPlayStrategyCard = tryPlayStrategyCard,
        tryPrimeSyntacAbility = tryPrimeSyntacAbility,
        tryResolveEngageClick = tryResolveEngageClick,
        tryResolvePendingStrategySelection = tryResolvePendingStrategySelection,
        tryResolvePrimedSyntacAbility = tryResolvePrimedSyntacAbility,
        tryUseEngageReroll = tryUseEngageReroll,
        tryUseSyntacRewardButton = tryUseSyntacRewardButton,
        tryUseTomeCard = tryUseTomeCard,
        updateHoveredCard = updateHoveredCard,
    }

getContextBuildersContext = function()
    return contextassembly.build(contextbuilders, contextassemblyState)
end

startNewRun = function(saveSlotId, saveTimestamp)
    gamestate.resetForNewRun(gameState)
    gameState.saveSlotId = saveSlotId
    gameState.saveTimestamp = saveTimestamp
    turnrules.reset()
    resourcerules.reset()
    warrules.reset()
    notifications.reset()
    cardinstances.reset()
    warzonecontrolrules.reset()
    topsloteffects.reset()
    infiltrationrules.reset()
    gameState.playerJacl = jaclrules.getJacl(setupScenario.playerJaclId)
    gameState.activeChampion = championrules.getChampion(setupScenario.activeChampionId)
    if gameState.activeChampion then
        gameState.activeChampion.hidden = false
    end
    gameState.activeWarzone = warzonerules.getRandomWarzoneByIdSuffix(setupScenario.randomWarzoneSuffix)
        or warzonerules.getWarzone(setupScenario.activeWarzoneId)
    gameState.activePoi = nil
    gameState.activePrimaryObjective = getChampionPrimaryObjective(gameState.activeChampion)
    gameState.activeIntel = getRandomChampionIntel(gameState.activeChampion)
    if gameState.activeIntel then
        gameState.activeIntel.hidden = false
    end
    envdraw.preloadTopStripAssets(gameState.activeChampion, gameState.activeWarzone, gameState.activePoi, gameState.activePrimaryObjective, gameState.activeIntel)
    preloadWarzoneFamily(gameState.activeWarzone)
    gameState.playerDeck = gameState.playerJacl
        and deckrules.buildDeckWithAdditionalDecks(gameState.playerJacl.deckId, getSetupAgentDeckIds())
        or nil
    gameState.championDeck = gameState.activeChampion
        and gameState.activeChampion.deckId
        and deckrules.buildDeckWithAdditionalDecks(gameState.activeChampion.deckId, setupScenario.championAdditionalDeckIds or {})
        or nil

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

        if #(setupScenario.championAdditionalDeckIds or {}) > 0 then
            deckrules.shuffleDeck(gameState.championDeck)
        end
    end

    enterCurrentPhase()
    gameState.pendingPhaseEntry = false

    for cardIndex = 1, #gameState.cards do
        gameState.cardExpansion[cardIndex] = 0
        gameState.cardEntranceProgress[cardIndex] = 0
    end
end

startMissionFromWorldNode = function(payload)
    if not payload or not payload.jaclId or not payload.championId or not payload.warzoneId then
        return false
    end

    setupScenario.playerJaclId = payload.jaclId
    setupScenario.setupAgentIds = {}

    for _, agentId in ipairs(payload.agentIds or {}) do
        setupScenario.setupAgentIds[#setupScenario.setupAgentIds + 1] = agentId
    end

    setupScenario.activeChampionId = payload.championId
    setupScenario.activeWarzoneId = payload.warzoneId
    setupScenario.randomWarzoneSuffix = nil
    setupScenario.championAdditionalDeckIds = {}

    for _, deckId in ipairs(payload.championAdditionalDeckIds or {}) do
        setupScenario.championAdditionalDeckIds[#setupScenario.championAdditionalDeckIds + 1] = deckId
    end

    startNewRun(appState.selectedSaveSlot, appState.selectedSaveTimestamp)
    appState.current = "MissionStage"
    appState.worldMapDeckModal = nil
    appState.worldMapObjectivePreviewModal = nil
    appState.worldMapNodePlayButtonTarget = nil
    appState.worldMapNodePlayButtonTargets = nil
    appState.worldToMissionTransition = {
        elapsed = 0,
        duration = appconfig.WORLD_TO_MISSION_TRANSITION_DURATION,
        seed = love.math.random(1, 1000000),
    }

    return true
end

function love.load()
    love.math.setRandomSeed(os.time())
    love.graphics.setBackgroundColor(0.08, 0.08, 0.1)
    love.graphics.setColor(1, 1, 1)
end

updateInfiltrationEffect = function(dt)
    infiltrationrules.update(dt, function(generatedCardDefinition)
        if createGeneratedDeckCardShuffled(generatedCardDefinition) then
            sfxrules.playInfluence()
        end
    end)
end

contextassemblyState.updateInfiltrationEffect = updateInfiltrationEffect

function love.update(dt)
    if appState.worldToMissionTransition then
        local transition = appState.worldToMissionTransition

        transition.elapsed = transition.elapsed + (dt or 0)

        if transition.elapsed >= transition.duration then
            appState.worldToMissionTransition = nil
            appState.hoveredWorldMapNode = nil
            appState.pinnedWorldMapNode = nil
        end

        return
    end

    if gamestates.isFileSelect(appState) then
        gamestates.updateFileSelect(appState, dt, {
            sfxrules = sfxrules,
        })
        return
    end

    if gamestates.isWorldStage(appState) then
        gamestates.updateWorldStage(appState, dt, {
            sfxrules = sfxrules,
        })
        return
    end

    local entranceDt = math.min(dt, appconfig.CARD_ENTRANCE_MAX_DT)

    gameState.cardEntranceTimer = gameState.cardEntranceTimer + entranceDt
    resourcerules.update(dt)
    updateKitReturnAnimations(dt)
    updatePilotVehicleAnimations(dt)
    updateHunterAutoPlayAnimations(dt)
    updateMulliganAnimations(dt)

    cardlifecycle.updateDestroyedCards(getCardLifecycleContext(), dt)
    cardlifecycle.updateIncapRecoveryAnimations(getCardLifecycleContext(), dt)

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
        local startTime = (cardIndex - 1) * appconfig.CARD_ENTRANCE_STAGGER
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
            gameState.cardEntranceProgress[cardIndex] = math.min(entranceTarget, entranceProgress + (entranceDt * appconfig.CARD_ENTRANCE_SPEED))
        elseif entranceProgress > entranceTarget then
            gameState.cardEntranceProgress[cardIndex] = math.max(entranceTarget, entranceProgress - (entranceDt * appconfig.CARD_ENTRANCE_SPEED))
        end

        if expansionProgress < expansionTarget then
            gameState.cardExpansion[cardIndex] = math.min(expansionTarget, expansionProgress + (dt * appconfig.CARD_HOVER_ANIMATION_SPEED))
        elseif expansionProgress > expansionTarget then
            gameState.cardExpansion[cardIndex] = math.max(expansionTarget, expansionProgress - (dt * appconfig.CARD_HOVER_ANIMATION_SPEED))
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
            gameState.topSlotExpansion[slotId] = math.min(expansionTarget, expansionProgress + (dt * appconfig.CARD_HOVER_ANIMATION_SPEED))
        elseif expansionProgress > expansionTarget then
            gameState.topSlotExpansion[slotId] = math.max(expansionTarget, expansionProgress - (dt * appconfig.CARD_HOVER_ANIMATION_SPEED))
        end
    end
end

function love.mousepressed(x, y, button)
    if appState.worldToMissionTransition then
        return
    end

    if gamestates.isFileSelect(appState) then
        gamestates.mousepressedFileSelect(appState, x, y, button, {
            sfxrules = sfxrules,
        })
        return
    end

    if gamestates.isWorldStage(appState) then
        gamestates.mousepressedWorldStage(appState, x, y, button, {
            sfxrules = sfxrules,
            startMissionFromWorldNode = startMissionFromWorldNode,
        })
        return
    end

    inputcontroller.mousepressed(gameState, getInputControllerDeps(), x, y, button)
end

function love.wheelmoved(_, y)
    if appState.worldToMissionTransition then
        return
    end

    if gamestates.isFileSelect(appState) then
        return
    end

    if gamestates.isWorldStage(appState) then
        gamestates.wheelmovedWorldStage(appState, _, y)
        return
    end

    inputcontroller.wheelmoved(gameState, getInputControllerDeps(), _, y)
end

function love.mousereleased(x, y, button)
    if appState.worldToMissionTransition then
        return
    end

    if gamestates.isFileSelect(appState) or gamestates.isWorldStage(appState) then
        return
    end

    inputcontroller.mousereleased(gameState, getInputControllerDeps(), x, y, button)
end

function love.keypressed(key)
    if appState.worldToMissionTransition then
        return
    end

    if gamestates.isFileSelect(appState) then
        gamestates.keypressedFileSelect(appState, key)
        return
    end

    if gamestates.isWorldStage(appState) then
        gamestates.keypressedWorldStage(appState, key)
        return
    end

    inputcontroller.keypressed(gameState, getInputControllerDeps(), key)
end

function drawMissionStage()
    gameState.hasRenderedFirstFrame = true
    gamestatedraw.draw({
        turnrules = turnrules,
        warrules = warrules,
        resourcerules = resourcerules,
        cardregistry = cardregistry,
        previewrules = previewrules,
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
        syntacRewardButtons = gameState.syntacRewardButtons,
        getRetaliationPhaseObjectiveProgress = getRetaliationPhaseObjectiveProgress,
        cards = gameState.cards,
        hoveredCardIndex = gameState.hoveredCardIndex,
        draggedCardIndex = gameState.draggedCardIndex,
        expandedGridCardIndex = gameState.expandedGridCardIndex,
        pendingSelectionPrompt = (
                gameState.pendingSacrificeSelection
                and (gameState.pendingSacrificeSelection.prompt or "Choose a troop or token to sacrifice")
            )
            or (
                gameState.pendingHandLimitDiscardSelection
                and (gameState.pendingHandLimitDiscardSelection.prompt or "Hand limit exceeded. Choose one card in hand to discard.")
            )
            or nil,
        hoverPreview = getHoverPreviewState(),
        isJaclDeckModalOpen = gameState.isJaclDeckModalOpen,
        activeDeckModalDeck = gameState.activeDeckModalDeck,
        fullArtImage = gameState.fullArtImage,
        jaclDeckModalScroll = gameState.jaclDeckModalScroll,
        jaclDeckPreviewCard = gameState.jaclDeckPreviewCard,
        isResourceExchangeModalOpen = gameState.isResourceExchangeModalOpen,
        isSyntacMethodModalOpen = gameState.isSyntacMethodModalOpen,
        primedSyntacAbility = gameState.primedSyntacAbility,
        hoveredKeyword = gameState.hoveredKeyword,
        hoveredDiceFace = gameState.hoveredDiceFace,
        hoveredJaclSpecialDefinition = gameState.hoveredJaclSpecialDefinition,
        hoveredJaclSpecialPreviewCard = gameState.hoveredJaclSpecialPreviewCard,
        hoveredTomeSpawnPreviewCard = gameState.hoveredTomeSpawnPreviewCard,
        hoveredTomeSpawnPreviewCardEntries = gameState.hoveredTomeSpawnPreviewCardEntries,
        hoveredTomeSpawnPreviewCards = gameState.hoveredTomeSpawnPreviewCards,
        hoveredTomeSpawnPreviewLabel = gameState.hoveredTomeSpawnPreviewLabel,
        hoveredTomeSpawnPreviewCardIndex = gameState.hoveredTomeSpawnPreviewCardIndex,
        hoveredCardAbilityPreviewCardEntries = gameState.hoveredCardAbilityPreviewCardEntries,
        hoveredCardAbilityPreviewCards = gameState.hoveredCardAbilityPreviewCards,
        hoveredCardAbilityPreviewLabel = gameState.hoveredCardAbilityPreviewLabel,
        hoveredCardAbilityPreviewDefinition = gameState.hoveredCardAbilityPreviewDefinition,
        hoveredCardAbilityPreviewCardIndex = gameState.hoveredCardAbilityPreviewCardIndex,
        mulliganActive = gameState.mulliganActive,
        mulliganSelection = gameState.mulliganSelection,
        mulliganPromptAlpha = gameState.mulliganPromptAlpha,
        isTomeCard = function(card)
            return tomerules.isTomeCard(card, {
                cardregistry = cardregistry,
            })
        end,
        primedActivatedAbility = gameState.primedActivatedAbility,
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
        drawKitReturnAnimations = drawKitReturnAnimations,
        drawHunterAutoPlayAnimations = drawHunterAutoPlayAnimations,
        drawPilotVehicleAnimations = drawPilotVehicleAnimations,
    })
end

function drawWorldToMissionTransition(transition)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local progress = math.max(0, math.min(1, (transition.elapsed or 0) / math.max(0.01, transition.duration or 1)))
    local easedProgress = progress * progress * (3 - (2 * progress))
    local scanlineY = math.floor(windowHeight * easedProgress)
    local burnBandHeight = appconfig.WORLD_TO_MISSION_BURN_BAND_HEIGHT
    local burnTop = math.max(0, scanlineY - math.floor(burnBandHeight * 0.42))
    local burnBottom = math.min(windowHeight, scanlineY + math.floor(burnBandHeight * 0.58))

    gamestates.drawWorldStage(appState)

    if scanlineY > 0 then
        love.graphics.setScissor(0, 0, windowWidth, scanlineY)
        drawMissionStage()
        love.graphics.setScissor()
    end

    love.graphics.setColor(0.01, 0.01, 0.015, 0.32 * (1 - progress))
    love.graphics.rectangle("fill", 0, math.max(0, scanlineY - 2), windowWidth, windowHeight - scanlineY + 2)

    love.graphics.setColor(0.906, 0.102, 0.176, 0.88)
    love.graphics.rectangle("fill", 0, scanlineY - 1, windowWidth, 2)
    love.graphics.setColor(1, 0.84, 0.58, 0.78)
    love.graphics.rectangle("fill", 0, scanlineY - 3, windowWidth, 1)

    local noiseSeed = (transition.seed or 1) + math.floor((transition.elapsed or 0) * 60)
    local function noiseValue(index)
        return (math.sin((noiseSeed + index) * 12.9898) * 43758.5453) % 1
    end

    local function noiseRange(index, minValue, maxValue)
        return minValue + ((maxValue - minValue) * noiseValue(index))
    end

    for stripIndex = 1, appconfig.WORLD_TO_MISSION_BURN_STRIP_COUNT do
        local stripWidth = math.floor(noiseRange(stripIndex * 5, 8, 34))
        local stripHeight = math.floor(noiseRange((stripIndex * 5) + 1, 2, 12))
        local stripX = math.floor(noiseRange((stripIndex * 5) + 2, -16, math.max(1, windowWidth)))
        local stripY = math.floor(noiseRange((stripIndex * 5) + 3, burnTop, math.max(burnTop, burnBottom)))
        local alpha = noiseValue((stripIndex * 5) + 4) * 0.48 * (1 - (progress * 0.35))

        if noiseValue((stripIndex * 5) + 5) < 0.62 then
            love.graphics.setColor(0.906, 0.102, 0.176, alpha)
        else
            love.graphics.setColor(1, 0.82, 0.42, alpha)
        end

        love.graphics.rectangle("fill", stripX, stripY, stripWidth, stripHeight)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function love.draw()
    if appState.worldToMissionTransition then
        drawWorldToMissionTransition(appState.worldToMissionTransition)
        return
    end

    if gamestates.isFileSelect(appState) then
        gamestates.drawFileSelect(appState)
        return
    end

    if gamestates.isWorldStage(appState) then
        gamestates.drawWorldStage(appState)
        return
    end

    drawMissionStage()
end
