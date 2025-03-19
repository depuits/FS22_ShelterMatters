
ShelterMattersBale = {
}

function ShelterMattersBale.registerFunctions()
    -- custom logic method overwrites
    Bale.new = Utils.overwrittenFunction(Bale.new, ShelterMattersBale.new)
    Bale.showInfo = Utils.appendedFunction(Bale.showInfo, ShelterMattersBale.showInfo)

    -- saving overwrites
    Bale.registerSavegameXMLPaths = Utils.appendedFunction(Bale.registerSavegameXMLPaths, ShelterMattersBale.registerSavegameXMLPaths)
    Bale.loadBaleAttributesFromXMLFile = Utils.overwrittenFunction(Bale.loadBaleAttributesFromXMLFile, ShelterMattersBale.loadBaleAttributesFromXMLFile)
    Bale.getBaleAttributes = Utils.overwrittenFunction(Bale.getBaleAttributes, ShelterMattersBale.getBaleAttributes)
    Bale.applyBaleAttributes = Utils.appendedFunction(Bale.applyBaleAttributes, ShelterMattersBale.applyBaleAttributes)
    Bale.saveBaleAttributesToXMLFile = Utils.appendedFunction(Bale.saveBaleAttributesToXMLFile, ShelterMattersBale.saveBaleAttributesToXMLFile)
    Bale.saveToXMLFile = Utils.appendedFunction(Bale.saveToXMLFile, ShelterMattersBale.saveToXMLFile)

    -- multiplayer overwrites
    Bale.readUpdateStream = Utils.appendedFunction(Bale.readUpdateStream, ShelterMattersBale.readUpdateStream)
    Bale.writeUpdateStream = Utils.appendedFunction(Bale.writeUpdateStream, ShelterMattersBale.writeUpdateStream)
    Bale.readStream = Utils.appendedFunction(Bale.readStream, ShelterMattersBale.readStream)
    Bale.writeStream = Utils.appendedFunction(Bale.writeStream, ShelterMattersBale.writeStream)
end

-----------------------------------
-- init, load and save functions --
-----------------------------------

function ShelterMattersBale.registerSavegameXMLPaths(schema, basePath)
    ShelterMattersObjectDecayFunctions.registerSavegameXMLPaths(schema, basePath)
end

function ShelterMattersBale.new(isServer, superFunc, isClient, customMt)
    local self = superFunc(isServer, isClient, customMt)

    ShelterMattersObjectDecayFunctions.initObject(self, self)

    return self
end

function ShelterMattersBale.loadBaleAttributesFromXMLFile(attributes, superFunc, xmlFile, key, resetVehicles)
    ShelterMattersObjectDecayFunctions.loadFromXMLFile(xmlFile, key, attributes)
    return superFunc(attributes, xmlFile, key, resetVehicles)
end

function ShelterMattersBale:getBaleAttributes(superFunc)
    attributes = superFunc(self)
    attributes.lastUpdate = self.lastUpdate

    attributes.bestBefore = self.bestBefore

    attributes.wetness = self.wetness
    attributes.fillLevelFull = self.fillLevelFull or self.fillLevel
    attributes.decayAmount = self.decayAmount

    return attributes
end

function ShelterMattersBale:applyBaleAttributes(attributes)
    self.lastUpdate = attributes.lastUpdate or self.lastUpdate

    self:setBestBefore(attributes.bestBefore or self.bestBefore)

    self:setWetness(attributes.wetness or self.wetness)
    self:setFillLevelFull(attributes.fillLevelFull or self.fillLevelFull or self.fillLevel)
    self:setDecayAmount(attributes.decayAmount or self.decayAmount)
end

function ShelterMattersBale.saveBaleAttributesToXMLFile(attributes, xmlFile, key)
    ShelterMattersObjectDecayFunctions.saveToXMLFile(xmlFile, key, attributes)
end

function ShelterMattersBale:saveToXMLFile(xmlFile, key)
    ShelterMattersObjectDecayFunctions.saveToXMLFile(xmlFile, key, self)
end

------------------------
-- Gameplay functions --
------------------------

function ShelterMattersBale.update(bale)
    ShelterMattersObjectDecayFunctions.update(bale)
end

function ShelterMattersBale:showInfo(box)
    ShelterMattersObjectDecayFunctions.infoBoxAddInfo(box, self)
end

--------------------------------------------
-- data access and manipulation functions --
--------------------------------------------

function Bale:getLastDecayUpdate()
    return self.lastUpdate
end

function Bale:setLastDecayUpdate(lastUpdate)
    self.lastUpdate = lastUpdate
end

function Bale:getSpawnTime()
    return self.spawnTime
end

function Bale:getWetness()
    return self.wetness
end

