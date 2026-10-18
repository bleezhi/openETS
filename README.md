# openETS

**openETS** is a standalone, open-source truck-driving simulator prototype. It is not a mod or replacement executable for Euro Truck Simulator 2, and it does not include proprietary game assets.

## Current prototype

- Procedurally generated road, roadside scenery, truck and trailer
- Basic acceleration, braking, steering and speed readout
- Cockpit and chase camera views
- Linux-first Godot 4 project
- GitHub Actions workflow for headless project validation

## Requirements

- Godot Engine 4.3 or newer
- Linux desktop with OpenGL 3.3 / compatible graphics support

## Run

1. Install Godot 4.x from your distribution or from [godotengine.org](https://godotengine.org/).
2. Extract or clone this repository.
3. Open `project.godot` in Godot and press **F6** or **F5**.

You can also launch it from a terminal:

```sh
godot --path . --editor
# or run the project directly
godot --path .
```

Depending on your package, the executable may be named `godot4`.

## Main menu

The game opens to a main menu with **Continue Driving**, **New Drive**, **Controls**, and **Quit**. New Drive resets the truck and returns to the cockpit view. Press Escape while driving to toggle mouse capture.

## Controls

| Key | Action |
| --- | --- |
| W / S | Accelerate / reverse |
| A / D | Steer |
| Space | Brake |
| C | Switch cockpit / chase camera |
| H | Toggle headlights |
| Q / E | Left / right indicator |
| X | Cancel indicators |
| K | Toggle cruise control |
| R | Reset truck |
| Esc | Toggle mouse capture |

## Roadmap

- [x] Basic driving controls and speed HUD
- [x] Cockpit and chase camera modes
- [x] Headlights, indicators and cruise-control prototype
- [ ] Better vehicle dynamics and collision handling
- [ ] Proper cockpit mesh, dashboard and mirrors
- [ ] Gearbox, engine audio, lights and indicators
- [ ] Traffic AI and road junctions
- [ ] Cargo jobs, delivery economy and save files
- [ ] More detailed scenery and a modular map system
- [ ] Controller and steering-wheel support

## Project principles

- Standalone game; no ETS2 installation required
- Linux first
- Original assets and clean-room implementation
- Open development and reproducible CI builds

## License

The project is licensed under the MIT License. See `LICENSE`.

## Current limitations

This is an early prototype with placeholder geometry. The truck is currently controlled with a lightweight kinematic model; there is not yet a full rigid-body drivetrain, traffic, cargo economy, sound design, or a detailed European map. Cruise control is a basic prototype feature, and the indicator lamps are visual controls rather than a fully timed signal system.
