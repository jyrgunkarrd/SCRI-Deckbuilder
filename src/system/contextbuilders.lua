local contextbuilders = {}

function contextbuilders.getChampionPlayContext(c)
    local state = c.state

    return {
        championDeck = state.championDeck,
        cards = state.cards,
        cardExpansion = state.cardExpansion,
        cardEntranceProgress = state.cardEntranceProgress,
        getOppRow = c.getOppRow,
        isGridRowColumnOccupied = c.isGridRowColumnOccupied,
        initializeCardHealthState = c.initializeCardHealthState,
        resolveEnemyEncounter = c.resolveEnemyEncounter,
    }
end

function contextbuilders.getPhaseControllerDeps(c)
    local state = c.state

    return {
        carddraw = c.carddraw,
        cardregistry = c.cardregistry,
        championplayrules = c.championplayrules,
        deckrules = c.deckrules,
        envdraw = c.envdraw,
        envrules = c.envrules,
        keywordrules = c.keywordrules,
        notifications = c.notifications,
        resourcerules = c.resourcerules,
        sfxrules = c.sfxrules,
        topsloteffects = c.topsloteffects,
        turnrules = c.turnrules,
        temporaryeffects = c.temporaryeffects,
        warrules = c.warrules,
        addObjectiveProgress = c.addObjectiveProgress,
        addSetupAgents = c.addSetupAgents,
        addWarzoneControl = c.addWarzoneControl,
        beginInfiltrationEffect = c.beginInfiltrationEffect,
        beginEndPhaseSacrificeSelection = c.beginEndPhaseSacrificeSelection,
        beginPoiGeneratedCardTransformation = c.beginPoiGeneratedCardTransformation,
        clearResolvedSyntacMethodReward = c.clearResolvedSyntacMethodReward,
        clearTemporaryRerollBonus = c.clearTemporaryRerollBonus,
        clearAllBlocking = c.clearAllBlocking,
        createGeneratedSupportCard = c.createGeneratedSupportCard,
        dealDamageToCard = c.dealDamageToCard,
        dealDamageToChampion = c.dealDamageToChampion,
        drawCardFromPlayerDeck = c.drawCardFromPlayerDeck,
        healCard = c.healCard,
        notifyMeatCacheDecayed = function(cacheCardIndex)
            c.trooprules.notifyMeatCacheDecayed(cacheCardIndex, {
                cards = state.cards,
                cardregistry = c.cardregistry,
                isCardUnavailable = c.isCardUnavailable,
                addCardKeywordValue = c.addCardKeywordValue,
            })
        end,
        getCardDrawPosition = c.getCardDrawPosition,
        getChampionPlayContext = c.getChampionPlayContext,
        getEngageRerollBonus = function()
            return state.engageRerollBonus or 0
        end,
        getEndPhaseObjectiveProgress = c.getEndPhaseObjectiveProgress,
        getRetaliationPhaseObjectiveProgress = c.getRetaliationPhaseObjectiveProgress,
        getReplacementIntel = c.getReplacementIntel,
        getSetupCardCount = c.getSetupCardCount,
        getTopSlotRollTargets = c.getTopSlotRollTargets,
        initializeCardsHealthState = c.initializeCardsHealthState,
        isCardUnavailable = c.isCardUnavailable,
        isGridCard = c.isGridCard,
        normalizeSetupCardSlots = c.normalizeSetupCardSlots,
        playHunterAddedSfxForCards = c.playHunterAddedSfxForCards,
        resolveSyntacRewardButtons = c.resolveSyntacRewardButtons,
        expireCardFromPlay = c.expireCardFromPlay,
        removeCardFromPlay = c.removeCardFromPlay,
        updateInfiltrationEffect = c.updateInfiltrationEffect,
    }
end

function contextbuilders.getCardLifecycleContext(c)
    local state = c.state

    return {
        state = state,
        cardregistry = c.cardregistry,
        sfxrules = c.sfxrules,
        trooprules = c.trooprules,
        turnrules = c.turnrules,
        warrules = c.warrules,
        addCardKeywordValue = c.addCardKeywordValue,
        beginKitReturnAnimation = c.beginKitReturnAnimation,
        copyLocation = c.copyLocation,
        destructionDuration = c.destructionDuration,
        getNextOpenHandSlot = c.getNextOpenHandSlot,
        resolveDestroyedTroopCard = c.resolveDestroyedTroopCard,
    }
end

