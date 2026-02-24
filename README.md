# Small Frog Game

A small-scale 3rd person 3D mini RPG built with Godot 4.6.

## Current Features

### Controls
- **Click to move** — left-click anywhere on the ground to walk there
- **Mouse wheel** — zoom the camera in/out
- **Click on items** — items highlight when clicked; walk near them to interact
- **Escape** — quit the game

### What's in the game
- Animated knight character with walk/idle animations
- Isometric follow camera with zoom
- Text-based map system for building levels (ground textures, 3D grass, buildings, items)
- Procedural ground shader with grass/dirt tile blending
- 3D grass blades with wind sway animation
- Navigation mesh with pathfinding around obstacles
- Item pickup with highlight and interaction dialog
- Map transitions with portal system and fade-to-black effect

## Map System

Levels are defined as `.map` text files with a layered grid format:

- **Ground layer** — controls flat ground texture (grass vs bare dirt)
- **Decoration layer** — 3D decorations like grass blades
- **Objects layer** — buildings, trees, and other models with collision and optional portal triggers
- **Items section** — pickups placed at exact world positions

Models are referenced by ID and resolved through an asset registry (`assets/asset_registry.cfg`). See `.claude/MAP_FILES.md` for the full format spec.

## Development Status

The project follows a 10-phase plan.

**Phase 1 (Core Foundation) — complete:**
1. ~~Player with click-to-move~~
2. ~~Animated 3D model~~
3. ~~Map, collision & navigation~~
4. ~~Item interaction~~

**Phase 2 (World Building) — in progress:**
1. ~~Map transitions (portal system)~~
2. World map navigation
3. Terrain height
4. NPC placement

**Upcoming phases:** Combat system, monsters, leveling & stats, equipment, NPCs & villages, dialog system, UI/HUD, polish & balance.

## CI/CD

A GitHub Actions workflow automatically exports the game on tag push (`v*`):
- Windows Desktop build
- Web build
- Both attached to a GitHub Release

## Asset Credits

3D models and animations by **Kay Lousberg** — [kaylousberg.com](https://www.kaylousberg.com)
Licensed under **CC0 1.0** (Creative Commons Zero). Free for personal, educational, and commercial use.

- [Patreon](http://patreon.com/kaylousberg)
- [Twitter](http://twitter.com/KayLousberg)

## License

Game code is licensed under **AGPL-3.0**. See `assets/LICENSE_stuff.txt`.
