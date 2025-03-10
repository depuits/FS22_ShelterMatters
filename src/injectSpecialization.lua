local modName = g_currentModName

TypeManager.finalizeTypes = Utils.prependedFunction(TypeManager.finalizeTypes, function(self, ...)
	if self.typeName == "vehicle" then
		for typeName, typeEntry in pairs(self:getTypes()) do
			for name, _ in pairs(typeEntry.specializationsByName) do
				if name == "fillUnit" then
					self:addSpecialization(typeName, modName..".fillUnitDecay")
					break
					end
				end
			end
		end
	end
)
