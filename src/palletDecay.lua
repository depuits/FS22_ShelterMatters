local modName = g_currentModName
MileageCounter = {}
MileageCounter.SPEC_TABLE_NAME = "spec_"..modName..".mileageCounter"

function MileageCounter.prerequisitesPresent(specializations)
	return true
end

function MileageCounter.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", MileageCounter)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", MileageCounter)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", MileageCounter)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", MileageCounter)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", MileageCounter)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", MileageCounter)
end

function MileageCounter.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getDrivenDistance", MileageCounter.getDrivenDistance)
end

function MileageCounter.initSpecialization()
	local schemaSavegame = Vehicle.xmlSchemaSavegame
	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?)."..modName..".mileageCounter#drivenDistance", "Driven distance in meters")
end

function MileageCounter:onLoad(savegame)
	local spec = self[MileageCounter.SPEC_TABLE_NAME]
	spec.drivenDistance = 0
	if savegame ~= nil then
		spec.drivenDistance = savegame.xmlFile:getValue(savegame.key .. "."..modName..".mileageCounter#drivenDistance", 0)
	end
	
	spec.drivenDistanceNetworkThreshold = 10
	spec.drivenDistanceSent = spec.drivenDistance
	spec.dirtyFlag = self:getNextDirtyFlag()
end

function MileageCounter:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self[MileageCounter.SPEC_TABLE_NAME]
	xmlFile:setValue(key .. "#drivenDistance", spec.drivenDistance)
end

function MileageCounter:onReadStream(streamId, connection)
	local spec = self[MileageCounter.SPEC_TABLE_NAME]
	spec.drivenDistance = streamReadInt32(streamId)
end

function MileageCounter:onWriteStream(streamId, connection)
	local spec = self[MileageCounter.SPEC_TABLE_NAME]
	streamWriteInt32(streamId, spec.drivenDistance)
end

function MileageCounter:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		if streamReadBool(streamId) then
			local spec = self[MileageCounter.SPEC_TABLE_NAME]
			spec.drivenDistance = streamReadInt32(streamId)
		end
	end
end

function MileageCounter:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self[MileageCounter.SPEC_TABLE_NAME]
		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			streamWriteInt32(streamId, spec.drivenDistance)
		end
	end
end

function MileageCounter:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self[MileageCounter.SPEC_TABLE_NAME]
	if self:getIsMotorStarted() then
		if self.isServer then
			if self.lastMovedDistance > 0.001 then
				spec.drivenDistance = spec.drivenDistance + self.lastMovedDistance
				if math.abs(spec.drivenDistance - spec.drivenDistanceSent) > spec.drivenDistanceNetworkThreshold then
					self:raiseDirtyFlags(spec.dirtyFlag)
					spec.drivenDistanceSent = spec.drivenDistance
				end
			end
		end
	end
end

function MileageCounter:getDrivenDistance()
	-- first get the specialization namespace
	local spec = self[MileageCounter.SPEC_TABLE_NAME]
	return spec.drivenDistance
end
