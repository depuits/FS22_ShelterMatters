-- @Author: Depuits

ShelterMattersDefaultRules = {
}

function ShelterMattersDefaultRules.loadDefaultDecayProperties()
    return {
        -------------------
        -- Bale products --
        -------------------
        [g_fillTypeManager:getFillTypeIndexByName("DRYGRASS_WINDROW")] = {
            wetnessImpact = 1.5,  -- **Hay absorbs rain quickly** due to being dried
            wetnessDecay = 4000,  -- Moderate decay when fully wet (liters/month)
            bestBeforePeriod = 12,  -- **Shelf life before decay starts (months)**
            bestBeforeDecay = 2000 -- Decays faster after best-before period (liters/month)
        },

        [g_fillTypeManager:getFillTypeIndexByName("SILAGE")] = {
            wetnessImpact = 0.6,  -- **Unwrapped silage absorbs rain slowly**
            wetnessDecay = 2000,  -- **Decays when soaked**, but slower than straw/grass
            bestBeforePeriod = 18, -- **Longer shelf life (months)**
            bestBeforeDecay = 1000 -- Gradual decay after best-before period
        },

        [g_fillTypeManager:getFillTypeIndexByName("STRAW")] = {
            wetnessImpact = 1.2,  -- **Straw absorbs rain quickly**, but not as fast as hay
            wetnessDecay = 5000,  -- **Severe decay when fully wet**
            bestBeforePeriod = 26, -- **Extended shelf life (months)**
            bestBeforeDecay = 500 -- Slower decay after best-before period
        },

        [g_fillTypeManager:getFillTypeIndexByName("GRASS")] = {
            wetnessImpact = 0.8,  -- **Fresh grass has moisture**, absorbs rain more slowly
            wetnessDecay = 6000,  -- **Decays the fastest when wet**
            bestBeforePeriod = 3,  -- **Short shelf life (months)**
            bestBeforeDecay = 3000 -- Heavy decay after best-before period
        },

        --------------------
        -- Dairy products --
        [g_fillTypeManager:getFillTypeIndexByName("MILK")] = {
            bestBeforePeriod = 2, 
            bestBeforeDecay = 8000, 
            maxTemperature = 10,
            maxTemperatureDecay = 20,  -- **20 liters per minute decay when too warm**
        },
        [g_fillTypeManager:getFillTypeIndexByName("BUTTER")] = {
            bestBeforePeriod = 8, 
            bestBeforeDecay = 2000,
            maxTemperature = 10,
            maxTemperatureDecay = 10  -- **10 liters per minute**
        },
        [g_fillTypeManager:getFillTypeIndexByName("CHEESE")] = {
            bestBeforePeriod = 14, 
            bestBeforeDecay = 1000,
            maxTemperature = 15,
            maxTemperatureDecay = 5  -- **More resistant, decays at 5 liters per minute**
        },
        [g_fillTypeManager:getFillTypeIndexByName("YOGURT")] = {
            bestBeforePeriod = 4, 
            bestBeforeDecay = 5000,
            maxTemperature = 10,
            maxTemperatureDecay = 15  -- **15 liters per minute**
        },

        -------------------
        -- Fresh produce --
        -------------------
        [g_fillTypeManager:getFillTypeIndexByName("LETTUCE")] = {
            bestBeforePeriod = 3, 
            bestBeforeDecay = 5000,
            maxTemperature = 20,
            maxTemperatureDecay = 30,  -- **Highly perishable in heat**
            minTemperature = 0,
            minTemperatureDecay = 10  -- **Freezing damages it but slower**
        },
        [g_fillTypeManager:getFillTypeIndexByName("TOMATOES")] = {
            bestBeforePeriod = 3, 
            bestBeforeDecay = 4000,
            maxTemperature = 20,
            maxTemperatureDecay = 20,
            minTemperature = 0,
            minTemperatureDecay = 5  
        },
        [g_fillTypeManager:getFillTypeIndexByName("STRAWBERRIES")] = {
            bestBeforePeriod = 3, 
            bestBeforeDecay = 6000,
            maxTemperature = 20,
            maxTemperatureDecay = 40,  -- **Very heat-sensitive**
            minTemperature = 0,
            minTemperatureDecay = 15  
        },

        ----------
        -- Oils --
        ----------  
        [g_fillTypeManager:getFillTypeIndexByName("SUNFLOWER_OIL")] = {
            bestBeforePeriod = 30, 
            bestBeforeDecay = 500
        },
        [g_fillTypeManager:getFillTypeIndexByName("CANOLA_OIL")] = {
            bestBeforePeriod = 30, 
            bestBeforeDecay = 500
        },
        [g_fillTypeManager:getFillTypeIndexByName("OLIVE_OIL")] = {
            bestBeforePeriod = 30, 
            bestBeforeDecay = 500
        },

        -------------------
        -- Misc products --
        -------------------
        [g_fillTypeManager:getFillTypeIndexByName("EGGS")] = {
            bestBeforePeriod = 5, 
            bestBeforeDecay = 2000,
            maxTemperature = 15,
            maxTemperatureDecay = 5  -- **Eggs last longer than milk**
        },
        [g_fillTypeManager:getFillTypeIndexByName("HONEY")] = {
            bestBeforePeriod = 24,
            bestBeforeDecay = 500,
            maxTemperature = 30,
            maxTemperatureDecay = 2  -- **Resistant to heat**
        },
        [g_fillTypeManager:getFillTypeIndexByName("GRAPE_JUICE")] = {
            bestBeforePeriod = 14, 
            bestBeforeDecay = 2000,
            maxTemperature = 30,
            maxTemperatureDecay = 5  
        },
        [g_fillTypeManager:getFillTypeIndexByName("WINE")] = {
            bestBeforePeriod = 72, 
            bestBeforeDecay = 200,
            maxTemperature = 30,
            maxTemperatureDecay = 1  -- **Very slow decay in heat**
        },
        [g_fillTypeManager:getFillTypeIndexByName("FLOUR")] = {
            wetnessImpact = 1.2, 
            wetnessDecay = 4000,
            bestBeforePeriod = 12, 
            bestBeforeDecay = 500
        },
        [g_fillTypeManager:getFillTypeIndexByName("BREAD")] = {
            wetnessImpact = 1.2, 
            wetnessDecay = 4000,
            bestBeforePeriod = 3, 
            bestBeforeDecay = 6000,
            maxTemperature = 25,
            maxTemperatureDecay = 25  
        },
        [g_fillTypeManager:getFillTypeIndexByName("CEREAL")] = {
            bestBeforePeriod = 14, 
            bestBeforeDecay = 1000
        }
    }
end
