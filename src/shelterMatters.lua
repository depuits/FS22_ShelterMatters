-- @Author: Depuits
-- @Version: 1.0.0.0

ShelterMatters = {};
ShelterMatters.name = g_currentModName;
ShelterMatters.modDirectory = g_currentModDirectory

addModEventListener(ShelterMatters);

function ShelterMatters.init()
    Logging.info("[shelterMatters] registering mod functions")
    --Wearable.updateDamageAmount = Utils.overwrittenFunction(Wearable.updateDamageAmount, ShelterMatters.updateDamageAmount)

    ShelterMatters.insideIcon = createImageOverlay(ShelterMatters.modDirectory .. "src/insideIcon.dds")
    ShelterMatters.outsideIcon = createImageOverlay(ShelterMatters.modDirectory .. "src/outsideIcon.dds")
end

function ShelterMatters:draw()
    local vehicle = g_currentMission.controlledVehicle
    if vehicle then

        local uiScale = g_gameSettings:getValue("uiScale")

        --local startX = 1 - 0.0755 * uiScale + (0.04 * (uiScale - 0.5))
        local startX = 1 - 0.0535 * uiScale + (0.04 * (uiScale - 0.5))
        local startY = 0.05 * uiScale - (0.08 * (uiScale - 0.5))
        local iconWidth = 0.01 * uiScale
        local iconHeight = iconWidth * g_screenAspectRatio

        local isInside = ShelterMatters.isInShed(vehicle)
        local icon = isInside and ShelterMatters.insideIcon or ShelterMatters.outsideIcon

        renderOverlay(icon, startX, startY, iconWidth, iconHeight)
    end
end

function ShelterMatters:update(dt)
    local weatherMultiplier = ShelterMatters.weatherMultiplier()

    for _, vehicle in pairs(g_currentMission.vehicles) do
        ShelterMatters.updateDamageAmount(vehicle, dt, weatherMultiplier)
    end
end

function ShelterMatters.weatherMultiplier()
    local weatherSystem = g_currentMission.environment.weather
    local weatherType = weatherSystem:getCurrentWeatherType()

    --local weatherObject = weatherSystem.typeToWeatherObject[weatherType]
    --DebugUtil.printTableRecursively(weatherObject, "Wheater: ", 0, 1)

    -- Map the weather type to a string
    local weatherTypes = {
        [1] = "SUNNY",
        [2] = "RAIN",
        [3] = "CLOUDY",
        [4] = "FOG",
        [5] = "SNOW",
    }

    local weatherDescription = weatherTypes[weatherType] or "UNKNOWN"

    if weatherDescription == "RAIN" then
        -- Increase wear/damage when it's raining
        print("It's raining! Applying extra wear.")
        return 10
    elseif weatherDescription == "SNOW" then
        -- Normal conditions
        print("It's snowing.")
        return 5
    else
        -- Other weather types
        print("Weather: " .. weatherDescription)
        return 1
    end
end

function ShelterMatters.updateDamageAmount(vehicle, dt, multiplier)
    if not SpecializationUtil.hasSpecialization(Wearable, vehicle.specializations) then
        return
    end

    Logging.info("[shelterMatters] Entity type: " .. (vehicle.typeName or "unknown"))
    Logging.info("[shelterMatters] Entity name: " .. vehicle:getFullName())
    Logging.info("[shelterMatters] dmg: " .. tostring(vehicle:getDamageAmount()))
    Logging.info("[shelterMatters] active: " .. tostring(vehicle.isActive))
    Logging.info("[shelterMatters] operating: " .. tostring(vehicle:getIsOperating()))
    Logging.info("[shelterMatters] operatingtime: " .. tostring(vehicle.operatingTime))

    -- should be not active or not operating
    if vehicle.isActive and vehicle:getIsOperating() then
        Logging.info("[shelterMatters] in use, using default calculations")
        return
    end

    local inShed = ShelterMatters.isInShed(vehicle)

    if not inShed then
        local baseOutsideDamage = 0.00001
        local outsideDamage = (baseOutsideDamage * multiplier * dt) / 1000 -- divide by 1000 so values are dmg/second
        Logging.info("[shelterMatters] NOT in shed: " .. tostring(outsideDamage))

        vehicle:addDamageAmount(outsideDamage)
    else
        Logging.info("[shelterMatters] in shed ")
    end
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

        print(string.format(" placeable rot: x %.2f, y %.2f, z %.2f", rotX, rotY, rotZ))
        print(string.format(" start Node: x %.2f, y %.2f, z %.2f", startX, startY, startZ))
        print(string.format(" width Node: x %.2f, y %.2f, z %.2f", widthX, widthY, widthZ))
        print(string.format(" height Node: x %.2f, y %.2f, z %.2f", heightX, heightY, heightZ))
        print("withinX: " .. tostring(withinX))
        print("withinZ: " .. tostring(withinZ))

        print(string.format("Local Start: %.2f, %.2f", localStartX, localStartZ))
        print(string.format("Local Width: %.2f, %.2f", localWidthX, localWidthZ))
        print(string.format("Local Height: %.2f, %.2f", localHeightX, localHeightZ))
        print(string.format("Local Vehicle Position: %.2f, %.2f", localX, localZ))
        print(string.format("Bounds: X(%.2f, %.2f), Z(%.2f, %.2f)", minX, maxX, minZ, maxZ))
    end]]

    return withinX and withinZ
end

ShelterMatters.init()