function contextbuilders.getCardPresentationContext(c)
    local state = c.state

    return {
        carddraw = c.carddraw,
        envdraw = c.envdraw,
        turnrules = c.turnrules,
        warrules = c.warrules,
        cards = state.cards,
        cardExpansion = state.cardExpansion,
        cardEntranceProgress = state.cardEntranceProgress,
        draggedCardIndex = state.draggedCardIndex,
        dragOffsetX = state.dragOffsetX,
        dragOffsetY = state.dragOffsetY,
        selectedAttackerCardIndex = state.selectedAttackerCardIndex,
        activeChampion = state.activeChampion,
        activeWarzone = state.activeWarzone,
        activePoi = state.activePoi,
        activePrimaryObjective = state.activePrimaryObjective,
        activeIntel = state.activeIntel,
        destructionDuration = c.destructionDuration,
        isWarRollSourceActive = c.isWarRollSourceActive,
        isCardUnavailable = c.isCardUnavailable,
        getSetupCardCount = c.getSetupCardCount,
        getPlayerHandLayout = c.getPlayerHandLayout,
        getDamageJitterOffset = c.getDamageJitterOffset,
        getDamageJitterKeyForCard = c.getDamageJitterKeyForCard,
        getTargetingContext = c.getTargetingContext,
        drawKitReturnAnimations = c.drawKitReturnAnimations,
    }
end

function contextbuilders.getEngageContext(c)
    local state = c.state

    return {
        turnrules = c.turnrules,
        warrules = c.warrules,
        envdraw = c.envdraw,
        cardregistry = c.cardregistry,
        cards = state.cards,
        hoveredCardIndex = state.hoveredCardIndex,
        selectedAttackerCardIndex = state.selectedAttackerCardIndex,
        selectedAttackerTopSlotId = state.selectedAttackerTopSlotId,
        engageRerollCount = state.engageRerollCount,
        playerJacl = state.playerJacl,
        activePrimaryObjective = state.activePrimaryObjective,
        activeIntel = state.activeIntel,
        activeWarzone = state.activeWarzone,
        activePoi = state.activePoi,
        isCardUnavailable = c.isCardUnavailable,
        isWarRollSourceActive = c.isWarRollSourceActive,
        getCardDrawPosition = c.getCardDrawPosition,
        addBlockingToCard = c.addBlockingToCard,
        addObjectiveProgress = c.addObjectiveProgress,
        canApplyObjectiveProgress = c.canApplyObjectiveProgress,
        addWarzoneControl = c.addWarzoneControl,
        drawCardFromPlayerDeck = c.drawCardFromPlayerDeck,
        healCard = c.healCard,
        dealDamageToChampion = c.dealDamageToChampion,
        dealDamageToCard = c.dealDamageToCard,
        resolveKilledEnemyByPlayerCard = c.resolveKilledEnemyByPlayerCard,
        beginInfiltrationEffect = c.beginInfiltrationEffect,
        spawnTokensNearCard = c.spawnTokensNearCard,
        spawnRandomTokensNearCard = c.spawnRandomTokensNearCard,
        addSyntac = function(amount)
            state.syntacCount = math.min(10, math.max(0, (state.syntacCount or 0) + math.max(0, tonumber(amount) or 0)))
        end,
        addMethodResource = function(resourceName, amount, sourceEntityKey)
            local sourceRect = sourceEntityKey and c.getEntitySourceRect(sourceEntityKey) or nil
            local sourceCenter = sourceRect and {
                x = sourceRect.x + (sourceRect.width / 2),
                y = sourceRect.y + (sourceRect.height / 2),
            } or nil

            return c.resourcerules.addResourceFromSource(
                resourceName,
                amount,
                sourceCenter,
                c.envdraw.getBottomLeftPanelLayout(state.playerJacl),
                c.envdraw.getResourceTrackerLayout()
            )
        end,
        setSelectedAttackerCardIndex = function(cardIndex)
            state.selectedAttackerCardIndex = cardIndex
            state.selectedAttackerTopSlotId = nil
        end,
        setSelectedAttackerTopSlotId = function(slotId)
            state.selectedAttackerTopSlotId = slotId
            state.selectedAttackerCardIndex = nil
        end,
        setExpandedGridCardIndex = function(cardIndex)
            state.expandedGridCardIndex = cardIndex
        end,
        setExpandedTopSlotId = function(slotId)
            state.expandedTopSlotId = slotId
        end,
        setEngageRerollCount = function(count)
            state.engageRerollCount = count
        end,
    }
end

function contextbuilders.buildModalState(state)
    return {
        playerJacl = state.playerJacl,
        activePrimaryObjective = state.activePrimaryObjective,
        isSyntacMethodModalOpen = state.isSyntacMethodModalOpen,
        isResourceExchangeModalOpen = state.isResourceExchangeModalOpen,
        isJaclDeckModalOpen = state.isJaclDeckModalOpen,
        jaclDeckModalScroll = state.jaclDeckModalScroll,
        jaclDeckPreviewCard = state.jaclDeckPreviewCard,
        activeDeckModalDeck = state.activeDeckModalDeck,
        primedActivatedAbility = state.primedActivatedAbility,
    }
