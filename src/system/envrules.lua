local envrules = {}

envrules.rows = {
    { id = "OppRow" },
    { id = "PlayerRow" },
}

envrules.playerHand = {
    id = "PlayerHand",
    slots = 10,
    anchor = "bottom_right",
}

function envrules.getRows()
    return envrules.rows
end

function envrules.getPlayerHand()
    return envrules.playerHand
end

return envrules
