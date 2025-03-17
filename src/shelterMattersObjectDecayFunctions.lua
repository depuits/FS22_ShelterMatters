
ShelterMattersObjectDecayFunctions = {
}

-- update object which can decay to the currentTime and with which rate wetness is applied
function ShelterMattersObjectDecayFunctions.update(object)
    if not g_currentMission:getIsServer() then
        return -- Skip on clients
    end

    local currentDay = g_currentMission.environment.currentMonotonicDay
    local currentTime = g_currentMission.environment.dayTime

    local lastUpdate = object:getLastDecayUpdate()

    -- Initialize the lastUpdateInGameTime if this is the first run
    if lastUpdate == nil or lastUpdate.day == nil or lastUpdate.time == nil then
        object:setLastDecayUpdate({ day = currentDay, time = currentTime })
        return -- No update needed on the first run
    end

    -- Calculate the elapsed in-game minutes
    local elapsedTime = (currentDay - lastUpdate.day) * (24 * 60 * 60 * 1000) + (currentTime - lastUpdate.time)
    local elapsedInMinutes = elapsedTime / (60 * 1000) -- Convert from ms to minutes

    -- only execute the update logic once every ingame minute
    if elapsedInMinutes > 1 then
        return
    end

    -- check if spawn protection is applied
    local spawnTime = object:getSpawnTime()
    if spawnTime ~= nil then
        -- calculate diference in time
        local elapsedSinceSpawn = (currentDay - spawnTime.day) * (24 * 60 * 60 * 1000) + (currentTime - spawnTime.time)
        local elapsedSinceSpawnInHours = elapsedTime / (60 * 60 * 1000) -- Convert from ms to hours

        -- if the spwan proection is within the timeframe don't execute the rest of the function
        if elapsedSinceSpawnInHours < ShelterMatters.palletSpawnProtection then
            return
        end
    end

    -- Store the last update time
    object:setLastDecayUpdate({ day = currentDay, time = currentTime })

    local decayProps = object:getDecayProperties()

    if object:isAffectedByWetness() then -- we will not check wetness if the is no decay for it
        local wetnessRate = ShelterMatters:getWeatherWetnessRate()
        -- update wetness
        if
            wetnessRate > 0 and -- only if there is a wetnessRate
            object:getWetness() < 1 -- object is not yet soaked
        then
            local inShed = ShelterMatters.isObjectInShed(object)
            if not inShed then
                object:setWetness(object:getWetness() + (wetnessRate * decayProps.wetnessImpact * elapsedInMinutes))
            end
        end

        -- update decay by wetness
        if object:getWetness() > 0 then -- only if the bale is wet then it will decay
            local decayPerMinute = decayProps.wetnessDecay / 60 /  24 / g_currentMission.environment.daysPerPeriod
            local wetnessDamage = (decayPerMinute * elapsedInMinutes) * object:getWetness()
            object:addDecayAmount(wetnessDamage)
        end
    end

    -- update bestBefore
    local bb = object:getBestBefore()
    if bb and bb.month < g_currentMission.environment.currentPeriod and bb.year <= g_currentMission.environment.currentYear then
        local elapsedDecayInMinutes = elapsedInMinutes -- decay from lastupdate
        -- unless the last update is from before the best before date
        if ShelterMattersHelpers.isLastUpdateBefore(elapsedInMinutes, bb.month, bb.year) then
            -- if it is from before then only decay from the bestbefore date
            elapsedDecayInMinutes = ShelterMattersHelpers.getElapsedMinutesSince(bb.month, bb.year)
        end
 
        -- calculate decay scaled to the minute timeframe given the decay in liters/month
        -- => value / minutes / hours / days
        local decayScaled = decayProps.bestBeforeDecay / 60 /  24 / g_currentMission.environment.daysPerPeriod
        local decayDamage = elapsedDecayInMinutes * decayScaled
        object:addDecayAmount(decayDamage)
    end
end

