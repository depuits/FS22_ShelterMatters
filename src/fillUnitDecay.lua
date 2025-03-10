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
end

function FillUnitDecay.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getIsDecayProtected", FillUnitDecay.getIsDecayProtected)
    SpecializationUtil.registerFunction(vehicleType, "getIsPallet", FillUnitDecay.getIsPallet)
    SpecializationUtil.registerFunction(vehicleType, "isAffectedByWeather", FillUnitDecay.isAffectedByWeather)
    SpecializationUtil.registerFunction(vehicleType, "isTrailer", FillUnitDecay.isTrailer)
    SpecializationUtil.registerFunction(vehicleType, "getHasCover", FillUnitDecay.getHasCover)
    SpecializationUtil.registerFunction(vehicleType, "getIsCoverClosed", FillUnitDecay.getIsCoverClosed)
end

function FillUnitDecay.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "showInfo", FillUnitDecay.showInfo)
end

function FillUnitDecay.initSpecialization()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?)."..modName..".fillUnitDecay#lastDecayCheck", "Last time the decay was checked")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?)."..modName..".fillUnitDecay#spawnTime", "Time when the item has spawned")
end

function FillUnitDecay:onLoad(savegame)
    local spec = self[FillUnitDecay.SPEC_TABLE_NAME]
    local currentTime = g_currentMission.environment.dayTime

    spec.lastDecayCheck = currentTime
    spec.spawnTime = currentTime -- Used for spawn point grace period

    if savegame ~= nil then
        spec.lastDecayCheck = savegame.xmlFile:getValue(savegame.key .. "."..modName..".fillUnitDecay#lastDecayCheck", currentTime)
        spec.spawnTime = savegame.xmlFile:getValue(savegame.key .. "."..modName..".fillUnitDecay#spawnTime", currentTime)
    end 
end

function FillUnitDecay:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self[FillUnitDecay.SPEC_TABLE_NAME]
    xmlFile:setValue(key .. "#lastDecayCheck", spec.lastDecayCheck)
    xmlFile:setValue(key .. "#spawnTime", spec.spawnTime)
end

function FillUnitDecay:onUpdate(dt)
    if not self.isServer then
        return
    end

    local spec = self[FillUnitDecay.SPEC_TABLE_NAME]
    local currentTime = g_currentMission.environment.dayTime
    
    -- Only check decay every in-game minute
    if currentTime - spec.lastDecayCheck < 1000 * 60 then 
        return 
    end

--[[    if self.spec_cover then
        DebugUtil.printTableRecursively(self.spec_cover, "cover: ", 0, 1)
    end]]
    -- log vehicle stats
--[[    local inShed = ShelterMatters.isVehicleInShed(self)

    local fillType = self:getFillUnitFillType(1) -- Assume single fill unit for pallets
    local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillType)
    local fillLevel = self:getFillUnitFillLevel(1) -- Assume single fill unit for pallets

    local detailString = ("Entity type: " .. (self.typeName or "unknown") ..
        "\nEntity name: " .. self:getFullName() ..
        "\nfillType: " .. tostring(fillTypeDesc) ..
        "\nfillLevel: " .. tostring(fillLevel) ..
        "\nlastDecayCheck: " .. tostring(spec.lastDecayCheck) ..
        "\nisPallet: " .. tostring(self:getIsPallet()) ..
        "\ninShed: " .. tostring(inShed))

    print(detailString)]]

    spec.lastDecayCheck = currentTime
    
--[[    if self:getIsDecayProtected() then
        return
    end
    
    local decayRate = self:getDecayRate()
    if decayRate > 0 then
        self:applyDecay(decayRate)
    end]]
end

function FillUnitDecay:getIsDecayProtected()
    local spec = self[FillUnitDecay.SPEC_TABLE_NAME]

    -- Protection for spawn points (grace period)
    if g_currentMission.time - spec.spawnTime < 86400000 then
        return true
    end

    -- Check if the vehicle is enclosed (tanker or covered trailer)
