local crewrules = require("src.system.crewrules")

local cardzones = {}

local function isDestroyed(card, isCardDestroyed)
    if isCardDestroyed then
        return isCardDestroyed(card)
    end

    return card and card.destroyed == true or false
end

function cardzones.isSetupCard(card)
    return card and card.location and card.location.kind == "setup" or false
end

function cardzones.isGridCard(card)
    return card and card.location and card.location.kind == "grid" or false
end

function cardzones.canExpandCard(card)
    return cardzones.isGridCard(card) or cardzones.isSetupCard(card)
end

function cardzones.getSetupCardCount(cards, isCardDestroyed)
    local count = 0

    for _, card in ipairs(cards or {}) do
        if cardzones.isSetupCard(card) and not isDestroyed(card, isCardDestroyed) then
            count = count + 1
        end
    end

    return count
end

function cardzones.normalizeSetupCardSlots(cards, isCardDestroyed)
    local slotIndex = 1

    for _, card in ipairs(cards or {}) do
        if cardzones.isSetupCard(card) and not isDestroyed(card, isCardDestroyed) then
            card.location.slotIndex = slotIndex
            slotIndex = slotIndex + 1
        end
    end
end

function cardzones.normalizeHandCardSlots(cards, isCardDestroyed)
    local slotIndex = 1

    for _, card in ipairs(cards or {}) do
        if card and card.location and card.location.kind == "hand" and not isDestroyed(card, isCardDestroyed) then
            card.location.slotIndex = slotIndex
            slotIndex = slotIndex + 1
        end
    end
end

function cardzones.getNextOpenHandSlot(cards, handSlotCount, isCardDestroyed)
    cardzones.normalizeHandCardSlots(cards, isCardDestroyed)

    local nextSlotIndex = 1

    for _, card in ipairs(cards or {}) do
        if card and card.location and card.location.kind == "hand" and not isDestroyed(card, isCardDestroyed) then
            nextSlotIndex = math.max(nextSlotIndex, (card.location.slotIndex or 0) + 1)
        end
    end

    if nextSlotIndex > handSlotCount then
        return nil
    end

    return nextSlotIndex
end

function cardzones.isGridRowColumnOccupied(cards, rowId, column, ignoredCardIndex)
    for cardIndex, card in ipairs(cards or {}) do
        if cardIndex ~= ignoredCardIndex
            and card
            and card.location
            and card.location.kind == "grid"
            and not card.destroyed
            and card.location.rowId == rowId
            and card.location.column == column then
            return true
        end
    end

    return false
end

function cardzones.getCellAt(row, mouseX, mouseY)
    if not row then
        return nil
    end

    for _, cell in ipairs(row.cells or {}) do
        if mouseX >= cell.x
            and mouseX <= cell.x + cell.width
            and mouseY >= cell.y
            and mouseY <= cell.y + cell.height then
            return cell
        end
    end

    return nil
end

function cardzones.getDropColumn(mouseX, mouseY, draggedCard, context)
    local targetRow = context.isHunterCard(draggedCard) and context.getOppRow() or context.getPlayerRow()
    local cell = cardzones.getCellAt(targetRow, mouseX, mouseY)

    return cell and cell.column or nil
end

function cardzones.getValidDropColumn(mouseX, mouseY, cards, ignoredCardIndex, draggedCard, context)
    local dropColumn = cardzones.getDropColumn(mouseX, mouseY, draggedCard, context)

    if not dropColumn then
        return nil
    end

    local targetRowId = context.isHunterCard(draggedCard) and "OppRow" or "PlayerRow"

    if cardzones.isGridRowColumnOccupied(cards, targetRowId, dropColumn, ignoredCardIndex)
        and not crewrules.canCardCoverCrew(cards, targetRowId, dropColumn, ignoredCardIndex, draggedCard) then
        return nil
    end

    return dropColumn
end

function cardzones.getDropCell(mouseX, mouseY, cards, draggedCardIndex, context)
    local draggedCard = draggedCardIndex and cards[draggedCardIndex] or nil
    local targetRow = context.isHunterCard(draggedCard) and context.getOppRow() or context.getPlayerRow()
    local dropColumn = cardzones.getValidDropColumn(mouseX, mouseY, cards, draggedCardIndex, draggedCard, context)

    if not targetRow or not dropColumn then
        return nil
    end

    return targetRow.cells[dropColumn]
end

function cardzones.getValidJaclSpecialTargetCell(mouseX, mouseY, cards, context)
    local targetCell = cardzones.getCellAt(context.getPlayerRow(), mouseX, mouseY)

    if not targetCell or cardzones.isGridRowColumnOccupied(cards, "PlayerRow", targetCell.column) then
        return nil
    end

    return targetCell
end

return cardzones
