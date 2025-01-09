ShelterMattersSyncEvent = {}
local ShelterMattersSyncEvent_mt = Class(ShelterMattersSyncEvent, Event)
InitEventClass(ShelterMattersSyncEvent, "ShelterMattersSyncEvent")


function ShelterMattersSyncEvent.emptyNew()
    return Event.new(ShelterMattersSyncEvent_mt)
end

function ShelterMattersSyncEvent.new(damageRates, weatherMultipliers)
    local self = ShelterMattersSyncEvent.emptyNew()
    self.damageRates = damageRates
    self.weatherMultipliers = weatherMultipliers
    return self
end

function ShelterMattersSyncEvent:readStream(streamId, connection)
    self.damageRates = {}
    local count = streamReadInt32(streamId)
    for i = 1, count do
        local typeName = streamReadString(streamId)
        local rate = streamReadFloat32(streamId)
        self.damageRates[typeName] = rate
    end

    self.weatherMultipliers = {}
    count = streamReadInt32(streamId)
    for i = 1, count do
        local weatherType = streamReadString(streamId)
        local multiplier = streamReadFloat32(streamId)
        self.weatherMultipliers[weatherType] = multiplier
    end
    
    self:run(connection)
end

function ShelterMattersSyncEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, table.getn(self.damageRates))
    for typeName, rate in pairs(self.damageRates) do
        streamWriteString(streamId, typeName)
        streamWriteFloat32(streamId, rate)
    end

    streamWriteInt32(streamId, table.getn(self.weatherMultipliers))
    for weatherType, multiplier in pairs(self.weatherMultipliers) do
        streamWriteString(streamId, weatherType)
        streamWriteFloat32(streamId, multiplier)
    end
end

function ShelterMattersSyncEvent:run(connection)
    if not connection:getIsServer() then
        ShelterMatters.damageRates = self.damageRates
        ShelterMatters.weatherMultipliers = self.weatherMultipliers
    end
end

function ShelterMattersSyncEvent.sendToClients()
    g_server:broadcastEvent(ShelterMattersSyncEvent.new(ShelterMatters.damageRates, ShelterMatters.weatherMultipliers))
end
