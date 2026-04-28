local envdraw = require("src.render.envdraw")
local carddraw = require("src.render.carddraw")
cardanimations = require("src.render.cardanimations")
local cardpresentation = require("src.render.cardpresentation")
local infiltrationdraw = require("src.render.infiltrationdraw")
local sfxrules = require("src.audio.sfxrules")
local cardregistry = require("src.system.cardregistry")
local cardinstances = require("src.system.cardinstances")
cardlifecycle = require("src.system.cardlifecycle")
local cardzones = require("src.system.cardzones")
local championplayrules = require("src.system.championplayrules")
local championrules = require("src.system.championrules")
local engagerules = require("src.system.engagerules")
local envrules = require("src.system.envrules")
local notifications = require("src.system.notifications")
local objectiverules = require("src.system.objectiverules")
local phasecontroller = require("src.system.phasecontroller")
local turnrules = require("src.system.turnrules")
local warzonerules = require("src.system.warzonerules")
local warzonecontrolrules = require("src.system.warzonecontrolrules")
local topsloteffects = require("src.system.topsloteffects")
local deckrules = require("src.system.deckrules")
local jaclrules = require("src.system.jaclrules")
local keywordrules = require("src.system.keywordrules")
local temporaryeffects = require("src.system.temporaryeffects")
local kitrules = require("src.system.kitrules")
local resourcerules = require("src.system.resourcerules")
local abilityrules = require("src.system.abilityrules")
local infiltrationrules = require("src.system.infiltrationrules")
local strategyrules = require("src.system.strategyrules")
local tomerules = require("src.system.tomerules")
local trooprules = require("src.system.trooprules")
local previewrules = require("src.system.previewrules")
syntacrules = require("src.system.syntacrules")
spawncontroller = require("src.system.spawncontroller")
gameactions = require("src.system.gameactions")
boardquery = require("src.system.boardquery")
huntercontroller = require("src.system.huntercontroller")
cardplaycontroller = require("src.system.cardplaycontroller")
contextbuilders = require("src.system.contextbuilders")
local targetoverlays = require("src.render.targetoverlays")
local gamestatedraw = require("src.render.gamestate_draw")
local inputcontroller = require("src.ui.inputcontroller")
local modals = require("src.ui.modals")
hoverpreview = require("src.ui.hoverpreview")
local warrules = require("src.system.warrules")

local CARD_HOVER_ANIMATION_SPEED = 10
local CARD_ENTRANCE_SPEED = 6
local CARD_ENTRANCE_STAGGER = 0.1
local CARD_ENTRANCE_MAX_DT = 1 / 60
local DAMAGE_JITTER_DURATION = 0.28
local DAMAGE_JITTER_MAGNITUDE = 7
local DESTRUCTION_DURATION = 0.6
local KIT_RETURN_FLASH_DURATION = 0.1
local KIT_RETURN_EXPAND_DURATION = 0.14
local KIT_RETURN_FLY_DURATION = 0.28
local KIT_RETURN_TOTAL_DURATION = KIT_RETURN_FLASH_DURATION + KIT_RETURN_EXPAND_DURATION + KIT_RETURN_FLY_DURATION
local PILOT_VEHICLE_ANIMATION_DURATION = 0.58
MULLIGAN_PROMPT_FADE_DURATION = 0.16
MULLIGAN_REPLACEMENT_ANIMATION_DURATION = 0.28
MULLIGAN_REPLACEMENT_SLIDE_OFFSET = 96
local PLAYER_JACL_ID = "JACL001"
local ACTIVE_CHAMPION_ID = "CH0001"
local ACTIVE_WARZONE_ID = "WZ0001"
local RANDOM_WARZONE_SUFFIX = "B"
local ACTIVE_POI_ID = "POI0001"
local ACTIVE_PRIMARY_OBJECTIVE_ID = "PRIMOBJ0001"
SETUP_AGENT_IDS = {
    "AGT0001",
    "AGT0002",
}

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
    hoveredDiceFace = nil,
    expandedGridCardIndex = nil,
    expandedTopSlotId = nil,
    selectedAttackerCardIndex = nil,
    selectedAttackerTopSlotId = nil,
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
    engageRerollBonus = 0,
    syntacCount = 0,
    syntacRewardButtons = {},
    syntacMethodRewardAnimating = false,
    isSyntacMethodModalOpen = false,
    syntacPendingMethodChoicePaid = false,
    primedSyntacAbility = nil,
    isResourceExchangeModalOpen = false,
    isJaclDeckModalOpen = false,
    jaclDeckModalScroll = {
        deck = 0,
        discard = 0,
    },
    jaclDeckPreviewCard = nil,
    activeDeckModalDeck = nil,
    primedActivatedAbility = nil,
    fullArtImage = nil,
    hoveredJaclSpecialDefinition = nil,
    hoveredJaclSpecialPreviewCard = nil,
    hoveredTomeSpawnPreviewCard = nil,
    hoveredTomeSpawnPreviewCards = nil,
    hoveredTomeSpawnPreviewLabel = nil,
    hoveredTomeSpawnPreviewCardIndex = nil,
    hoveredCardAbilityPreviewCards = nil,
    hoveredCardAbilityPreviewLabel = nil,
    hoveredCardAbilityPreviewDefinition = nil,
    hoveredCardAbilityPreviewCardIndex = nil,
    pendingStrategySelection = nil,
    pendingSacrificeSelection = nil,
    endPhaseSacrificeHandled = false,
    mulliganActive = false,
    mulliganCompleted = false,
    mulliganSelection = {},
    mulliganResolving = false,
    mulliganPromptAlpha = 0,
    kitReturnAnimations = {},
    pilotVehicleAnimations = {},
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
local releaseAttachedKits
local getCardLifecycleContext
local function getDamageJitterKeyForCard(cardIndex)
    return "card:" .. tostring(cardIndex)