function ShelterMattersObjectDecayFunctions.infoBoxAddInfo(box, object)
    -- display best by date
    local bb = object:getBestBefore()
    ShelterMattersHelpers.infoBoxAddBestBefore(box, bb)

    -- display wetness in info box
    if ShelterMattersObjectDecayFunctions.shouldDisplayWetness(object) then
        ShelterMattersHelpers.infoBoxAddWetness(box, object:getWetness())
    end

    -- display decay in info box
    local decayPercentage = 0
    local fillLevelFull = object:getFillLevelFull()
    if fillLevelFull > 0 then 
        decayPercentage = object:getDecayAmount() / fillLevelFull
    end

    if decayPercentage > 0 then
        box:addLine(g_i18n:getText("SM_InfoDecay"), string.format("%d%%", decayPercentage * 100))
    end
end

function ShelterMattersObjectDecayFunctions.shouldDisplayWetness(object)
    -- only things with a decay rate are affected by wetness
    local decayProps = object:getDecayProperties()

    return decayProps and -- should have decay properties defined
        decayProps.wetnessImpact and decayProps.wetnessImpact > 0 and -- and the wetnessImpact must be greater then 0
        decayProps.wetnessDecay and decayProps.wetnessDecay > 0 -- and there must also be a decay from the wetness
end

-----------------------------------
-- init, load and save functions --
-----------------------------------

function ShelterMattersObjectDecayFunctions.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. ".lastUpdate#day", "Last update day of current item")
    schema:register(XMLValueType.FLOAT, basePath .. ".lastUpdate#time", "Last update time of current item")

    schema:register(XMLValueType.INT, basePath .. ".spawnTime#day", "Day when the item has spawned")
    schema:register(XMLValueType.FLOAT, basePath .. ".spawnTime#time", "Time when the item has spawned")

    schema:register(XMLValueType.INT, basePath .. ".bestBefore#month", "Best before month of current item")
    schema:register(XMLValueType.INT, basePath .. ".bestBefore#year", "Best before year of current item")

    schema:register(XMLValueType.FLOAT, basePath .. "#wetness", "Wetness level of current item")
    schema:register(XMLValueType.FLOAT, basePath .. "#fillLevelFull", "Current item fill level when it was created")
    schema:register(XMLValueType.FLOAT, basePath .. "#decayAmount", "Amount lost to decay of current item")
end

function ShelterMattersObjectDecayFunctions.initObject(self, spec)
    spec.lastUpdate = {} -- initialize the lastUpdate as empty object to prevent errors when saving thing that have never been updated yet

    spec.wetness = 0
    spec.wetnessDirtyFlag = self:getNextDirtyFlag()

    spec.decayAmount = 0
    spec.decayAmountDirtyFlag = self:getNextDirtyFlag()

    spec.fillLevelFull = 0
    spec.fillLevelFullDirtyFlag = self:getNextDirtyFlag()

    spec.bestBeforeDirtyFlag = self:getNextDirtyFlag()

    -- following are set dynamicly if not yet defined
    -- spec.spawnTime, spec.bestBefore
end

function ShelterMattersObjectDecayFunctions.loadFromXMLFile(xmlFile, key, spec)

    spec.lastUpdate = { day = xmlFile:getValue(key .. ".lastUpdate#day"), time = xmlFile:getValue(key .. ".lastUpdate#time") }

    spec.spawnTime = { day = xmlFile:getValue(key .. ".spawnTime#day"), time = xmlFile:getValue(key .. ".spawnTime#time") }

    spec.bestBefore = { month = xmlFile:getValue(key .. ".bestBefore#month"), year = xmlFile:getValue(key .. ".bestBefore#year") }

    spec.wetness = xmlFile:getValue(key .. "#wetness", 0)
    spec.decayAmount = xmlFile:getValue(key .. "#decayAmount", 0)
    spec.fillLevelFull = xmlFile:getValue(key .. "#fillLevelFull", 0)

    -- reset the spawnTime and bestBefore if not all properties or correctly set
    -- this to prevent errors and saving nil values in the feature
    if spec.spawnTime.day == nil or spec.spawnTime.time == nil then
        spec.spawnTime = nil
    end

    if spec.bestBefore.month == nil or spec.bestBefore.year == nil then
        spec.bestBefore = nil -- reset the bestbefore if one of the 2 properties or not correctly set
    end
