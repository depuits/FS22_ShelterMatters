ShelterMattersDecayUnit = {}
ShelterMattersDecayUnit_mt = Class(ShelterMattersDecayUnit)

-----------------------------------
-- init, load and save functions --
-----------------------------------

function ShelterMattersDecayUnit.new(parent, fillUnitIndex)
    local self = setmetatable({}, ShelterMattersDecayUnit_mt)

    self.object = parent

    if self.object.isServer then
        self.dirtyFlag = self.object:getNextDirtyFlag()
    end

    self.fillUnitIndex = fillUnitIndex

    self.wetness = 0
    self.fillLevelFull = 0
    self.decayAmount = 0

    -- following are set dynamicly if not yet defined
    self.bestBefore = nil

    return self
end

function ShelterMattersDecayUnit.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#index", "Fill Unit index")

    schema:register(XMLValueType.INT, basePath .. ".bestBefore#month", "Best before month of current item")
    schema:register(XMLValueType.INT, basePath .. ".bestBefore#year", "Best before year of current item")

    schema:register(XMLValueType.FLOAT, basePath .. "#wetness", "Wetness level of current item")
    schema:register(XMLValueType.FLOAT, basePath .. "#fillLevelFull", "Current item fill level when it was created")
    schema:register(XMLValueType.FLOAT, basePath .. "#decayAmount", "Amount lost to decay of current item")
end

function ShelterMattersDecayUnit:loadFromXMLFile(xmlFile, key)
    self.fillUnitIndex = xmlFile:getValue(key .. "#index")

    self.bestBefore = { month = xmlFile:getValue(key .. ".bestBefore#month"), year = xmlFile:getValue(key .. ".bestBefore#year") }

    self.wetness = xmlFile:getValue(key .. "#wetness", 0)
    self.fillLevelFull = xmlFile:getValue(key .. "#fillLevelFull", 0)

    self.decayAmount = xmlFile:getValue(key .. "#decayAmount", 0)

    -- reset the bestBefore if not all properties or correctly set
    -- this to prevent errors and saving nil values in the feature
    if self.bestBefore.month == nil or self.bestBefore.year == nil then
        self.bestBefore = nil -- reset the bestbefore if one of the 2 properties or not correctly set
    end
end

function ShelterMattersDecayUnit:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. "#index", self.fillUnitIndex)

    if self.bestBefore ~= nil then
        xmlFile:setValue(key .. ".bestBefore#month", self.bestBefore.month)
        xmlFile:setValue(key .. ".bestBefore#year", self.bestBefore.year)
    end

    xmlFile:setValue(key .. "#wetness", self.wetness)
    xmlFile:setValue(key .. "#fillLevelFull", self.fillLevelFull)
    xmlFile:setValue(key .. "#decayAmount", self.decayAmount)
end
------------------------
-- Gameplay functions --
------------------------

function ShelterMattersDecayUnit:update(elapsedInMinutes)
    local decayProps = self:getDecayProperties()
    local inShed = nil -- preinit inShed so when it is calculated in one of the step it can be reused

    -- update wetness impact
    if self:isAffectedByWetness() then -- we will not check wetness if the is no decay for it
        local wetnessRate = ShelterMatters:getWeatherWetnessRate()
        -- update wetness
        if
            wetnessRate > 0 and -- only if there is a wetnessRate
            self:getWetness() < 1 -- object is not yet soaked
        then
            inShed = ShelterMatters.isObjectInShed(self.object, inShed)
            if not inShed then
                self:setWetness(self:getWetness() + (wetnessRate * decayProps.wetnessImpact * elapsedInMinutes))
            end
        end
    end

    -- update decay by wetness
    if self:getWetness() > 0 and decayProps then -- only if the object is wet then it will decay
        local decayPerMinute = decayProps.wetnessDecay / 60 /  24 / g_currentMission.environment.daysPerPeriod
        local damageWetness = (decayPerMinute * elapsedInMinutes) * self:getWetness()
        self:addDecayAmount(damageWetness)
    end

    -- update temperature impact
    if self:isAffectedByTemperature() then
        local temperature = g_currentMission.environment.weather:getCurrentTemperature()

        -- max tempertature decay
        if decayProps.maxTemperature ~= nil and decayProps.maxTemperature < temperature and decayProps.maxTemperatureDecay ~= nil and decayProps.maxTemperatureDecay > 0 then
            inShed = ShelterMatters.isObjectInShed(self.object, inShed)
            if not inShed then -- only if the object is not inside it will decay
                local decayPerMinute = decayProps.maxTemperatureDecay / 60
                local damageMaxTemp = (decayPerMinute * elapsedInMinutes)
                self:addDecayAmount(damageMaxTemp)
            end
        end

        -- min temperature decay
        if decayProps.minTemperature ~= nil and decayProps.minTemperature > temperature and decayProps.minTemperatureDecay ~= nil and decayProps.minTemperatureDecay > 0 then
            inShed = ShelterMatters.isObjectInShed(self.object, inShed)
            if not inShed then -- only if the object is not inside it will decay
                local decayPerMinute = decayProps.minTemperatureDecay / 60
                local damageMinTemp = (decayPerMinute * elapsedInMinutes)
                self:addDecayAmount(damageMinTemp)
            end
        end
    end

    -- update bestBefore
    local bb = self:getBestBefore()
    if bb ~= nil and bb.month < g_currentMission.environment.currentPeriod and bb.year <= g_currentMission.environment.currentYear then
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
        self:addDecayAmount(decayDamage)
    end
end

--------------------------------------------
-- data access and manipulation functions --
--------------------------------------------

function ShelterMattersObjectDecay:reset()
    self:setWetness(0)
    self:setFillLevelFull(0)
    self:setDecayAmount(0)
    self:setBestBefore(nil)
