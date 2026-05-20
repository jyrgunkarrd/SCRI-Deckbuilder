local crewrules = {}

local STARTING_CREW_ROLES = {
    {
        name = "Captain",
        column = 3,
    },
    {
        name = "Surgeon",
        column = 4,
    },
    {
        name = "Sheriff",
        column = 5,
    },
    {
        name = "Tactician",
        column = 6,
    },
    {
        name = "Engineer",
        column = 7,
    },
}

local function getCrewDefinitionByName(cardregistry, roleName)
    for _, crewDefinition in ipairs(cardregistry and cardregistry.getSet("crew") or {}) do
        if crewDefinition.name == roleName then
            return crewDefinition
        end
    end

    return nil
end

local function getCrewPortraitPath(roleName)
    if not roleName then
        return nil
    end

    return "assets/images/crew/" .. string.lower(roleName) .. ".png"
end

function crewrules.getCrewRoleKey(roleName)
    if not roleName then
        return nil
    end

    return tostring(roleName):lower()
end

function crewrules.isCrewRoleDead(deadCrewRoles, roleName)
    local roleKey = crewrules.getCrewRoleKey(roleName)

    return roleKey ~= nil and deadCrewRoles and deadCrewRoles[roleKey] == true or false
end

function crewrules.markCrewRoleDead(deadCrewRoles, roleName)
    local roleKey = crewrules.getCrewRoleKey(roleName)

    if not deadCrewRoles or not roleKey then
        return false
    end

    deadCrewRoles[roleKey] = true
    return true
end

function crewrules.markCrewRoleAlive(deadCrewRoles, roleName)
    local roleKey = crewrules.getCrewRoleKey(roleName)

    if not deadCrewRoles or not roleKey then
        return false
    end

    deadCrewRoles[roleKey] = nil
    return true
end

function crewrules.isCrewCard(card, cardDefinition)
    return card
        and (
            card.setName == "crew"
            or (cardDefinition and cardDefinition.type == "crew")
        )
        or false
end

local function isActiveGridCard(card)
    return card
        and card.location
        and card.location.kind == "grid"
        and not card.destroyed
        and not card.destroying
end

function crewrules.getCoveringCardIndex(cards, crewCardIndex)
    local crewCard = crewCardIndex and cards and cards[crewCardIndex] or nil

    if not crewrules.isCrewCard(crewCard)
        or not isActiveGridCard(crewCard)
        or not crewCard.location.rowId
        or not crewCard.location.column then
        return nil
    end

    for cardIndex, card in ipairs(cards or {}) do
        if cardIndex ~= crewCardIndex
            and isActiveGridCard(card)
            and not crewrules.isCrewCard(card)
            and card.location.rowId == crewCard.location.rowId
            and card.location.column == crewCard.location.column then
            return cardIndex, card
        end
    end

    return nil
end

function crewrules.isCrewCovered(cards, crewCardIndex)
    return crewrules.getCoveringCardIndex(cards, crewCardIndex) ~= nil
end

function crewrules.getTopCardIndexAt(cards, rowId, column, ignoredCardIndex)
    local crewCardIndex = nil

    for cardIndex, card in ipairs(cards or {}) do
        if cardIndex ~= ignoredCardIndex
            and isActiveGridCard(card)
            and card.location.rowId == rowId
            and card.location.column == column then
            if crewrules.isCrewCard(card) then
                crewCardIndex = crewCardIndex or cardIndex
            else
                return cardIndex, card
            end
        end
    end

    if crewCardIndex then
        return crewCardIndex, cards[crewCardIndex]
    end

    return nil
end

function crewrules.canCardCoverCrew(cards, rowId, column, ignoredCardIndex, card)
    if not card or crewrules.isCrewCard(card) or rowId ~= "PlayerRow" then
        return false
    end

    local crewCardIndex = nil

    for cardIndex, existingCard in ipairs(cards or {}) do
        if cardIndex ~= ignoredCardIndex
            and isActiveGridCard(existingCard)
            and existingCard.location.rowId == rowId
            and existingCard.location.column == column then
            if crewrules.isCrewCard(existingCard) then
                crewCardIndex = crewCardIndex or cardIndex
            else
                return false
            end
        end
    end

    return crewCardIndex ~= nil
end

function crewrules.isCardProtectedByCover(cards, card)
    if not crewrules.isCrewCard(card) then
        return false
    end

    for cardIndex, candidateCard in ipairs(cards or {}) do
        if candidateCard == card then
            return crewrules.isCrewCovered(cards, cardIndex)
        end
    end

    return false
end

function crewrules.addStartingCrewCards(ctx)
    if not ctx or not ctx.cards or not ctx.cardregistry or not ctx.cardinstances then
        return 0
    end

    local addedCount = 0

    for _, role in ipairs(STARTING_CREW_ROLES) do
        if not crewrules.isCrewRoleDead(ctx.deadCrewRoles, role.name) then
            local crewDefinition = getCrewDefinitionByName(ctx.cardregistry, role.name)
            local crewCard = ctx.cardinstances.create(
                crewDefinition,
                "crew:" .. tostring(role.name),
                {
                    kind = "grid",
                    rowId = "PlayerRow",
                    column = role.column,
                },
                "player"
            )

            if crewCard then
                crewCard.portraitPath = crewDefinition.portraitPath or getCrewPortraitPath(crewDefinition.name)
                ctx.cards[#ctx.cards + 1] = crewCard
                addedCount = addedCount + 1

                if ctx.initializeCardHealthState then
                    ctx.initializeCardHealthState(crewCard)
                end
            end
        end
    end

    return addedCount
end

return crewrules
