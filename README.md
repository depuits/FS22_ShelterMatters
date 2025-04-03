![ShelterMatters](logo.png)

**ShelterMatters** enhances the importance of sheds and indoor storage in Farming Simulator 22 by introducing realistic wear and decay mechanics. Vehicles, tools, and stored goods deteriorate faster when exposed to the elements, making proper storage essential. Products now have a best-before period, after which they begin to degrade. Factors like moisture and temperature further influence their lifespan, requiring players to manage storage conditions carefully. Proper shelter is no longer just optional - it is key to efficiently preserving your equipment and produce, adding to a more immersive farming experience.

---

- [Features](#features)
- [Installation](#installation)
  - [Uninstalling](#uninstalling)
- [How It Works](#how-it-works)
  - [Vehicles and Tools](#vehicles-and-tools)
  - [Bales, Pallets, and Stored Goods](#bales-pallets-and-stored-goods)
- [Configuration](#configuration)
- [Commands](#commands)
  - [Current Weather](#current-weather)
  - [Toggle Icon Status](#toggle-icon-status)
- [Multiplayer Support](#multiplayer-support)
- [Troubleshooting](#troubleshooting)
- [Contribution](#contribution)
- [License](#license)
- [Credits](#credits)

---

## Features

- **Vehicle & Tool Degradation**: Outdoor exposure causes gradual damage to unused vehicles and equipment
- **Perishable Goods System**:
  - Best-by dates
  - Weather wetness (rain/snow causes moisture damage)
  - Temperature effects (heat spoilage, freezing damage)
- **Smart Storage Detection**:
  - Automatic recognition of valid indoor spaces
  - Custom zone markers for non-standard structures (found in Buildings - Sheds)
- **Customizable Settings**:
  - Adjustable decay rates via config files
  - Savegame-specific configurations

---

## Installation

1. Download the `FS22_ShelterMatters.zip` file.
2. Place the file in your Farming Simulator 22 mods folder, typically located at: `Documents/My Games/FarmingSimulator2022/mods`.
3. Launch the game and enable the mod in the "Installed Mods" section.

> **Tip**: To ensure proper indoor detection, especially on custom maps, use the included **Indoor Area placeables** (*Buildings → Sheds*) to define sheltered zones.

### Uninstalling

If you decide that the ShelterMatters mod does not fit your playstyle, you can easily remove it without affecting your savegame. Follow these simple steps to uninstall the mod safely:

1. Sell or remove any placed Indoor Area placeables before uninstalling to avoid lingering objects in your savegame.
2. Disable the mod in your savegame from the "Installed Mods" section in the main menu.
3. (Optional) Delete the FS22_ShelterMatters.zip file from your mods folder, typically located at: `Documents/My Games/FarmingSimulator2022/mods`.

That's it! Your savegame will continue to work as normal without the mod.

---

## How It Works
Here’s an improved version of your **How It Works** section with better flow, clarity, and consistency while keeping all the essential details:

---

## How It Works

ShelterMatters dynamically detects whether vehicles, tools, and products are properly stored using the `indoorAreas` of placeables. If a building lacks defined indoor areas (common for static buildings in custom maps), you can manually define them using the Indoor Area placeables included in the mod.

### Vehicles and Tools

- Vehicles and tools left outdoors will gradually accumulate wear and tear, even when idle.
- Vehicles in use will only experience their normal operational wear.

#### Vehicle Damage

Vehicles degrade over time when exposed to the elements. The rate of damage varies based on the type of vehicle and the current weather conditions.

- **Base Damage Rate**: Each vehicle type (tractors, harvesters, trailers, etc.) has a configurable wear rate, reflecting realistic usage.
- **Weather Influence**: Environmental conditions can accelerate wear, making storage a crucial part of farm management.

#### Weather Impact on Vehicles

Different weather conditions affect vehicle durability:

- **Rain** – Significantly increases wear due to water exposure.
- **Snow** – Increases wear over time due to freezing and thawing cycles.
- **Fog** – Causes minor additional wear due to excess moisture.
- **Sunny & Cloudy** – Standard wear rate with no additional impact.

#### Vehicle Shelter Indication

ShelterMatters provides an on-screen indicator showing whether the **currently selected vehicle or tool** is inside or outside a shelter. This helps you track which equipment is protected from the elements.

- **Inside a Shelter** – Confirms the selected vehicle is protected from environmental wear.
- **Outside a Shelter** – Warns that the vehicle is exposed, making it more susceptible to damage.

Below is an example of the shelter indication in action:

**Inside a Shelter**
![Inside Shelter Example](screenshots/indicationInside.jpg)

**Outside a Shelter**
![Outside Shelter Example](screenshots/indicationOutside.jpg)

You can disable this indicator using the [`smToggleShelterStatusIcon` command](#toggle-icon-status) or by modifying the save file.

---

### Bales, Pallets, and Stored Goods

Stored goods are affected by two key mechanics: **Shelf Life System** and **Weather Exposure**.

#### Shelf Life System

Certain products have a **best-before period**. Once this period expires, they begin to decay, regardless of storage conditions.

#### Weather Exposure (Only Applies Outdoors)

- **Temperature Sensitivity**: Some products are temperature-sensitive and will decay if stored outside their optimal temperature range.
- **Moisture Absorption**: Products left in rain, snow, or fog will absorb moisture. Moisture accumulation makes products wet. Wet products will decay regardless of whether they are stored inside or outside.
    - **Rain** – Causes rapid moisture absorption.
    - **Snow** – Slower moisture absorption, as snow must first settle and then melt.
    - **Fog** – Minor moisture accumulation over time.
    - **Sunny & Cloudy** – No additional moisture effects.
- **Wetness Decay**: Once wet, a product will continue to decay until dried, whether stored inside or outside.
- **Drying Mechanism**: Wet products can be dried by processing them again (e.g., cutting open and rebaling bales, unloading and reloading trailers).
- **Pallet Spawn Protection**: Newly spawned pallets have temporary protection from decay and moisture (default: 24 in-game hours).

#### **Wetness Levels**
Products can have different levels of moisture, affecting decay rates:

- **Dry** (0%) – No decay.
- **Slightly Moist** (1 - 30%) – Minor decay.
- **Damp** (30 - 60%) – Noticeable decay.
- **Wet** (60 - 80%) – Significant decay.
- **Soaking Wet** (80 - 100%) – Maximum decay. 

---

## Configuration

The mod comes with a default configuration that can be customized. All parameters are configurable through a file in your savegame or by using in game commands.

- **Hide Shelter Status Icon**: Toggles the visibility of the Vehicle Shelter Indication.
- **Pallet Spawn Protection**: Sets the duration (in hours) during which newly spawned pallets are protected from decay and wetness.
- **Damage Rates**: Defines how much damage is applied to different vehicle types over time (expressed as a percentage per in-game year).
- **Weather Multipliers**: Adjusts how various weather conditions influence vehicle wear and degradation.
- **Weather Wetness Rates**: Controls the rate at which products absorb moisture in different weather conditions (expressed as %/min).
- **Decay Properties** (affects product degradation based on environmental conditions, **optional**—properties can be omitted if they do not apply to a specific product):
    - **wetnessImpact**: Multiplier affecting how quickly moisture affects the product.
    - **wetnessDecay**: Deterioration rate when fully wet (liters/month).
    - **bestBeforePeriod**: Duration (in months) before a product starts to decay.
    - **bestBeforeDecay**: Decay rate after the best-before period expires (liters/month).
    - **maxTemperature**: Maximum temperature at which the product remains in good condition (°C).
    - **maxTemperatureDecay**: Deterioration rate when above the maximum temperature (liters/hour).
    - **minTemperature**: Minimum temperature at which the product remains in good condition (°C).
    - **minTemperatureDecay**: Deterioration rate when below the minimum temperature (liters/hour).
- **Weather-Affected Specs**: Determines which vehicle specializations are impacted by weather conditions. If a vehicle has at least one of these, it will be affected.
- **Weather-Excluded Specs**: Specifies vehicle specializations that are immune to weather-related degradation. If a vehicle has any of these, it will not be affected.
- **Weather-Excluded Types**: Defines vehicle types that are not affected by weather conditions.

### Example config

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<ShelterMatters>
    <hideShelterStatusIcon>false</hideShelterStatusIcon>
    <palletSpawnProtection>24</palletSpawnProtection>
    <damageRates>
        <rate type="default" rate="10.000000"/>
        <rate type="seeder" rate="12.000000"/>
        <rate type="combineHarvester" rate="20.000000"/>
        <rate type="baler" rate="15.000000"/>
        <rate type="tractor" rate="10.000000"/>
        ...
    </damageRates>
    <weatherMultipliers>
        <multiplier type="rain" multiplier="5.000000"/>
        <multiplier type="snow" multiplier="2.000000"/>
        <multiplier type="fog" multiplier="1.500000"/>
        <multiplier type="cloudy" multiplier="1.000000"/>
        <multiplier type="sunny" multiplier="1.000000"/>
    </weatherMultipliers>
    <weatherWetnessRates>
        <rate type="default" rate="0.000000"/>
        <rate type="fog" rate="0.500000"/>
        <rate type="rain" rate="2.000000"/>
        <rate type="snow" rate="1.000000"/>
    </weatherWetnessRates>
    <decayProperties>
        <property type="WHEAT" wetnessImpact="1.000000" wetnessDecay="2000.000000" bestBeforePeriod="24" bestBeforeDecay="500.000000"/>
        <property type="BARLEY" wetnessImpact="1.000000" wetnessDecay="2000.000000" bestBeforePeriod="24" bestBeforeDecay="500.000000"/>
        <property type="PARSNIP" wetnessImpact="1.200000" wetnessDecay="3000.000000" bestBeforePeriod="9" bestBeforeDecay="2500.000000" maxTemperature="8" maxTemperatureDecay="15.000000" minTemperature="-2" minTemperatureDecay="10.000000"/>
        ...
    </decayProperties>
    <weatherAffectedSpecs>
        <value name="Shovel"/>
        <value name="Trailer"/>
    </weatherAffectedSpecs>
    <weatherExcludedSpecs>
        <value name="WaterTrailer"/>
    </weatherExcludedSpecs>
    <weatherExcludedTypes>
    </weatherExcludedTypes>
</ShelterMatters>
```

## Commands

The following commands can be useful for quick ingame changes and debug purposes. These commands must be entered through the developer console, which can be accessed by enabling the console in the game's settings.

---

### Current Weather
- **Command**: `smCurrentWeather`
- **Description**: Displays the current weather conditions and their associated multiplier.
- **Example Output**: `Weather: rain, applying multiplier: 5.00`

---

### Toggle icon status
- **Command**: `smToggleShelterStatusIcon`
- **Description**: Toggle the visibility of the shelter status icon. This is saved in the savegame and for all users.

---

## Multiplayer Support

The ShelterMatters mod is compatible with multiplayer. The configuration and damage logic are server-side, and changes to damage rates and weather multipliers will affect all players on the server. Only server admins can change these values using the commands.

---

## Troubleshooting

**Q: Vehicles are not recognized as "inside".**
- Ensure the shed or placeable has a properly defined indoor area.
- Move the vehicle slightly to ensure it is within the boundaries.

**Q: Buildings do not provide indoor detection.**
- Some placeables or map buildings may **lack defined indoor areas**, particularly static buildings on custom maps (**non-selectable in construction mode**).
- **➡️ Solution**:
    - Use the **Indoor Area placeables** included in this mod (**Buildings → Sheds**) to manually define indoor zones.
    - This ensures vehicles, tools, bales, and pallets stored within these areas are correctly recognized as "inside."

![Indoor area placeables](screenshots/indoorAreas.jpg)

**Q: I’m not seeing any changes in wear or damage.**
- Verify that the mod is enabled in your save game.
- Check the logs for errors (`log.txt` in the game directory).

---

## Contribution

Feel free to contribute to the development of **ShelterMatters** by reporting bugs, suggesting features, or submitting pull requests on the project’s GitHub page.

---

## License

This mod is distributed under the [MIT License](https://opensource.org/licenses/MIT). Feel free to modify and share it, but please give credit to the original creator.

---

## Credits

- Developed by: depuits
- Special thanks to the Farming Simulator modding community for documentation and support.
