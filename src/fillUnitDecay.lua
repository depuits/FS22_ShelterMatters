-- FillUnitDecay.lua
-- Specialization for handling pallet and trailer decay
local modName = g_currentModName

FillUnitDecay = {}
FillUnitDecay.SPEC_NAME = "fillUnitDecay"
FillUnitDecay.SPEC_TABLE_NAME = "spec_"..modName.."."..FillUnitDecay.SPEC_NAME

function FillUnitDecay.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end

function FillUnitDecay.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", FillUnitDecay)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", FillUnitDecay)

    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", FillUnitDecay)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", FillUnitDecay)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", FillUnitDecay)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", FillUnitDecay)

    -- onFillUnitFillLevelChanged --TODO use to reset bestBeforeDate and fillLevelFull
end

function FillUnitDecay.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getIsPallet", FillUnitDecay.getIsPallet)
    SpecializationUtil.registerFunction(vehicleType, "isAffectedByWeather", FillUnitDecay.isAffectedByWeather)
    SpecializationUtil.registerFunction(vehicleType, "getIsCoverClosed", FillUnitDecay.getIsCoverClosed)

    SpecializationUtil.registerFunction(vehicleType, "setWetness", FillUnitDecay.setWetness)
    SpecializationUtil.registerFunction(vehicleType, "getFillLevelFull", FillUnitDecay.getFillLevelFull)
    SpecializationUtil.registerFunction(vehicleType, "setFillLevelFull", FillUnitDecay.setFillLevelFull)
    SpecializationUtil.registerFunction(vehicleType, "getBestBefore", FillUnitDecay.getBestBefore)
    SpecializationUtil.registerFunction(vehicleType, "setBestBefore", FillUnitDecay.setBestBefore)
    SpecializationUtil.registerFunction(vehicleType, "addDecayAmount", FillUnitDecay.addDecayAmount)
    SpecializationUtil.registerFunction(vehicleType, "setDecayAmount", FillUnitDecay.setDecayAmount)
    SpecializationUtil.registerFunction(vehicleType, "getDecayProperties", FillUnitDecay.getDecayProperties)
    SpecializationUtil.registerFunction(vehicleType, "isAffectedByWetness", FillUnitDecay.isAffectedByWetness)
end

function FillUnitDecay.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "showInfo", FillUnitDecay.showInfo)
end

function FillUnitDecay.initSpecialization()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    local baseKey = "vehicles.vehicle(?)."..modName..".fillUnitDecay"

    schemaSavegame:register(XMLValueType.INT, baseKey .. ".lastUpdate#day", "Last update day of current bale")
    schemaSavegame:register(XMLValueType.FLOAT, baseKey .. ".lastUpdate#time", "Last update time of current bale")
    schemaSavegame:register(XMLValueType.INT, baseKey .. ".bestBefore#month", "Best before month of current bale")
    schemaSavegame:register(XMLValueType.INT, baseKey .. ".bestBefore#year", "Best before year of current bale")
    schemaSavegame:register(XMLValueType.FLOAT, baseKey .. "#wetness", "Wetness level of current bale")
    schemaSavegame:register(XMLValueType.FLOAT, baseKey .. "#decayAmount", "Amount lost to decay of current bale")
    schemaSavegame:register(XMLValueType.FLOAT, baseKey .. "#fillLevelFull", "Current bale fill level when it was created")
    schemaSavegame:register(XMLValueType.FLOAT, baseKey.."#spawnTime", "Time when the item has spawned")
end

function FillUnitDecay:onLoad(savegame)
    local spec = self[FillUnitDecay.SPEC_TABLE_NAME]

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

    if savegame ~= nil then
        local baseKey = savegame.key .. "."..modName..".fillUnitDecay"

        spec.lastUpdate = { day = savegame.xmlFile:getValue(baseKey .. ".lastUpdate#day"), time = savegame.xmlFile:getValue(baseKey .. ".lastUpdate#time") }

        spec.bestBefore = { month = savegame.xmlFile:getValue(baseKey .. ".bestBefore#month"), year = savegame.xmlFile:getValue(baseKey .. ".bestBefore#year") }

        spec.wetness = savegame.xmlFile:getValue(baseKey .. "#wetness", 0)
        spec.decayAmount = savegame.xmlFile:getValue(baseKey .. "#decayAmount", 0)
        spec.fillLevelFull = savegame.xmlFile:getValue(baseKey .. "#fillLevelFull", 0)

        spec.spawnTime = savegame.xmlFile:getValue(baseKey.."#spawnTime")

        if spec.bestBefore.month == nil or spec.bestBefore.year == nil then
            spec.bestBefore = nil -- reset the bestbefore if one of the 2 properties or not correctly set
        end
    end 
end

