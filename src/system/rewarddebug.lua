local rewarddebug = {}

local LOG_FILE = "reward-debug.log"

local function formatValue(value, depth)
    depth = depth or 0

    if type(value) == "table" then
        if depth >= 2 then
            return "{...}"
        end

        local parts = {}

        for key, item in pairs(value) do
            parts[#parts + 1] = tostring(key) .. "=" .. formatValue(item, depth + 1)
        end

        table.sort(parts)
        return "{" .. table.concat(parts, ", ") .. "}"
    elseif type(value) == "string" then
        return string.format("%q", value)
    end

    return tostring(value)
end

local function getTimestamp()
    if love and love.timer and love.timer.getTime then
        return string.format("%.3f", love.timer.getTime())
    end

    return "0.000"
end

function rewarddebug.log(eventName, fields)
    local line = "[reward-debug] " .. getTimestamp() .. " " .. tostring(eventName)

    if fields then
        line = line .. " " .. formatValue(fields)
    end

    print(line)

    if love and love.filesystem and love.filesystem.append then
        pcall(love.filesystem.append, LOG_FILE, line .. "\n")
    end
end

function rewarddebug.clear()
    if love and love.filesystem and love.filesystem.write then
        pcall(love.filesystem.write, LOG_FILE, "")
    end
end

function rewarddebug.getLogFileName()
    return LOG_FILE
end

return rewarddebug
