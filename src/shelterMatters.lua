-- @Author: Depuits

ShelterMatters = {}
ShelterMatters.name = g_currentModName
ShelterMatters.modDirectory = g_currentModDirectory
ShelterMatters.lastUpdateInGameTime = nil -- Global variable to track the last update time

ShelterMatters.isDevBuild = true -- Default is true; overridden by the build process if not in dev mode.

-- default values for weather multipliers
ShelterMatters.weatherMultipliers = {
    sunny  = 1.0, -- normal wear. vehicles experience no additional wear in sunny conditions.
    cloudy = 1.0, -- normal wear. cloudy weather has no impact on wear rates.
    fog    = 1.5, -- increased wear. moisture in the air leads to slightly accelerated wear.
    snow   = 2.0, -- increased wear. freezing and thawing cycles cause more significant wear.
    rain   = 5.0  -- severe increase in wear. constant moisture can cause rust and damage quickly.
}

-- percentage of damage added to vehicle per game year
ShelterMatters.damageRates = {
    default = 10,   -- 10% damage per in-game year when left outside. 
                    -- Represents general wear and tear for most vehicles.
    tractor = 10,            -- 10% damage per in-game year. Tractors are durable but still wear down from exposure.
    car = 10,                -- 10% damage per in-game year. Cars are durable but still wear down from exposure.
    combineHarvester = 20,   -- 20% damage per in-game year. Harvesters are complex machines and wear more quickly outdoors.
    plow = 15,               -- 15% damage per in-game year. Plows are exposed to elements and have high wear due to frequent use.
    seeder = 12,             -- 12% damage per in-game year. Seeders are moderately complex and exposed to moisture.
    harvester = 20,          -- 20% damage per in-game year. Similar to combine harvesters, they have a lot of moving parts.
    cultivator = 10,         -- 10% damage per in-game year. Cultivators are exposed to the weather but not as fragile as seeders.
    baler = 15,              -- 15% damage per in-game year. Balers experience wear due to the outdoor environment and usage.
    mower = 10,              -- 10% damage per in-game year. Mowers experience some wear but are typically more robust.
    sprayer = 12,            -- 12% damage per in-game year. Sprayers are delicate and prone to wear when exposed to elements.
    windrower = 10,          -- 10% damage per in-game year. Windrowers are generally durable, but moisture affects them.
    fertilizerSpreader = 10, -- 10% damage per in-game year. Fertilizer spreaders are susceptible to wear but not highly fragile.
    slurrySpreader = 15,     -- 15% damage per in-game year. Similar to fertilizer spreaders, but with more components exposed to the elements.
    manureSpreader = 15,     -- 15% damage per in-game year. Similar to slurry spreaders, susceptible to rust and wear.
    seedDrill = 12,          -- 12% damage per in-game year. Seed drills experience wear from being outdoors for long periods.
    stonePicker = 10,        -- 10% damage per in-game year. Stone pickers are durable but still affected by weather.
    vehicle = 10,            -- 10% damage per in-game year. General vehicle category; typical wear and tear from outdoor exposure.
    transport = 5,           -- 5% damage per in-game year. Transport vehicles experience minimal wear outdoors.
    trailer = 5,             -- 5% damage per in-game year. Trailers experience minimal wear outdoors.
    balerWrapper = 10,       -- 10% damage per in-game year. Bale wrappers experience moderate wear from exposure to weather.
}

addModEventListener(ShelterMatters)

function ShelterMatters.log(message, ...)
    if ShelterMatters.isDevBuild then
        Logging.info(string.format("[shelterMatters] " .. message, ...))
    end
end

function ShelterMatters:loadMap(name)
    ShelterMatters.log("loadMap: " .. name)

    ShelterMatters.insideIcon = createImageOverlay(ShelterMatters.modDirectory .. "src/insideIcon.dds")
    ShelterMatters.outsideIcon = createImageOverlay(ShelterMatters.modDirectory .. "src/outsideIcon.dds")

    if g_currentMission:getIsServer() then
        FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, ShelterMatters.save)
   
        self:loadConfig()
    else
        ShelterMattersSyncEvent.sendToServer()
    end
end