end

function contextbuilders.applyModalState(state, modalState)
    state.isSyntacMethodModalOpen = modalState.isSyntacMethodModalOpen
    state.isResourceExchangeModalOpen = modalState.isResourceExchangeModalOpen
    state.isJaclDeckModalOpen = modalState.isJaclDeckModalOpen
    state.jaclDeckPreviewCard = modalState.jaclDeckPreviewCard
    state.activeDeckModalDeck = modalState.activeDeckModalDeck
    state.primedActivatedAbility = modalState.primedActivatedAbility
end

function contextbuilders.getModalDeps(c)
    local state = c.state

    return {
        turnrules = c.turnrules,
        resourcerules = c.resourcerules,
        abilityrules = c.abilityrules,
        cardregistry = c.cardregistry,
        cards = state.cards,
        isCardUnavailable = c.isCardUnavailable,
        sfxrules = c.sfxrules,
        envdraw = c.envdraw,
        cardinstances = c.cardinstances,
        createGeneratedGridCard = c.createGeneratedGridCard,
        transformCardAtIndex = c.transformCardAtIndex,
        pilotCardWithVehicleAtIndex = c.pilotCardWithVehicleAtIndex,
        getCardMethodBadgeTarget = c.getCardMethodBadgeTarget,
        getHoveredTopSlotId = c.getHoveredTopSlotId,
        getGridCardAt = c.getGridCardAt,
        getValidJaclSpecialTargetCell = c.getValidJaclSpecialTargetCell,
        getPlayerRowCellAt = c.getPlayerRowCellAt,
        activeChampion = state.activeChampion,
        dealDamageToCard = c.dealDamageToCard,
        dealDamageToChampion = c.dealDamageToChampion,
        resolveKilledEnemyByPlayerCard = c.resolveKilledEnemyByPlayerCard,
        addSyntac = function(amount)
            state.syntacCount = math.min(10, math.max(0, (state.syntacCount or 0) + math.max(0, tonumber(amount) or 0)))
        end,
        addObjectiveProgress = c.addObjectiveProgress,
        copyLocation = c.copyLocation,
        cancelSyntacMethodChoice = function(modalState)
            c.refundPendingSyntacMethodChoice()
            modalState.isSyntacMethodModalOpen = state.isSyntacMethodModalOpen
        end,
        chooseSyntacMethodResource = function(resourceName, modalState)
            c.chooseSyntacMethodResource(resourceName)
            modalState.isSyntacMethodModalOpen = state.isSyntacMethodModalOpen
        end,
    }
end

function contextbuilders.getHoverPreviewDeps(c)
    return {
        abilityrules = c.abilityrules,
        carddraw = c.carddraw,
        cardregistry = c.cardregistry,
        envdraw = c.envdraw,
        sfxrules = c.sfxrules,
        strategyrules = c.strategyrules,
        tomerules = c.tomerules,
        trooprules = c.trooprules,
        turnrules = c.turnrules,
        warrules = c.warrules,
        getCardDrawPosition = c.getCardDrawPosition,
        getCardMethodBadgeTarget = c.getCardMethodBadgeTarget,
        getHoveredTopSlotId = c.getHoveredTopSlotId,
        getModalDeps = c.getModalDeps,
        isCardDestroyed = c.isCardDestroyed,
        isCardUnavailable = c.isCardUnavailable,
    }
end

function contextbuilders.getTargetingContext(c)
    local state = c.state

    return {
        cards = state.cards,
        hoveredCardIndex = state.hoveredCardIndex,
        hoveredTopSlotId = state.hoveredTopSlotId,
        pendingStrategySelection = c.getPendingSelection(),
        primedActivatedAbility = state.primedActivatedAbility,
        selectedAttackerCardIndex = state.selectedAttackerCardIndex,
        selectedAttackerTopSlotId = state.selectedAttackerTopSlotId,
        currentPhase = c.turnrules.getCurrentPhase(),
        displayStates = c.warrules.getDisplayStates(),
        activeChampion = state.activeChampion,
        activePrimaryObjective = state.activePrimaryObjective,
        activeIntel = state.activeIntel,
        activeWarzone = state.activeWarzone,
        activePoi = state.activePoi,
        getCardRollState = c.warrules.getCardRollState,
        canTargetEnemyCard = c.warrules.canTargetEnemyCard,
        canAttackTarget = c.warrules.canAttackTarget,
        canTargetCardByHeavyRestriction = c.warrules.canTargetCardByHeavyRestriction,
        canTargetPlayerWarzone = c.warrules.canTargetPlayerWarzone,
        cardregistry = c.cardregistry,
        isPrimedAbilityTarget = function(cardIndex, primedAbility)
            return c.abilityrules.isPrimedAbilityTarget(cardIndex, primedAbility, c.getModalDeps())
        end,
        isPendingStrategyTarget = function(cardIndex, pendingSelection)
            if pendingSelection and pendingSelection.kind == "troop_script_sacrifice" then
                return c.trooprules.isValidPendingSacrificeTarget(cardIndex, pendingSelection, {
                    cards = state.cards,
                    cardregistry = c.cardregistry,
                })
            end

            return c.strategyrules.isValidFunccostTarget(cardIndex, pendingSelection, {
                cards = state.cards,
                cardregistry = c.cardregistry,
            })
        end,
    }
