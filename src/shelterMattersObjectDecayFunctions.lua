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
    if elapsedInMinutes < 1 then
        return
    end

    -- Store the last update time
    object:setLastDecayUpdate({ day = currentDay, time = currentTime })

    -- check if spawn protection is applied
    local spawnTime = object:getSpawnTime()
    if spawnTime ~= nil then
        -- calculate diference in time
        local elapsedSinceSpawn = (currentDay - spawnTime.day) * (24 * 60 * 60 * 1000) + (currentTime - spawnTime.time)
        local elapsedSinceSpawnInHours = elapsedSinceSpawn / (60 * 60 * 1000) -- Convert from ms to hours

        -- if the spawn protection is within the timeframe don't execute the rest of the function
        if elapsedSinceSpawnInHours < ShelterMatters.palletSpawnProtection then
            return
        end
    end

    -- run update for each fillUnit
    for _, unit in ipairs(object:getDecayUnits()) do
        unit:update(elapsedInMinutes)
    end
end

function ShelterMattersObjectDecayFunctions.infoBoxAddInfo(box, object)
    local totalFill = 0
    local totalDecay = 0
    local totalWetness = 0
    local wetnessWeight = 0
    local bestBefore = nil
    local minTemp = nil
    local maxTemp = nil
    local isAffectedByWetness = false

    for _, unit in pairs(object:getDecayUnits()) do
        local fillLevel = unit:getFillLevel()
        if fillLevel > 0 then
            -- Best before: earliest one
            local unitBestBefore = unit:getBestBefore()
            if unitBestBefore and ( not bestBefore or
                unitBestBefore.year < bestBefore.year or
                (unitBestBefore.year == bestBefore.year and unitBestBefore.month < bestBefore.month)
            ) then
                bestBefore = unit.bestBefore
            end

            if unit:isAffectedByTemperature() then
                local decayProps = unit:getDecayProperties()
                -- Temperature range
                if decayProps.minTemperature then
                    minTemp = math.max(minTemp or -math.huge, decayProps.minTemperature)
                end
                if decayProps.maxTemperature then
                    maxTemp = math.min(maxTemp or math.huge, decayProps.maxTemperature)
                end
            end

            -- Total decay
            totalFill = totalFill + unit:getFillLevelFull()
            totalDecay = totalDecay + (unit.decayAmount or 0)

            -- Weighted wetness
            if unit:isAffectedByWetness() then
                isAffectedByWetness = true
                local unitWetness = unit:getWetness()
                if unitWetness then
                    totalWetness = totalWetness + unitWetness * fillLevel
                    wetnessWeight = wetnessWeight + fillLevel
                end
            end
        end
    end

    -- If no valid units, display nothing
    if totalFill <= 0 then return end

    ShelterMattersHelpers.infoBoxAddBestBefore(box, bestBefore)

    if wetnessWeight > 0 or isAffectedByWetness then
        local avgWetness = (totalWetness / wetnessWeight) * 100
        ShelterMattersHelpers.infoBoxAddWetness(box, avgWetness)
    end

    if object:smIsAffectedByWeather() then
        if minTemp and maxTemp then
            box:addLine(g_i18n:getText("SM_InfoTemperature"), string.format("%s - %s", g_i18n:formatTemperature(minTemp, 0), g_i18n:formatTemperature(maxTemp, 0)))
        elseif maxTemp then
            box:addLine(g_i18n:getText("SM_InfoTemperature"), string.format("%s %s", g_i18n:getText("SM_InfoMax"), g_i18n:formatTemperature(maxTemp, 0)))
        elseif minTemp then
            box:addLine(g_i18n:getText("SM_InfoTemperature"), string.format("%s %s", g_i18n:getText("SM_InfoMin"), g_i18n:formatTemperature(minTemp, 0)))
        end
    end

    local decayPercent = (totalDecay / totalFill) * 100
    if decayPercent > 0 then
        box:addLine(g_i18n:getText("SM_InfoDecay"), string.format("%d%%", decayPercent))
    end
end

-----------------------------------
-- init, load and save functions --
-----------------------------------

