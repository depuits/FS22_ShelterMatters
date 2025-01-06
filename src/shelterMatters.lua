-- @Author: Depuits

ShelterMatters = {}
ShelterMatters.name = g_currentModName
ShelterMatters.modDirectory = g_currentModDirectory
ShelterMatters.lastUpdateInGameTime = nil -- Global variable to track the last update time

-- default values for weather multipliers
ShelterMatters.weatherMultipliers = {
    SUNNY = 1,
    CLOUDY = 1,
    FOG = 1.5,
    SNOW = 5,
    RAIN = 10,
}

ShelterMatters.damageRates = {
    default = 10, -- Default damage rate
}

ShelterMatters.isDevBuild = true -- Default is true; overridden by the build process if not in dev mode.

addModEventListener(ShelterMatters)

function ShelterMatters.log(message, ...)
    if ShelterMatters.isDevBuild then
        Logging.info(string.format("[shelterMatters] " .. message, ...))
    end
end

function ShelterMatters:loadMap(name)
    ShelterMatters.log("loading map")
end

function ShelterMatters.init()
    ShelterMatters.log("registering mod functions")

    ShelterMatters.insideIcon = createImageOverlay(ShelterMatters.modDirectory .. "src/insideIcon.dds")
    ShelterMatters.outsideIcon = createImageOverlay(ShelterMatters.modDirectory .. "src/outsideIcon.dds")

    if g_currentMission:getIsServer() then
        self:loadConfig()
    end
end

function ShelterMatters:draw()
    local vehicle = g_currentMission.controlledVehicle
    if vehicle then
        local uiScale = g_gameSettings:getValue("uiScale")

        local startX = 1 - 0.0535 * uiScale + (0.04 * (uiScale - 0.5))
        local startY = 0.05 * uiScale - (0.08 * (uiScale - 0.5))
        local iconWidth = 0.01 * uiScale
        local iconHeight = iconWidth * g_screenAspectRatio

        local isInside = ShelterMatters.isInShed(vehicle)
        local icon = isInside and ShelterMatters.insideIcon or ShelterMatters.outsideIcon

        renderOverlay(icon, startX, startY, iconWidth, iconHeight)
    end
end

--[[
Base logic
]]
function ShelterMatters:update(dt)
    if not g_currentMission:getIsServer() then
        return -- Skip on clients
    end
    
    -- Get the current in-game time in hours
    local currentInGameTime = g_currentMission.environment.dayTime / (60 * 60 * 1000) -- ms to hours

    -- Initialize the lastUpdateInGameTime if this is the first run
    if self.lastUpdateInGameTime == nil then
        self.lastUpdateInGameTime = currentInGameTime
        return -- No update needed on the first run
    end

    -- Calculate the elapsed in-game hours
    local elapsedInGameHours = currentInGameTime - self.lastUpdateInGameTime
    if elapsedInGameHours < 0 then
        elapsedInGameHours = elapsedInGameHours + 24 -- Handle midnight rollover
    end

    -- Update last recorded in-game time
    self.lastUpdateInGameTime = currentInGameTime

    -- Skip if no time has passed
    if elapsedInGameHours <= 0 then
        return
    end

    -- Get effect of the current weather
    local weatherMultiplier = self:weatherMultiplier()

    -- Apply the damages to vehicles left outside
    for _, vehicle in pairs(g_currentMission.vehicles) do
        self:updateDamageAmount(vehicle, elapsedInGameHours, weatherMultiplier)
    end
end