end

function contextbuilders.getInputControllerDeps(c)
    return {
        carddraw = c.carddraw,
        envdraw = c.envdraw,
        modals = c.modals,
        notifications = c.notifications,
        phasecontroller = c.phasecontroller,
        sfxrules = c.sfxrules,
        turnrules = c.turnrules,
        warrules = c.warrules,
        applyModalState = c.applyModalState,
        buildModalState = c.buildModalState,
        canExpandCard = c.canExpandCard,
        canOpenPlayerDeckModal = c.canOpenPlayerDeckModal,
        canPlayCard = c.canPlayCard,
        completeSetupPhaseIfReady = c.completeSetupPhaseIfReady,
        copyLocation = c.copyLocation,
        getCardDrawPosition = c.getCardDrawPosition,
        getHoveredPlayerRollBadgeCardIndex = c.getHoveredPlayerRollBadgeCardIndex,
        getCardMethodBadgeTarget = c.getCardMethodBadgeTarget,
        getHoveredTopSlotId = c.getHoveredTopSlotId,
        getHoveredTopSlotRollBadgeId = c.getHoveredTopSlotRollBadgeId,
        isAlliedTopSlot = c.isAlliedTopSlot,
        getGridCardAt = c.getGridCardAt,
        getModalDeps = c.getModalDeps,
        getPhaseControllerDeps = c.getPhaseControllerDeps,
        getValidDropColumn = c.getValidDropColumn,
        isEngagePhase = c.isEngagePhase,
        isGridCard = c.isGridCard,
        isHunterCard = c.isHunterCard,
        isPointInsideJaclPortrait = c.isPointInsideJaclPortrait,
        isPointInsideJaclScratchBadge = c.isPointInsideJaclScratchBadge,
        isKitCard = function(card)
            return c.kitrules.isKitCard(card, {
                cardregistry = c.cardregistry,
            })
        end,
        isSetupCard = c.isSetupCard,
        isStrategyPhase = c.isStrategyPhase,
        isStrategyCard = c.isStrategyCard,
        isTomeCard = function(card)
            return c.tomerules.isTomeCard(card, {
                cardregistry = c.cardregistry,
            })
        end,
        hasPendingStrategySelection = c.hasPendingStrategySelection,
        normalizeHandCardSlots = c.normalizeHandCardSlots,
        normalizeSetupCardSlots = c.normalizeSetupCardSlots,
        payCardCosts = c.payCardCosts,
        primeCardMethodAbility = c.primeCardMethodAbility,
        primeJaclSpecial = c.primeJaclSpecial,
        refundPrimedSyntacAbility = c.refundPrimedSyntacAbility,
        resolvePlayedTroopCard = c.resolvePlayedTroopCard,
        resolveOpeningMulligan = c.resolveOpeningMulligan,
        cancelPendingStrategySelection = c.cancelPendingStrategySelection,
        tryPlayKitCard = c.tryPlayKitCard,
        tryPlayStrategyCard = c.tryPlayStrategyCard,
        tryResolvePendingStrategySelection = c.tryResolvePendingStrategySelection,
        tryUseTomeCard = c.tryUseTomeCard,
        tryPrimeSyntacAbility = c.tryPrimeSyntacAbility,
        tryResolvePrimedSyntacAbility = c.tryResolvePrimedSyntacAbility,
        tryUseSyntacRewardButton = c.tryUseSyntacRewardButton,
        tryOpenFullArt = c.tryOpenFullArt,
        tryCancelSelectedEngageAttacker = c.tryCancelSelectedEngageAttacker,
        tryResolveEngageClick = c.tryResolveEngageClick,
        tryUseEngageReroll = c.tryUseEngageReroll,
        updateHoveredCard = c.updateHoveredCard,
    }
end

return contextbuilders
