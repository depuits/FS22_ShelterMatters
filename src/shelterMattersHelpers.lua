
ShelterMattersHelpers = {
}

---------------------------------------
-- date and time calcultaion helpers --
---------------------------------------

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

-----------------------------
-- infobox display helpers --
-----------------------------

function ShelterMattersHelpers.infoBoxAddBestBefore(box, bb)
    if bb == nil then
        return
    end

    if bb.month < g_currentMission.environment.currentPeriod and bb.year <= g_currentMission.environment.currentYear then
        box:addLine(g_i18n:getText("SM_InfoBestBefore"), g_i18n:getText("SM_InfoExpired"))
    else
        local monthName = g_i18n:formatPeriod(bb.month, true)

        local inYears = bb.year - g_currentMission.environment.currentYear

        -- Adjust for the shifted calendar where 1 = March and 12 = February
        -- we will only shift the months by 1 to bring them to a 0 index base (0 = jan, 11 = dec)
        local adjustedCurrentMonth = (g_currentMission.environment.currentPeriod + 1)
        local adjustedTargetMonth = (bb.month + 1)

        -- we need to adjust the year according to which month goes over the year threshold
        inYears = inYears - math.floor(adjustedCurrentMonth / 12)
        inYears = inYears + math.floor(adjustedTargetMonth / 12)

        -- Display info
        if inYears == 1 then
            box:addLine(g_i18n:getText("SM_InfoBestBefore"), string.format(g_i18n:getText("SM_InfoBestBeforeNextYear"), monthName))
        elseif inYears > 0 then
            box:addLine(g_i18n:getText("SM_InfoBestBefore"), string.format(g_i18n:getText("SM_InfoBestBeforeInYears"), monthName, inYears))
        else
            box:addLine(g_i18n:getText("SM_InfoBestBefore"), monthName)
        end
    end
end

function ShelterMattersHelpers.infoBoxAddWetness(box, wetness)
    local wetnessDesc = "SM_InfoWetness_1"
    if wetness > 80 then
        wetnessDesc = "SM_InfoWetness_5"
    elseif wetness > 60 then
        wetnessDesc = "SM_InfoWetness_4"
    elseif wetness > 30 then
        wetnessDesc = "SM_InfoWetness_3"
    elseif wetness > 0 then
        wetnessDesc = "SM_InfoWetness_2"
    end
    box:addLine(g_i18n:getText("SM_InfoWetness"), g_i18n:getText(wetnessDesc))
end
