local titheDefinitions = require("data.tithes")

local tithesrules = {}

local TITHE_SCRIPT_MODULE_PREFIX = "data.scripts."

local tithesById = nil
local scriptHandlers = {}

local function loadTithes()
    if tithesById ~= nil then
        return
    end

    tithesById = {}

    for _, definition in ipairs(titheDefinitions or {}) do
        if definition.id then
            tithesById[definition.id] = definition
        end
    end
end

function tithesrules.getTithe(titheId)
    loadTithes()
    return titheId and tithesById[titheId] or nil
end

function tithesrules.getJaclTithe(jaclDefinition)
    return jaclDefinition and tithesrules.getTithe(jaclDefinition.titheId) or nil
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

    local ok, handler = pcall(require, TITHE_SCRIPT_MODULE_PREFIX .. scriptName)

    if ok then
        scriptHandlers[scriptName] = handler
        return handler
    end

    if not tostring(handler):find("module '" .. TITHE_SCRIPT_MODULE_PREFIX .. scriptName .. "' not found", 1, true) then
        print(handler)
    end

    scriptHandlers[scriptName] = false
    return nil
end

function tithesrules.tryUseButton(ctx)
    local state = ctx.state
    local worldResources = ctx.worldResources or {}
    local systemDefinition = state and state.titheSystem or nil
    local button = ctx.envdraw.getSyntacRewardButtonLayout("tithes", state.playerJacl)

    if not systemDefinition or not button then
        ctx.sfxrules.playPlayReject()
        return true
    end

    if not ((ctx.getCurrentPhase and ctx.getCurrentPhase() == "Prelude") or (ctx.isEngagePhase and ctx.isEngagePhase())) then
        ctx.sfxrules.playPlayReject()
        return true
    end

    state.syntacRewardButtons = state.syntacRewardButtons or {}

    if state.syntacRewardButtons.tithes then
        ctx.sfxrules.playPlayReject()
        return true
    end

    if (tonumber(worldResources.tithes) or 0) <= 0 then
        ctx.sfxrules.playPlayReject()
        return true
    end

    local scriptHandler = getScriptHandler(systemDefinition)
    local activate = type(scriptHandler) == "table" and (scriptHandler.activate or scriptHandler.use) or scriptHandler

    if type(activate) ~= "function" then
        ctx.sfxrules.playPlayReject()
        return true
    end

    local ok = activate({
        state = state,
        system = systemDefinition,
        cardregistry = ctx.cardregistry,
        notifications = ctx.notifications,
        isCardUnavailable = ctx.isCardUnavailable,
    })

    if not ok then
        ctx.sfxrules.playPlayReject()
        return true
    end

    worldResources.tithes = math.max(0, math.floor((tonumber(worldResources.tithes) or 0) - 1))
    state.syntacRewardButtons.tithes = true
    return true
end

return tithesrules
