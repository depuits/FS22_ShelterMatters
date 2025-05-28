-- ShelterMattersObjectDecay.lua
-- Specialization for handling pallet and trailer decay
local modName = g_currentModName

ShelterMattersObjectDecay = {}
ShelterMattersObjectDecay.SPEC_NAME = "shelterMattersObjectDecay"
ShelterMattersObjectDecay.SPEC_TABLE_NAME = "spec_"..modName.."."..ShelterMattersObjectDecay.SPEC_NAME

function ShelterMattersObjectDecay.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end

function ShelterMattersObjectDecay.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", ShelterMattersObjectDecay)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", ShelterMattersObjectDecay)

    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", ShelterMattersObjectDecay)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", ShelterMattersObjectDecay)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", ShelterMattersObjectDecay)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", ShelterMattersObjectDecay)

    SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", ShelterMattersObjectDecay)
end

function ShelterMattersObjectDecay.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getIsPallet", ShelterMattersObjectDecay.getIsPallet)
    SpecializationUtil.registerFunction(vehicleType, "getIsCoverClosed", ShelterMattersObjectDecay.getIsCoverClosed)

    SpecializationUtil.registerFunction(vehicleType, "smIsAffectedByWeather", ShelterMattersObjectDecay.isAffectedByWeather)

    SpecializationUtil.registerFunction(vehicleType, "getLastDecayUpdate", ShelterMattersObjectDecay.getLastDecayUpdate)
    SpecializationUtil.registerFunction(vehicleType, "setLastDecayUpdate", ShelterMattersObjectDecay.setLastDecayUpdate)
    SpecializationUtil.registerFunction(vehicleType, "getSpawnTime", ShelterMattersObjectDecay.getSpawnTime)
    SpecializationUtil.registerFunction(vehicleType, "setSpawnTime", ShelterMattersObjectDecay.setSpawnTime)

    SpecializationUtil.registerFunction(vehicleType, "smGetFillLevel", ShelterMattersObjectDecay.getFillLevel)
    SpecializationUtil.registerFunction(vehicleType, "smAddFillLevel", ShelterMattersObjectDecay.addFillLevel)
    SpecializationUtil.registerFunction(vehicleType, "smGetFillType", ShelterMattersObjectDecay.getFillType)

    SpecializationUtil.registerFunction(vehicleType, "getDecayUnits", ShelterMattersObjectDecay.getDecayUnits)
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
    table.insert(ShelterMatters.vehicles, self) -- save to vehicle list to update

    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]

    ShelterMattersObjectDecayFunctions.initObject(self, spec)

    if savegame ~= nil then
        local baseKey = savegame.key .. "."..modName.."."..ShelterMattersObjectDecay.SPEC_NAME
        ShelterMattersObjectDecayFunctions.loadFromXMLFile(savegame.xmlFile, baseKey, spec)
    end 
end

function ShelterMattersObjectDecay:onDelete()
    -- remove object from vehicle list
    for i, vehicle in ipairs(ShelterMatters.vehicles) do
        if vehicle == self then
            table.remove(ShelterMatters.vehicles, i)
            break
        end
    end
end

function ShelterMattersObjectDecay:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]
    ShelterMattersObjectDecayFunctions.saveToXMLFile(xmlFile, key, spec)
end

------------------------
-- Gameplay functions --
------------------------
function ShelterMattersObjectDecay:showInfo(superFunc, box)
    -- debugging stuff
    --box:addLine("type", tostring(self.typeName))
    --box:addLine("isAffectedByWetness", tostring(self:isAffectedByWetness()))
    --box:addLine("isAffectedByTemperature", tostring(self:isAffectedByTemperature()))
    --box:addLine("isAffectedByWeather", tostring(self:isAffectedByWeather()))
    --box:addLine("isCoverClosed", tostring(self:getIsCoverClosed()))
    --box:addLine("hasSpec", tostring(ShelterMattersObjectDecay.hasMatchingSpecializations(self)))

    --[[local spawnTime = self:getSpawnTime()
    if spawnTime ~= nil then
        -- calculate diference in time
        local currentDay = g_currentMission.environment.currentMonotonicDay
        local currentTime = g_currentMission.environment.dayTime
        local elapsedSinceSpawn = (currentDay - spawnTime.day) * (24 * 60 * 60 * 1000) + (currentTime - spawnTime.time)
        local elapsedSinceSpawnInHours = elapsedSinceSpawn / (60 * 60 * 1000) -- Convert from ms to hours

        -- if the spawn protection is within the timeframe don't execute the rest of the function
        if elapsedSinceSpawnInHours < ShelterMatters.palletSpawnProtection then
            box:addLine("spawnProtection", "true")
        else
            box:addLine("spawnProtection", "false")
        end
    end]]

    ShelterMattersObjectDecayFunctions.infoBoxAddInfo(box, self)

    superFunc(self, box)
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
function ShelterMattersObjectDecay:setSpawnTime(spawnTime)
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]
    spec.spawnTime = spawnTime
