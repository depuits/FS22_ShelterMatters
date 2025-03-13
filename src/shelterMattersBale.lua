
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

    self.lastUpdate = {} -- initialize the lastUpdate as empty object to prevent errors when saving thing that have never been updated yet

    self.wetness = 0
    self.wetnessDirtyFlag = self:getNextDirtyFlag()

    self.decayAmount = 0
    self.decayAmountDirtyFlag = self:getNextDirtyFlag()

    self.fillLevelFullDirtyFlag = self:getNextDirtyFlag()

    self.bestBeforeDirtyFlag = self:getNextDirtyFlag()

    return self
end

function Bale:setWetness(wetness)
    self.wetness = MathUtil.clamp(wetness, 0, 1)

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
    self.decayAmount = MathUtil.clamp(decayAmount, 0, self.fillLevelFull or self.fillLevel)

    if self.isServer then
        self:raiseDirtyFlags(self.decayAmountDirtyFlag)
    end
end

function Bale:getDecayProperties()
    return ShelterMatters.decayProperties[self:getFillType()]
end

function Bale:isAffectedByWetness()
    -- only things with a decay rate are affected by wetness
    local decayProps = self:getDecayProperties()

    return decayProps and -- should have decay properties defined
        decayProps.wetnessImpact and decayProps.wetnessImpact > 0 and -- and the wetnessImpact must be greater then 0
        decayProps.wetnessDecay and decayProps.wetnessDecay > 0 -- and there must also be a decay from the wetness
end

-- update bale to the currentTime and with which rate wetness is applied
function ShelterMattersBale.updateBale(bale, wetnessRate)
    if not g_currentMission:getIsServer() then
        return -- Skip on clients
    end

    local currentDay = g_currentMission.environment.currentMonotonicDay
    local currentTime = g_currentMission.environment.dayTime

    -- Initialize the lastUpdateInGameTime if this is the first run
    if bale.lastUpdate == nil or bale.lastUpdate.day == nil or bale.lastUpdate.time == nil then
        bale.lastUpdate = { day = currentDay, time = currentTime }
        return -- No update needed on the first run
    end

    local lastDay = bale.lastUpdate.day
    local lastTime = bale.lastUpdate.time

    -- Calculate the elapsed in-game minutes
    local elapsedTime = (currentDay - lastDay) * (24 * 60 * 60 * 1000) + (currentTime - lastTime)
    local elapsedInMinutes = elapsedTime / (60 * 1000) -- Convert from ms to minutes

    -- only execute the update logic once every ingame minute
    if elapsedInMinutes > 1 then
        return
    end

    -- Store the last update time
    bale.lastUpdate = { day = currentDay, time = currentTime }

    local decayProps = bale:getDecayProperties()

    if bale:isAffectedByWetness() then -- we will not check wetness if the is no decay for it
        -- update wetness
        if
            wetnessRate > 0 and -- only if there is a wetnessRate
            bale.wrappingState ~= 1 and -- wrapped bales don't get wet
            bale.wetness < 1 -- bale is not yet soaked
        then
            local inShed = ShelterMatters.isNodeInShed(bale.nodeId)
            if not inShed then
                bale:setWetness(bale.wetness + (wetnessRate * decayProps.wetnessImpact * elapsedInMinutes))
            end
        end

        -- update decay by wetness
        if bale.wetness > 0 then -- only if the bale is wet then it will decay
            local decayPerMinute = decayProps.wetnessDecay / 60 /  24 / g_currentMission.environment.daysPerPeriod
            local wetnessDamage = (decayPerMinute * elapsedInMinutes) * bale.wetness
            bale:addDecayAmount(wetnessDamage)
        end
    end

    -- update bestBefore
    local bb = bale:getBestBefore()
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
        bale:addDecayAmount(decayDamage)
    end
end

function ShelterMattersBale:showInfo(box)
    -- display best by date
    local bb = self:getBestBefore()
    if bb then
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

    -- display wetness in info box
    if self:isAffectedByWetness() then
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
    end

    -- display decay in info box
    local decayPercentage = 0
    if self.fillLevelFull ~= nil then
        decayPercentage = self.decayAmount / self.fillLevelFull
    end

    if decayPercentage > 0 then
        box:addLine(g_i18n:getText("SM_InfoBaleDecay"), string.format("%d%%", decayPercentage * 100))
    end
end

function ShelterMattersBale.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. ".lastUpdate#day", "Last update day of current bale")
    schema:register(XMLValueType.FLOAT, basePath .. ".lastUpdate#time", "Last update time of current bale")
    schema:register(XMLValueType.INT, basePath .. ".bestBefore#month", "Best before month of current bale")
    schema:register(XMLValueType.INT, basePath .. ".bestBefore#year", "Best before year of current bale")
    schema:register(XMLValueType.FLOAT, basePath .. "#wetness", "Wetness level of current bale")
    schema:register(XMLValueType.FLOAT, basePath .. "#decayAmount", "Amount lost to decay of current bale")
    schema:register(XMLValueType.FLOAT, basePath .. "#fillLevelFull", "Current bale fill level when it was created")
