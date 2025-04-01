-- @Author: Depuits

ShelterMatters = {
    COLLISION_MASK = 20
}
ShelterMatters.name = g_currentModName
ShelterMatters.modDirectory = g_currentModDirectory
ShelterMatters.lastUpdateInGameTime = nil -- Global variable to track the last update time

ShelterMatters.isDevBuild = true -- Default is true; overridden by the build process if not in dev mode.

ShelterMatters.hideShelterStatusIcon = false
ShelterMatters.palletSpawnProtection = 24 -- time in hours for spawned pallets to have decay and wetness protection

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

-- default values for wetness rates per game minute in weather conditions (expressed in %/min)
ShelterMatters.weatherWetnessRates = {
    default = 0.0,
    fog     = 0.1,
    snow    = 1.0,
    rain    = 2.0
}

-- properties defining which conditions can make item decay
ShelterMatters.decayProperties = {
    -- filled in on load
    --[[
        wetnessImpact = 1.5 -- Multiplier on weatherWetnessRates to make the weather impact more or less
        wetnessDecay = 4000 -- Amount of decay when fully wet (liters/month)
        bestBeforePeriod = 12,  -- Shelf life before decay starts (months)
        bestBeforeDecay = 2000 -- Decays after best-before period ended (liters/month)
        maxTemperature = 21 -- Maximum temperature the product stays good in (celcius)
        maxTemperatureDecay = 1000 -- Decay when product stays above the maximum temperature (liters/hour)
        minTemperature = -5 -- Minimum temperature the product stays good in (celcius)
        minTemperatureDecay = 1000 -- Decay when product stays under the minimum temperature (liters/hour)
    ]]--
}

ShelterMatters.weatherAffectedSpecs = { "shovel", "trailer" }
ShelterMatters.weatherExcludedSpecs = { "waterTrailer" }
ShelterMatters.weatherExcludedTypes = { }

ShelterMatters.vehicles = {}

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

    FSBaseMission.onConnectionFinishedLoading = Utils.appendedFunction(FSBaseMission.onConnectionFinishedLoading, ShelterMatters.loadSettingsFromServer)

    if g_currentMission:getIsServer() then
        FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, ShelterMatters.save)
   
        self:loadConfig()
    end

    ConstructionScreen.setBrush = Utils.appendedFunction(ConstructionScreen.setBrush, self.indoorAreasShow)
    ConstructionScreen.onClose = Utils.appendedFunction(ConstructionScreen.onClose, self.indoorAreasHide)

    --local abstractClass = PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_CLASS_NAME['Vehicle']
    --DebugUtil.printTableRecursively(abstractClass, "abstractClass: ", 0, 3)
end

function ShelterMatters.loadSettingsFromServer()
    ShelterMattersSyncEvent.sendToServer()
end

function ShelterMatters.indoorAreasShow()
    ShelterMatters:indoorAreasVisibility(true)
end
function ShelterMatters.indoorAreasHide()
    ShelterMatters:indoorAreasVisibility(false)
end

function ShelterMatters:indoorAreasVisibility(visible)
    ShelterMatters.shouldShowIndoorAreas = visible
    local allPlaceables = g_currentMission.placeableSystem.placeables

    for placeableIndex, placeable in ipairs(allPlaceables) do
        if placeable.spec_shelterMattersIndoorArea ~= nil  then
            setVisibility(placeable.spec_shelterMattersIndoorArea.helperNavMeshPlane, visible)
            self:updateRigidBodyType(placeable.spec_shelterMattersIndoorArea.collision, visible)
        end
    end
end

function ShelterMatters:updateRigidBodyType(node, visible)
    if node == nil then
        return
    end

    if visible then
        setRigidBodyType(node, RigidBodyType.STATIC)
        setCollisionMask(node, ShelterMatters.COLLISION_MASK)
    else
        setRigidBodyType(node, RigidBodyType.NONE)
    end
end

function ShelterMatters.save()
    if g_currentMission:getIsServer() then
        ShelterMatters:saveConfig()
    end
end

function ShelterMatters:draw()
    local vehicle = g_currentMission.controlledVehicle
    if vehicle and not self.hideShelterStatusIcon then

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

        local isInside = ShelterMatters.isObjectInShed(vehicle)
        local icon = isInside and ShelterMatters.insideIcon or ShelterMatters.outsideIcon

        renderOverlay(icon, startX, startY, iconWidth, iconHeight)
    end