end


function ShelterMattersObjectDecay:getFillLevel(index)
    return self:getFillUnitFillLevel(index)
end

function ShelterMattersObjectDecay:addFillLevel(index, amount)
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]

    local fillTypeIndex = self:getFillUnitFillType(index)
    self:addFillUnitFillLevel(self:getOwnerFarmId(), index, amount, fillTypeIndex, ToolType.UNDEFINED, nil)
-- TODO do we want a popup on pallets decayed? or a more generic items are decaying
--[[    if self.fillLevel <= 0 then
        shelterMattersBaleDecayedEvent.showDecayedNotification(self:getOwnerFarmId(), self:getFillType())
        -- send event to display popup on clients
        g_server:broadcastEvent(shelterMattersBaleDecayedEvent.new(self))
    end]]
end

function ShelterMattersObjectDecay:getFillType(index)
    return self:getFillUnitFillType(index)
end


function ShelterMattersObjectDecay:isAffectedByWeather()
    -- Pallets and bigbags are always affected
    if self:getIsPallet() then
        return true
    end

    -- Check if the vehicle has the required specs matching and no type exclude
    if ShelterMattersObjectDecay.hasMatchingSpecializations(self) then
        -- if it meets those criteria then we check if the cover is closed
        return not self:getIsCoverClosed()
    end

    return false -- all other items are not affected
end

function ShelterMattersObjectDecay:getIsPallet()
    return SpecializationUtil.hasSpecialization(Pallet, self.specializations)
end

function ShelterMattersObjectDecay.hasSpecialization(specName, specializations)
    for _, spec in pairs(specializations) do
        if spec.className == specName then
            return true
        end
    end

    return false
end

function ShelterMattersObjectDecay.hasMatchingSpecializations(vehicle)
    -- Ensure the vehicle and specializations exist
    if vehicle == nil or vehicle.specializations == nil then
        return false
    end

    -- Check required specializations (at least one must be present)
    local hasRequiredSpec = false

    for _, specName in ipairs(ShelterMatters.weatherAffectedSpecs) do
        if ShelterMattersObjectDecay.hasSpecialization(specName, vehicle.specializations) then
            hasRequiredSpec = true
            break -- Stop searching once we find a matching specialization
        end
    end

    -- If no required specializations were found, return false
    if not hasRequiredSpec then
        return false
    end

    -- Check excluded specializations
    for _, specName in ipairs(ShelterMatters.weatherExcludedSpecs) do
        if ShelterMattersObjectDecay.hasSpecialization(specName, vehicle.specializations) then
            return false -- If an excluded spec is found, return false
        end
    end

    -- Check excluded types
    for _, typeName in ipairs(ShelterMatters.weatherExcludedTypes) do
        if vehicle.typeName == typeName then
            return false -- If an excluded type is found, return false
        end
    end

    return true -- If all required specs are present and none of the excluded specs exist, return true
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

    return false -- If it's an open trailer, decay should still apply
end

function ShelterMattersObjectDecay:getDecayUnits()
    local spec = self[ShelterMattersObjectDecay.SPEC_TABLE_NAME]
    return spec.decayUnits
end

function ShelterMattersObjectDecay:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)
    if fillUnitIndex ~= 1 then
        -- we only care about fill index 1 at the moment. Multi index storage units are not checked.
        return
    end
    local fillLevel = self:getFillUnitFillLevel(fillUnitIndex)
    if fillLevel < 0.01 then -- we see this as good as empty
        -- reset wetness, bestBeforeDate, and fillLevelFull when the vehicle is empty
        spec.decayUnits[fillUnitIndex]:reset()
    end
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
