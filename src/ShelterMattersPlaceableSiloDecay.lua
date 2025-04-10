local modName = g_currentModName

ShelterMattesPlaceableSiloDecay = {}
ShelterMattesPlaceableSiloDecay.SPEC_TABLE_NAME = "spec_" .. modName .. ".objectRotate"

function ShelterMattesPlaceableSiloDecay.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Silo, specializations)
end

function ShelterMattesPlaceableSiloDecay.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "updateBestBefore", ShelterMattesPlaceableSiloDecay.updateBestBefore)
end

function ShelterMattesPlaceableSiloDecay.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", ShelterMattesPlaceableSiloDecay.updateInfo)
end

function ShelterMattesPlaceableSiloDecay.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", ShelterMattesPlaceableSiloDecay)
    SpecializationUtil.registerEventListener(placeableType, "onUpdate", ShelterMattesPlaceableSiloDecay)
end

function ShelterMattesPlaceableSiloDecay:onLoad(savegame)
    self.spec_bestBeforeSilo = {
        lastDecayCheck = 0
    }
end

function ShelterMattesPlaceableSiloDecay:onUpdate(dt)
    if not self.storage then return end

    local storageId = tostring(self.storage)
    if BestBeforeStorageManager.storageData[storageId] == nil then
        BestBeforeStorageManager.storageData[storageId] = {}
    end

    local currentTime = g_currentMission.environment.time

    for fillTypeIndex, fillLevel in pairs(self.storage.fillLevels) do
        if fillLevel > 0 then
            local data = BestBeforeStorageManager.storageData[storageId][fillTypeIndex]
            if not data then
                BestBeforeStorageManager.storageData[storageId][fillTypeIndex] = {
                    addedTime = currentTime
                }
            else
                local bestBefore = BestBeforeStorageManager.FILLTYPE_BEST_BEFORE[fillTypeIndex] or math.huge
                local timeStored = currentTime - data.addedTime

                if timeStored > bestBefore then
                    local decayRate = BestBeforeStorageManager.DECAY_RATE or 0.0001 -- fallback rate
                    local decayAmount = fillLevel * decayRate * (dt / (60 * 60 * 1000))
                    self.storage:addFillLevel(-decayAmount, fillTypeIndex, nil, nil, nil, nil)
                end
            end
        else
            BestBeforeStorageManager.storageData[storageId][fillTypeIndex] = nil
        end
    end
end

function ShelterMattesPlaceableSiloDecay:updateInfo(superFunc, infoTable)
    superFunc(self, infoTable)

    if not self.storage then return end

    local storageId = tostring(self.storage)
    local decayData = BestBeforeStorageManager.storageData[storageId]
    local currentTime = g_currentMission.environment.time

    if not decayData then return end

    local i = 1
    while i <= #infoTable do
        local entry = infoTable[i]
        local text = entry.text or ""

        local fillTypeIndex = nil
        for ftIndex, _ in pairs(self.storage.fillLevels) do
            local name = g_fillTypeManager:getFillTypeTitleByIndex(ftIndex)
            if text:find(name) then
                fillTypeIndex = ftIndex
                break
            end
        end

        if fillTypeIndex and decayData[fillTypeIndex] then
            local info = decayData[fillTypeIndex]
            local bestBefore = BestBeforeStorageManager.FILLTYPE_BEST_BEFORE[fillTypeIndex] or math.huge
            local timeStored = currentTime - info.addedTime
            local remaining = bestBefore - timeStored

            local statusLine = ""
            if remaining > 0 then
                statusLine = string.format("  Best Before: %.1f h left", remaining / (60 * 60 * 1000))
            else
                statusLine = "  Expired (decaying)"
            end

            table.insert(infoTable, i + 1, { title = "", text = statusLine })
            i = i + 1
        end

        i = i + 1
    end
end
