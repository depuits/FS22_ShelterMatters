ShelterMattersSyncEvent = {}
local ShelterMattersSyncEvent_mt = Class(ShelterMattersSyncEvent, Event)
InitEventClass(ShelterMattersSyncEvent, "ShelterMattersSyncEvent")

function ShelterMattersSyncEvent.emptyNew()
    return Event.new(ShelterMattersSyncEvent_mt)
end

function ShelterMattersSyncEvent.new(hideShelterStatusIcon, damageRates, weatherMultipliers, decayProperties, weatherAffectedSpecs, weatherExcludedSpecs, weatherExcludedTypes)
    local self = ShelterMattersSyncEvent.emptyNew()
    self.hideShelterStatusIcon = hideShelterStatusIcon
    self.damageRates = damageRates
    self.weatherMultipliers = weatherMultipliers
    self.decayProperties = decayProperties
    self.weatherAffectedSpecs = weatherAffectedSpecs
    self.weatherExcludedSpecs = weatherExcludedSpecs
    self.weatherExcludedTypes = weatherExcludedTypes
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

    self.decayProperties = {}
    count = streamReadInt32(streamId)
    for i = 1, count do
        local fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
        self.decayProperties[fillType] = {}

        if streamReadBool(streamId) then
            self.decayProperties[fillType].wetnessImpact = streamReadFloat32(streamId)
        end
        if streamReadBool(streamId) then
            self.decayProperties[fillType].wetnessDecay = streamReadFloat32(streamId)
        end
        if streamReadBool(streamId) then
            self.decayProperties[fillType].bestBeforePeriod = streamReadInt32(streamId)
        end
        if streamReadBool(streamId) then
            self.decayProperties[fillType].bestBeforeDecay = streamReadFloat32(streamId)
        end
    end

    self.weatherAffectedSpecs = self:readStringListFromStream(streamId)
    self.weatherExcludedSpecs = self:readStringListFromStream(streamId)
    self.weatherExcludedTypes = self:readStringListFromStream(streamId)
    
    self:run(connection)
end

function ShelterMattersSyncEvent:writeStream(streamId, connection)
    if self.damageRates == nil or self.weatherMultipliers == nil or self.decayProperties == nill then
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

    -- Write decayProperties
    local decayPropertiesCount = 0
    for _ in pairs(self.decayProperties) do
        decayPropertiesCount = decayPropertiesCount + 1
    end
    streamWriteInt32(streamId, decayPropertiesCount)

    for fillType, props in pairs(self.decayProperties) do
        streamWriteUIntN(streamId, fillType, FillTypeManager.SEND_NUM_BITS)

        if streamWriteBool(streamId, props.wetnessImpact ~= nil) then
            streamWriteFloat32(streamId, props.wetnessImpact)
        end
        if streamWriteBool(streamId, props.wetnessDecay ~= nil) then
            streamWriteFloat32(streamId, props.wetnessDecay)
        end
        if streamWriteBool(streamId, props.bestBeforePeriod ~= nil) then
            streamWriteInt32(streamId, props.bestBeforePeriod)
        end
        if streamWriteBool(streamId, props.bestBeforeDecay ~= nil) then
            streamWriteFloat32(streamId, props.bestBeforeDecay)
        end
    end

    self:writeStringListToStream(streamId, self.weatherAffectedSpecs)
    self:writeStringListToStream(streamId, self.weatherExcludedSpecs)
    self:writeStringListToStream(streamId, self.weatherExcludedTypes)
end

function ShelterMattersSyncEvent:readStringListFromStream(streamId)
    local list = {}
    count = streamReadInt32(streamId)
    for i = 1, count do
        local value = streamReadString(streamId)
        table.insert(list, value)
    end

    return list
end

function ShelterMattersSyncEvent:writeStringListToStream(streamId, list)
    local propertiesCount = 0
    for _ in ipairs(list) do
        propertiesCount = propertiesCount + 1
    end
    streamWriteInt32(streamId, propertiesCount)

    for _, value in ipairs(list) do
        streamWriteString(streamId, value)
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
    ShelterMatters.decayProperties = self.decayProperties
    ShelterMatters.weatherAffectedSpecs = self.weatherAffectedSpecs
    ShelterMatters.weatherExcludedSpecs = self.weatherExcludedSpecs
    ShelterMatters.weatherExcludedTypes = self.weatherExcludedTypes
end

function ShelterMattersSyncEvent.sendToClients()
    g_server:broadcastEvent(ShelterMattersSyncEvent.new(ShelterMatters.hideShelterStatusIcon, ShelterMatters.damageRates, ShelterMatters.weatherMultipliers, ShelterMatters.decayProperties, ShelterMatters.weatherAffectedSpecs, ShelterMatters.weatherExcludedSpecs, ShelterMatters.weatherExcludedTypes))
end

function ShelterMattersSyncEvent.sendToServer()
    g_client:getServerConnection():sendEvent(ShelterMattersSyncEvent.new())
end
