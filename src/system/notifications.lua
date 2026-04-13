local notifications = {}

local NOTIFICATION_FONT_PATH = "assets/fonts/Furore.otf"
local NOTIFICATION_FONT_SIZE = 24
local NOTIFICATION_DURATION = 1.2
local NOTIFICATION_FADE_DURATION = 0.45
local NOTIFICATION_PADDING_X = 26
local NOTIFICATION_PADDING_Y = 16
local NOTIFICATION_MIN_WIDTH = 300
local NOTIFICATION_TEXT_COLOR = { 1, 0.345, 0.345 }

local activeNotifications = {}
local fontCache = {}

local function getFont(path, size)
    local cacheKey = path .. ":" .. size

    if fontCache[cacheKey] ~= nil then
        return fontCache[cacheKey]
    end

    fontCache[cacheKey] = love.graphics.newFont(path, size)
    return fontCache[cacheKey]
end

function notifications.reset()
    activeNotifications = {}
end

function notifications.push(text)
    activeNotifications[#activeNotifications + 1] = {
        text = text,
        elapsed = 0,
        duration = NOTIFICATION_DURATION,
    }
end

function notifications.update(dt)
    for index = #activeNotifications, 1, -1 do
        local notification = activeNotifications[index]
        notification.elapsed = notification.elapsed + dt

        if notification.elapsed >= notification.duration then
            table.remove(activeNotifications, index)
        end
    end
end

function notifications.draw()
    local notification = activeNotifications[1]

    if not notification then
        return
    end

    local previousFont = love.graphics.getFont()
    local font = getFont(NOTIFICATION_FONT_PATH, NOTIFICATION_FONT_SIZE)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local textWidth = font:getWidth(notification.text)
    local boxWidth = math.max(NOTIFICATION_MIN_WIDTH, textWidth + (NOTIFICATION_PADDING_X * 2))
    local boxHeight = font:getHeight() + (NOTIFICATION_PADDING_Y * 2)
    local boxX = (windowWidth - boxWidth) / 2
    local boxY = (windowHeight - boxHeight) / 2
    local remaining = notification.duration - notification.elapsed
    local alpha = 1

    if remaining < NOTIFICATION_FADE_DURATION then
        alpha = math.max(0, remaining / NOTIFICATION_FADE_DURATION)
    end

    love.graphics.setColor(0.05, 0.05, 0.07, 0.92 * alpha)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 10, 10)
    love.graphics.setColor(0.95, 0.96, 0.98, 0.86 * alpha)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 10, 10)
    love.graphics.setColor(NOTIFICATION_TEXT_COLOR[1], NOTIFICATION_TEXT_COLOR[2], NOTIFICATION_TEXT_COLOR[3], alpha)
    love.graphics.setFont(font)
    love.graphics.printf(
        notification.text,
        boxX + NOTIFICATION_PADDING_X,
        boxY + ((boxHeight - font:getHeight()) / 2),
        boxWidth - (NOTIFICATION_PADDING_X * 2),
        "center"
    )

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

return notifications
