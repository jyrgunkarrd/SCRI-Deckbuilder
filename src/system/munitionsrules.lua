local munitionsDefinitions = require("data.munitions")

local munitionsrules = {}

local MUNITIONS_SCRIPT_MODULE_PREFIX = "data.scripts."
local MUNITIONS_PROJECTILE_DURATION = 0.42
local MUNITIONS_PROJECTILE_COLOR = { 0.549, 1, 0.871, 1 }
local ENEMY_ROW_ID = "OppRow"

local munitionsById = nil
local scriptHandlers = {}
local activeProjectiles = {}

local function loadMunitions()
    if munitionsById ~= nil then
        return
    end

    munitionsById = {}

    for _, definition in ipairs(munitionsDefinitions or {}) do
        if definition.id then
            munitionsById[definition.id] = definition
        end
    end
end

function munitionsrules.getMunitions(munId)
    loadMunitions()
    return munId and munitionsById[munId] or nil
end

function munitionsrules.getJaclMunitions(jaclDefinition)
    return jaclDefinition and munitionsrules.getMunitions(jaclDefinition.munId) or nil
end

local function cloneColor(color)
    return { color[1], color[2], color[3], color[4] }
end

local function getScriptHandler(systemDefinition)
    local scriptName = systemDefinition and (systemDefinition.script or systemDefinition.id) or nil

    if not scriptName then
        return nil
    end

    scriptName = tostring(scriptName)

    if scriptHandlers[scriptName] ~= nil then
        return scriptHandlers[scriptName] or nil
    end

    local ok, handler = pcall(require, MUNITIONS_SCRIPT_MODULE_PREFIX .. scriptName)

    if ok then
        scriptHandlers[scriptName] = handler
        return handler
    end

    if not tostring(handler):find("module '" .. MUNITIONS_SCRIPT_MODULE_PREFIX .. scriptName .. "' not found", 1, true) then
        print(handler)
    end

    scriptHandlers[scriptName] = false
    return nil
end

local function getButtonCenter(ctx)
    local button = ctx.envdraw.getSyntacRewardButtonLayout("munitions", ctx.state.playerJacl)

    return button and {
        x = button.x + (button.width / 2),
        y = button.y + (button.height / 2),
    } or nil
end

function munitionsrules.isLiveEnemyCard(card)
    if not card
        or not card.location
        or card.location.kind ~= "grid"
        or card.location.rowId ~= ENEMY_ROW_ID
        or card.destroyed
        or card.destroying
    then
        return false
    end

    local currentHealth = tonumber(card.currentHealth)
    return currentHealth == nil or currentHealth > 0
end

function munitionsrules.getLiveEnemyCardIndices(ctx)
    local indices = {}

    for cardIndex, card in ipairs(ctx and ctx.state and ctx.state.cards or {}) do
        if munitionsrules.isLiveEnemyCard(card) then
            indices[#indices + 1] = cardIndex
        end
    end

    return indices
end

function munitionsrules.getCardCenter(ctx, cardIndex)
    local card = ctx and ctx.state and ctx.state.cards and ctx.state.cards[cardIndex] or nil

    if not card or not ctx.getCardDrawPosition or not ctx.carddraw then
        return nil
    end

    local drawX, drawY, expansionProgress, renderOptions = ctx.getCardDrawPosition(card, cardIndex)
    local cardWidth, collapsedHeight = ctx.carddraw.getCardSize(renderOptions)
    local _, expandedHeight = ctx.carddraw.getExpandedCardSize(renderOptions)
    local cardHeight = collapsedHeight + ((expandedHeight - collapsedHeight) * (expansionProgress or 0))

    return {
        x = drawX + (cardWidth / 2),
        y = drawY + (cardHeight / 2),
    }
end

function munitionsrules.queueProjectile(sourceCenter, targetCenter, onHit)
    if not sourceCenter or not targetCenter then
        return false
    end

    activeProjectiles[#activeProjectiles + 1] = {
        sourceX = sourceCenter.x,
        sourceY = sourceCenter.y,
        targetX = targetCenter.x,
        targetY = targetCenter.y,
        elapsed = 0,
        duration = MUNITIONS_PROJECTILE_DURATION,
        color = cloneColor(MUNITIONS_PROJECTILE_COLOR),
        onHit = onHit,
    }

    return true
end

function munitionsrules.getActiveProjectiles()
    return activeProjectiles
end

function munitionsrules.update(dt, deps)
    for projectileIndex = #activeProjectiles, 1, -1 do
        local projectile = activeProjectiles[projectileIndex]
        projectile.elapsed = projectile.elapsed + dt

        if projectile.elapsed >= projectile.duration then
            if deps and deps.sfxrules and deps.sfxrules.playMunitions then
                deps.sfxrules.playMunitions()
            end

            if projectile.onHit then
                projectile.onHit()
            end

            table.remove(activeProjectiles, projectileIndex)
        end
    end
end

function munitionsrules.reset()
    activeProjectiles = {}
end

function munitionsrules.tryUseButton(ctx)
    local state = ctx.state
    local worldResources = ctx.worldResources or {}
    local systemDefinition = state and state.munitionsSystem or nil
    local button = ctx.envdraw.getSyntacRewardButtonLayout("munitions", state.playerJacl)

    if not systemDefinition or not button then
        ctx.sfxrules.playPlayReject()
        return true
    end

    if not ((ctx.getCurrentPhase and ctx.getCurrentPhase() == "Prelude") or (ctx.isEngagePhase and ctx.isEngagePhase())) then
        ctx.sfxrules.playPlayReject()
        return true
    end

    state.syntacRewardButtons = state.syntacRewardButtons or {}

    if state.syntacRewardButtons.munitions then
        ctx.sfxrules.playPlayReject()
        return true
    end

    if (tonumber(worldResources.munitions) or 0) <= 0 then
        ctx.sfxrules.playPlayReject()
        return true
    end

    local scriptHandler = getScriptHandler(systemDefinition)
    local activate = type(scriptHandler) == "table" and (scriptHandler.activate or scriptHandler.fire or scriptHandler.use) or scriptHandler

    if type(activate) ~= "function" then
        ctx.sfxrules.playPlayReject()
        return true
    end

    local ok = activate({
        state = state,
        system = systemDefinition,
        sourceCenter = getButtonCenter(ctx),
        queueProjectile = munitionsrules.queueProjectile,
        getLiveEnemyCardIndices = function()
            return munitionsrules.getLiveEnemyCardIndices(ctx)
        end,
        getCardCenter = function(cardIndex)
            return munitionsrules.getCardCenter(ctx, cardIndex)
        end,
        dealDamageToCard = ctx.dealDamageToCard,
    })

    if not ok then
        ctx.sfxrules.playPlayReject()
        return true
    end

    worldResources.munitions = math.max(0, math.floor((tonumber(worldResources.munitions) or 0) - 1))
    state.syntacRewardButtons.munitions = true
    return true
end

return munitionsrules
