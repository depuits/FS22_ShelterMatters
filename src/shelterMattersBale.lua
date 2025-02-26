
ShelterMattersBale = {
}

function ShelterMattersBale.registerFunctions()
    Bale.showInfo = Utils.appendedFunction(Bale.showInfo, ShelterMattersBale.showInfo)
    Bale.delete = Utils.appendedFunction(Bale.delete, ShelterMattersBale.delete)

    Bale.registerSavegameXMLPaths = Utils.appendedFunction(Bale.registerSavegameXMLPaths, ShelterMattersBale.registerSavegameXMLPaths)
    Bale.loadBaleAttributesFromXMLFile = Utils.overwrittenFunction(Bale.loadBaleAttributesFromXMLFile, ShelterMattersBale.loadBaleAttributesFromXMLFile)
    Bale.getBaleAttributes = Utils.overwrittenFunction(Bale.getBaleAttributes, ShelterMattersBale.getBaleAttributes)
    Bale.applyBaleAttributes = Utils.appendedFunction(Bale.applyBaleAttributes, ShelterMattersBale.applyBaleAttributes)
    Bale.saveToXMLFile = Utils.appendedFunction(Bale.saveToXMLFile, ShelterMattersBale.saveToXMLFile)
end

function ShelterMattersBale.updateBaleDamage(bale, elapsedInGameHours, rate)
    if bale.wrappingState == 1 then
        return -- no damage is applied when the bale is wrapped
    end

    local inShed = ShelterMatters.isNodeInShed(bale.nodeId)
    if not inShed then
        -- save fillLevel when applying first damage
        if bale.fillLevelFull == nil then
            bale.fillLevelFull = bale.fillLevel
        end

        local outsideDamage = (rate * elapsedInGameHours)
        bale.fillLevel = bale.fillLevel - outsideDamage

        if bale.fillLevel > 0 then
            -- send new fill level to all clients
            g_server:broadcastEvent(shelterMattersBaleDamageEvent.new(bale))
        else
            bale:delete()
        end
    end
end

function ShelterMattersBale:showInfo(box)
    local decayPercentage = 0
    if self.fillLevelFull ~= nil then
        decayPercentage = 1 - (self.fillLevel / self.fillLevelFull)
    end

    box:addLine(g_i18n:getText("SM_InfoBaleDecay"), string.format("%d%%", decayPercentage * 100))
end

function ShelterMattersBale:delete()
    g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("SM_AlertBaleDeleted"))
end

function ShelterMattersBale.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.FLOAT, basePath .. "#fillLevelFull", "Current bale fill level when it was created")
end

function ShelterMattersBale.loadBaleAttributesFromXMLFile(attributes, superFunc, xmlFile, key, resetVehicles)
    attributes.fillLevelFull = xmlFile:getValue(key .. "#fillLevelFull")

    return superFunc(attributes, xmlFile, key, resetVehicles)
end

function ShelterMattersBale:getBaleAttributes(superFunc)
    attributes = superFunc(self)
    attributes.fillLevelFull = self.fillLevelFull or self.fillLevel

    return attributes
end

function ShelterMattersBale:applyBaleAttributes(attributes)
    -- TODO use setFillLevelFull with self:raiseDirtyFlags(self.fermentingDirtyFlag)
    self.fillLevelFull = attributes.fillLevelFull or self.fillLevelFull or self.fillLevel
end

function ShelterMattersBale:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. "#fillLevelFull", self.fillLevelFull or self.fillLevel)
end

--TODO multiplayer methods
--[[function Bale:readUpdateStream(streamId, timestamp, connection)
function Bale:writeUpdateStream(streamId, connection, dirtyMask)
function Bale:readStream(streamId, connection)
function Bale:writeStream(streamId, connection)]]

ShelterMattersBale.registerFunctions()