function ShelterMatters.save()
    if g_currentMission:getIsServer() then
        ShelterMatters:saveConfig()
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


        local childVehicles = vehicle.rootVehicle.childVehicles

        for i = 1, #childVehicles do
            local childVehicle = childVehicles[i]

            if childVehicle.getIsSelected ~= nil and childVehicle:getIsSelected() then
                vehicle = childVehicle
            end
        end

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

function ShelterMatters:weatherMultiplier(debugPrint)
    local weatherSystem = g_currentMission.environment.weather
    local weatherType = weatherSystem:getCurrentWeatherType()

    --local weatherObject = weatherSystem.typeToWeatherObject[weatherType]
    --DebugUtil.printTableRecursively(weatherObject, "Wheater: ", 0, 1)

    -- Map the weather type to a string
    -- TODO debug if these values are correct
    local weatherTypes = {
        [1] = "sunny",
        [2] = "cloudy",
        [3] = "rain",
        [4] = "fog",
        [5] = "snow",
    }

    local weatherDescription = weatherTypes[weatherType] or "UNKNOWN"
    local multiplier = self.weatherMultipliers[weatherDescription] or 1

    if debugPrint then
        print(string.format("Weather: %s, applying multiplier: %.2f", weatherDescription, multiplier))
    else
        ShelterMatters.log(string.format("Weather: %s, applying multiplier: %.2f", weatherDescription, multiplier))
    end

    return multiplier
end

function ShelterMatters:getVehicleDetailsString(vehicle)
    local typeName = vehicle.typeName
    local damageRate = self.damageRates[typeName] or self.damageRates.default

    local inShed = ShelterMatters.isInShed(vehicle)

    return ("Entity type: " .. (vehicle.typeName or "unknown") ..
        "\nEntity name: " .. vehicle:getFullName() ..
        "\ndmg: " .. tostring(vehicle:getDamageAmount()) ..
        "\nactive: " .. tostring(vehicle.isActive) ..
        "\noperating: " .. tostring(vehicle:getIsOperating()) ..
        "\noperatingtime: " .. tostring(vehicle.operatingTime) ..
        "\ndamageRate: " .. tostring(damageRate) ..
        "\ninShed: " .. tostring(inShed))
end

function ShelterMatters:updateDamageAmount(vehicle, elapsedInGameHours, multiplier)
    if not SpecializationUtil.hasSpecialization(Wearable, vehicle.specializations) then
        return
    end

    ShelterMatters.log(self:getVehicleDetailsString(vehicle))

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
    local damageRateScaled = damageRate / 100 / 24 / g_currentMission.environment.daysPerPeriod / 12
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
        return savegameDir .. "/shelterMatters.xml"
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
        local key = string.format("ShelterMatters.damageRates.rate(%d)", i)
        setXMLString(xmlFile, key .. "#type", typeName)
        setXMLFloat(xmlFile, key .. "#rate", rate)
        i = i + 1
    end

    i = 0 -- reset i counter
    for weatherType, multiplier in pairs(self.weatherMultipliers) do
        local key = string.format("ShelterMatters.weatherMultipliers.multiplier(%d)", i)
        setXMLString(xmlFile, key .. "#type", weatherType)
        setXMLFloat(xmlFile, key .. "#multiplier", multiplier)
        i = i + 1
    end

    saveXMLFile(xmlFile)
    delete(xmlFile)

    Logging.info("[shelterMatters] Configuration saved to: " .. configFile)
end

function ShelterMatters:loadConfig()
    local configFile = self:getSavegameConfigPath()
    if not configFile then
        Logging.warning("[shelterMatters] Unable to save config: Savegame directory not found.")
        return
    end

    if not fileExists(configFile) then
        Logging.info("[shelterMatters] Configuration file not found. Using defaults.")
        self:saveConfig()
        return
    end

    local xmlFile = loadXMLFile("ShelterMattersConfig", configFile)
    local i = 0
    while true do
        local key = string.format("ShelterMatters.damageRates.rate(%d)", i)
        local typeName = getXMLString(xmlFile, key .. "#type")
        if typeName == nil then
            break -- Exit when no more child nodes are found
        end

        local rate = getXMLFloat(xmlFile, key .. "#rate")
        if rate then
            self.damageRates[typeName] = rate
        end

        i = i + 1
    end

    i = 0 -- reset i counter
    while true do
        local key = string.format("ShelterMatters.weatherMultipliers.multiplier(%d)", i)
        local weatherType = getXMLString(xmlFile, key .. "#type")
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
    Logging.info("[shelterMatters] Configuration loaded from: " .. configFile)
