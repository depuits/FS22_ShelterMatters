ShelterMattersDecayUnit = {}
ShelterMattersDecayUnit_mt = Class(ShelterMattersDecayUnit)

function ShelterMattersDecayUnit.new(vehicle, fillUnitIndex)
    local self = setmetatable({}, ShelterMattersDecayUnit_mt)

    self.vehicle = vehicle
    self.fillUnitIndex = fillUnitIndex

    self.wetness = 0
    self.lastUpdate = 0
    self.fillLevelFull = 0
    self.spawnTime = nil
    self.bestBefore = nil
    self.decayAmount = 0

    return self
end

function ShelterMattersDecayUnit:getFillLevel()
    return self.vehicle:getFillUnitFillLevel(self.fillUnitIndex)
end

function ShelterMattersDecayUnit:update()
    -- Add your decay computation logic here
end

function ShelterMattersDecayUnit:addDecayAmount(amount)
    self.decayAmount = math.max(0, self.decayAmount + amount)
    local fillType = self.vehicle:getFillUnitFillType(self.fillUnitIndex)
    self.vehicle:addFillUnitFillLevel(self.vehicle:getOwnerFarmId(), self.fillUnitIndex, -amount, fillType, ToolType.UNDEFINED)
end

-- TODO add: save/load methods, bestBefore calculation, etc.
