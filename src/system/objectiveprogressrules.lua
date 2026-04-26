local objectiveprogressrules = {}

function objectiveprogressrules.addProgress(objectiveDefinition, amount, context)
    local result = {
        appliedChange = 0,
        progressEffect = nil,
        shouldDestroyIntel = false,
        escalationId = nil,
    }

    if not objectiveDefinition or amount == nil then
        return result
    end

    context = context or {}

    local currentPlan = tonumber(objectiveDefinition.plan) or 0
    local maxPlan = tonumber(objectiveDefinition.max)
    local nextPlan = currentPlan + (tonumber(amount) or 0)

    if maxPlan ~= nil then
        nextPlan = math.min(maxPlan, nextPlan)
    end

    objectiveDefinition.plan = math.max(0, nextPlan)
    result.appliedChange = objectiveDefinition.plan - currentPlan

    if result.appliedChange > 0 then
        result.progressEffect = {
            overlayName = "progress",
            slotId = context.slotId or "objective",
        }
    elseif result.appliedChange < 0 then
        result.progressEffect = {
            overlayName = "sabotage",
            slotId = context.slotId or "objective",
        }
    end

    if objectiveDefinition.type == "intel"
        and (tonumber(objectiveDefinition.plan) or 0) <= 0 then
        result.shouldDestroyIntel = true
    end

    if objectiveDefinition == context.activePrimaryObjective
        and result.appliedChange > 0 then
        local escalationId = objectiveDefinition.escalation or objectiveDefinition.escalate

        if maxPlan ~= nil
            and (tonumber(objectiveDefinition.plan) or 0) >= maxPlan
            and escalationId
            and not context.objectiveEscalationActive then
            result.escalationId = escalationId
        end
    end

    return result
end

function objectiveprogressrules.canApplyProgress(objectiveDefinition, amount)
    if not objectiveDefinition or amount == nil then
        return false
    end

    local currentPlan = tonumber(objectiveDefinition.plan) or 0
    local maxPlan = tonumber(objectiveDefinition.max)
    local nextPlan = currentPlan + (tonumber(amount) or 0)

    if maxPlan ~= nil then
        nextPlan = math.min(maxPlan, nextPlan)
    end

    nextPlan = math.max(0, nextPlan)
    return nextPlan ~= currentPlan
end

return objectiveprogressrules