--[[    if self:getIsEnclosedTrailer() then
        return true
    end]]

  --[[  -- Indoor protection
    if self:getIsInDoor() then
        return true
    end

    -- Optimal temperature protection
    if self:getIsInOptimalTemperature() then
        return true
    end]]

    return false
end

function FillUnitDecay:getHasCover()
    if self.spec_cover then
        return self.spec_cover.hasCovers
    end

    return false
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

function FillUnitDecay:getDecayRate()
    local weather = g_currentMission.environment.weather
    local temperature = g_currentMission.environment.weather:getCurrentTemperature()
    local fillType = self:getFillUnitFillType(1) -- Assume single fill unit for pallets
    
    local decayRates = {
        [FillType.MILK] = (temperature > 10) and 1.5 or 0,
        [FillType.BUTTER] = (temperature > 10) and 1.5 or 0,
        [FillType.CHEESE] = (temperature > 10) and 1.5 or 0,
        [FillType.YOGURT] = (temperature > 10) and 1.5 or 0,
        [FillType.EGGS] = (temperature > 15) and 1.2 or 0,
        [FillType.LETTUCE] = (temperature < 0 or temperature > 20) and 1.5 or 0,
        [FillType.TOMATOES] = (temperature < 0 or temperature > 20) and 1.5 or 0,
        [FillType.STRAWBERRIES] = (temperature < 0 or temperature > 20) and 1.5 or 0,
        [FillType.HONEY] = (temperature > 30) and 1.5 or 0,
        [FillType.GRAPE_JUICE] = (temperature > 30) and 1.5 or 0,
        [FillType.WINE] = (temperature > 30) and 1.5 or 0,
    }
    
    local baseDecay = decayRates[fillType] or 0
    --[[if weather:getIsRaining() or weather:getIsSnowing() or weather:getIsFoggy() then
        baseDecay = baseDecay * 2 -- Increase decay during bad weather
    end]]
    
    return baseDecay
end

function FillUnitDecay:applyDecay(rate)
    local spec = self.spec_fillUnit
    if spec and spec.fillUnits then
        for _, fillUnit in pairs(spec.fillUnits) do
            fillUnit.fillLevel = math.max(0, fillUnit.fillLevel - rate)
        end
    end
end

function FillUnitDecay:getIsPallet()
    return self.typeName == "pallet" or self.typeName == "treeSaplingPallet" or self.typeName == "bigBag"
end

function FillUnitDecay:showInfo(superFunc, box)
    local decayPercentage = 0

    box:addLine(g_i18n:getText("SM_InfoBaleDecay"), string.format("%d%%", decayPercentage * 100))
    box:addLine("type", tostring(self.typeName))
    box:addLine("isAffected", tostring(self:isAffectedByWeather()))
    box:addLine("isTrailer", tostring(self:isTrailer()))
    box:addLine("hasCover", tostring(self:getHasCover()))
    box:addLine("isCoverClosed", tostring(self:getIsCoverClosed()))

    local row = 0
    local x, y = 0.05, 0.85 -- Screen position
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1) -- White color
    renderText(x, y, 0.01, "SPECS:")
    local index = 0
    local rowCount = 25
    for _, spec in pairs(self.specializations) do
        if spec ~= nil and spec.className ~= nil then
            index = index + 1

            local col = math.floor(index / rowCount)
            local row = math.fmod(index, rowCount)

            renderText(x + col * 0.1, y - row * 0.02, 0.01, spec.className)
        end
    end

    superFunc(self, box)
end

function FillUnitDecay:isAffectedByWeather()
    -- Pallets and bigbags are affected, treeSaplingPallets are not affected
    if self.typeName == "pallet" or self.typeName == "bigBag" then
        return true
    end

    -- Check if the vehicle has a cover, all trailers have the cover spec
    if self.spec_cover then
        -- Check if the vehicle is a known closed tanker/container
        -- TODO get from config
        if self.typeName == "tankerTrailer" or self.typeName == "liquidTrailer" or self.typeName == "waterTrailer" then
            return false
        end

        return true
    end

    return false -- all other items are not affected
end

function FillUnitDecay:isTrailer()
    if self.spec_trailer then
        return true
    end

    return false -- all other items are not affected
end