end

--[[
    Console commands
]]

addConsoleCommand("smSetDamageRate", "Changes the damage rate for a specific vehicle type", "smSetDamageRate", ShelterMatters)
function ShelterMatters:smSetDamageRate(typeName, newRate)
    if not g_currentMission:getIsServer() then
        print("Changes can only be done on the server.")
        return
    end

    -- Validate the input
    newRate = tonumber(newRate)
    if not newRate or newRate < 0 then
        print("Invalid damage rate. Must be a positive number.")
        return
    end

    -- Update the rate
    self.damageRates[typeName] = newRate
    print(string.format("Updated damage rate for type '%s' to %.1f", typeName, newRate))

    ShelterMattersSyncEvent.sendToClients()
end

addConsoleCommand("smSetWeatherMultiplier", "Updates the wear multiplier associated with a specific weather type", "smSetWeatherMultiplier", ShelterMatters)
function ShelterMatters:smSetWeatherMultiplier(weatherType, newMultiplier)
    if not g_currentMission:getIsServer() then
        print("Changes can only be done on the server.")
        return
    end

    -- Validate the input
    newMultiplier = tonumber(newMultiplier)
    if not newMultiplier or newMultiplier < 0 then
        print("Invalid multiplier. Must be a positive number.")
        return
    end

    -- Update the rate
    self.weatherMultipliers[weatherType] = newMultiplier
    print(string.format("Updated weather multiplier for type '%s' to %.2f", weatherType, newMultiplier))

    ShelterMattersSyncEvent.sendToClients()
end

addConsoleCommand("smVehicleDetails", "Displays detailed information about a the vehicle currently being used and attached implements", "smVehicleDetails", ShelterMatters)
function ShelterMatters:smVehicleDetails()
    local vehicle = g_currentMission.controlledVehicle
    if vehicle then
        print(self:getVehicleDetailsStringRecursive(vehicle, ""))
    else
        print("Currently not in vehicle")
    end
end

function ShelterMatters:getVehicleDetailsStringRecursive(vehicle, indent, prev)
    prev = prev or ""
    if vehicle then
        prev = prev .. indent .. " " .. self:getVehicleDetailsString(vehicle):gsub("\n", "\n" .. indent .. " ")
        local implements = vehicle:getAttachedImplements()
        if implements and #implements > 0 then
            prev = prev .. "\n" .. indent .. " Attached implements:\n"
            for _, implement in ipairs(implements) do
                local implementObject = implement.object
                if implementObject then
                    prev = self:getVehicleDetailsStringRecursive(implementObject, indent .. "-", prev)
                end
            end
        else
            prev = prev .. "\n" .. indent .. " No implements attached.\n"
        end
    end

    return prev
end


addConsoleCommand("smCurrentWeather", "Displays the current weather conditions and their associated multiplier", "smCurrentWeather", ShelterMatters)
function ShelterMatters:smCurrentWeather()
    self:weatherMultiplier(true)
end

addConsoleCommand("smListDamageRates", "Lists the current damage rates for all vehicle types", "smListDamageRates", ShelterMatters)
function ShelterMatters:smListDamageRates()
    print("=== Current Damage Rates ===")
    for typeName, rate in pairs(self.damageRates) do
        print(string.format("Type: %s, Rate: %.2f", typeName, rate))
    end
    print("=== End of List ===")
end

addConsoleCommand("smListWeatherMultipliers", "Lists the current weather multipliers, showing how different weather conditions impact vehicle wear", "smListWeatherMultipliers", ShelterMatters)
function ShelterMatters:smListWeatherMultipliers()
    print("=== Current Weather Multipliers ===")
    for weatherType, multiplier in pairs(self.weatherMultipliers) do
        print(string.format("Weather: %s, Multiplier: %.2f", weatherType, multiplier))
    end
    print("=== End of List ===")
end
