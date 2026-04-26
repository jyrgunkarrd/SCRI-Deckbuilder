local kitrules = {}
local keywordrules = require("src.system.keywordrules")

local KIT_CARD_TYPE = "kit"
local EQUIPPED_KEYWORD_ID = "KWKIT"
local VALID_ATTACHMENT_TARGET_TYPES = {
    troop = true,
    token = true,
    agent = true,
}

function kitrules.isKitDefinition(cardDefinition)
    return cardDefinition and cardDefinition.type == KIT_CARD_TYPE or false
end

function kitrules.isKitCard(card, ctx)
    local cardDefinition = card and ctx.cardregistry.getCard(card.setName, card.cardId) or nil
    return kitrules.isKitDefinition(cardDefinition)
end

function kitrules.isValidAttachmentTarget(targetCard, targetDefinition)
    return targetCard
        and targetDefinition
        and targetCard.location
        and targetCard.location.kind == "grid"
        and targetCard.location.rowId == "PlayerRow"
        and not keywordrules.cardHasKeyword(targetDefinition, EQUIPPED_KEYWORD_ID, targetCard)
        and VALID_ATTACHMENT_TARGET_TYPES[targetDefinition.type] == true
        or false
end

function kitrules.canPlayKit(kitCard, targetCardIndex, ctx)
    local kitDefinition = kitCard and ctx.cardregistry.getCard(kitCard.setName, kitCard.cardId) or nil
    local targetCard = targetCardIndex and ctx.cards[targetCardIndex] or nil
    local targetDefinition = targetCard and ctx.cardregistry.getCard(targetCard.setName, targetCard.cardId) or nil

    return kitrules.isKitDefinition(kitDefinition)
        and kitCard.location
        and kitCard.location.kind == "hand"
        and kitrules.isValidAttachmentTarget(targetCard, targetDefinition)
end

function kitrules.playKit(kitCardIndex, targetCardIndex, ctx)
    local kitCard = kitCardIndex and ctx.cards[kitCardIndex] or nil
    local targetCard = targetCardIndex and ctx.cards[targetCardIndex] or nil

    if not kitrules.canPlayKit(kitCard, targetCardIndex, ctx) then
        return false
    end

    targetCard.attachedKitCards = targetCard.attachedKitCards or {}
    targetCard.attachedKitCards[#targetCard.attachedKitCards + 1] = {
        instanceId = kitCard.instanceId,
        setName = kitCard.setName,
        cardId = kitCard.cardId,
        deckOwner = kitCard.deckOwner,
        displayName = kitCard.displayName,
        portraitPath = kitCard.portraitPath,
    }

    ctx.removeCardFromPlay(kitCardIndex)
    return true
end

return kitrules
