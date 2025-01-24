shelterMattersBaleDamageEvent = {}
local shelterMattersBaleDamageEvent_mt = Class(shelterMattersBaleDamageEvent, Event)
InitEventClass(shelterMattersBaleDamageEvent, "shelterMattersBaleDamageEvent")

function shelterMattersBaleDamageEvent.emptyNew()
    return Event.new(shelterMattersBaleDamageEvent_mt)
end

function shelterMattersBaleDamageEvent.new(bale)
    local self = shelterMattersBaleDamageEvent.emptyNew()
    self.baleId = NetworkUtil.getObjectId(bale)
    self.newFillLevel = bale.fillLevel
    return self
end

function shelterMattersBaleDamageEvent:readStream(streamId, connection)
    if g_server ~= nil then
        return
    end

    self.baleId = streamReadInt32(streamId)
    self.newFillLevel = streamReadFloat32(streamId)
    self:run(connection)
end

function shelterMattersBaleDamageEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.baleId)
    streamWriteFloat32(streamId, self.newFillLevel)
end

function shelterMattersBaleDamageEvent:run(connection)
    local bale = NetworkUtil.getObject(self.baleId)
    if bale ~= nil then
        bale.fillLevel = self.newFillLevel
    end
end
