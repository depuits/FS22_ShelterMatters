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
    -- TODO display first bestBefore
    -- TODO display highest min and lowest max values of all units
    -- TODO display combined decay value (add all decay amounts and filllevelFulls)
    -- TODO display avarage wetness
    local decay = object:getDecayUnits()
    box:addLine("decay units", tostring(#decay))

--[[
    -- display best by date
    local bb = object:getBestBefore()
    ShelterMattersHelpers.infoBoxAddBestBefore(box, bb)

    local decayProps = object:getDecayProperties()

    -- display wetness in info box
    if object:getWetness() > 0 or object:isAffectedByWetness() then
        ShelterMattersHelpers.infoBoxAddWetness(box, object:getWetness())
    end

    -- display temperature in info box
    if object:isAffectedByTemperature() then
        local decayProps = object:getDecayProperties()
        local hasMaxTemp = decayProps ~= nil and decayProps.maxTemperature ~= nil and decayProps.maxTemperatureDecay ~= nil and decayProps.maxTemperatureDecay > 0
        local hasMinTemp = decayProps ~= nil and decayProps.minTemperature ~= nil and decayProps.minTemperatureDecay ~= nil and decayProps.minTemperatureDecay > 0

        if hasMaxTemp and hasMinTemp then
            box:addLine(g_i18n:getText("SM_InfoTemperature"), string.format("%s - %s", g_i18n:formatTemperature(decayProps.minTemperature, 0), g_i18n:formatTemperature(decayProps.maxTemperature, 0)))
        elseif hasMaxTemp then
            box:addLine(g_i18n:getText("SM_InfoTemperature"), string.format("%s %s", g_i18n:getText("SM_InfoMax"), g_i18n:formatTemperature(decayProps.maxTemperature, 0)))
        elseif hasMinTemp then
            box:addLine(g_i18n:getText("SM_InfoTemperature"), string.format("%s %s", g_i18n:getText("SM_InfoMin"), g_i18n:formatTemperature(decayProps.minTemperature, 0)))
        end
    end

    -- display decay in info box
    local decayPercentage = 0
    local fillLevelFull = object:getFillLevelFull()
    if fillLevelFull > 0 then 
        decayPercentage = object:getDecayAmount() / fillLevelFull
    end

    if decayPercentage > 0 then
        box:addLine(g_i18n:getText("SM_InfoDecay"), string.format("%d%%", decayPercentage * 100))
    end]]
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
