# ShelterMatters

**ShelterMatters** is a mod for Farming Simulator 22 that enhances the importance of sheds and indoor storage by introducing mechanics for vehicle and tool wear and tear based on their location.

---

## Features

- **Damage Accumulation**: Vehicles and tools left outside will accumulate damage over time, even if they're not in use.
- **Dynamic Indoor Detection**: Automatically detects indoor areas for all placeables on the map.
- **Weather Sensitivity**: Protect your equipment from harsh weather conditions by storing them properly.

---

## Installation

1. Download the `ShelterMatters.zip` file.
2. Place the file in your Farming Simulator 22 mods folder, typically located at: `Documents/My Games/FarmingSimulator2022/mods`.
3. Launch the game and enable the mod in the "Installed Mods" section.

---

## Usage

### How It Works
- Vehicles and tools left outdoors will slowly accumulate damage, even when idle.
- The mod uses the `indoorAreas` of placeables to detect whether equipment is stored properly.

### Weather Interaction
- Damage and wear accumulation rates are influenced by the current weather. For example:
- **Rain or Snow**: Accelerated damage for vehicles left outside.

---

## Configuration

The mod currently does not include a configuration file but can be adjusted by modifying the Lua script. Future updates may include customizable damage and wear rates.

---

## Troubleshooting

### Common Issues
- **Q: Vehicles are not recognized as "inside."**
- Ensure the shed or placeable has a properly defined indoor area.
- Move the vehicle slightly to ensure it is within the boundaries.

- **Q: I’m not seeing any changes in wear or damage.**
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
