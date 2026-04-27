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
local temporaryeffects = require("src.system.temporaryeffects")
local kitrules = require("src.system.kitrules")
local resourcerules = require("src.system.resourcerules")
local abilityrules = require("src.system.abilityrules")
local infiltrationrules = require("src.system.infiltrationrules")
local strategyrules = require("src.system.strategyrules")
local tomerules = require("src.system.tomerules")
local trooprules = require("src.system.trooprules")
spawnrules = require("src.system.spawnrules")
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
    return cardzones.getNextOpenHandSlot(gameState.cards, envrules.getPlayerHand().slots, isCardDestroyed)
end

getSpawnContext = function()
    return {
        cards = gameState.cards,
        cardExpansion = gameState.cardExpansion,
        cardEntranceProgress = gameState.cardEntranceProgress,
        playerDeck = gameState.playerDeck,
        envdraw = envdraw,
        turnrules = turnrules,
        warrules = warrules,
        isCardUnavailable = isCardUnavailable,
        playHunterAddedSfxForCardDefinition = playHunterAddedSfxForCardDefinition,
    }
end

local function createGeneratedSupportCard(cardDefinition, targetLocation)
    return spawnrules.createGeneratedSupportCard(getSpawnContext(), cardDefinition, targetLocation)
end

local function createGeneratedDeckCardShuffled(cardDefinition)
    return spawnrules.createGeneratedDeckCardShuffled(getSpawnContext(), cardDefinition)
end

local function createGeneratedGridCard(cardDefinition, rowId, column)
    return spawnrules.createGeneratedGridCard(getSpawnContext(), cardDefinition, rowId, column)
end

local function spawnTokensNearCard(sourceCardIndex, tokenDefinition, count, options)
    return spawnrules.spawnTokensNearCard(getSpawnContext(), sourceCardIndex, tokenDefinition, count, options)
end

local function spawnRandomTokensNearCard(sourceCardIndex, tokenDefinitions, count, options)
    return spawnrules.spawnRandomTokensNearCard(getSpawnContext(), sourceCardIndex, tokenDefinitions, count, options)
end

local function spawnTokensNearPlayerCard(sourceCardIndex, tokenDefinition, count, options)
    return spawnrules.spawnTokensNearPlayerCard(getSpawnContext(), sourceCardIndex, tokenDefinition, count, options)
end

local function createOrStackPlayerCacheNearCard(sourceCardIndex, cacheDefinition, count)
    return spawnrules.createOrStackPlayerCacheNearCard(getSpawnContext(), sourceCardIndex, cacheDefinition, count)
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

local function resolveSyntacRewardButtons()
    local rewardButtons = gameState.syntacRewardButtons or {}
    local nextRewardButtons = {}

    if rewardButtons.draw then
        drawCardFromPlayerDeck()
    end

    if rewardButtons.rerolls then
        gameState.engageRerollBonus = math.max(0, tonumber(gameState.engageRerollBonus) or 0) + 2
    end

    if rewardButtons.method and rewardButtons.methodResource then
        local methodButton = envdraw.getSyntacRewardButtonLayout("method", gameState.playerJacl)
        local sourceCenter = methodButton and {
            x = methodButton.x + (methodButton.width / 2),
            y = methodButton.y + (methodButton.height / 2),
        } or nil

        resourcerules.addResourceFromSource(
            rewardButtons.methodResource,
            1,
            sourceCenter,
            envdraw.getBottomLeftPanelLayout(gameState.playerJacl),
            envdraw.getResourceTrackerLayout()
        )

        nextRewardButtons.method = true
        nextRewardButtons.methodResource = rewardButtons.methodResource
        gameState.syntacMethodRewardAnimating = true
    end

    gameState.syntacRewardButtons = nextRewardButtons
end

local function clearResolvedSyntacMethodReward()
    if gameState.syntacMethodRewardAnimating then
        gameState.syntacMethodRewardAnimating = false
        gameState.syntacRewardButtons = {}
    end
end

local function clearTemporaryRerollBonus()
    gameState.engageRerollBonus = 0

    if gameState.engageRerollCount > 2 then
        gameState.engageRerollCount = 2
    end
