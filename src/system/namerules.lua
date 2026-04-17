local names = require("data.names")

local namerules = {}

local CARD_IMAGE_DIRECTORY = "assets/images/cards/"

local function getRandomEntry(entries)
    if type(entries) ~= "table" or #entries == 0 then
        return nil
    end

    if love and love.math and love.math.random then
        return entries[love.math.random(1, #entries)]
    end

    return entries[math.random(1, #entries)]
end

local RANDOM_NAME_FIRST_NAME_KEYS = {
    masc = "Masculine",
    fem = "Feminine",
}

local function buildPersonName(firstNameKey)
    local personNames = names.Person or {}
    local firstName = getRandomEntry(personNames[firstNameKey])
    local surname = getRandomEntry(personNames.Surname)

    if firstName and surname then
        return firstName .. " " .. surname
    end

    return firstName or surname
end

function namerules.buildRandomName(randomNameType)
    local firstNameKey = RANDOM_NAME_FIRST_NAME_KEYS[randomNameType]

    if firstNameKey then
        return buildPersonName(firstNameKey)
    end

    return nil
end

function namerules.buildRandomPortraitPath(cardDefinition)
    if not cardDefinition or not cardDefinition.rname or not cardDefinition.rclass then
        return nil
    end

    if not love or not love.filesystem or not love.filesystem.getDirectoryItems then
        return nil
    end

    local portraitDirectory = CARD_IMAGE_DIRECTORY .. "troops/" .. tostring(cardDefinition.rname)

    if not love.filesystem.getInfo(portraitDirectory) then
        return nil
    end

    local matchingPaths = {}
    local prefix = tostring(cardDefinition.rclass)

    for _, fileName in ipairs(love.filesystem.getDirectoryItems(portraitDirectory)) do
        local extension = fileName:match("%.([^%.]+)$")

        if fileName:sub(1, #prefix) == prefix
            and extension
            and extension:lower() == "png" then
            matchingPaths[#matchingPaths + 1] = portraitDirectory .. "/" .. fileName
        end
    end

    return getRandomEntry(matchingPaths)
end

function namerules.applyRandomizedName(card, cardDefinition)
    if not card or not cardDefinition then
        return card
    end

    if not card.displayName then
        card.displayName = namerules.buildRandomName(cardDefinition.rname)
    end

    if not card.portraitPath then
        card.portraitPath = namerules.buildRandomPortraitPath(cardDefinition)
    end

    return card
end

return namerules
