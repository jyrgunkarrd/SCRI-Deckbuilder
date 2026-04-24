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
local temporaryeffects = require("src.system.temporaryeffects")
local kitrules = require("src.system.kitrules")
local resourcerules = require("src.system.resourcerules")
local specialrules = require("src.system.specialrules")
local abilityrules = require("src.system.abilityrules")
local infiltrationrules = require("src.system.infiltrationrules")
local strategyrules = require("src.system.strategyrules")
local tomerules = require("src.system.tomerules")
local trooprules = require("src.system.trooprules")
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
local KIT_RETURN_FLASH_DURATION = 0.1
local KIT_RETURN_EXPAND_DURATION = 0.14
local KIT_RETURN_FLY_DURATION = 0.28
local KIT_RETURN_TOTAL_DURATION = KIT_RETURN_FLASH_DURATION + KIT_RETURN_EXPAND_DURATION + KIT_RETURN_FLY_DURATION
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
    hoveredDiceFace = nil,
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
    primedActivatedAbility = nil,
    fullArtImage = nil,
    hoveredJaclSpecialDefinition = nil,
    hoveredJaclSpecialPreviewCard = nil,
    hoveredTomeSpawnPreviewCard = nil,
    hoveredTomeSpawnPreviewCards = nil,
    hoveredTomeSpawnPreviewLabel = nil,
    pendingStrategySelection = nil,
    pendingSacrificeSelection = nil,
    endPhaseSacrificeHandled = false,
    kitReturnAnimations = {},
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

local function getClosestOpenGridColumns(rowId, anchorColumn, ignoredCardIndex, preferredColumn)
    local row = rowId and envdraw.getGridRow(rowId) or nil
    local columns = {}
    local preferredIsOpen = false

    if not row or not anchorColumn then
        return columns
    end

    for _, cell in ipairs(row.cells or {}) do
        local column = cell.column

        if column and not cardzones.isGridRowColumnOccupied(gameState.cards, rowId, column, ignoredCardIndex) then
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

local function spawnTokensNearCard(sourceCardIndex, tokenDefinition, count, options)
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
    local preferredColumn = options and options.preferredColumn or nil
    local ignoredCardIndex = options and options.ignoredCardIndex or nil
    local openColumns = getClosestOpenGridColumns(rowId, sourceCard.location.column, ignoredCardIndex, preferredColumn)

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