end

local function refundPendingSyntacMethodChoice()
    if gameState.syntacPendingMethodChoicePaid then
        resourcerules.addResource("The Scratch", 2)
        sfxrules.playResourcePlay()
        gameState.syntacPendingMethodChoicePaid = false
    end

    gameState.isSyntacMethodModalOpen = false
end

local function chooseSyntacMethodResource(resourceName)
    if not gameState.syntacPendingMethodChoicePaid or not resourceName then
        return false
    end

    gameState.syntacRewardButtons = gameState.syntacRewardButtons or {}
    gameState.syntacRewardButtons.method = true
    gameState.syntacRewardButtons.methodResource = resourceName
    gameState.syntacPendingMethodChoicePaid = false
    gameState.isSyntacMethodModalOpen = false
    sfxrules.playResourcePlay()
    return true
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

local function canApplyObjectiveProgress(objectiveDefinition, amount)
    return objectiveprogressrules.canApplyProgress(objectiveDefinition, amount)
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
    return gameState.activePrimaryObjective and gameState.activePrimaryObjective.emphasis or 0
end

local function getRetaliationPhaseObjectiveProgress()
    return getHunterEmphasisInHand()
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

local function healCard(card, amount)
    if not card or amount == nil then
        return nil
    end

    initializeCardHealthState(card)

    if card.currentHealth == nil then
        return nil
    end

    local previousHealth = math.max(0, tonumber(card.currentHealth) or 0)
    local maxHealth = math.max(previousHealth, math.max(0, tonumber(card.maxHealth) or 0))
    local healAmount = math.max(0, tonumber(amount) or 0)

    card.currentHealth = math.min(maxHealth, previousHealth + healAmount)

    return {
        previousHealth = previousHealth,
        currentHealth = card.currentHealth,
        healed = card.currentHealth - previousHealth,
        changed = card.currentHealth > previousHealth,
    }
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
        temporaryeffects = temporaryeffects,
        warrules = warrules,
        addObjectiveProgress = addObjectiveProgress,
        addSetupAgents = addSetupAgents,
        addWarzoneControl = addWarzoneControl,
        beginInfiltrationEffect = beginInfiltrationEffect,
        beginEndPhaseSacrificeSelection = beginEndPhaseSacrificeSelection,
        beginPoiGeneratedCardTransformation = beginPoiGeneratedCardTransformation,
        clearResolvedSyntacMethodReward = clearResolvedSyntacMethodReward,
        clearTemporaryRerollBonus = clearTemporaryRerollBonus,
        clearAllBlocking = clearAllBlocking,
        createGeneratedSupportCard = createGeneratedSupportCard,
        dealDamageToCard = dealDamageToCard,
        dealDamageToChampion = dealDamageToChampion,
        drawCardFromPlayerDeck = drawCardFromPlayerDeck,
        healCard = healCard,
        notifyMeatCacheDecayed = function(cacheCardIndex)
            trooprules.notifyMeatCacheDecayed(cacheCardIndex, {
                cards = gameState.cards,
                cardregistry = cardregistry,
                isCardUnavailable = isCardUnavailable,
                addCardKeywordValue = addCardKeywordValue,
            })
        end,
        getCardDrawPosition = getCardDrawPosition,
        getChampionPlayContext = getChampionPlayContext,
        getEngageRerollBonus = function()
            return gameState.engageRerollBonus or 0
        end,
        getEndPhaseObjectiveProgress = getEndPhaseObjectiveProgress,
        getRetaliationPhaseObjectiveProgress = getRetaliationPhaseObjectiveProgress,
        getReplacementIntel = getReplacementIntel,
        getSetupCardCount = getSetupCardCount,
        getTopSlotRollTargets = getTopSlotRollTargets,
        initializeCardsHealthState = initializeCardsHealthState,
        isCardUnavailable = isCardUnavailable,
        isGridCard = isGridCard,
        normalizeSetupCardSlots = normalizeSetupCardSlots,
        playHunterAddedSfxForCards = playHunterAddedSfxForCards,
        resolveSyntacRewardButtons = resolveSyntacRewardButtons,
        expireCardFromPlay = expireCardFromPlay,
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

    if kitrules.isKitDefinition(cardDefinition) then
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

