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
- Terrain and environment
- Basic level design
- Scene management and transitions

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
