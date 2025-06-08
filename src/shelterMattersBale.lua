
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
    ShelterMattersObjectDecayFunctions.loadFromXMLFile(xmlFile, key, attributes, true)
    return superFunc(attributes, xmlFile, key, resetVehicles)
end

function ShelterMattersBale:getBaleAttributes(superFunc)
    attributes = superFunc(self)
    attributes.lastUpdate = self.lastUpdate

    attributes.decayUnits = self.decayUnits

    return attributes
end

function ShelterMattersBale:applyBaleAttributes(attributes)
    self.lastUpdate = attributes.lastUpdate or self.lastUpdate

    self.decayUnits = attributes.decayUnits or self.decayUnits
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

function Bale:smGetFillLevel(index)
    return self.fillLevel
end

function Bale:smAddFillLevel(index, amount)
    self:setFillLevel(self.fillLevel + amount)

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

function Bale:smGetFillType(index)
    return self:getFillType()
end

function Bale:smIsAffectedByWeather()
    return self.wrappingState ~= 1 -- wrapped bales are not affected by weather
end

function Bale:getDecayUnits()
    return self.decayUnits
end

-- method to help with initialization of decayUnits
function Bale:getFillUnits()
    return { 
        [1] = {
            fillType = self.fillType,
            capacity = self.fillLevel,
            fillLevel = self.fillLevel
        }
    }
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