function Bale:setWetness(wetness)
    self.wetness = MathUtil.clamp(wetness, 0, 1)

    if self.isServer then
        self:raiseDirtyFlags(self.wetnessDirtyFlag)
    end
end

function Bale:isAffectedByWetness()
    -- only things with a decay rate are affected by wetness
    local decayProps = self:getDecayProperties()

    return decayProps and -- should have decay properties defined
        decayProps.wetnessImpact and decayProps.wetnessImpact > 0 and -- and the wetnessImpact must be greater then 0
        decayProps.wetnessDecay and decayProps.wetnessDecay > 0 and -- and there must also be a decay from the wetness
        self.wrappingState ~= 1 -- wrapped bales don't get wet
end

function Bale:isAffectedByTemperature()
    -- only things with a decay rate are affected by wetness
    local decayProps = self:getDecayProperties()

    return decayProps and ( -- should have decay properties defined
        ( decayProps.maxTemperature and decayProps.maxTemperatureDecay and decayProps.maxTemperatureDecay > 0 ) or -- and there must also be a decay from the maxTemperatureDecay
        ( decayProps.minTemperature and decayProps.minTemperatureDecay and decayProps.minTemperatureDecay > 0 ) -- or there must also be a decay from the minTemperatureDecay
    )
end

function Bale:getFillLevelFull()
    local currentFillLevel = self.fillLevel

    if currentFillLevel ~= nil and currentFillLevel > self.fillLevelFull then
        -- unlike for the pallets we never update the spawntime because bales don't get protection
        
        self:setFillLevelFull(currentFillLevel)
    end

    return self.fillLevelFull
end
function Bale:setFillLevelFull(fillLevelFull)
    self.fillLevelFull = fillLevelFull

    if self.isServer then
        self:raiseDirtyFlags(self.fillLevelFullDirtyFlag)
    end
end

function Bale:getBestBefore()
    if self.bestBefore then
        return self.bestBefore
    end

    local decayProps = self:getDecayProperties()
    
    -- if type bestBeforePeriod or bestBeforeDecay not defined then return nil
    if decayProps and 
        decayProps.bestBeforePeriod and decayProps.bestBeforePeriod > 0 and 
        decayProps.bestBeforeDecay and decayProps.bestBeforeDecay > 0 
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

function Bale:setBestBefore(bestBefore)
    self.bestBefore = bestBefore

    -- if the bestbefore is not valid then we clear it
    if not bestBefore or bestBefore.month == nil or bestBefore.year == nil then
        self.bestBefore = nil
    end

    if self.isServer then
        self:raiseDirtyFlags(self.bestBeforeDirtyFlag)
    end
end

function Bale:addDecayAmount(decayAmount)
    if self.fillLevelFull == nil then
        self:setFillLevelFull(self.fillLevel)
    end

    self:setDecayAmount(self.decayAmount + decayAmount)
    self:setFillLevel(self.fillLevel - decayAmount)

    local fillTypeInfo = self:getFillTypeInfo(self.fillType)
    if fillTypeInfo ~= nil then
        local massProc = self.fillLevel / fillTypeInfo.capacity
        setMass(self.nodeId, fillTypeInfo.mass * massProc)
    end

    if self.fillLevel <= 0 then
        self:delete()
        shelterMattersBaleDecayedEvent.showDecayedNotification(self:getOwnerFarmId(), self:getFillType())
        -- send event to display popup on clients
        g_server:broadcastEvent(shelterMattersBaleDecayedEvent.new(self))
    end
end
function Bale:getDecayAmount()
    return self.decayAmount
end
function Bale:setDecayAmount(decayAmount)
    self.decayAmount = MathUtil.clamp(decayAmount, 0, self.fillLevelFull)

    if self.isServer then
        self:raiseDirtyFlags(self.decayAmountDirtyFlag)
    end
end

function Bale:getDecayProperties()
    return ShelterMatters.decayProperties[self:getFillType()]
end

--------------------------------
-- multiplayer sync functions --
--------------------------------

function ShelterMattersBale:readStream(streamId, connection)
    ShelterMattersObjectDecayFunctions.readStream(streamId, connection, self)
end
function ShelterMattersBale:writeStream(streamId, connection)
    ShelterMattersObjectDecayFunctions.writeStream(streamId, connection, self)
end

function ShelterMattersBale:readUpdateStream(streamId, timestamp, connection)
    ShelterMattersObjectDecayFunctions.readUpdateStream(streamId, timestamp, connection, self)
end
function ShelterMattersBale:writeUpdateStream(streamId, connection, dirtyMask)
    ShelterMattersObjectDecayFunctions.writeUpdateStream(streamId, connection, dirtyMask, self)
end

ShelterMattersBale.registerFunctions()
