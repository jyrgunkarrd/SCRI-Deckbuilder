local warrules = require("src.system.warrules")
local warzonerules = require("src.system.warzonerules")

local warzonecontrolrules = {}

local spawnedLinkedPoisByWarzoneId = {}

local function getWarzoneFamilyId(warzoneDefinition)
    if not warzoneDefinition or not warzoneDefinition.id then
        return nil
    end

    if warzoneDefinition.id:sub(-1) == "B" then
        return warzoneDefinition.id:sub(1, -2)
    end

    return warzoneDefinition.id
end

local function preloadTopStripAsset(preloadTopStripAssets, slotId, definition)
    if not preloadTopStripAssets or not definition then
        return
    end

    if slotId == "warzone" then
        preloadTopStripAssets(nil, definition, nil, nil, nil)
    elseif slotId == "poi" then
        preloadTopStripAssets(nil, nil, definition, nil, nil)
    end
end

function warzonecontrolrules.reset()
    spawnedLinkedPoisByWarzoneId = {}
end

function warzonecontrolrules.getWarzoneFamilyId(warzoneDefinition)
    return getWarzoneFamilyId(warzoneDefinition)
end

function warzonecontrolrules.preloadLinkedPoiForWarzone(warzoneDefinition, preloadTopStripAssets)
    if not warzoneDefinition then
        return
    end

    local poiId = warzoneDefinition.poi

    if not poiId then
        local variantWarzone = warzonerules.getControlVariant(warzoneDefinition)
        poiId = variantWarzone and variantWarzone.poi or nil
    end

    if not poiId then
        return
    end

    preloadTopStripAsset(preloadTopStripAssets, "poi", warzonerules.getWarzone(poiId))
end

function warzonecontrolrules.preloadWarzoneFamily(warzoneDefinition, preloadTopStripAssets)
    if not warzoneDefinition then
        return
    end

    preloadTopStripAsset(preloadTopStripAssets, "warzone", warzoneDefinition)

    local variantWarzone = warzonerules.getControlVariant(warzoneDefinition)

    if variantWarzone then
        preloadTopStripAsset(preloadTopStripAssets, "warzone", variantWarzone)
    end

    warzonecontrolrules.preloadLinkedPoiForWarzone(warzoneDefinition, preloadTopStripAssets)
end

function warzonecontrolrules.addControl(warzoneDefinition, amount, context)
    if not warzoneDefinition or amount == nil then
        return 0
    end

    context = context or {}

    local currentControl = tonumber(warzoneDefinition.control) or 0
    local controlCap = tonumber(warzoneDefinition.max)
    local nextControl = currentControl + (tonumber(amount) or 0)

    if controlCap ~= nil then
        nextControl = math.max(-controlCap, math.min(controlCap, nextControl))
    end

    warzoneDefinition.control = nextControl
    local appliedChange = nextControl - currentControl

    if appliedChange ~= 0 and context.onControlChanged then
        context.onControlChanged(context.slotId or "warzone")
    end

    if warzoneDefinition == context.activePoi
        and not context.poiHunterTransformationActive
        and warzoneDefinition.allyID
        and controlCap ~= nil
        and nextControl >= controlCap
        and context.beginPoiGeneratedCardTransformation then
        context.beginPoiGeneratedCardTransformation(warzoneDefinition, warzoneDefinition.allyID)
    end

    if warzoneDefinition ~= context.activeWarzone then
        return appliedChange
    end

    local shouldUsePositiveVariant = nextControl > 0
    local currentIsNegativeVariant = warzoneDefinition.id and warzoneDefinition.id:sub(-1) == "B"
    local shouldSwap = (currentIsNegativeVariant and shouldUsePositiveVariant)
        or ((not currentIsNegativeVariant) and nextControl <= 0)

    if not shouldSwap then
        return appliedChange
    end

    local variantWarzone = warzonerules.getControlVariant(warzoneDefinition)

    if not variantWarzone then
        return appliedChange
    end

    variantWarzone.control = nextControl

    if context.beginWarzoneTransformation then
        context.beginWarzoneTransformation(warzoneDefinition, variantWarzone)
    end

    local activePoi = context.activePoi

    if not currentIsNegativeVariant
        and activePoi
        and activePoi.id
        and activePoi.id:sub(-1) ~= "B" then
        local poiVariant = warzonerules.getPairedVariant(activePoi)

        if poiVariant then
            poiVariant.control = activePoi.control

            if context.beginPoiFlipEffect then
                context.beginPoiFlipEffect(activePoi, poiVariant)
            end

            activePoi = poiVariant

            if context.setActivePoi then
                context.setActivePoi(activePoi)
            end

            preloadTopStripAsset(context.preloadTopStripAssets, "poi", activePoi)
        end
    end

    if context.setActiveWarzone then
        context.setActiveWarzone(variantWarzone)
    end

    warrules.setWarzoneTargetPreview(variantWarzone)

    if currentIsNegativeVariant then
        warrules.rerollEntity("warzone", variantWarzone, true)
    end

    warzonecontrolrules.preloadWarzoneFamily(variantWarzone, context.preloadTopStripAssets)

    local warzoneFamilyId = getWarzoneFamilyId(variantWarzone)

    if currentIsNegativeVariant
        and variantWarzone.poi
        and warzoneFamilyId
        and not spawnedLinkedPoisByWarzoneId[warzoneFamilyId] then
        activePoi = warzonerules.getWarzone(variantWarzone.poi)

        if activePoi then
            spawnedLinkedPoisByWarzoneId[warzoneFamilyId] = true

            if context.setActivePoi then
                context.setActivePoi(activePoi)
            end

            preloadTopStripAsset(context.preloadTopStripAssets, "poi", activePoi)

            if context.beginPoiEmergenceEffect then
                context.beginPoiEmergenceEffect()
            end
        end
    end

    return appliedChange
end

return warzonecontrolrules
