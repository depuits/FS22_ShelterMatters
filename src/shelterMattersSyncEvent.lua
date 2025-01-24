ShelterMattersSyncEvent = {}
local ShelterMattersSyncEvent_mt = Class(ShelterMattersSyncEvent, Event)
InitEventClass(ShelterMattersSyncEvent, "ShelterMattersSyncEvent")

function ShelterMattersSyncEvent.emptyNew()
    return Event.new(ShelterMattersSyncEvent_mt)
end

function ShelterMattersSyncEvent.new(hideShelterStatusIcon, damageRates, weatherMultipliers, baleWeatherDecay)
    local self = ShelterMattersSyncEvent.emptyNew()
    self.hideShelterStatusIcon = hideShelterStatusIcon
    self.damageRates = damageRates
    self.weatherMultipliers = weatherMultipliers
    self.baleWeatherDecay = baleWeatherDecay
    return self
end

function ShelterMattersSyncEvent:readStream(streamId, connection)
    if g_server ~= nil then
        return
    end

    self.hideShelterStatusIcon = streamReadBool(streamId)

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

    self.baleWeatherDecay = {}
    count = streamReadInt32(streamId)
    for i = 1, count do
        local weatherType = streamReadString(streamId)
        local rate = streamReadFloat32(streamId)
        self.baleWeatherDecay[weatherType] = rate
    end
    
    self:run(connection)
end

function ShelterMattersSyncEvent:writeStream(streamId, connection)
    if self.damageRates == nil or self.weatherMultipliers == nil or self.baleWeatherDecay == nill then
        return
    end

    -- write status icon state
    streamWriteBool(streamId, self.hideShelterStatusIcon)

    -- Write damageRates
    local damageRatesCount = 0
    for _ in pairs(self.damageRates) do
        damageRatesCount = damageRatesCount + 1
    end
    streamWriteInt32(streamId, damageRatesCount)

    for typeName, rate in pairs(self.damageRates) do
        streamWriteString(streamId, typeName)
        streamWriteFloat32(streamId, rate)
    end

    -- Write weatherMultipliers
    local weatherMultipliersCount = 0
    for _ in pairs(self.weatherMultipliers) do
        weatherMultipliersCount = weatherMultipliersCount + 1
    end
    streamWriteInt32(streamId, weatherMultipliersCount)

    for weatherType, multiplier in pairs(self.weatherMultipliers) do
        streamWriteString(streamId, weatherType)
        streamWriteFloat32(streamId, multiplier)
    end

    -- Write baleWeatherDecay
    local baleWeatherDecayCount = 0
    for _ in pairs(self.baleWeatherDecay) do
        baleWeatherDecayCount = baleWeatherDecayCount + 1
    end
    streamWriteInt32(streamId, baleWeatherDecayCount)

    for weatherType, rate in pairs(self.baleWeatherDecay) do
        streamWriteString(streamId, weatherType)
        streamWriteFloat32(streamId, rate)
    end
end

function ShelterMattersSyncEvent:run(connection)
    if g_server ~= nil then
        ShelterMattersSyncEvent.sendToClients()
        return
    end

    ShelterMatters.hideShelterStatusIcon = self.hideShelterStatusIcon
    ShelterMatters.damageRates = self.damageRates
    ShelterMatters.weatherMultipliers = self.weatherMultipliers
    ShelterMatters.baleWeatherDecay = self.baleWeatherDecay
end

function ShelterMattersSyncEvent.sendToClients()
    g_server:broadcastEvent(ShelterMattersSyncEvent.new(ShelterMatters.hideShelterStatusIcon, ShelterMatters.damageRates, ShelterMatters.weatherMultipliers, ShelterMatters.baleWeatherDecay))
end

function ShelterMattersSyncEvent.sendToServer()
    g_client:getServerConnection():sendEvent(ShelterMattersSyncEvent.new())
end
