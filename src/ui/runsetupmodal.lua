local runsetupmodal = {}

local jaclDefinitions = require("data.jacl")
local troopDefinitions = require("data.cards.troops")
local abilityrules = require("src.system.abilityrules")
local cardregistry = require("src.system.cardregistry")
local deckrules = require("src.system.deckrules")
local previewrules = require("src.system.previewrules")
local carddraw = require("src.render.carddraw")
local envdraw = require("src.render.envdraw")

local FONT_PATH = "assets/fonts/Furore.otf"
local JACL_IMAGE_DIRECTORY = "assets/images/jacl/"
local METHOD_IMAGE_DIRECTORY = "assets/images/method/"
local BUNDLE_COUNT = 3
local AGENT_COUNT = 2
local CARD_WIDTH = 118
local JACL_WIDTH_MULTIPLIER = 3
local JACL_LABEL_VERTICAL_PADDING = 6
local JACL_METHOD_BADGE_SIZE = 42
local JACL_METHOD_BADGE_MARGIN = 8
local AGENT_PREVIEW_WIDTH = 320
local AGENT_PREVIEW_SCREEN_HEIGHT_RATIO = 0.86
local DECK_MODAL_CARD_WIDTH = 150
local DECK_MODAL_CARD_GAP = 14
local DECK_MODAL_HEADER_HEIGHT = 44
local DECK_MODAL_MARGIN = 38
local DECK_MODAL_PADDING = 18
local DECK_MODAL_MAX_HEIGHT_RATIO = 0.78
local TITLE_HEIGHT = 58
local PANEL_RADIUS = 6
local SLOT_RADIUS = 4
local PACKAGE_BUTTON_SIZE = 34
local PACKAGE_BUTTON_MARGIN = 10
local PACKAGE_SELECTION_FLASH_DURATION = 0.48
local PACKAGE_SELECTION_FLASH_INTERVAL = 0.08
local DICE_SUMMON_PREVIEW_GAP = 14
local DICE_SUMMON_PREVIEW_PADDING = 10

local font = nil
local jaclImageCache = {}
local methodImageCache = {}

local function getFont()
    if font ~= nil then
        return font
    end

    font = love.graphics.newFont(FONT_PATH, 18)
    return font
end

local function getJaclImage(jaclDefinition)
    if not jaclDefinition or not jaclDefinition.name then
        return nil
    end

    if jaclImageCache[jaclDefinition.name] ~= nil then
        return jaclImageCache[jaclDefinition.name] or nil
    end

    local imagePath = JACL_IMAGE_DIRECTORY .. jaclDefinition.name .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        jaclImageCache[jaclDefinition.name] = false
        return nil
    end

    local image = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    image:setFilter("linear", "linear")
    image:setMipmapFilter("linear")
    jaclImageCache[jaclDefinition.name] = image
    return image
end

local function getMethodImage(resourceName)
    if not resourceName then
        return nil
    end

    if methodImageCache[resourceName] ~= nil then
        return methodImageCache[resourceName] or nil
    end

    local imagePath = METHOD_IMAGE_DIRECTORY .. resourceName .. ".png"

    if not love.filesystem.getInfo(imagePath) then
        methodImageCache[resourceName] = false
        return nil
    end

    local image = love.graphics.newImage(imagePath, {
        mipmaps = true,
    })
    image:setFilter("linear", "linear")
    image:setMipmapFilter("linear")
    methodImageCache[resourceName] = image
    return image
end

