local cardregistry = require("src.system.cardregistry")

local cardrewardpools = {}

local DEFAULT_POOL_ID = "universal"

local CARD_REWARD_RARITY_PROFILES = {
    regular = {
        { rarity = "common", weight = 75 },
        { rarity = "uncommon", weight = 25 },
    },
}

local function normalizePoolId(poolId)
    if type(poolId) == "string" and poolId ~= "" then
        return poolId
    end

    return DEFAULT_POOL_ID
end

local function normalizeLookupKey(value)
    if type(value) == "string" then
        return value:lower()
    end

    return nil
end

local function normalizeRarity(value)
    return normalizeLookupKey(value)
end

local function addLookupValue(lookup, value)
    if type(value) == "string" and value ~= "" then
        lookup[value] = true
        lookup[value:lower()] = true
    end
end

local function addMethodEntries(methodLookup, methodEntries)
    for _, methodEntry in ipairs(methodEntries or {}) do
        if type(methodEntry) == "string" then
            addLookupValue(methodLookup, methodEntry)
        elseif type(methodEntry) == "table" then
            addLookupValue(methodLookup, methodEntry.resource)
            addLookupValue(methodLookup, methodEntry.method)
            addLookupValue(methodLookup, methodEntry.id)
            addLookupValue(methodLookup, methodEntry.name)
        end
    end
end

local function addCharacterContext(context, characterDefinition)
    if type(characterDefinition) ~= "table" then
        return
    end

    addLookupValue(context.activeIds, characterDefinition.id)
    addMethodEntries(context.activeMethods, characterDefinition.method or characterDefinition.methods)
end

local function addPoolEntry(entries, value)
    if type(value) == "string" and value ~= "" then
        entries[#entries + 1] = value
    elseif type(value) == "table" then
        addPoolEntry(entries, value.id)
        addPoolEntry(entries, value.poolId)
        addPoolEntry(entries, value.resource)
        addPoolEntry(entries, value.method)
        addPoolEntry(entries, value.name)
    end
end

local function addPoolEntries(entries, values)
    if type(values) == "string" then
        addPoolEntry(entries, values)
        return
    end

    for _, value in ipairs(values or {}) do
        addPoolEntry(entries, value)
    end
end

local function addLookupValues(lookup, values)
    if type(values) == "string" then
        addLookupValue(lookup, values)
        return
    end

    for _, value in ipairs(values or {}) do
        addLookupValue(lookup, value)
    end
end

local function getCardPoolEntries(cardDefinition)
    local entries = {}

    if type(cardDefinition) ~= "table" then
        return entries
    end

    addPoolEntry(entries, cardDefinition.poolId)
    addPoolEntries(entries, cardDefinition.poolIds)
    addPoolEntries(entries, cardDefinition.pools)
    addPoolEntries(entries, cardDefinition.tags)

    return entries
end

local function buildRewardContext(state)
    local context = {
        activeIds = {},
        activeMethods = {},
    }

    if type(state) ~= "table" then
        return context
    end

    addLookupValue(context.activeIds, state.selectedRunJaclId)
    addLookupValues(context.activeIds, state.selectedRunAgentIds)

    if state.selectedRunPackage then
        addCharacterContext(context, state.selectedRunPackage.jacl)

        for _, agentDefinition in ipairs(state.selectedRunPackage.agents or {}) do
            addCharacterContext(context, agentDefinition)
        end
    end

    addCharacterContext(context, state.playerJacl)

    for _, card in ipairs(state.playerCards or {}) do
        addCharacterContext(context, card)
    end

    return context
end

local function matchesPool(cardDefinition, poolId, context)
    if not cardDefinition then
        return false
    end

    local basePoolId = normalizePoolId(poolId)
    local basePoolKey = normalizeLookupKey(basePoolId)
    local entries = getCardPoolEntries(cardDefinition)

    for _, entry in ipairs(entries) do
        local entryKey = normalizeLookupKey(entry)

        if entry == basePoolId or entryKey == basePoolKey or entryKey == DEFAULT_POOL_ID then
            return true
        end

        if context.activeIds[entry] or context.activeIds[entryKey] then
            return true
        end

        if context.activeMethods[entry] or context.activeMethods[entryKey] then
            return true
        end
    end

    return false
end

local function getRarityProfile(cardrw)
    local profileId = normalizeLookupKey(cardrw)

    if not profileId then
        return nil
    end

    return CARD_REWARD_RARITY_PROFILES[profileId]
end

local function addCardToRarityBucket(buckets, cardDefinition)
    local rarity = normalizeRarity(cardDefinition and cardDefinition.rarity)

    if not rarity then
        return
    end

    buckets[rarity] = buckets[rarity] or {}
    buckets[rarity][#buckets[rarity] + 1] = cardDefinition
end

local function buildRarityBuckets(pool)
    local buckets = {}

    for _, cardDefinition in ipairs(pool or {}) do
        addCardToRarityBucket(buckets, cardDefinition)
    end

    return buckets
end

local function chooseWeightedRarity(profile, buckets)
    local totalWeight = 0
    local availableEntries = {}

    for _, entry in ipairs(profile or {}) do
        local rarity = normalizeRarity(entry and entry.rarity)
        local weight = math.max(0, tonumber(entry and entry.weight) or 0)
        local bucket = rarity and buckets[rarity] or nil

        if rarity and weight > 0 and bucket and #bucket > 0 then
            totalWeight = totalWeight + weight
            availableEntries[#availableEntries + 1] = {
                rarity = rarity,
                cumulativeWeight = totalWeight,
            }
        end
    end

    if totalWeight <= 0 then
        return nil
    end

    local roll = love.math.random() * totalWeight

    for _, entry in ipairs(availableEntries) do
        if roll <= entry.cumulativeWeight then
            return entry.rarity
        end
    end

    return availableEntries[#availableEntries].rarity
end

local function chooseRandomCardFromPool(pool)
    if not pool or #pool <= 0 then
        return nil
    end

    return pool[love.math.random(1, #pool)]
end

local function chooseRandomCardForReward(pool, cardrw)
    local profile = getRarityProfile(cardrw)

    if profile then
        local buckets = buildRarityBuckets(pool)
        local rarity = chooseWeightedRarity(profile, buckets)
        local bucket = rarity and buckets[rarity] or nil

        if bucket and #bucket > 0 then
            return chooseRandomCardFromPool(bucket)
        end
    end

    return chooseRandomCardFromPool(pool)
end

function cardrewardpools.getPool(poolId, state)
    local pool = {}
    local context = buildRewardContext(state)

    for _, cardDefinition in ipairs(cardregistry.getAllCards()) do
        if matchesPool(cardDefinition, poolId, context) then
            pool[#pool + 1] = cardDefinition
        end
    end

    return pool
end

function cardrewardpools.roll(poolId, count, state, options)
    local pool = cardrewardpools.getPool(poolId, state)
    local choices = {}
    local cardrw = options and options.cardrw or nil

    if #pool <= 0 then
        return choices
    end

    for _ = 1, count or 1 do
        local cardDefinition = chooseRandomCardForReward(pool, cardrw)

        if cardDefinition then
            choices[#choices + 1] = {
                setName = cardDefinition.setName,
                cardId = cardDefinition.id,
                definition = cardDefinition,
            }
        end
    end

    return choices
end

return cardrewardpools