end

function ShelterMattersBale.loadBaleAttributesFromXMLFile(attributes, superFunc, xmlFile, key, resetVehicles)
    attributes.lastUpdate = { day = xmlFile:getValue(key .. ".lastUpdate#day"), time = xmlFile:getValue(key .. ".lastUpdate#time") }
    attributes.bestBefore = { month = xmlFile:getValue(key .. ".bestBefore#month"), year = xmlFile:getValue(key .. ".bestBefore#year") }
    attributes.wetness = xmlFile:getValue(key .. "#wetness")
    attributes.decayAmount = xmlFile:getValue(key .. "#decayAmount")
    attributes.fillLevelFull = xmlFile:getValue(key .. "#fillLevelFull")

    if attributes.bestBefore.month == nil or attributes.bestBefore.year == nil then
        attributes.bestBefore = nil
    end

    return superFunc(attributes, xmlFile, key, resetVehicles)
end

function ShelterMattersBale:getBaleAttributes(superFunc)
    attributes = superFunc(self)
    attributes.lastUpdate = self.lastUpdate

    attributes.bestBefore = self.bestBefore

    attributes.wetness = self.wetness
    attributes.decayAmount = self.decayAmount
    attributes.fillLevelFull = self.fillLevelFull or self.fillLevel

    return attributes
end

function ShelterMattersBale:applyBaleAttributes(attributes)
    self.lastUpdate = attributes.lastUpdate or self.lastUpdate

    self:setBestBefore(attributes.bestBefore or self.bestBefore)

    self:setWetness(attributes.wetness or self.wetness)
    self:setDecayAmount(attributes.decayAmount or self.decayAmount)
    self:setFillLevelFull(attributes.fillLevelFull or self.fillLevelFull or self.fillLevel)
end

function ShelterMattersBale.saveBaleAttributesToXMLFile(attributes, xmlFile, key)
    xmlFile:setValue(key .. ".lastUpdate#day", attributes.lastUpdate.day)
    xmlFile:setValue(key .. ".lastUpdate#time", attributes.lastUpdate.time)

    if attributes.bestBefore and attributes.bestBefore.month and attributes.bestBefore.year then
        xmlFile:setValue(key .. ".bestBefore#month", attributes.bestBefore.month)
        xmlFile:setValue(key .. ".bestBefore#year", attributes.bestBefore.year)
    end

    xmlFile:setValue(key .. "#wetness", attributes.wetness)
    xmlFile:setValue(key .. "#decayAmount", attributes.decayAmount)
    xmlFile:setValue(key .. "#fillLevelFull", attributes.fillLevelFull)
end

function ShelterMattersBale:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. ".lastUpdate#day", self.lastUpdate.day)
    xmlFile:setValue(key .. ".lastUpdate#time", self.lastUpdate.time)

    if self.bestBefore then
        xmlFile:setValue(key .. ".bestBefore#month", self.bestBefore.month)
        xmlFile:setValue(key .. ".bestBefore#year", self.bestBefore.year)
    end

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

        if streamWriteBool(streamId, bitAND(dirtyMask, self.fillLevelFullDirtyFlag) ~= 0) then
            streamWriteFloat32(streamId, self.fillLevelFull or self.fillLevel)
        end

        if streamWriteBool(streamId, bitAND(dirtyMask, self.bestBeforeDirtyFlag) ~= 0) then
            if streamWriteBool(streamId, self.bestBefore) then
                streamWriteInt32(streamId, self.bestBefore.month)
                streamWriteInt32(streamId, self.bestBefore.year)
            end
        end
    end
end
function ShelterMattersBale:readStream(streamId, connection)
    self.wetness = streamReadFloat32(streamId)
    self.decayAmount = streamReadFloat32(streamId)
    self.fillLevelFull = streamReadFloat32(streamId)
    if streamReadBool(streamId) then
        local month = streamReadInt32(streamId)
        local year = streamReadInt32(streamId)

        self.bestBefore = { month = month, year = year }
    else
        self.bestBefore = nil
    end
end
function ShelterMattersBale:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.wetness)
    streamWriteFloat32(streamId, self.decayAmount)
    streamWriteFloat32(streamId, self.fillLevelFull or self.fillLevel)
    if streamWriteBool(streamId, self.bestBefore) then
        streamWriteInt32(streamId, self.bestBefore.month)
        streamWriteInt32(streamId, self.bestBefore.year)
    end
end

ShelterMattersBale.registerFunctions()
