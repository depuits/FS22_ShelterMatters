
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

function ShelterMattersBale.new(isServer, superFunc, isClient, customMt)
    local self = superFunc(isServer, isClient, customMt)

    self.wetness = 0
    self.wetnessDirtyFlag = self:getNextDirtyFlag()

    self.decayAmount = 0
    self.decayAmountDirtyFlag = self:getNextDirtyFlag()

    self.fillLevelFullDirtyFlag = self:getNextDirtyFlag()

    return self
end

function Bale:setWetness(wetness)
    self.wetness = wetness

    if self.isServer then
        self:raiseDirtyFlags(self.wetnessDirtyFlag)
    end
end

function Bale:setFillLevelFull(fillLevelFull)
    self.fillLevelFull = fillLevelFull

    if self.isServer then
        self:raiseDirtyFlags(self.fillLevelFullDirtyFlag)
    end
end

function Bale:addDecayAmount(decayAmount)
    self:setDecayAmount(self.decayAmount + decayAmount)

    if self.fillLevelFull == nil then
        self:setFillLevelFull(self.fillLevel)
    end

    self:setFillLevel(self.fillLevel - decayAmount)

    if self.fillLevel <= 0 then
        self:delete()
        shelterMattersBaleDecayedEvent.showDecayedNotification(self:getOwnerFarmId(), self:getFillType())
        -- send event to display popup on clients
        g_server:broadcastEvent(shelterMattersBaleDecayedEvent.new(self))
    end
end

function Bale:setDecayAmount(decayAmount)
    self.decayAmount = decayAmount

    if self.isServer then
        self:raiseDirtyFlags(self.decayAmountDirtyFlag)
    end
end

-- update bale to currentTime (in minutes) and with which rate wetness is applied
function ShelterMattersBale.updateBale(bale, currentTime, wetnessRate)
    if not g_currentMission:getIsServer() then
        return -- Skip on clients
    end

    -- Initialize the lastUpdateInGameTime if this is the first run
    if bale.lastUpdate == nil then
        bale.lastUpdate = currentTime
        return -- No update needed on the first run
    end

    -- Calculate the elapsed in-game hours
    local elapsedInMinutes = currentTime - bale.lastUpdate
    if elapsedInMinutes < 0 then
        elapsedInMinutes = elapsedInMinutes + (24 * 60) -- Handle midnight rollover
    end

    -- only execute the update logic once every ingame minute
    if elapsedInMinutes > 1 then
        return
    end

    -- Update last recorded in-game time
    bale.lastUpdate = currentTime

    -- update wetness
    if wetnessRate > 0 then -- only if there is a wetnessRate
        if bale.wrappingState == 1 then
            -- wrapped bales don't get wet
        else
            local inShed = ShelterMatters.isNodeInShed(bale.nodeId)
            if not inShed then
                bale:setWetness(bale.wetness + (wetnessRate * elapsedInMinutes))
            end
        end
    end

    -- update decay
    if bale.wetness > 0 then -- only if the bale is wet then it will decay
        local decayPerMinute = ShelterMatters.baleWetnessDecay / 60
        local wetnessDamage = (decayPerMinute * elapsedInMinutes) * bale.wetness
        bale:addDecayAmount(wetnessDamage)
    end
end

--[[function ShelterMattersBale.updateBaleDamage(bale, elapsedInGameHours, rate)
    if bale.wrappingState == 1 then
        return -- no damage is applied when the bale is wrapped
    end

    local inShed = ShelterMatters.isNodeInShed(bale.nodeId)
    if not inShed then
        local outsideDamage = (rate * elapsedInGameHours)
        bale:addDecayAmount(outsideDamage)
    end
end]]

function ShelterMattersBale:showInfo(box)
    -- display wetness in info box
    local wetnessDesc = "SM_InfoBaleWetness_1"
    if self.wetness > 80 then
        wetnessDesc = "SM_InfoBaleWetness_5"
    elseif self.wetness > 60 then
        wetnessDesc = "SM_InfoBaleWetness_4"
    elseif self.wetness > 30 then
        wetnessDesc = "SM_InfoBaleWetness_3"
    elseif self.wetness > 0 then
        wetnessDesc = "SM_InfoBaleWetness_2"
    end
    box:addLine(g_i18n:getText("SM_InfoBaleWetness"), g_i18n:getText(wetnessDesc))

    -- display decay in info box
    local decayPercentage = 0
    if self.fillLevelFull ~= nil then
        decayPercentage = self.decayAmount / self.fillLevelFull
    end

    box:addLine(g_i18n:getText("SM_InfoBaleDecay"), string.format("%d%%", decayPercentage * 100))
