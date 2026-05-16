local envrules = require("src.system.envrules")
local envassets = require("src.render.envassets")

local envgrid = {}

local GRID_COLUMNS = 9
local CELL_WIDTH = 180
local CELL_HEIGHT = 180
local CELL_GAP = 20
local SETUP_MODAL_MARGIN = 24
local SETUP_MODAL_PADDING = 18
local SETUP_MODAL_SLOT_GAP = 20
local SETUP_MODAL_MAX_HEIGHT_RATIO = 0.48

function envgrid.getGridLayout()
    local rows = envrules.getRows()
    local gridRows = #rows
    local totalWidth = (GRID_COLUMNS * CELL_WIDTH) + ((GRID_COLUMNS - 1) * CELL_GAP)
    local totalHeight = (gridRows * CELL_HEIGHT) + ((gridRows - 1) * CELL_GAP)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local startX = (windowWidth - totalWidth) / 2
    local startY = (windowHeight - totalHeight) / 2
    local layout = {
        rows = {},
    }

    for row = 0, gridRows - 1 do
        local rowDefinition = rows[row + 1]
        local rowY = startY + (row * (CELL_HEIGHT + CELL_GAP))
        local cells = {}

        for column = 0, GRID_COLUMNS - 1 do
            local x = startX + (column * (CELL_WIDTH + CELL_GAP))
            cells[column + 1] = {
                column = column + 1,
                x = x,
                y = rowY,
                width = CELL_WIDTH,
                height = CELL_HEIGHT,
            }
        end

        layout.rows[row + 1] = {
            id = rowDefinition.id,
            y = rowY,
            cells = cells,
        }
    end

    return layout
end

function envgrid.getGridRow(rowId)
    local gridLayout = envgrid.getGridLayout()

    for _, row in ipairs(gridLayout.rows) do
        if row.id == rowId then
            return row
        end
    end

    return nil
end

function envgrid.getSetupModalLayout(agentCount)
    if not agentCount or agentCount <= 0 then
        return nil
    end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    local playerRow = envgrid.getGridRow("PlayerRow")
    local cardsWidth = (agentCount * CELL_WIDTH) + ((agentCount - 1) * SETUP_MODAL_SLOT_GAP)
    local modalWidth = cardsWidth + (SETUP_MODAL_PADDING * 2)
    local modalHeight = CELL_HEIGHT + (SETUP_MODAL_PADDING * 2)
    local maxBottom = math.min(
        windowHeight * SETUP_MODAL_MAX_HEIGHT_RATIO,
        playerRow and (playerRow.y - SETUP_MODAL_MARGIN) or (windowHeight * SETUP_MODAL_MAX_HEIGHT_RATIO)
    )
    local modalX = (windowWidth - modalWidth) / 2
    local modalY = math.max(SETUP_MODAL_MARGIN, maxBottom - modalHeight)
    local slots = {}

    for slotIndex = 1, agentCount do
        slots[slotIndex] = {
            x = modalX + SETUP_MODAL_PADDING + ((slotIndex - 1) * (CELL_WIDTH + SETUP_MODAL_SLOT_GAP)),
            y = modalY + SETUP_MODAL_PADDING,
            width = CELL_WIDTH,
            height = CELL_HEIGHT,
        }
    end

    return {
        x = modalX,
        y = modalY,
        width = modalWidth,
        height = modalHeight,
        slots = slots,
    }
end

function envgrid.drawGrid(currentPhase)
    local gridLayout = envgrid.getGridLayout()

    love.graphics.setColor(0.75, 0.78, 0.82, 1)

    for _, row in ipairs(gridLayout.rows) do
        if currentPhase ~= "Setup" or row.id ~= "OppRow" then
            local rowImage = envassets.getRowImage(row.id)

            for _, cell in ipairs(row.cells) do
                local x = cell.x
                local y = cell.y

                if rowImage then
                    local imageWidth = rowImage:getWidth()
                    local imageHeight = rowImage:getHeight()
                    local scaleX = CELL_WIDTH / imageWidth
                    local scaleY = CELL_HEIGHT / imageHeight
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(rowImage, x, y, 0, scaleX, scaleY)
                    love.graphics.setColor(0.75, 0.78, 0.82, 1)
                end

                love.graphics.rectangle("line", x, y, CELL_WIDTH, CELL_HEIGHT)
            end
        end
    end

    love.graphics.setColor(1, 1, 1)
end

function envgrid.drawSetupModal(agentCount)
    local layout = envgrid.getSetupModalLayout(agentCount)

    if not layout then
        return
    end

    love.graphics.setColor(0.06, 0.07, 0.09, 0.94)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.width, layout.height, 10, 10)
    love.graphics.setColor(0.82, 0.85, 0.89, 0.78)
    love.graphics.rectangle("line", layout.x, layout.y, layout.width, layout.height, 10, 10)
    love.graphics.setColor(1, 1, 1, 1)
end

return envgrid
