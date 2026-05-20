local championplayrules = require("src.system.championplayrules")
local systemrules = require("src.system.systemrules")

local gamestate = {}

local DEFAULT_SCENARIO = {
    playerJaclId = "JACL001",
    activeChampionId = "CH0001",
    activeWarzoneId = "WZ0001",
    randomWarzoneSuffix = "B",
    activePoiId = "POI0001",
    activePrimaryObjectiveId = "PRIMOBJ0001",
    setupAgentIds = {
        "AGT0001",
        "AGT0002",
    },
}

local function copyArray(source)
    local copied = {}

    for index, value in ipairs(source or {}) do
        copied[index] = value
    end

    return copied
end

function gamestate.getDefaultScenario()
    return {
        playerJaclId = DEFAULT_SCENARIO.playerJaclId,
        activeChampionId = DEFAULT_SCENARIO.activeChampionId,
        activeWarzoneId = DEFAULT_SCENARIO.activeWarzoneId,
        randomWarzoneSuffix = DEFAULT_SCENARIO.randomWarzoneSuffix,
        activePoiId = DEFAULT_SCENARIO.activePoiId,
        activePrimaryObjectiveId = DEFAULT_SCENARIO.activePrimaryObjectiveId,
        setupAgentIds = copyArray(DEFAULT_SCENARIO.setupAgentIds),
    }
end

function gamestate.createInitialState()
    return {
        playerJacl = nil,
        activeChampion = nil,
        activeWarzone = nil,
        activePoi = nil,
        activePrimaryObjective = nil,
        activeIntel = nil,
        missionSystems = systemrules.createFreshSystems(),
        munitionsSystem = nil,
        titheSystem = nil,
        playerDeck = nil,
        championDeck = nil,
        cards = {},
        saveSlotId = nil,
        saveTimestamp = nil,

        hoveredCardIndex = nil,
        hoveredTopSlotId = nil,
        hoveredKeyword = nil,
        hoveredEnhancement = nil,
        hoveredDiceFace = nil,
        hoveredButtonBadge = nil,
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
        domainAwarenessRerollBonus = 0,
        domainAwarenessOpeningHandBonus = 0,
        syntacCount = 0,
        syntacRewardButtons = {},
        syntacMethodRewardAnimating = false,
        scannerPurchased = false,
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
        hoveredTomeSpawnPreviewCardEntries = nil,
        hoveredTomeSpawnPreviewCards = nil,
        hoveredTomeSpawnPreviewLabel = nil,
        hoveredTomeSpawnPreviewCardIndex = nil,
        hoveredCardAbilityPreviewCardEntries = nil,
        hoveredCardAbilityPreviewCards = nil,
        hoveredCardAbilityPreviewLabel = nil,
        hoveredCardAbilityPreviewDefinition = nil,
        hoveredCardAbilityPreviewCardIndex = nil,
        pendingStrategySelection = nil,
        pendingSacrificeSelection = nil,
        pendingHandLimitDiscardSelection = nil,
        pendingButtonSelection = nil,
        championSurrender = {
            offered = false,
            rejected = false,
            modal = nil,
        },
        endPhaseHandLimitDiscardHandled = false,
        endPhaseDrawHandled = false,
        endPhasePoiHandled = false,
        endPhaseSacrificeHandled = false,
        endPhaseHaywireHandled = false,
        mulliganActive = false,
        mulliganCompleted = false,
        mulliganSelection = {},
        mulliganResolving = false,
        mulliganReturnedCards = nil,
        mulliganPromptAlpha = 0,
        kitReturnAnimations = {},
        pilotVehicleAnimations = {},
        hunterAutoPlayAnimations = {},
        hunterDeckDiscardAnimations = {},
        haywireDeckAddAnimations = {},
        hasRenderedFirstFrame = false,
        pendingPhaseEntry = false,
        pendingSetupCompletion = false,
        worldMapEncounterPreviewCache = {},
    }
end

function gamestate.resetForNewRun(state)
    local freshState = gamestate.createInitialState()

    for key in pairs(state) do
        state[key] = nil
    end

    for key, value in pairs(freshState) do
        state[key] = value
    end

    return state
end

return gamestate
