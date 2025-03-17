-- @Author: Depuits

ShelterMattersDefaultRules = {
}

function ShelterMattersDefaultRules.loadDefaultDecayProperties()
    local list = {}

    -------------------
    -- Bale products --
    -------------------
    ShelterMattersDefaultRules.addDecayProperties(list, "DRYGRASS_WINDROW", {
        wetnessImpact = 1.5,  -- **Hay absorbs rain quickly** due to being dried
        wetnessDecay = 4000,  -- Moderate decay when fully wet (liters/month)
        bestBeforePeriod = 12,  -- **Shelf life before decay starts (months)**
        bestBeforeDecay = 2000 -- Decays faster after best-before period (liters/month)
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "SILAGE", {
        wetnessImpact = 0.6,  -- **Unwrapped silage absorbs rain slowly**
        wetnessDecay = 2000,  -- **Decays when soaked**, but slower than straw/grass
        bestBeforePeriod = 18, -- **Longer shelf life (months)**
        bestBeforeDecay = 1000 -- Gradual decay after best-before period
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "STRAW", {
        wetnessImpact = 1.2,  -- **Straw absorbs rain quickly**, but not as fast as hay
        wetnessDecay = 5000,  -- **Severe decay when fully wet**
        bestBeforePeriod = 26, -- **Extended shelf life (months)**
        bestBeforeDecay = 500 -- Slower decay after best-before period
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "GRASS", {
        wetnessImpact = 0.8,  -- **Fresh grass has moisture**, absorbs rain more slowly
        wetnessDecay = 6000,  -- **Decays the fastest when wet**
        bestBeforePeriod = 3,  -- **Short shelf life (months)**
        bestBeforeDecay = 3000 -- Heavy decay after best-before period
    })

    --------------------
    -- Dairy products --
    ShelterMattersDefaultRules.addDecayProperties(list, "MILK", {
        bestBeforePeriod = 2, 
        bestBeforeDecay = 8000, 
        maxTemperature = 10,
        maxTemperatureDecay = 20,  -- **20 liters per minute decay when too warm**
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "BUTTER", {
        bestBeforePeriod = 8, 
        bestBeforeDecay = 2000,
        maxTemperature = 10,
        maxTemperatureDecay = 10  -- **10 liters per minute**
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "CHEESE", {
        bestBeforePeriod = 14, 
        bestBeforeDecay = 1000,
        maxTemperature = 15,
        maxTemperatureDecay = 5  -- **More resistant, decays at 5 liters per minute**
    })

    -------------------
    -- Fresh produce --
    -------------------
    ShelterMattersDefaultRules.addDecayProperties(list, "LETTUCE", {
        bestBeforePeriod = 3, 
        bestBeforeDecay = 5000,
        maxTemperature = 20,
        maxTemperatureDecay = 30,  -- **Highly perishable in heat**
        minTemperature = 0,
        minTemperatureDecay = 10  -- **Freezing damages it but slower**
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "TOMATOES", {
        bestBeforePeriod = 3, 
        bestBeforeDecay = 4000,
        maxTemperature = 20,
        maxTemperatureDecay = 20,
        minTemperature = 0,
        minTemperatureDecay = 5  
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "STRAWBERRIES", {
        bestBeforePeriod = 3, 
        bestBeforeDecay = 6000,
        maxTemperature = 20,
        maxTemperatureDecay = 40,  -- **Very heat-sensitive**
        minTemperature = 0,
        minTemperatureDecay = 15  
    })

    ----------
    -- Oils --
    ----------  
    ShelterMattersDefaultRules.addDecayProperties(list, "SUNFLOWER_OIL", {
        bestBeforePeriod = 30, 
        bestBeforeDecay = 500
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "CANOLA_OIL", {
        bestBeforePeriod = 30, 
        bestBeforeDecay = 500
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "OLIVE_OIL", {
        bestBeforePeriod = 30, 
        bestBeforeDecay = 500
    })

    -------------------
    -- Misc products --
    -------------------
    ShelterMattersDefaultRules.addDecayProperties(list, "EGGS", {
        bestBeforePeriod = 5, 
        bestBeforeDecay = 2000,
        maxTemperature = 15,
        maxTemperatureDecay = 5  -- **Eggs last longer than milk**
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "HONEY", {
        bestBeforePeriod = 24,
        bestBeforeDecay = 500,
        maxTemperature = 30,
        maxTemperatureDecay = 2  -- **Resistant to heat**
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "GRAPE_JUICE", {
        bestBeforePeriod = 14, 
        bestBeforeDecay = 2000,
        maxTemperature = 30,
        maxTemperatureDecay = 5  
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "WINE", {
        bestBeforePeriod = 72, 
        bestBeforeDecay = 200,
        maxTemperature = 30,
        maxTemperatureDecay = 1  -- **Very slow decay in heat**
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "FLOUR", {
        wetnessImpact = 1.2, 
        wetnessDecay = 4000,
        bestBeforePeriod = 12, 
        bestBeforeDecay = 500
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "BREAD", {
        wetnessImpact = 1.2, 
        wetnessDecay = 4000,
        bestBeforePeriod = 3, 
        bestBeforeDecay = 6000,
        maxTemperature = 25,
        maxTemperatureDecay = 25  
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "CEREAL", {
        bestBeforePeriod = 14, 
        bestBeforeDecay = 1000
    })

    return list
end

function ShelterMattersDefaultRules.addDecayProperties(list, name, props)
    local index = g_fillTypeManager:getFillTypeIndexByName(name)
    print(name .. ": " .. index)
    list[index] = props
end
