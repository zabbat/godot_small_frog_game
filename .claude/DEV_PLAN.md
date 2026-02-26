# Development Plan

Bottom-up phased approach — build core systems first, then layer features on top.

## Phase 1: Core Foundation

### 1.1 — Placeholder Player with Click-to-Move
- Create a simple 3D shape (e.g. capsule) as a placeholder player
- Fixed camera at 45-degree top-down angle
- Click-to-move: clicking on the ground plane moves the character to that point
- Movement on a 2D plane (XZ), no jumping yet

### 1.2 — Animated 3D Player Model
- Replace placeholder shape with an animated 3D character model
- Walk/idle animations that play correctly based on movement state

### 1.3 — Map & Collision
- Build a basic map/environment with obstacles
- Add collision shapes so the player cannot walk through objects
- Navigation mesh for proper pathfinding around obstacles

### 1.4 — Item Interaction Proof of Concept
- Place a small pickup item in the world
- Display text on screen when the player walks over/near the item
- Serves as proof of concept for future interaction systems

## Phase 2: World Building

### 2.1 — Map Transitions (Interiors)
- Add a `[portals]` section to the map format: `<name>, (<x>, <y>, <z>), <target_map>, (<spawn_x>, <spawn_y>, <spawn_z>)`
- Portal objects in the world (e.g. door on a house) that the player can click/walk into
- Scene transition: unload current map, load target map, place player at spawn position
- Build an interior map (e.g. inside_house.map) to test entering/exiting a building
- Fade-to-black or simple transition effect between maps

### 2.2 — World Map & Multi-Area Navigation
- Create a world map (overworld) where each area is a node the player can walk between
- Walking to the edge of a local map transitions to the world map
- Edge portals: define which map edges connect to the world map (or to adjacent maps)
- On the world map, villages/locations are clickable destinations
- Entering a destination loads the corresponding local map

### 2.3 — Terrain Height & Elevation (skipped for now)
- Extend the map format to support height data (e.g. a `[layer:height]` grid or per-cell height values)
- Ground mesh deforms based on height values instead of being a flat plane
- Navigation mesh adapts to elevation so pathfinding works on slopes/hills
- Objects and decorations spawn at the correct Y position based on terrain height
- Camera adjusts smoothly as the player moves across elevation changes

### 2.4 — NPC Placement ✓
- `[npcs]` section in map files: `<id>: "<name>", "<info>", (<col>, <row>), <pattern>`
- NPC registry (`assets/npc_registry.cfg`) maps IDs to models, materials, and animations
- `scripts/npc.gd` loads model, applies material, plays idle animation
- NPCs spawn at grid positions on map load, cleaned up on map transitions
- Move patterns: IDLE for now, expandable to PATROL, WANDER, etc.

## Phase 3: Combat System
- Player attacks and animations
- Hit detection
- Health system (player and enemies)
- Basic enemy AI

## Phase 4: Monsters
- Enemy types with different behaviors
- Spawn system
- Loot drops

## Phase 5: Leveling & Stats
- Experience points
- Level-up system
- Player stats (HP, attack, defense, etc.)
- Stat scaling per level

## Phase 6: Equipment
- Inventory system
- Equippable items (weapon, armor, etc.)
- Stat modifiers from gear

## Phase 7: NPCs & Villages
- Village scenes
- NPC placement and idle behavior
- Interaction system (approach + interact)

## Phase 8: Dialog System
- Dialog UI
- Branching conversations
- Quest-related dialogs

## Phase 9: UI & HUD
- Health bar
- XP bar
- Inventory screen
- Main menu and pause menu

## Phase 10: Polish & Balance
- Game balance (damage, XP curves, enemy difficulty)
- Bug fixes
- Visual and audio polish
