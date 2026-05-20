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
buttonrules = appmodules.buttonrules
cardinstances = appmodules.cardinstances
cardlifecycle = appmodules.cardlifecycle
cardplaycontroller = appmodules.cardplaycontroller
cardregistry = appmodules.cardregistry
cardzones = appmodules.cardzones
championplayrules = appmodules.championplayrules
championrules = appmodules.championrules
contextassembly = appmodules.contextassembly
contextbuilders = appmodules.contextbuilders
crewrules = appmodules.crewrules
deckrules = appmodules.deckrules
engagerules = appmodules.engagerules
enhancementrules = appmodules.enhancementrules
envrules = appmodules.envrules
gameactions = appmodules.gameactions
gamestate = appmodules.gamestate
gamestates = appmodules.gamestates
haywirerules = appmodules.haywirerules
huntercontroller = appmodules.huntercontroller
infiltrationrules = appmodules.infiltrationrules
jaclrules = appmodules.jaclrules
keywordrules = appmodules.keywordrules
kitrules = appmodules.kitrules
lifecyclebridge = appmodules.lifecyclebridge
notifications = appmodules.notifications
objectiverules = appmodules.objectiverules
phasecontroller = appmodules.phasecontroller
playerdefeatcontroller = appmodules.playerdefeatcontroller
previewrules = appmodules.previewrules
resourcerules = appmodules.resourcerules
rewarddebug = appmodules.rewarddebug
spawnbridge = appmodules.spawnbridge
strategyrules = appmodules.strategyrules
systemrules = appmodules.systemrules
syntacrules = appmodules.syntacrules
temporaryeffects = appmodules.temporaryeffects
tithesrules = appmodules.tithesrules
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
munitionsrules = appmodules.munitionsrules
surrendermodal = appmodules.surrendermodal

local setupScenario = gamestate.getDefaultScenario()
local gameState = gamestate.createInitialState()
local appState = gamestates.create()
local DOMAIN_AWARENESS_METHOD_RESOURCES = {
    "The Blade",
    "The Shadow",
    "The Rampage",
    "The Inferno",
    "The Stitch",
    "The Crusade",
    "The Gate",
    "The Trigger",
    "The Beast",
    "The Nightmare",
}
local getCardDrawPosition
local isGridRowColumnOccupied
local isWarRollSourceActive
local getTargetingContext
local getTopSlotRollTargets
local getPlayerDefeatControllerContext
local clearDomainAwarenessEncounterBonus
local beginInfiltrationEffect
local addCardKeywordValue
local beginEndPhaseSacrificeSelection
local getNextOpenHandSlot
local preloadWarzoneFamily
local updateInfiltrationEffect
local resolveChampionDefeated
local beginPlayerDefeat
local playHunterAddedSfxForCard
local playHunterAddedSfxForCardDefinition
local playHunterAddedSfxForCards
local isPointInsideJaclPortrait
local isHunterCard
local getCardPresentationContext
local startNewRun
getDamageJitterKeyForCard = lifecyclebridge.getDamageJitterKeyForCard

local function getMissionRewardAlms()
    local reward = appState.activeMissionReward

    return math.max(0, math.floor(tonumber(reward and reward.alms or appState.activeMissionPrize) or 0))
end

local function setActiveMissionReward(reward)
    local previousReward = appState.activeMissionReward
    local alms = math.max(0, math.floor(tonumber(reward and reward.alms) or 0))
    local resourceKey = reward and reward.resourceKey or nil
    local resourceAmount = math.max(0, math.floor(tonumber(reward and reward.resourceAmount) or 0))
    local cardrw = reward and reward.cardrw or previousReward and previousReward.cardrw or nil

    if rewarddebug and rewarddebug.log then
        rewarddebug.log("setActiveMissionReward", {
            alms = alms,
            resourceKey = resourceKey,
            resourceAmount = resourceAmount,
            cardrw = cardrw,
            incomingCardrw = reward and reward.cardrw or nil,
            previousCardrw = previousReward and previousReward.cardrw or nil,
            source = reward and reward.source or nil,
        })
    end

    appState.activeMissionReward = {
        alms = alms,
        source = reward and reward.source or nil,
        cardrw = cardrw,
    }

    if resourceKey and resourceAmount > 0 then
        appState.activeMissionReward.resourceKey = resourceKey
        appState.activeMissionReward.resourceAmount = resourceAmount
    end

    appState.activeMissionPrize = alms
end

local function clearActiveMissionReward()
    appState.activeMissionReward = nil
    appState.activeMissionPrize = nil
end

local function getRewardEntryCardId(entry)
    if type(entry) == "string" then
        return entry
    end

    return type(entry) == "table" and (entry.cardId or entry.id) or nil
end

local function copyRewardEntry(entry)
    if type(entry) ~= "table" then
        return entry
    end

    local copiedEntry = {}

    for key, value in pairs(entry) do
        copiedEntry[key] = value
    end

    return copiedEntry
end

local function isRewardEntryCardType(entry, cardType)
    local cardId = getRewardEntryCardId(entry)
    local cardDefinition = cardId and cardregistry.getCardById(cardId) or nil

    return cardDefinition and cardDefinition.type == cardType or false
end

local function isHunterRewardEntry(entry)
    return isRewardEntryCardType(entry, "hunter")
end

local function isAllyRewardEntry(entry)
    return isRewardEntryCardType(entry, "ally")
end

local function ensureRunJaclRewardBucket()
    appState.selectedRunCardRewards = appState.selectedRunCardRewards or {}
    appState.selectedRunCardRewards.jacl = appState.selectedRunCardRewards.jacl or {}
    appState.selectedRunCardRewards.agents = appState.selectedRunCardRewards.agents or {}

    local jaclId = appState.selectedRunJaclId or setupScenario.playerJaclId

    if not jaclId then
        return nil
    end

    appState.selectedRunCardRewards.jacl[jaclId] = appState.selectedRunCardRewards.jacl[jaclId] or {}
    return appState.selectedRunCardRewards.jacl[jaclId]
end

local function copyDeckCardAsRewardEntry(card)
    if not card or not card.cardId then
        return nil
    end

    return {
        cardId = card.cardId,
        enh = card.enh,
        enhancement = card.enhancement,
        enhancements = card.enhancements,
        enhance = card.enhance,
    }
end