function ShelterMatters:weatherMultiplier()
    local weatherSystem = g_currentMission.environment.weather
    local weatherType = weatherSystem:getCurrentWeatherType()

    --local weatherObject = weatherSystem.typeToWeatherObject[weatherType]
    --DebugUtil.printTableRecursively(weatherObject, "Wheater: ", 0, 1)

    -- Map the weather type to a string
    -- TODO debug if these values are correct
    local weatherTypes = {
        [1] = "SUNNY",
        [2] = "CLOUDY",
        [3] = "RAIN",
        [4] = "FOG",
        [5] = "SNOW",
    }

    local weatherDescription = weatherTypes[weatherType] or "UNKNOWN"
    local multiplier = self.weatherMultipliers[weatherDescription] or 1

    ShelterMatters.log(string.format("Weather: %s, applying multiplier: %.2f", weatherDescription, multiplier))
    return multiplier
end

function ShelterMatters:updateDamageAmount(vehicle, elapsedInGameHours, multiplier)
    if not SpecializationUtil.hasSpecialization(Wearable, vehicle.specializations) then
        return
    end

    ShelterMatters.log("Entity type: " .. (vehicle.typeName or "unknown"))
    ShelterMatters.log("Entity name: " .. vehicle:getFullName())
    ShelterMatters.log("dmg: " .. tostring(vehicle:getDamageAmount()))
    ShelterMatters.log("active: " .. tostring(vehicle.isActive))
    ShelterMatters.log("operating: " .. tostring(vehicle:getIsOperating()))
    ShelterMatters.log("operatingtime: " .. tostring(vehicle.operatingTime))

    -- should be not active or not operating
    if vehicle.isActive and vehicle:getIsOperating() then
        ShelterMatters.log("in use, using default calculations")
        return
    end

    local inShed = ShelterMatters.isInShed(vehicle)

    if not inShed then
        local baseOutsideDamage = self:getDamageRate(vehicle) -- damage percentage per ingame hour
        local outsideDamage = (baseOutsideDamage * multiplier * elapsedInGameHours)
        ShelterMatters.log("NOT in shed: " .. tostring(outsideDamage))

        vehicle:addDamageAmount(outsideDamage)
    else
        ShelterMatters.log("in shed ")
    end
end

function ShelterMatters:getDamageRate(vehicle)
    local typeName = vehicle.typeName
    local damageRate = self.damageRates[typeName] or self.damageRates.default

    -- calculate float percentage = value / percentage / hours / days / months
    local damageRateScaled = damageRate / 100 / 24 / g_currentMission.environment.daysPerMonth / 12
    return damageRateScaled
end

function ShelterMatters.isInShed(vehicle)
    for _, placeable in pairs(g_currentMission.placeableSystem.placeables) do
        if ShelterMatters.isVehicleInsideIndoorArea(vehicle, placeable) then
            return true
        end
    end
    return false
end

