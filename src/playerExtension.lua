Player.registerActionEvents = Utils.appendedFunction(Player.registerActionEvents, function(self)
	g_inputBinding:beginActionEventsModification(Player.INPUT_CONTEXT_NAME)
	local inputAction = InputAction.OPEN_SHELTER_MATTERS_SETTINGS
	local callbackTarget = self
	local callbackFunc = self.openShelterMattersSettings
	local triggerUp = false
	local triggerDown = true
	local triggerAlways = false
	local startActive = true
	local _, eventId = g_inputBinding:registerActionEvent(inputAction, callbackTarget, callbackFunc, triggerUp, triggerDown, triggerAlways, startActive)
	g_inputBinding:setActionEventText(eventId, g_i18n:getText("input_OPEN_SHELTER_MATTERS_SETTINGS"))
	g_inputBinding:setActionEventTextVisibility(eventId, true)
	g_inputBinding:endActionEventsModification()
end)

function Player:openShelterMattersSettings(actionName, inputValue, callbackState, isAnalog, isMouse, deviceCategory)
	local callback = function(baleTypeIndex, fillTypeIndex, numBales)
		local x, y, z = getWorldTranslation(self.rootNode)
		local dirX, dirZ = -math.sin(self.rotY), -math.cos(self.rotY)
		x = x + dirX * 4
		z = z + dirZ * 4
		local farmId = self.farmId
		--g_client:getServerConnection():sendEvent(MultiBaleSpawnerEvent.new(baleTypeIndex, fillTypeIndex, numBales, x, y, z, dirX, dirZ, farmId))
	end

	ShelterMattersSettings.show(callback)
end
