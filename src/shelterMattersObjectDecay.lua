-- ShelterMattersObjectDecay.lua
-- Specialization for handling pallet and trailer decay
local modName = g_currentModName

ShelterMattersObjectDecay = {}
ShelterMattersObjectDecay.SPEC_NAME = "ObjectDecay"
ShelterMattersObjectDecay.SPEC_TABLE_NAME = "spec_"..modName.."."..ShelterMattersObjectDecay.SPEC_NAME

function ShelterMattersObjectDecay.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end

function ShelterMattersObjectDecay.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", ShelterMattersObjectDecay)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ShelterMattersObjectDecay)

    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", ShelterMattersObjectDecay)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", ShelterMattersObjectDecay)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", ShelterMattersObjectDecay)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", ShelterMattersObjectDecay)

    -- onFillUnitFillLevelChanged --TODO use to reset bestBeforeDate and fillLevelFull
end

function ShelterMattersObjectDecay.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getIsPallet", ShelterMattersObjectDecay.getIsPallet)
    SpecializationUtil.registerFunction(vehicleType, "isAffectedByWeather", ShelterMattersObjectDecay.isAffectedByWeather)
    SpecializationUtil.registerFunction(vehicleType, "getIsCoverClosed", ShelterMattersObjectDecay.getIsCoverClosed)

    SpecializationUtil.registerFunction(vehicleType, "getLastDecayUpdate", ShelterMattersObjectDecay.getLastDecayUpdate)
    SpecializationUtil.registerFunction(vehicleType, "setLastDecayUpdate", ShelterMattersObjectDecay.setLastDecayUpdate)
    SpecializationUtil.registerFunction(vehicleType, "getSpawnTime", ShelterMattersObjectDecay.getSpawnTime)
    SpecializationUtil.registerFunction(vehicleType, "getWetness", ShelterMattersObjectDecay.getWetness)
    SpecializationUtil.registerFunction(vehicleType, "setWetness", ShelterMattersObjectDecay.setWetness)
    SpecializationUtil.registerFunction(vehicleType, "getFillLevelFull", ShelterMattersObjectDecay.getFillLevelFull)
    SpecializationUtil.registerFunction(vehicleType, "setFillLevelFull", ShelterMattersObjectDecay.setFillLevelFull)
    SpecializationUtil.registerFunction(vehicleType, "getBestBefore", ShelterMattersObjectDecay.getBestBefore)
    SpecializationUtil.registerFunction(vehicleType, "setBestBefore", ShelterMattersObjectDecay.setBestBefore)
    SpecializationUtil.registerFunction(vehicleType, "addDecayAmount", ShelterMattersObjectDecay.addDecayAmount)
    SpecializationUtil.registerFunction(vehicleType, "getDecayAmount", ShelterMattersObjectDecay.getDecayAmount)
    SpecializationUtil.registerFunction(vehicleType, "setDecayAmount", ShelterMattersObjectDecay.setDecayAmount)
    SpecializationUtil.registerFunction(vehicleType, "getDecayProperties", ShelterMattersObjectDecay.getDecayProperties)
    SpecializationUtil.registerFunction(vehicleType, "isAffectedByWetness", ShelterMattersObjectDecay.isAffectedByWetness)
end

function ShelterMattersObjectDecay.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "showInfo", ShelterMattersObjectDecay.showInfo)
end

-----------------------------------
-- init, load and save functions --
-----------------------------------

function ShelterMattersObjectDecay.initSpecialization()
    local basePath = "vehicles.vehicle(?)."..modName.."."..ShelterMattersObjectDecay.SPEC_NAME
    ShelterMattersObjectDecayFunctions.registerSavegameXMLPaths(Vehicle.xmlSchemaSavegame, basePath)
end

function ShelterMattersObjectDecay:onLoad(savegame)
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]

    ShelterMattersObjectDecayFunctions.initObject(self, spec)

    if savegame ~= nil then
        local baseKey = savegame.key .. "."..modName.."."..ShelterMattersObjectDecay.SPEC_NAME
        ShelterMattersObjectDecayFunctions.loadFromXMLFile(savegame.xmlFile, baseKey, spec)
    end 
end

function ShelterMattersObjectDecay:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]
    ShelterMattersObjectDecayFunctions.saveToXMLFile(xmlFile, key, spec)
end

------------------------
-- Gameplay functions --
------------------------

function ShelterMattersObjectDecay:onUpdate(dt) 
    ShelterMattersObjectDecayFunctions.update(self)
end

function ShelterMattersObjectDecay:showInfo(superFunc, box)
    -- debugging stuff
    box:addLine("type", tostring(self.typeName))
    box:addLine("isAffected", tostring(self:isAffectedByWeather()))
    box:addLine("isCoverClosed", tostring(self:getIsCoverClosed()))

    -- debug spec rendering
    --ShelterMattersObjectDecay.renderSpecs(self.specializations) -- shovel, trailer - waterTrailer

    ShelterMattersObjectDecayFunctions.infoBoxAddInfo(box, self)

    superFunc(self, box)