local function isStrategyPhase()
    return strategyrules.isStrategyPhase({
        turnrules = turnrules,
    })
end

local function getTomeUseContext()
    return {
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
    }
end

local function tryUseTomeCard(cardIndex, mouseX, mouseY)
    local hostCard = cardIndex and gameState.cards[cardIndex] or nil

    if not hostCard or mouseX == nil or mouseY == nil then
        return false
    end

    local drawX, drawY, expansionProgress, renderOptions = getCardDrawPosition(hostCard, cardIndex)
    local kitBadgeRect = carddraw.getKeywordBadgeRect(hostCard.setName, hostCard.cardId, drawX, drawY, renderOptions, "KWKIT")

    if not kitBadgeRect
        or mouseX < kitBadgeRect.x
        or mouseX > kitBadgeRect.x + kitBadgeRect.size
        or mouseY < kitBadgeRect.y
        or mouseY > kitBadgeRect.y + kitBadgeRect.size then
        return false
    end

    return tomerules.useAttachedTome(cardIndex, getTomeUseContext())
end

local function tryPlayStrategyCard(strategyCardIndex, targetCardIndex)
    return strategyrules.playStrategy(strategyCardIndex, targetCardIndex, {
        cards = gameState.cards,
        turnrules = turnrules,
        warrules = warrules,
        cardregistry = cardregistry,
        discardCard = discardCardFromPlay,
        startCardDestruction = startCardDestruction,
        dealDamageToCard = dealDamageToCard,
        dealDamageToChampion = dealDamageToChampion,
        spawnTokensNearCard = spawnTokensNearCard,
        beginPendingStrategySelection = function(pendingSelection)
            local hasValidTarget = false

            for cardIndex = 1, #gameState.cards do
                if strategyrules.isValidFunccostTarget(cardIndex, pendingSelection, {
                    cards = gameState.cards,
                    cardregistry = cardregistry,
                }) then
                    hasValidTarget = true
                    break
                end
            end

            if not hasValidTarget then
                notifications.push("Strategy fizzled")
                return true
            end

            gameState.pendingStrategySelection = pendingSelection
            notifications.push("Choose a troop or token to sacrifice")
            return true
        end,
    })
end

local function tryPlayKitCard(kitCardIndex, targetCardIndex)
    return kitrules.playKit(kitCardIndex, targetCardIndex, {
        cards = gameState.cards,
        cardregistry = cardregistry,
        canAffordCosts = function(costEntries)
            return resourcerules.canAffordCosts(costEntries)
        end,
        payCosts = function(costEntries)
            return resourcerules.payCosts(costEntries)
        end,
        removeCardFromPlay = removeCardFromPlay,
    })
end

local function getPendingSelection()
    return gameState.pendingStrategySelection or gameState.pendingSacrificeSelection
end

local function hasPendingStrategySelection()
    return getPendingSelection() ~= nil
end

local function tryResolvePendingStrategySelection(cardIndex)
    local pendingSelection = getPendingSelection()

    if not pendingSelection then
        return false
    end

    if pendingSelection.kind == "troop_script_sacrifice" then
        local resolved = trooprules.isValidPendingSacrificeTarget(cardIndex, pendingSelection, {
            cards = gameState.cards,
            cardregistry = cardregistry,
        })

        if not resolved then
            return false
        end

        startCardDestruction(cardIndex)
        gameState.pendingSacrificeSelection = nil
        phasecontroller.enterCurrentPhase(gameState, getPhaseControllerDeps())
        return true
    end

    local resolved = strategyrules.resolvePendingSelection(cardIndex, pendingSelection, {
        cards = gameState.cards,
        cardregistry = cardregistry,
        warrules = warrules,
        discardCard = discardCardFromPlay,
        startCardDestruction = startCardDestruction,
        dealDamageToCard = dealDamageToCard,
        dealDamageToChampion = dealDamageToChampion,
    })

    if resolved then
        gameState.pendingStrategySelection = nil
    end

    return resolved