function ShelterMattersObjectDecayFunctions.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. ".lastUpdate#day", "Last update day of current item")
    schema:register(XMLValueType.FLOAT, basePath .. ".lastUpdate#time", "Last update time of current item")

    schema:register(XMLValueType.INT, basePath .. ".spawnTime#day", "Day when the item has spawned")
    schema:register(XMLValueType.FLOAT, basePath .. ".spawnTime#time", "Time when the item has spawned")

    ShelterMattersDecayUnit.registerSavegameXMLPaths(schema, basePath .. ".decayUnits.unit(?)")
end

function ShelterMattersObjectDecayFunctions.initObject(self, spec)
    spec.lastUpdate = {} -- initialize the lastUpdate as empty object to prevent errors when saving thing that have never been updated yet

    spec.decayUnits = {} -- initialize empty decay unit list

    -- initialize from fillUnit
    local fillUnits = self:getFillUnits() 
    for fillUnitIndex, fillUnit in ipairs(fillUnits) do
        spec.decayUnits[fillUnitIndex] = ShelterMattersDecayUnit.new(self, fillUnitIndex)
    end
end

function ShelterMattersObjectDecayFunctions.loadFromXMLFile(xmlFile, key, spec, bale)
    spec.lastUpdate = { day = xmlFile:getValue(key .. ".lastUpdate#day"), time = xmlFile:getValue(key .. ".lastUpdate#time") }
    spec.spawnTime = { day = xmlFile:getValue(key .. ".spawnTime#day"), time = xmlFile:getValue(key .. ".spawnTime#time") }

    -- reset the spawnTime if not all properties or correctly set
    -- this to prevent errors and saving nil values in the feature
    if spec.spawnTime.day == nil or spec.spawnTime.time == nil then
        spec.spawnTime = nil
    end

    if spec.decayUnits == nil and bale then
        -- decayUnits can be nil when loading xml from placeable storage instead of item
        spec.decayUnits = { ShelterMattersDecayUnit.new(spec, 1) }
    end

    -- Try to load decay unit info from xml
    local i = 0
    for _, decayUnit in ipairs(spec.decayUnits) do
        local decayUnitKey = string.format("%s.decayUnits.unit(%d)", key, i)

        if xmlFile:hasProperty(decayUnitKey) then
            decayUnit:loadFromXMLFile(xmlFile, decayUnitKey)
        end

        i = i + 1
    end
end

function ShelterMattersObjectDecayFunctions.saveToXMLFile(xmlFile, key, spec)
    if spec.lastUpdate ~= nil then -- it is posible that a bale was never updated if this mod is added to an existing savegame
        xmlFile:setValue(key .. ".lastUpdate#day", spec.lastUpdate.day)
        xmlFile:setValue(key .. ".lastUpdate#time", spec.lastUpdate.time)
    end

    if spec.spawnTime ~= nil then
        xmlFile:setValue(key .. ".spawnTime#day", spec.spawnTime.day)
        xmlFile:setValue(key .. ".spawnTime#time", spec.spawnTime.time)
    end

    -- Save the decay units to xml
    local i = 0
    for _, decayUnit in ipairs(spec.decayUnits) do
        local decayUnitKey = string.format("%s.decayUnits.unit(%d)", key, i)
        decayUnit:saveToXMLFile(xmlFile, decayUnitKey)

        i = i + 1
    end
end

--------------------------------
-- multiplayer sync functions --
--------------------------------

-- lastUpdate and spawnTime are not synced because those values are only used on the server

function ShelterMattersObjectDecayFunctions.readStream(streamId, connection, spec)
    for _, unit in ipairs(spec.decayUnits) do
        unit:readStream(streamId, connection)
    end
end
function ShelterMattersObjectDecayFunctions.writeStream(streamId, connection, spec)
    for _, unit in ipairs(spec.decayUnits) do
        unit:writeStream(streamId, connection)
    end
end

function ShelterMattersObjectDecayFunctions.readUpdateStream(streamId, timestamp, connection, spec)
    if connection:getIsServer() then
        for _, unit in ipairs(spec.decayUnits) do
            if streamReadBool(streamId) then
                unit:readStream(streamId)
            end
        end
    end
end
function ShelterMattersObjectDecayFunctions.writeUpdateStream(streamId, connection, dirtyMask, spec)
    if not connection:getIsServer() then
        for _, unit in ipairs(spec.decayUnits) do
            if streamWriteBool(streamId, bitAND(dirtyMask, unit.dirtyFlag) ~= 0) then
                unit:writeStream(streamId, connection)
            end
        end
    end
end
