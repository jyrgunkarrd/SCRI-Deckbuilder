local envassets = {}

local IMAGE_DIRECTORY = "assets/images/env/"
local JACL_IMAGE_DIRECTORY = "assets/images/jacl/"
local CHAMP_IMAGE_DIRECTORY = "assets/images/champ/"
local OBJECTIVE_IMAGE_DIRECTORY = "assets/images/objectives/"
local WARZONE_IMAGE_DIRECTORY = "assets/images/warzone/"
local METHOD_IMAGE_DIRECTORY = "assets/images/method/"
local MAP_IMAGE_DIRECTORY = "assets/images/map/"

local imageCache = {}
local fontCache = {}

local function loadImage(cacheKey, imagePath, imageOptions)
    if imageCache[cacheKey] ~= nil then
        return imageCache[cacheKey]
    end

    if not love.filesystem.getInfo(imagePath) then
        imageCache[cacheKey] = false
        return nil
    end

    imageCache[cacheKey] = love.graphics.newImage(imagePath, imageOptions)

    if imageOptions and imageOptions.mipmaps then
        imageCache[cacheKey]:setFilter("linear", "linear")
    end

    return imageCache[cacheKey]
end

function envassets.getFont(path, size)
    local cacheKey = path .. ":" .. size

    if fontCache[cacheKey] ~= nil then
        return fontCache[cacheKey]
    end

    fontCache[cacheKey] = love.graphics.newFont(path, size)
    return fontCache[cacheKey]
end

function envassets.getRowImage(rowIdentifier)
    if not rowIdentifier then
        return nil
    end

    return loadImage(rowIdentifier, IMAGE_DIRECTORY .. rowIdentifier .. ".png")
end

function envassets.getJaclImage(jaclName)
    if not jaclName then
        return nil
    end

    return loadImage("jacl:" .. jaclName, JACL_IMAGE_DIRECTORY .. jaclName .. ".png", {
        mipmaps = true,
    })
end

function envassets.getChampImage(championId)
    if not championId then
        return nil
    end

    return loadImage("champ:" .. championId, CHAMP_IMAGE_DIRECTORY .. championId .. ".png", {
        mipmaps = true,
    })
end

function envassets.getObjectiveImage(objectiveId)
    if not objectiveId then
        return nil
    end

    return loadImage("objective:" .. objectiveId, OBJECTIVE_IMAGE_DIRECTORY .. objectiveId .. ".png", {
        mipmaps = true,
    })
end

function envassets.getWarzoneImage(warzoneId)
    if not warzoneId then
        return nil
    end

    return loadImage("warzone:" .. warzoneId, WARZONE_IMAGE_DIRECTORY .. warzoneId .. ".png", {
        mipmaps = true,
    })
end

function envassets.getMethodImage(resourceName)
    if not resourceName then
        return nil
    end

    return loadImage("method:" .. resourceName, METHOD_IMAGE_DIRECTORY .. resourceName .. ".png", {
        mipmaps = true,
    })
end

function envassets.getMapImage(fileName)
    if not fileName then
        return nil
    end

    return loadImage("map:" .. fileName, MAP_IMAGE_DIRECTORY .. fileName, {
        mipmaps = true,
    })
end

return envassets
