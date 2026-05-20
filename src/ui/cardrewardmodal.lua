local cardrewardpools = require("src.system.cardrewardpools")
local cardregistry = require("src.system.cardregistry")
local carddraw = require("src.render.carddraw")
local crewrules = require("src.system.crewrules")
local enhancementrules = require("src.system.enhancementrules")
local worldloadoutdraw = require("src.render.worldloadoutdraw")
local rewarddebug = require("src.system.rewarddebug")

local cardrewardmodal = {}

local FONT_PATH = "assets/fonts/Furore.otf"
local MODAL_MARGIN = 38
local MODAL_PADDING = 22
local CARD_WIDTH = 172
local CARD_GAP = 26
local HEADER_HEIGHT = 94
local FOOTER_HEIGHT = 44
local OUTLINE_COLOR = { 0.976, 0.761, 0.169, 1 }
local TARGET_COLOR = { 0.549, 1, 0.871, 1 }
local CAPTAIN_HIGHLIGHT_COLOR = { 1, 0.725, 0.337, 1 }
local OLD_FRIEND_ENHANCEMENT_ID = "FRND"
local CAPTAIN_PORTRAIT_PATH = "assets/images/crew/captain.png"
local OLD_FRIEND_BADGE_PATH = "assets/images/cards/enh/FRND.png"
local CAPTAIN_BADGE_SIZE = 34
local CAPTAIN_BADGE_GAP = 10
local CAPTAIN_PORTRAIT_SIZE = 46
local CAPTAIN_PORTRAIT_GAP = 12
local CAPTAIN_HIGHLIGHT_MARGIN = 12

local fontCache = {}
local imageCache = {}

local function getFont(size)
    local key = tostring(size)

    if fontCache[key] then
        return fontCache[key]
    end

    fontCache[key] = love.graphics.newFont(FONT_PATH, size)
    return fontCache[key]
end

local function getImage(path)
    if imageCache[path] ~= nil then
        return imageCache[path] or nil
    end

    if not love.filesystem.getInfo(path) then
        imageCache[path] = false
        return nil
    end

    imageCache[path] = love.graphics.newImage(path, {
        mipmaps = true,
    })
    imageCache[path]:setFilter("linear", "linear")
    return imageCache[path]
end

local function isPointInsideRect(x, y, rect)
    return rect
        and x >= rect.x
        and x <= rect.x + rect.width
        and y >= rect.y
        and y <= rect.y + rect.height
end

local function ensureRewardBuckets(state)
    state.selectedRunCardRewards = state.selectedRunCardRewards or {}
    state.selectedRunCardRewards.jacl = state.selectedRunCardRewards.jacl or {}
    state.selectedRunCardRewards.agents = state.selectedRunCardRewards.agents or {}
    return state.selectedRunCardRewards
end

local function getAgentDefinition(agentId)
    return agentId and cardregistry.getCard("troops", agentId) or nil
end

local function getJaclDefinition(state)
    return state and state.selectedRunPackage and state.selectedRunPackage.jacl or nil
end

local function hasCaptainOldFriendChoice(modal)
    for _, choice in ipairs(modal and modal.choices or {}) do
        if choice.captainOldFriend then
            return true
        end
    end

    return false
end