end

function ShelterMatters:getWeather()
    local weatherSystem = g_currentMission.environment.weather
    local weatherType = weatherSystem:getCurrentWeatherType()

    -- Map the weather type to a string
    -- TODO debug if these values are correct
    local weatherTypes = {
        [1] = "sunny",
        [2] = "cloudy",
        [3] = "rain",
        [4] = "fog",
        [5] = "snow",
    }

    return weatherTypes[weatherType] or "UNKNOWN"
end

function ShelterMatters:getWeatherWetnessRate()
    local weather = self:getWeather()

    return self.weatherWetnessRates[weather] or self.weatherWetnessRates.default or 0
end

--[[
Base logic
]]
function ShelterMatters:update(dt)
    if not g_currentMission:getIsServer() then
        return -- Skip on clients
    end

    -- Apply the damages to bales left outside 
    self:updateAllBales()
    self:updateAllVehicles()

    -- Get the current in-game time in hours
    local currentInGameHours = g_currentMission.environment.dayTime / (60 * 60 * 1000) -- ms to hours


    -- Initialize the lastUpdateInGameTime if this is the first run
    if self.lastUpdateInGameTime == nil then
        self.lastUpdateInGameTime = currentInGameHours
        return -- No update needed on the first run
    end

    -- Calculate the elapsed in-game hours
    local elapsedInGameHours = currentInGameHours - self.lastUpdateInGameTime
    if elapsedInGameHours < 0 then
        elapsedInGameHours = elapsedInGameHours + 24 -- Handle midnight rollover
    end

    -- only execute the update logic once every ingame minute
    if elapsedInGameHours * 60 < 1 then
        return
    end

    -- Update last recorded in-game time
    self.lastUpdateInGameTime = currentInGameHours

    -- Get effect of the current weather
    local weather = self:getWeather()
    local weatherMultiplier = self.weatherMultipliers[weather] or 1

    -- Apply the damages to vehicles left outside
    for _, vehicle in pairs(g_currentMission.vehicles) do
        self:updateDamageAmount(vehicle, elapsedInGameHours, weatherMultiplier)
    end
end

function ShelterMatters:updateAllBales() 
    for _, saveItem in pairs(g_currentMission.itemSystem.itemsToSave) do
        -- Check if the object is a bale by checking its class name
        if saveItem.className == "Bale" then
            ShelterMattersObjectDecayFunctions.update(saveItem.item)
        end
    end
end

function ShelterMatters:updateAllVehicles()
    for _, vehicle in ipairs(ShelterMatters.vehicles) do
        ShelterMattersObjectDecayFunctions.update(vehicle)
    end
end