function FillUnitDecay:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self[FillUnitDecay.SPEC_TABLE_NAME]

    xmlFile:setValue(key .. ".lastUpdate#day", spec.lastUpdate.day)
    xmlFile:setValue(key .. ".lastUpdate#time", spec.lastUpdate.time)

    if spec.bestBefore then
        xmlFile:setValue(key .. ".bestBefore#month", spec.bestBefore.month)
        xmlFile:setValue(key .. ".bestBefore#year", spec.bestBefore.year)
    end

    xmlFile:setValue(key .. "#wetness", spec.wetness)
    xmlFile:setValue(key .. "#decayAmount", spec.decayAmount)
    xmlFile:setValue(key .. "#fillLevelFull", spec.fillLevelFull)

    xmlFile:setValue(key .. "#spawnTime", spec.spawnTime)
end

function FillUnitDecay:onUpdate(dt)
    if not self.isServer then
        return
    end

    local spec = self[FillUnitDecay.SPEC_TABLE_NAME]

    --TODO
end


function FillUnitDecay:setWetness(wetness)
    local spec = self[FillUnitDecay.SPEC_TABLE_NAME]
    spec.wetness = MathUtil.clamp(wetness, 0, 1)

    if self.isServer then
        self:raiseDirtyFlags(spec.wetnessDirtyFlag)
    end
end

function FillUnitDecay:getFillLevelFull()
    local spec = self[FillUnitDecay.SPEC_TABLE_NAME]

    --  always get the current fill level
    local currentFillLevel = self:getFillUnitFillLevel(1)

    if currentFillLevel ~= nil and currentFillLevel > spec.fillLevelFull then
        self:setFillLevelFull(currentFillLevel)
    end

    return spec.fillLevelFull
end

function FillUnitDecay:setFillLevelFull(fillLevelFull)
    local spec = self[FillUnitDecay.SPEC_TABLE_NAME]
    spec.fillLevelFull = fillLevelFull

    if self.isServer then
        self:raiseDirtyFlags(spec.fillLevelFullDirtyFlag)
    end
end

function FillUnitDecay:getBestBefore()
    local spec = self[FillUnitDecay.SPEC_TABLE_NAME]
    if spec.bestBefore then
        return spec.bestBefore
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

    return spec.bestBefore
end

function FillUnitDecay:setBestBefore(bestBefore)
    local spec = self[FillUnitDecay.SPEC_TABLE_NAME]
    spec.bestBefore = bestBefore

    -- if the bestbefore is not valid then we clear it
    if not bestBefore or bestBefore.month == nil or bestBefore.year == nil then
        spec.bestBefore = nil
    end

    if self.isServer then
        self:raiseDirtyFlags(spec.bestBeforeDirtyFlag)
    end
end

function FillUnitDecay:addDecayAmount(decayAmount)
    local spec = self[FillUnitDecay.SPEC_TABLE_NAME]

    self:getFillLevelFull() -- getting fillLevelFull here to make sure it is updated

    self:setDecayAmount(spec.decayAmount + decayAmount)

    local fillTypeIndex = self:getFillUnitFillType(1)
    self:addFillUnitFillLevel(self:getOwnerFarmId(), 1, decayAmount * -1, fillTypeIndex, ToolType.UNDEFINED, nil)
-- TODO test if this is needed for pallets and fix if so
--[[    if self.fillLevel <= 0 then
        self:delete()
        shelterMattersBaleDecayedEvent.showDecayedNotification(self:getOwnerFarmId(), self:getFillType())
        -- send event to display popup on clients
        g_server:broadcastEvent(shelterMattersBaleDecayedEvent.new(self))
    end]]
end

function FillUnitDecay:setDecayAmount(decayAmount)
    local spec = self[FillUnitDecay.SPEC_TABLE_NAME]

    spec.decayAmount = MathUtil.clamp(decayAmount, 0, self:getFillLevelFull())

    if self.isServer then
        self:raiseDirtyFlags(spec.decayAmountDirtyFlag)
    end
end

function FillUnitDecay:getDecayProperties()
    local fillTypeIndex = self:getFillUnitFillType(1) -- Assume single fill unit for pallets
    return ShelterMatters.decayProperties[fillTypeIndex]
end

function FillUnitDecay:isAffectedByWetness()
    -- only things with a decay rate are affected by wetness
    local decayProps = self:getDecayProperties()

    return decayProps and -- should have decay properties defined
        decayProps.wetnessImpact and decayProps.wetnessImpact > 0 and -- and the wetnessImpact must be greater then 0
        decayProps.wetnessDecay and decayProps.wetnessDecay > 0 -- and there must also be a decay from the wetness
end

function FillUnitDecay:getIsSpawnProtected()
    local spec = self[FillUnitDecay.SPEC_TABLE_NAME]

    -- Protection for spawn points (grace period)
    local gracePeriod = 24 * 60 * 60 * 1000 -- TODO get from config
    return g_currentMission.time - spec.spawnTime < gracePeriod -- TODO get time from parameter or so that it's a correct game time
