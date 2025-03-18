-- @Author: Depuits

ShelterMattersDefaultRules = {
}

function ShelterMattersDefaultRules.loadDefaultDecayProperties()
    local list = {}

    -----------
    -- BALES --
    -----------
    ShelterMattersDefaultRules.addDecayProperties(list, "DRYGRASS_WINDROW", {
        bestBeforePeriod = 12,  -- **Shelf life before decay starts (months)**
        bestBeforeDecay = 2000 -- Decays faster after best-before period (liters/month)
        wetnessImpact = 1.5,  -- **Hay absorbs rain quickly** due to being dried
        wetnessDecay = 4000,  -- Moderate decay when fully wet (liters/month)
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "SILAGE", {
        bestBeforePeriod = 18, -- **Longer shelf life (months)**
        bestBeforeDecay = 1000 -- Gradual decay after best-before period
        wetnessImpact = 0.6,  -- **Unwrapped silage absorbs rain slowly**
        wetnessDecay = 2000,  -- **Decays when soaked**, but slower than straw/grass
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "STRAW", {
        bestBeforePeriod = 26, -- **Extended shelf life (months)**
        bestBeforeDecay = 500 -- Slower decay after best-before period
        wetnessImpact = 1.2,  -- **Straw absorbs rain quickly**, but not as fast as hay
        wetnessDecay = 5000,  -- **Severe decay when fully wet**
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "GRASS", {
        bestBeforePeriod = 3,  -- **Short shelf life (months)**
        bestBeforeDecay = 3000 -- Heavy decay after best-before period
        wetnessImpact = 0.8,  -- **Fresh grass has moisture**, absorbs rain more slowly
        wetnessDecay = 6000,  -- **Decays the fastest when wet**
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "COTTON", {
        wetnessImpact = 1.5,
        wetnessDecay = 1000,
    })

    ------------------------
    -- GRAINS & OILSEEDS  --
    ------------------------
    ShelterMattersDefaultRules.addDecayProperties(list, "WHEAT", {
        bestBeforePeriod = 24, 
        bestBeforeDecay = 500,
        wetnessImpact = 1.0, 
        wetnessDecay = 2000
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "BARLEY", {
        bestBeforePeriod = 24, 
        bestBeforeDecay = 500,
        wetnessImpact = 1.0, 
        wetnessDecay = 2000
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "OAT", {
        bestBeforePeriod = 24, 
        bestBeforeDecay = 500,
        wetnessImpact = 1.2, 
        wetnessDecay = 2500
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "CANOLA", {
        bestBeforePeriod = 30, 
        bestBeforeDecay = 300,
        wetnessImpact = 0.8, 
        wetnessDecay = 1500
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "SORGHUM", {
        bestBeforePeriod = 30, 
        bestBeforeDecay = 300,
        wetnessImpact = 0.8, 
        wetnessDecay = 1500
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "SUNFLOWER", {
        bestBeforePeriod = 30, 
        bestBeforeDecay = 300,
        wetnessImpact = 0.8, 
        wetnessDecay = 1500
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "SOYBEAN", {
        bestBeforePeriod = 36, 
        bestBeforeDecay = 300,
        wetnessImpact = 0.7, 
        wetnessDecay = 1200
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "MAIZE", {
        bestBeforePeriod = 24, 
        bestBeforeDecay = 800,
        wetnessImpact = 1.5,  
        wetnessDecay = 3000
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "OLIVE", {
        bestBeforePeriod = 18, 
        bestBeforeDecay = 1000,
        wetnessImpact = 0.7, 
        wetnessDecay = 1200
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "GRAPE", {
        bestBeforePeriod = 3, 
        bestBeforeDecay = 6000,
        wetnessImpact = 1.8, 
        wetnessDecay = 4000,
        maxTemperature = 25,
        maxTemperatureDecay = 30,  
        minTemperature = 0,
        minTemperatureDecay = 10  
    })

    ----------
    -- OILS --
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
    
    -------------------------
    -- ROOT CROPS & FORAGE --
    -------------------------
    ShelterMattersDefaultRules.addDecayProperties(list, "POTATO", {
        bestBeforePeriod = 10,
        bestBeforeDecay = 2000,
        wetnessImpact = 1.2,
        wetnessDecay = 3000,
        maxTemperature = 15,
        maxTemperatureDecay = 10,
        minTemperature = 2,
        minTemperatureDecay = 10
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "SUGARBEET", {
        bestBeforePeriod = 10,
        bestBeforeDecay = 2000,
        wetnessImpact = 1.0,
        wetnessDecay = 2500,
        maxTemperature = 15,
        maxTemperatureDecay = 10,
        minTemperature = 2,
        minTemperatureDecay = 10
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "SUGARBEET_CUT", {
        bestBeforePeriod = 1,
        bestBeforeDecay = 8000,
        wetnessImpact = 1.5,
        wetnessDecay = 5000,
        maxTemperature = 10,
        maxTemperatureDecay = 20,
        minTemperature = 2,
        minTemperatureDecay = 10
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "BEETROOT", {
        bestBeforePeriod = 8,
        bestBeforeDecay = 3000,
        wetnessImpact = 1.3,
        wetnessDecay = 3500,
        maxTemperature = 10,
        maxTemperatureDecay = 15,
        minTemperature = 0,
        minTemperatureDecay = 15
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "CARROT", {
        bestBeforePeriod = 8,
        bestBeforeDecay = 3000,
        wetnessImpact = 1.3,
        wetnessDecay = 3500,
        maxTemperature = 10,
        maxTemperatureDecay = 15,
        minTemperature = 0,
        minTemperatureDecay = 15
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "PARSNIP", {
        bestBeforePeriod = 9,
        bestBeforeDecay = 2500,
        wetnessImpact = 1.2,
        wetnessDecay = 3000,
        maxTemperature = 8,
        maxTemperatureDecay = 15,
        minTemperature = -2,
        minTemperatureDecay = 10
    })

    -------------------
    -- FRESH PRODUCE --
    -------------------
    ShelterMattersDefaultRules.addDecayProperties(list, "LETTUCE", {
        bestBeforePeriod = 3, 
        bestBeforeDecay = 5000,
        maxTemperature = 20,
        maxTemperatureDecay = 30,  -- **Highly perishable in heat**
        minTemperature = 0,
        minTemperatureDecay = 10  -- **Freezing damages it but slower**
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "TOMATO", {
        bestBeforePeriod = 3, 
        bestBeforeDecay = 4000,
        maxTemperature = 20,
        maxTemperatureDecay = 20,
        minTemperature = 0,
        minTemperatureDecay = 5  
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "STRAWBERRY", {
        bestBeforePeriod = 3, 
        bestBeforeDecay = 6000,
        maxTemperature = 20,
        maxTemperatureDecay = 40,  -- **Very heat-sensitive**
        minTemperature = 0,
        minTemperatureDecay = 15  
    })

    ---------------------
    -- ANIMAL PRODUCTS --
    ---------------------
    ShelterMattersDefaultRules.addDecayProperties(list, "WOOL", {
        wetnessImpact = 1,
        wetnessDecay = 3000 -- wool is only sensitive to wetness
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "HONEY", {
        bestBeforePeriod = 24,
        bestBeforeDecay = 500,
        maxTemperature = 30,
        maxTemperatureDecay = 2  -- **Resistant to heat**
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "EGG", {
        bestBeforePeriod = 5, 
        bestBeforeDecay = 2000,
        maxTemperature = 15,
        maxTemperatureDecay = 5  -- **Eggs last longer than milk**
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "MILK", {
        bestBeforePeriod = 2, 
        bestBeforeDecay = 8000, 
        maxTemperature = 10,
        maxTemperatureDecay = 20,  -- **20 liters per minute decay when too warm**
    })
    ShelterMattersDefaultRules.addDecayProperties(list, "GOATMILK", {
        bestBeforePeriod = 2, 
        bestBeforeDecay = 8000, 
        maxTemperature = 10,
        maxTemperatureDecay = 20,  -- **20 liters per minute decay when too warm**
    })

    ---------------------
    -- PROCESSED FOODS --
    ---------------------
    ShelterMattersDefaultRules.addDecayProperties(list, "FLOUR", {
        bestBeforePeriod = 12,
        bestBeforeDecay = 500,
        wetnessImpact = 1.5,
        wetnessDecay = 4000
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "BREAD", {
        bestBeforePeriod = 3,
        bestBeforeDecay = 2000,
        wetnessImpact = 2.0,
        wetnessDecay = 6000,
        maxTemperature = 25,
        maxTemperatureDecay = 20,
        minTemperature = 0,
        minTemperatureDecay = 5
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "CAKE", {
        bestBeforePeriod = 3,
        bestBeforeDecay = 4000,
        wetnessImpact = 2.5,
        wetnessDecay = 8000,
        maxTemperature = 15,
        maxTemperatureDecay = 30,
        minTemperature = 0,
        minTemperatureDecay = 10
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "BUTTER", {
        bestBeforePeriod = 8, 
        bestBeforeDecay = 2000,
        maxTemperature = 10,
        maxTemperatureDecay = 15  
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "CHEESE", {
        bestBeforePeriod = 14,
        bestBeforeDecay = 1000,
        maxTemperature = 15,
        maxTemperatureDecay = 5 -- **More resistant, decays at 5 liters per minute**
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "SUGAR", {
        bestBeforePeriod = 24,
        bestBeforeDecay = 200,
        wetnessImpact = 2.0,
        wetnessDecay = 5000
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "CEREAL", {
        bestBeforePeriod = 6,
        bestBeforeDecay = 800,
        wetnessImpact = 1.8,
        wetnessDecay = 5000
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "RAISINS", {
        bestBeforePeriod = 12,
        bestBeforeDecay = 1000,
        maxTemperature = 25,
        maxTemperatureDecay = 10
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "GRAPEJUICE", {
        bestBeforePeriod = 14,
        bestBeforeDecay = 2000,
        maxTemperature = 30,
        maxTemperatureDecay = 5
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "POTATOCHIPS", {
        bestBeforePeriod = 6,
        bestBeforeDecay = 1000
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "CHOCOLATE", {
        bestBeforePeriod = 6,
        bestBeforeDecay = 1500,
        maxTemperature = 22,
        maxTemperatureDecay = 20
    })

    -----------------------------
    -- PRESERVED FOODS & SOUPS --
    -----------------------------
    ShelterMattersDefaultRules.addDecayProperties(list, "PRESERVEDCARROTS", {
        bestBeforePeriod = 36,
        bestBeforeDecay = 500
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "PRESERVEDPARSNIP", {
        bestBeforePeriod = 36,
        bestBeforeDecay = 500
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "PRESERVEDBEETROOT", {
        bestBeforePeriod = 36,
        bestBeforeDecay = 500
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "SOUPCANSMIXED", {
        bestBeforePeriod = 60,
        bestBeforeDecay = 200
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "SOUPCANSCARROTS", {
        bestBeforePeriod = 60,
        bestBeforeDecay = 200
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "SOUPCANSPARSNIP", {
        bestBeforePeriod = 60,
        bestBeforeDecay = 200
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "SOUPCANSBEETROOT", {
        bestBeforePeriod = 60,
        bestBeforeDecay = 200
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "SOUPCANSPOTATO", {
        bestBeforePeriod = 60,
        bestBeforeDecay = 200
    })

    ----------
    -- MISC --
    ----------
    ShelterMattersDefaultRules.addDecayProperties(list, "FERTILIZER", {
        bestBeforePeriod = 24,
        bestBeforeDecay = 250,
        wetnessImpact = 1.5,
        wetnessDecay = 5000,
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "LIQUIDFERTILIZER", {
        bestBeforePeriod = 24,
        bestBeforeDecay = 250
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "PIGFOOD", {
        bestBeforePeriod = 12,
        bestBeforeDecay = 3000,
        wetnessImpact = 1.5,
        wetnessDecay = 5000,
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "LIME", {
        bestBeforePeriod = 48,
        bestBeforeDecay = 100,
        wetnessImpact = 2.0,
        wetnessDecay = 4000
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "SUGARCANE", {
        bestBeforePeriod = 14,
        bestBeforeDecay = 2000,
        wetnessImpact = 1.2,
        wetnessDecay = 6000,
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "SEEDS", {
        bestBeforePeriod = 36,
        bestBeforeDecay = 1000,
        wetnessImpact = 1.2,
        wetnessDecay = 3000,
        maxTemperature = 30,
        maxTemperatureDecay = 10
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "WOODCHIPS", {
        wetnessImpact = 2,
        wetnessDecay = 4000
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "CHAFF", {
        bestBeforePeriod = 3,
        bestBeforeDecay = 5000,
        wetnessImpact = 1.5,
        wetnessDecay = 5000
    })

    ShelterMattersDefaultRules.addDecayProperties(list, "SNOW", {
        maxTemperature = 0,
        maxTemperatureDecay = 100
    })

    return list
end

function ShelterMattersDefaultRules.addDecayProperties(list, name, props)
    local index = g_fillTypeManager:getFillTypeIndexByName(name)
    --TODO chec if valid
    list[index] = props
end