function ShelterMatters:getVehicleDetailsString(vehicle)
    local typeName = vehicle.typeName
    local damageRate = self.damageRates[typeName] or self.damageRates.default

    local inShed = ShelterMatters.isObjectInShed(vehicle)

    return ("Entity type: " .. (typeName or "unknown") ..
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

    -- should be not active or not operating
    if vehicle.isActive and vehicle:getIsOperating() then
        return
    end

    local inShed = ShelterMatters.isObjectInShed(vehicle)
    if not inShed then
        local baseOutsideDamage = self:getDamageRate(vehicle) -- damage percentage per ingame hour
        local outsideDamage = (baseOutsideDamage * multiplier * elapsedInGameHours)

        vehicle:addDamageAmount(outsideDamage)
    end
end

function ShelterMatters:getDamageRate(vehicle)
    local typeName = vehicle.typeName
    local damageRate = self.damageRates[typeName] or self.damageRates.default or 10

    -- calculate float percentage = value / percentage / hours / days / months
    local damageRateScaled = damageRate / 100 / 24 / g_currentMission.environment.daysPerPeriod / 12
    return damageRateScaled
end

function ShelterMatters.isObjectInShed(object, inShed) -- optional inShed parameter, if this is not nil then the inShed value will be returned else we will check in the world if we need to calculate the inShed
    if inShed == nil then
        return ShelterMattersIndoorDetection.isObjectInShed(object)
    else
        return inShed
    end
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

    setXMLBool(xmlFile, "ShelterMatters.hideShelterStatusIcon", self.hideShelterStatusIcon)

    setXMLInt(xmlFile, "ShelterMatters.palletSpawnProtection", self.palletSpawnProtection)

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

    i = 0 -- reset i counter
    for weatherType, rate in pairs(self.weatherWetnessRates) do
        local key = string.format("ShelterMatters.weatherWetnessRates.rate(%d)", i)
        setXMLString(xmlFile, key .. "#type", weatherType)
        setXMLFloat(xmlFile, key .. "#rate", rate)
        i = i + 1
    end

    i = 0 -- reset i counter
    for fillType, props in pairs(self.decayProperties) do
        local key = string.format("ShelterMatters.decayProperties.property(%d)", i)
        local fillTypeName = Utils.getNoNil(g_fillTypeManager:getFillTypeNameByIndex(fillType), "unknown")
        setXMLString(xmlFile, key .. "#type", fillTypeName)
        if props.wetnessImpact then setXMLFloat(xmlFile, key .. "#wetnessImpact", props.wetnessImpact) end
        if props.wetnessDecay then setXMLFloat(xmlFile, key .. "#wetnessDecay", props.wetnessDecay) end

        if props.bestBeforePeriod then setXMLInt(xmlFile, key .. "#bestBeforePeriod", props.bestBeforePeriod) end
        if props.bestBeforeDecay then setXMLFloat(xmlFile, key .. "#bestBeforeDecay", props.bestBeforeDecay) end

        if props.maxTemperature then setXMLInt(xmlFile, key .. "#maxTemperature", props.maxTemperature) end
        if props.maxTemperatureDecay then setXMLFloat(xmlFile, key .. "#maxTemperatureDecay", props.maxTemperatureDecay) end

        if props.minTemperature then setXMLInt(xmlFile, key .. "#minTemperature", props.minTemperature) end
        if props.minTemperatureDecay then setXMLFloat(xmlFile, key .. "#minTemperatureDecay", props.minTemperatureDecay) end

        i = i + 1
    end

    self:saveStringListToConfig(xmlFile, self.weatherAffectedSpecs, "weatherAffectedSpecs")
    self:saveStringListToConfig(xmlFile, self.weatherExcludedSpecs, "weatherExcludedSpecs")
    self:saveStringListToConfig(xmlFile, self.weatherExcludedTypes, "weatherExcludedTypes")

    saveXMLFile(xmlFile)
    delete(xmlFile)

    ShelterMatters.log("Configuration saved to: " .. configFile)
end

function ShelterMatters:loadConfig()
    -- initialize default decay properties
    self.decayProperties = ShelterMattersDefaultRules.loadDefaultDecayProperties()

    local configFile = self:getSavegameConfigPath()
    if not configFile then
        Logging.warning("[shelterMatters] Unable to save config: Savegame directory not found.")
        return
    end

    if not fileExists(configFile) then
        ShelterMatters.log("Configuration file not found. Using defaults.")
        self:saveConfig()
        return
    end

    local xmlFile = loadXMLFile("ShelterMattersConfig", configFile)

    self.hideShelterStatusIcon = Utils.getNoNil(getXMLBool(xmlFile, "ShelterMatters.hideShelterStatusIcon"), false)

    self.palletSpawnProtection = Utils.getNoNil(getXMLInt(xmlFile, "ShelterMatters.palletSpawnProtection"), self.palletSpawnProtection)

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

    i = 0 -- reset i counter
    while true do
        local key = string.format("ShelterMatters.weatherWetnessRates.rate(%d)", i)
        local weatherType = getXMLString(xmlFile, key .. "#type")
        if not weatherType then
            break
        end

        local rate = getXMLFloat(xmlFile, key .. "#rate")
        if rate then
            self.weatherWetnessRates[weatherType] = rate
        end


        i = i + 1
    end

    i = 0 -- reset i counter
    while true do
        local key = string.format("ShelterMatters.decayProperties.property(%d)", i)
        local fillTypeName = getXMLString(xmlFile, key .. "#type")
        if not fillTypeName then
            break
        end

        local fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

        local wetnessImpact = getXMLFloat(xmlFile, key .. "#wetnessImpact")
        local wetnessDecay = getXMLFloat(xmlFile, key .. "#wetnessDecay")
        local bestBeforePeriod = getXMLInt(xmlFile, key .. "#bestBeforePeriod")
        local bestBeforeDecay = getXMLFloat(xmlFile, key .. "#bestBeforeDecay")
        local maxTemperature = getXMLInt(xmlFile, key .. "#maxTemperature")
        local maxTemperatureDecay = getXMLFloat(xmlFile, key .. "#maxTemperatureDecay")
        local minTemperature = getXMLInt(xmlFile, key .. "#minTemperature")
        local minTemperatureDecay = getXMLFloat(xmlFile, key .. "#minTemperatureDecay")

        self.decayProperties[fillType] = {
            wetnessImpact = wetnessImpact,
            wetnessDecay = wetnessDecay,
            bestBeforePeriod = bestBeforePeriod,
            bestBeforeDecay = bestBeforeDecay,
            maxTemperature = maxTemperature,
            maxTemperatureDecay = maxTemperatureDecay,
            minTemperature = minTemperature,
            minTemperatureDecay = minTemperatureDecay
        }

        i = i + 1
    end

    self:loadStringListFromConfig(xmlFile, self.weatherAffectedSpecs, "weatherAffectedSpecs")
    self:loadStringListFromConfig(xmlFile, self.weatherExcludedSpecs, "weatherExcludedSpecs")
    self:loadStringListFromConfig(xmlFile, self.weatherExcludedTypes, "weatherExcludedTypes")

    delete(xmlFile)
    ShelterMatters.log("Configuration loaded from: " .. configFile)
end

function ShelterMatters:saveStringListToConfig(xmlFile, list, baseKey)
    local i = 0

    for _, value in ipairs(list) do
        local key = string.format("ShelterMatters." .. baseKey .. ".value(%d)", i)
        setXMLString(xmlFile, key .. "#value", value)
        i = i + 1
    end
end

function ShelterMatters:loadStringListFromConfig(xmlFile, list, baseKey)
    local i = 0
    local foundValues = false

    while true do
        local key = string.format("ShelterMatters." .. baseKey .. ".value(%d)", i)
        local value = getXMLString(xmlFile, key .. "#value")
        if not value then
            break
        end

        if not foundValues then
            -- Only clear the list if we find values in the save file
            table.clear(list)  -- Clears the list but only when values exist
            foundValues = true
        end

        table.insert(list, value) -- Adds new value to the list
        i = i + 1
    end
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
    print(string.format("Updated weather multiplier for '%s' to %.2f", weatherType, newMultiplier))

    ShelterMattersSyncEvent.sendToClients()
end

addConsoleCommand("smSetWeatherWetnessRates", "Updates the weather wetness rate associated with a specific weather type", "smSetWeatherWetnessRates", ShelterMatters)
function ShelterMatters:smSetWeatherWetnessRates(weatherType, newRate)
    if not g_currentMission:getIsServer() then
        print("Changes can only be done on the server.")
        return
    end

    -- Validate the input
    newRate = tonumber(newRate)
    if not newRate then
        print("Invalid multiplier.")
        return
    end

    -- Update the rate
    self.weatherWetnessRates[weatherType] = newRate
    print(string.format("Updated weather wetness rate for '%s' to %.2f %%/minute", weatherType, newRate))

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
    local weather = self:getWeather()
    local multiplier = self.weatherMultipliers[weather] or 1

    print(string.format("Weather: %s, applying multiplier: %.2f", weather, multiplier))
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

addConsoleCommand("smListWeatherWetnessRates", "Lists the wetness rates by weather, showing how different weather conditions impact products left outside", "smListWeatherWetnessRates", ShelterMatters)
function ShelterMatters:smListWeatherWetnessRates()
    print("=== Current Bale Decay by Weather ===")
    for weatherType, rate in pairs(self.weatherWetnessRates) do
        print(string.format("Weather: %s, Rate: %.2f %%/minute", weatherType, rate))
    end
    print("=== End of List ===")
end

addConsoleCommand("smToggleShelterStatusIcon", "Toggles the shelter status icon visibility", "smToggleShelterStatusIcon", ShelterMatters)
function ShelterMatters:smToggleShelterStatusIcon()
    if not g_currentMission:getIsServer() then
        print("Changes can only be done on the server.")
        return
    end

    self.hideShelterStatusIcon = not self.hideShelterStatusIcon
    ShelterMattersSyncEvent.sendToClients()
end

addConsoleCommand("smResetDecayProperties", "Reset all decay properties to the mods defaults", "smResetDecayProperties", ShelterMatters)
function ShelterMatters:smResetDecayProperties()
    if not g_currentMission:getIsServer() then
        print("Changes can only be done on the server.")
        return
    end

    self.decayProperties = ShelterMattersDefaultRules.loadDefaultDecayProperties()
    ShelterMattersSyncEvent.sendToClients()
end