local function getLayout(modal)
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local cardWidth, cardHeight = carddraw.getCardSize({
        width = CARD_WIDTH,
        showLabelWhenCollapsed = true,
        showHealthOnPortrait = true,
    })
    local hasCaptainSlot = hasCaptainOldFriendChoice(modal)
    local oldFriendTopBand = hasCaptainSlot and (CAPTAIN_BADGE_SIZE + CAPTAIN_BADGE_GAP + CAPTAIN_HIGHLIGHT_MARGIN) or 0
    local oldFriendBottomBand = hasCaptainSlot and (CAPTAIN_PORTRAIT_SIZE + CAPTAIN_PORTRAIT_GAP + CAPTAIN_HIGHLIGHT_MARGIN) or 0
    local choiceCount = math.max(1, #(modal and modal.choices or {}))
    local contentWidth = (choiceCount * cardWidth) + (math.max(0, choiceCount - 1) * CARD_GAP)
    local modalWidth = math.min(screenWidth - (MODAL_MARGIN * 2), contentWidth + (MODAL_PADDING * 2))
    local modalHeight = math.min(screenHeight - (MODAL_MARGIN * 2), HEADER_HEIGHT + oldFriendTopBand + cardHeight + oldFriendBottomBand + FOOTER_HEIGHT + (MODAL_PADDING * 2))
    local modalX = math.floor((screenWidth - modalWidth) * 0.5)
    local modalY = math.floor((screenHeight - modalHeight) * 0.34)
    local cardsX = math.floor(modalX + ((modalWidth - contentWidth) * 0.5))
    local cardsY = math.floor(modalY + HEADER_HEIGHT + oldFriendTopBand)

    return {
        x = modalX,
        y = modalY,
        width = modalWidth,
        height = modalHeight,
        cardWidth = cardWidth,
        cardHeight = cardHeight,
        cardsX = cardsX,
        cardsY = cardsY,
        oldFriendTopBand = oldFriendTopBand,
        oldFriendBottomBand = oldFriendBottomBand,
    }
end

local function getChoiceTargets(modal)
    local layout = getLayout(modal)
    local targets = {}

    for choiceIndex, choice in ipairs(modal and modal.choices or {}) do
        local x = layout.cardsX + ((choiceIndex - 1) * (layout.cardWidth + CARD_GAP))

        targets[#targets + 1] = {
            x = x,
            y = layout.cardsY,
            width = layout.cardWidth,
            height = layout.cardHeight,
            choice = choice,
            choiceIndex = choiceIndex,
        }
    end

    return targets, layout
end

local function isCaptainAlive(state)
    return not crewrules.isCrewRoleDead(state and state.deadCrewRoles or nil, "Captain")
end

local function markCaptainOldFriendChoice(state, choices)
    if not isCaptainAlive(state) or #choices <= 0 then
        return nil
    end

    local choiceIndex = math.ceil(#choices / 2)
    local choice = choices[choiceIndex]

    if choice then
        choice.captainOldFriend = true
        choice.enh = OLD_FRIEND_ENHANCEMENT_ID
    end

    return choiceIndex
end

local function getRewardEntryForChoice(choice)
    if not choice or not choice.cardId then
        return nil
    end

    if choice.captainOldFriend then
        return {
            cardId = choice.cardId,
            enh = OLD_FRIEND_ENHANCEMENT_ID,
        }
    end

    return choice.cardId
end

local function getRewardTargetAt(state, x, y)
    local layout = worldloadoutdraw.getLayout(state)

    if not layout then
        return nil
    end

    local jaclDefinition = getJaclDefinition(state)
    local jaclRect = {
        x = layout.x,
        y = layout.y,
        width = layout.jaclWidth,
        height = layout.jaclHeight - layout.jaclLabelHeight,
    }

    if state.selectedRunJaclId and isPointInsideRect(x, y, jaclRect) then
        return {
            kind = "jacl",
            id = state.selectedRunJaclId,
            label = jaclDefinition and jaclDefinition.name or "JACL",
            rect = jaclRect,
        }
    end

    for agentIndex = 1, 2 do
        local agentId = state.selectedRunAgentIds and state.selectedRunAgentIds[agentIndex] or nil
        local agentDefinition = getAgentDefinition(agentId)
        local agentX = layout.x + layout.jaclWidth + layout.gap + ((agentIndex - 1) * (layout.agentWidth + layout.gap))
        local agentY = layout.y + layout.jaclHeight - layout.agentHeight
        local agentRect = {
            x = agentX,
            y = agentY,
            width = layout.agentWidth,
            height = layout.agentHeight,
        }

        if agentId and agentDefinition and carddraw.isPointInsideCard(x, y, agentX, agentY, 0, {
            width = layout.agentWidth,
            showLabelWhenCollapsed = false,
        }) then
            return {
                kind = "agent",
                id = agentId,
                label = agentDefinition.name or agentDefinition.id,
                rect = agentRect,
            }
        end
    end

    return nil
end

local function getRewardTargets(state)
    local targets = {}
    local layout = worldloadoutdraw.getLayout(state)

    if not layout then
        return targets
    end

    local jaclDefinition = getJaclDefinition(state)

    if state.selectedRunJaclId then
        targets[#targets + 1] = {
            kind = "jacl",
            id = state.selectedRunJaclId,
            label = jaclDefinition and jaclDefinition.name or "JACL",
            rect = {
                x = layout.x,
                y = layout.y,
                width = layout.jaclWidth,
                height = layout.jaclHeight - layout.jaclLabelHeight,
            },
        }
    end

    for agentIndex = 1, 2 do
        local agentId = state.selectedRunAgentIds and state.selectedRunAgentIds[agentIndex] or nil
        local agentDefinition = getAgentDefinition(agentId)

        if agentId and agentDefinition then
            local agentX = layout.x + layout.jaclWidth + layout.gap + ((agentIndex - 1) * (layout.agentWidth + layout.gap))
            local agentY = layout.y + layout.jaclHeight - layout.agentHeight

            targets[#targets + 1] = {
                kind = "agent",
                id = agentId,
                label = agentDefinition.name or agentDefinition.id,
                rect = {
                    x = agentX,
                    y = agentY,
                    width = layout.agentWidth,
                    height = layout.agentHeight,
                },
            }
        end
    end

    return targets
end

local function addRewardToTarget(state, choice, target)
    if not state or not choice or not choice.cardId or not target or not target.id then
        return false
    end

    local rewards = ensureRewardBuckets(state)
    local bucket = target.kind == "jacl" and rewards.jacl or rewards.agents

    bucket[target.id] = bucket[target.id] or {}
    bucket[target.id][#bucket[target.id] + 1] = getRewardEntryForChoice(choice)

    state.worldMapCardRewardModal = nil
    state.worldMapCardRewardTargets = nil
    state.worldMapCardRewardChoiceTargets = nil

    return true
end

function cardrewardmodal.open(state, options)
    if not state then
        rewarddebug.log("cardrewardmodal.open.failed", {
            reason = "missing_state",
        })
        return false
    end

    local choices = cardrewardpools.roll(options and options.poolId or "universal", options and options.count or 3, state, {
        cardrw = options and options.cardrw or nil,
    })
    local captainOldFriendChoiceIndex = markCaptainOldFriendChoice(state, choices)

    if #choices <= 0 then
        rewarddebug.log("cardrewardmodal.open.failed", {
            reason = "no_choices",
            poolId = options and options.poolId or "universal",
            count = options and options.count or 3,
            cardrw = options and options.cardrw or nil,
            selectedRunJaclId = state.selectedRunJaclId,
            selectedRunAgentIds = state.selectedRunAgentIds,
        })
        return false
    end

    rewarddebug.log("cardrewardmodal.open.ok", {
        poolId = options and options.poolId or "universal",
        count = #choices,
        cardrw = options and options.cardrw or nil,
        firstChoice = choices[1] and choices[1].cardId or nil,
    })

    state.worldMapDeckModal = nil
    state.worldMapObjectivePreviewModal = nil
    state.worldMapCardRewardModal = {
        poolId = options and options.poolId or "universal",
        cardrw = options and options.cardrw or nil,
        choices = choices,
        captainOldFriendChoiceIndex = captainOldFriendChoiceIndex,
        selectedChoice = nil,
        selectedChoiceIndex = nil,
        stage = "choose_card",
    }

    return true
end

function cardrewardmodal.hasOpen(state)
    return state and state.worldMapCardRewardModal ~= nil or false
end

function cardrewardmodal.update()
    return false
end

function cardrewardmodal.mousepressed(state, x, y, button, deps)
    local modal = state and state.worldMapCardRewardModal or nil

    if not modal then
        return false
    end

    if button == 2 and modal.selectedChoice then
        modal.selectedChoice = nil
        modal.selectedChoiceIndex = nil
        modal.stage = "choose_card"

        if deps and deps.sfxrules and deps.sfxrules.playClick then
            deps.sfxrules.playClick()
        end

        return true
    end

    if button ~= 1 then
        return true
    end

    if modal.selectedChoice then
        local target = getRewardTargetAt(state, x, y)

        if target and addRewardToTarget(state, modal.selectedChoice, target) then
            if deps and deps.sfxrules and deps.sfxrules.playCollect then
                deps.sfxrules.playCollect()
            elseif deps and deps.sfxrules and deps.sfxrules.playClick then
                deps.sfxrules.playClick()
            end

            return true
        end

        return true
    end

    for _, target in ipairs(getChoiceTargets(modal)) do
        if isPointInsideRect(x, y, target) then
            modal.selectedChoice = target.choice
            modal.selectedChoiceIndex = target.choiceIndex
            modal.stage = "choose_owner"

            if deps and deps.sfxrules and deps.sfxrules.playClick then
                deps.sfxrules.playClick()
            end

            return true
        end
    end

    return true
end

function cardrewardmodal.wheelmoved(state)
    return cardrewardmodal.hasOpen(state)
end

local function drawTargetHighlights(state)
    local previousLineWidth = love.graphics.getLineWidth()
    local mouseX, mouseY = love.mouse.getPosition()
    local hoveredTarget = getRewardTargetAt(state, mouseX, mouseY)
    local targetFont = getFont(11)

    for _, target in ipairs(getRewardTargets(state)) do
        local rect = target.rect
        local hovered = hoveredTarget and hoveredTarget.kind == target.kind and hoveredTarget.id == target.id

        love.graphics.setLineWidth(hovered and 4 or 2)
        love.graphics.setColor(TARGET_COLOR[1], TARGET_COLOR[2], TARGET_COLOR[3], hovered and 1 or 0.72)
        love.graphics.rectangle("line", rect.x - 4, rect.y - 4, rect.width + 8, rect.height + 8, 7, 7)
        love.graphics.setColor(0.01, 0.012, 0.016, 0.78)
        love.graphics.rectangle("fill", rect.x, rect.y - 23, rect.width, 20, 4, 4)
        love.graphics.setFont(targetFont)
        love.graphics.setColor(TARGET_COLOR[1], TARGET_COLOR[2], TARGET_COLOR[3], 1)
        love.graphics.printf("ADD HERE", rect.x, rect.y - 20, rect.width, "center")
    end

    love.graphics.setLineWidth(previousLineWidth)
    love.graphics.setColor(1, 1, 1, 1)
end

local function drawImageInRect(image, x, y, width, height, alpha)
    if not image then
        return
    end

    local scale = math.min(width / image:getWidth(), height / image:getHeight())
    local drawWidth = image:getWidth() * scale
    local drawHeight = image:getHeight() * scale
    local drawX = math.floor(x + ((width - drawWidth) * 0.5) + 0.5)
    local drawY = math.floor(y + ((height - drawHeight) * 0.5) + 0.5)

    love.graphics.setColor(1, 1, 1, alpha or 1)
    love.graphics.draw(image, drawX, drawY, 0, scale, scale)
end

local function drawCaptainOldFriendHighlight(target, alpha)
    local previousLineWidth = love.graphics.getLineWidth()
    local badgeX = math.floor(target.x + ((target.width - CAPTAIN_BADGE_SIZE) * 0.5) + 0.5)
    local badgeY = math.floor(target.y - CAPTAIN_BADGE_SIZE - CAPTAIN_BADGE_GAP)
    local portraitX = math.floor(target.x + ((target.width - CAPTAIN_PORTRAIT_SIZE) * 0.5) + 0.5)
    local portraitY = math.floor(target.y + target.height + CAPTAIN_PORTRAIT_GAP + 0.5)
    local highlightY = badgeY - CAPTAIN_HIGHLIGHT_MARGIN
    local highlightHeight = (portraitY + CAPTAIN_PORTRAIT_SIZE + CAPTAIN_HIGHLIGHT_MARGIN) - highlightY

    love.graphics.setColor(CAPTAIN_HIGHLIGHT_COLOR[1], CAPTAIN_HIGHLIGHT_COLOR[2], CAPTAIN_HIGHLIGHT_COLOR[3], 0.14 * alpha)
    love.graphics.rectangle("fill", target.x - CAPTAIN_HIGHLIGHT_MARGIN, highlightY, target.width + (CAPTAIN_HIGHLIGHT_MARGIN * 2), highlightHeight, 8, 8)
    love.graphics.setLineWidth(3)
    love.graphics.setColor(CAPTAIN_HIGHLIGHT_COLOR[1], CAPTAIN_HIGHLIGHT_COLOR[2], CAPTAIN_HIGHLIGHT_COLOR[3], 0.86 * alpha)
    love.graphics.rectangle("line", target.x - CAPTAIN_HIGHLIGHT_MARGIN, highlightY, target.width + (CAPTAIN_HIGHLIGHT_MARGIN * 2), highlightHeight, 8, 8)
    love.graphics.setLineWidth(previousLineWidth)

    love.graphics.setColor(0.04, 0.035, 0.025, 0.96 * alpha)
    love.graphics.rectangle("fill", badgeX - 4, badgeY - 4, CAPTAIN_BADGE_SIZE + 8, CAPTAIN_BADGE_SIZE + 8, 5, 5)
    love.graphics.setColor(CAPTAIN_HIGHLIGHT_COLOR[1], CAPTAIN_HIGHLIGHT_COLOR[2], CAPTAIN_HIGHLIGHT_COLOR[3], 0.92 * alpha)
    love.graphics.rectangle("line", badgeX - 4, badgeY - 4, CAPTAIN_BADGE_SIZE + 8, CAPTAIN_BADGE_SIZE + 8, 5, 5)
    drawImageInRect(getImage(OLD_FRIEND_BADGE_PATH), badgeX, badgeY, CAPTAIN_BADGE_SIZE, CAPTAIN_BADGE_SIZE, alpha)

    love.graphics.setColor(0.04, 0.035, 0.025, 0.96 * alpha)
    love.graphics.rectangle("fill", portraitX - 4, portraitY - 4, CAPTAIN_PORTRAIT_SIZE + 8, CAPTAIN_PORTRAIT_SIZE + 8, 6, 6)
    love.graphics.setColor(CAPTAIN_HIGHLIGHT_COLOR[1], CAPTAIN_HIGHLIGHT_COLOR[2], CAPTAIN_HIGHLIGHT_COLOR[3], 0.92 * alpha)
    love.graphics.rectangle("line", portraitX - 4, portraitY - 4, CAPTAIN_PORTRAIT_SIZE + 8, CAPTAIN_PORTRAIT_SIZE + 8, 6, 6)
    drawImageInRect(getImage(CAPTAIN_PORTRAIT_PATH), portraitX, portraitY, CAPTAIN_PORTRAIT_SIZE, CAPTAIN_PORTRAIT_SIZE, alpha)

    return {
        x = badgeX - 4,
        y = badgeY - 4,
        width = CAPTAIN_BADGE_SIZE + 8,
        height = CAPTAIN_BADGE_SIZE + 8,
    }
end

function cardrewardmodal.draw(state)
    local modal = state and state.worldMapCardRewardModal or nil

    if not modal then
        return
    end

    local targets, layout = getChoiceTargets(modal)
    local titleFont = getFont(20)
    local bodyFont = getFont(13)
    local mouseX, mouseY = love.mouse.getPosition()

    love.graphics.setColor(0, 0, 0, 0.62)
    love.graphics.rectangle("fill", layout.x - 7, layout.y - 7, layout.width + 14, layout.height + 14, 8, 8)
    love.graphics.setColor(0.06, 0.07, 0.09, 0.98)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height, 6, 6)
    love.graphics.setColor(OUTLINE_COLOR[1], OUTLINE_COLOR[2], OUTLINE_COLOR[3], 0.95)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height, 6, 6)

    love.graphics.setFont(titleFont)
    love.graphics.setColor(0.95, 0.96, 0.98, 1)
    love.graphics.printf("CARD REWARD", layout.x + MODAL_PADDING, layout.y + 24, layout.width - (MODAL_PADDING * 2), "center")

    love.graphics.setFont(bodyFont)
    love.graphics.setColor(0.78, 0.82, 0.86, 1)

    if modal.selectedChoice then
        love.graphics.printf(
            "Click a JACL or Agent portrait to add the selected card. Right click to cancel.",
            layout.x + MODAL_PADDING,
            layout.y + layout.height - FOOTER_HEIGHT + 10,
            layout.width - (MODAL_PADDING * 2),
            "center"
        )
    else
        love.graphics.printf(
            "Choose one card.",
            layout.x + MODAL_PADDING,
            layout.y + layout.height - FOOTER_HEIGHT + 10,
            layout.width - (MODAL_PADDING * 2),
            "center"
        )
    end

    local hoveredOldFriendBadge = false

    for _, target in ipairs(targets) do
        local hovered = isPointInsideRect(mouseX, mouseY, target)
        local selected = modal.selectedChoiceIndex == target.choiceIndex
        local alpha = modal.selectedChoice and not selected and 0.36 or 1
        local drawCardOptions = {
            width = CARD_WIDTH,
            showLabelWhenCollapsed = true,
            showHealthOnPortrait = true,
        }

        if target.choice.captainOldFriend then
            drawCardOptions.card = {
                enh = OLD_FRIEND_ENHANCEMENT_ID,
            }
        end

        love.graphics.setColor(1, 1, 1, alpha)
        carddraw.drawCardState(target.choice.setName, target.choice.cardId, target.x, target.y, 0, drawCardOptions)

        if target.choice.captainOldFriend then
            local badgeRect = drawCaptainOldFriendHighlight(target, alpha)
            hoveredOldFriendBadge = hoveredOldFriendBadge or isPointInsideRect(mouseX, mouseY, badgeRect)
        end

        if hovered or selected then
            love.graphics.setColor(hovered and 1 or OUTLINE_COLOR[1], hovered and 1 or OUTLINE_COLOR[2], hovered and 1 or OUTLINE_COLOR[3], selected and 1 or 0.78)
            love.graphics.setLineWidth(selected and 4 or 2)
            love.graphics.rectangle("line", target.x - 4, target.y - 4, target.width + 8, target.height + 8, 8, 8)
            love.graphics.setLineWidth(1)
        end
    end

    if modal.selectedChoice then
        drawTargetHighlights(state)
    end

    if hoveredOldFriendBadge then
        carddraw.drawEnhancementTooltip({
            definition = enhancementrules.getDefinition(OLD_FRIEND_ENHANCEMENT_ID),
            enhancementId = OLD_FRIEND_ENHANCEMENT_ID,
        }, mouseX, mouseY)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return cardrewardmodal
