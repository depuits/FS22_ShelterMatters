
ShelterMattersHelpers = {
}

function ShelterMattersHelpers.isLastUpdateBefore(elapsedInMinutes, targetMonth, targetYear)
    -- Get the current in-game date
    local currentYear = g_currentMission.environment.currentYear
    local currentMonth = g_currentMission.environment.currentPeriod
    local currentDay = g_currentMission.environment.currentDay

    -- Time calculations
    local minutesPerDay = 1440 -- 24 hours * 60 minutes
    local minutesPerMonth = g_currentMission.environment.daysPerPeriod * minutesPerDay
    local minutesPerYear = 12 * minutesPerMonth

    -- Approximate last update time
    local lastUpdateMinutesInGame = g_currentMission.environment.dayTime / 60000 + g_currentMission.environment.currentMonotonicDay * minutesPerDay - elapsedInMinutes

    local lastYear = math.floor(lastUpdateMinutesInGame / minutesPerYear)
    local lastMonth = math.floor((lastUpdateMinutesInGame % minutesPerYear) / minutesPerMonth) + 1

    -- Compare to the target date
    if lastYear < targetYear then
        return true
    elseif lastYear == targetYear and lastMonth < targetMonth then
        return true
    end

    return false
end

function ShelterMattersHelpers.getElapsedMinutesSince(targetMonth, targetYear)
    -- Get the current in-game date and time
    local currentYear = g_currentMission.environment.currentYear
    local currentMonth = g_currentMission.environment.currentPeriod
    local currentDay = g_currentMission.environment.currentDay
    local currentTimeInMinutes = g_currentMission.environment.dayTime / 60000 -- Convert ms to minutes
    
    -- Time calculations
    local minutesPerDay = 1440 -- 24 hours * 60 minutes
    local minutesPerMonth = g_currentMission.environment.daysPerPeriod * minutesPerDay
    local minutesPerYear = 12 * minutesPerMonth

    -- Determine the starting point (Month +1)
    local startMonth = targetMonth + 1
    local startYear = targetYear

    -- Handle rollover if the month exceeds 12
    if startMonth > 12 then
        startMonth = 1
        startYear = startYear + 1
    end

    -- Compute the time of the given month +1 in minutes
    local startMinutes = (startYear * minutesPerYear) + ((startMonth - 1) * minutesPerMonth)

    -- Compute the current time in minutes
    local currentMinutes = (currentYear * minutesPerYear) + ((currentMonth - 1) * minutesPerMonth) +
                           ((currentDay - 1) * minutesPerDay) + currentTimeInMinutes

    -- Return elapsed time
    return currentMinutes - startMinutes
end