end

function ShelterMattersObjectDecay:markDirty()
    if self.object.isServer then
        self.object:raiseDirtyFlags(self.dirtyFlag)
    end
end

function ShelterMattersObjectDecay:getWetness()
    return self.wetness
end
function ShelterMattersObjectDecay:setWetness(wetness)
    self.wetness = MathUtil.clamp(wetness, 0, 1)
    self:markDirty()
end

function ShelterMattersObjectDecay:getFillLevelFull()
    --  always get the current fill level
    local currentFillLevel = self.object:smGetFillLevel(self.fillUnitIndex)

    if currentFillLevel ~= nil and currentFillLevel > self.fillLevelFull then
        -- when the fill level increases this indicates that the pallet is not yet full
        -- so we should update the spawn protection time to start from here
        if self.fillLevelFull == 0 and self.object.smSetSpawnTime then
            -- we only do this when the previous fillLevelFull was 0
            -- if not then the pallets could also be spawned by buying from the store and in that case there is no spawn protection
            local currentDay = g_currentMission.environment.currentMonotonicDay
            local currentTime = g_currentMission.environment.dayTime

            self.object:smSetSpawnTime({ day = currentDay, time = currentTime })
        end

        self:setFillLevelFull(currentFillLevel)
    end

    return self.fillLevelFull
end
function ShelterMattersObjectDecay:setFillLevelFull(fillLevelFull)
    self.fillLevelFull = fillLevelFull
    self:markDirty()
end

function ShelterMattersObjectDecay:getBestBefore()
    if self.bestBefore ~= nil then
        return self.bestBefore
    end

    local decayProps = self:getDecayProperties()
    
    -- if type bestBeforePeriod or bestBeforeDecay not defined then return nil
    if decayProps ~= nil and 
        decayProps.bestBeforePeriod ~= nil and decayProps.bestBeforePeriod > 0 and 
        decayProps.bestBeforeDecay ~= nil and decayProps.bestBeforeDecay > 0 
    then
        local month = g_currentMission.environment.currentPeriod + decayProps.bestBeforePeriod -- 1 (March) to 12 (Feb)
        local year = g_currentMission.environment.currentYear

        -- Handle month rollover
        if month > 12 then
            year = year + math.floor((month - 1) / 12)  -- Increase the year
            month = ((month - 1) % 12) + 1  -- Wrap month to stay within 1-12
        end
        
        self:setBestBefore({ month = month, year = year })
    end

    return self.bestBefore
end
function ShelterMattersObjectDecay:setBestBefore(bestBefore)
    self.bestBefore = bestBefore

    -- if the bestbefore is not valid then we clear it
    if bestBefore == nil or bestBefore.month == nil or bestBefore.year == nil then
        self.bestBefore = nil
    end

    self:markDirty()
end

function ShelterMattersObjectDecay:addDecayAmount(decayAmount)
    self:getFillLevelFull() -- getting fillLevelFull here to make sure it is updated

    self:setDecayAmount(self.decayAmount + decayAmount)

    self.object:smAddFillLevel(self.fillUnitIndex, decayAmount * -1)
end
function ShelterMattersObjectDecay:getDecayAmount()
    return self.decayAmount
end
function ShelterMattersObjectDecay:setDecayAmount(decayAmount)
    self.decayAmount = MathUtil.clamp(decayAmount, 0, self:getFillLevelFull())
    self:markDirty()
end

function ShelterMattersObjectDecay:getDecayProperties()
    local fillTypeIndex = self.object:smGetFillType(self.fillUnitIndex)
    return ShelterMatters.decayProperties[fillTypeIndex]
end

function ShelterMattersObjectDecay:isAffectedByWetness()
    -- only things with a decay rate are affected by wetness
    local decayProps = self:getDecayProperties()

    return decayProps ~= nil and -- should have decay properties defined
        decayProps.wetnessImpact ~= nil and decayProps.wetnessImpact > 0 and -- and the wetnessImpact must be greater then 0
        decayProps.wetnessDecay ~= nil and decayProps.wetnessDecay > 0 and -- and there must also be a decay from the wetness
        self.object:smIsAffectedByWeather()
end

function ShelterMattersObjectDecay:isAffectedByTemperature()
    -- only things with a decay rate are affected by wetness
    local decayProps = self:getDecayProperties()

    return decayProps ~= nil and ( -- should have decay properties defined
        ( decayProps.maxTemperature ~= nil and decayProps.maxTemperatureDecay ~= nil and decayProps.maxTemperatureDecay > 0 ) or -- and there must also be a decay from the maxTemperatureDecay
        ( decayProps.minTemperature ~= nil and decayProps.minTemperatureDecay ~= nil and decayProps.minTemperatureDecay > 0 ) -- or there must also be a decay from the minTemperatureDecay
    ) and self.object:smIsAffectedByWeather()
end

--------------------------------
-- multiplayer sync functions --
--------------------------------

function ShelterMattersDecayUnit:readStream(streamId, connection)
    self.wetness = streamReadFloat32(streamId)
    self.fillLevelFull = streamReadFloat32(streamId)
    self.decayAmount = streamReadFloat32(streamId)

    if streamReadBool(streamId) then
        local month = streamReadInt32(streamId)
        local year = streamReadInt32(streamId)

        self.bestBefore = { month = month, year = year }
    else
        self.bestBefore = nil
    end
end

function ShelterMattersDecayUnit.writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.wetness)
    streamWriteFloat32(streamId, self.fillLevelFull)
    streamWriteFloat32(streamId, self.decayAmount)

    if streamWriteBool(streamId, self.bestBefore ~= nil) then
        streamWriteInt32(streamId, self.bestBefore.month)
        streamWriteInt32(streamId, self.bestBefore.year)
    end
end