end

local function isCardDestroyed(card)
    return cardlifecycle.isCardDestroyed(card)
end

local function isCardUnavailable(card)
    return cardlifecycle.isCardUnavailable(card)
end

local function startCardDestruction(cardIndex)
    return cardlifecycle.startCardDestruction(getCardLifecycleContext(), cardIndex)
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

local function beginObjectiveHunterDeckTransformation(objectiveDefinition, generatedCardId)
    return topsloteffects.beginObjectiveHunterDeckTransformation(objectiveDefinition, generatedCardId)
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

local getCardAnimationContext

local function pilotCardWithVehicleAtIndex(cardIndex, vehicleDefinition)
    return cardanimations.pilotCardWithVehicleAtIndex(getCardAnimationContext(), cardIndex, vehicleDefinition)
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
    for slotIndex, cardId in ipairs(SETUP_AGENT_IDS) do
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

    for _, cardId in ipairs(SETUP_AGENT_IDS) do
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

getCardAnimationContext = function()
    return {
        cards = gameState.cards,
        playerDeck = gameState.playerDeck,
        kitReturnAnimations = gameState.kitReturnAnimations,
        pilotVehicleAnimations = gameState.pilotVehicleAnimations,
        mulliganActive = gameState.mulliganActive,
        mulliganResolving = gameState.mulliganResolving,
        mulliganPromptAlpha = gameState.mulliganPromptAlpha,
        mulliganReturnedCards = gameState.mulliganReturnedCards,
        mulliganCompleted = gameState.mulliganCompleted,
        cardregistry = cardregistry,
        warrules = warrules,
        getCardDrawPosition = getCardDrawPosition,
        getPlayerHandLayout = getPlayerHandLayout,
        copyLocation = copyLocation,
        normalizeHandCardSlots = normalizeHandCardSlots,
        kitReturnFlashDuration = KIT_RETURN_FLASH_DURATION,
        kitReturnExpandDuration = KIT_RETURN_EXPAND_DURATION,
        kitReturnFlyDuration = KIT_RETURN_FLY_DURATION,
        kitReturnTotalDuration = KIT_RETURN_TOTAL_DURATION,
        pilotVehicleAnimationDuration = PILOT_VEHICLE_ANIMATION_DURATION,
        mulliganPromptFadeDuration = MULLIGAN_PROMPT_FADE_DURATION,
    }