end

function ShelterMattersObjectDecayFunctions.saveToXMLFile(xmlFile, key, spec)
    xmlFile:setValue(key .. ".lastUpdate#day", spec.lastUpdate.day)
    xmlFile:setValue(key .. ".lastUpdate#time", spec.lastUpdate.time)

    if spec.spawnTime then
        xmlFile:setValue(key .. ".spawnTime#day", spec.spawnTime.day)
        xmlFile:setValue(key .. ".spawnTime#time", spec.spawnTime.time)
    end

    if spec.bestBefore then
        xmlFile:setValue(key .. ".bestBefore#month", spec.bestBefore.month)
        xmlFile:setValue(key .. ".bestBefore#year", spec.bestBefore.year)
    end

    xmlFile:setValue(key .. "#wetness", spec.wetness)
    xmlFile:setValue(key .. "#decayAmount", spec.decayAmount)
    xmlFile:setValue(key .. "#fillLevelFull", spec.fillLevelFull)
end

--------------------------------
-- multiplayer sync functions --
--------------------------------

-- lastUpdate and spawnTime are not synced because those values are only used on the server

function ShelterMattersObjectDecayFunctions.readStream(streamId, connection, spec)
    spec.wetness = streamReadFloat32(streamId)
    spec.fillLevelFull = streamReadFloat32(streamId)
    spec.decayAmount = streamReadFloat32(streamId)

    if streamReadBool(streamId) then
        local month = streamReadInt32(streamId)
        local year = streamReadInt32(streamId)

        spec.bestBefore = { month = month, year = year }
    else
        spec.bestBefore = nil
    end
end
function ShelterMattersObjectDecayFunctions.writeStream(streamId, connection, spec)
    streamWriteFloat32(streamId, spec.wetness)
    streamWriteFloat32(streamId, spec.fillLevelFull)
    streamWriteFloat32(streamId, spec.decayAmount)

    if streamWriteBool(streamId, spec.bestBefore ~= nil) then
        streamWriteInt32(streamId, spec.bestBefore.month)
        streamWriteInt32(streamId, spec.bestBefore.year)
    end
end

function ShelterMattersObjectDecayFunctions.readUpdateStream(streamId, timestamp, connection, spec)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            spec.wetness = streamReadFloat32(streamId)
        end

        if streamReadBool(streamId) then
            spec.fillLevelFull = streamReadFloat32(streamId)
        end

        if streamReadBool(streamId) then
            spec.decayAmount = streamReadFloat32(streamId)
        end

        if streamReadBool(streamId) then
            if streamReadBool(streamId) then
                local month = streamReadInt32(streamId)
                local year = streamReadInt32(streamId)

                self.bestBefore = { month = month, year = year }
            else
                self.bestBefore = nil
            end
        end
    end
end
function ShelterMattersObjectDecayFunctions.writeUpdateStream(streamId, connection, dirtyMask, spec)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.wetnessDirtyFlag) ~= 0) then
            streamWriteFloat32(streamId, spec.wetness)
        end

        if streamWriteBool(streamId, bitAND(dirtyMask, spec.fillLevelFullDirtyFlag) ~= 0) then
            streamWriteFloat32(streamId, spec.fillLevelFull)
        end

        if streamWriteBool(streamId, bitAND(dirtyMask, spec.decayAmountDirtyFlag) ~= 0) then
            streamWriteFloat32(streamId, spec.decayAmount)
        end

        if streamWriteBool(streamId, bitAND(dirtyMask, spec.bestBeforeDirtyFlag) ~= 0) then
            if streamWriteBool(streamId, spec.bestBefore ~= nil) then
                streamWriteInt32(streamId, spec.bestBefore.month)
                streamWriteInt32(streamId, spec.bestBefore.year)
            end
        end
    end
end