local function spawnRandomTokensNearCard(sourceCardIndex, tokenDefinitions, count, options)
    local sourceCard = sourceCardIndex and gameState.cards[sourceCardIndex] or nil

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
    local openColumns = getClosestOpenGridColumns(rowId, sourceCard.location.column, ignoredCardIndex, preferredColumn)

    for _, column in ipairs(openColumns) do
        if spawnedCount >= count then
            break
        end

        local tokenDefinition = tokenDefinitions[love.math.random(1, #tokenDefinitions)]

        if createGeneratedGridCard(tokenDefinition, rowId, column) then
            spawnedCount = spawnedCount + 1
        end
    end

    return spawnedCount
end

local function spawnTokensNearPlayerCard(sourceCardIndex, tokenDefinition, count, options)
    local sourceCard = sourceCardIndex and gameState.cards[sourceCardIndex] or nil

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
    local openColumns = getClosestOpenGridColumns("PlayerRow", sourceCard.location.column, ignoredCardIndex, preferredColumn)

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

local function findPlayerCacheCard(cacheCardId)
    for cardIndex, card in ipairs(gameState.cards) do
        if card
            and not isCardUnavailable(card)
            and card.location
            and card.location.kind == "grid"
            and card.location.rowId == "PlayerRow"
            and card.cardId == cacheCardId then
            return cardIndex, card
        end
    end

    return nil, nil
end

local function createOrStackPlayerCacheNearCard(sourceCardIndex, cacheDefinition, count)
    local sourceCard = sourceCardIndex and gameState.cards[sourceCardIndex] or nil
    local stackCount = math.max(0, math.floor(tonumber(count) or 0))

    if not sourceCard
        or not sourceCard.location
        or sourceCard.location.kind ~= "grid"
        or not cacheDefinition
        or stackCount <= 0 then
        return 0
    end

    local _, existingCache = findPlayerCacheCard(cacheDefinition.id)

    if existingCache then
        existingCache.currentHealth = math.max(0, tonumber(existingCache.currentHealth) or 0) + stackCount
        existingCache.maxHealth = math.max(existingCache.currentHealth, math.max(0, tonumber(existingCache.maxHealth) or 0))
        return stackCount
    end

    local spawnedCache = nil
    local openColumns = getClosestOpenGridColumns("PlayerRow", sourceCard.location.column)

    for _, column in ipairs(openColumns) do
        spawnedCache = createGeneratedGridCard(cacheDefinition, "PlayerRow", column)

        if spawnedCache then
            spawnedCache.currentHealth = stackCount
            spawnedCache.maxHealth = stackCount
            break
        end
    end

    return spawnedCache and stackCount or 0
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

local function beginKitReturnAnimation(hostCard, attachedKit, returningCard)
    if not hostCard or not attachedKit or not returningCard then
        return false
    end

    local hostCardIndex = nil

    for cardIndex, candidateCard in ipairs(gameState.cards) do
        if candidateCard == hostCard then
            hostCardIndex = cardIndex
            break
        end
    end

    if not hostCardIndex then
        return false
    end

    local drawX, drawY, expansionProgress, renderOptions = getCardDrawPosition(hostCard, hostCardIndex)
    local badgeRect = carddraw.getKeywordBadgeRect(hostCard.setName, hostCard.cardId, drawX, drawY, renderOptions, "KWKIT")
    local handLayout = getPlayerHandLayout()
    local slot = handLayout and handLayout.slots[returningCard.location and returningCard.location.slotIndex or 0] or nil

    if not badgeRect or not slot then
        return false
    end

    local previewOptions = {
        width = slot.width,
        showLabelWhenCollapsed = true,
        showHealthOnPortrait = false,
        showBadgesInTextbox = true,
        displayName = returningCard.displayName,
        portraitPath = returningCard.portraitPath,
    }
    local cardWidth, cardHeight = carddraw.getCardSize(previewOptions)

    gameState.kitReturnAnimations[#gameState.kitReturnAnimations + 1] = {
        elapsed = 0,
        duration = KIT_RETURN_TOTAL_DURATION,
        badgeRect = {
            x = badgeRect.x,
            y = badgeRect.y,
            size = badgeRect.size,
        },
        startX = badgeRect.x + (badgeRect.size / 2),
        startY = badgeRect.y + (badgeRect.size / 2),
        targetX = slot.x + (cardWidth / 2),
        targetY = slot.y + (cardHeight / 2),
        peakY = math.min(badgeRect.y, slot.y) - math.max(34, badgeRect.size * 1.8),
        setName = attachedKit.setName,
        cardId = attachedKit.cardId,
        renderOptions = previewOptions,
        cardWidth = cardWidth,
        cardHeight = cardHeight,
        returningCard = returningCard,
    }

    returningCard.returningToHandAnimation = true
    return true
end

local function updateKitReturnAnimations(dt)
    for animationIndex = #gameState.kitReturnAnimations, 1, -1 do
        local animation = gameState.kitReturnAnimations[animationIndex]
        animation.elapsed = animation.elapsed + dt

        if animation.elapsed >= animation.duration then
            if animation.returningCard then
                animation.returningCard.returningToHandAnimation = nil
            end

            table.remove(gameState.kitReturnAnimations, animationIndex)
        end
    end
end

local function drawKitReturnAnimations()
    for _, animation in ipairs(gameState.kitReturnAnimations) do
        local elapsed = math.max(0, animation.elapsed)
        local flashProgress = math.min(1, elapsed / KIT_RETURN_FLASH_DURATION)
        local expandProgress = math.min(1, math.max(0, elapsed - KIT_RETURN_FLASH_DURATION) / KIT_RETURN_EXPAND_DURATION)
        local flyProgress = math.min(1, math.max(0, elapsed - KIT_RETURN_FLASH_DURATION - KIT_RETURN_EXPAND_DURATION) / KIT_RETURN_FLY_DURATION)

        if flashProgress < 1 then
            local glowAlpha = (1 - flashProgress) * 0.55
            local glowInset = 2 + (flashProgress * 6)

            love.graphics.setColor(1, 0.92, 0.52, glowAlpha)
            love.graphics.rectangle(
                "fill",
                animation.badgeRect.x - glowInset,
                animation.badgeRect.y - glowInset,
                animation.badgeRect.size + (glowInset * 2),
                animation.badgeRect.size + (glowInset * 2),
                6,
                6
            )
        end

        local centerX = animation.startX
        local centerY = animation.startY
        local scale = 0.22

        if flyProgress > 0 then
            local t = 1 - ((1 - flyProgress) * (1 - flyProgress))
            local invT = 1 - t
            centerX = (invT * invT * animation.startX) + (2 * invT * t * ((animation.startX + animation.targetX) / 2)) + (t * t * animation.targetX)
            centerY = (invT * invT * animation.startY) + (2 * invT * t * animation.peakY) + (t * t * animation.targetY)
            scale = 0.5 + (0.5 * t)
        elseif expandProgress > 0 then
            local t = 1 - ((1 - expandProgress) * (1 - expandProgress))
            centerY = animation.startY - (18 * t)
            scale = 0.22 + (0.42 * t)
        end

        love.graphics.push()
        love.graphics.translate(centerX, centerY)
        love.graphics.scale(scale, scale)
        carddraw.drawCardState(
            animation.setName,
            animation.cardId,
            -animation.cardWidth / 2,
            -animation.cardHeight / 2,
            0,
            animation.renderOptions
        )
        love.graphics.pop()
    end

    love.graphics.setColor(1, 1, 1, 1)
end

releaseAttachedKits = function(card)
    if not card
        or card.deckOwner ~= "player"
        or not gameState.playerDeck
        or not card.attachedKitCards
        or #card.attachedKitCards <= 0 then
        return false
    end

    local releasedAny = false

    for _, attachedKit in ipairs(card.attachedKitCards) do
        local nextSlotIndex = getNextOpenHandSlot()
        local kitCard = {
            instanceId = attachedKit.instanceId,
            setName = attachedKit.setName,
            cardId = attachedKit.cardId,
            displayName = attachedKit.displayName,
            portraitPath = attachedKit.portraitPath,
            deckOwner = "player",
        }

        if nextSlotIndex then
            kitCard.location = {
                kind = "hand",
                slotIndex = nextSlotIndex,
            }
            gameState.cards[#gameState.cards + 1] = kitCard
            gameState.cardExpansion[#gameState.cards] = 0
            gameState.cardEntranceProgress[#gameState.cards] = 1
            beginKitReturnAnimation(card, attachedKit, kitCard)
        else
            deckrules.discardCard(gameState.playerDeck, kitCard)
        end

        releasedAny = true
    end

    card.attachedKitCards = nil
    return releasedAny
end

local function discardDestroyedCard(card)
    if not card or card.sentToDiscard then
        return nil
    end

    local cardDefinition = cardregistry.getCard(card.setName, card.cardId)

    if cardDefinition and (cardDefinition.type == "token" or cardDefinition.type == "cache") then
        card.sentToDiscard = true
        return nil
    end

    if card.deckOwner == "player" and gameState.playerDeck then
        releaseAttachedKits(card)
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
        releaseAttachedKits(card)
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

local function resolveDestroyedTroopCard(troopCardIndex)
    return trooprules.resolveDeath(troopCardIndex, {
        cards = gameState.cards,
        cardregistry = cardregistry,
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

local function copyRenderOptions(renderOptions)
    local copiedOptions = {}

    for key, value in pairs(renderOptions or {}) do
        copiedOptions[key] = value
    end

    return copiedOptions
end

local function getHoveredCardPreview()
    local cardIndex = gameState.hoveredCardIndex
    local card = cardIndex and gameState.cards[cardIndex] or nil

    if not card
        or isCardDestroyed(card)
        or card.returningToHandAnimation
        or isCardUnavailable(card) then
        return nil
    end

    local drawX, drawY, expansionProgress, renderOptions = getCardDrawPosition(card, cardIndex)
    local cardWidth, collapsedHeight = carddraw.getCardSize(renderOptions)
    local _, expandedHeight = carddraw.getExpandedCardSize(renderOptions)
    local cardHeight = collapsedHeight + ((expandedHeight - collapsedHeight) * (expansionProgress or 0))

    return {
        kind = "card",
        cardIndex = cardIndex,
        card = card,
        sourceRect = {
            x = drawX,
            y = drawY,
            width = cardWidth,
            height = cardHeight,
        },
        setName = card.setName,
        cardId = card.cardId,
        renderOptions = copyRenderOptions(renderOptions),
    }
end

local function getHoveredTopSlotPreview()
    local slotId = gameState.hoveredTopSlotId

    if not slotId then
        return nil
    end

    local slots = envdraw.getTopSlotLayouts(
        turnrules.getCurrentPhase(),
        gameState.activeChampion,
        gameState.activeWarzone,
        gameState.activePoi,
        gameState.activePrimaryObjective,
        gameState.activeIntel
    )

    for _, slot in ipairs(slots or {}) do
        if slot.id == slotId and slot.definition and slot.imageRect then
            local displayStates = warrules.getDisplayStates()

            return {
                kind = "topslot",
                sourceRect = {
                    x = slot.imageRect.x,
                    y = slot.imageRect.y,
                    width = slot.imageRect.width,
                    height = slot.imageRect.height,
                },
                slotId = slot.id,
                label = slot.nameText or slot.slotLabel or slot.id,
                image = slot.image,
                definition = slot.definition,
                accentColor = slot.accentColor,
                rollState = displayStates and displayStates[slot.id] or nil,
            }
        end
    end

    return nil
end

local function getHoveredJaclPreview(mouseX, mouseY)
    local jaclLayout = envdraw.getBottomLeftPanelLayout(gameState.playerJacl)

    if not jaclLayout then
        return nil
    end

    local insidePanel = mouseX >= jaclLayout.panelX
        and mouseX <= jaclLayout.panelX + jaclLayout.panelSize
        and mouseY >= jaclLayout.panelY
        and mouseY <= jaclLayout.panelY + jaclLayout.panelSize

    if not insidePanel then
        return nil
    end

    return {
        kind = "jacl",
        sourceRect = {
            x = jaclLayout.panelX,
            y = jaclLayout.panelY,
            width = jaclLayout.panelSize,
            height = jaclLayout.panelSize,
        },
        label = gameState.playerJacl and gameState.playerJacl.name or "JACL",
        image = envdraw.getJaclArtImage(gameState.playerJacl),
    }
end

local function getHoverPreviewState()
    if gameState.draggedCardIndex
        or gameState.fullArtImage
        or gameState.isJaclDeckModalOpen
        or gameState.isResourceExchangeModalOpen
        or love.keyboard.isDown("lshift")
        or love.keyboard.isDown("rshift") then
        return nil
    end

    local hoveredCardPreview = getHoveredCardPreview()

    if hoveredCardPreview then
        return hoveredCardPreview
    end

    local hoveredTopSlotPreview = getHoveredTopSlotPreview()

    if hoveredTopSlotPreview then
        return hoveredTopSlotPreview
    end

    local mouseX, mouseY = love.mouse.getPosition()
    return getHoveredJaclPreview(mouseX, mouseY)
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
        primedActivatedAbility = gameState.primedActivatedAbility,
    }
end

local function applyModalState(modalState)
    gameState.isResourceExchangeModalOpen = modalState.isResourceExchangeModalOpen
    gameState.isJaclDeckModalOpen = modalState.isJaclDeckModalOpen
    gameState.jaclDeckPreviewCard = modalState.jaclDeckPreviewCard
    gameState.activeDeckModalDeck = modalState.activeDeckModalDeck
    gameState.primedJaclSpecial = modalState.primedJaclSpecial
    gameState.primedActivatedAbility = modalState.primedActivatedAbility
end

local function getModalDeps()
    return {
        turnrules = turnrules,
        resourcerules = resourcerules,
        specialrules = specialrules,
        abilityrules = abilityrules,
        cardregistry = cardregistry,
        cards = gameState.cards,
        isCardUnavailable = isCardUnavailable,
        sfxrules = sfxrules,
        envdraw = envdraw,
        cardinstances = cardinstances,
        createGeneratedGridCard = createGeneratedGridCard,
        transformCardAtIndex = transformCardAtIndex,
        getCardMethodBadgeTarget = getCardMethodBadgeTarget,
        getGridCardAt = getGridCardAt,
        getValidJaclSpecialTargetCell = getValidJaclSpecialTargetCell,
        getPlayerRowCellAt = getPlayerRowCellAt,
        addObjectiveProgress = addObjectiveProgress,
        copyLocation = copyLocation,
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

local function updateHoveredSpawnPreview(card)
    gameState.hoveredTomeSpawnPreviewCard = nil
    gameState.hoveredTomeSpawnPreviewCards = nil
    gameState.hoveredTomeSpawnPreviewLabel = nil

    local cardDefinition = card and cardregistry.getCard(card.setName, card.cardId) or nil

    if tomerules.isSpawnTomeDefinition(cardDefinition) then
        local targetCardId = tomerules.getFirstTargetCardId(cardDefinition)
        gameState.hoveredTomeSpawnPreviewCard = targetCardId and cardregistry.getCardById(targetCardId) or nil
    elseif strategyrules.isSpawnStrategyDefinition(cardDefinition) then
        local targetCardId = strategyrules.getFirstTargetCardId(cardDefinition)
        gameState.hoveredTomeSpawnPreviewCard = targetCardId and cardregistry.getCardById(targetCardId) or nil
    elseif not (card.location and card.location.kind == "grid") then
        local previewCardIds, previewLabel = trooprules.getPreviewCardIds(cardDefinition)

        if previewCardIds and #previewCardIds > 0 then
            gameState.hoveredTomeSpawnPreviewCards = {}
            gameState.hoveredTomeSpawnPreviewLabel = previewLabel

            for _, previewCardId in ipairs(previewCardIds) do
                local previewCardDefinition = previewCardId and cardregistry.getCardById(previewCardId) or nil

                if previewCardDefinition then
                    gameState.hoveredTomeSpawnPreviewCards[#gameState.hoveredTomeSpawnPreviewCards + 1] = previewCardDefinition
                end
            end

            gameState.hoveredTomeSpawnPreviewCard = gameState.hoveredTomeSpawnPreviewCards[1] or nil
        end
    end
end

local function attachDiceFaceSummonPreview(tooltip)
    if tooltip and tooltip.summonCardId then
        tooltip.previewCardDefinition = cardregistry.getCardById(tooltip.summonCardId)
    end

    if tooltip and tooltip.summonCardIds then
        tooltip.previewCardDefinitions = {}

        for _, summonCardId in ipairs(tooltip.summonCardIds) do
            local previewCardDefinition = cardregistry.getCardById(summonCardId)

            if previewCardDefinition then
                tooltip.previewCardDefinitions[#tooltip.previewCardDefinitions + 1] = previewCardDefinition
            end
        end
    end

    return tooltip
end

local function updateHoveredCard()
    local previousHoveredCardIndex = gameState.hoveredCardIndex
    gameState.hoveredKeyword = nil
    gameState.hoveredDiceFace = nil

    if gameState.draggedCardIndex or gameState.isResourceExchangeModalOpen or gameState.isJaclDeckModalOpen then
        gameState.hoveredCardIndex = nil
        gameState.hoveredTopSlotId = nil
        gameState.hoveredJaclSpecialDefinition = nil
        gameState.hoveredJaclSpecialPreviewCard = nil
        gameState.hoveredTomeSpawnPreviewCard = nil
        gameState.hoveredTomeSpawnPreviewCards = nil
        gameState.hoveredTomeSpawnPreviewLabel = nil
        gameState.hoveredDiceFace = nil
        return
    end

    local mouseX, mouseY = love.mouse.getPosition()
    gameState.hoveredTopSlotId = getHoveredTopSlotId(mouseX, mouseY)
    gameState.hoveredJaclSpecialDefinition = nil
    gameState.hoveredJaclSpecialPreviewCard = nil
    gameState.hoveredTomeSpawnPreviewCard = nil
    gameState.hoveredTomeSpawnPreviewCards = nil
    gameState.hoveredTomeSpawnPreviewLabel = nil
    gameState.hoveredDiceFace = nil

    gameState.hoveredDiceFace = attachDiceFaceSummonPreview(envdraw.getHoveredTopSlotDiceFace(
        mouseX,
        mouseY,
        turnrules.getCurrentPhase(),
        gameState.activeChampion,
        gameState.activeWarzone,
        gameState.activePoi,
        gameState.activePrimaryObjective,
        gameState.activeIntel,
        warrules.getDisplayStates(),
        gameState.expandedTopSlotId,
        gameState.topSlotExpansion[gameState.expandedTopSlotId] or 0
    ))

    if gameState.hoveredCardIndex then
        local activeCard = gameState.cards[gameState.hoveredCardIndex]

        if activeCard and not activeCard.returningToHandAnimation and not isCardUnavailable(activeCard) then
            local drawX, drawY, expansionProgress, renderOptions = getCardDrawPosition(activeCard, gameState.hoveredCardIndex)

            if carddraw.isPointInsideDrawnCard(mouseX, mouseY, drawX, drawY, expansionProgress, nil, renderOptions) then
                gameState.hoveredDiceFace = attachDiceFaceSummonPreview(carddraw.getHoveredDiceFace(activeCard.setName, activeCard.cardId, drawX, drawY, expansionProgress, renderOptions, mouseX, mouseY, warrules.getCardRollState(gameState.hoveredCardIndex))) or gameState.hoveredDiceFace
                gameState.hoveredKeyword = carddraw.getHoveredKeyword(activeCard.setName, activeCard.cardId, drawX, drawY, renderOptions, mouseX, mouseY)
                updateHoveredSpawnPreview(activeCard)
                return
            end
        end
    end

    gameState.hoveredCardIndex = nil

    for cardIndex = #gameState.cards, 1, -1 do
        if not gameState.cards[cardIndex].returningToHandAnimation and not isCardUnavailable(gameState.cards[cardIndex]) then
            local drawX, drawY, expansionProgress, renderOptions = getCardDrawPosition(gameState.cards[cardIndex], cardIndex)

            if carddraw.isPointInsideDrawnCard(mouseX, mouseY, drawX, drawY, expansionProgress, nil, renderOptions) then
                gameState.hoveredCardIndex = cardIndex
                gameState.hoveredDiceFace = attachDiceFaceSummonPreview(carddraw.getHoveredDiceFace(gameState.cards[cardIndex].setName, gameState.cards[cardIndex].cardId, drawX, drawY, expansionProgress, renderOptions, mouseX, mouseY, warrules.getCardRollState(cardIndex))) or gameState.hoveredDiceFace
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
        getCardMethodBadgeTarget = getCardMethodBadgeTarget,
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
        isKitCard = function(card)
            return kitrules.isKitCard(card, {
                cardregistry = cardregistry,
            })
        end,
        isSetupCard = isSetupCard,
        isStrategyCard = isStrategyCard,
        hasPendingStrategySelection = hasPendingStrategySelection,
        normalizeHandCardSlots = normalizeHandCardSlots,
        normalizeSetupCardSlots = normalizeSetupCardSlots,
        payCardCosts = payCardCosts,
        primeCardMethodAbility = primeCardMethodAbility,
        primeJaclSpecial = primeJaclSpecial,
        resolvePlayedTroopCard = resolvePlayedTroopCard,
        cancelPendingStrategySelection = cancelPendingStrategySelection,
        tryPlayKitCard = tryPlayKitCard,
        tryPlayStrategyCard = tryPlayStrategyCard,
        tryResolvePendingStrategySelection = tryResolvePendingStrategySelection,
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
    gameState.hoveredDiceFace = nil
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
    gameState.primedActivatedAbility = nil
    gameState.fullArtImage = nil
    gameState.hoveredJaclSpecialDefinition = nil
    gameState.hoveredJaclSpecialPreviewCard = nil
    gameState.hoveredTomeSpawnPreviewCard = nil
    gameState.hoveredTomeSpawnPreviewCards = nil
    gameState.hoveredTomeSpawnPreviewLabel = nil
    gameState.pendingStrategySelection = nil
    gameState.pendingSacrificeSelection = nil
    gameState.endPhaseSacrificeHandled = false
    gameState.kitReturnAnimations = {}
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
    updateKitReturnAnimations(dt)

    for cardIndex, card in ipairs(gameState.cards) do
        if card.destroying then
            card.destroyElapsed = (card.destroyElapsed or 0) + dt

            if card.destroyElapsed >= DESTRUCTION_DURATION then
                resolveDestroyedTroopCard(cardIndex)
                trooprules.notifyPlayerRowUnitDefeated(cardIndex, {
                    cards = gameState.cards,
                    cardregistry = cardregistry,
                    isCardUnavailable = isCardUnavailable,
                    addCardKeywordValue = addCardKeywordValue,
                })
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
        hoverPreview = getHoverPreviewState(),
        isJaclDeckModalOpen = gameState.isJaclDeckModalOpen,
        activeDeckModalDeck = gameState.activeDeckModalDeck,
        fullArtImage = gameState.fullArtImage,
        jaclDeckModalScroll = gameState.jaclDeckModalScroll,
        jaclDeckPreviewCard = gameState.jaclDeckPreviewCard,
        isResourceExchangeModalOpen = gameState.isResourceExchangeModalOpen,
        hoveredKeyword = gameState.hoveredKeyword,
        hoveredDiceFace = gameState.hoveredDiceFace,
        hoveredJaclSpecialDefinition = gameState.hoveredJaclSpecialDefinition,
        hoveredJaclSpecialPreviewCard = gameState.hoveredJaclSpecialPreviewCard,
        hoveredTomeSpawnPreviewCard = gameState.hoveredTomeSpawnPreviewCard,
        hoveredTomeSpawnPreviewCards = gameState.hoveredTomeSpawnPreviewCards,
        hoveredTomeSpawnPreviewLabel = gameState.hoveredTomeSpawnPreviewLabel,
        primedJaclSpecial = gameState.primedJaclSpecial,
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
    })
end