end

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
            duration = MULLIGAN_REPLACEMENT_ANIMATION_DURATION,
            offset = MULLIGAN_REPLACEMENT_SLIDE_OFFSET,
        }
    end

    table.sort(replacementSlots)

    for _, slotIndex in ipairs(replacementSlots) do
        local replacementCard = deckrules.drawCardToHand(gameState.playerDeck, slotIndex)

        if replacementCard then
            replacementCard.deckOwner = "player"
            replacementCard.mulliganInAnimation = {
                elapsed = 0,
                duration = MULLIGAN_REPLACEMENT_ANIMATION_DURATION,
                offset = MULLIGAN_REPLACEMENT_SLIDE_OFFSET,
            }
            gameState.cards[#gameState.cards + 1] = replacementCard
            initializeCardHealthState(replacementCard)
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
    return spawncontroller.getNextOpenHandSlot(getSpawnControllerContext())
end

getSpawnControllerContext = function()
    return {
        state = gameState,
        cardzones = cardzones,
        envrules = envrules,
        envdraw = envdraw,
        turnrules = turnrules,
        warrules = warrules,
        deckrules = deckrules,
        cardregistry = cardregistry,
        initializeCardHealthState = initializeCardHealthState,
        isCardDestroyed = isCardDestroyed,
        isCardUnavailable = isCardUnavailable,
        playHunterAddedSfxForCard = playHunterAddedSfxForCard,
        playHunterAddedSfxForCardDefinition = playHunterAddedSfxForCardDefinition,
    }
end

local function createGeneratedSupportCard(cardDefinition, targetLocation)
    return spawncontroller.createGeneratedSupportCard(getSpawnControllerContext(), cardDefinition, targetLocation)
end

local function createGeneratedDeckCardShuffled(cardDefinition)
    return spawncontroller.createGeneratedDeckCardShuffled(getSpawnControllerContext(), cardDefinition)
end

local function createGeneratedGridCard(cardDefinition, rowId, column)
    return spawncontroller.createGeneratedGridCard(getSpawnControllerContext(), cardDefinition, rowId, column)
end

local function spawnTokensNearCard(sourceCardIndex, tokenDefinition, count, options)
    return spawncontroller.spawnTokensNearCard(getSpawnControllerContext(), sourceCardIndex, tokenDefinition, count, options)
end

local function spawnRandomTokensNearCard(sourceCardIndex, tokenDefinitions, count, options)
    return spawncontroller.spawnRandomTokensNearCard(getSpawnControllerContext(), sourceCardIndex, tokenDefinitions, count, options)
end

local function spawnTokensNearPlayerCard(sourceCardIndex, tokenDefinition, count, options)
    return spawncontroller.spawnTokensNearPlayerCard(getSpawnControllerContext(), sourceCardIndex, tokenDefinition, count, options)
end

local function createOrStackPlayerCacheNearCard(sourceCardIndex, cacheDefinition, count)
    return spawncontroller.createOrStackPlayerCacheNearCard(getSpawnControllerContext(), sourceCardIndex, cacheDefinition, count)
end

local function resolveEnemyEncounter(sourceCardIndex, enemyDefinition)
    return spawncontroller.resolveEnemyEncounter(getSpawnControllerContext(), sourceCardIndex, enemyDefinition)
end

local function drawCardFromPlayerDeck()
    return spawncontroller.drawCardFromPlayerDeck(getSpawnControllerContext())
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

local function beginKitReturnAnimation(hostCard, attachedKit, returningCard)
    return cardanimations.beginKitReturnAnimation(getCardAnimationContext(), hostCard, attachedKit, returningCard)
end

local function updateKitReturnAnimations(dt)
    cardanimations.updateKitReturnAnimations(getCardAnimationContext(), dt)
end

local function drawKitReturnAnimations()
    cardanimations.drawKitReturnAnimations(getCardAnimationContext())
end

local function updatePilotVehicleAnimations(dt)
    cardanimations.updatePilotVehicleAnimations(getCardAnimationContext(), dt)
end

updateMulliganAnimations = function(dt)
    local animationContext = getCardAnimationContext()

    cardanimations.updateMulliganAnimations(animationContext, dt)

    gameState.mulliganPromptAlpha = animationContext.mulliganPromptAlpha
    gameState.mulliganReturnedCards = animationContext.mulliganReturnedCards
    gameState.mulliganResolving = animationContext.mulliganResolving
    gameState.mulliganActive = animationContext.mulliganActive
    gameState.mulliganCompleted = animationContext.mulliganCompleted
end

local function drawPilotVehicleAnimations()
    cardanimations.drawPilotVehicleAnimations(getCardAnimationContext())
end

releaseAttachedKits = function(card)
    return cardlifecycle.releaseAttachedKits(getCardLifecycleContext(), card)
end

local function removeCardFromPlay(cardIndex)
    return cardlifecycle.removeCardFromPlay(getCardLifecycleContext(), cardIndex)
end

local function expireCardFromPlay(cardIndex)
    return cardlifecycle.expireCardFromPlay(getCardLifecycleContext(), cardIndex)
end

local function discardCardFromPlay(cardIndex)
    return cardlifecycle.discardCardFromPlay(getCardLifecycleContext(), cardIndex)
end

getGameActionsContext = function()
    return {
        state = gameState,
        envdraw = envdraw,
        sfxrules = sfxrules,
        topsloteffects = topsloteffects,
        damageJitterDuration = DAMAGE_JITTER_DURATION,
        damageJitterMagnitude = DAMAGE_JITTER_MAGNITUDE,
        beginObjectiveEscalation = beginObjectiveEscalation,
        beginObjectiveHunterDeckTransformation = beginObjectiveHunterDeckTransformation,
        beginWarzoneTransformation = beginWarzoneTransformation,
        beginPoiEmergenceEffect = beginPoiEmergenceEffect,
        beginPoiFlipEffect = beginPoiFlipEffect,
        beginPoiGeneratedCardTransformation = beginPoiGeneratedCardTransformation,
        getDamageJitterKeyForCard = getDamageJitterKeyForCard,
        startCardDestruction = startCardDestruction,
        startChampionDestruction = startChampionDestruction,
        startIntelDestruction = startIntelDestruction,
        triggerDamageFeedback = triggerDamageFeedback,
    }
end

local function addObjectiveProgress(objectiveDefinition, amount, slotId)
    return gameactions.addObjectiveProgress(getGameActionsContext(), objectiveDefinition, amount, slotId)
end

local function canApplyObjectiveProgress(objectiveDefinition, amount)
    return gameactions.canApplyObjectiveProgress(objectiveDefinition, amount)
end

local function addWarzoneControl(warzoneDefinition, amount, slotId)
    return gameactions.addWarzoneControl(getGameActionsContext(), warzoneDefinition, amount, slotId)
end

local function getChampionPrimaryObjective(championDefinition)
    local objectiveId = championDefinition and championDefinition.PrimaryObjective or ACTIVE_PRIMARY_OBJECTIVE_ID
    return objectiverules.getObjective(objectiveId)
end

preloadWarzoneFamily = function(warzoneDefinition)
    warzonecontrolrules.preloadWarzoneFamily(warzoneDefinition, envdraw.preloadTopStripAssets)
end

getHunterControllerContext = function()
    return {
        state = gameState,
        cardregistry = cardregistry,
        objectiverules = objectiverules,
        sfxrules = sfxrules,
        isCardDestroyed = isCardDestroyed,
    }
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
    return gameactions.initializeCardHealthState(card)
end

initializeCardsHealthState = function(cardList)
    return gameactions.initializeCardsHealthState(cardList)
end

dealDamageToCard = function(card, amount, suppressFeedback)
    return gameactions.dealDamageToCard(getGameActionsContext(), card, amount, suppressFeedback)
end

addBlockingToCard = function(card, amount)
    return gameactions.addBlockingToCard(card, amount)
end

local function healCard(card, amount)
    return gameactions.healCard(card, amount)
end

clearAllBlocking = function()
    return gameactions.clearAllBlocking(getGameActionsContext())
end

dealDamageToChampion = function(amount, suppressFeedback)
    return gameactions.dealDamageToChampion(getGameActionsContext(), amount, suppressFeedback)
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
    return {
        state = gameState,
        carddraw = carddraw,
        cardregistry = cardregistry,
        keywordrules = keywordrules,
        kitrules = kitrules,
        notifications = notifications,
        resourcerules = resourcerules,
        strategyrules = strategyrules,
        tomerules = tomerules,
        trooprules = trooprules,
        turnrules = turnrules,
        warrules = warrules,
        createOrStackPlayerCacheNearCard = createOrStackPlayerCacheNearCard,
        dealDamageToCard = dealDamageToCard,
        dealDamageToChampion = dealDamageToChampion,
        discardCardFromPlay = discardCardFromPlay,
        drawCardFromPlayerDeck = drawCardFromPlayerDeck,
        enterCurrentPhase = enterCurrentPhase,
        getCardDrawPosition = getCardDrawPosition,
        removeCardFromPlay = removeCardFromPlay,
        spawnTokensNearCard = spawnTokensNearCard,
        spawnTokensNearPlayerCard = spawnTokensNearPlayerCard,
        startCardDestruction = startCardDestruction,
    }
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
    return contextbuilders.getCardLifecycleContext(getContextBuildersContext())
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

local getHoverPreviewDeps

local function getHoverPreviewState()
    return hoverpreview.getHoverPreviewState(gameState, getHoverPreviewDeps())
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
    return {
        state = gameState,
        envdraw = envdraw,
        sfxrules = sfxrules,
        resourcerules = resourcerules,
        cardregistry = cardregistry,
        addBlockingToCard = addBlockingToCard,
        dealDamageToCard = dealDamageToCard,
        dealDamageToChampion = dealDamageToChampion,
        addWarzoneControl = addWarzoneControl,
        addObjectiveProgress = addObjectiveProgress,
        getCurrentPhase = turnrules.getCurrentPhase,
        isEngagePhase = isEngagePhase,
    }
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

local function buildModalState()
    return contextbuilders.buildModalState(gameState)
end

local function applyModalState(modalState)
    contextbuilders.applyModalState(gameState, modalState)
end

local function getModalDeps()
    return contextbuilders.getModalDeps(getContextBuildersContext())
end

getHoverPreviewDeps = function()
    return contextbuilders.getHoverPreviewDeps(getContextBuildersContext())
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

local function primeCardMethodAbility(cardIndex, resourceName)
    local modalState = buildModalState()
    local primed = abilityrules.primeCardMethodAbility(cardIndex, resourceName, modalState, getModalDeps())
    applyModalState(modalState)
    return primed
end

local function tryUseEngageReroll(mouseX, mouseY)
    return engagerules.tryUseReroll(mouseX, mouseY, getEngageContext())
end

local function getHoveredTopSlotRollBadgeId(mouseX, mouseY)
    return boardquery.getHoveredTopSlotRollBadgeId(getBoardQueryContext(), mouseX, mouseY)
end

local function isAlliedTopSlot(slotId)
    return slotId == "warzone" and gameState.activeWarzone and gameState.activeWarzone.allied == true or false
end

local function tryCancelSelectedEngageAttacker()
    return engagerules.tryCancelSelectedAttacker(getEngageContext())
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
    hoverpreview.clearSpawnPreview(gameState)
end

local function updateHoveredCard()
    hoverpreview.updateHoveredCard(gameState, getHoverPreviewDeps())
end

local function getInputControllerDeps()
    return contextbuilders.getInputControllerDeps(getContextBuildersContext())
end

local function getContextBuilderRules()
    return {
        state = gameState,
        abilityrules = abilityrules,
        carddraw = carddraw,
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
    }
end

local function getContextBuilderCoreActions()
    return {
        addBlockingToCard = addBlockingToCard,
        addCardKeywordValue = addCardKeywordValue,
        addObjectiveProgress = addObjectiveProgress,
        addSetupAgents = addSetupAgents,
        addWarzoneControl = addWarzoneControl,
        applyModalState = applyModalState,
        beginEndPhaseSacrificeSelection = beginEndPhaseSacrificeSelection,
        beginInfiltrationEffect = beginInfiltrationEffect,
        beginKitReturnAnimation = beginKitReturnAnimation,
        beginPoiGeneratedCardTransformation = beginPoiGeneratedCardTransformation,
        buildModalState = buildModalState,
        canApplyObjectiveProgress = canApplyObjectiveProgress,
        canExpandCard = canExpandCard,
        canOpenPlayerDeckModal = canOpenPlayerDeckModal,
        canPlayCard = canPlayCard,
        cancelPendingStrategySelection = cancelPendingStrategySelection,
        chooseSyntacMethodResource = chooseSyntacMethodResource,
        clearAllBlocking = clearAllBlocking,
        clearResolvedSyntacMethodReward = clearResolvedSyntacMethodReward,
        clearTemporaryRerollBonus = clearTemporaryRerollBonus,
        completeSetupPhaseIfReady = completeSetupPhaseIfReady,
        copyLocation = copyLocation,
        createGeneratedGridCard = createGeneratedGridCard,
        createGeneratedSupportCard = createGeneratedSupportCard,
        dealDamageToCard = dealDamageToCard,
        dealDamageToChampion = dealDamageToChampion,
        destructionDuration = DESTRUCTION_DURATION,
        discardCardFromPlay = discardCardFromPlay,
        drawCardFromPlayerDeck = drawCardFromPlayerDeck,
        drawKitReturnAnimations = drawKitReturnAnimations,
        expireCardFromPlay = expireCardFromPlay,
        healCard = healCard,
        initializeCardHealthState = initializeCardHealthState,
        initializeCardsHealthState = initializeCardsHealthState,
        removeCardFromPlay = removeCardFromPlay,
        resolveEnemyEncounter = resolveEnemyEncounter,
        resolveKilledEnemyByPlayerCard = resolveKilledEnemyByPlayerCard,
        resolveOpeningMulligan = resolveOpeningMulligan,
        resolvePlayedTroopCard = resolvePlayedTroopCard,
        resolveDestroyedTroopCard = resolveDestroyedTroopCard,
        resolveSyntacRewardButtons = resolveSyntacRewardButtons,
        spawnRandomTokensNearCard = spawnRandomTokensNearCard,
        spawnTokensNearCard = spawnTokensNearCard,
        transformCardAtIndex = transformCardAtIndex,
        updateInfiltrationEffect = updateInfiltrationEffect,
    }
end

local function getContextBuilderGetters()
    return {
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
    }
end

local function getContextBuilderPredicates()
    return {
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
    }
end

local function getContextBuilderInputActions()
    return {
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
end

getContextBuildersContext = function()
    local context = getContextBuilderRules()

    local actionGroups = {
        getContextBuilderCoreActions(),
        getContextBuilderGetters(),
        getContextBuilderPredicates(),
        getContextBuilderInputActions(),
    }

    for _, actions in ipairs(actionGroups) do
        for key, value in pairs(actions) do
            context[key] = value
        end
    end

    return context
end

function love.load()
    love.math.setRandomSeed(os.time())
    love.graphics.setBackgroundColor(0.08, 0.08, 0.1)
    love.graphics.setColor(1, 1, 1)
    gameState.cards = {}
    gameState.hoveredCardIndex = nil
    gameState.hoveredTopSlotId = nil
    gameState.hoveredKeyword = nil
    gameState.hoveredDiceFace = nil
    gameState.expandedGridCardIndex = nil
    gameState.expandedTopSlotId = nil
    gameState.selectedAttackerCardIndex = nil
    gameState.selectedAttackerTopSlotId = nil
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
    gameState.engageRerollBonus = 0
    gameState.syntacCount = 0
    gameState.syntacRewardButtons = {}
    gameState.syntacMethodRewardAnimating = false
    gameState.isSyntacMethodModalOpen = false
    gameState.syntacPendingMethodChoicePaid = false
    gameState.primedSyntacAbility = nil
    gameState.isResourceExchangeModalOpen = false
    gameState.isJaclDeckModalOpen = false
    gameState.jaclDeckModalScroll.deck = 0
    gameState.jaclDeckModalScroll.discard = 0
    gameState.jaclDeckPreviewCard = nil
    gameState.activeDeckModalDeck = nil
    gameState.primedActivatedAbility = nil
    gameState.fullArtImage = nil
    gameState.hoveredJaclSpecialDefinition = nil
    gameState.hoveredJaclSpecialPreviewCard = nil
    clearHoveredSpawnPreview()
    gameState.pendingStrategySelection = nil
    gameState.pendingSacrificeSelection = nil
    gameState.endPhaseSacrificeHandled = false
    gameState.mulliganActive = false
    gameState.mulliganCompleted = false
    gameState.mulliganSelection = {}
    gameState.mulliganResolving = false
    gameState.mulliganReturnedCards = nil
    gameState.mulliganPromptAlpha = 0
    gameState.kitReturnAnimations = {}
    gameState.pilotVehicleAnimations = {}
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
    gameState.playerDeck = gameState.playerJacl
        and deckrules.buildDeckWithAdditionalDecks(gameState.playerJacl.deckId, getSetupAgentDeckIds())
        or nil
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
    updateKitReturnAnimations(dt)
    updatePilotVehicleAnimations(dt)
    updateMulliganAnimations(dt)

    cardlifecycle.updateDestroyedCards(getCardLifecycleContext(), dt)

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
        syntacRewardButtons = gameState.syntacRewardButtons,
        getRetaliationPhaseObjectiveProgress = getRetaliationPhaseObjectiveProgress,
        cards = gameState.cards,
        hoveredCardIndex = gameState.hoveredCardIndex,
        draggedCardIndex = gameState.draggedCardIndex,
        expandedGridCardIndex = gameState.expandedGridCardIndex,
        pendingSelectionPrompt = gameState.pendingSacrificeSelection
            and (gameState.pendingSacrificeSelection.prompt or "Choose a troop or token to sacrifice")
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
        hoveredTomeSpawnPreviewCards = gameState.hoveredTomeSpawnPreviewCards,
        hoveredTomeSpawnPreviewLabel = gameState.hoveredTomeSpawnPreviewLabel,
        hoveredTomeSpawnPreviewCardIndex = gameState.hoveredTomeSpawnPreviewCardIndex,
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
        drawPilotVehicleAnimations = drawPilotVehicleAnimations,
    })
end
