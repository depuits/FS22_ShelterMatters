-- @Author: Depuits

ShelterMattersIndoorDetection = {
}

function ShelterMattersIndoorDetection.isObjectInShed(object)
    return ShelterMattersIndoorDetection.isNodeInShed(object.rootNode or object.nodeId) -- vehicles use rootNode and bales use nodeId
end

function ShelterMattersIndoorDetection.isNodeInShed(node)
    -- Get the node's position
    local vx, vy, vz = getWorldTranslation(node)

    for _, placeable in pairs(g_currentMission.placeableSystem.placeables) do
        if ShelterMattersIndoorDetection.isPointInsideplaceable(vx, vy, vz, placeable) then
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

-- Function to check if a vehicle is inside any indoor area of a placeable
function ShelterMattersIndoorDetection.isPointInsideplaceable(x, y, z, placeable)
    if not placeable.spec_indoorAreas or not placeable.spec_indoorAreas.areas then
        return false
    end

    local rootX, rootY, rootZ = getWorldTranslation(placeable.rootNode)
    local distance = calculateDistance(x, y, z, rootX, rootY, rootZ)
    -- optimization: no shed is bigger then 200 meters so we don't check when obtjects are further away then 100m from the placeable center
    if distance > 100 then
        return false
    end

    -- Check all indoor areas
    for _, indoorArea in ipairs(placeable.spec_indoorAreas.areas) do
        if ShelterMattersIndoorDetection.isPointInsideIndoorArea(x, y, z, indoorArea, placeable) then
            return true
        end
    end

    return false
end

function ShelterMattersIndoorDetection.isPointInsideIndoorArea(x, y, z, indoorArea, placeable)
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

    return withinX and withinZ
end