local function expandMethodEntries(methodEntries)
    local resources = {}

    for _, methodEntry in ipairs(methodEntries or {}) do
        local amount = math.max(1, math.floor(methodEntry.amount or 1))

        for _ = 1, amount do
            resources[#resources + 1] = methodEntry.resource
        end
    end

    return resources
end

local function isPointInsideRect(x, y, rect)
    return rect
        and x >= rect.x
        and x <= rect.x + rect.width
        and y >= rect.y
        and y <= rect.y + rect.height
end

local function collectAgents()
    local agents = {}

    for _, troopDefinition in ipairs(troopDefinitions) do
        if troopDefinition.type == "agent" then
            agents[#agents + 1] = troopDefinition
        end
    end

    return agents
end

local function pickRandomEntries(entries, count)
    local pool = {}
    local selected = {}

    for index, entry in ipairs(entries or {}) do
        pool[index] = entry
    end

    for _ = 1, math.min(count, #pool) do
        local selectedIndex = love.math.random(1, #pool)
        selected[#selected + 1] = pool[selectedIndex]
        table.remove(pool, selectedIndex)
    end

    return selected
end

local function buildBundles()
    local bundles = {}
    local jaclDefinition = #jaclDefinitions > 0 and jaclDefinitions[love.math.random(1, #jaclDefinitions)] or nil
    local agents = pickRandomEntries(collectAgents(), AGENT_COUNT)

    bundles[1] = {
        jacl = jaclDefinition,
        agents = agents,
    }

    for bundleIndex = 2, BUNDLE_COUNT do
        bundles[bundleIndex] = {
            jacl = nil,
            agents = {},
        }
    end

    return bundles
end

function runsetupmodal.ensure(state)
    if not state or state.runSetupModal then
        return
    end

    state.runSetupModal = {
        isOpen = true,
        bundles = buildBundles(),
        agentPreviewCardId = nil,
        deckModal = nil,
        hoveredPackageIndex = nil,
        pendingPackageSelection = nil,
    }
end

local function getJaclImageAspectRatio(bundles)
    for _, bundle in ipairs(bundles or {}) do
        local image = getJaclImage(bundle and bundle.jacl or nil)

        if image then
            return image:getHeight() / image:getWidth()
        end
    end

    return 1
end

local function getLayout(bundleCount, bundles)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local cardWidth = math.max(86, math.min(CARD_WIDTH, screenWidth * 0.075))
    local cardHeight = select(2, carddraw.getCardSize({
        width = cardWidth,
    }))
    local labelHeight = math.max(20, cardWidth * 0.2) + JACL_LABEL_VERTICAL_PADDING
    local slotGap = math.max(8, cardWidth * 0.08)
    local rowGap = math.max(10, cardWidth * 0.1)
    local panelPadding = math.max(12, cardWidth * 0.11)
    local panelHeaderHeight = math.max(24, cardWidth * 0.22)
    local jaclWidth = cardWidth * JACL_WIDTH_MULTIPLIER
    local jaclArtHeight = jaclWidth * getJaclImageAspectRatio(bundles)
    local jaclHeight = jaclArtHeight + labelHeight
    local panelWidth = jaclWidth + (panelPadding * 2)
    local panelHeight = panelHeaderHeight + cardHeight + rowGap + jaclHeight + (panelPadding * 2)
    local panelGap = math.max(14, screenWidth * 0.012)
    local modalPadding = math.max(18, screenWidth * 0.015)
    local titleHeight = TITLE_HEIGHT
    local modalWidth = (panelWidth * bundleCount) + (panelGap * (bundleCount - 1)) + (modalPadding * 2)
    local modalHeight = titleHeight + panelHeight + (modalPadding * 2)
    local modalX = (screenWidth - modalWidth) * 0.5
    local modalY = math.max(26, screenHeight * 0.08)

    if modalX < 18 then
        modalX = 18
        modalWidth = screenWidth - 36
        panelWidth = (modalWidth - (modalPadding * 2) - (panelGap * (bundleCount - 1))) / bundleCount
        cardWidth = math.min(cardWidth, (panelWidth - (panelPadding * 2)) / JACL_WIDTH_MULTIPLIER)
        cardHeight = select(2, carddraw.getCardSize({
            width = cardWidth,
        }))
        labelHeight = math.max(20, cardWidth * 0.2) + JACL_LABEL_VERTICAL_PADDING
        slotGap = math.max(8, cardWidth * 0.08)
        rowGap = math.max(10, cardWidth * 0.1)
        jaclWidth = cardWidth * JACL_WIDTH_MULTIPLIER
        jaclArtHeight = jaclWidth * getJaclImageAspectRatio(bundles)
        jaclHeight = jaclArtHeight + labelHeight
        panelHeight = panelHeaderHeight + cardHeight + rowGap + jaclHeight + (panelPadding * 2)
        modalHeight = titleHeight + panelHeight + (modalPadding * 2)
    end

    return {
        x = modalX,
        y = modalY,
        width = modalWidth,
        height = modalHeight,
        padding = modalPadding,
        titleHeight = titleHeight,
        panelWidth = panelWidth,
        panelHeight = panelHeight,
        panelGap = panelGap,
        panelPadding = panelPadding,
        panelHeaderHeight = panelHeaderHeight,
        slotGap = slotGap,
        rowGap = rowGap,
        cardWidth = cardWidth,
        cardHeight = cardHeight,
        jaclWidth = jaclWidth,
        jaclHeight = jaclHeight,
        labelHeight = labelHeight,
    }
end

local function drawEmptySlot(x, y, width, height, label)
    love.graphics.setColor(0.025, 0.028, 0.035, 0.88)
    love.graphics.rectangle("fill", x, y, width, height, SLOT_RADIUS, SLOT_RADIUS)
    love.graphics.setColor(0.32, 0.35, 0.39, 0.85)
    love.graphics.rectangle("line", x, y, width, height, SLOT_RADIUS, SLOT_RADIUS)
    love.graphics.line(x + 10, y + 10, x + width - 10, y + height - 10)
    love.graphics.line(x + width - 10, y + 10, x + 10, y + height - 10)
    love.graphics.setColor(0.48, 0.51, 0.55, 0.92)
    love.graphics.printf(label or "EMPTY", x, y + (height * 0.5) - 8, width, "center")
end

local function drawJaclSlot(jaclDefinition, x, y, width, cardHeight, labelHeight)
    local image = getJaclImage(jaclDefinition)
    local methodBadges = {}

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", x, y, width, cardHeight, SLOT_RADIUS, SLOT_RADIUS)

    if image then
        local imageHeight = cardHeight - labelHeight
        local scale = math.min(width / image:getWidth(), imageHeight / image:getHeight())
        local imageWidth = image:getWidth() * scale
        local scaledImageHeight = image:getHeight() * scale
        local previousScissorX, previousScissorY, previousScissorWidth, previousScissorHeight = love.graphics.getScissor()

        love.graphics.setScissor(x, y, width, imageHeight)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(image, x + ((width - imageWidth) * 0.5), y + ((imageHeight - scaledImageHeight) * 0.5), 0, scale, scale)
        if previousScissorX then
            love.graphics.setScissor(previousScissorX, previousScissorY, previousScissorWidth, previousScissorHeight)
        else
            love.graphics.setScissor()
        end
    else
        love.graphics.setColor(0.16, 0.17, 0.2, 1)
        love.graphics.rectangle("fill", x, y, width, cardHeight - labelHeight)
    end

    love.graphics.setColor(0.02, 0.02, 0.025, 1)
    love.graphics.rectangle("fill", x, y + cardHeight - labelHeight, width, labelHeight)
    love.graphics.setColor(0.93, 0.93, 0.95, 1)
    local labelFont = love.graphics.getFont()
    local labelTextY = y + cardHeight - labelHeight + ((labelHeight - labelFont:getHeight()) * 0.5)
    love.graphics.printf(
        jaclDefinition and jaclDefinition.name or "JACL",
        x + 6,
        labelTextY,
        width - 12,
        "center"
    )
    love.graphics.setColor(0.88, 0.9, 0.92, 0.95)
    love.graphics.rectangle("line", x, y, width, cardHeight, SLOT_RADIUS, SLOT_RADIUS)

    local methodResources = expandMethodEntries(jaclDefinition and jaclDefinition.method or nil)
    local badgeSize = math.max(24, math.min(JACL_METHOD_BADGE_SIZE, width * 0.14))
    local badgeGap = math.max(2, badgeSize * 0.12)
    local totalBadgeWidth = (#methodResources * badgeSize) + (math.max(0, #methodResources - 1) * badgeGap)
    local badgeStartX = x + width - JACL_METHOD_BADGE_MARGIN - totalBadgeWidth
    local badgeY = y + cardHeight - labelHeight - JACL_METHOD_BADGE_MARGIN - badgeSize

    for badgeIndex, resourceName in ipairs(methodResources) do
        local badgeX = badgeStartX + ((badgeIndex - 1) * (badgeSize + badgeGap))
        local methodImage = getMethodImage(resourceName)

        love.graphics.setColor(0.12, 0.13, 0.16, 0.95)
        love.graphics.rectangle("fill", badgeX, badgeY, badgeSize, badgeSize)
        love.graphics.setColor(0.87, 0.87, 0.9, 0.9)
        love.graphics.rectangle("line", badgeX, badgeY, badgeSize, badgeSize)

        if methodImage then
            local imageScale = math.min(badgeSize / methodImage:getWidth(), badgeSize / methodImage:getHeight())
            local imageWidth = methodImage:getWidth() * imageScale
            local imageHeight = methodImage:getHeight() * imageScale
            local imageX = badgeX + ((badgeSize - imageWidth) * 0.5)
            local imageY = badgeY + ((badgeSize - imageHeight) * 0.5)

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(methodImage, imageX, imageY, 0, imageScale, imageScale)
        end

        methodBadges[#methodBadges + 1] = {
            resource = resourceName,
            jacl = jaclDefinition,
            x = badgeX,
            y = badgeY,
            width = badgeSize,
            height = badgeSize,
        }
    end

    return methodBadges
end

local function getBundleSlotLayout(bundleIndex, layout)
    local panelX = layout.x + layout.padding + ((bundleIndex - 1) * (layout.panelWidth + layout.panelGap))
    local panelY = layout.y + layout.padding + layout.titleHeight
    local agentY = panelY + layout.panelPadding + layout.panelHeaderHeight
    local agentsWidth = (layout.cardWidth * AGENT_COUNT) + (layout.slotGap * (AGENT_COUNT - 1))
    local firstAgentX = panelX + ((layout.panelWidth - agentsWidth) * 0.5)
    local secondAgentX = firstAgentX + layout.cardWidth + layout.slotGap
    local jaclX = panelX + ((layout.panelWidth - layout.jaclWidth) * 0.5)
    local jaclY = agentY + layout.cardHeight + layout.rowGap

    return {
        panelX = panelX,
        panelY = panelY,
        panelWidth = layout.panelWidth,
        panelHeight = layout.panelHeight,
        agentY = agentY,
        agentSlots = {
            {
                x = firstAgentX,
                y = agentY,
                width = layout.cardWidth,
                height = layout.cardHeight,
            },
            {
                x = secondAgentX,
                y = agentY,
                width = layout.cardWidth,
                height = layout.cardHeight,
            },
        },
        jaclX = jaclX,
        jaclY = jaclY,
    }
end

local function getHoveredPackageIndex(state, x, y)
    if not state or not state.runSetupModal or not state.runSetupModal.isOpen then
        return nil
    end

    if state.runSetupModal.agentPreviewCardId
        or state.runSetupModal.deckModal
        or state.runSetupModal.pendingPackageSelection then
        return nil
    end

    local bundles = state.runSetupModal.bundles or {}
    local layout = getLayout(BUNDLE_COUNT, bundles)

    for bundleIndex = 1, BUNDLE_COUNT do
        local slotLayout = getBundleSlotLayout(bundleIndex, layout)

        if isPointInsideRect(x, y, {
            x = slotLayout.panelX,
            y = slotLayout.panelY,
            width = slotLayout.panelWidth,
            height = slotLayout.panelHeight,
        }) then
            return bundleIndex
        end
    end

    return nil
end

local function commitPackageSelection(state, packageIndex)
    local package = packageIndex
        and state
        and state.runSetupModal
        and state.runSetupModal.bundles
        and state.runSetupModal.bundles[packageIndex]
        or nil

    if not package then
        return false
    end

    local agentIds = {}

    for _, agent in ipairs(package.agents or {}) do
        if agent and agent.id then
            agentIds[#agentIds + 1] = agent.id
        end
    end

    state.selectedRunPackageIndex = packageIndex
    state.selectedRunJaclId = package.jacl and package.jacl.id or nil
    state.selectedRunAgentIds = agentIds
    state.selectedRunPackage = {
        packageIndex = packageIndex,
        jaclId = state.selectedRunJaclId,
        agentIds = agentIds,
        jacl = package.jacl,
        agents = package.agents or {},
    }
    state.runSetupModal.isOpen = false
    state.runSetupModal.agentPreviewCardId = nil
    state.runSetupModal.deckModal = nil
    state.runSetupModal.hoveredPackageIndex = nil
    state.runSetupModal.pendingPackageSelection = nil

    return true
end

function runsetupmodal.update(state, dt, deps)
    if not state or not state.runSetupModal or not state.runSetupModal.isOpen then
        return
    end

    local pendingSelection = state.runSetupModal.pendingPackageSelection

    if pendingSelection then
        pendingSelection.elapsed = pendingSelection.elapsed + (dt or 0)

        if pendingSelection.elapsed >= pendingSelection.duration then
            commitPackageSelection(state, pendingSelection.packageIndex)
        end

        return
    end

    local mouseX, mouseY = love.mouse.getPosition()
    local hoveredPackageIndex = getHoveredPackageIndex(state, mouseX, mouseY)

    if hoveredPackageIndex
        and hoveredPackageIndex ~= state.runSetupModal.hoveredPackageIndex
        and deps
        and deps.sfxrules
        and deps.sfxrules.playHover then
        deps.sfxrules.playHover()
    end

    state.runSetupModal.hoveredPackageIndex = hoveredPackageIndex
end

local function getAgentAt(state, x, y)
    if not state or not state.runSetupModal or not state.runSetupModal.isOpen then
        return nil
    end

    local bundles = state.runSetupModal.bundles or {}
    local layout = getLayout(BUNDLE_COUNT, bundles)

    for bundleIndex = 1, BUNDLE_COUNT do
        local bundle = bundles[bundleIndex]
        local slotLayout = getBundleSlotLayout(bundleIndex, layout)

        for agentSlotIndex = 1, AGENT_COUNT do
            local agent = bundle and bundle.agents and bundle.agents[agentSlotIndex] or nil

            if agent and isPointInsideRect(x, y, slotLayout.agentSlots[agentSlotIndex]) then
                return agent
            end
        end
    end

    return nil
end

local function getDeckSourceAt(state, x, y)
    if not state or not state.runSetupModal or not state.runSetupModal.isOpen then
        return nil
    end

    local bundles = state.runSetupModal.bundles or {}
    local layout = getLayout(BUNDLE_COUNT, bundles)

    for bundleIndex = 1, BUNDLE_COUNT do
        local bundle = bundles[bundleIndex]
        local slotLayout = getBundleSlotLayout(bundleIndex, layout)

        for agentSlotIndex = 1, AGENT_COUNT do
            local agent = bundle and bundle.agents and bundle.agents[agentSlotIndex] or nil

            if agent and isPointInsideRect(x, y, slotLayout.agentSlots[agentSlotIndex]) then
                return {
                    deckId = agent.deck or agent.deckId,
                    title = agent.name,
                }
            end
        end

        if bundle
            and bundle.jacl
            and isPointInsideRect(x, y, {
                x = slotLayout.jaclX,
                y = slotLayout.jaclY,
                width = layout.jaclWidth,
                height = layout.jaclHeight,
            }) then
            return {
                deckId = bundle.jacl.deckId or bundle.jacl.deck,
                title = bundle.jacl.name,
            }
        end
    end

    return nil
end

local function drawPackageButton(panelX, panelY, panelWidth)
    local buttonSize = PACKAGE_BUTTON_SIZE
    local buttonX = panelX + panelWidth - PACKAGE_BUTTON_MARGIN - buttonSize
    local buttonY = panelY + PACKAGE_BUTTON_MARGIN
    local triangleInsetX = buttonSize * 0.34
    local triangleInsetY = buttonSize * 0.28

    love.graphics.setColor(0.906, 0.102, 0.176, 1)
    love.graphics.rectangle("fill", buttonX, buttonY, buttonSize, buttonSize, 3, 3)
    love.graphics.setColor(0.96, 0.96, 0.95, 1)
    love.graphics.polygon(
        "fill",
        buttonX + triangleInsetX,
        buttonY + triangleInsetY,
        buttonX + triangleInsetX,
        buttonY + buttonSize - triangleInsetY,
        buttonX + buttonSize - triangleInsetX + 2,
        buttonY + (buttonSize * 0.5)
    )
end

local function getPackageButtonRect(slotLayout)
    return {
        x = slotLayout.panelX + slotLayout.panelWidth - PACKAGE_BUTTON_MARGIN - PACKAGE_BUTTON_SIZE,
        y = slotLayout.panelY + PACKAGE_BUTTON_MARGIN,
        width = PACKAGE_BUTTON_SIZE,
        height = PACKAGE_BUTTON_SIZE,
    }
end

local function getPackageButtonAt(state, x, y)
    if not state or not state.runSetupModal or not state.runSetupModal.isOpen then
        return nil
    end

    local bundles = state.runSetupModal.bundles or {}
    local layout = getLayout(BUNDLE_COUNT, bundles)

    for bundleIndex = 1, BUNDLE_COUNT do
        local slotLayout = getBundleSlotLayout(bundleIndex, layout)

        if isPointInsideRect(x, y, getPackageButtonRect(slotLayout)) then
            return bundleIndex
        end
    end

    return nil
end

local function beginPackageSelection(state, packageIndex, deps)
    local package = packageIndex
        and state
        and state.runSetupModal
        and state.runSetupModal.bundles
        and state.runSetupModal.bundles[packageIndex]
        or nil

    if not package then
        return false
    end

    state.runSetupModal.pendingPackageSelection = {
        packageIndex = packageIndex,
        elapsed = 0,
        duration = PACKAGE_SELECTION_FLASH_DURATION,
    }
    state.runSetupModal.agentPreviewCardId = nil
    state.runSetupModal.deckModal = nil
    state.runSetupModal.hoveredPackageIndex = nil

    if deps and deps.sfxrules and deps.sfxrules.playGo then
        deps.sfxrules.playGo()
    end

    return true
end

local function drawBundle(bundle, bundleIndex, layout, titleFont, mouseX, mouseY, isHovered, pendingSelection)
    local slotLayout = getBundleSlotLayout(bundleIndex, layout)
    local panelX = slotLayout.panelX
    local panelY = slotLayout.panelY

    if isHovered then
        love.graphics.setColor(0.105, 0.116, 0.14, 0.98)
    else
        love.graphics.setColor(0.075, 0.082, 0.098, 0.96)
    end
    love.graphics.rectangle("fill", panelX, panelY, layout.panelWidth, layout.panelHeight, PANEL_RADIUS, PANEL_RADIUS)
    if pendingSelection and pendingSelection.packageIndex == bundleIndex then
        local flashIndex = math.floor((pendingSelection.elapsed or 0) / PACKAGE_SELECTION_FLASH_INTERVAL)

        if flashIndex % 2 == 0 then
            love.graphics.setColor(1, 0.74, 0.18, 1)
        else
            love.graphics.setColor(0, 0, 0, 1)
        end
    elseif isHovered then
        love.graphics.setColor(1, 0.74, 0.18, 0.98)
    else
        love.graphics.setColor(bundleIndex == 1 and 0.95 or 0.38, bundleIndex == 1 and 0.28 or 0.42, bundleIndex == 1 and 0.15 or 0.46, 0.9)
    end
    love.graphics.rectangle("line", panelX, panelY, layout.panelWidth, layout.panelHeight, PANEL_RADIUS, PANEL_RADIUS)
    drawPackageButton(panelX, panelY, layout.panelWidth)

    love.graphics.setFont(titleFont)
    love.graphics.setColor(0.88, 0.9, 0.92, 1)
    love.graphics.printf(
        "PACKAGE " .. bundleIndex,
        panelX + layout.panelPadding,
        panelY + 10,
        layout.panelWidth - (layout.panelPadding * 2) - PACKAGE_BUTTON_SIZE - PACKAGE_BUTTON_MARGIN,
        "left"
    )

    for agentSlotIndex = 1, AGENT_COUNT do
        local agent = bundle and bundle.agents and bundle.agents[agentSlotIndex] or nil
        local agentSlot = slotLayout.agentSlots[agentSlotIndex]

        if agent then
            carddraw.drawCard("troops", agent.id, agentSlot.x, agentSlot.y, {
                width = layout.cardWidth,
            })
        else
            drawEmptySlot(agentSlot.x, agentSlot.y, layout.cardWidth, layout.cardHeight, "AGENT")
        end
    end

    if bundle and bundle.jacl then
        local methodBadges = drawJaclSlot(bundle.jacl, slotLayout.jaclX, slotLayout.jaclY, layout.jaclWidth, layout.jaclHeight, layout.labelHeight)

        for _, badge in ipairs(methodBadges or {}) do
            if isPointInsideRect(mouseX, mouseY, badge) then
                return badge
            end
        end
    else
        drawEmptySlot(slotLayout.jaclX, slotLayout.jaclY, layout.jaclWidth, layout.jaclHeight, "JACL")
    end

    return nil
end

local function drawJaclMethodTooltip(hoveredBadge)
    if not hoveredBadge or not hoveredBadge.jacl or not hoveredBadge.resource then
        return
    end

    local specialDefinition = abilityrules.getJaclMethodAbility(hoveredBadge.jacl, hoveredBadge.resource, nil)
    local preview = previewrules.getDefinitionPreview(specialDefinition)

    envdraw.drawJaclSpecialTooltip(
        specialDefinition,
        preview and preview.cardDefinition or nil,
        hoveredBadge.x,
        hoveredBadge.y,
        hoveredBadge.width,
        hoveredBadge.height
    )
end

local function drawAgentPreview(cardId)
    if not cardId then
        return nil
    end

    local screenWidth, screenHeight = love.graphics.getDimensions()
    local previewWidth = math.min(AGENT_PREVIEW_WIDTH, screenWidth * 0.34)
    local renderOptions = {
        width = previewWidth,
        showBadgesInTextbox = true,
        showHealthOnPortrait = true,
    }
    local _, previewHeight = carddraw.getExpandedCardSize(renderOptions)
    local maxPreviewHeight = screenHeight * AGENT_PREVIEW_SCREEN_HEIGHT_RATIO

    if previewHeight > maxPreviewHeight then
        previewWidth = previewWidth * (maxPreviewHeight / previewHeight)
        renderOptions.width = previewWidth
        _, previewHeight = carddraw.getExpandedCardSize(renderOptions)
    end

    local previewX = (screenWidth - previewWidth) * 0.5
    local previewY = (screenHeight - previewHeight) * 0.5

    love.graphics.setColor(0, 0, 0, 0.58)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    love.graphics.setColor(1, 1, 1, 1)
    carddraw.drawCardState("troops", cardId, previewX, previewY, 1, renderOptions)

    return {
        cardId = cardId,
        x = previewX,
        y = previewY,
        width = previewWidth,
        height = previewHeight,
        renderOptions = renderOptions,
    }
end

local function getPreviewMethodAbility(cardId, resourceName)
    if not cardId or not resourceName then
        return nil
    end

    local cardDefinition = cardregistry.getCard("troops", cardId)

    for _, abilityDefinition in ipairs(cardDefinition and cardDefinition.agentAbilities or {}) do
        if abilityDefinition
            and abilityDefinition.trigger == "method_badge_click"
            and abilityDefinition.badgeResource == resourceName then
            return abilityDefinition
        end
    end

    return nil
end

local function getHoveredPreviewMethodBadge(previewLayout, mouseX, mouseY)
    if not previewLayout then
        return nil
    end

    local badgeRects = carddraw.getMethodBadgeRects(
        "troops",
        previewLayout.cardId,
        previewLayout.x,
        previewLayout.y,
        1,
        previewLayout.renderOptions
    )

    for _, badgeRect in ipairs(badgeRects or {}) do
        if isPointInsideRect(mouseX, mouseY, badgeRect) then
            badgeRect.cardId = previewLayout.cardId
            return badgeRect
        end
    end

    return nil
end

local function drawPreviewMethodTooltip(previewLayout, mouseX, mouseY)
    local hoveredMethodBadge = getHoveredPreviewMethodBadge(previewLayout, mouseX, mouseY)

    if not hoveredMethodBadge then
        return false
    end

    local abilityDefinition = getPreviewMethodAbility(hoveredMethodBadge.cardId, hoveredMethodBadge.resource)
    local preview = previewrules.getDefinitionPreview(abilityDefinition, abilityDefinition and abilityDefinition.previewLabel or "CREATE")

    envdraw.drawJaclSpecialTooltip(
        abilityDefinition,
        preview and (preview.cardDefinitionEntries or preview.cardDefinitions) or nil,
        previewLayout.x,
        previewLayout.y,
        previewLayout.width,
        previewLayout.height
    )

    return abilityDefinition ~= nil
end

local function drawPreviewDiceTooltip(previewLayout, mouseX, mouseY)
    if not previewLayout then
        return false
    end

    local diceTooltip = carddraw.getHoveredDiceFace(
        "troops",
        previewLayout.cardId,
        previewLayout.x,
        previewLayout.y,
        1,
        previewLayout.renderOptions,
        mouseX,
        mouseY,
        nil
    )

    if not diceTooltip then
        return false
    end

    local previewCards = diceTooltip.previewCardDefinitionEntries or diceTooltip.previewCardDefinitions

    carddraw.drawDiceFaceTooltip(diceTooltip)

    if previewCards and #previewCards > 0 then
        envdraw.drawSummonPreviewTooltip(
            previewCards,
            diceTooltip.cardX,
            diceTooltip.cardY,
            diceTooltip.cardWidth,
            diceTooltip.cardHeight,
            diceTooltip.previewLabel
        )
    elseif diceTooltip.previewCardDefinition then
        envdraw.drawTomeSpawnTooltip(
            diceTooltip.previewCardDefinition,
            diceTooltip.cardX,
            diceTooltip.cardY,
            diceTooltip.cardWidth,
            diceTooltip.cardHeight
        )
    end

    return true
end

local function drawPreviewHoverTooltips(previewLayout, mouseX, mouseY)
    if drawPreviewMethodTooltip(previewLayout, mouseX, mouseY) then
        return
    end

    drawPreviewDiceTooltip(previewLayout, mouseX, mouseY)
end

local function openDeckModal(state, deckSource)
    local deck = deckSource and deckrules.buildDeck(deckSource.deckId) or nil

    if not deck then
        return false
    end

    deck.owner = "worldstage"
    deck.displayTitle = deckSource.title

    state.runSetupModal.deckModal = {
        deck = deck,
        scrollY = 0,
    }

    return true
end

local function getDeckModalLayout(deckModal)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local deck = deckModal and deckModal.deck or nil
    local cards = deck and deck.cards or {}
    local cardWidth, cardHeight = carddraw.getCardSize({
        width = DECK_MODAL_CARD_WIDTH,
        showLabelWhenCollapsed = true,
    })
    local sectionWidth = math.max(
        cardWidth,
        windowWidth - ((DECK_MODAL_MARGIN + DECK_MODAL_PADDING) * 2)
    )
    local cardsPerRow = math.max(1, math.floor((sectionWidth + DECK_MODAL_CARD_GAP) / (cardWidth + DECK_MODAL_CARD_GAP)))
    local usedSectionWidth = (cardsPerRow * cardWidth) + ((cardsPerRow - 1) * DECK_MODAL_CARD_GAP)
    local contentWidth = math.min(sectionWidth, usedSectionWidth)
    local modalWidth = contentWidth + (DECK_MODAL_PADDING * 2)
    local viewportHeight = math.max(
        cardHeight,
        math.min(
            windowHeight - (DECK_MODAL_MARGIN * 2) - (DECK_MODAL_PADDING * 2) - DECK_MODAL_HEADER_HEIGHT,
            (windowHeight * DECK_MODAL_MAX_HEIGHT_RATIO) - (DECK_MODAL_PADDING * 2) - DECK_MODAL_HEADER_HEIGHT
        )
    )
    local rows = math.max(1, math.ceil(math.max(1, #cards) / cardsPerRow))
    local bodyContentHeight = (rows * cardHeight) + ((rows - 1) * DECK_MODAL_CARD_GAP)
    local maxScroll = math.max(0, bodyContentHeight - viewportHeight)
    local scrollY = math.max(0, math.min(maxScroll, deckModal and deckModal.scrollY or 0))
    local modalHeight = DECK_MODAL_HEADER_HEIGHT + viewportHeight + (DECK_MODAL_PADDING * 2)
    local modalX = (windowWidth - modalWidth) * 0.5
    local modalY = (windowHeight - modalHeight) * 0.5
    local bodyX = modalX + DECK_MODAL_PADDING
    local bodyY = modalY + DECK_MODAL_PADDING + DECK_MODAL_HEADER_HEIGHT
    local cardLayouts = {}

    for cardIndex, card in ipairs(cards) do
        local rowIndex = math.floor((cardIndex - 1) / cardsPerRow)
        local columnIndex = (cardIndex - 1) % cardsPerRow

        cardLayouts[#cardLayouts + 1] = {
            card = card,
            x = bodyX + (columnIndex * (cardWidth + DECK_MODAL_CARD_GAP)),
            y = bodyY + (rowIndex * (cardHeight + DECK_MODAL_CARD_GAP)) - scrollY,
            width = cardWidth,
        }
    end

    return {
        x = modalX,
        y = modalY,
        width = modalWidth,
        height = modalHeight,
        bodyX = bodyX,
        bodyY = bodyY,
        bodyWidth = contentWidth,
        bodyHeight = viewportHeight,
        bodyContentHeight = bodyContentHeight,
        cardHeight = cardHeight,
        cardLayouts = cardLayouts,
        maxScroll = maxScroll,
        scrollY = scrollY,
    }
end

local function getDeckModalCardAt(deckModal, x, y)
    local layout = getDeckModalLayout(deckModal)

    if not isPointInsideRect(x, y, {
        x = layout.bodyX,
        y = layout.bodyY,
        width = layout.bodyWidth,
        height = layout.bodyHeight,
    }) then
        return nil
    end

    for _, cardLayout in ipairs(layout.cardLayouts or {}) do
        if carddraw.isPointInsideCard(x, y, cardLayout.x, cardLayout.y, 0, {
            width = cardLayout.width,
            showLabelWhenCollapsed = true,
            showHealthOnPortrait = false,
            showBadgesInTextbox = true,
        }) then
            return cardLayout.card
        end
    end

    return nil
end

local function normalizeDiceSummonPreviewEntries(previewCards)
    local entries = {}

    for _, previewCard in ipairs(previewCards or {}) do
        if previewCard.definition then
            entries[#entries + 1] = {
                definition = previewCard.definition,
                count = math.max(1, math.floor(tonumber(previewCard.count or previewCard.quantity) or 1)),
            }
        elseif previewCard.cardDefinition then
            entries[#entries + 1] = {
                definition = previewCard.cardDefinition,
                count = math.max(1, math.floor(tonumber(previewCard.count or previewCard.quantity) or 1)),
            }
        else
            entries[#entries + 1] = {
                definition = previewCard,
                count = math.max(1, math.floor(tonumber(previewCard.count or previewCard.quantity) or 1)),
            }
        end
    end

    return entries
end

local function getDiceSummonPreviewEntryWidth(previewWidth, previewEntry)
    local count = math.max(1, tonumber(previewEntry and previewEntry.count) or 1)
    local visibleStackCount = math.min(count, 5)

    return previewWidth + ((visibleStackCount - 1) * previewWidth * 0.24)
end

local function getDiceSummonPreviewWidth(previewEntries, previewWidth)
    local width = 0

    for entryIndex, previewEntry in ipairs(previewEntries or {}) do
        if entryIndex > 1 then
            width = width + DICE_SUMMON_PREVIEW_GAP
        end

        width = width + getDiceSummonPreviewEntryWidth(previewWidth, previewEntry)
    end

    return width
end

local function drawDiceSummonPreviewStack(previewEntry, x, y, previewWidth, previewHeight, labelFont)
    local definition = previewEntry and previewEntry.definition or nil

    if not definition then
        return
    end

    local count = math.max(1, math.floor(tonumber(previewEntry.count) or 1))
    local visibleStackCount = math.min(count, 5)
    local stackOffset = previewWidth * 0.24

    for stackIndex = visibleStackCount, 1, -1 do
        local cardX = x + ((stackIndex - 1) * stackOffset)

        if stackIndex > 1 then
            love.graphics.setColor(0.02, 0.025, 0.03, 0.72)
            love.graphics.rectangle("fill", cardX - 4, y + 4, previewWidth, previewHeight, 8, 8)
            love.graphics.setColor(0.86, 0.88, 0.93, 0.64)
            love.graphics.rectangle("line", cardX, y, previewWidth, previewHeight, 8, 8)
        end

        carddraw.drawCardState(definition.setName, definition.id, cardX, y, 1, {
            width = previewWidth,
            showBadgesInTextbox = true,
        })
    end

    if count > 1 then
        local badgeText = "x" .. tostring(count)
        local badgePaddingX = DICE_SUMMON_PREVIEW_PADDING * 0.7
        local badgeHeight = labelFont:getHeight() + 8
        local badgeWidth = math.max(labelFont:getWidth(badgeText) + (badgePaddingX * 2), badgeHeight)
        local badgeX = x + getDiceSummonPreviewEntryWidth(previewWidth, previewEntry) - badgeWidth - 8
        local badgeY = y + previewHeight - badgeHeight - 8

        love.graphics.setColor(0.04, 0.045, 0.055, 0.94)
        love.graphics.rectangle("fill", badgeX, badgeY, badgeWidth, badgeHeight, 5, 5)
        love.graphics.setColor(0.92, 0.94, 0.98, 0.92)
        love.graphics.rectangle("line", badgeX, badgeY, badgeWidth, badgeHeight, 5, 5)
        love.graphics.setFont(labelFont)
        love.graphics.setColor(0.96, 0.97, 1, 1)
        love.graphics.printf(badgeText, badgeX, badgeY + ((badgeHeight - labelFont:getHeight()) / 2), badgeWidth, "center")
    end
end

local function drawDiceSummonPreviewLeft(previewCards, labelText, cardLayout)
    local previewEntries = normalizeDiceSummonPreviewEntries(previewCards)

    if #previewEntries <= 0 or not cardLayout then
        return
    end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    local labelFont = getFont()
    local previewWidth, previewHeight = carddraw.getExpandedCardSize({
        width = math.min(190, math.max(150, windowWidth * 0.1)),
    })
    local totalWidth = getDiceSummonPreviewWidth(previewEntries, previewWidth)
    local bubbleHeight = (DICE_SUMMON_PREVIEW_PADDING * 2) + labelFont:getHeight()
    local totalHeight = previewHeight + DICE_SUMMON_PREVIEW_GAP + bubbleHeight
    local boxX = math.max(8, cardLayout.cardX - DICE_SUMMON_PREVIEW_GAP - totalWidth)
    local boxY = math.max(8, math.min(cardLayout.cardY, windowHeight - totalHeight - 8))
    local bubbleY = boxY + previewHeight + DICE_SUMMON_PREVIEW_GAP
    local previewX = boxX

    love.graphics.setColor(0.02, 0.025, 0.03, 0.42)
    love.graphics.rectangle(
        "fill",
        boxX - DICE_SUMMON_PREVIEW_PADDING,
        boxY - DICE_SUMMON_PREVIEW_PADDING,
        totalWidth + (DICE_SUMMON_PREVIEW_PADDING * 2),
        totalHeight + (DICE_SUMMON_PREVIEW_PADDING * 2),
        8,
        8
    )

    for _, previewEntry in ipairs(previewEntries) do
        drawDiceSummonPreviewStack(previewEntry, previewX, boxY, previewWidth, previewHeight, labelFont)
        previewX = previewX + getDiceSummonPreviewEntryWidth(previewWidth, previewEntry) + DICE_SUMMON_PREVIEW_GAP
    end

    love.graphics.setColor(0.05, 0.05, 0.06, 0.96)
    love.graphics.rectangle("fill", boxX, bubbleY, totalWidth, bubbleHeight, 6, 6)
    love.graphics.setColor(0.82, 0.85, 0.89, 0.82)
    love.graphics.rectangle("line", boxX, bubbleY, totalWidth, bubbleHeight, 6, 6)

    love.graphics.setFont(labelFont)
    love.graphics.setColor(0.95, 0.96, 0.98, 1)
    love.graphics.printf(
        labelText or "SUMMON",
        boxX + DICE_SUMMON_PREVIEW_PADDING,
        bubbleY + ((bubbleHeight - labelFont:getHeight()) / 2),
        totalWidth - (DICE_SUMMON_PREVIEW_PADDING * 2),
        "center"
    )
end

local function drawDeckCardPreview(card)
    if not card then
        return
    end

    local cardDefinition = cardregistry.getCard(card.setName, card.cardId)
    local preview = previewrules.getDefinitionPreview(cardDefinition, nil, card)
    local previewCards = preview and (preview.cardDefinitionEntries or preview.cardDefinitions) or nil
    local layout = envdraw.getJaclDeckPreviewModalLayout(previewCards)
    local mouseX, mouseY = love.mouse.getPosition()
    local diceTooltip = nil

    envdraw.drawJaclDeckPreviewModal(card, preview)

    diceTooltip = carddraw.getHoveredDiceFace(
        card.setName,
        card.cardId,
        layout.cardX,
        layout.cardY,
        1,
        {
            displayName = card.displayName,
            portraitPath = card.portraitPath,
            showBadgesInTextbox = true,
        },
        mouseX,
        mouseY,
        nil
    )

    if diceTooltip then
        previewrules.applyDefinitionPreviewToTooltip(diceTooltip.definition or diceTooltip, diceTooltip, diceTooltip.previewLabel or "SUMMON")

        local dicePreviewCards = diceTooltip.previewCardDefinitionEntries or diceTooltip.previewCardDefinitions

        if dicePreviewCards and #dicePreviewCards > 0 then
            drawDiceSummonPreviewLeft(dicePreviewCards, diceTooltip.previewLabel, layout)
        elseif diceTooltip.previewCardDefinition then
            drawDiceSummonPreviewLeft({ diceTooltip.previewCardDefinition }, diceTooltip.previewLabel, layout)
        end

        carddraw.drawDiceFaceTooltip(diceTooltip)
    end
end

local function drawDeckModal(deckModal)
    if not deckModal or not deckModal.deck then
        return
    end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    local layout = getDeckModalLayout(deckModal)
    local previousFont = love.graphics.getFont()
    local headerFont = getFont()
    local deck = deckModal.deck
    local cards = deck.cards or {}
    local title = deck.displayTitle or deck.name or "Deck"

    love.graphics.setColor(0.01, 0.01, 0.02, 0.72)
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    love.graphics.setColor(0.06, 0.07, 0.09, 0.96)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height, 10, 10)
    love.graphics.setColor(0.82, 0.85, 0.89, 0.78)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height, 10, 10)

    love.graphics.setFont(headerFont)
    love.graphics.setColor(0.93, 0.93, 0.95, 1)
    love.graphics.print(
        title .. " Deck (" .. tostring(#cards) .. ")",
        layout.x + DECK_MODAL_PADDING,
        layout.y + DECK_MODAL_PADDING + ((DECK_MODAL_HEADER_HEIGHT - headerFont:getHeight()) * 0.5)
    )

    love.graphics.setScissor(
        math.floor(layout.bodyX),
        math.floor(layout.bodyY),
        math.max(1, math.floor(layout.bodyWidth)),
        math.max(1, math.floor(layout.bodyHeight))
    )
    for _, cardLayout in ipairs(layout.cardLayouts) do
        carddraw.drawCardState(cardLayout.card.setName, cardLayout.card.cardId, cardLayout.x, cardLayout.y, 0, {
            width = cardLayout.width,
            showLabelWhenCollapsed = true,
            showHealthOnPortrait = false,
            showBadgesInTextbox = true,
            displayName = cardLayout.card.displayName,
            portraitPath = cardLayout.card.portraitPath,
        })
    end
    love.graphics.setScissor()

    if layout.maxScroll > 0 then
        local trackHeight = math.max(24, layout.bodyHeight)
        local thumbHeight = math.max(20, trackHeight * (layout.bodyHeight / layout.bodyContentHeight))
        local thumbTravel = math.max(0, trackHeight - thumbHeight)
        local thumbY = layout.bodyY + (thumbTravel * (layout.scrollY / layout.maxScroll))

        love.graphics.setColor(0.22, 0.24, 0.29, 0.9)
        love.graphics.rectangle("fill", layout.bodyX + layout.bodyWidth - 6, layout.bodyY + 4, 3, trackHeight - 8, 2, 2)
        love.graphics.setColor(0.88, 0.9, 0.94, 0.8)
        love.graphics.rectangle("fill", layout.bodyX + layout.bodyWidth - 7, thumbY + 4, 5, math.max(12, thumbHeight - 8), 2, 2)
    end

    drawDeckCardPreview(deckModal.cardPreview)

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

function runsetupmodal.mousepressed(state, x, y, button, deps)
    if not state or not state.runSetupModal or not state.runSetupModal.isOpen then
        return false
    end

    if state.runSetupModal.pendingPackageSelection then
        return true
    end

    if state.runSetupModal.agentPreviewCardId then
        state.runSetupModal.agentPreviewCardId = nil
        return true
    end

    local deckModal = state.runSetupModal.deckModal

    if deckModal then
        if deckModal.cardPreview then
            deckModal.cardPreview = nil
            return true
        end

        if button == 2 then
            deckModal.cardPreview = getDeckModalCardAt(deckModal, x, y)
            return true
        end

        state.runSetupModal.deckModal = nil
        return true
    end

    if button == 1 then
        local packageIndex = getPackageButtonAt(state, x, y)

        if packageIndex then
            return beginPackageSelection(state, packageIndex, deps)
        end
    end

    if button == 3 then
        return openDeckModal(state, getDeckSourceAt(state, x, y))
    end

    if button ~= 2 then
        return false
    end

    local agent = getAgentAt(state, x, y)

    if not agent then
        return false
    end

    state.runSetupModal.agentPreviewCardId = agent.id
    return true
end

function runsetupmodal.wheelmoved(state, _, y)
    local deckModal = state and state.runSetupModal and state.runSetupModal.deckModal or nil

    if not deckModal or not deckModal.deck then
        return false
    end

    local mouseX, mouseY = love.mouse.getPosition()
    local layout = getDeckModalLayout(deckModal)

    if not isPointInsideRect(mouseX, mouseY, {
        x = layout.bodyX,
        y = layout.bodyY,
        width = layout.bodyWidth,
        height = layout.bodyHeight,
    }) then
        return true
    end

    local scrollDelta = -(y or 0) * 42
    deckModal.scrollY = math.max(0, math.min(layout.maxScroll, (deckModal.scrollY or 0) + scrollDelta))

    return true
end

function runsetupmodal.draw(state)
    if not state or not state.runSetupModal or not state.runSetupModal.isOpen then
        return
    end

    local bundles = state.runSetupModal.bundles or {}
    local layout = getLayout(BUNDLE_COUNT, bundles)
    local previousFont = love.graphics.getFont()
    local titleFont = getFont()
    local mouseX, mouseY = love.mouse.getPosition()
    local hoveredBadge = nil

    love.graphics.setColor(0, 0, 0, 0.42)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(0.04, 0.045, 0.055, 0.98)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height, 8, 8)
    love.graphics.setColor(0.82, 0.85, 0.89, 0.86)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height, 8, 8)

    love.graphics.setFont(titleFont)
    love.graphics.setColor(0.92, 0.94, 0.9, 1)
    love.graphics.printf("EMBARK", layout.x + layout.padding, layout.y + layout.padding - 2, layout.width - (layout.padding * 2), "left")
    love.graphics.setColor(0.54, 0.58, 0.62, 1)
    love.graphics.printf("Choose a JACL and agent bundle", layout.x + layout.padding, layout.y + layout.padding + 22, layout.width - (layout.padding * 2), "left")

    for bundleIndex = 1, BUNDLE_COUNT do
        hoveredBadge = drawBundle(
            bundles[bundleIndex],
            bundleIndex,
            layout,
            titleFont,
            mouseX,
            mouseY,
            state.runSetupModal.hoveredPackageIndex == bundleIndex,
            state.runSetupModal.pendingPackageSelection
        ) or hoveredBadge
    end

    if not state.runSetupModal.agentPreviewCardId and not state.runSetupModal.deckModal then
        drawJaclMethodTooltip(hoveredBadge)
    end

    local previewLayout = drawAgentPreview(state.runSetupModal.agentPreviewCardId)

    if previewLayout then
        drawPreviewHoverTooltips(previewLayout, mouseX, mouseY)
    end

    drawDeckModal(state.runSetupModal.deckModal)

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

return runsetupmodal