end

function ShelterMattersBale.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.FLOAT, basePath .. "#lastUpdate", "Last update of current bale")
    schema:register(XMLValueType.FLOAT, basePath .. "#wetness", "Wetness level of current bale")
    schema:register(XMLValueType.FLOAT, basePath .. "#decayAmount", "Amount lost to decay of current bale")
    schema:register(XMLValueType.FLOAT, basePath .. "#fillLevelFull", "Current bale fill level when it was created")
end

function ShelterMattersBale.loadBaleAttributesFromXMLFile(attributes, superFunc, xmlFile, key, resetVehicles)
    attributes.lastUpdate = xmlFile:getValue(key .. "#lastUpdate")
    attributes.wetness = xmlFile:getValue(key .. "#wetness")
    attributes.decayAmount = xmlFile:getValue(key .. "#decayAmount")
    attributes.fillLevelFull = xmlFile:getValue(key .. "#fillLevelFull")

    return superFunc(attributes, xmlFile, key, resetVehicles)
end

function ShelterMattersBale:getBaleAttributes(superFunc)
    attributes = superFunc(self)
    attributes.lastUpdate = self.lastUpdate
    attributes.wetness = self.wetness
    attributes.decayAmount = self.decayAmount
    attributes.fillLevelFull = self.fillLevelFull or self.fillLevel

    return attributes
end

function ShelterMattersBale:applyBaleAttributes(attributes)
    self.lastUpdate = attributes.lastUpdate or self.lastUpdate

    self:setWetness(attributes.wetness or self.wetness)
    self:setDecayAmount(attributes.decayAmount or self.decayAmount)
    self:setFillLevelFull(attributes.fillLevelFull or self.fillLevelFull or self.fillLevel)
end

function ShelterMattersBale.saveBaleAttributesToXMLFile(attributes, xmlFile, key)
    xmlFile:setValue(key .. "#lastUpdate", attributes.lastUpdate)
    xmlFile:setValue(key .. "#wetness", attributes.wetness)
    xmlFile:setValue(key .. "#decayAmount", attributes.decayAmount)
    xmlFile:setValue(key .. "#fillLevelFull", attributes.fillLevelFull)
end

function ShelterMattersBale:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. "#lastUpdate", self.lastUpdate)
    xmlFile:setValue(key .. "#wetness", self.wetness)
    xmlFile:setValue(key .. "#decayAmount", self.decayAmount)
    xmlFile:setValue(key .. "#fillLevelFull", self.fillLevelFull or self.fillLevel)
end


-- multiplayer methods
function ShelterMattersBale:readUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            self:setWetness(streamReadFloat32(streamId))
        end

        if streamReadBool(streamId) then
            self:setDecayAmount(streamReadFloat32(streamId))
        end

        if streamReadBool(streamId) then
            self:setFillLevelFull(streamReadFloat32(streamId))
        end
    end
end
function ShelterMattersBale:writeUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bitAND(dirtyMask, self.wetnessAmountDirtyFlag) ~= 0) then
            streamWriteFloat32(streamId, self.wetness)
        end

        if streamWriteBool(streamId, bitAND(dirtyMask, self.decayAmountDirtyFlag) ~= 0) then
            streamWriteFloat32(streamId, self.decayAmount)
        end

        if streamWriteBool(streamId, bitAND(dirtyMask, self.fillLevelFullDirtyFlag) ~= 0) then
            streamWriteFloat32(streamId, self.fillLevelFull or self.fillLevel)
        end
    end
end
function ShelterMattersBale:readStream(streamId, connection)
    self.wetness = streamReadFloat32(streamId)
    self.decayAmount = streamReadFloat32(streamId)
    self.fillLevelFull = streamReadFloat32(streamId)
end
function ShelterMattersBale:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.wetness)
    streamWriteFloat32(streamId, self.decayAmount)
    streamWriteFloat32(streamId, self.fillLevelFull or self.fillLevel)
end

ShelterMattersBale.registerFunctions()