-- Function to check if a vehicle is inside any indoor area of a placeable
function ShelterMatters.isVehicleInsideIndoorArea(vehicle, placeable)
    if not placeable.spec_indoorAreas or not placeable.spec_indoorAreas.areas then
        --Logging.info("[shelterMatters] placeable: " .. (placeable.typeName or "unknown") .. " has no indoor areas")
        return false
    end

    -- Get the vehicle's position
    local vx, vy, vz = getWorldTranslation(vehicle.rootNode)

    -- Check all indoor areas
    for _, indoorArea in ipairs(placeable.spec_indoorAreas.areas) do
        if ShelterMatters.isPointInsideIndoorArea(vx, vy, vz, indoorArea, placeable) then
            --Logging.info("[shelterMatters] placeable: " .. (placeable.typeName or "unknown") .. Vehicle is inside.")
            return true
        end
    end

    return false
end

-- Function to calculate distance between two points in 3D space
local function calculateDistance(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function ShelterMatters.isPointInsideIndoorArea(x, y, z, indoorArea, placeable)
    -- Get the position and rotation of the root node
    local rootX, rootY, rootZ = getWorldTranslation(placeable.rootNode)
    local rotX, rotY, rotZ = getWorldRotation(placeable.rootNode)

    -- Get world positions of width and height nodes
    local startX, startY, startZ = getWorldTranslation(indoorArea.start)
    local widthX, widthY, widthZ = getWorldTranslation(indoorArea.width)
    local heightX, heightY, heightZ = getWorldTranslation(indoorArea.height)

    -- Translate nodes to the root node's local space
    local function transformToLocalSpace(worldX, worldY, worldZ)
        local relX, relY, relZ = worldX - rootX, worldY - rootY, worldZ - rootZ

        -- Apply rotation around the root node
        local cosY = math.cos(-rotY)
        local sinY = math.sin(-rotY)

        local localX = relX * cosY - relZ * sinY
        local localZ = relX * sinY + relZ * cosY
        return localX, relY, localZ
    end

    -- Convert indoor area nodes to local space
    local localStartX, localStartY, localStartZ = transformToLocalSpace(startX, startY, startZ)
    local localWidthX, localWidthY, localWidthZ = transformToLocalSpace(widthX, widthY, widthZ)
    local localHeightX, localHeightY, localHeightZ = transformToLocalSpace(heightX, heightY, heightZ)
    local localX, localY, localZ = transformToLocalSpace(x, y, z)

    -- Compute all possible bounds (accounting for reversed nodes)
    local minX = math.min(localStartX, localWidthX, localHeightX)
    local maxX = math.max(localStartX, localWidthX, localHeightX)
    local minZ = math.min(localStartZ, localWidthZ, localHeightZ)
    local maxZ = math.max(localStartZ, localWidthZ, localHeightZ)

    -- Check if the position is within the axis-aligned bounds
    local withinX = localX >= minX and localX <= maxX
    local withinZ = localZ >= minZ and localZ <= maxZ

--[[    local distance = calculateDistance(x, y, z, startX, startY, startZ)

    if distance < 50 then
        Logging.info("[shelterMatters] placeable: " .. (placeable.typeName or "unknown") .. string.format(" Distance to Start Node: %.2f", distance))

        ShelterMatters.log(string.format(" placeable rot: x %.2f, y %.2f, z %.2f", rotX, rotY, rotZ))
        ShelterMatters.log(string.format(" start Node: x %.2f, y %.2f, z %.2f", startX, startY, startZ))
        ShelterMatters.log(string.format(" width Node: x %.2f, y %.2f, z %.2f", widthX, widthY, widthZ))
        ShelterMatters.log(string.format(" height Node: x %.2f, y %.2f, z %.2f", heightX, heightY, heightZ))
        ShelterMatters.log("withinX: " .. tostring(withinX))
        ShelterMatters.log("withinZ: " .. tostring(withinZ))

        ShelterMatters.log(string.format("Local Start: %.2f, %.2f", localStartX, localStartZ))
        ShelterMatters.log(string.format("Local Width: %.2f, %.2f", localWidthX, localWidthZ))
        ShelterMatters.log(string.format("Local Height: %.2f, %.2f", localHeightX, localHeightZ))
        ShelterMatters.log(string.format("Local Vehicle Position: %.2f, %.2f", localX, localZ))
        ShelterMatters.log(string.format("Bounds: X(%.2f, %.2f), Z(%.2f, %.2f)", minX, maxX, minZ, maxZ))
    end]]

    return withinX and withinZ
end




--[[
    Config saving and loading
]]

function ShelterMatters:getSavegameConfigPath()
    local savegameDir = g_currentMission.missionInfo.savegameDirectory
    if savegameDir then
        return savegameDir .. "/shelterMattersConfig.xml"
    else
        -- Fallback for unsaved games or missions without save directories
        return nil
    end
end

function ShelterMatters:saveConfig()
    local configFile = self:getSavegameConfigPath()
    if not configFile then
        Logging.warning("[shelterMatters] Unable to save config: Savegame directory not found.")
        return
    end

    local xmlFile = createXMLFile("ShelterMattersConfig", configFile, "ShelterMatters")

    local i = 0
    for typeName, rate in pairs(self.damageRates) do
        local key = string.format("ShelterMatters.damageRates.type(%d)", i)
        setXMLString(xmlFile, key .. "#typeName", typeName)
        setXMLFloat(xmlFile, key .. "#rate", rate)
        i = i + 1
    end

    i = 0 -- reset i counter
    for weatherType, multiplier in pairs(self.weatherMultipliers) do
        local key = string.format("ShelterMatters.weatherMultipliers.type(%d)", i)
        setXMLString(xmlFile, key .. "#typeName", weatherType)
        setXMLFloat(xmlFile, key .. "#multiplier", multiplier)
        i = i + 1
    end

    saveXMLFile(xmlFile)
    delete(xmlFile)

    ShelterMatters.log("Configuration saved to: " .. configFile)
end

function ShelterMatters:loadConfig()
    local configFile = self:getSavegameConfigPath()
    if not configFile or not fileExists(configFile) then
        ShelterMatters.log("Configuration file not found. Using defaults.")
        return
    end

    local xmlFile = loadXMLFile("ShelterMattersConfig", configFile)
    local i = 0
    while true do
        local key = string.format("ShelterMatters.damageRates.type(%d)", i)
        local typeName = getXMLString(xmlFile, key .. "#typeName")
        if typeName == nil then
            break
        end

        local rate = getXMLFloat(xmlFile, key .. "#rate")
        if rate then
            self.damageRates[typeName] = rate
        end

        i = i + 1
    end

    i = 0 -- reset i counter
    while true do
        local key = string.format("ShelterMatters.weatherMultipliers.type(%d)", i)
        local weatherType = getXMLString(xmlFile, key .. "#typeName")
        if not weatherType then
            break
        end

        local multiplier = getXMLFloat(xmlFile, key .. "#multiplier")
        if multiplier then
            self.weatherMultipliers[weatherType] = multiplier
        end

        i = i + 1
    end

    delete(xmlFile)
    ShelterMatters.log("Configuration loaded from: " .. configFile)
end




--[[
    Console commands
]]

function ShelterMatters:changeDamageRate(typeName, newRate)
    if not g_currentMission:getIsServer() then
        return
    end

    -- Validate the input
    newRate = tonumber(newRate)
    if not newRate or newRate < 0 then
        ShelterMatters.log("Invalid damage rate. Must be a positive number.")
        return
    end

    -- Update the rate
    self.damageRates[typeName] = newRate
    ShelterMatters.log("Updated damage rate for type '%s' to %.1f", typeName, newRate)

    -- Save the updated configuration
    self:saveConfig()
end

function ShelterMatters:changeWeatherMultiplier(weatherType, newMultiplier)
    if not g_currentMission:getIsServer() then
        return
    end

    -- Validate the input
    newMultiplier = tonumber(newMultiplier)
    if not newMultiplier or newMultiplier < 0 then
        ShelterMatters.log("Invalid multiplier. Must be a positive number.")
        return
    end

    -- Update the rate
    self.weatherMultipliers[weatherType] = newMultiplier
    ShelterMatters.log("Updated weather multiplier for type '%s' to %.2f", weatherType, newMultiplier)

    -- Save the updated configuration
    self:saveConfig()
end

function ShelterMatters:onChatCommand(command, arguments, playerId)
    if not g_currentMission:getIsServer() then
        return
    end

    if command == "sm_setDamageRate" then
        local typeName, newRate = unpack(arguments)
        if g_currentMission.userManager:getUserByUserId(playerId).isAdmin then
            self:changeDamageRate(typeName, newRate)
        else
            ShelterMatters.log("You do not have permission to execute this command.")
        end
    elseif command == "sm_setWeatherMultiplier" then
        local weatherType, newMultiplier = unpack(arguments)
        if g_currentMission.userManager:getUserByUserId(playerId).isAdmin then
            self:changeWeatherMultiplier(weatherType, newMultiplier)
        else
            ShelterMatters.log("You do not have permission to execute this command.")
        end
    end
end

ShelterMatters.init()