end

function ShelterMattersObjectDecay.renderSpecs(specializations)
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

--------------------------------------------
-- data access and manipulation functions --
--------------------------------------------

function ShelterMattersObjectDecay:getLastDecayUpdate()
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]
    return spec.lastUpdate
end
function ShelterMattersObjectDecay:setLastDecayUpdate(lastUpdate)
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]
    spec.lastUpdate = lastUpdate
end

function ShelterMattersObjectDecay:getSpawnTime()
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]
    return spec.spawnTime
end

function ShelterMattersObjectDecay:getWetness()
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]
    return spec.wetness
end
function ShelterMattersObjectDecay:setWetness(wetness)
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]
    spec.wetness = MathUtil.clamp(wetness, 0, 1)

    if self.isServer then
        self:raiseDirtyFlags(spec.wetnessDirtyFlag)
    end
end

function ShelterMattersObjectDecay:isAffectedByWetness()
    -- only things with a decay rate are affected by wetness
    local decayProps = self:getDecayProperties()

    return decayProps and -- should have decay properties defined
        decayProps.wetnessImpact and decayProps.wetnessImpact > 0 and -- and the wetnessImpact must be greater then 0
        decayProps.wetnessDecay and decayProps.wetnessDecay > 0 and -- and there must also be a decay from the wetness
        self:getIsPallet() -- currently only pallets are affected we'll want to expand this in the future to also include trailers etc
end

function ShelterMattersObjectDecay:getFillLevelFull()
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]

    --  always get the current fill level
    local currentFillLevel = self:getFillUnitFillLevel(1)

    if currentFillLevel ~= nil and currentFillLevel > spec.fillLevelFull then
        -- when the fill level increases this indicates that the pallet is not yet full
        -- so we should update the spawn protection time to start from here
        if spec.fillLevelFull > 0 and self:getIsPallet() then
            -- we only do this when the previous fillLevelFull was 0
            -- if not then the pallets could also be spawned by buying from the store and in that case there is no spawn protetion
            --TODO set spanwProtectionTime
            local currentDay = g_currentMission.environment.currentMonotonicDay
            local currentTime = g_currentMission.environment.dayTime

            spec.spawnTime = { day = currentDay, time = currentTime }
        end

        self:setFillLevelFull(currentFillLevel)
    end

    return spec.fillLevelFull
end
function ShelterMattersObjectDecay:setFillLevelFull(fillLevelFull)
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]
    spec.fillLevelFull = fillLevelFull

    if self.isServer then
        self:raiseDirtyFlags(spec.fillLevelFullDirtyFlag)
    end
end

function ShelterMattersObjectDecay:getBestBefore()
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]
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
function ShelterMattersObjectDecay:setBestBefore(bestBefore)
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]
    spec.bestBefore = bestBefore

    -- if the bestbefore is not valid then we clear it
    if not bestBefore or bestBefore.month == nil or bestBefore.year == nil then
        spec.bestBefore = nil
    end

    if self.isServer then
        self:raiseDirtyFlags(spec.bestBeforeDirtyFlag)
    end
end

function ShelterMattersObjectDecay:addDecayAmount(decayAmount)
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]

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
function ShelterMattersObjectDecay:getDecayAmount()
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]
    return spec.decayAmount
end
function ShelterMattersObjectDecay:setDecayAmount(decayAmount)
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]
    spec.decayAmount = MathUtil.clamp(decayAmount, 0, self:getFillLevelFull())

    if self.isServer then
        self:raiseDirtyFlags(spec.decayAmountDirtyFlag)
    end
end

function ShelterMattersObjectDecay:getDecayProperties()
    local fillTypeIndex = self:getFillUnitFillType(1) -- Assume single fill unit for pallets
    return ShelterMatters.decayProperties[fillTypeIndex]
end

function ShelterMattersObjectDecay:isAffectedByWeather()
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

function ShelterMattersObjectDecay:getIsPallet()
    return self.typeName == "pallet" or self.typeName == "treeSaplingPallet" or self.typeName == "bigBag"
end

function ShelterMattersObjectDecay:getIsCoverClosed()
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

--------------------------------
-- multiplayer sync functions --
--------------------------------

function ShelterMattersObjectDecay:onReadStream(streamId, connection)
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]
    ShelterMattersObjectDecayFunctions.readStream(streamId, connection, spec)
end
function ShelterMattersObjectDecay:onWriteStream(streamId, connection)
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]
    ShelterMattersObjectDecayFunctions.writeStream(streamId, connection, spec)
end

function ShelterMattersObjectDecay:onReadUpdateStream(streamId, timestamp, connection)
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]
    ShelterMattersObjectDecayFunctions.readUpdateStream(streamId, timestamp, connection, spec)
end
function ShelterMattersObjectDecay:onWriteUpdateStream(streamId, connection, dirtyMask)
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]
    ShelterMattersObjectDecayFunctions.writeUpdateStream(streamId, connection, dirtyMask, spec)
end
