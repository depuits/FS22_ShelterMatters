local modName = g_currentModName

TypeManager.finalizeTypes = Utils.prependedFunction(TypeManager.finalizeTypes, function(self, ...)
	if self.typeName == "vehicle" then
		for typeName, typeEntry in pairs(self:getTypes()) do
			for name, _ in pairs(typeEntry.specializationsByName) do
				if name == "motorized" then
					self:addSpecialization(typeName, modName..".mileageCounter")
					break
					end
				end
			end
		end
	end
)
