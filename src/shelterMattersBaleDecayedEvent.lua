shelterMattersBaleDecayedEvent = {}
local shelterMattersBaleDecayedEvent_mt = Class(shelterMattersBaleDecayedEvent, Event)
InitEventClass(shelterMattersBaleDecayedEvent, "shelterMattersBaleDecayedEvent")

function shelterMattersBaleDecayedEvent.emptyNew()
    return Event.new(shelterMattersBaleDamageEvent_mt)
end

function shelterMattersBaleDecayedEvent.new(bale)
    local self = shelterMattersBaleDecayedEvent.emptyNew()
    self.farmId = bale:getOwnerFarmId()
    self.fillType = bale:getFillType()
    return self
end

function shelterMattersBaleDecayedEvent:readStream(streamId, connection)
    if g_server ~= nil then
        return
    end

    self.farmId = streamReadInt32(streamId)
    self.fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
    self:run(connection)
end

function shelterMattersBaleDecayedEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.farmId)
    streamWriteUIntN(streamId, self.fillType, FillTypeManager.SEND_NUM_BITS)
end

function shelterMattersBaleDecayedEvent:run(connection)
    shelterMattersBaleDecayedEvent.showDecayedNotification(self.farmId, self.fillType)
end

function shelterMattersBaleDecayedEvent.showDecayedNotification(farmId, fillType)
    -- check if bale is from the current players farm
    if farmId == g_currentMission:getFarmId() then
        local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillType)
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("SM_AlertBaleDeleted"), fillTypeDesc.title))
    end
end