end

local function cancelPendingStrategySelection()
    if not gameState.pendingStrategySelection then
        return false
    end

    gameState.pendingStrategySelection = nil
    notifications.push("Strategy fizzled")
    return true
end

local function resolvePlayedTroopCard(troopCardIndex)
    return trooprules.resolvePlay(troopCardIndex, {
        cards = gameState.cards,
        cardregistry = cardregistry,
        spawnTokensNearPlayerCard = spawnTokensNearPlayerCard,
    })
end

local function resolveDestroyedTroopCard(troopCardIndex, attachedKitCards)
    return trooprules.resolveDeath(troopCardIndex, {
        cards = gameState.cards,
        cardregistry = cardregistry,
        attachedKitCards = attachedKitCards,
        drawCardFromPlayerDeck = drawCardFromPlayerDeck,
        spawnTokensNearPlayerCard = function(sourceCardIndex, tokenDefinition, count)
            local sourceCard = sourceCardIndex and gameState.cards[sourceCardIndex] or nil

            if not sourceCard or not sourceCard.location or sourceCard.location.kind ~= "grid" then
                return 0
            end

            return spawnTokensNearPlayerCard(sourceCardIndex, tokenDefinition, count, {
                ignoredCardIndex = sourceCardIndex,
                preferredColumn = sourceCard.location.column,
            })
        end,
    })
end

local function resolveKilledEnemyByPlayerCard(attackerCardIndex, targetCardIndex)
    return trooprules.resolveKill(attackerCardIndex, targetCardIndex, {
        cards = gameState.cards,
        cardregistry = cardregistry,
        createOrStackPlayerCacheNearCard = createOrStackPlayerCacheNearCard,
    })
end

addCardKeywordValue = function(cardIndex, keywordId, amount)
    local card = cardIndex and gameState.cards[cardIndex] or nil
    local cardDefinition = card and cardregistry.getCard(card.setName, card.cardId) or nil

    if not card or not cardDefinition then
        return nil
    end

    local nextValue = keywordrules.addCardKeywordValue(card, cardDefinition, keywordId, amount)

    if nextValue ~= nil then
        warrules.refreshCardRollValue(cardIndex, gameState.cards)
    end

    return nextValue
end

getCardLifecycleContext = function()
    return {
        state = gameState,
        cardregistry = cardregistry,
        sfxrules = sfxrules,
        trooprules = trooprules,
        turnrules = turnrules,
        warrules = warrules,
        addCardKeywordValue = addCardKeywordValue,
        beginKitReturnAnimation = beginKitReturnAnimation,
        copyLocation = copyLocation,
        destructionDuration = DESTRUCTION_DURATION,
        getNextOpenHandSlot = getNextOpenHandSlot,
        resolveDestroyedTroopCard = resolveDestroyedTroopCard,
    }
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