local function collectMissionDeckCardEntriesByType(cardType)
    local cardEntries = {}

    for _, card in ipairs(gameState.playerDeck and gameState.playerDeck.cards or {}) do
        local cardDefinition = cardregistry.getCard(card.setName, card.cardId)

        if cardDefinition and cardDefinition.type == cardType then
            cardEntries[#cardEntries + 1] = copyDeckCardAsRewardEntry(card)
        end
    end

    for _, card in ipairs(gameState.playerDeck and gameState.playerDeck.discard or {}) do
        local cardDefinition = cardregistry.getCard(card.setName, card.cardId)

        if cardDefinition and cardDefinition.type == cardType then
            cardEntries[#cardEntries + 1] = copyDeckCardAsRewardEntry(card)
        end
    end

    return cardEntries
end

local function collectMissionHandCardEntriesByType(cardType)
    local cardEntries = {}

    for _, card in ipairs(gameState.cards or {}) do
        local cardDefinition = cardregistry.getCard(card.setName, card.cardId)

        if card
            and card.location
            and card.location.kind == "hand"
            and not cardlifecycle.isCardDestroyed(card)
            and cardDefinition
            and cardDefinition.type == cardType then
            cardEntries[#cardEntries + 1] = copyDeckCardAsRewardEntry(card)
        end
    end

    return cardEntries
end

local function appendEntries(target, entries)
    for _, entry in ipairs(entries or {}) do
        target[#target + 1] = entry
    end
end

local function preserveMissionCardsForWorld()
    local rewardBucket = ensureRunJaclRewardBucket()

    if not rewardBucket then
        return {}
    end

    local retainedRewards = {}

    for _, rewardEntry in ipairs(rewardBucket) do
        if not isHunterRewardEntry(rewardEntry) and not isAllyRewardEntry(rewardEntry) then
            retainedRewards[#retainedRewards + 1] = copyRewardEntry(rewardEntry)
        end
    end

    local hunterEntries = collectMissionDeckCardEntriesByType("hunter")
    local allyEntries = collectMissionDeckCardEntriesByType("ally")

    appendEntries(allyEntries, collectMissionHandCardEntriesByType("ally"))
    appendEntries(retainedRewards, hunterEntries)
    appendEntries(retainedRewards, allyEntries)

    for index = #rewardBucket, 1, -1 do
        rewardBucket[index] = nil
    end

    for index, rewardEntry in ipairs(retainedRewards) do
        rewardBucket[index] = rewardEntry
    end

    return hunterEntries
end

local function addWorldHunterToJaclDeck(_, hunterId)
    local rewardBucket = ensureRunJaclRewardBucket()

    if not rewardBucket or not hunterId then
        return false
    end

    rewardBucket[#rewardBucket + 1] = hunterId
    return true
end

local function removeFirstMatchingHunterReward(rewardBucket, hunterEntry)
    local hunterId = getRewardEntryCardId(hunterEntry)

    if not rewardBucket or not hunterId then
        return false
    end

    for index, rewardEntry in ipairs(rewardBucket) do
        if rewardEntry == hunterEntry then
            table.remove(rewardBucket, index)
            return true
        end
    end

    for index, rewardEntry in ipairs(rewardBucket) do
        if isHunterRewardEntry(rewardEntry) and getRewardEntryCardId(rewardEntry) == hunterId then
            table.remove(rewardBucket, index)
            return true
        end
    end

    return false
end

local function finalizeWorldHunterModal(_, modal)
    local rewardBucket = ensureRunJaclRewardBucket()

    if not rewardBucket or not modal then
        return false
    end

    local shouldAddNewHunter = true

    for _, lockedHunter in pairs(modal.lockedHunters or {}) do
        if lockedHunter.source == "new" then
            shouldAddNewHunter = false
        elseif lockedHunter.source == "existing" then
            removeFirstMatchingHunterReward(rewardBucket, lockedHunter.entry)
        end
    end

    if shouldAddNewHunter and modal.newHunterId then
        rewardBucket[#rewardBucket + 1] = modal.newHunterId
    end

    return true
end

local function getMissionDeadCrewRoleNames()
    local orderedRoles = { "Captain", "Surgeon", "Sheriff", "Tactician", "Engineer" }
    local roleNames = {}
    local missionDeadCrewRoles = appState.missionDeadCrewRoles or {}

    for _, roleName in ipairs(orderedRoles) do
        local roleKey = crewrules.getCrewRoleKey(roleName)

        if roleKey and missionDeadCrewRoles[roleKey] then
            roleNames[#roleNames + 1] = roleName
        end
    end

    return roleNames
end

local function finalizeWorldCrewReviveModal(_, modal)
    if modal and modal.lockedCrew and modal.lockedCrew.roleName then
        crewrules.markCrewRoleAlive(appState.deadCrewRoles, modal.lockedCrew.roleName)
    end

    appState.missionDeadCrewRoles = {}
    return true
end

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

local function isVictoryInputLocked()
    return appState.victoryTransition
        or appState.championVictoryDestruction
        or appState.worldToMissionTransition
        or appState.pendingMissionSetup
        or false
end

local function beginVictoryTransition()
    appState.victoryTransition = {
        elapsed = 0,
        duration = appconfig.VICTORY_TRANSITION_DURATION,
        coverDuration = appconfig.VICTORY_TRANSITION_COVER_DURATION,
        seed = love.math.random(1, 1000000),
        nextMapPosition = gamestates.getNextPlayerMapPosition(appState),
        switchedToWorld = false,
    }

    if gameState.activeChampion and gameState.activeChampion.defeat then
        sfxrules.playChampionDefeat(gameState.activeChampion.defeat)
    end

    appState.hoveredWorldMapNode = nil
    appState.pinnedWorldMapNode = nil
    appState.worldMapDeckModal = nil
    appState.worldMapObjectivePreviewModal = nil
    appState.worldMapNodePlayButtonTarget = nil
    appState.worldMapNodePlayButtonTargets = nil
    appState.worldMapRewardModal = nil
    appState.worldMapRewardCollectButtonTarget = nil
    appState.worldMapSystemRepair = nil
    appState.worldMapSystemRepairQueue = nil
    clearDomainAwarenessEncounterBonus()
    appState.pendingWorldMapCardReward = nil
    appState.worldMapCardRewardModal = nil
    appState.pendingWorldMapHunterModal = nil
    appState.worldMapHunterModal = nil
    appState.pendingWorldMapCrewReviveModal = nil
    appState.worldMapCrewReviveModal = nil
    appState.worldToMissionTransition = nil
end

local function isVictoryDestructionUnit(card)
    if not card
        or not card.location
        or card.location.kind ~= "grid"
        or card.location.rowId ~= "OppRow"
        or card.destroyed
        or card.destroying then
        return false
    end

    local definition = cardregistry.getCard(card.setName, card.cardId)

    return definition
        and (
            definition.type == "troop"
            or definition.type == "token"
            or definition.type == "agent"
            or definition.classname == "Enemy"
        )
        or false
end

local function beginChampionVictoryDestruction()
    local targetCardIndexes = {}

    startChampionDestruction()

    for cardIndex, card in ipairs(gameState.cards or {}) do
        if isVictoryDestructionUnit(card) then
            targetCardIndexes[#targetCardIndexes + 1] = cardIndex
            startCardDestruction(cardIndex)
        end
    end

    gameState.draggedCardIndex = nil
    gameState.selectedAttackerCardIndex = nil
    gameState.selectedAttackerTopSlotId = nil
    gameState.primedActivatedAbility = nil
    gameState.pendingStrategySelection = nil
    gameState.pendingSacrificeSelection = nil
    gameState.pendingHandLimitDiscardSelection = nil
    gameState.pendingButtonSelection = nil

    appState.championVictoryDestruction = {
        targetCardIndexes = targetCardIndexes,
    }
end

local function hasChampionVictoryDestructionTarget(pending, cardIndex)
    for _, targetCardIndex in ipairs(pending and pending.targetCardIndexes or {}) do
        if targetCardIndex == cardIndex then
            return true
        end
    end

    return false
end

local function queueNewChampionVictoryDestructionTargets()
    local pending = appState.championVictoryDestruction

    if not pending then
        return false
    end

    local queuedAny = false

    for cardIndex, card in ipairs(gameState.cards or {}) do
        if not hasChampionVictoryDestructionTarget(pending, cardIndex)
            and isVictoryDestructionUnit(card) then
            pending.targetCardIndexes[#pending.targetCardIndexes + 1] = cardIndex
            startCardDestruction(cardIndex)
            queuedAny = true
        end
    end

    return queuedAny
end

local function isChampionVictoryDestructionComplete()
    local pending = appState.championVictoryDestruction

    if not pending then
        return true
    end

    if topsloteffects.isChampionDestructionActive() then
        return false
    end

    for _, card in ipairs(gameState.cards or {}) do
        if card
            and card.destroying
            and card.location
            and card.location.kind == "grid"
            and card.location.rowId == "OppRow" then
            return false
        end
    end

    for _, cardIndex in ipairs(pending.targetCardIndexes or {}) do
        local card = gameState.cards and gameState.cards[cardIndex] or nil

        if card and card.destroying then
            return false
        end
    end

    return true
end

resolveChampionDefeated = function()
    if not gamestates.isMissionStage(appState) then
        return appState.victoryTransition ~= nil
    end

    if appState.victoryTransition then
        return true
    end

    if appState.championVictoryDestruction then
        return true
    end

    beginChampionVictoryDestruction()

    return true
end

local function completeVictoryTransitionToWorld(transition)
    if transition.switchedToWorld then
        return
    end

    if transition.nextMapPosition then
        appState.playerMapPosition = transition.nextMapPosition
    else
        gamestates.advancePlayerMapPosition(appState)
    end

    appState.current = "WorldStage"
    appState.hoveredWorldMapNode = nil
    appState.pinnedWorldMapNode = nil
    appState.worldMapDeckModal = nil
    appState.worldMapObjectivePreviewModal = nil
    appState.worldMapNodePlayButtonTarget = nil
    appState.worldMapNodePlayButtonTargets = nil
    appState.worldMapRewardModal = nil
    appState.worldMapRewardCollectButtonTarget = nil
    appState.worldMapSystemRepair = nil
    appState.worldMapSystemRepairQueue = nil
    clearDomainAwarenessEncounterBonus()
    appState.pendingWorldMapCardReward = nil
    appState.worldMapCardRewardModal = nil
    appState.pendingWorldMapHunterModal = nil
    appState.worldMapHunterModal = nil
    appState.pendingWorldMapCrewReviveModal = nil
    appState.worldMapCrewReviveModal = nil
    transition.switchedToWorld = true

    local existingHunterEntries = preserveMissionCardsForWorld()

    local reward = appState.activeMissionReward
    local prize = getMissionRewardAlms()
    local resourceAmount = math.max(0, math.floor(tonumber(reward and reward.resourceAmount) or 0))
    local hasCurrencyReward = prize > 0 or (reward and reward.resourceKey and resourceAmount > 0)

    if rewarddebug and rewarddebug.log then
        rewarddebug.log("completeVictoryTransitionToWorld.reward", {
            hasReward = reward ~= nil,
            prize = prize,
            resourceKey = reward and reward.resourceKey or nil,
            resourceAmount = resourceAmount,
            cardrw = reward and reward.cardrw or nil,
            hasCurrencyReward = hasCurrencyReward,
        })
    end

    if reward and reward.cardrw then
        appState.pendingWorldMapCardReward = reward.cardrw
    end

    if hasCurrencyReward then
        appState.worldMapRewardModal = {
            prize = prize,
            resourceKey = reward and reward.resourceKey or nil,
            resourceAmount = resourceAmount,
            cardrw = reward and reward.cardrw or nil,
        }
    end

    appState.pendingWorldMapHunterModal = {
        newHunterId = "HNTINFFM",
        existingHunters = existingHunterEntries,
        scannerPurchased = gameState.scannerPurchased == true,
        sheriffAlive = not crewrules.isCrewRoleDead(appState.deadCrewRoles, "Sheriff"),
    }

    local missionDeadCrewRoles = getMissionDeadCrewRoleNames()

    if #missionDeadCrewRoles > 0 and not crewrules.isCrewRoleDead(appState.deadCrewRoles, "Surgeon") then
        appState.pendingWorldMapCrewReviveModal = {
            deadCrewRoles = missionDeadCrewRoles,
        }
    else
        appState.missionDeadCrewRoles = {}
    end

    clearActiveMissionReward()
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

getPlayerDefeatControllerContext = function()
    return {
        appState = appState,
        gameState = gameState,
        gamestate = gamestate,
        envdraw = envdraw,
        turnrules = turnrules,
        resourcerules = resourcerules,
        warrules = warrules,
        notifications = notifications,
        cardinstances = cardinstances,
        warzonecontrolrules = warzonecontrolrules,
        topsloteffects = topsloteffects,
        infiltrationrules = infiltrationrules,
        munitionsrules = munitionsrules,
        setSetupScenario = function(nextSetupScenario)
            setupScenario = nextSetupScenario
        end,
    }
end

beginPlayerDefeat = function(objectiveDefinition)
    return playerdefeatcontroller.begin(getPlayerDefeatControllerContext(), objectiveDefinition)
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

local function addStartingCrewCards()
    return crewrules.addStartingCrewCards({
        cards = gameState.cards,
        cardinstances = cardinstances,
        cardregistry = cardregistry,
        deadCrewRoles = appState.deadCrewRoles,
        initializeCardHealthState = initializeCardHealthState,
    })
end

local function getWorldMissionSystems()
    appState.worldMissionSystems = systemrules.ensureSystems(appState.worldMissionSystems)
    return appState.worldMissionSystems
end

local function finishMissionSetup()
    gameState.pendingPhaseEntry = false

    for cardIndex = 1, #gameState.cards do
        gameState.cardExpansion[cardIndex] = 0
        gameState.cardEntranceProgress[cardIndex] = 0
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

local function copyCardRewardBuckets(source)
    local function copyRewardEntry(entry)
        if type(entry) ~= "table" then
            return entry
        end

        local copiedEntry = {}

        for key, value in pairs(entry) do
            copiedEntry[key] = value
        end

        return copiedEntry
    end

    local copied = {
        jacl = {},
        agents = {},
    }

    for ownerId, cardIds in pairs((source and source.jacl) or {}) do
        copied.jacl[ownerId] = {}

        for index, cardId in ipairs(cardIds or {}) do
            copied.jacl[ownerId][index] = copyRewardEntry(cardId)
        end
    end

    for ownerId, cardIds in pairs((source and source.agents) or {}) do
        copied.agents[ownerId] = {}

        for index, cardId in ipairs(cardIds or {}) do
            copied.agents[ownerId][index] = copyRewardEntry(cardId)
        end
    end

    return copied
end

local function collectSetupRewardCardEntries()
    local rewardCardEntries = {}
    local rewards = setupScenario.playerCardRewards or {}
    local jaclRewards = rewards.jacl and rewards.jacl[setupScenario.playerJaclId] or nil

    for _, rewardEntry in ipairs(jaclRewards or {}) do
        rewardCardEntries[#rewardCardEntries + 1] = rewardEntry
    end

    for _, agentId in ipairs(setupScenario.setupAgentIds or {}) do
        local agentRewards = rewards.agents and rewards.agents[agentId] or nil

        for _, rewardEntry in ipairs(agentRewards or {}) do
            rewardCardEntries[#rewardCardEntries + 1] = rewardEntry
        end
    end

    return rewardCardEntries
end

local function applySetupRewardCardsToPlayerDeck()
    if not gameState.playerDeck then
        return 0
    end

    return deckrules.addCardIds(gameState.playerDeck, collectSetupRewardCardEntries(), {
        owner = "player",
        insertRandomly = true,
        source = "card-reward",
    })
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
    sfxrules = sfxrules,
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
    destructionDuration = appconfig.DESTRUCTION_DURATION,
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
    addObjectiveProgress = function(objectiveDefinition, amount, slotId, options)
        return addObjectiveProgress(objectiveDefinition, amount, slotId, options)
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
        gameState.hoveredEnhancement = nil
        gameState.hoveredDiceFace = nil
        gameState.hoveredButtonBadge = nil
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
    gameState.hoveredEnhancement = nil
    gameState.hoveredDiceFace = nil
    gameState.hoveredButtonBadge = nil
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

    local baselineRerolls = 2 + math.max(0, tonumber(gameState.domainAwarenessRerollBonus) or 0)

    if gameState.engageRerollCount > baselineRerolls then
        gameState.engageRerollCount = baselineRerolls
    end
end

local function getDomainAwarenessOpeningHandBonus()
    return math.max(0, math.floor(tonumber(gameState.domainAwarenessOpeningHandBonus) or 0))
end

local function applyPendingDomainAwarenessToMission()
    local pending = appState.pendingDomainAwareness

    gameState.domainAwarenessRerollBonus = 0
    gameState.domainAwarenessOpeningHandBonus = 0

    if not pending then
        return
    end

    gameState.domainAwarenessRerollBonus = math.max(0, math.floor(tonumber(pending.rerollBonus) or 0))
    gameState.domainAwarenessOpeningHandBonus = math.max(0, math.floor(tonumber(pending.openingHandBonus) or 0))

    if pending.methodResourceBonus then
        for _, resourceName in ipairs(DOMAIN_AWARENESS_METHOD_RESOURCES) do
            resourcerules.addResource(resourceName, 1)
        end
    end
end

clearDomainAwarenessEncounterBonus = function()
    appState.pendingDomainAwareness = nil
    gameState.domainAwarenessRerollBonus = 0
    gameState.domainAwarenessOpeningHandBonus = 0
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

beginHunterDeckDiscardAnimation = function(card)
    return animationbridge.beginHunterDeckDiscardAnimation(animationbridgeState, card)
end

beginHaywireDeckAddAnimation = function(card)
    return animationbridge.beginHaywireDeckAddAnimation(animationbridgeState, card)
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

updateHunterDeckDiscardAnimations = function(dt)
    animationbridge.updateHunterDeckDiscardAnimations(animationbridgeState, dt)
end

updateHaywireDeckAddAnimations = function(dt)
    animationbridge.updateHaywireDeckAddAnimations(animationbridgeState, dt)
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

drawHunterDeckDiscardAnimations = function()
    animationbridge.drawHunterDeckDiscardAnimations(animationbridgeState)
end

drawHaywireDeckAddAnimations = function()
    animationbridge.drawHaywireDeckAddAnimations(animationbridgeState)
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

addObjectiveProgress = function(objectiveDefinition, amount, slotId, options)
    return lifecyclebridge.addObjectiveProgress(lifecyclebridgeState, objectiveDefinition, amount, slotId, options)
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

local function getHaywireHandObjectiveProgress()
    return haywirerules.getHandEmphasis({
        state = gameState,
        cardregistry = cardregistry,
    })
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
    local damageResult = lifecyclebridge.dealDamageToChampion(lifecyclebridgeState, amount, suppressFeedback)
    local championHealth = gameState.activeChampion and tonumber(gameState.activeChampion.health) or nil

    if gamestates.isMissionStage(appState)
        and championHealth
        and championHealth <= 0 then
        resolveChampionDefeated(damageResult)
    elseif gamestates.isMissionStage(appState) then
        surrendermodal.maybeOffer(gameState, damageResult, getMissionRewardAlms())
    end

    return damageResult
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

local function tryResolvePendingStrategySelection(cardIndex, topSlotId)
    return cardplaycontroller.tryResolvePendingStrategySelection(cardIndex, getCardPlayControllerContext(), topSlotId)
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

local function getCardButtonBadgeTarget(mouseX, mouseY)
    return boardquery.getCardButtonBadgeTarget(getBoardQueryContext(), mouseX, mouseY)
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

local function getButtonRulesContext()
    return {
        state = gameState,
        cards = gameState.cards,
        cardregistry = cardregistry,
        buttonrules = buttonrules,
        systemrules = systemrules,
        turnrules = turnrules,
        notifications = notifications,
        deckrules = deckrules,
        beginHunterDeckDiscardAnimation = beginHunterDeckDiscardAnimation,
        drawCardFromPlayerDeck = drawCardFromPlayerDeck,
        isCardUnavailable = isCardUnavailable,
    }
end

local function tryUseCardButtonBadge(cardIndex)
    return buttonrules.useButton(cardIndex, getButtonRulesContext())
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
        appState = appState,
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
        enhancementrules = enhancementrules,
        haywirerules = haywirerules,
        keywordrules = keywordrules,
        previewrules = previewrules,
        kitrules = kitrules,
        modals = modals,
        munitionsrules = munitionsrules,
        tithesrules = tithesrules,
        notifications = notifications,
        objectiverules = objectiverules,
        phasecontroller = phasecontroller,
        resourcerules = resourcerules,
        sfxrules = sfxrules,
        strategyrules = strategyrules,
        systemrules = systemrules,
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
        addStartingCrewCards = addStartingCrewCards,
        addWarzoneControl = addWarzoneControl,
        applyModalState = applyModalState,
        beginEndPhaseSacrificeSelection = beginEndPhaseSacrificeSelection,
        beginHaywireDeckAddAnimation = beginHaywireDeckAddAnimation,
        beginInfiltrationEffect = beginInfiltrationEffect,
        beginKitReturnAnimation = beginKitReturnAnimation,
        beginObjectiveEscalation = beginObjectiveEscalation,
        beginObjectiveHunterDeckTransformation = beginObjectiveHunterDeckTransformation,
        beginPlayerDefeat = beginPlayerDefeat,
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
        getOpeningHandBonus = getDomainAwarenessOpeningHandBonus,
        drawHunterAutoPlayAnimations = drawHunterAutoPlayAnimations,
        drawHunterDeckDiscardAnimations = drawHunterDeckDiscardAnimations,
        drawHaywireDeckAddAnimations = drawHaywireDeckAddAnimations,
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
        getCardButtonBadgeTarget = getCardButtonBadgeTarget,
        getCardMethodBadgeTarget = getCardMethodBadgeTarget,
        getChampionPlayContext = getChampionPlayContext,
        getCardPresentationContext = getCardPresentationContext,
        getDamageJitterKeyForCard = getDamageJitterKeyForCard,
        getDamageJitterOffset = getDamageJitterOffset,
        getEndPhaseObjectiveProgress = getEndPhaseObjectiveProgress,
        getHaywireHandObjectiveProgress = getHaywireHandObjectiveProgress,
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
        resolveChampionDefeated = resolveChampionDefeated,
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
        tryUseCardButtonBadge = tryUseCardButtonBadge,
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
    munitionsrules.reset()
    appState.missionDeadCrewRoles = {}
    clearDomainAwarenessEncounterBonus()
    gameState.missionSystems = getWorldMissionSystems()
    applyPendingDomainAwarenessToMission()
    gameState.playerJacl = jaclrules.getJacl(setupScenario.playerJaclId)
    gameState.munitionsSystem = munitionsrules.getJaclMunitions(gameState.playerJacl)
    gameState.titheSystem = tithesrules.getJaclTithe(gameState.playerJacl)
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

    applySetupRewardCardsToPlayerDeck()

    if gameState.playerDeck then
        gameState.playerDeck.owner = "player"

        for _, deckCard in ipairs(gameState.playerDeck.cards) do
            deckCard.deckOwner = "player"
        end
    end

    if gameState.championDeck then
        gameState.championDeck.owner = "champion"
        gameState.championDeck.shuffleOnReset = #(setupScenario.championAdditionalDeckIds or {}) > 0

        for _, deckCard in ipairs(gameState.championDeck.cards) do
            deckCard.deckOwner = "champion"
        end

        if gameState.championDeck.shuffleOnReset then
            deckrules.shuffleDeck(gameState.championDeck)
        end
    end

    enterCurrentPhase()
    finishMissionSetup()
end

local function applyWorldMissionPayload(payload)
    if rewarddebug and rewarddebug.log then
        rewarddebug.log("applyWorldMissionPayload", {
            prize = payload and payload.prize or nil,
            cardrw = payload and payload.cardrw or nil,
            jaclId = payload and payload.jaclId or nil,
            agentIds = payload and payload.agentIds or nil,
            championId = payload and payload.championId or nil,
            warzoneId = payload and payload.warzoneId or nil,
        })
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
    setupScenario.playerCardRewards = copyCardRewardBuckets(appState.selectedRunCardRewards)
    setActiveMissionReward({
        alms = payload.prize,
        source = "victory",
        cardrw = payload.cardrw,
    })

    for _, deckId in ipairs(payload.championAdditionalDeckIds or {}) do
        setupScenario.championAdditionalDeckIds[#setupScenario.championAdditionalDeckIds + 1] = deckId
    end
end

local function buildMissionSetupQueue(saveSlotId, saveTimestamp)
    return {
        {
            id = "reset",
            action = function()
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
                munitionsrules.reset()
                appState.missionDeadCrewRoles = {}
                gameState.missionSystems = getWorldMissionSystems()
                applyPendingDomainAwarenessToMission()
            end,
        },
        {
            id = "definitions",
            action = function()
                gameState.playerJacl = jaclrules.getJacl(setupScenario.playerJaclId)
                gameState.munitionsSystem = munitionsrules.getJaclMunitions(gameState.playerJacl)
                gameState.titheSystem = tithesrules.getJaclTithe(gameState.playerJacl)
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
            end,
        },
        {
            id = "preload-champion",
            action = function()
                envdraw.preloadTopStripAssets(gameState.activeChampion, nil, nil, nil, nil)
            end,
        },
        {
            id = "preload-warzone",
            action = function()
                envdraw.preloadTopStripAssets(nil, gameState.activeWarzone, nil, nil, nil)
            end,
        },
        {
            id = "preload-objective",
            action = function()
                envdraw.preloadTopStripAssets(nil, nil, nil, gameState.activePrimaryObjective, nil)
            end,
        },
        {
            id = "preload-intel",
            action = function()
                envdraw.preloadTopStripAssets(nil, nil, nil, nil, gameState.activeIntel)
            end,
        },
        {
            id = "preload-warzone-family",
            action = function()
                preloadWarzoneFamily(gameState.activeWarzone)
            end,
        },
        {
            id = "player-deck",
            action = function()
                gameState.playerDeck = gameState.playerJacl
                    and deckrules.buildDeckWithAdditionalDecks(gameState.playerJacl.deckId, getSetupAgentDeckIds())
                    or nil
            end,
        },
        {
            id = "player-reward-cards",
            action = function()
                applySetupRewardCardsToPlayerDeck()
            end,
        },
        {
            id = "champion-deck",
            action = function()
                gameState.championDeck = gameState.activeChampion
                    and gameState.activeChampion.deckId
                    and deckrules.buildDeckWithAdditionalDecks(gameState.activeChampion.deckId, setupScenario.championAdditionalDeckIds or {})
                    or nil
            end,
        },
        {
            id = "deck-owners",
            action = function()
                if gameState.playerDeck then
                    gameState.playerDeck.owner = "player"

                    for _, deckCard in ipairs(gameState.playerDeck.cards) do
                        deckCard.deckOwner = "player"
                    end
                end

                if gameState.championDeck then
                    gameState.championDeck.owner = "champion"
                    gameState.championDeck.shuffleOnReset = #(setupScenario.championAdditionalDeckIds or {}) > 0

                    for _, deckCard in ipairs(gameState.championDeck.cards) do
                        deckCard.deckOwner = "champion"
                    end

                    if gameState.championDeck.shuffleOnReset then
                        deckrules.shuffleDeck(gameState.championDeck)
                    end
                end
            end,
        },
        {
            id = "opening-hand",
            action = function()
                local firstCardId = gameState.playerJacl and gameState.playerJacl.tomeId or nil
                local openingHandSize = (firstCardId and 7 or 6) + getDomainAwarenessOpeningHandBonus()

                gameState.cards = deckrules.assignCardsToHand(gameState.playerDeck, openingHandSize, {
                    firstCardId = firstCardId,
                })
                gameState.mulliganSelection = {}
                gameState.mulliganActive = gameState.mulliganCompleted ~= true
                gameState.mulliganResolving = false
                gameState.mulliganReturnedCards = nil
                gameState.mulliganPromptAlpha = 0
                initializeCardsHealthState(gameState.cards)
            end,
        },
        {
            id = "hunters",
            action = function()
                resolveHuntersInHand()
            end,
        },
        {
            id = "crew",
            action = function()
                addStartingCrewCards()
            end,
        },
        {
            id = "agents",
            action = function()
                addSetupAgents()
                normalizeSetupCardSlots()
            end,
        },
        {
            id = "prewarm-card-render-assets",
            cursor = 1,
            process = function(step)
                local cards = gameState.cards or {}
                local card = cards[step.cursor]

                if not card then
                    return true
                end

                if carddraw.preloadCardRenderAssets then
                    carddraw.preloadCardRenderAssets(card.setName, card.cardId, {
                        card = card,
                        portraitPath = card.portraitPath,
                    })
                end

                step.cursor = step.cursor + 1
                return false
            end,
        },
        {
            id = "finalize",
            action = function()
                finishMissionSetup()
                appState.current = "MissionStage"
            end,
        },
    }
end

local function beginQueuedMissionSetup(saveSlotId, saveTimestamp)
    return {
        steps = buildMissionSetupQueue(saveSlotId, saveTimestamp),
        index = 1,
        complete = false,
    }
end

local function processMissionSetupQueue(queue)
    if not queue or queue.complete then
        return true
    end

    local step = queue.steps and queue.steps[queue.index] or nil

    if not step then
        queue.complete = true
        return true
    end

    if step.process then
        queue.lastStepId = step.id

        if not step.process(step, queue) then
            return false
        end
    elseif step.action then
        step.action()
    end

    queue.lastStepId = step.id
    queue.index = queue.index + 1
    queue.complete = queue.index > #(queue.steps or {})
    return queue.complete
end

local function beginWorldToMissionTransition()
    appState.worldToMissionTransition = {
        elapsed = 0,
        duration = appconfig.WORLD_TO_MISSION_TRANSITION_DURATION,
        seed = love.math.random(1, 1000000),
        missionReady = true,
    }
end

startMissionFromWorldNode = function(payload)
    if not payload or not payload.jaclId or not payload.championId or not payload.warzoneId then
        return false
    end

    applyWorldMissionPayload(payload)
    appState.worldMapDeckModal = nil
    appState.worldMapObjectivePreviewModal = nil
    appState.worldMapNodePlayButtonTarget = nil
    appState.worldMapNodePlayButtonTargets = nil
    appState.worldMapRewardModal = nil
    appState.worldMapRewardCollectButtonTarget = nil
    appState.worldMapSystemRepair = nil
    appState.worldMapSystemRepairQueue = nil
    appState.pendingWorldMapCardReward = nil
    appState.worldMapCardRewardModal = nil
    appState.pendingWorldMapHunterModal = nil
    appState.worldMapHunterModal = nil
    appState.pendingWorldMapCrewReviveModal = nil
    appState.worldMapCrewReviveModal = nil
    appState.victoryTransition = nil
    appState.worldToMissionTransition = nil
    appState.pendingMissionSetup = {
        setupQueue = beginQueuedMissionSetup(appState.selectedSaveSlot, appState.selectedSaveTimestamp),
        complete = false,
        elapsed = 0,
    }

    return true
end

function love.load()
    if rewarddebug and rewarddebug.clear then
        rewarddebug.clear()
        rewarddebug.log("love.load")
    end

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
    if playerdefeatcontroller.hasOpen(getPlayerDefeatControllerContext()) then
        playerdefeatcontroller.update(getPlayerDefeatControllerContext(), dt)
        return
    end

    if appState.victoryTransition then
        local transition = appState.victoryTransition
        local coverDuration = math.max(0.01, transition.coverDuration or transition.duration or 1)

        transition.elapsed = transition.elapsed + (dt or 0)

        if not transition.switchedToWorld and transition.elapsed >= coverDuration then
            completeVictoryTransitionToWorld(transition)
        end

        if transition.elapsed >= math.max(coverDuration, transition.duration or coverDuration) then
            if not transition.switchedToWorld then
                completeVictoryTransitionToWorld(transition)
            end

            appState.victoryTransition = nil
        end

        return
    end

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

    if appState.pendingMissionSetup then
        local pendingSetup = appState.pendingMissionSetup

        pendingSetup.elapsed = pendingSetup.elapsed + (dt or 0)
        pendingSetup.complete = processMissionSetupQueue(pendingSetup.setupQueue)

        if pendingSetup.complete then
            appState.pendingMissionSetup = nil
            appState.loadingWorldMapNode = nil
            beginWorldToMissionTransition()
        end

        return
    end

    if appState.championVictoryDestruction then
        cardlifecycle.updateDestroyedCards(getCardLifecycleContext(), dt)
        queueNewChampionVictoryDestructionTargets()

        local topSlotEffectEvents = topsloteffects.update(dt)

        if topSlotEffectEvents.championDestroyed and gameState.activeChampion then
            gameState.activeChampion.hidden = true
        end

        for entityKey, jitter in pairs(gameState.damageJitters) do
            jitter.elapsed = jitter.elapsed + dt

            if jitter.elapsed >= jitter.duration then
                gameState.damageJitters[entityKey] = nil
            end
        end

        notifications.update(dt)
        updateHoveredCard()

        if isChampionVictoryDestructionComplete() then
            appState.championVictoryDestruction = nil
            beginVictoryTransition()
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

    if gameState.activeChampion
        and (tonumber(gameState.activeChampion.health) or 0) <= 0
        and resolveChampionDefeated() then
        return
    end

    local entranceDt = math.min(dt, appconfig.CARD_ENTRANCE_MAX_DT)

    if surrendermodal.hasOpenModal(gameState) then
        for entityKey, jitter in pairs(gameState.damageJitters) do
            jitter.elapsed = jitter.elapsed + dt

            if jitter.elapsed >= jitter.duration then
                gameState.damageJitters[entityKey] = nil
            end
        end

        notifications.update(dt)
        updateHoveredCard()
        return
    end

    gameState.cardEntranceTimer = gameState.cardEntranceTimer + entranceDt
    resourcerules.update(dt)
    munitionsrules.update(dt, {
        sfxrules = sfxrules,
    })
    updateKitReturnAnimations(dt)
    updatePilotVehicleAnimations(dt)
    updateHunterAutoPlayAnimations(dt)
    updateHunterDeckDiscardAnimations(dt)
    updateHaywireDeckAddAnimations(dt)
    updateMulliganAnimations(dt)

    cardlifecycle.updateDestroyedCards(getCardLifecycleContext(), dt)

    if gamestates.isWorldStage(appState) then
        return
    end

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
    if playerdefeatcontroller.hasOpen(getPlayerDefeatControllerContext()) then
        playerdefeatcontroller.mousepressed(getPlayerDefeatControllerContext(), x, y, button)
        return
    end

    if isVictoryInputLocked() then
        return
    end

    if surrendermodal.hasOpenModal(gameState) then
        surrendermodal.mousepressed(gameState, x, y, button, {
            beginChampionVictoryDestruction = beginChampionVictoryDestruction,
            setActiveMissionReward = setActiveMissionReward,
            sfxrules = sfxrules,
        })
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
            addWorldHunterToJaclDeck = addWorldHunterToJaclDeck,
            finalizeWorldHunterModal = finalizeWorldHunterModal,
            finalizeWorldCrewReviveModal = finalizeWorldCrewReviveModal,
        })
        return
    end

    inputcontroller.mousepressed(gameState, getInputControllerDeps(), x, y, button)
end

function love.wheelmoved(_, y)
    if playerdefeatcontroller.hasOpen(getPlayerDefeatControllerContext()) then
        return
    end

    if isVictoryInputLocked() then
        return
    end

    if surrendermodal.hasOpenModal(gameState) then
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
    if playerdefeatcontroller.hasOpen(getPlayerDefeatControllerContext()) then
        return
    end

    if isVictoryInputLocked() then
        return
    end

    if surrendermodal.hasOpenModal(gameState) then
        return
    end

    if gamestates.isWorldStage(appState) then
        gamestates.mousereleasedWorldStage(appState, x, y, button, {
            sfxrules = sfxrules,
            finalizeWorldHunterModal = finalizeWorldHunterModal,
            finalizeWorldCrewReviveModal = finalizeWorldCrewReviveModal,
        })
        return
    end

    if gamestates.isFileSelect(appState) then
        return
    end

    inputcontroller.mousereleased(gameState, getInputControllerDeps(), x, y, button)
end

function love.keypressed(key)
    if playerdefeatcontroller.hasOpen(getPlayerDefeatControllerContext()) then
        return
    end

    if isVictoryInputLocked() then
        return
    end

    if surrendermodal.hasOpenModal(gameState) then
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
        munitionsrules = munitionsrules,
        tithesrules = tithesrules,
        cardregistry = cardregistry,
        crewrules = crewrules,
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
        missionSystems = gameState.missionSystems,
        expandedTopSlotId = gameState.expandedTopSlotId,
        topSlotExpansion = gameState.topSlotExpansion,
        playerJacl = gameState.playerJacl,
        engageRerollCount = gameState.engageRerollCount,
        syntacCount = gameState.syntacCount,
        syntacRewardButtons = gameState.syntacRewardButtons,
        worldResources = appState.worldResources,
        munitionsSystem = gameState.munitionsSystem,
        titheSystem = gameState.titheSystem,
        getRetaliationPhaseObjectiveProgress = getRetaliationPhaseObjectiveProgress,
        getEndPhaseObjectiveProgress = getEndPhaseObjectiveProgress,
        getHaywireHandObjectiveProgress = getHaywireHandObjectiveProgress,
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
            or (
                gameState.pendingButtonSelection
                and (gameState.pendingButtonSelection.prompt or "Choose a target")
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
        hoveredEnhancement = gameState.hoveredEnhancement,
        hoveredDiceFace = gameState.hoveredDiceFace,
        hoveredButtonBadge = gameState.hoveredButtonBadge,
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
        isHunterCard = isHunterCard,
        getCardDrawPosition = getCardDrawPosition,
        drawCardStateOverlays = drawCardStateOverlays,
        getDropCell = getDropCell,
        getCardRenderOptions = getCardRenderOptions,
        drawTopSlotHoverTargetBrackets = drawTopSlotHoverTargetBrackets,
        drawInfiltrationEffect = drawInfiltrationEffect,
        drawKitReturnAnimations = drawKitReturnAnimations,
        drawHunterAutoPlayAnimations = drawHunterAutoPlayAnimations,
        drawHunterDeckDiscardAnimations = drawHunterDeckDiscardAnimations,
        drawHaywireDeckAddAnimations = drawHaywireDeckAddAnimations,
        drawPilotVehicleAnimations = drawPilotVehicleAnimations,
    })

    surrendermodal.draw(gameState)
    playerdefeatcontroller.draw(getPlayerDefeatControllerContext())
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

    if transition.missionReady and scanlineY > 0 then
        love.graphics.setScissor(0, 0, windowWidth, scanlineY)
        love.graphics.setColor(0.045, 0.047, 0.055, 1)
        love.graphics.rectangle("fill", 0, 0, windowWidth, scanlineY)
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

function drawVictoryTransition(transition)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local elapsed = transition.elapsed or 0
    local coverDuration = math.max(0.01, transition.coverDuration or appconfig.VICTORY_TRANSITION_COVER_DURATION)
    local totalDuration = math.max(coverDuration, transition.duration or appconfig.VICTORY_TRANSITION_DURATION)
    local coverProgress = math.max(0, math.min(1, elapsed / coverDuration))
    local easedCoverProgress = coverProgress * coverProgress * (3 - (2 * coverProgress))
    local fadeProgress = transition.switchedToWorld
        and math.max(0, math.min(1, (elapsed - coverDuration) / math.max(0.01, totalDuration - coverDuration)))
        or 0
    local overlayAlpha = transition.switchedToWorld and (1 - fadeProgress) or 1
    local fireEdgeX = math.floor(windowWidth * easedCoverProgress)
    local fireBandWidth = appconfig.VICTORY_TRANSITION_FIRE_BAND_WIDTH
    local fireBandLeft = math.max(0, fireEdgeX - fireBandWidth)
    local smokeAlpha = 0.82 * overlayAlpha
    local noiseSeed = (transition.seed or 1) + math.floor(elapsed * 72)

    if transition.switchedToWorld then
        gamestates.drawWorldStage(appState)
    else
        drawMissionStage()
    end

    local function noiseValue(index)
        return (math.sin((noiseSeed + index) * 12.9898) * 43758.5453) % 1
    end

    local function noiseRange(index, minValue, maxValue)
        return minValue + ((maxValue - minValue) * noiseValue(index))
    end

    if fireEdgeX > 0 then
        love.graphics.setColor(0.025, 0.02, 0.018, smokeAlpha)
        love.graphics.rectangle("fill", 0, 0, fireEdgeX, windowHeight)
    end

    for stripIndex = 1, appconfig.VICTORY_TRANSITION_SMOKE_STRIP_COUNT do
        local stripX = math.floor(noiseRange(stripIndex * 6, -80, math.max(1, fireEdgeX)))
        local stripY = math.floor(noiseRange((stripIndex * 6) + 1, -40, windowHeight))
        local stripWidth = math.floor(noiseRange((stripIndex * 6) + 2, 80, 260))
        local stripHeight = math.floor(noiseRange((stripIndex * 6) + 3, 24, 96))
        local alpha = noiseRange((stripIndex * 6) + 4, 0.08, 0.26) * overlayAlpha

        love.graphics.setColor(0.07, 0.065, 0.06, alpha)
        love.graphics.rectangle("fill", stripX, stripY, stripWidth, stripHeight, 10, 10)
    end

    if not transition.switchedToWorld then
        love.graphics.setColor(1, 0.18, 0.04, 0.82)
        love.graphics.rectangle("fill", fireBandLeft, 0, math.max(1, fireEdgeX - fireBandLeft), windowHeight)
        love.graphics.setColor(1, 0.74, 0.26, 0.58)
        love.graphics.rectangle("fill", math.max(0, fireEdgeX - 14), 0, 14, windowHeight)
    end

    for emberIndex = 1, appconfig.VICTORY_TRANSITION_EMBER_COUNT do
        local baseX = noiseRange(emberIndex * 7, fireBandLeft - 40, math.min(windowWidth + 40, fireEdgeX + 90))
        local rise = (elapsed * noiseRange((emberIndex * 7) + 1, 42, 154)) % (windowHeight + 80)
        local emberX = math.floor(baseX + math.sin(elapsed * noiseRange((emberIndex * 7) + 2, 1.2, 4.2)) * 18)
        local emberY = math.floor(windowHeight - rise + noiseRange((emberIndex * 7) + 3, -24, 24))
        local emberSize = math.floor(noiseRange((emberIndex * 7) + 4, 2, 6))
        local alpha = noiseRange((emberIndex * 7) + 5, 0.22, 0.9) * overlayAlpha

        if emberX >= -12 and emberX <= windowWidth + 12 and emberY >= -12 and emberY <= windowHeight + 12 then
            if noiseValue((emberIndex * 7) + 6) < 0.7 then
                love.graphics.setColor(1, 0.33, 0.06, alpha)
            else
                love.graphics.setColor(1, 0.84, 0.35, alpha)
            end

            love.graphics.rectangle("fill", emberX, emberY, emberSize, emberSize)
        end
    end

    if transition.switchedToWorld then
        love.graphics.setColor(0.02, 0.018, 0.016, 0.48 * overlayAlpha)
        love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function love.draw()
    if appState.victoryTransition then
        drawVictoryTransition(appState.victoryTransition)
        return
    end

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
