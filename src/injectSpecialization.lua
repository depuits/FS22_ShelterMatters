local modName = g_currentModName

TypeManager.finalizeTypes = Utils.prependedFunction(TypeManager.finalizeTypes, function(self, ...)
	-- insert objetDecay spec on vehicles and pallets
	if self.typeName == "vehicle" then
		for typeName, typeEntry in pairs(self:getTypes()) do
			for name, _ in pairs(typeEntry.specializationsByName) do
				if name == "fillUnit" then
					self:addSpecialization(typeName, modName..".shelterMattersObjectDecay")
					break
				end
			end
		end
	end

	-- insert siloDecay on placeables
	if self.typeName == "placeable" then
		for typeName, typeEntry in pairs(self:getTypes()) do
			for name, _ in pairs(typeEntry.specializationsByName) do
				if name == "silo" then
					self:addSpecialization(typeName, modName..".shelterMattersSiloDecay")
					break
				end
			end
		end
	end
end)
