
-- @Author: Depuits
-- @Version: 1.0.0.0


ShelterMatters = {};
ShelterMatters.name = g_currentModName;
ShelterMatters.modDirectory = g_currentModDirectory
--source(g_currentModDirectory .. "loadMaintenanceSettingsEvent.lua")

function ShelterMatters.init()
    Logging.info("[shelterMatters] registering mod functions")
    Wearable.updateDamageAmount = Utils.overwrittenFunction(Wearable.updateDamageAmount, ShelterMatters.updateDamageAmount)
end

function ShelterMatters.weatherMultiplier()
    local weatherSystem = g_currentMission.environment.weather
    local weatherType = weatherSystem:getCurrentWeatherType()
    local weatherObject = weatherSystem.typeToWeatherObject[weatherType]

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
    elseif weatherDescription == "SNOW" then
        -- Normal conditions
        print("It's snowing.")
    else
        -- Other weather types
        print("Weather: " .. weatherDescription)
    end
end

function ShelterMatters.updateDamageAmount(wearable, superFunc, dt)
    local damage = wearable:getDamageAmount()

    ShelterMatters.weatherMultiplier()

    local inShed = ShelterMatters.isInShed(wearable)

    local vx, vy, vz = getWorldTranslation(wearable.rootNode)

    Logging.info("[shelterMatters] Entity type: " .. (wearable.typeName or "unknown"))
    Logging.info("[shelterMatters] Entity name: " .. wearable:getFullName())
    Logging.info("[shelterMatters] pos: " .. string.format("x %.2f, y %.2f, z %.2f", vx, vy, vz))
    Logging.info("[shelterMatters] dmg: " .. tostring(damage))
    Logging.info("[shelterMatters] active: " .. tostring(wearable.isActive))
    Logging.info("[shelterMatters] operating: " .. tostring(wearable:getIsOperating()))
    Logging.info("[shelterMatters] operatingtime: " .. tostring(wearable.operatingTime))
    Logging.info("[shelterMatters] inshed: " .. tostring(inShed))

    --getDamageAmount
    --getVehicleDamage
    -- isActive

    -- Apply gradual damage if outside and in bad weather
    --if self:isOutside() and self:isBadWeather() then
    --end

    -- should be not active or not operating
    if not wearable.isActive then
        -- Example: Apply passive damage if outside a shed
        if not inShed then
            Logging.info(string.format("[shelterMatters] %s NOT shed with damage " .. (wearable.damage or "unknown"), wearable:getFullName()))
            -- wearable.damage = math.min(wearable.damage + (0.0001 * dt), 1.0) -- Increment passive damage
            -- setDamageAmount
            -- addDamageAmount
        else
            Logging.info(string.format("[shelterMatters] %s in shed with damage " .. (wearable.damage or "unknown"), wearable:getFullName()))
        end
    else
        Logging.info(string.format("[shelterMatters] %s in use, using default calculations", wearable:getFullName()))
    end


    -- Call original update logic
    return superFunc(wearable, dt)
end


function ShelterMatters.isInShed(vehicle)
    for _, placeable in pairs(g_currentMission.placeableSystem.placeables) do
        if ShelterMatters.isVehicleInsideIndoorArea(vehicle, placeable) then
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


    local distance = calculateDistance(x, y, z, startX, startY, startZ)

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
    end

    return withinX and withinZ
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



















function ShelterMatters.isInsideBounds(x, y, z, placeable)
    -- Get the rotation of the placeable
    local placeableRotation = { getWorldRotation(placeable.rootNode) }
    
    -- Translate the vehicle position relative to the placeable's position
    local placeableX, placeableY, placeableZ = getWorldTranslation(placeable.rootNode)
    local localX, localY, localZ = worldToLocal(
        placeable.rootNode,
        x, y, z
    )

    DebugUtil.printTableRecursively(placeable, "[shelterMatters] placeable: ", 0, 1)

    Logging.info("[shelterMatters] localX: " .. localX )
    Logging.info("[shelterMatters] localZ: " .. localZ )

    -- Get the bounding box of the placeable
    local bounds = ShelterMatters.calculateBoundingBox(placeable.rootNode)


    DebugUtil.printTableRecursively(bounds, "[shelterMatters] bounds: ", 0, 1)

    -- Check if the vehicle's position in local space falls within the bounding box
    if localX >= bounds.min.x and localX <= bounds.max.x and
       localZ >= bounds.min.z and localZ <= bounds.max.z then
        Logging.info("[shelterMatters] in shed: " .. (placeable.typeName or "unknown") )
        return true
    end

    return false
end


ShelterMatters.init()