end

function FillUnitDecay:isAffectedByWeather()
    -- Pallets and bigbags are affected, treeSaplingPallets are not affected
    if self:getIsPallet() then
        return true
    end

    -- Check if the vehicle has a cover, all trailers have the cover spec
    if self.spec_cover then
        -- Check if the vehicle is a known closed tanker/container
        -- TODO get from config and refine
        if self.typeName == "tankerTrailer" or self.typeName == "liquidTrailer" or self.typeName == "waterTrailer" then
            return false
        end

        return self:getIsCoverClosed()
    end

    return false -- all other items are not affected
end

function FillUnitDecay:getIsPallet()
    return self.typeName == "pallet" or self.typeName == "treeSaplingPallet" or self.typeName == "bigBag"
end

function FillUnitDecay:getIsCoverClosed()
    -- Check if the vehicle has a cover and is currently covered
    if self.spec_cover then
        if self.spec_cover.hasCovers then
            local covers = self.spec_cover.covers

            if covers ~= nil and #covers > 0 then
                local isOpen = false

                for i = 1, #covers do
                    local cover = covers[i]

                    if self.spec_cover.state ~= cover.index then
                        return true
                    end
                end
            end
        end
    end

    -- Check if the vehicle is a known closed tanker/container
--[[    if self.typeName == "tankerTrailer" or self.typeName == "liquidTrailer" or self.typeName == "waterTrailer" then
        return true
    end]]

    return false -- If it's an open trailer, decay should still apply
end

function FillUnitDecay:showInfo(superFunc, box)
    local spec = self[FillUnitDecay.SPEC_TABLE_NAME]

    -- debugging stuff
    box:addLine("type", tostring(self.typeName))
    box:addLine("isAffected", tostring(self:isAffectedByWeather()))
    box:addLine("isCoverClosed", tostring(self:getIsCoverClosed()))

    -- debug spec rendering
    --FillUnitDecay.renderSpecs(self.specializations) -- shovel, trailer - waterTrailer


    -- display best by date
    local bb = self:getBestBefore()
    ShelterMattersHelpers.infoBoxAddBestBefore(box, bb)

    -- display wetness in info box
    if self:isAffectedByWetness() then
        ShelterMattersHelpers.infoBoxAddWetness(box, spec.wetness)
    end

    -- display decay in info box
    local decayPercentage = 0
    local fillLevelFull = self:getFillLevelFull()
    if fillLevelFull > 0 then 
        decayPercentage = spec.decayAmount / fillLevelFull
    end

    if decayPercentage > 0 then
        box:addLine(g_i18n:getText("SM_InfoDecay"), string.format("%d%%", decayPercentage * 100))
    end

    superFunc(self, box)
end

function FillUnitDecay.renderSpecs(specializations)
    local row = 0
    local x, y = 0.05, 0.85 -- Screen position
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1) -- White color
    renderText(x, y, 0.01, "SPECS:")
    local index = 0
    local rowCount = 25
    for _, spec in pairs(specializations) do
        if spec ~= nil and spec.className ~= nil then
            index = index + 1

            local col = math.floor(index / rowCount)
            local row = math.fmod(index, rowCount)

            renderText(x + col * 0.1, y - row * 0.02, 0.01, spec.className)
        end
    end
end

-- sync events
function FillUnitDecay:onReadStream(streamId, connection)
    local spec = self[FillUnitDecay.SPEC_TABLE_NAME]

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

function FillUnitDecay:onWriteStream(streamId, connection)
    local spec = self[FillUnitDecay.SPEC_TABLE_NAME]

    streamWriteFloat32(streamId, spec.wetness)
    streamWriteFloat32(streamId, spec.fillLevelFull)
    streamWriteFloat32(streamId, spec.decayAmount)
    if streamWriteBool(streamId, spec.bestBefore ~= nil) then
        streamWriteInt32(streamId, spec.bestBefore.month)
        streamWriteInt32(streamId, spec.bestBefore.year)
    end
end

function FillUnitDecay:onReadUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        local spec = self[FillUnitDecay.SPEC_TABLE_NAME]

        if streamReadBool(streamId) then
            self:setWetness(streamReadFloat32(streamId))
        end

        if streamReadBool(streamId) then
            self:setFillLevelFull(streamReadFloat32(streamId))
        end

        if streamReadBool(streamId) then
            self:setDecayAmount(streamReadFloat32(streamId))
        end

        if streamReadBool(streamId) then
            if streamReadBool(streamId) then
                local month = streamReadInt32(streamId)
                local year = streamReadInt32(streamId)

                spec.bestBefore = { month = month, year = year }
            else
                spec.bestBefore = nil
            end
        end
    end
end

function FillUnitDecay:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self[FillUnitDecay.SPEC_TABLE_NAME]

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
