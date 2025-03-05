
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
    self.decayAmount = 0
    self.decayAmountDirtyFlag = self:getNextDirtyFlag()
    self.fillLevelFullDirtyFlag = self:getNextDirtyFlag()

    return self
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


function ShelterMattersBale.updateBaleDamage(bale, elapsedInGameHours, rate)
    if bale.wrappingState == 1 then
        return -- no damage is applied when the bale is wrapped
    end

    local inShed = ShelterMatters.isNodeInShed(bale.nodeId)
    if not inShed then
        local outsideDamage = (rate * elapsedInGameHours)
        bale:addDecayAmount(outsideDamage)
    end
end

function ShelterMattersBale:showInfo(box)
    local decayPercentage = 0
    if self.fillLevelFull ~= nil then
        decayPercentage = self.decayAmount / self.fillLevelFull
    end

    box:addLine(g_i18n:getText("SM_InfoBaleDecay"), string.format("%d%%", decayPercentage * 100))
end

function ShelterMattersBale.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.FLOAT, basePath .. "#decayAmount", "Amount lost to decay of current bale")
    schema:register(XMLValueType.FLOAT, basePath .. "#fillLevelFull", "Current bale fill level when it was created")
end

function ShelterMattersBale.loadBaleAttributesFromXMLFile(attributes, superFunc, xmlFile, key, resetVehicles)
    attributes.decayAmount = xmlFile:getValue(key .. "#decayAmount")
    attributes.fillLevelFull = xmlFile:getValue(key .. "#fillLevelFull")

    return superFunc(attributes, xmlFile, key, resetVehicles)
end

function ShelterMattersBale:getBaleAttributes(superFunc)
    attributes = superFunc(self)
    attributes.decayAmount = self.decayAmount
    attributes.fillLevelFull = self.fillLevelFull or self.fillLevel

    return attributes
end

function ShelterMattersBale:applyBaleAttributes(attributes)
    self:setDecayAmount(attributes.decayAmount or self.decayAmount)
    self:setFillLevelFull(attributes.fillLevelFull or self.fillLevelFull or self.fillLevel)
end

function ShelterMattersBale.saveBaleAttributesToXMLFile(attributes, xmlFile, key)
    xmlFile:setValue(key .. "#decayAmount", attributes.decayAmount)
    xmlFile:setValue(key .. "#fillLevelFull", attributes.fillLevelFull)
end

function ShelterMattersBale:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. "#decayAmount", self.decayAmount)
    xmlFile:setValue(key .. "#fillLevelFull", self.fillLevelFull or self.fillLevel)
end


-- multiplayer methods
function ShelterMattersBale:readUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
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
        if streamWriteBool(streamId, bitAND(dirtyMask, self.decayAmountDirtyFlag) ~= 0) then
            streamWriteFloat32(streamId, self.decayAmount)
        end

        if streamWriteBool(streamId, bitAND(dirtyMask, self.fillLevelFullDirtyFlag) ~= 0) then
            streamWriteFloat32(streamId, self.fillLevelFull or self.fillLevel)
        end
    end
end
function ShelterMattersBale:readStream(streamId, connection)
    self.decayAmount = streamReadFloat32(streamId)
    self.fillLevelFull = streamReadFloat32(streamId)
end
function ShelterMattersBale:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.decayAmount)
    streamWriteFloat32(streamId, self.fillLevelFull or self.fillLevel)
end

ShelterMattersBale.registerFunctions()