local function getCardPresentationContext()
    return {
        carddraw = carddraw,
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
        drawKitReturnAnimations = drawKitReturnAnimations,
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

local function getCardMethodBadgeTarget(mouseX, mouseY)
    local cardIndex = getGridCardAt(mouseX, mouseY)
    local card = cardIndex and gameState.cards[cardIndex] or nil

    if not card
        or not card.location
        or card.location.kind ~= "grid"
        or card.location.rowId ~= "PlayerRow" then
        return nil
    end

    local drawX, drawY, expansionProgress, renderOptions = getCardDrawPosition(card, cardIndex)
    local badgeRects = carddraw.getMethodBadgeRects(card.setName, card.cardId, drawX, drawY, expansionProgress, renderOptions)

    for _, badgeRect in ipairs(badgeRects or {}) do
        if mouseX >= badgeRect.x
            and mouseX <= badgeRect.x + badgeRect.width
            and mouseY >= badgeRect.y
            and mouseY <= badgeRect.y + badgeRect.height then
            return {
                cardIndex = cardIndex,
                resource = badgeRect.resource,
            }
        end
    end

    return nil
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
        cardregistry = cardregistry,
        cards = gameState.cards,
        hoveredCardIndex = gameState.hoveredCardIndex,
        selectedAttackerCardIndex = gameState.selectedAttackerCardIndex,
        selectedAttackerTopSlotId = gameState.selectedAttackerTopSlotId,
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
        canApplyObjectiveProgress = canApplyObjectiveProgress,
        addWarzoneControl = addWarzoneControl,
        drawCardFromPlayerDeck = drawCardFromPlayerDeck,
        healCard = healCard,
        dealDamageToChampion = dealDamageToChampion,
        dealDamageToCard = dealDamageToCard,
        resolveKilledEnemyByPlayerCard = resolveKilledEnemyByPlayerCard,
        beginInfiltrationEffect = beginInfiltrationEffect,
        spawnTokensNearCard = spawnTokensNearCard,
        spawnRandomTokensNearCard = spawnRandomTokensNearCard,
        addSyntac = function(amount)
            gameState.syntacCount = math.min(10, math.max(0, (gameState.syntacCount or 0) + math.max(0, tonumber(amount) or 0)))
        end,
        addMethodResource = function(resourceName, amount, sourceEntityKey)
            local sourceRect = sourceEntityKey and getEntitySourceRect(sourceEntityKey) or nil
            local sourceCenter = sourceRect and {
                x = sourceRect.x + (sourceRect.width / 2),
                y = sourceRect.y + (sourceRect.height / 2),
            } or nil

            return resourcerules.addResourceFromSource(
                resourceName,
                amount,
                sourceCenter,
                envdraw.getBottomLeftPanelLayout(gameState.playerJacl),
                envdraw.getResourceTrackerLayout()
            )
        end,
        setSelectedAttackerCardIndex = function(cardIndex)
            gameState.selectedAttackerCardIndex = cardIndex
            gameState.selectedAttackerTopSlotId = nil
        end,
        setSelectedAttackerTopSlotId = function(slotId)
            gameState.selectedAttackerTopSlotId = slotId
            gameState.selectedAttackerCardIndex = nil
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

local function canUseSyntacRewardButtons()
    return turnrules.getCurrentPhase() == "Prelude" or isEngagePhase()
end

local function tryUseSyntacRewardButton(mouseX, mouseY)
    local button = envdraw.getSyntacRewardButtonAt(mouseX, mouseY, gameState.playerJacl)

    if not button or (button.id ~= "method" and button.id ~= "draw" and button.id ~= "rerolls") then
        return false
    end

    if not canUseSyntacRewardButtons() then
        sfxrules.playPlayReject()
        return true
    end

    gameState.syntacRewardButtons = gameState.syntacRewardButtons or {}

    if gameState.syntacRewardButtons[button.id] then
        sfxrules.playPlayReject()
        return true
    end

    if button.id == "method" and gameState.syntacPendingMethodChoicePaid then
        sfxrules.playPlayReject()
        return true
    end

    if not resourcerules.payCosts({
        { resource = "The Scratch", amount = 2 },
    }) then
        sfxrules.playPlayReject()
        return true
    end

    if button.id == "method" then
        gameState.syntacPendingMethodChoicePaid = true
        gameState.isSyntacMethodModalOpen = true
        gameState.isResourceExchangeModalOpen = false
        gameState.isJaclDeckModalOpen = false
        sfxrules.playResourcePlay()
        return true
    end

    gameState.syntacRewardButtons[button.id] = true
    sfxrules.playResourcePlay()
    return true
end

local function getHoveredPlayerRollBadgeCardIndex(mouseX, mouseY)
    return engagerules.getHoveredPlayerRollBadgeCardIndex(mouseX, mouseY, getEngageContext())
end

local function buildModalState()
    return {
        playerJacl = gameState.playerJacl,
        activePrimaryObjective = gameState.activePrimaryObjective,
        isSyntacMethodModalOpen = gameState.isSyntacMethodModalOpen,
        isResourceExchangeModalOpen = gameState.isResourceExchangeModalOpen,
        isJaclDeckModalOpen = gameState.isJaclDeckModalOpen,
        jaclDeckModalScroll = gameState.jaclDeckModalScroll,
        jaclDeckPreviewCard = gameState.jaclDeckPreviewCard,
        activeDeckModalDeck = gameState.activeDeckModalDeck,
        primedActivatedAbility = gameState.primedActivatedAbility,
    }
end

local function applyModalState(modalState)
    gameState.isSyntacMethodModalOpen = modalState.isSyntacMethodModalOpen
    gameState.isResourceExchangeModalOpen = modalState.isResourceExchangeModalOpen
    gameState.isJaclDeckModalOpen = modalState.isJaclDeckModalOpen
    gameState.jaclDeckPreviewCard = modalState.jaclDeckPreviewCard
    gameState.activeDeckModalDeck = modalState.activeDeckModalDeck
    gameState.primedActivatedAbility = modalState.primedActivatedAbility
end

local function getModalDeps()
    return {
        turnrules = turnrules,
        resourcerules = resourcerules,
        abilityrules = abilityrules,
        cardregistry = cardregistry,
        cards = gameState.cards,
        isCardUnavailable = isCardUnavailable,
        sfxrules = sfxrules,
        envdraw = envdraw,
        cardinstances = cardinstances,
        createGeneratedGridCard = createGeneratedGridCard,
        transformCardAtIndex = transformCardAtIndex,
        pilotCardWithVehicleAtIndex = pilotCardWithVehicleAtIndex,
        getCardMethodBadgeTarget = getCardMethodBadgeTarget,
        getHoveredTopSlotId = getHoveredTopSlotId,
        getGridCardAt = getGridCardAt,
        getValidJaclSpecialTargetCell = getValidJaclSpecialTargetCell,
        getPlayerRowCellAt = getPlayerRowCellAt,
        activeChampion = gameState.activeChampion,
        dealDamageToCard = dealDamageToCard,
        dealDamageToChampion = dealDamageToChampion,
        resolveKilledEnemyByPlayerCard = resolveKilledEnemyByPlayerCard,
        addSyntac = function(amount)
            gameState.syntacCount = math.min(10, math.max(0, (gameState.syntacCount or 0) + math.max(0, tonumber(amount) or 0)))
        end,
        addObjectiveProgress = addObjectiveProgress,
        copyLocation = copyLocation,
        cancelSyntacMethodChoice = function(state)
            refundPendingSyntacMethodChoice()
            state.isSyntacMethodModalOpen = gameState.isSyntacMethodModalOpen
        end,
        chooseSyntacMethodResource = function(resourceName, state)
            chooseSyntacMethodResource(resourceName)
            state.isSyntacMethodModalOpen = gameState.isSyntacMethodModalOpen
        end,
    }
end

getHoverPreviewDeps = function()
    return {
        abilityrules = abilityrules,
        carddraw = carddraw,
        cardregistry = cardregistry,
        envdraw = envdraw,
        sfxrules = sfxrules,
        strategyrules = strategyrules,
        tomerules = tomerules,
        trooprules = trooprules,
        turnrules = turnrules,
        warrules = warrules,
        getCardDrawPosition = getCardDrawPosition,
        getCardMethodBadgeTarget = getCardMethodBadgeTarget,
        getHoveredTopSlotId = getHoveredTopSlotId,
        getModalDeps = getModalDeps,
        isCardDestroyed = isCardDestroyed,
        isCardUnavailable = isCardUnavailable,
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
    return envdraw.getTopSlotRollBadgeHit(
        mouseX,
        mouseY,
        turnrules.getCurrentPhase(),
        gameState.activeChampion,
        gameState.activeWarzone,
        gameState.activePoi,
        gameState.activePrimaryObjective,
        gameState.activeIntel,
        warrules.getDisplayStates()
    )
end

local function isAlliedTopSlot(slotId)
    return slotId == "warzone" and gameState.activeWarzone and gameState.activeWarzone.allied == true or false
end

local function tryCancelSelectedEngageAttacker()
    return engagerules.tryCancelSelectedAttacker(getEngageContext())
end

getTargetingContext = function()
    return {
        cards = gameState.cards,
        hoveredCardIndex = gameState.hoveredCardIndex,
        hoveredTopSlotId = gameState.hoveredTopSlotId,
        pendingStrategySelection = getPendingSelection(),
        primedActivatedAbility = gameState.primedActivatedAbility,
        selectedAttackerCardIndex = gameState.selectedAttackerCardIndex,
        selectedAttackerTopSlotId = gameState.selectedAttackerTopSlotId,
        currentPhase = turnrules.getCurrentPhase(),
        displayStates = warrules.getDisplayStates(),
        activeChampion = gameState.activeChampion,
        activePrimaryObjective = gameState.activePrimaryObjective,
        activeIntel = gameState.activeIntel,
        activeWarzone = gameState.activeWarzone,
        activePoi = gameState.activePoi,
        getCardRollState = warrules.getCardRollState,
        canTargetEnemyCard = warrules.canTargetEnemyCard,
        canAttackTarget = warrules.canAttackTarget,
        canTargetCardByHeavyRestriction = warrules.canTargetCardByHeavyRestriction,
        canTargetPlayerWarzone = warrules.canTargetPlayerWarzone,
        cardregistry = cardregistry,
        isPrimedAbilityTarget = function(cardIndex, primedAbility)
            return abilityrules.isPrimedAbilityTarget(cardIndex, primedAbility, getModalDeps())
        end,
        isPendingStrategyTarget = function(cardIndex, pendingSelection)
            if pendingSelection and pendingSelection.kind == "troop_script_sacrifice" then
                return trooprules.isValidPendingSacrificeTarget(cardIndex, pendingSelection, {
                    cards = gameState.cards,
                    cardregistry = cardregistry,
                })
            end

            return strategyrules.isValidFunccostTarget(cardIndex, pendingSelection, {
                cards = gameState.cards,
                cardregistry = cardregistry,
            })
        end,
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

function clearHoveredSpawnPreview()
    hoverpreview.clearSpawnPreview(gameState)
end

local function updateHoveredCard()
    hoverpreview.updateHoveredCard(gameState, getHoverPreviewDeps())
end

local function getInputControllerDeps()
    return {
        carddraw = carddraw,
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
        getCardMethodBadgeTarget = getCardMethodBadgeTarget,
        getHoveredTopSlotId = getHoveredTopSlotId,
        getHoveredTopSlotRollBadgeId = getHoveredTopSlotRollBadgeId,
        isAlliedTopSlot = isAlliedTopSlot,
        getGridCardAt = getGridCardAt,
        getModalDeps = getModalDeps,
        getPhaseControllerDeps = getPhaseControllerDeps,
        getValidDropColumn = getValidDropColumn,
        isEngagePhase = isEngagePhase,
        isGridCard = isGridCard,
        isHunterCard = isHunterCard,
        isPointInsideJaclPortrait = isPointInsideJaclPortrait,
        isPointInsideJaclScratchBadge = isPointInsideJaclScratchBadge,
        isKitCard = function(card)
            return kitrules.isKitCard(card, {
                cardregistry = cardregistry,
            })
        end,
        isSetupCard = isSetupCard,
        isStrategyPhase = isStrategyPhase,
        isStrategyCard = isStrategyCard,
        isTomeCard = function(card)
            return tomerules.isTomeCard(card, {
                cardregistry = cardregistry,
            })
        end,
        hasPendingStrategySelection = hasPendingStrategySelection,
        normalizeHandCardSlots = normalizeHandCardSlots,
        normalizeSetupCardSlots = normalizeSetupCardSlots,
        payCardCosts = payCardCosts,
        primeCardMethodAbility = primeCardMethodAbility,
        primeJaclSpecial = primeJaclSpecial,
        resolvePlayedTroopCard = resolvePlayedTroopCard,
        resolveOpeningMulligan = resolveOpeningMulligan,
        cancelPendingStrategySelection = cancelPendingStrategySelection,
        tryPlayKitCard = tryPlayKitCard,
        tryPlayStrategyCard = tryPlayStrategyCard,
        tryResolvePendingStrategySelection = tryResolvePendingStrategySelection,
        tryUseTomeCard = tryUseTomeCard,
        tryUseSyntacRewardButton = tryUseSyntacRewardButton,
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
